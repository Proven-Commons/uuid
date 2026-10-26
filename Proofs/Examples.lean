/-
  Proved example cases, each closed by `decide`: the parser and
  the field readings are programs, so a claim about a concrete
  text is a computation the kernel can check.

  The first block is the two named values. The second is the
  example UUIDs printed in RFC 9562, with the version and the
  variant each one carries. The third checks that an upper case
  or mixed case spelling is read and reprinted in the canonical
  lowercase form. The fourth checks that texts outside this
  slice are rejected.
-/

import Uuid

namespace Uuid.Examples

open Uuid

/-! ## The named values -/

theorem print_nil : print nil = "00000000-0000-0000-0000-000000000000".toList := by
  decide

theorem print_max : print max = "ffffffff-ffff-ffff-ffff-ffffffffffff".toList := by
  decide

theorem parse_nil : parse "00000000-0000-0000-0000-000000000000".toList = some nil := by
  decide

theorem parse_max : parse "ffffffff-ffff-ffff-ffff-ffffffffffff".toList = some max := by
  decide

/-- The nil value carries version 0 and the NCS variant: both
    readings look at zero bytes. -/
theorem nil_fields : version nil = 0 ∧ variant nil = Variant.ncs := by
  decide

/-- The max value carries version 15 and the future variant:
    both readings look at bytes of all ones. -/
theorem max_fields : version max = 15 ∧ variant max = Variant.future := by
  decide

/-! ## The examples printed in RFC 9562 -/

/-- The version 1 example from the RFC introduction. -/
theorem ex1_print : (parse "f81d4fae-7dec-11d0-a765-00a0c91e6bf6".toList).map print =
    some "f81d4fae-7dec-11d0-a765-00a0c91e6bf6".toList := by
  decide

theorem ex1_version : (parse "f81d4fae-7dec-11d0-a765-00a0c91e6bf6".toList).map version =
    some 1 := by
  decide

theorem ex1_variant : (parse "f81d4fae-7dec-11d0-a765-00a0c91e6bf6".toList).map variant =
    some Variant.rfc := by
  decide

/-- The DNS namespace value from the RFC appendix. -/
theorem dns_print : (parse "6ba7b810-9dad-11d1-80b4-00c04fd430c8".toList).map print =
    some "6ba7b810-9dad-11d1-80b4-00c04fd430c8".toList := by
  decide

theorem dns_version : (parse "6ba7b810-9dad-11d1-80b4-00c04fd430c8".toList).map version =
    some 1 := by
  decide

theorem dns_variant : (parse "6ba7b810-9dad-11d1-80b4-00c04fd430c8".toList).map variant =
    some Variant.rfc := by
  decide

/-- The other three namespace values from the RFC appendix:
    URL, OID, and X.500. -/
theorem url_print : (parse "6ba7b811-9dad-11d1-80b4-00c04fd430c8".toList).map print =
    some "6ba7b811-9dad-11d1-80b4-00c04fd430c8".toList := by
  decide

theorem oid_print : (parse "6ba7b812-9dad-11d1-80b4-00c04fd430c8".toList).map print =
    some "6ba7b812-9dad-11d1-80b4-00c04fd430c8".toList := by
  decide

theorem x500_print : (parse "6ba7b814-9dad-11d1-80b4-00c04fd430c8".toList).map print =
    some "6ba7b814-9dad-11d1-80b4-00c04fd430c8".toList := by
  decide

/-! ## Case on input -/

/-- An upper case spelling is read, and reprints in lowercase. -/
theorem upper_print : (parse "F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6".toList).map print =
    some "f81d4fae-7dec-11d0-a765-00a0c91e6bf6".toList := by
  decide

/-- A mixed case spelling of the DNS namespace value. -/
theorem mixed_print : (parse "6BA7b810-9Dad-11d1-80B4-00c04fd430C8".toList).map print =
    some "6ba7b810-9dad-11d1-80b4-00c04fd430c8".toList := by
  decide

/-- The fields do not depend on the case of the spelling. -/
theorem upper_fields : (parse "F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6".toList).map version =
    some 1 ∧
    (parse "F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6".toList).map variant =
    some Variant.rfc := by
  decide

/-! ## Texts outside this slice are rejected -/

theorem reject_brace : parse "{f81d4fae-7dec-11d0-a765-00a0c91e6bf6}".toList = none := by
  decide

theorem reject_urn : parse "urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6".toList = none := by
  decide

theorem reject_bare : parse "f81d4fae7dec11d0a76500a0c91e6bf6".toList = none := by
  decide

theorem reject_short : parse "f81d4fae-7dec-11d0-a765-00a0c91e6bf".toList = none := by
  decide

theorem reject_long : parse "f81d4fae-7dec-11d0-a765-00a0c91e6bf6a".toList = none := by
  decide

theorem reject_moved_hyphen : parse "f81d4fae7-dec-11d0-a765-00a0c91e6bf6".toList = none := by
  decide

theorem reject_bad_digit : parse "f81d4fae-7dec-11d0-a765-00a0c91e6bfg".toList = none := by
  decide

theorem reject_empty : parse "".toList = none := by
  decide

end Uuid.Examples
