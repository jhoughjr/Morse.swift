//
//  morset.swift
//  Morse.swift
//
//  Created by Jimmy Hough Jr on 12/12/24.
//

import Morse
import ArgumentParser

@main

struct morset: AsyncParsableCommand {
    
    public enum Mode: String, CaseIterable, ExpressibleByArgument{
        // maybe init a mode by inferring the type of text at some point...
        case toMorse = "to"
        case fromMorse = "from"
    }
    
    @Option(name: .shortAndLong, help: "To or from Morse code. Defaults to 'to'.")
    var mode: Mode = .toMorse
    
    @Option(name: .shortAndLong, help: "Verbosity of conversion output. Defaults to false.")
    var verbosity: Bool = false
    
    @Argument(help: "Text to convert to or from morse code.")
    var text: String
    
    func run() throws  {
        var retVal = ""
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if verbosity {
            print("\(trimmedText) -> ")
        }
        
        switch mode{
        case .toMorse:
            let morseText = Morse.morse(from: trimmedText, verbose: verbosity)
           
            retVal = morseText
            
        case .fromMorse:
            let latinText = Morse.latin(from: trimmedText, verbose: verbosity)
            retVal = latinText
        }
        
        print(retVal)

    }
}



