//
//  chasm.swift
//  chasm
//
//  Created by Josh Shepard on 9/15/26.
//

import ArgumentParser
import Foundation

public struct CodeLine: Decodable {
	let label: String
	let op: Opcode
}

public struct DirectiveLine: Decodable {
	let name: String
	let content: String
	let newPC: UInt16?
}

public enum Line: Decodable {
	case code(CodeLine)
	case directive(DirectiveLine)
}

// global symbols, incl the symbol table and the "tokenized" and preprocessed input
// an instance of will be passed around as inout parameter
public struct Globals: Decodable {
	// the global symbol table tracking labels and their addresses
	var symbolTable: [String: UInt16] = [:]
	var preprocInput: [Line]
}

@main
public struct Chasm: ParsableCommand {
	var globals: Globals = Globals(preprocInput: [])

	// explicit public init is needed
	public init() {}

	@Argument(help: "input .chasm filename")
	var input: String

	@Option(name: [.short, .long], help: "output filename")
	var output: String?

	public mutating func run() throws {
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
		passOne(lines)
		print("\(globals.symbolTable)")

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

	// passOne takes the input as an array of strings (lines), and returns a symbol table.
	public mutating func passOne(_ lines: [String]) {
		// program counter to track current offset
		var pc: UInt16 = 0
		for line in lines {
			pc += parseLine(line, from: pc)
			print(line)
		}
	}

	public mutating func parseLine(_ line: String, from pc: UInt16) -> UInt16 {
		var offset = pc
		if line.count == 0 || line.trimmingCharacters(in: .whitespaces).count == 0 {
			return offset
		}
		// directive?
		let d = directive(line, from: pc)
		if let dir = d {
			globals.preprocInput.append(Line.directive(dir))
			// if the directive changed the pc, change it
			if let npc = dir.newPC {
				offset = npc
			}
		} else {
			// code line?
			// no, parse to:
			// label: opcode arg1, arg2 ; comment
			// if label, add to symbol table with current pc
			// parse opcode & args for size
			// return opcode size
		}
		return offset
	}

	// dot-prefixed directives: .org, .data, .db, .dw, .include, .incbin...
	public mutating func directive(_ line: String, from pc: UInt16) -> DirectiveLine? {
		// directive? (starts with '.' IN COLUMN 1!)
		if !line.hasPrefix(".") {
			return nil
		}
		let parts = line.split(maxSplits: 1){ $0.isWhitespace }
		let name = String(parts[0])
		let content = String(parts[1])
		// TODO: calc new pc correctly for other directives
		var npc = pc
		if name.lowercased() == ".org" {
			// 'content' should be convertible to a hex number
			
			if let n = parseNum(content) {
				npc = n
			} else {
				// TODO: error msg
				return nil
			}
		}
		return DirectiveLine(name: name, content: content, newPC: npc)
	}
	
	public mutating func code(_ line: String, from pc: UInt16) -> CodeLine? {
		return nil
	}
	
	// NOTE: does not handle "#" prefix for immediates - caller must handle
	public func parseNum(_ n: String) -> UInt16? {
		// $ prefix = hex
		if n.hasPrefix("$") {
			return UInt16(n.trimmingPrefix("$"), radix: 16)
		} else if n.hasPrefix("b") {
			// TODO: 'b' prefix for binary??
			return UInt16(n.trimmingPrefix("b"), radix: 2)
		} else {
			// no prefix = decimal
			return UInt16(n)
		}
	}
}
