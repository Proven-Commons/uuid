/-
  The UUID value, its printed form, and its two field readings,
  following RFC 9562.

  A UUID value is sixteen bytes, held as a list of `UInt8`. The
  printer writes the canonical form: five groups of lowercase
  hex digits of lengths 8, 4, 4, 4, and 12, split by hyphens,
  36 characters in all.
-/

namespace Uuid

/-- A UUID value is well formed when it holds sixteen bytes.
    The parser always returns a well formed value, and the round
    trip claim is stated for well formed values. -/
def WF (bs : List UInt8) : Prop :=
  bs.length = 16

/-- The sixteen hex digits, lowercase. -/
def hexDigits : List Char :=
  ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

/-- The lowercase hex digit for a value below 16. A value of 16
    or more gives the fallback character; the printer only ever
    calls this below 16, and no claim is made above it. -/
def hexDigit (n : Nat) : Char :=
  hexDigits.getD n '0'

/-- The two hex digits of one byte, high digit first. -/
def printByte (b : UInt8) : List Char :=
  [hexDigit (b.toNat / 16), hexDigit (b.toNat % 16)]

/-- The hex digits of a list of bytes, with no separators. -/
def hexs : List UInt8 → List Char
  | [] => []
  | b :: bs => printByte b ++ hexs bs

/-- The canonical printed form: groups of 4, 2, 2, 2, and 6
    bytes, split by hyphens. On a list that does not hold sixteen
    bytes the slices take what is there; the printer is only
    claimed on sixteen bytes. -/
def print (bs : List UInt8) : List Char :=
  hexs (bs.take 4) ++ ['-'] ++
  hexs ((bs.drop 4).take 2) ++ ['-'] ++
  hexs ((bs.drop 6).take 2) ++ ['-'] ++
  hexs ((bs.drop 8).take 2) ++ ['-'] ++
  hexs (bs.drop 10)

/-- The version: the high four bits of the seventh byte (index
    6). A list too short to hold that byte reads as version 0. -/
def version (bs : List UInt8) : Nat :=
  (bs.getD 6 0).toNat / 16

/-- The variant, named from the top bits of the ninth byte
    (index 8), as the table in RFC 9562 section 4.1 lays out. -/
inductive Variant where
  | ncs
  | rfc
  | microsoft
  | future
deriving DecidableEq, Repr

/-- The variant of a value: a ninth byte below 128 is NCS, from
    128 to 191 is the RFC 9562 variant, from 192 to 223 is
    Microsoft, and from 224 up is set aside for future use. A
    list too short to hold that byte reads as NCS. -/
def variant (bs : List UInt8) : Variant :=
  let b := (bs.getD 8 0).toNat
  if b < 128 then .ncs
  else if b < 192 then .rfc
  else if b < 224 then .microsoft
  else .future

/-- The variant as a number, the form the command line tool
    reports: 0 for NCS, 1 for the RFC 9562 variant, 2 for
    Microsoft, 3 for future use. -/
def variantNumber : Variant → Nat
  | .ncs => 0
  | .rfc => 1
  | .microsoft => 2
  | .future => 3

/-- The nil UUID: all sixteen bytes zero. -/
def nil : List UInt8 :=
  List.replicate 16 0

/-- The max UUID: all sixteen bytes 255. -/
def max : List UInt8 :=
  List.replicate 16 255

end Uuid
