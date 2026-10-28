# uuid

A UUID parser and printer in Lean, following RFC 9562, with the round trip proved: parsing the printed form of any sixteen bytes gives those bytes back.

`SPEC.md` states the rules as this library applies them.

## What it does

`Uuid/Value.lean` holds the printer and the two field readings. A value is sixteen bytes. The printer writes the canonical form, five groups of lowercase hex digits split by hyphens. The version reading takes the high four bits of the seventh byte, and the variant reading names the top bits of the ninth byte. The nil value (all bytes zero) and the max value (all bytes 255) are named. `Uuid/Parse.lean` holds the parser, which reads the canonical shape with hex letters in either case. `Main.lean` is a small command-line front end the tests drive, with a `parse` operation and a `fields` operation.

## What is proved

The definitions are in `Uuid/Value.lean` and `Uuid/Parse.lean`. The proofs are in `Uuid/Proofs/`.

| Claim | Theorem |
|-------|---------|
| Parsing the printed form of a well formed value gives the value back. | `Uuid.Proofs.parse_print` |
| The nil value prints as the all zero text, and reads back from it. | `Uuid.Examples.print_nil`, `Uuid.Examples.parse_nil` |
| The max value prints as the all f text, and reads back from it. | `Uuid.Examples.print_max`, `Uuid.Examples.parse_max` |
| The RFC example values carry their versions and variants: `f81d4fae-7dec-11d0-a765-00a0c91e6bf6` and the DNS namespace value are version 1 with the RFC variant. | `Uuid.Examples.ex1_version`, `Uuid.Examples.ex1_variant`, `Uuid.Examples.dns_version`, `Uuid.Examples.dns_variant` |
| The brace form, the URN form, and the form with no hyphens are rejected, along with the wrong lengths and a moved hyphen. | `Uuid.Examples.reject_brace` and the cases with it |

The proved theorems check against the standard axioms only (`propext`, `Classical.choice`, `Quot.sound`), which a reader can confirm with the prints in `Uuid/Verify.lean`.

## What is not proved

- That the parser accepts every text the shape allows, and rejects every text it forbids. The round trip does not need either, so neither is proved. The test harness checks that behaviour against Python's `uuid` module and against a strict reading of the shape, and the results file records the outcome, including any failure.
- Anything about making new UUIDs. There are no generators here: no clock, no random source, and no name based hashing, so versions 1, 3, 4, 5, 6, 7, and 8 are only ever read, never made.
- That the other text forms mean the same value. The brace, URN, and no-hyphen forms are rejected, not read, so no claim connects them to a value.
- Reading requests and printing answers in `Main.lean`: splitting lines, the decimal parser, and the check that a code is a Unicode scalar value. The tests cover them, malformed requests included.
- Speed. The code works on lists of characters and bytes, which suits proofs, not large data.

## What you must trust

- The Lean kernel, which checks the proofs.
- The Lean compiler, with the C compiler and linker shipped with it, and the runtime, which turn the proved definitions into the program that runs.
- Lean's core library, including the compiled code it puts in place of some definitions the proofs reason about.
- The operating system and hardware it runs on.
- Python's `uuid` module and the strict oracle in the test harness, and the reader's own reading of RFC 9562, which the oracle and this code both follow.

This project has no dependencies beyond Lean itself.

## Run it

Needs Linux and [elan](https://github.com/leanprover/elan). Build, then feed request lines to the tool:

```
lake build
echo "parse 102,56,49,100,52,102,97,101,45,55,100,101,99,45,49,49,100,48,45,97,55,54,53,45,48,48,97,48,99,57,49,101,54,98,102,54" | .lake/build/bin/uuid
```

That request is the text `f81d4fae-7dec-11d0-a765-00a0c91e6bf6` as character codes, and the answer is `ok:` with the same codes back. The same codes under `fields` answer `ok:49,44,49`, the codes of the text `1,1`. A text the parser rejects, such as the same value in braces, answers `none`. A malformed request answers `error`. See `SPEC.md` for the full protocol.

## Re-check it

```
lake build
python3 tests/run_tests.py
```

The test script rebuilds, reruns the fixed RFC cases and the differential run, and rewrites `tests/TEST-RESULTS.md`.
