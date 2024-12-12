//
//  morset.swift
//  Morse.swift
//
//  Created by Jimmy Hough Jr on 12/12/24.
//

import Morse
import ArgumentParser
@main

struct morset:AsyncParsableCommand{
    
    @Argument(help: "Text to convert to morse code.") var text: String
    
    static var configuration: CommandConfiguration{
        CommandConfiguration(
            commandName: "morset",
            abstract: "Convert text to morse code."
        )
    }
    
    func run() throws{
        print("\(text) -> ")
        print(Morse.morse(from: text))
    }
}



