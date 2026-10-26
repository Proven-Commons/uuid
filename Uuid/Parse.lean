/-
  The UUID parser, following RFC 9562.

  The parser reads the canonical shape from a list of
  characters: eight hex digits, a hyphen, four, a hyphen, four,
  a hyphen, four, a hyphen, twelve. A hex digit may be a decimal
  digit, a letter from a to f, or a letter from A to F. Anything
  else is turned away: the wrong length, a hyphen anywhere but
  its four places, a character outside hex in a digit place,
  and any text after the last digit. The brace form, the URN
  form, and the form with no hyphens are not read; they sit
  outside this slice.
-/

namespace Uuid

/-- The value of one hex digit, in either case. -/
def hexVal (c : Char) : Option Nat :=
  if '0' ≤ c ∧ c ≤ '9' then some (c.toNat - 48)
  else if 'a' ≤ c ∧ c ≤ 'f' then some (c.toNat - 87)
  else if 'A' ≤ c ∧ c ≤ 'F' then some (c.toNat - 55)
  else none

/-- Read exactly `k` bytes, each written as two hex digits,
    from the front of the text. Returns the bytes and the text
    that is left. -/
def takeHex : Nat → List Char → Option (List UInt8 × List Char)
  | 0, cs => some ([], cs)
  | k + 1, c₁ :: c₂ :: cs =>
    match hexVal c₁, hexVal c₂, takeHex k cs with
    | some hi, some lo, some (bs, rest) =>
        some (UInt8.ofNat (hi * 16 + lo) :: bs, rest)
    | _, _, _ => none
  | _, _ => none

/-- Read one hyphen from the front of the text. -/
def dash : List Char → Option (List Char)
  | '-' :: cs => some cs
  | _ => none

/-- Parse the canonical form into sixteen bytes: four groups
    of bytes read in turn, a hyphen between each pair of
    groups, and nothing left over at the end. -/
def parse (cs : List Char) : Option (List UInt8) :=
  match takeHex 4 cs with
  | none => none
  | some (a, cs) =>
    match dash cs with
    | none => none
    | some cs =>
      match takeHex 2 cs with
      | none => none
      | some (b, cs) =>
        match dash cs with
        | none => none
        | some cs =>
          match takeHex 2 cs with
          | none => none
          | some (c, cs) =>
            match dash cs with
            | none => none
            | some cs =>
              match takeHex 2 cs with
              | none => none
              | some (d, cs) =>
                match dash cs with
                | none => none
                | some cs =>
                  match takeHex 6 cs with
                  | none => none
                  | some (e, cs) =>
                    match cs with
                    | [] => some (a ++ b ++ c ++ d ++ e)
                    | _ => none

end Uuid
