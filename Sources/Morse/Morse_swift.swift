
public struct Morse {
    static let loggerID = "Morse"
    
    public protocol MorseCodable: CaseIterable {
        static var name: String { get }
        func toMorse() -> String
        func comparator() -> String
    }

    //MARK -- Functions
    static public func KnownCodes() -> [any MorseCodable.Type] {

        [
            LatinCharacters.self,
            ArabicNumerals.self,
        ]
    }
    
    static public func isTextMorse(_ input: String) -> Bool {
        // not optimal
        var flag = false
        input.forEach { c in
            flag =
                Symbols.allCases.filter({ c2 in
                    return c2.rawValue == String(c)
                }).count == input.count

        }
        return flag
    }
    
    static public func isTextLatin(_ input: String) -> Bool {
        var flag = false
        input.forEach { c in
            flag =
                LatinCharacters.allCases.filter({ c2 in
                    return c2.comparator() == String(c)
                }).count == input.count
        }
        return flag
    }
    
    static public func words(from input: String) -> [String] {
        input.split(separator: " ").map({$0.uppercased()})
    }
    
    public struct StructuredMorseLetter {
        public let latin: LatinCharacters
        public let morse:String
    }
    
    public struct StructuredMorsePhrase {
        public var input:String = ""
        public var words:[StructuredMorseWord] = [StructuredMorseWord]()
        public var morse:String = ""
    }
    
    public struct StructuredMorseWord {
        public var input:String = ""
        public var letters:[StructuredMorseLetter] = [StructuredMorseLetter]()
        public var morse:String = ""
    }
    
    static public func structuredMorse(from input: String,
                                       verbose: Bool = true) -> StructuredMorsePhrase {
        print("\(loggerID)|structuredMorse from input= \(input)")
        // need to break into words first
        let latinWords = words(from: input)
        print("\(loggerID)|  \(latinWords.count) words")
        
        var structuredPhrase = StructuredMorsePhrase()
        structuredPhrase.input = input
        
        var builtPhrase:String  = ""
        for word in latinWords {
            var builtWord = ""
            
            if verbose { print("\(loggerID)| Checking word \(word) in latin") }
            let upper = word.uppercased()
            var sword = StructuredMorseWord()
            sword.input = word
            
            for char in upper {
                
                let chars = LatinCharacters.allCases.filter { c in
                    let match = c.comparator() == String(char)
                    return match
                }
                for char in chars {
                    let m = char.toMorse()
                    sword.letters.append(.init(latin: char, morse: m))
                    builtWord += m + Morse.Symbols.letterSpace.rawValue
                }
                
            }
            sword.morse = builtWord
            builtPhrase += builtWord + "       "
            
            structuredPhrase.words.append(sword)
            structuredPhrase.words.append(.init(input: " ",
                                                letters: [.init(latin: Morse.LatinCharacters.SPACE,
                                                                                                              morse: "        ")]))
        }
        
        structuredPhrase.words.removeLast(1) // last word needs no space and this is simplest way.
        structuredPhrase.morse = builtPhrase         // whole phrase morse is whole built output
        return structuredPhrase
    }
    
    static public func morse(from input: String, verbose: Bool = true) -> String {
        print("\(loggerID)| input= \(input)")
        // need to break into words first
        let latinWords = words(from: input)
        print("\(loggerID)|  \(latinWords.count) words")
        
        var built = ""
        for word in latinWords {
            if verbose { print("\(loggerID)| Checking word \(word) in latin") }
            
            let upper = word.uppercased()
            let enumeratedUpper = upper.enumerated()
            
            for inputChar in upper {
                
                let latinChars = LatinCharacters.allCases.filter { c in
                    let match = c.comparator() == String(inputChar)
                    return match
                }
                                
                for char in latinChars {
                    let m = char.toMorse()
                    
                    built += m
                    print("\(loggerID)| +\(m)")
                    // add letterpsace
                    built += Symbols.letterSpace.rawValue
                }
            }
            built += Symbols.wordSpace.rawValue
           //add wordspace
        }
     

        return built
    }
    
    static public func latin(from morse: String, verbose: Bool = false) -> String {
        var built = ""

        let splitByWords = morse.split(separator: Symbols.wordSpace.rawValue)
        for word in splitByWords {
            if verbose { print("Checking word \(word) in morse") }

            let letters = word.split(separator: Symbols.letterSpace.rawValue)
            for unknownLetter in letters {
                for letter in LatinCharacters.allCases.filter({ c in
                    return true
                }) {
                    //                    print("checking \(unknownLetter) : for morse letter \(letter.rawValue)")
                    if letter.toMorse() == unknownLetter {
                        if verbose { print("\(unknownLetter) is \(letter)") }

                        built += letter.rawValue
                    }
                }
            }
            built += " "
        }
        
        return built //.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    //MARK -- Enums
    enum ArabicNumerals: String, CaseIterable, MorseCodable {
        static let name = "ArabicNumerals"
        case ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, ZERO
        func comparator() -> String {
            switch self {

            case .ONE:
                "1"
            case .TWO:
                "2"
            case .THREE:
                "3"
            case .FOUR:
                "4"
            case .FIVE:
                "5"
            case .SIX:
                "6"
            case .SEVEN:
                "7"
            case .EIGHT:
                "8"
            case .NINE:
                "9"
            case .ZERO:
                "0"
            }
        }

        func toMorse() -> String {
            switch self {
            case .ONE: return ".----"
            case .TWO: return "..---"
            case .THREE: return "...--"
            case .FOUR: return "....-"
            case .FIVE: return "....."
            case .SIX: return "-...."
            case .SEVEN: return "--..."
            case .EIGHT: return "---.."
            case .NINE: return "----."
            case .ZERO: return "-----"
            }
        }
    }

    public enum LatinCharacters: String, CaseIterable, MorseCodable {
        static public let name = "LatinCharacters"
        case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, SPACE,
            DOT, DASH

        public func comparator() -> String {
            if self != .SPACE {
//                print("\(loggerID)| comparator> returning \(self.rawValue)")
                return self.rawValue
            } else {
//                print("\(loggerID)| comparator> returning \(Symbols.wordSpace.rawValue)")
                return Symbols.letterSpace.rawValue
            }

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
            case .P: return ".--"
            case .Q: return "--.-"
            case .R: return ".-."
            case .S: return "..."
            case .T: return "-"
            case .U: return "..-"
            case .V: return "...-"
            case .W: return ".--.-"
            case .X: return "-..-"
            case .Y: return "-.--"
            case .Z: return "--.."
            case .SPACE: return Morse.Symbols.wordSpace.rawValue
            case .DOT: return "."
            case .DASH: return "-"
            }
        }
    }

    public enum Symbols: String, CaseIterable {
        
        case dit = "."  // base time unit
        case dah = "-"  // 3 dits
        case infraSpace = " "  // space within character (1 dit)
        case letterSpace = "   "  // space between letters (3 dits)
        case wordSpace = "       "  // space between words (7 dits)
        
        static public func ditTime() -> Double {
            0.1
        }
        
        static public func Timings() -> [String: Double] {
            [
                // base time unit
                Symbols.dit.rawValue: ditTime(),
                Symbols.dah.rawValue: 3 * ditTime(),
                // space between symbols in the same letter
                Symbols.infraSpace.rawValue: ditTime(),
                // space between letters in the same word
                Symbols.letterSpace.rawValue: 3 * ditTime(),
                // space between words
                Symbols.wordSpace.rawValue: 7 * ditTime(),
            ]
        }
    }
}
