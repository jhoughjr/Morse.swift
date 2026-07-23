import Testing
@testable import Morse

// MARK: - Known codes

@Test func testLatinCharactersAndArabicNumeralsAreKnownCodes() {
    #expect(
        Morse.KnownCodes().map({ codable in
            codable.name
        }) == ["LatinCharacters","ArabicNumerals"]
    )
}

// MARK: - Encoding

@Test func testEisDit() {
    #expect(Morse.morse(from: "E") == Morse.Symbols.dit.rawValue)
}

@Test func testUppercasedInput() {
    #expect(Morse.morse(from: "e") == Morse.Symbols.dit.rawValue)
}

/// Letters are separated by a letter space. This used to expect `...---...` —
/// three characters run together with no gap — which is a different
/// transmission, and one that decodes as a single unknown symbol.
@Test func testSOS() {
    let letterSpace = Morse.Symbols.letterSpace.rawValue
    #expect(Morse.morse(from: "sos") == "..." + letterSpace + "---" + letterSpace + "...")
}

@Test func testSOSphrase() {
    let sos = Morse.morse(from: "sos")
    #expect(Morse.morse(from: "sos sos") == sos + Morse.Symbols.wordSpace.rawValue + sos)
}

@Test func testNumbersAndPunctuationEncode() {
    #expect(Morse.morse(from: "5") == ".....")
    #expect(Morse.morse(from: "?") == "..--..")
    #expect(Morse.morse(from: "/") == "-..-.")
}

@Test func testEveryTableEntryEncodes() {
    for character in Morse.characterCodes.keys {
        #expect(Morse.morse(from: String(character)) == Morse.characterCodes[character],
                "\(character) did not encode to its own code")
    }
}

// MARK: - Decoding

/// The decoded text used to carry a trailing space, so nothing round-tripped.
@Test func testLatinFromMorse() {
    #expect(Morse.latin(from: Morse.morse(from: "hello world")) == "HELLO WORLD")
}

/// `LatinCharacters.DOT` and `.DASH` answered with their own case names and the
/// decoder appended that answer directly, so a full stop came back as "DOT".
@Test func testPunctuationDecodesToPunctuation() {
    #expect(Morse.latin(from: ".-.-.-") == ".")
    #expect(Morse.latin(from: "-....-") == "-")
    #expect(Morse.latin(from: Morse.morse(from: "a.b")) == "A.B")
}

@Test func testRoundTripsForEverythingSendable() {
    let samples = ["HELLO WORLD", "SOS", "CQ DE W4ABC", "RST 599", "IT'S 5/9!",
                   "A.B,C?D", "73 & 88", "@ $ = + - _ ( ) : ;"]
    for sample in samples {
        #expect(Morse.latin(from: Morse.morse(from: sample)) == sample,
                "\(sample) did not survive the round trip")
    }
}

@Test func testUnknownCodeDecodesToNothingRatherThanGarbage() {
    #expect(Morse.latin(from: "........-") == "")
}

// MARK: - Skipped characters

/// Encoding used to drop what it couldn't send and say nothing, so a caller
/// showing the input beside the audio displayed characters never transmitted.
@Test func testEncodeReportsWhatItCouldNotSend() {
    let encoded = Morse.encode("a#b")

    #expect(encoded.morse == Morse.morse(from: "ab"))
    #expect(encoded.skipped == ["#"])
    #expect(encoded.isComplete == false)
    #expect(encoded.tokens.map(\.text) == ["A", "B"])
}

@Test func testEncodeReportsNothingSkippedForCleanInput() {
    let encoded = Morse.encode("hello world")

    #expect(encoded.isComplete)
    #expect(encoded.tokens.count == 10)
    #expect(encoded.tokens.map(\.text).joined() == "HELLOWORLD")
}

// MARK: - Prosigns

@Test func testProsignEncodesAsOneSymbol() {
    let encoded = Morse.encode("<AR>")

    #expect(encoded.morse == ".-.-.")
    #expect(encoded.tokens == [.prosign(.AR)])
    #expect(encoded.isComplete)
}

@Test func testProsignInAPhrase() {
    let encoded = Morse.encode("TU <SK>")

    #expect(encoded.tokens == [.character("T"), .character("U"), .prosign(.SK)])
    #expect(encoded.morse.hasSuffix("...-.-"))
}

/// A prosign is not the letters it is named after: `<AR>` is one symbol, `AR`
/// is two with a gap between them.
@Test func testProsignIsNotItsLetters() {
    #expect(Morse.encode("<AR>").morse != Morse.encode("AR").morse)
}

@Test func testUnknownProsignTokenIsReportedNotDropped() {
    let encoded = Morse.encode("<ZZ>")

    #expect(encoded.skipped.contains("<"))
    #expect(encoded.skipped.contains(">"))
}

@Test func testProsignsOffTreatsBracketsAsUnsendable() {
    let encoded = Morse.encode("<AR>", prosigns: false)

    #expect(encoded.skipped.contains("<"))
    #expect(encoded.tokens.map(\.text) == ["A", "R"])
}

/// Some prosigns share a code with a punctuation mark — they *are* the same
/// code — so the decoder has to be told which reading is wanted.
@Test func testSharedCodesDecodeEitherWay() {
    #expect(Morse.decode(".-.-.") == "+")
    #expect(Morse.decode(".-.-.", prosigns: true) == "<AR>")
    #expect(Morse.decode("-...-") == "=")
    #expect(Morse.decode("-...-", prosigns: true) == "<BT>")
}

/// A prosign with no punctuation twin decodes to itself without being asked.
@Test func testUnsharedProsignDecodesWithoutAsking() {
    #expect(Morse.decode("...-.-") == "<SK>")
}

@Test func testEveryProsignRoundTrips() {
    for prosign in Morse.Prosign.allCases {
        let encoded = Morse.encode(prosign.token)
        #expect(encoded.morse == prosign.code, "\(prosign) encoded wrong")
        #expect(Morse.decode(encoded.morse, prosigns: true) == prosign.token,
                "\(prosign) did not survive the round trip")
    }
}

// MARK: - Alphabets

@Test func testAlphabetsCoverTheTableWithoutOverlapping() {
    let letters = Set(Morse.Alphabet.letters.characters)
    let digits = Set(Morse.Alphabet.digits.characters)
    let punctuation = Set(Morse.Alphabet.punctuation.characters)

    #expect(letters.count == 26)
    #expect(digits.count == 10)
    #expect(letters.isDisjoint(with: digits))
    #expect(letters.isDisjoint(with: punctuation))
    #expect(digits.isDisjoint(with: punctuation))
    #expect(letters.union(digits).union(punctuation) == Set(Morse.characterCodes.keys))
}

@Test func testLookupsAgreeWithEachOther() {
    for (character, code) in Morse.characterCodes {
        #expect(Morse.code(for: character) == code)
        #expect(Morse.character(for: code) == character)
    }
    #expect(Morse.code(for: "e") == ".")     // lookup is case-insensitive
    #expect(Morse.code(for: "#") == nil)
}

// MARK: - Predicates

/// Both predicates overwrote their answer once per character, so only the last
/// one counted — and they compared a per-character match count against the
/// length of the whole string, so they answered false for valid input as well.
@Test func testIsTextMorse() {
    #expect(Morse.isTextMorse("..."))
    #expect(Morse.isTextMorse("...   ---   ..."))
    #expect(Morse.isTextMorse("hello") == false)
    #expect(Morse.isTextMorse("") == false)
}

@Test func testIsTextLatin() {
    #expect(Morse.isTextLatin("hello"))
    #expect(Morse.isTextLatin("hello world"))
    #expect(Morse.isTextLatin("5/9"))
    #expect(Morse.isTextLatin("hello #world") == false)
    #expect(Morse.isTextLatin("") == false)
}

// MARK: - Enums

@Test func testEnumsAgreeWithTheTable() {
    for latin in Morse.LatinCharacters.allCases where latin != .SPACE {
        #expect(latin.toMorse() == Morse.code(for: Character(latin.comparator())),
                "\(latin) disagrees with the table")
    }
    for numeral in Morse.ArabicNumerals.allCases {
        #expect(numeral.toMorse() == Morse.code(for: Character(numeral.comparator())))
    }
}

// MARK: - Timing

@Test func testSYmbolTimings() {
    #expect(Morse.Symbols.Timings()[Morse.Symbols.dit.rawValue] == Morse.Symbols.ditTime())
    #expect(Morse.Symbols.Timings()[Morse.Symbols.dah.rawValue] == 3 * Morse.Symbols.ditTime())
    #expect(Morse.Symbols.Timings()[Morse.Symbols.infraSpace.rawValue] == Morse.Symbols.ditTime())
    #expect(Morse.Symbols.Timings()[Morse.Symbols.letterSpace.rawValue] == 3 * Morse.Symbols.ditTime())
    #expect(Morse.Symbols.Timings()[Morse.Symbols.wordSpace.rawValue] == 7 * Morse.Symbols.ditTime())
}

@Test func testWPMIsMeasuredAgainstPARIS() {
    #expect(abs(Morse.Timing.ditTime(wpm: 20) - 0.06) < 1e-9)
    #expect(abs(Morse.Timing.wpm(ditTime: 0.06) - 20) < 1e-9)
}

/// The property that keeps an ordinary send honest rather than merely close:
/// with both speeds equal, the Farnsworth arithmetic *is* the plain arithmetic.
@Test func testFarnsworthDegeneratesToPlainTiming() {
    for wpm in [10.0, 13.0, 18.0, 25.0, 35.0] {
        let spacing = Morse.Timing.farnsworthSpaceDitTime(characterWPM: wpm, effectiveWPM: wpm)
        #expect(abs(spacing - Morse.Timing.ditTime(wpm: wpm)) < 1e-9,
                "spacing diverged at \(wpm) wpm")
    }
}

@Test func testFarnsworthStretchesGapsOnly() {
    let spacing = Morse.Timing.farnsworthSpaceDitTime(characterWPM: 20, effectiveWPM: 10)
    #expect(spacing > Morse.Timing.ditTime(wpm: 20))
}

@Test func testSpacingNeverOutrunsTheCharacters() {
    let spacing = Morse.Timing.farnsworthSpaceDitTime(characterWPM: 15, effectiveWPM: 30)
    #expect(abs(spacing - Morse.Timing.ditTime(wpm: 15)) < 1e-9)
}

@Test func testDegenerateSpeedsDoNotProduceNonsense() {
    #expect(Morse.Timing.ditTime(wpm: 0) > 0)
    #expect(Morse.Timing.farnsworthSpaceDitTime(characterWPM: 0, effectiveWPM: 0) > 0)
    #expect(Morse.Timing.farnsworthSpaceDitTime(characterWPM: 20, effectiveWPM: 0) > 0)
}

// MARK: - Words

@Test func testWordSplitting() {
    #expect(Morse.latinWords(from: "hello world") == ["HELLO", "WORLD"])
    #expect(Morse.morseWords(from: Morse.morse(from: "sos sos")).count == 2)
}
