@preconcurrency import Lullaby
import LullabyMusic
import LullabyMiniAudioEngine

public struct Morse {
    
    public protocol MorseCodable:CaseIterable {
        static var name: String {get}
        func toMorse() -> String
        func comparator() -> String
    }

    //MARK -- Functions
    static public func KnownCodes() -> [any MorseCodable.Type] {
        
        [LatinCharacters.self,
         ArabicNumerals.self,
        ]
    }
    static public func isTextMorse(_ input: String) -> Bool {
        // not optimal
        var flag = false
        input.forEach { c in
            flag =  Symbols.allCases.filter({ c2 in
                return c2.rawValue == String(c)
            }).count == input.count
            
        }
        return flag
    }
    static public func isTextLatin(_ input: String) -> Bool {
        var flag = false
        input.forEach { c in
            flag = LatinCharacters.allCases.filter({ c2 in
                return c2.comparator() == String(c)
            }).count == input.count
        }
        return flag
    }
    static public func morse(from input: String, verbose: Bool = false) -> String {
        let upper = input.uppercased()
        var built = ""
        
        for char in upper {
            let chars = LatinCharacters.allCases.filter { c in
                c.comparator() == String(char)
            }
           
            for char in chars {
                built += char.toMorse() + Symbols.letterSpace.rawValue
            }
        }
        
        return built
    }
    static public func latin(from morse: String, verbose: Bool = false) -> String {
        var built = ""
        
        let splitByWords = morse.split(separator: Symbols.wordSpace.rawValue)
        for word in splitByWords {
            if verbose {print("Checking word \(word) in morse")}
            
            let letters = word.split(separator: Symbols.letterSpace.rawValue)
            for unknownLetter in letters {
                for letter in LatinCharacters.allCases.filter({ c in
                    if c == .DOT {
                        return false
                    }
                    if c == .DASH {
                        return false
                    }
                    return true
                }) {
//                    print("checking \(unknownLetter) : for morse letter \(letter.rawValue)")
                    if letter.toMorse() == unknownLetter {
                        if verbose {print("\(unknownLetter) is \(letter)")}
                        
                        built += letter.rawValue
                    }
                }
            }
            built += " "
        }
        
       
        
        return built.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    enum LatinCharacters: String, CaseIterable, MorseCodable {
        static let name = "LatinCharacters"
        case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, SPACE, DOT, DASH
        
        func comparator() -> String {
            if self != .SPACE {
                return self.rawValue
            }else {
                return " "
            }
            
        }
        
        func toMorse() -> String {
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
                case .SPACE: return "       "
                case .DOT: return "."
                case .DASH: return "-"
            }
        }
    }
    
    public enum Symbols: String, CaseIterable {
        case dit = "."             // base time unit
        case dah = "-"             // 3 dits
        case infraSpace = " "      // space within character (1 dit)
        case letterSpace = "   "   // space between letters (3 dits)
        case wordSpace = "       " // space between words (7 dits)
        static public func ditTime() -> Double {
            0.2
        }
        static public func Timings() -> [String:Double] {
            [Symbols.dit.rawValue : ditTime(),
             Symbols.dah.rawValue : 3 * ditTime(),
             Symbols.infraSpace.rawValue : ditTime(),
             Symbols.letterSpace.rawValue : 3 * ditTime(),
             Symbols.wordSpace.rawValue : 7 * ditTime()]
        }
    }
    
    //MARK -- Structures
    public struct Tone {
        
        public struct Test {
            
            public static func sineTest() async throws {
                let value = Value(value: 440)
                
                let carrier = await sine(frequency: value.output)
                
                let task = Task {
                    for i in twelveToneEqualTemperamentTuning.pitches {
                        await value.setValue(Sample(i * 440))
                        await Task.sleep(seconds: 0.5)
                    }
                    
                    return
                }
                
                let engine = try await MiniAudioEngine()
                
                engine.setOutput(to: carrier)
                try engine.prepare()
                try engine.start()
                
                await task.value
                
                try engine.stop()
            }
            
        }
        
        static public func test() -> Bool {
          let task =  Task(operation: Test.sineTest)
            
            task.cancel()
            return true
        }
    }
    
    
}
