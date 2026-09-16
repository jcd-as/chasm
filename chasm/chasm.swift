//
//  chasm.swift
//  chasm
//
//  Created by Josh Shepard on 9/15/26.
//

import Foundation
import ArgumentParser

// the global symbol table tracking labels and their addresses
//var symbolTable: [String: UInt16] = [:]

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
        
        // TODO: actual logic:
        // - determine the full paths for input & output files
        // - read the input file
        let fileURL = URL(fileURLWithPath: input)
		let content = try String(contentsOf: fileURL, encoding: .utf8)
		let lines = content.components(separatedBy: .newlines)
		//print("\(lines)")
		let symbolTable = passOne(lines)
		print("\(symbolTable)")
		
        // - lex the input into tokens
        // - (optional?) pre-process:
        //   - expand macros
        // - first pass, scan line by line, tracking:
        //   - handle directives (.org etc) & update pc/offset
        //   - convert instruction mnemonics to opcodes for sizing (needed for address calc)
        //   - track current memory address
        //   - labels (addresses) into symbol table
        //   - defs/equs (symbol table)
        //   - (leaves forward references for jmp/jsr/branch)
        // - second pass, re-read w/ completed symbol table:
        //   - resolve forward referenced labels
        //   - finish translating mnemonics to opcodes with final addresses 
        // - write to output file in given format (raw for now?)
    }
}

// passOne takes the input as an array of strings (lines), and returns a symbol table.
func passOne(_ lines: [String]) -> [String : UInt16] {
	// program counter to track current offset
	var pc: UInt16 = 0
	var symbolTable: [String: UInt16] = [:]
	for line in lines {
		pc += parseLine(line, from: pc, into: &symbolTable)
		print(line)
	}	
	return symbolTable
}

func parseLine(_ line: String, from pc: UInt16, into: inout [String : UInt16]) -> UInt16 {
	// TODO:
	// directive? (starts with '.')
	// no, parse to:
	// label: opcode arg1, arg2 ; comment
	// if label, add to symbol table with current pc
	// parse opcode & args for size
	// return opcode size
	return pc
}

