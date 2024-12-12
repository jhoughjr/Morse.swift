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
    static var configuration: CommandConfiguration{
        CommandConfiguration(
            commandName: "morse",
            abstract: "Convert text to morse code."
        )
    }
    
    func run() throws{
        Morse.Tone.test()
        print(Morse.morse(from: "Hello World!"))
    }
}



