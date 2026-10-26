/-
  Command line front end, used by the tests.

  Reads one request per line and prints one answer per line. A
  request is an operation and its input as comma-separated
  decimal character codes.

    parse 102,56,49,100,...      prints  ok:102,56,49,100,...
    fields 102,56,49,100,...     prints  ok:49,44,49

  The operations are `parse` and `fields`.

  `parse` takes the character codes of one UUID text. Its
  answer is `ok:` and the character codes of the canonical
  print of the parsed value, or `none` when the text is
  rejected.

  `fields` takes the same input. Its answer is `ok:` and the
  character codes of a short text holding the version number,
  a comma, and the variant number: for the RFC example value
  the text is `1,1`, version 1 and variant 1 (the RFC 9562
  variant), so the answer is `ok:49,44,49`. A text that is
  rejected answers `none`, as with `parse`.

  A request is an operation, then optionally one space and its
  numbers; with no numbers after the space, the input is empty.
  A malformed request prints `error`: any other line, an
  unknown operation, a number that is not plain decimal digits,
  or a character code that is not a Unicode scalar value. A
  line may end in LF or CR LF; nothing else around a request
  is ignored.

  The parsing, printing, and field readings here call
  `Uuid.parse`, `Uuid.print`, `Uuid.version`, and `Uuid.variant`
  directly. The line handling is covered by the tests, not by
  a proof.
-/

import Uuid

open Uuid

/-- A number in plain decimal digits. Longer numbers than any
    character code are refused before they are converted, since
    that takes time quadratic in their length. -/
def number (t : String) : Option Nat :=
  let ds := t.toList
  if ds.isEmpty || !ds.all Char.isDigit || (ds.dropWhile (· = '0')).length > 7 then none
  else t.toNat?

/-- The comma-separated numbers in `s`. -/
def numbers (s : String) : Option (List Nat) :=
  if s.isEmpty then some [] else (s.splitOn ",").mapM number

def toChars (ns : List Nat) : Option (List Char) :=
  ns.mapM fun n => if n.isValidChar then some (Char.ofNat n) else none

def showCodes (cs : List Char) : String :=
  ",".intercalate (cs.map fun c => toString c.toNat)

/-- The answer to one request, or `none` when the request is
    malformed. -/
def answer (op : String) (ns : List Nat) : Option String :=
  match op with
  | "parse" =>
    match toChars ns with
    | none => none
    | some cs =>
      match parse cs with
      | some bs => some ("ok:" ++ showCodes (print bs))
      | none => some "none"
  | "fields" =>
    match toChars ns with
    | none => none
    | some cs =>
      match parse cs with
      | some bs =>
        let text := (toString (version bs) ++ "," ++
          toString (variantNumber (variant bs))).toList
        some ("ok:" ++ showCodes text)
      | none => some "none"
  | _ => none

/-- The answer to one line: an operation, then optionally one space
    and its numbers. -/
def request (line : String) : Option String :=
  match line.splitOn " " with
  | [op] => answer op []
  | [op, arg] => numbers arg >>= answer op
  | _ => none

/-- The line without its line ending: LF, or CR LF. -/
def chomp (line : String) : String :=
  let cs := line.toList
  if cs.getLast? = some '\n' then
    let cs := cs.dropLast
    String.ofList (if cs.getLast? = some '\r' then cs.dropLast else cs)
  else line

def main : IO Unit := do
  let stdin ← IO.getStdin
  let stdout ← IO.getStdout
  repeat
    let line ← stdin.getLine
    if line.isEmpty then break
    let line := chomp line
    stdout.putStrLn ((request line).getD "error")
