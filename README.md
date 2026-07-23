# Morse.swift

Morse code utilities.

## Encoding

```swift
Morse.morse(from: "hello world")
```

`morse(from:)` returns just the string. When it matters what actually went out —
because you are showing the input beside the audio — use `encode`, which reports
what it could not send instead of dropping it silently:

```swift
let encoded = Morse.encode("hi #5")
encoded.morse       // the transmission
encoded.tokens      // [.character("H"), .character("I"), .character("5")]
encoded.skipped     // ["#"]
encoded.isComplete  // false
```

`tokens` is one entry per character group in `morse`, in order, so a caller can
line text up against the transmission without guessing which characters survived.

## Decoding

```swift
Morse.latin(from: "....   .   .-..   .-..   ---")   // "HELLO"
```

Anything sendable round-trips: `Morse.latin(from: Morse.morse(from: x)) == x.uppercased()`.

## Prosigns

Procedural signals are written `<AR>` — bare letters would be indistinguishable
from sending an A and then an R.

```swift
Morse.encode("TU <SK>").morse
```

Several prosigns share a code with a punctuation mark, because historically they
*are* the same code: `AR` and `+` are both `.-.-.`, `BT` and `=` are both `-...-`.
That ambiguity belongs to the mode, not to this library, so decoding takes a side
explicitly:

```swift
Morse.decode(".-.-.")                  // "+"
Morse.decode(".-.-.", prosigns: true)  // "<AR>"
```

## Lookups and alphabets

```swift
Morse.code(for: "q")                    // "--.-"
Morse.character(for: "--.-")            // "Q"
Morse.characterCodes                    // the whole table
Morse.Alphabet.digits.characters        // ["0", "1", … "9"]
```

`Alphabet` splits the mode into `letters`, `digits` and `punctuation` for anything
that works with part of it — a drill on numbers only, say.

## Timing

Speed is measured against the standard word PARIS, which is 50 dit-lengths long.

```swift
Morse.Timing.ditTime(wpm: 20)     // 0.06
Morse.Timing.wpm(ditTime: 0.06)   // 20
```

Farnsworth timing sends characters at full speed and pads the gaps, so a learner
hears the real rhythm of a letter with time to write it down. This gives the dit
length the *gaps* are measured in:

```swift
Morse.Timing.farnsworthSpaceDitTime(characterWPM: 18, effectiveWPM: 10)
```

With both speeds equal it reduces exactly to `ditTime(wpm:)`, so an ordinary send
is the same arithmetic rather than a special case beside it.
