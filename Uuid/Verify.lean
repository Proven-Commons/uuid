/-
  Axiom check for the claims this package makes. Run with:

    lake env lean Uuid/Verify.lean

  Every claim should list only the standard axioms (propext,
  Classical.choice, Quot.sound). A line naming sorryAx would mean
  a proof rests on an admitted gap, and the claim is not proved.
-/

import Uuid.Proofs
import Uuid.Proofs.Examples

open Uuid.Proofs Uuid.Examples

#print axioms parse_print
#print axioms takeHex_hexs
#print axioms print_nil
#print axioms print_max
#print axioms ex1_version
#print axioms reject_brace
