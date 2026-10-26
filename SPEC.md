# Specification: uuid

A UUID parser and printer in Lean, following RFC 9562. A reviewer who did not write this specification approves it, together with any statement file a reviewer adds later. No such file exists yet, so nothing here counts toward the verified bar yet.

Text is `List Char`. A value is sixteen bytes, a `List UInt8`.

## The value and its layout

A UUID is 128 bits, held here as sixteen bytes in the order the RFC text writes them: the first byte of the text is byte 0, and the last is byte 15.

Two readings come with the value:

- The version is the high four bits of the seventh byte (byte 6). It is a number from 0 to 15; the RFC gives names and layouts to versions 1 to 8, and this library only reads the number.
- The variant is named by the top bits of the ninth byte (byte 8), as the table in RFC 9562 section 4.1 lays out:

  | Top bits of byte 8 | Variant | Number |
  |--------------------|---------|--------|
  | 0xxxxxxx | NCS | 0 |
  | 10xxxxxx | RFC 9562 | 1 |
  | 110xxxxx | Microsoft | 2 |
  | 111xxxxx | future use | 3 |

Two values are named: the nil UUID, all sixteen bytes zero, and the max UUID, all sixteen bytes 255.

## The text form

The printer writes the canonical form:

- five groups of lowercase hex digits, of lengths 8, 4, 4, 4, and 12;
- the groups split by single hyphens, at character positions 8, 13, 18, and 23;
- 36 characters in all. Each byte is two digits, the high digit first.

The parser reads that shape:

- A hex digit may be a decimal digit, a letter from a to f, or a letter from A to F. Case on input does not change the value, and the printer always writes lowercase, so an upper case spelling reprints in lowercase.
- Anything else is turned away: a text of any other length, a hyphen anywhere but the four places above, a hyphen where a digit belongs, a character outside hex in a digit place, and any text after the last digit.

The brace form (`{...}`), the URN form (`urn:uuid:...`), and the form with no hyphens (32 digits) are not read. They sit outside this slice, so all three are turned away like any other text of the wrong shape.

## The claim

The proved claim is a round trip: for every well formed value, parsing what the printer wrote returns the same value. Well formed means the value holds sixteen bytes. The parser always returns a well formed value.

The named values and the examples printed in RFC 9562 are proved as fixed facts by computation: the nil value prints as the all zero text, the max value prints as the all f text, and the RFC example values carry the versions and variants the RFC gives them.

No claim is made that the parser accepts every text the rules above allow, or rejects every text they forbid, beyond what the round trip needs. The test suite checks that behaviour against Python's `uuid` module and against a strict reading of the rules above, and the results record the counts.

## The command-line tool

`Main.lean` reads one request per line. A request is an operation, a space, and the character codes of a UUID text as comma-separated decimal numbers. Two operations:

- `parse`: the answer is `ok:` followed by the character codes of the canonical print of the parsed value, or `none` when the text is rejected.
- `fields`: the answer is `ok:` followed by the character codes of a short text holding the version number, a comma, and the variant number. For the RFC example value `f81d4fae-7dec-11d0-a765-00a0c91e6bf6` the text is `1,1`, so the answer is `ok:49,44,49`. A rejected text answers `none`.

A request with no numbers after the space has the empty text as input. A malformed request line prints `error`: an unknown operation, a number that is not plain decimal digits, or a code that is not a Unicode scalar value. A line may end in LF or CR LF.
