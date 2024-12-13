//
//  morset.swift
//  Morse.swift
//
//  Created by Jimmy Hough Jr on 12/12/24.
//

import Morse
import ArgumentParser
@main

struct morset: AsyncParsableCommand{
    
    public enum Mode: String, CaseIterable, ExpressibleByArgument{
        case toMorse = "to"
        case fromMorse = "from"
    }
    
    @Argument(help: "Text to convert to or from morse code.")
    var text: String
    
    @Option(name: .shortAndLong, help: "To or from Morse code. Defaults to 'to'.")
    var mode: Mode = .toMorse
    
    static var configuration: CommandConfiguration{
        CommandConfiguration(
            commandName: "morset",
            abstract: "Convert text to and from Morse code."
        )
    }
    
    func run() throws -> String {
        var retVal = ""
        switch mode{
        case .toMorse:
            let morseText = Morse.morse(from: text)
            print("\(text) -> ")
            print("\(morseText)")
            
        case .fromMorse:
            let latinText = Morse.latin(from: text)
            print("\(text) -> ")
            print("\(latinText)")
            retVal = latinText
        }
        return retVal

    }
}



