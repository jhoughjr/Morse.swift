
public struct Morse {
    static let loggerID = "Morse"
    
    public protocol MorseCodable: CaseIterable {
        static var name: String { get }
        func toMorse() -> String
        func comparator() -> String
    }

    // Shared punctuation table used by both encode and decode paths.
    static let punctuationToMorse: [String: String] = [
        ".": ".-.-.-", ",": "--..--", "?": "..--..", "'": ".----.",
        "!": "-.-.--", "/": "-..-.", "(": "-.--.", ")": "-.--.-",
        "&": ".-...", ":": "---...", ";": "-.-.-.", "=": "-...-",
        "+": ".-.-.", "-": "-....-", "_": "..--.-", "\"": ".-..-.",
        "$": "...-..-", "@": ".--.-."
    ]

    //MARK -- Functions
    static public func KnownCodes() -> [any MorseCodable.Type] {
        [
            LatinCharacters.self,
            ArabicNumerals.self,
        ]
    }
    
    static public func isTextMorse(_ input: String) -> Bool {
        var flag = false
        input.forEach { c in
            flag = Symbols.allCases.filter({ $0.rawValue == String(c) }).count == input.count
        }
        return flag
    }
    
    static public func isTextLatin(_ input: String) -> Bool {
        var flag = false
        input.forEach { c in
            flag = LatinCharacters.allCases.filter({ $0.comparator() == String(c) }).count == input.count
        }
        return flag
    }
    
    static public func latinWords(from input: String) -> [String] {
        input.split(separator: " ").map { $0.uppercased() }
    }
    
    static public func morseWords(from input: String) -> [String] {
        input.split(separator: Symbols.wordSpace.rawValue).map { $0.uppercased() }
    }
    
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
            phrase.words.append(sword)
        }
        return phrase
    }
    
    /// Encodes a latin/numeric/punctuation string to morse code.
    static public func morse(from input: String, verbose: Bool = false) -> String {
        let words = latinWords(from: input)
        var builtWords: [String] = []
        for word in words {
            var letters: [String] = []
            for inputChar in word {
                let s = String(inputChar)
                if let lc = LatinCharacters.allCases.first(where: { $0.comparator() == s }) {
                    letters.append(lc.toMorse())
                } else if let an = ArabicNumerals.allCases.first(where: { $0.comparator() == s }) {
                    letters.append(an.toMorse())
                } else if let p = punctuationToMorse[s] {
                    letters.append(p)
                }
                // unknown characters are silently skipped
            }
            if !letters.isEmpty {
                builtWords.append(letters.joined(separator: Symbols.letterSpace.rawValue))
            }
        }
        return builtWords.joined(separator: Symbols.wordSpace.rawValue)
    }
    
    /// Decodes a morse code string back to latin text.
    static public func latin(from morse: String, verbose: Bool = false) -> String {
        let morseToPunct = Dictionary(uniqueKeysWithValues: punctuationToMorse.map { ($1, $0) })
        var built = ""
        let words = morseWords(from: morse)
        for word in words {
            let letters = word.split(separator: Symbols.letterSpace.rawValue)
            for unknownLetter in letters {
                let ls = String(unknownLetter)
                if let lc = LatinCharacters.allCases.first(where: { $0.toMorse() == ls }) {
                    built += lc.rawValue
                } else if let an = ArabicNumerals.allCases.first(where: { $0.toMorse() == ls }) {
                    built += an.comparator()
                } else if let p = morseToPunct[ls] {
                    built += p
                }
            }
            built += " "
        }
        return built
    }

    //MARK -- Enums
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
            switch self {
            case .ONE:   return ".----"
            case .TWO:   return "..---"
            case .THREE: return "...--"
            case .FOUR:  return "....-"
            case .FIVE:  return "....."
            case .SIX:   return "-...."
            case .SEVEN: return "--..."
            case .EIGHT: return "---.."
            case .NINE:  return "----."
            case .ZERO:  return "-----"
            }
        }
    }

    public enum LatinCharacters: String, CaseIterable, MorseCodable {
        static public let name = "LatinCharacters"
        case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, SPACE,
            DOT, DASH

        public func comparator() -> String {
            self != .SPACE ? self.rawValue : Symbols.letterSpace.rawValue
        }

        public func toMorse() -> String {
            switch self {
            case .A: return ".-"
            case .B: return "-..."
            case .C: return "-.-."
            case .D: return "-.."
            case .E: return "."
            case .F: return "..-."
            case .G: return "--."
            case .H: return "...."
            case .I: return ".."
            case .J: return ".---"
            case .K: return "-.-"
            case .L: return ".-.."
            case .M: return "--"
            case .N: return "-."
            case .O: return "---"
            case .P: return ".--."
            case .Q: return "--.-"
            case .R: return ".-."
            case .S: return "..."
            case .T: return "-"
            case .U: return "..-"
            case .V: return "...-"
            case .W: return ".--"
            case .X: return "-..-"
            case .Y: return "-.--"
            case .Z: return "--.."
            case .SPACE: return Morse.Symbols.wordSpace.rawValue
            case .DOT:  return ".-.-.-"
            case .DASH: return "-....-"
            }
        }
    }

    public enum Symbols: String, CaseIterable {
        case dit        = "."    // base time unit
        case dah        = "-"    // 3 dits
        case infraSpace = " "    // space within character (1 dit)
        case letterSpace = "   " // space between letters (3 dits)
        case wordSpace  = "       " // space between words (7 dits)
        
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
