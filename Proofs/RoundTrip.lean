/-
  The round trip proof: parsing the printed form of sixteen
  bytes gives those bytes back.

  The proof goes one byte at a time through the hex reader: a
  byte printed as two hex digits reads back as the same byte,
  because the two digits are the byte divided by 16 and the
  byte modulo 16, and the reader puts them back together. The
  printed form is then read group by group, and the five groups
  are the five slices of the sixteen bytes, which rejoin into
  the whole list.
-/

import Uuid

namespace Uuid.Proofs

open Uuid

/-- Every one of the sixteen hex digits reads back as its own
    value. Checked digit by digit. -/
theorem hexVal_hexDigit : ∀ n : Fin 16, hexVal (hexDigit n.val) = some n.val := by
  decide

/-- The hex digit for a value below 16 reads back as that
    value. -/
theorem hexVal_of_hexDigit {n : Nat} (h : n < 16) : hexVal (hexDigit n) = some n :=
  hexVal_hexDigit ⟨n, h⟩

/-- Reading back the printed digits of a byte list: the reader
    returns the bytes and leaves the rest of the text alone. -/
theorem takeHex_hexs : ∀ (k : Nat) (bs : List UInt8) (rest : List Char),
    bs.length = k → takeHex k (hexs bs ++ rest) = some (bs, rest) := by
  intro k
  induction k with
  | zero =>
    intro bs rest h
    cases bs with
    | nil => rfl
    | cons b bs' => simp at h
  | succ k ih =>
    intro bs rest h
    match bs, h with
    | [], h => simp at h
    | b :: bs', h =>
      have hb16 : b.toNat / 16 < 16 := by
        have hlt := b.toNat_lt
        omega
      have hlen : bs'.length = k := by simpa using h
      have e1 : hexVal (hexDigit (b.toNat / 16)) = some (b.toNat / 16) :=
        hexVal_of_hexDigit hb16
      have e2 : hexVal (hexDigit (b.toNat % 16)) = some (b.toNat % 16) :=
        hexVal_of_hexDigit (Nat.mod_lt _ (by decide))
      have e3 := ih bs' rest hlen
      have hbyte : UInt8.ofNat (b.toNat / 16 * 16 + b.toNat % 16) = b := by
        have hval : b.toNat / 16 * 16 + b.toNat % 16 = b.toNat := by omega
        rw [hval]
        exact UInt8.ofNat_toNat
      simp only [hexs, printByte, List.cons_append, List.nil_append,
        takeHex, e1, e2, e3, hbyte]

/-- Reading back the printed digits of a byte list that makes
    up the whole text: nothing is left over. -/
theorem takeHex_hexs_nil (bs : List UInt8) (h : bs.length = 6) :
    takeHex 6 (hexs bs) = some (bs, []) := by
  have h' := takeHex_hexs 6 bs [] h
  simpa using h'

/-- The five slices the printed form is built from, put back
    together in order, are the whole list. This holds for a list
    of any length: each slice boundary is a take and a drop at
    the same place. -/
theorem slices (bs : List UInt8) :
    bs.take 4 ++ ((bs.drop 4).take 2 ++ ((bs.drop 6).take 2 ++
      ((bs.drop 8).take 2 ++ bs.drop 10))) = bs := by
  have e1 : bs.take 4 ++ bs.drop 4 = bs := List.take_append_drop 4 bs
  have e2 : (bs.drop 4).take 2 ++ bs.drop 6 = bs.drop 4 := by
    have h := List.take_append_drop 2 (bs.drop 4)
    simpa [List.drop_drop] using h
  have e3 : (bs.drop 6).take 2 ++ bs.drop 8 = bs.drop 6 := by
    have h := List.take_append_drop 2 (bs.drop 6)
    simpa [List.drop_drop] using h
  have e4 : (bs.drop 8).take 2 ++ bs.drop 10 = bs.drop 8 := by
    have h := List.take_append_drop 2 (bs.drop 8)
    simpa [List.drop_drop] using h
  rw [e4, e3, e2, e1]

/-- The round trip: parsing the printed form of a well formed
    value gives the value back. -/
theorem parse_print (bs : List UInt8) (h : WF bs) : parse (print bs) = some bs := by
  have h16 : bs.length = 16 := h
  have h4 : (bs.take 4).length = 4 := by simp [List.length_take, h16]
  have h2a : ((bs.drop 4).take 2).length = 2 := by
    simp [List.length_take, List.length_drop, h16]
  have h2b : ((bs.drop 6).take 2).length = 2 := by
    simp [List.length_take, List.length_drop, h16]
  have h2c : ((bs.drop 8).take 2).length = 2 := by
    simp [List.length_take, List.length_drop, h16]
  have h6 : (bs.drop 10).length = 6 := by simp [List.length_drop, h16]
  have s1 := takeHex_hexs 4 (bs.take 4)
    ('-' :: (hexs ((bs.drop 4).take 2) ++ '-' ::
      (hexs ((bs.drop 6).take 2) ++ '-' ::
        (hexs ((bs.drop 8).take 2) ++ '-' :: hexs (bs.drop 10))))) h4
  have s2 := takeHex_hexs 2 ((bs.drop 4).take 2)
    ('-' :: (hexs ((bs.drop 6).take 2) ++ '-' ::
      (hexs ((bs.drop 8).take 2) ++ '-' :: hexs (bs.drop 10)))) h2a
  have s3 := takeHex_hexs 2 ((bs.drop 6).take 2)
    ('-' :: (hexs ((bs.drop 8).take 2) ++ '-' :: hexs (bs.drop 10))) h2b
  have s4 := takeHex_hexs 2 ((bs.drop 8).take 2)
    ('-' :: hexs (bs.drop 10)) h2c
  have s5 := takeHex_hexs_nil (bs.drop 10) h6
  simp only [parse, print, List.append_assoc, List.cons_append, List.nil_append]
  simp only [dash, s1, s2, s3, s4, s5]
  rw [slices]

end Uuid.Proofs
