
public struct Morse {
    static let loggerID = "Morse"

    public protocol MorseCodable: CaseIterable {
        static var name: String { get }
        func toMorse() -> String
        func comparator() -> String
    }

    // MARK: - The table
    //
    // One source of truth. Encoding, decoding, the enums below and anything a
    // client needs to look up all read from here — previously the same facts were
    // written out three times (an enum switch, a punctuation dictionary, and a
    // reversed copy of it rebuilt on every decode call), which is how the decode
    // path came to disagree with the encode path.

    /// Every single-character token this library can send, and its code.
    public static let characterCodes: [Character: String] = {
        var table: [Character: String] = [:]
        for (character, code) in letterCodes { table[character] = code }
        for (character, code) in digitCodes { table[character] = code }
        for (character, code) in punctuationCodes { table[character] = code }
        return table
    }()

    static let letterCodes: [Character: String] = [
        "A": ".-",   "B": "-...", "C": "-.-.", "D": "-..",  "E": ".",
        "F": "..-.", "G": "--.",  "H": "....", "I": "..",   "J": ".---",
        "K": "-.-",  "L": ".-..", "M": "--",   "N": "-.",   "O": "---",
        "P": ".--.", "Q": "--.-", "R": ".-.",  "S": "...",  "T": "-",
        "U": "..-",  "V": "...-", "W": ".--",  "X": "-..-", "Y": "-.--",
        "Z": "--.."
    ]

    static let digitCodes: [Character: String] = [
        "0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
        "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----."
    ]

    static let punctuationCodes: [Character: String] = [
        ".": ".-.-.-", ",": "--..--", "?": "..--..", "'": ".----.",
        "!": "-.-.--", "/": "-..-.",  "(": "-.--.",  ")": "-.--.-",
        "&": ".-...",  ":": "---...", ";": "-.-.-.", "=": "-...-",
        "+": ".-.-.",  "-": "-....-", "_": "..--.-", "\"": ".-..-.",
        "$": "...-..-", "@": ".--.-."
    ]

    /// Reverse lookup, built once rather than on every decode call.
    static let charactersByCode: [String: Character] = {
        var table: [String: Character] = [:]
        for (character, code) in characterCodes { table[code] = character }
        return table
    }()

    /// The code for a character, or nil when it can't be sent.
    public static func code(for character: Character) -> String? {
        characterCodes[Character(String(character).uppercased())]
    }

    /// The character a code spells, or nil when nothing does.
    public static func character(for code: String) -> Character? {
        charactersByCode[code]
    }

    // MARK: - Prosigns

    /// Procedural signals: two or more letters run together with no gap between
    /// them, sent and heard as a single symbol.
    ///
    /// Several share a code with a punctuation mark, because historically they
    /// *are* the same code — `AR` and `+` are both `.-.-.`, `BT` and `=` are both
    /// `-...-`. The ambiguity is in the mode, not in this library, so decoding
    /// takes a side explicitly rather than pretending one exists.
    public enum Prosign: String, CaseIterable, Sendable {
        case AR    // end of message
        case AS    // wait
        case BT    // break, new section
        case CT    // attention, start of transmission
        case KN    // go ahead, named station only
        case SK    // end of contact
        case SN    // understood
        case BK    // break-in
        case CL    // closing down
        case HH    // error

        public var code: String {
            switch self {
            case .AR: return ".-.-."
            case .AS: return ".-..."
            case .BT: return "-...-"
            case .CT: return "-.-.-"
            case .KN: return "-.--."
            case .SK: return "...-.-"
            case .SN: return "...-."
            case .BK: return "-...-.-"
            case .CL: return "-.-..-.."
            case .HH: return "........"
            }
        }

        /// How a prosign is written in text: `<AR>`. Bare letters would be
        /// indistinguishable from sending an A and then an R.
        public var token: String { "<\(rawValue)>" }
    }

    static let prosignsByCode: [String: Prosign] = {
        var table: [String: Prosign] = [:]
        for prosign in Prosign.allCases where table[prosign.code] == nil {
            table[prosign.code] = prosign
        }
        return table
    }()

    // MARK: - Alphabets

    /// Addressable groups, for anything that works with part of the mode — a
    /// drill on numbers only, say.
    public enum Alphabet: String, CaseIterable, Sendable {
        case letters, digits, punctuation

        public var characters: [Character] {
            switch self {
            case .letters:     return Morse.letterCodes.keys.sorted()
            case .digits:      return Morse.digitCodes.keys.sorted()
            case .punctuation: return Morse.punctuationCodes.keys.sorted()
            }
        }
    }

    // MARK: - Tokens

    /// One sendable unit: a character, or a prosign.
    public enum Token: Hashable, Sendable {
        case character(Character)
        case prosign(Prosign)

        public var code: String {
            switch self {
            case .character(let character): return Morse.code(for: character) ?? ""
            case .prosign(let prosign):     return prosign.code
            }
        }

        /// How this token is written in text.
        public var text: String {
            switch self {
            case .character(let character): return String(character)
            case .prosign(let prosign):     return prosign.token
            }
        }
    }

    // MARK: - Encoding

    /// The result of encoding: the morse, what went into it, and what didn't.
    ///
    /// `skipped` is the point of this type. Encoding used to drop anything it
    /// couldn't send and say nothing about it, so a caller showing the input
    /// beside the audio would display characters that were never transmitted.
    public struct Encoded: Equatable, Sendable {
        public let morse: String
        /// The tokens actually sent, in order — one per character group in `morse`.
        public let tokens: [Token]
        /// Input characters that could not be sent, in the order they appeared.
        public let skipped: [Character]

        public init(morse: String, tokens: [Token], skipped: [Character]) {
            self.morse = morse
            self.tokens = tokens
            self.skipped = skipped
        }

        public var isComplete: Bool { skipped.isEmpty }
    }

    /// Encodes text to morse, reporting what it could and couldn't send.
    /// - Parameter prosigns: recognise `<AR>`-style tokens. With this off the
    ///   angle brackets are ordinary characters — and unsendable ones at that.
    public static func encode(_ input: String, prosigns: Bool = true) -> Encoded {
        var words: [[Token]] = []
        var current: [Token] = []
        var skipped: [Character] = []

        var index = input.startIndex
        while index < input.endIndex {
            let character = input[index]

            if character == " " || character.isNewline {
                if !current.isEmpty { words.append(current); current = [] }
                index = input.index(after: index)
                continue
            }

            if prosigns, character == "<",
               let close = input[index...].firstIndex(of: ">"),
               let prosign = Prosign(rawValue: String(input[input.index(after: index)..<close]).uppercased()) {
                current.append(.prosign(prosign))
                index = input.index(after: close)
                continue
            }

            if code(for: character) != nil {
                current.append(.character(Character(String(character).uppercased())))
            } else {
                skipped.append(character)
            }
            index = input.index(after: index)
        }
        if !current.isEmpty { words.append(current) }

        let morse = words
            .map { word in word.map(\.code).joined(separator: Symbols.letterSpace.rawValue) }
            .joined(separator: Symbols.wordSpace.rawValue)

        return Encoded(morse: morse, tokens: words.flatMap { $0 }, skipped: skipped)
    }

    /// Encodes a latin/numeric/punctuation string to morse code.
    static public func morse(from input: String, verbose: Bool = false) -> String {
        encode(input).morse
    }

    // MARK: - Decoding

    /// Decodes morse back to text.
    /// - Parameter prosigns: resolve codes shared by a prosign and a punctuation
    ///   mark in favour of the prosign, written as `<AR>`.
    public static func decode(_ morse: String, prosigns: Bool = false) -> String {
        morseWords(from: morse)
            .map { word in
                word.split(separator: Symbols.letterSpace.rawValue)
                    .map { letter -> String in
                        let code = String(letter)
                        if prosigns, let prosign = prosignsByCode[code] { return prosign.token }
                        if let character = character(for: code) { return String(character) }
                        if let prosign = prosignsByCode[code] { return prosign.token }
                        return ""
                    }
                    .joined()
            }
            .joined(separator: " ")
    }

    /// Decodes a morse code string back to latin text.
    ///
    /// No longer leaves a trailing space after the last word, so this holds for
    /// anything sendable: `latin(from: morse(from: x)) == x.uppercased()`.
    static public func latin(from morse: String, verbose: Bool = false) -> String {
        decode(morse)
    }

    // MARK: - Predicates

    static public func KnownCodes() -> [any MorseCodable.Type] {
        [
            LatinCharacters.self,
            ArabicNumerals.self,
        ]
    }

    /// True when every character is a morse symbol.
    ///
    /// This used to overwrite its own answer once per character, so only the last
    /// character counted — and it compared a per-character match count against
    /// the length of the whole string, so it answered false for valid input too.
    static public func isTextMorse(_ input: String) -> Bool {
        guard !input.isEmpty else { return false }
        let symbols = Set(Symbols.allCases.flatMap { Array($0.rawValue) })
        return input.allSatisfy { symbols.contains($0) }
    }

    /// True when every character can be sent.
    static public func isTextLatin(_ input: String) -> Bool {
        guard !input.isEmpty else { return false }
        return input.allSatisfy { $0 == " " || code(for: $0) != nil }
    }

    // MARK: - Words

    static public func latinWords(from input: String) -> [String] {
        input.split(separator: " ").map { $0.uppercased() }
    }

    static public func morseWords(from input: String) -> [String] {
        input.split(separator: Symbols.wordSpace.rawValue).map(String.init)
    }

    // MARK: - Structured

    public struct StructuredMorseLetter {
        public let latin: LatinCharacters
        public let morse: String
    }

    public struct StructuredMorsePhrase {
        public var input: String = ""
        public var words: [StructuredMorseWord] = []
        public var morse: String = ""
    }

    public struct StructuredMorseWord {
        public var input: String = ""
        public var letters: [StructuredMorseLetter] = []
        public var morse: String = ""
    }

    static public func structuredMorse(from input: String, verbose: Bool = false) -> StructuredMorsePhrase {
        let words = latinWords(from: input)
        var phrase = StructuredMorsePhrase(input: input)
        for word in words {
            var sword = StructuredMorseWord(input: word)
            for char in word {
                let s = String(char)
                if let lc = LatinCharacters.allCases.first(where: { $0.comparator() == s }) {
                    sword.letters.append(.init(latin: lc, morse: lc.toMorse()))
                }
            }
            sword.morse = sword.letters.map(\.morse).joined(separator: Symbols.letterSpace.rawValue)
            phrase.words.append(sword)
        }
        phrase.morse = phrase.words.map(\.morse).joined(separator: Symbols.wordSpace.rawValue)
        return phrase
    }

    // MARK: - Timing

    /// Speed, in the terms operators actually use.
    ///
    /// Words per minute is measured against the standard word PARIS, which is 50
    /// dit-lengths long — that is where the 1.2 comes from.
    public enum Timing {

        /// Dit length in seconds for a given words-per-minute.
        public static func ditTime(wpm: Double) -> Double {
            guard wpm > 0 else { return Symbols.ditTime() }
            return 1.2 / wpm
        }

        /// Words per minute implied by a dit length.
        public static func wpm(ditTime: Double) -> Double {
            guard ditTime > 0 else { return 0 }
            return 1.2 / ditTime
        }

        /// The dit length the *gaps* are measured in when sending Farnsworth:
        /// characters at full speed, with the extra time added between them.
        ///
        /// Per the ARRL formula. At `effectiveWPM == characterWPM` it reduces
        /// exactly to `ditTime(wpm:)`, so an ordinary send is the same arithmetic
        /// rather than a special case beside it.
        public static func farnsworthSpaceDitTime(characterWPM: Double, effectiveWPM: Double) -> Double {
            guard characterWPM > 0, effectiveWPM > 0 else {
                return ditTime(wpm: max(characterWPM, 1))
            }
            // Spacing can pad a transmission, but never outrun the characters.
            let effective = min(effectiveWPM, characterWPM)
            let total = (60 * characterWPM - 37.2 * effective) / (characterWPM * effective)
            return total / 19
        }
    }

    // MARK: - Enums

    public enum ArabicNumerals: String, CaseIterable, MorseCodable {
        static public let name = "ArabicNumerals"
        case ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, ZERO

        public func comparator() -> String {
            switch self {
            case .ONE:   return "1"
            case .TWO:   return "2"
            case .THREE: return "3"
            case .FOUR:  return "4"
            case .FIVE:  return "5"
            case .SIX:   return "6"
            case .SEVEN: return "7"
            case .EIGHT: return "8"
            case .NINE:  return "9"
            case .ZERO:  return "0"
            }
        }

        public func toMorse() -> String {
            Morse.digitCodes[Character(comparator())] ?? ""
        }
    }

    public enum LatinCharacters: String, CaseIterable, MorseCodable {
        static public let name = "LatinCharacters"
        case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, SPACE,
            DOT, DASH

        /// The text this case stands for.
        ///
        /// `DOT` and `DASH` used to answer with their own case names, and the
        /// decoder appended that answer directly — which is why a full stop came
        /// back as the literal string "DOT".
        public func comparator() -> String {
            switch self {
            case .SPACE: return " "
            case .DOT:   return "."
            case .DASH:  return "-"
            default:     return rawValue
            }
        }

        public func toMorse() -> String {
            if self == .SPACE { return Morse.Symbols.wordSpace.rawValue }
            return Morse.characterCodes[Character(comparator())] ?? ""
        }
    }

    public enum Symbols: String, CaseIterable {
        case dit        = "."    // base time unit
        case dah        = "-"    // 3 dits
        case infraSpace = " "    // space within character (1 dit)
        case letterSpace = "   " // space between letters (3 dits)
        case wordSpace  = "       " // space between words (7 dits)

        /// The default dit length, in seconds. For a speed in words per minute,
        /// use `Morse.Timing.ditTime(wpm:)`.
        static public func ditTime() -> Double { 0.1 }

        static public func Timings() -> [String: Double] {
            [
                Symbols.dit.rawValue:         ditTime(),
                Symbols.dah.rawValue:         3 * ditTime(),
                Symbols.infraSpace.rawValue:  ditTime(),
                Symbols.letterSpace.rawValue: 3 * ditTime(),
                Symbols.wordSpace.rawValue:   7 * ditTime(),
            ]
        }
    }
}
