//
//  chasm.swift
//  chasm
//
//  Created by Josh Shepard on 9/15/26.
//
// TODO:
// * pre-processing (defs/equs, macros)
// * sub-routines (local labels/symbols)
// *


import ArgumentParser
import Foundation

public enum Register: Decodable {
	case A
	case X
	case Y
}

public enum Arg1: Decodable {
	case Addr8(UInt8)
	case Immed8(UInt8)
	case Addr16(UInt16)
	case Reg(Register)
}

public enum Arg2: Decodable {
	case Num8(UInt8)
	case Reg(Register)
}

public struct CodeLine: Decodable {
	let linenum: UInt16	// line number (from the original text!)
	let label: String
	let op: Opcode
	let arg1: String
	let arg2: String
	var byteSize: UInt16 {
		op.mode.byteSize
	}
}

public struct DirectiveLine: Decodable {
	let linenum: UInt16	// line number (from the original text!)
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
	var preprocInput: [Line] = []
}

@main
public struct Chasm: ParsableCommand {
	var globals: Globals = Globals()
	var buf = ContiguousArray<UInt8>()

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
		//dbg("\(input) => \(output)")

		// TODO: actual logic:
		// - determine the full paths for input & output files
		// - read the input file
		let fileURL = URL(fileURLWithPath: input)
		let content = try String(contentsOf: fileURL, encoding: .utf8)
		let lines = content.components(separatedBy: .newlines)
		//dbg("lines:\n\(lines)")
		
		// TODO: impl:
		// - (optional?) pre-process:
		//   - expand macros
		//   - defs/equs
		//preprocess(lines)
		
		// - first pass, scan line by line, tracking:
		//   - handle directives (.org etc) & update pc/offset
		//   - convert instruction mnemonics to opcodes for sizing (needed for address calc)
		//   - track current memory address
		//   - enter new labels (addresses) into symbol table, look up referenced labels
		//   - (leaves forward references for jmp/jsr/branch)
		passOne(lines)
		//dbg("sym tab:\n\(globals.symbolTable)")
		
		// - second pass, re-read w/ completed symbol table:
		//   - resolve forward referenced labels
		//   - finish translating mnemonics to opcodes with final addresses
		// - write to output file in given format (raw for now?)
		passTwo()
	}

	// passOne takes the input as an array of strings (lines), and returns a symbol table.
	public mutating func passOne(_ lines: [String]) {
		// program counter to track current offset
		var pc: UInt16 = 0
		for (linenum, line) in lines.enumerated() {
			pc = parseLine(line, number: UInt16(linenum), from: pc)
			//dbg("parsed line: \(line)")
		}
	}
	
	// passTwo takes the globals produced by passOne and generates code from them
	public mutating func passTwo() {
		var loc: UInt16 = 0
		
		// for each line (directive or code) in the preprocInput
		for line in globals.preprocInput {
			//  generate output 
			generateCode(line, from: &loc)
		}
	}
	
	public mutating func generateCode(_ line: Line, from: inout UInt16) {
		switch line {
		case .directive(let d):
			generateForDirective(d, from: &from)
		case .code(let c):
			generateForCode(c, from: &from)
		}
	}
	
	public mutating func generateForDirective(_ line: DirectiveLine, from: inout UInt16) {
		// TODO: impl all directives
		switch line.name {
		case ".ORG":
			if let newpc = line.newPC {
				let len = newpc - from
				if len < 0 {
					err("invalid ORG directive", line: line.linenum)
					abort()
				}
				// fill from current position to new position with BRKs ($00)
				for _ in 0..<len {
					buf.append(0)
					from += 1
				}
			} else {
				err("invalid ORG directive", line: line.linenum)
				abort()
			}
		default:
			break
		}
	}
	
	public mutating func generateForCode(_ line: CodeLine, from: inout UInt16) {
		// TODO: impl
	}

	public mutating func parseLine(_ line: String, number: UInt16, from pc: UInt16) -> UInt16 {
		var offset = pc
		if line.count == 0 || line.trimmingCharacters(in: .whitespaces).count == 0 {
			// empty line, no-op
			return offset
		}
		// directive?
		let d = directive(line, number: number, from: pc)
		if let dir = d {
			globals.preprocInput.append(Line.directive(dir))
			// if the directive changed the pc, change it
			if let npc = dir.newPC {
				if npc < offset {
					err("directive cannot set org prior to current location", line: number)
					abort()
				}
				offset = npc
			}
		} else {
			// code line?
			let c = code(line, number: number, from: pc)
			if let code = c {
				globals.preprocInput.append(Line.code(code))
				offset += code.byteSize
			} else {
				// comment-only line, no-op
				return offset
			}
		}
		return offset
	}

	// dot-prefixed directives: .org, .data, .db, .dw, .include, .incbin...
	// TODO: handle all directives
	public mutating func directive(_ line: String, number: UInt16, from pc: UInt16) -> DirectiveLine? {
		// strip off comments
		let stripped = line.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)[0]
		// directive? (starts with '.' IN COLUMN 1!)
		if !stripped.hasPrefix(".") {
			return nil
		}
		let parts = stripped.split(maxSplits: 1){ $0.isWhitespace }
		let name = String(parts[0]).trimmingCharacters(in: .whitespaces).uppercased()
		let content = String(parts[1]).trimmingCharacters(in: .whitespaces).uppercased()
		// TODO: calc new pc correctly for other directives
		var npc = pc
		if name.lowercased() == ".org" {
			// 'content' should be convertible to a hex number
			if let n = parseNum(content) {
				npc = n
			} else {
				err("invalid number '\(content)'", line: number)
				return nil
			}
		}
		// TODO: impl
		// .data, .db, .dw, .include, .incbin etc.
		return DirectiveLine(linenum: number, name: name, content: content, newPC: npc)
	}
	
	public mutating func code(_ line: String, number: UInt16, from pc: UInt16) -> CodeLine? {
		// format (<> delimiting fields):
		// <label:> <opcode> <arg1><, arg2> <;comment>
		// every field is optional, but <, arg2> is dependent on <arg1> existing, which is dependent
		//  on <opcode> existing
		// fields are separated by spaces or tabs
		// label must be in column 1 and have a trailing ':'
		// anything after a ';' is a comment
		// opcodes must be valid from list of opcodes
		// args can have indexed addressing modes indicated by use of parens:
    	//  indexed indirect: index ZP addres with X, fetch address from there e.g. `LDA ($20,X)`
    	//  indirect indexed: fetch 16-bit address from ZP, then add & to it e.g. `LDA($20), Y`
    	// arg fields can be either a label, a number or a register (A, X or Y)
    	// labels are C-like identifiers (alphanumeric + _, first char not numeric)
    	// numbers can be hex ($ prefix), binary (% prefix) or decimal (no prefix)
    	// numbers are 8 bit, except in indexed and absolute addressing modes, where they are 16
    	//  (and 16 bit numbers are ALWAYS arg1)
    	// numbers can be preceded by a '#' indicating they are immediate values, not addresses, but
    	//  only in the 'immediate' addressing mode (e.g. LDA #$44) and therefore only for arg1 
    	//   8-bit nums
    	// args can therefore be (where N is an 8-bit number and R is a register)
    	// arg 1:
    	//  N
    	//  NN
    	//  #N
    	//  R
    	//  (N
    	//  (N)
    	// arg 2:
    	//  , N
    	//  , R
    	//  , R)
    	// (where whitespace after ',' is optional)
    	// 
    	// NOTE: 16bit number args can be replaced by a label, which the assembler needs to
    	// turn into an address in the second pass
    	// *AND*
    	// 8bit number args to BRANCH instructions ONLY can also be replaced by a label, which
    	// the assembler needs to ensure is +127/-128 bytes away from the instruction offset
    	// (from instruction offset +2 actually, since the branch+arg are two bytes)
    	
				
		// label: opcode arg1, arg2 ; comment
		// - strip comments, if any
		let stripped = line.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)[0]
		if stripped.trimmingCharacters(in: .whitespaces).count == 0 {
			return nil
		}
		// - look for ':'
		let ssplit = stripped.split(separator: ":", maxSplits: 1)
		var label = ""
		var code = ""
		if ssplit.count == 2 {
			label = String(ssplit[0])
			if !validLabel(label) {
				err("invalid label", line: number)
				abort()
			}
			// ensure col 0 is non-whitespace
			if label[label.startIndex].isWhitespace {
				err("labels must start in the first column", line: number)
				abort()
			}
			// add label to symbol table with current pc
			globals.symbolTable[label.uppercased()] = pc
			
			code = String(ssplit[1])
		} else {
			code = String(ssplit[0])
		}
		// - split1 by whitespace for opcode & args
		let codesplit = code.split(maxSplits: 1){ $0.isWhitespace }
		let opcode = codesplit[0].uppercased()
		// - check opcode validity
		if !validOpcode(opcode) {
			err("invalid opcode '\(opcode)'", line: number)
			abort()
		}
		var arg1 = "", arg2 = ""
		// - split1 args by ',' for arg1 & arg2
		if codesplit.count == 2 {
			let args = codesplit[1].split(separator: ",", maxSplits: 1)
			arg1 = String(args[0]).trimmingCharacters(in: .whitespaces)
			arg1 = arg1.uppercased()
			if args.count == 2 {
				arg2 = String(args[1]).trimmingCharacters(in: .whitespaces)
				arg2 = arg2.uppercased()
			}
		}
		// TODO: check arg validity
		// ...

		// determine addressing mode
		let addrMode = parseAddressingMode(opcode: opcode, arg1: arg1, arg2: arg2)
		if let amode = addrMode {
			// parse opcode & args for size
			let ohex = OpcodeTable.assemblerLookup[opcode]?[amode]
			if let hex = ohex {
				// return opcode size
				let opc = Opcode(hex: hex, mnemonic: opcode, mode: amode)
				return CodeLine(linenum: number, label: label, op: opc, arg1: arg1, arg2: arg2)
			} else {
				err("invalid opcode or addressing mode", line: number)
				abort()
			}
		} else {
			err("invalid addressing mode in args: '\(stripped)'", line: number)
			abort()
		}
	}
	
	// if input is a number, returns it as a UInt16,
	// else returns nil
	// NOTE: does not handle "#" prefix for immediates - caller must handle
	public func parseNum(_ n: String) -> UInt16? {
		// $ prefix = hex
		if n.hasPrefix("$") {
			return UInt16(n.trimmingPrefix("$"), radix: 16)
		} else if n.hasPrefix("%") {
			// % prefix = binary
			return UInt16(n.trimmingPrefix("%"), radix: 2)
		} else if n.hasPrefix("0") {
			// 0 prefix = octal
			return UInt16(n, radix: 8)
		} else {
			// no prefix = decimal
			return UInt16(n)
		}
	}
	
	// if input is an immediate (e.g. '#$ff'), returns it as a UInt16,
	// else returns nil
	public func parseImmediate(_ n: String) -> UInt16? {
		if n[n.startIndex] == "#" {
			return parseNum(String(n.trimmingPrefix("#")))
		} else {
			return nil
		}
	}
	
	func validOpcode(_ opcode: String) -> Bool {
		OpcodeTable.assemblerLookup[opcode] != nil
	}
	
	func validLabel(_ label: String) -> Bool {
		if label.count == 0 {
			return false
		}
		let c = label[label.startIndex]
		if !c.isLetter && c != "_" {
			return false
		}
		for c in label {
			if !c.isLetter && !c.isNumber && c != "_" {
				return false
			}
		}
		return true
	}
	
	func parseAddressingMode(opcode: String, arg1: String, arg2: String) -> AddressingMode? {
		// addressing mode matching:

		// no-arg instructions:
		// implied: no args, e.g. TAX
		if arg1.count == 0 && arg2.count == 0 {
			return .implied
		}
		// single arg instructions
		if arg2.count == 0 {
			// accumulator: 1 arg, the A register, e.g. ASL A
			if arg1 == "A" {
				return .accumulator
			}
			// arg1 is in parentheses
			if arg1[arg1.startIndex] == "(" && arg1.last == ")" {
				// absolute indirect: JMP is the only op that uses this
				if opcode == "JMP" {
					return .indirect
				}
				return nil
			}
			// branch instruction = relative addressing
			switch opcode {
			case "BCC":
				fallthrough
			case "BCS":
				fallthrough
			case "BEQ":
				fallthrough
			case "BNE":
				fallthrough
			case "BMI":
				fallthrough
			case "BPL":
				fallthrough
			case "BVC":
				fallthrough
			case "BVS":	
				// validate label/number
				if !validLabel(arg1) && parseNum(arg1) == nil {
					return nil
				}
				return .relative
			default:
				break
			}
			// immediate: arg1 an immediate 8bit number, e.g. LDA #$ff
			if parseImmediate(arg1) != nil {
				return .immediate
			}
			// one arg and it's an address
			if parseNum(arg1) != nil {
				// arg1 is 16bit address
				if arg1.count == 5 {
					// absolute: arg1=16bit, e.g. LDA $42ff
					return .absolute
				} else {
					// zero page: 1 arg, 8 bits, e.g. LDA $ff
					return .zeroPage
				}
			} else if let sym = globals.symbolTable[arg1.uppercased()] {
				// it's a symbol, look it up in the symbol table
				// jmp instructions don't have zero-page versions
				if opcode == "JMP" || opcode == "JSR" || sym > 255 {
					return .absolute
				}
				return .zeroPage
			} else {
				// didn't find the symbol, assume absolute
				// (zero-page labels cannot be forward referenced)
				if !validLabel(arg1) {
					return nil
				}
				return .absolute
			}
		} else {
			// two arg instructions
			if arg2 == "X" {
				// symbol or number?
				if let sym = globals.symbolTable[arg1.uppercased()] {
					if sym < 256 { return .zeroPageX }
					return .absoluteX
				} else if parseNum(arg1) != nil {
					if arg1.count == 3 { return .zeroPageX }
					if arg1.count == 5 { return .absoluteX }
					return nil
				}
				// not a number and didn't find the symbol, assume absolute
				// (zero page labels cannot be forward referenced)
				if !validLabel(arg1) {
					return nil
				}
				return .absoluteX
			}
			// indirect x (pre-indexed): 2 args in parens, e.g. LDA ($42, X)
			if arg1[arg1.startIndex] == "(" && arg2.last == ")" {
				let a1 = String(arg1.trimmingPrefix("("))
				let a2 = arg2.dropLast(1)
				if a2 != "X" { return nil }
				if !validLabel(a1) && parseNum(a1) == nil {
					return nil
				}
				return .indexedIndirect
				
			}
			if arg2 == "Y" {
				// indirect y (post-indexed): 2 args, 1st in parens, e.g. LDA ($42), Y
				// relative: only branch instructions, 1 arg 8bit or label (assembler needs to 
				//           calculate the offset of the label & error out if it is more than
				//           +127/-128 bytes away
				if arg1[arg1.startIndex] == "(" && arg1.last == ")" {
					let a1 = String(arg1.trimmingPrefix("(").dropLast(1))
					if arg2 != "Y" { return nil }
					if !validLabel(a1) && parseNum(a1) == nil {
						return nil
					}
					return .indirectIndexed
				}
				// symbol or number?
				if let sym = globals.symbolTable[arg1.uppercased()] {
					if sym < 256 { return .zeroPageY }
					return .absoluteY
				} else if parseNum(arg1) != nil {
					if arg1.count == 3 { return .zeroPageY }
					if arg1.count == 5 { return .absoluteY }
					return nil
				}
				// not a number and didn't find the symbol, assume absolute
				// (zero page labels cannot be forward referenced)
				if !validLabel(arg1) {
					return nil
				}
				return .absoluteY
			}

			return nil // error, could not determine addressing mode
		}
	}
	
	func err(_ msg: String, line: UInt16) {
		print("\(input):\(line): error: \(msg)") 
	}
	
	func warn(_ msg: String, line: UInt16) {
		print("\(input):\(line): warning: \(msg)") 
	}
	
	func dbg(_ msg: String) {
#if DEBUG
		print("debug: \(msg)") 
#endif
	}
}
