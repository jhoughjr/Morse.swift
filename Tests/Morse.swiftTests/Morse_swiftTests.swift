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

   
func notABadWord() -> String {
    Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue +
    Morse.Symbols.dah.rawValue + Morse.Symbols.dah.rawValue + Morse.Symbols.dah.rawValue +
    Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue +
    Morse.Symbols.wordSpace.rawValue + Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue +  Morse.Symbols.dah.rawValue + Morse.Symbols.dah.rawValue + Morse.Symbols.dah.rawValue +
    Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue + Morse.Symbols.dit.rawValue
}
    
@Test func testSOSphrase() {
    #expect(
        Morse.morse(from: "sos sos") == notABadWord()
    )
}

@Test func testSYmbolTimings() {
    #expect(
        Morse.Symbols.Timings()[Morse.Symbols.dit.rawValue] == Morse.Symbols.ditTime()
    )
    #expect(
        Morse.Symbols.Timings()[Morse.Symbols.dah.rawValue] == 3 * Morse.Symbols.ditTime()
    )
    #expect(
        Morse.Symbols.Timings()[Morse.Symbols.infraSpace.rawValue] == Morse.Symbols.ditTime()
    )
    #expect(
        Morse.Symbols.Timings()[Morse.Symbols.letterSpace.rawValue] == 3 * Morse.Symbols.ditTime()
    )
    #expect(
        Morse.Symbols.Timings()[Morse.Symbols.wordSpace.rawValue] == 7 * Morse.Symbols.ditTime()
    )
}

@Test func testSound() {
    #expect(
        Morse.Tone().test()
    )
    

}
