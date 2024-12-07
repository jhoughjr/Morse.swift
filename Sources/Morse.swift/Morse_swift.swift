
public struct Morse {
    
    public protocol MorseCodable:CaseIterable {
        static var name: String {get}
        func toMorse() -> String
    }
    
    static public func KnownCodes() -> [any MorseCodable.Type] {
        
        [LatinCharacters.self,
         ArabicNumerals.self,
        ]
    }
    
    static public func morse(from input: String) -> String {
        let upper = input.uppercased()
        var built = ""
        
        for char in upper {
            let chars = LatinCharacters.allCases.filter { c in
                c.rawValue == String(char)
            }
            
            for char in chars {
                built += char.toMorse()
            }
        }
        
        return built
    }
    
    enum ArabicNumerals: String, CaseIterable, MorseCodable {
        static let name = "ArabicNumerals"
        case ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, ZERO
        
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
                case .SPACE: return " "
                case .DOT: return "."
                case .DASH: return "-"
            }
        }
    }
    
    enum Symbols: String {
        case dit = "."             // base time unit
        case dah = "-"             // 3 dits
        case infraSpace = " "      // space within character (1 dit)
        case letterSpace = "   "   // space between letters (3 dits)
        case wordSpace = "       " // space between words (7 dits)
    }
}
