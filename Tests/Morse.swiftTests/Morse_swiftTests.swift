import Testing
@testable import Morse_swift

@Test func testLatinCharactersAndArabicNumeralsAreKnownCodes() {
    #expect(
        Morse.KnownCodes().map({ codable in
            codable.name
        }) == ["LatinCharacters","ArabicNumerals"]
    )
}

@Test func testEisDit() {
    #expect(
        Morse.morse(from: "E") == Morse.Symbols.dit.rawValue
    )
}

@Test func testUppercasedInput() {

    #expect(
        Morse.morse(from: "e") == Morse.Symbols.dit.rawValue
    )
}

@Test func testSOS() {
    #expect(
        Morse.morse(from: "sos") == Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue +
                                    Morse.Symbols.dah.rawValue + Morse.Symbols.dah.rawValue + Morse.Symbols.dah.rawValue +
                                    Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue
    )
}
