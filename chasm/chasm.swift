//
//  chasm.swift
//  chasm
//
//  Created by Josh Shepard on 9/15/26.
//

import Foundation
import ArgumentParser

@main
struct Chasm : ParsableCommand {
    @Argument(help:"input .chasm filename")
    var input: String
    
    @Option(name: [.short, .long], help:"output filename")
    var output: String?
    
    func run() throws {
    	let url = URL(string: input)
    	let infile = url!.deletingPathExtension().lastPathComponent
    	let output = output ?? infile + ".out"
        print("\(input) => \(output)")
    }
}
