# Test results

Written by `tests/run_tests.py`. Rerun it to check these numbers.

- Oracles: Python 3.12.3 `uuid` module for values and canonical printing, plus a strict reading of the plan rules written in `tests/run_tests.py` for accept and reject
- Lean: Lean (version 4.35.0, x86_64-unknown-linux-gnu, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc, Release)
- Seed: 20261026
- This Python has no uuid7 generator, so version 7 values are covered by byte built values with that version nibble set

- fixed parse cases: 26 inputs, 26 agreements
- fixed fields cases: 24 inputs, 24 agreements
- python uuid values, parse: 3000 inputs, 3000 agreements
- python uuid values, fields: 3000 inputs, 3000 agreements
- mutated texts, parse: 1500 inputs, 1500 agreements
- mutated texts, fields: 1500 inputs, 1500 agreements
- soup texts, parse: 1500 inputs, 1500 agreements
- malformed requests: 12 inputs, 12 agreements
- Total: 10562 inputs, 10562 agreements
- Failures: 0
