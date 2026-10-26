#!/usr/bin/env python3
"""Tests for the Lean UUID parser, printer, and field readings.

Three parts.

1. Fixed cases. The example UUIDs printed in RFC 9562 (the
   version 1 example, the four namespace values, the nil value,
   the max value) as `parse` and `fields` requests; upper and
   mixed case spellings, which must reprint in lowercase; and
   texts outside this slice (the brace form, the URN form, the
   form with no hyphens, the wrong lengths, a moved hyphen, a
   character outside hex), which must be rejected.

2. A differential run. Values from Python's `uuid` module
   (uuid1, uuid3, uuid4, uuid5, and UUID(bytes=...) over random
   bytes, some with a chosen version nibble and variant class)
   are printed by the module, parsed by the Lean tool, and the
   reprints and the field readings are compared. This Python
   (3.12) has no uuid7 generator, so version 7 values are
   covered by byte built values with that version nibble set.
   Accept and reject on mutated and soup texts is settled by a
   strict oracle written in this file from the plan rules,
   because the module also accepts the brace, URN, and
   no-hyphen forms that this slice rejects.

3. Malformed request lines must be answered `error`.

The oracle shares no code with the Lean side. The seed is
recorded in the results file.

    python3 tests/run_tests.py [--seed N] [--count N]

The tool is driven one batch process per chunk of requests:
input written and closed, output drained until the process
exits. The harness builds the executable first, writes
tests/TEST-RESULTS.md, and exits non-zero if any check fails.
It needs Python 3.11 or later.
"""

import argparse
import platform
import random
import subprocess
import sys
import threading
import uuid as uuid_module
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXE = ROOT / ".lake" / "build" / "bin" / "uuid"
RESULTS = ROOT / "tests" / "TEST-RESULTS.md"
TIMEOUT = 900
BUILD_TIMEOUT = 3600
CHUNK = 2000

SEED_DEFAULT = 20261026

HEX = set("0123456789abcdefABCDEF")
HYPHENS = (8, 13, 18, 23)


def codes(text):
    return ",".join(str(ord(c)) for c in text)


def parse_request(text):
    return "parse " + codes(text)


def fields_request(text):
    return "fields " + codes(text)


def run_tool(lines, timeout=TIMEOUT):
    """Run the tool on a batch of request lines.

    Returns (answers, problem). No right answer is longer than
    its request plus a small constant, so output past twice the
    input plus 64 bytes a line is stopped, not read until memory
    runs out.
    """
    data = "".join(line + "\n" for line in lines)
    raw = data.encode("utf-8")
    limit = 2 * len(raw) + 64 * (len(lines) + 1)
    try:
        proc = subprocess.Popen(
            [str(EXE)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as e:
        return [], f"could not run {EXE}: {e.strerror or e}"
    out, err = bytearray(), bytearray()

    def feed():
        try:
            proc.stdin.write(raw)
            proc.stdin.close()
        except (BrokenPipeError, ValueError):
            pass

    def drain(stream, buf, cap):
        while chunk := stream.read1(1 << 16):
            buf += chunk
            if len(buf) > cap:
                proc.kill()
                return

    threads = [
        threading.Thread(target=feed),
        threading.Thread(target=drain, args=(proc.stdout, out, limit)),
        threading.Thread(target=drain, args=(proc.stderr, err, 1 << 20)),
    ]
    for t in threads:
        t.start()
    problem = None
    try:
        proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        proc.kill()
        problem = f"no end after {timeout} seconds"
    for t in threads:
        t.join()
    proc.wait()
    if len(out) > limit:
        problem = problem or f"more than {limit} bytes of output, stopped"
    elif proc.returncode != 0 and not problem:
        tail = " / ".join(
            bytes(err).decode("utf-8", "backslashreplace").splitlines()[-3:]
        )
        problem = f"exit status {proc.returncode}: {tail}"
    text = bytes(out).decode("utf-8", "backslashreplace")
    if text and not text.endswith("\n"):
        problem = problem or "the last answer has no LF"
    answers = text.split("\n")
    if answers and answers[-1] == "":
        answers.pop()
    if len(answers) != len(lines) and not problem:
        problem = f"{len(lines)} requests but {len(answers)} answers"
    return answers, problem


# ------------------------------------------------------------------
# The strict oracle, written from the plan rules.
#
# A text is read when it is 36 characters, has hyphens at
# positions 8, 13, 18, and 23, and has a hex digit (either case)
# at every other position. The reading is the sixteen bytes.
# The canonical print is Python uuid's own str of those bytes,
# which is the lowercase hyphenated form.


def oracle_parse(text):
    if len(text) != 36:
        return None
    for i, ch in enumerate(text):
        if i in HYPHENS:
            if ch != "-":
                return None
        elif ch not in HEX:
            return None
    return bytes.fromhex(text.replace("-", ""))


def oracle_fields(bs):
    version = bs[6] >> 4
    b = bs[8]
    if b < 128:
        variant = 0
    elif b < 192:
        variant = 1
    elif b < 224:
        variant = 2
    else:
        variant = 3
    return version, variant


def expected_parse_answer(text):
    bs = oracle_parse(text)
    if bs is None:
        return "none"
    return "ok:" + codes(str(uuid_module.UUID(bytes=bs)))


def expected_fields_answer(text):
    bs = oracle_parse(text)
    if bs is None:
        return "none"
    version, variant = oracle_fields(bs)
    return "ok:" + codes(f"{version},{variant}")


# ------------------------------------------------------------------
# Fixed cases.

VALID = [
    # The version 1 example from the RFC introduction.
    "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
    # The four namespace values from the RFC appendix.
    "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
    "6ba7b811-9dad-11d1-80b4-00c04fd430c8",
    "6ba7b812-9dad-11d1-80b4-00c04fd430c8",
    "6ba7b814-9dad-11d1-80b4-00c04fd430c8",
    # The named values.
    "00000000-0000-0000-0000-000000000000",
    "ffffffff-ffff-ffff-ffff-ffffffffffff",
    # Case on input: read, and reprinted lowercase.
    "F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6",
    "6BA7b810-9Dad-11d1-80B4-00c04fd430C8",
    "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF",
    # Built to cover the other two variant classes and a
    # version above 9: byte 8 is d0 (Microsoft), then e0
    # (future), then 7f (NCS).
    "123e4567-e89b-42d3-d456-426614174000",
    "123e4567-e89b-42d3-e456-426614174000",
    "123e4567-e89b-42d3-7456-426614174000",
]

INVALID = [
    "{f81d4fae-7dec-11d0-a765-00a0c91e6bf6}",
    "urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
    "f81d4fae7dec11d0a76500a0c91e6bf6",
    "f81d4fae-7dec-11d0-a765-00a0c91e6bf",
    "f81d4fae-7dec-11d0-a765-00a0c91e6bf6a",
    "f81d4fae7-dec-11d0-a765-00a0c91e6bf6",
    "f81d4fae-7dec-11d0-a765-00a0c91e6bfg",
    "f81d4fae_7dec_11d0_a765_00a0c91e6bf6",
    "",
    "f81d4fae-7dec-11d0-a765-00a0c91e6bf6 ",
    " f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
]

MALFORMED = [
    " ",
    "parse 1,,2",
    "parse 12a",
    "parse 55296",
    "parse 1114112",
    "bogus 1,2",
    "parse 49 50",
    " parse 49",
    "parse 49,",
    "fields 1,,2",
    "fields 55296",
    "fields 49,,50",
]


def module_values(rng, count):
    """UUID values from Python's module, of every kind it makes,
    plus byte built values with chosen field bits."""
    vals = []
    for i in range(count):
        kind = i % 6
        if kind == 0:
            vals.append(uuid_module.uuid1())
        elif kind == 1:
            vals.append(uuid_module.uuid3(
                uuid_module.NAMESPACE_DNS, f"example-{rng.randrange(10 ** 6)}"))
        elif kind == 2:
            vals.append(uuid_module.uuid4())
        elif kind == 3:
            vals.append(uuid_module.uuid5(
                uuid_module.NAMESPACE_URL, f"example-{rng.randrange(10 ** 6)}"))
        elif kind == 4:
            raw = bytes(rng.randrange(256) for _ in range(16))
            vals.append(uuid_module.UUID(bytes=raw))
        else:
            raw = bytearray(rng.randrange(256) for _ in range(16))
            nibble = rng.choice([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 15])
            raw[6] = (raw[6] & 0x0F) | (nibble << 4)
            cls = rng.randrange(4)
            if cls == 0:
                raw[8] &= 0x7F
            elif cls == 1:
                raw[8] = (raw[8] & 0x3F) | 0x80
            elif cls == 2:
                raw[8] = (raw[8] & 0x1F) | 0xC0
            else:
                raw[8] = (raw[8] & 0x1F) | 0xE0
            vals.append(uuid_module.UUID(bytes=bytes(raw)))
    return vals


def mutate(rng, text):
    chars = list(text)
    alphabet = "0123456789abcdefgABCDEFGH-z{}urn: "
    for _ in range(rng.randrange(1, 4)):
        if not chars:
            break
        op = rng.choice(["replace", "insert", "delete", "swap"])
        i = rng.randrange(0, len(chars))
        if op == "replace":
            chars[i] = rng.choice(alphabet)
        elif op == "insert":
            chars.insert(i, rng.choice(alphabet))
        elif op == "delete":
            del chars[i]
        elif i + 1 < len(chars):
            chars[i], chars[i + 1] = chars[i + 1], chars[i]
    return "".join(chars)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=SEED_DEFAULT)
    ap.add_argument("--count", type=int, default=3000)
    args = ap.parse_args()
    rng = random.Random(args.seed)

    print("building...", flush=True)
    build = subprocess.run(
        ["lake", "build"], cwd=ROOT, capture_output=True, text=True,
        timeout=BUILD_TIMEOUT,
    )
    if build.returncode != 0:
        print(build.stdout[-3000:])
        print(build.stderr[-3000:])
        return 1

    sections = []  # (name, requests, expected)
    failures = []
    problems = []

    def section(name, pairs):
        sections.append((name, [r for r, _ in pairs], [e for _, e in pairs]))

    fixed_parse = [(parse_request(t), expected_parse_answer(t)) for t in VALID + INVALID]
    fixed_parse.append(("parse", "none"))
    fixed_parse.append(("parse ", "none"))
    section("fixed parse cases", fixed_parse)

    fixed_fields = [(fields_request(t), expected_fields_answer(t)) for t in VALID + INVALID]
    section("fixed fields cases", fixed_fields)

    vals = module_values(rng, args.count)
    texts = [str(u) for u in vals]
    section(
        "python uuid values, parse",
        [(parse_request(t), "ok:" + codes(t)) for t in texts],
    )
    section(
        "python uuid values, fields",
        [(fields_request(t), expected_fields_answer(t)) for t in texts],
    )

    base = texts[: args.count // 2]
    mutated_parse = []
    mutated_fields = []
    for t in base:
        m = mutate(rng, t)
        mutated_parse.append((parse_request(m), expected_parse_answer(m)))
        mutated_fields.append((fields_request(m), expected_fields_answer(m)))
    section("mutated texts, parse", mutated_parse)
    section("mutated texts, fields", mutated_fields)

    soup = []
    soup_alphabet = "0123456789abcdefABCDEF-gz{} "
    for _ in range(args.count // 2):
        n = rng.randrange(30, 43)
        text = "".join(rng.choice(soup_alphabet) for _ in range(n))
        soup.append((parse_request(text), expected_parse_answer(text)))
    section("soup texts, parse", soup)

    section("malformed requests", [(line, "error") for line in MALFORMED])

    lines_out = []
    lines_out.append("# Test results")
    lines_out.append("")
    lines_out.append(
        "Written by `tests/run_tests.py`. Rerun it to check these numbers."
    )
    lines_out.append("")
    lean_version = subprocess.run(
        ["lake", "env", "lean", "--version"], cwd=ROOT,
        capture_output=True, text=True,
    ).stdout.strip()
    lines_out.append(
        f"- Oracles: Python {platform.python_version()} `uuid` module for values "
        "and canonical printing, plus a strict reading of the plan rules "
        "written in `tests/run_tests.py` for accept and reject"
    )
    lines_out.append(f"- Lean: {lean_version}")
    lines_out.append(f"- Seed: {args.seed}")
    lines_out.append(
        "- This Python has no uuid7 generator, so version 7 values are "
        "covered by byte built values with that version nibble set"
    )
    lines_out.append("")

    total_inputs = 0
    total_agree = 0
    for name, requests, expected in sections:
        answers = []
        for i in range(0, len(requests), CHUNK):
            chunk_answers, problem = run_tool(requests[i:i + CHUNK])
            if problem:
                problems.append(f"{name}: {problem}")
                chunk_answers = ["<no answer>"] * (len(requests[i:i + CHUNK]))
            answers.extend(chunk_answers)
        agree = 0
        for req, exp, ans in zip(requests, expected, answers):
            total_inputs += 1
            if ans == exp:
                agree += 1
                total_agree += 1
            elif len(failures) < 25:
                failures.append(f"{name}: request {req!r}: expected {exp!r}, got {ans!r}")
        lines_out.append(f"- {name}: {len(requests)} inputs, {agree} agreements")
    lines_out.append(f"- Total: {total_inputs} inputs, {total_agree} agreements")
    fail_count = total_inputs - total_agree
    lines_out.append(f"- Failures: {fail_count}")
    if problems:
        lines_out.append(f"- Tool problems: {len(problems)}")
    if failures or problems:
        lines_out.append("")
        lines_out.append("## Failures and problems")
        lines_out.append("")
        for f in (problems + failures)[:25]:
            lines_out.append(f"- {f}")
    lines_out.append("")
    RESULTS.write_text("\n".join(lines_out), encoding="utf-8")
    print("\n".join(lines_out))
    return 0 if fail_count == 0 and not problems else 1


if __name__ == "__main__":
    sys.exit(main())
