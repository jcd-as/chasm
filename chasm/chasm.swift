//
//  chasm.swift
//  chasm
//
//  Created by Josh Shepard on 9/15/26.
//
// TODO:
// P1
// * directives: .incbin
// * macros: .mac/.endmac - all enclosed labels must be local
// P2
// * support basic math on symbols (esp +[offset])
// * error handling - better error messages from closer to failure site
// * error handling - keep emitting errors through each pass & only fail at end of pass
// * will need (at least) .RORG directive to support loadable segments (i.e. for NES cartridge RAM)
// *

import ArgumentParser
import Foundation

public struct CodeLine: Decodable {
	let linenum: UInt16  // line number (from the original text!)
	var offset: UInt16  // byte offset to this line
	let label: String
	let op: Opcode?
	let arg1: String
	let arg2: String
	var byteSize: UInt16 {
		op?.mode.byteSize ?? 0
	}
}

public struct DirectiveLine: Decodable {
	let linenum: UInt16  // line number (from the original text!)
	var offset: UInt16  // byte offset to this line
	let name: String
	let content: String
	let newPC: UInt16?
}

public enum Line: Decodable {
	case code(CodeLine)
	case directive(DirectiveLine)
	case empty(Int)
}

public func highByte(_ word: UInt16) -> UInt8 {
	return UInt8((word >> 8) & 0xFF)
}

public func lowByte(_ word: UInt16) -> UInt8 {
	return UInt8(word & 0xFF)
}

@main
public struct Chasm: ParsableCommand {
	// the symbol table tracking labels/defs and their addresses
	var symbolTable: [String: UInt16] = [:]
	// the pre-processed output of pass one
	var preprocInput: [Line] = []
	// the buffer to write the binary output of pass two
	var buf = ContiguousArray<UInt8>()

	// the lines read from the input file
	var lines: [String] = []

	// flag to indicate we are currently parsing a sub-routine
	// (contains the sub-routine name)
	var sub = ""
	// flag to indicate we are currently parsing a macro definition
	// (contains the macro name)
	var mac = ""
	// current macro contents
	var macdef: [String] = []
	// macro name->definition map
	var macros: [String:[String]] = [:]

	// explicit public init is needed
	public init() {
		buf.reserveCapacity(64 * 1024)
	}

	@Argument(help: "input .chasm filename")
	var input: String

	@Option(name: [.short, .long], help: "output filename")
	var output: String?

	@Flag(name: [.customShort("d"), .long], help: "produce c64 header?")
	var header: Int

	@Flag(name: [.short, .long], help: "produce DASM-compatible symbol file?")
	var symbols: Int

	// MARK: main entry point

	public mutating func run() throws {
		// read the input file
		let fileURL = URL(fileURLWithPath: input)
		let content = try String(contentsOf: fileURL, encoding: .utf8)
		lines = content.components(separatedBy: .newlines)

		// TODO: impl:
		// - pre-process:
		//   - expand macros
		preprocess()

		// first pass, scan line by line, tracking:
		//  - handle directives (.org etc) & update pc/offset
		//  - convert instruction mnemonics to opcodes for sizing (needed for address calc)
		//  - track current memory address
		//  - enter new labels (addresses) into symbol table, look up referenced labels
		//  - (leaves forward references for jmp/jsr/branch)
		passOne()

		// second pass, re-read w/ completed symbol table:
		//  - resolve forward referenced labels
		//  - finish translating mnemonics to opcodes with final addresses
		passTwo()

		// write to output file in given format (raw for now?)
		var outURL: URL
		if output != nil {
			outURL = URL(fileURLWithPath: output!)
		} else {
			let url = URL(fileURLWithPath: input)
			outURL = url.deletingPathExtension().appendingPathExtension("out")
		}
		var data = buf.withUnsafeBytes { rawbuf in
			Data(bytes: rawbuf.baseAddress!, count: rawbuf.count)
		}
		// if -d, add a header with the initial org
		if header != 0 {
			let org = initialOrg
			let high = highByte(org)
			let low = lowByte(org)
			data.insert(high, at: 0)
			data.insert(low, at: 0)
		}
		do {
			try data.write(to: outURL, options: [.atomic])
			print("wrote \(outURL.relativePath)")
		} catch {
			print("error writing file: \(error)")
		}
		// if -s, write a symbol file
		if symbols != 0 {
			let url = URL(fileURLWithPath: input)
			let symURL = url.deletingPathExtension().appendingPathExtension("sym")
			writeSymbolFile(symURL)
			print("wrote \(symURL.relativePath)")
		}
	}

	// (initial org is assumed to be zero *unless* the first non-.def line is an .org line)
	var initialOrg: UInt16 {
		for line in preprocInput {
			switch line {
			case .directive(let d):
				if d.name == ".ORG" {
					return d.newPC!
				} else if d.name == ".DEF" {
					continue
				} else {
					return 0
				}
			case .code:
				fallthrough
			case .empty:
				return 0
			}
		}
		return 0
	}

	func writeSymbolFile(_ url: URL) {
		FileManager.default.createFile(atPath: url.path, contents: nil)
		guard let fh = try? FileHandle(forWritingTo: url) else {
			fatal("error writing symbol file: '\(url.relativePath)'")
		}
		for (sym, addr) in symbolTable {
			let plen = 63 - sym.count
			let padding = String(repeating: " ", count: plen)
			let line = "\(sym) \(padding)\(String(format: "%04x", addr))\n"
			if let data = line.data(using: .utf8) {
				do {
					try fh.write(contentsOf: data)
				} catch {
					fatal("error writing lines to symbol file: '\(url.relativePath)'")
				}
			}
		}
	}

	// MARK: preprocessing

	// preprocesses the file, handling reading macro definitions and replacing them
	// inline where used
	public mutating func preprocess() {
		// TODO:
		// line-by-line
		var linenum = 0
		while linenum < lines.count {
			let line = lines[linenum]
			//pc = parseLine(line, number: UInt16(linenum), from: pc)
			preprocessLine(line, number: UInt16(linenum))
			linenum += 1
		}
		// if we're in a macro definition still, error
		if mac.count > 0 {
			err("missing .ENDMAC directive: un-closed macro definition", line: UInt16(linenum))
			abort()
		}
	}

	// MARK: passes

	// passOne parses the input in 'lines' and returns a symbol table.
	// NOTE: passOne may mutate lines (on an .INCLUDE directive, for example)
	public mutating func passOne() {
		// program counter to track current offset
		var pc: UInt16 = 0
		var linenum = 0
		while linenum < lines.count {
			let line = lines[linenum]
			pc = parseLine(line, number: UInt16(linenum), from: pc)
			linenum += 1
		}
	}

	// passTwo takes the output produced by passOne and generates code from it
	public mutating func passTwo() {
		var loc: UInt16 = 0
		for line in preprocInput {
			generateCode(line, from: &loc)
		}
	}

	// MARK: preprocessing methods

	public mutating func preprocessLine(_ line: String, number: UInt16) {
		let ln = line.uppercased()

		if ln.trimmingCharacters(in: .whitespaces) == ".ENDMAC" {
			// end macro, save it
			macros[mac] = macdef
			mac = ""
			macdef = []
		} else if mac.count > 0 {
			// are we in a macro definition already?
			// TODO: ensure labels are unique!!
			//       (mac+<UUID>+label ??)
			macdef.append(line)
		} else if ln.hasPrefix(".MAC") {
			// if we're already defining a mac, error
			if mac.count > 0 {
				err("nested macros are not allowed", line: number)
				abort()
			}
			// check for .MAC macro definition
			let msplit = ln.split(maxSplits: 1) { $0.isWhitespace }
			if msplit.count != 2 {
				err("invalid .MAC: '\(line)': no name", line: number)
				abort()
			}
			// start a new macros entry
			mac = String(msplit[1])
		} else {
			// TODO:
			// check each line for use of any of the macros defined so far
			//  found:
			//  replace the line with the lines stored in macros
		}
	}


	// MARK: pass one methods

	public mutating func parseLine(_ line: String, number: UInt16, from pc: UInt16) -> UInt16 {
		var offset = pc
		if line.count == 0 || line.trimmingCharacters(in: .whitespaces).count == 0 {
			// empty line, no-op
			return offset
		}
		// directive?
		let d = directive(line, number: number, from: pc)
		if let ln = d {
			switch ln {
			case .code:
				// wtf??
				fallthrough
			case .empty:
				break
			case .directive(let dir):
				preprocInput.append(ln)
				//preprocInput.append(Line.directive(dir))
				// if the directive changed the pc, change it
				if let npc = dir.newPC {
					if npc < offset {
						err("directive cannot set org prior to current location", line: number)
						abort()
					}
					offset = npc
				}
			}
		} else {
			// code line?
			let c = code(line, number: number, from: pc)
			if let code = c {
				preprocInput.append(Line.code(code))
				offset += code.byteSize
			} else {
				// comment-only line, no-op
				return offset
			}
		}
		return offset
	}

	// TODO: handle all directives .incbin
	public mutating func directive(_ line: String, number: UInt16, from pc: UInt16)
		-> Line?
	{
		// strip off comments
		let stripped = line.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)[0]
		// directive? (starts with '.' IN COLUMN 1!)
		if !stripped.hasPrefix(".") {
			return nil
		}
		let parts = stripped.split(maxSplits: 1) { $0.isWhitespace }
		let name = String(parts[0]).trimmingCharacters(in: .whitespaces).uppercased()
		let content = parts.count < 2 ? "" : String(parts[1]).trimmingCharacters(in: .whitespaces).uppercased()
		var npc = pc
		// TODO: impl .incbin
		switch name {
		case ".MAC":
			fallthrough
		case ".ENDMAC":
			// ignore
			return Line.empty(0)
		case ".INCLUDE":
			if parts.count != 2 {
				err("missing filename in .INCLUDE directive", line: number)
				abort()
			}
			let fname = String(parts[1]).trimmingCharacters(in: .whitespaces)
			let fileURL = URL(fileURLWithPath: fname)
			var filecontents: String
			do {
				filecontents = try String(contentsOf: fileURL, encoding: .utf8)
			} catch {
				err("invalid .INCLUDE file: '\(fname)'", line: number)
				abort()
			}
			let inclines = filecontents.components(separatedBy: .newlines)
			lines.insert(contentsOf: inclines, at: Int(number+1))
			return Line.directive(DirectiveLine(
				linenum: number, offset: pc, name: name, content: content, newPC: pc))
		case ".SUB":
			// 'content' should be a valid label
			if !content.hasSuffix(":") {
				err("invalid .SUB label: '\(content)', missing ':'", line: number)
				abort()
			}
			let label = String(content.dropLast(1))
			if !validLabel(label) {
				err("invalid .SUB label: '\(content)'", line: number)
				abort()
			}
			// TODO: this code is the same as in code() below...
			// check for dups
			if symbolTable[label] != nil {
				err("symbol redefinition: '\(label)'", line: number)
				abort()
			}
			// add label to symbol table with current pc
			symbolTable[label] = pc
			sub = label
			return Line.directive(DirectiveLine(
				linenum: number, offset: pc, name: name, content: content, newPC: pc))
		case ".ENDSUB":
			sub = ""
			return Line.directive(DirectiveLine(
				linenum: number, offset: pc, name: name, content: content, newPC: pc))
		case ".ORG":
			// 'content' should be convertible to a hex number
			if let n = parseNum(content) {
				npc = n
			} else {
				err("invalid number '\(content)'", line: number)
				abort()
			}
			return Line.directive(DirectiveLine(
				linenum: number, offset: pc, name: name, content: content, newPC: npc))
		case ".DATA":
			// TODO: validate content ?
			let parts = content.split { $0.isWhitespace }
			return Line.directive(DirectiveLine(
				linenum: number, offset: pc, name: name, content: content,
				newPC: pc + UInt16(parts.count)))
		case ".BYTE":
			// TODO: validate content ?
			let parts = content.split(separator: ",", maxSplits: 1)
			var npc = pc
			if parts.count == 2 {
				if let len = parseNum(String(parts[1].trimmingCharacters(in: .whitespaces))) {
					npc += len
				} else {
					err("invalid .BYTE directive count: \(parts[1])", line: number)
					abort()
				}
			} else {
				npc += 1
			}
			return Line.directive(DirectiveLine(
				linenum: number, offset: pc, name: name, content: content, newPC: npc))
		case ".WORD":
			// TODO: validate content ?
			let parts = content.split(separator: ",", maxSplits: 1)
			var npc = pc
			if parts.count == 2 {
				if let len = parseNum(String(parts[1].trimmingCharacters(in: .whitespaces))) {
					npc += len * 2
				} else {
					err("invalid .BYTE directive count: \(parts[1])", line: number)
					abort()
				}
			} else {
				npc += 2
			}
			return Line.directive(DirectiveLine(
				linenum: number, offset: pc, name: name, content: content, newPC: npc))
		case ".STRING":
			// TODO: validate content ?
			let len = content.count
			return Line.directive(DirectiveLine(
				linenum: number, offset: pc, name: name, content: content, newPC: pc + UInt16(len)))
		case ".DEF":
			// parse out symbol & value from 'content'
			let contentparts = content.split(maxSplits: 1) { $0.isWhitespace }
			if contentparts.count != 2 {
				err("invalid .DEF: '\(content)'", line: number)
				abort()
			}
			let lhs = String(contentparts[0].trimmingCharacters(in: .whitespaces))
			let rhs = String(contentparts[1].trimmingCharacters(in: .whitespaces))
			if !validLabel(lhs) {
				err("invalid .DEF symbol name: '\(lhs)'", line: number)
				abort()
			}

			if let n = parseNum(rhs) {
				// check for dups
				if symbolTable[lhs] != nil {
					err(".DEF symbol redefinition: '\(lhs)'", line: number)
					abort()
				}
				// enter into symbol table
				symbolTable[lhs] = n
				return Line.directive(DirectiveLine(
					linenum: number, offset: pc, name: name, content: "", newPC: nil))
			} else {
				err("invalid .DEF value: '\(rhs)'", line: number)
				abort()
			}
		default:
			return nil
		}
	}

	public mutating func code(_ line: String, number: UInt16, from pc: UInt16) -> CodeLine? {
		// label: opcode arg1, arg2 ; comment

		// if we're in a macro definition, ignore
		if mac.count > 0 {
			return nil
		}

		// strip comments, if any
		let stripped = line.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)[0]
		if stripped.trimmingCharacters(in: .whitespaces).count == 0 {
			return nil
		}
		// look for ':'
		let ssplit = stripped.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
		var label = ""
		var code = ""
		if ssplit.count == 2 {
			label = String(ssplit[0]).uppercased()
			if !validLabel(label) {
				err("invalid label", line: number)
				abort()
			}
			// ensure col 0 is non-whitespace
			if label[label.startIndex].isWhitespace {
				err("labels must start in the first column", line: number)
				abort()
			}
			// if we're in a sub we need to check for local labels and prepend the sub name to them
			if sub.count > 0 {
				if label.first == "@" {
					label = "\(sub)\(label)"
				}
			}
			// check for dups
			if symbolTable[label] != nil {
				err("symbol redefinition: '\(label)'", line: number)
				abort()
			}
			// add label to symbol table with current pc
			symbolTable[label] = pc

			code = String(ssplit[1])
		} else {
			code = String(ssplit[0])
		}
		if code.count > 0 {
			// split1 by whitespace for opcode & args
			let codesplit = code.split(maxSplits: 1) { $0.isWhitespace }
			let opcode = codesplit[0].uppercased()
			// check opcode validity
			if !validOpcode(opcode) {
				err("invalid opcode '\(opcode)'", line: number)
				abort()
			}
			var arg1 = ""
			var arg2 = ""
			// split1 args by ',' for arg1 & arg2
			if codesplit.count == 2 {
				let args = codesplit[1].split(separator: ",", maxSplits: 1)
				arg1 = String(args[0]).trimmingCharacters(in: .whitespaces)
				arg1 = arg1.uppercased()
				if args.count == 2 {
					arg2 = String(args[1]).trimmingCharacters(in: .whitespaces)
					arg2 = arg2.uppercased()
				}
			}
			// TODO: check arg validity ?
			// ...

			// determine addressing mode
			let addrMode = parseAddressingMode(opcode: opcode, arg1: arg1, arg2: arg2)
			if let amode = addrMode {
				// parse opcode & args for size
				let ohex = OpcodeTable.assemblerLookup[opcode]?[amode]
				if let hex = ohex {
					// return opcode size
					let opc = Opcode(hex: hex, mnemonic: opcode, mode: amode)
					return CodeLine(
						linenum: number, offset: pc, label: label, op: opc, arg1: arg1, arg2: arg2)
				} else {
					err("invalid opcode or addressing mode", line: number)
					abort()
				}
			} else {
				err("invalid addressing mode in args: '\(stripped)'", line: number)
				abort()
			}
		} else {
			// label-only, no opcode or args
			return CodeLine(linenum: number, offset: pc, label: label, op: nil, arg1: "", arg2: "")
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
	public func parseImmediate(_ n: String) -> UInt8? {
		if n[n.startIndex] == "#" {
			if let n = parseNum(String(n.trimmingPrefix("#"))) {
				// number
				if n < 256 {
					return UInt8(n)
				}
			} else if let n = byteForSymbol(String(n.trimmingPrefix("#"))) {
				// symbol
				return n
			}
		}
		return nil
	}

	func validOpcode(_ opcode: String) -> Bool {
		OpcodeTable.assemblerLookup[opcode] != nil
	}

	func validLabel(_ label: String) -> Bool {
		if label.count == 0 {
			return false
		}
		let c = label[label.startIndex]
		// local labels only allowed inside sub-routines
		if c == "@" {
			if sub.count == 0 {
				// TODO: error message?
				// print("error: local labels only allowed in .SUB/.ENDSUB blocks")
				return false
			}
		} else if !c.isLetter && c != "_" {
			return false
		}
		for (i, c) in label.enumerated() {
			if i == 0 {
				if !c.isLetter && c != "_" && c != "@" {
					return false
				}
			} else if !c.isLetter && !c.isNumber && c != "_" {
			 	return false
			}
		}
		return true
	}

	// is this symbol valid in a "RHS" context. i.e. when being referenced, not defined
	func validSymbolRHS(_ label: String) -> Bool {
		if label.count == 0 {
			return false
		}
		let c = label[label.startIndex]
		if !c.isLetter && c != "_" && c != "<" && c != ">" {
			return false
		}
		for c in label {
			if !c.isLetter && !c.isNumber && c != "_" && c != "<" && c != ">" {
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
			case "BCC", "BCS", "BEQ", "BNE", "BMI", "BPL", "BVC", "BVS":
				// validate symbol/number
				if !validSymbolRHS(arg1) && parseNum(arg1) == nil {
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
			let optn = parseNum(arg1)
			//if parseNum(arg1) != nil {
			if let n = optn {
				// arg1 is 16bit address
				if n > 255 {
					// absolute: arg1=16bit, e.g. LDA $42ff
					return .absolute
				} else {
					// zero page: 1 arg, 8 bits, e.g. LDA $ff
					return .zeroPage
				}
			} else if let sym = wordForSymbol(arg1.uppercased()) {
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
				if let sym = wordForSymbol(arg1.uppercased()) {
					// 8-bit symbols or 16-bit with </> prefix (low/high byte) should be zero-page
					if sym < 256 { return .zeroPageX }
					return .absoluteX
				} else {
					let optn = parseNum(arg1)
					if let n = optn {
						if n > 255 { return .absoluteX } else { return .zeroPageX }
					}

					// not a number and didn't find the symbol, assume absolute
					// (zero page labels cannot be forward referenced)
					if !validLabel(arg1) {
						return nil
					}
					return .absoluteX
				}
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
				if let sym = wordForSymbol(arg1.uppercased()) {
					// 8-bit symbols or 16-bit with </> prefix (low/high byte) should be zero-page
					if sym < 256 { return .zeroPageY }
					return .absoluteY
				} else {
					let optn = parseNum(arg1)
					if let n = optn {
						if n > 255 { return .absoluteY } else { return .zeroPageY }
					}

					// not a number and didn't find the symbol, assume absolute
					// (zero page labels cannot be forward referenced)
					if !validLabel(arg1) {
						return nil
					}
					return .absoluteY
				}
			}

			return nil  // error, could not determine addressing mode
		}
	}

	// MARK: pass two methods

	public mutating func generateCode(_ line: Line, from: inout UInt16) {
		switch line {
		case .directive(let d):
			generateForDirective(d, from: &from)
		case .code(let c):
			generateForCode(c, from: &from)
		case .empty:
			break
		}
	}

	public mutating func generateForDirective(_ line: DirectiveLine, from: inout UInt16) {
		// TODO: impl all directives: .mac, .include, .incbin...
		// if a new pc (address) was set, use it
		if let newpc = line.newPC {
			let len = Int(newpc) - Int(from)
			if len < 0 {
				err("invalid \(line.name) directive", line: line.linenum)
				abort()
			}
			from = newpc
		} else {
			// TODO: .defs and macros don't change the address (PC)...
			if line.name != ".DEF" {
				err("invalid \(line.name) directive", line: line.linenum)
				abort()
			}
		}
		switch line.name {
		case ".DEF":
			break
		case ".ORG":
			break
		case ".DATA":
			// .DATA $ea $ff $01 $00 $ea ; generates the literal bytes ea ff 01 00 ea
			let parts = line.content.split { $0.isWhitespace }
			for part in parts {
				if let val = parseNum(String(part.trimmingCharacters(in: .whitespaces))) {
					if val > 255 {
						err(".DATA directive value >255: \(parts[0])", line: line.linenum)
						abort()
					}
					buf.append(UInt8(val))
				}
			}
		case ".BYTE":
			// .BYTE $ea, $ff ; generates 255 NOPs
			let parts = line.content.split(separator: ",", maxSplits: 1)
			if let val = parseNum(String(parts[0].trimmingCharacters(in: .whitespaces))) {
				if val > 255 {
					err(".BYTE directive value >255: \(parts[0])", line: line.linenum)
					abort()
				}
				if parts.count == 2 {
					if let len = parseNum(String(parts[1].trimmingCharacters(in: .whitespaces))) {
						// fill from current position with 'val'
						for _ in 0..<len {
							buf.append(UInt8(val))
						}
					} else {
						err("invalid .BYTE directive count: \(parts[1])", line: line.linenum)
						abort()
					}
				} else {
					buf.append(UInt8(val))
				}
			} else {
				err("invalid .BYTE directive value: \(parts[0])", line: line.linenum)
				abort()
			}
		case ".WORD":
			let parts = line.content.split(separator: ",", maxSplits: 1)
			if let val = parseNum(String(parts[0].trimmingCharacters(in: .whitespaces))) {
				if parts.count == 2 {
					if let len = parseNum(String(parts[1].trimmingCharacters(in: .whitespaces))) {
						// fill from current position with 'val'
						for _ in 0..<len {
							let low = lowByte(val)
							let high = highByte(val)
							buf.append(low)
							buf.append(high)
						}
					} else {
						err("invalid .WORD directive count: \(parts[1])", line: line.linenum)
						abort()
					}
				} else {
					let low = lowByte(val)
					let high = highByte(val)
					buf.append(low)
					buf.append(high)
				}
			} else {
				err("invalid .WORD directive value: \(parts[0])", line: line.linenum)
				abort()
			}
			break
		case ".STRING":
			// ensure this is a "" enclosed string
			if line.content.first != "\"" || line.content.last != "\"" {
				err("invalid .STRING directive value: \(line.content)", line: line.linenum)
			}
			// TODO: replace escaped quotes (\") in content
			for c in line.content.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) {
				if let ascii = c.asciiValue {
					buf.append(ascii)
				} else {
					err(
						"invalid .STRING directive value, non-ascii characters: \(line.content)",
						line: line.linenum)
				}
			}
			break
		default:
			break
		}
	}

	public mutating func generateForCode(_ line: CodeLine, from: inout UInt16) {
		// if there's an op (i.e. not just label only)
		// write line.op.hex
		if let op = line.op {
			buf.append(op.hex)
			// handle each op.mode and write args as appropriate
			switch op.mode {
			// one byte ops
			case .implied:
				break
			case .accumulator:  // A as operand (e.g. ASL A)
				break
			// two byte ops
			case .immediate:  // immediate operand (e.g. LDA #$FF)
				buf.append(byteForImmediate(line.arg1))
			case .zeroPage, .zeroPageX, .zeroPageY:  // adds Y to zero-page address (e.g. LDX $42,Y)
				buf.append(byteForAddr(line.arg1))
			case .indexedIndirect, .indirectIndexed:  // fetch 16-bit address from ZP, then add & to it (e.g. LDA($20), Y)
				buf.append(
					byteForAddr(
						String(line.arg1.trimmingCharacters(in: CharacterSet(charactersIn: "()")))))
			case .relative:  // branch opcodes only (e.g. BEQ .label, where label is -128 to +127 one byte signed offset)
				// if arg is numeric (very unlikely, but supported), simply emit
				let optn = parseNum(line.arg1)
				if let n = optn {
					if n < 256 {
						buf.append(UInt8(n))
					} else {
						err("branch is out of reach", line: line.linenum)
						abort()
					}
				} else {
					// if arg is a label, get the label address
					if let target = wordForSymbol(line.arg1) {
						// distance from (current addr+2) to target MUST be from -128 to +127
						let delta = Int(target) - (Int(line.offset) + 2)
						if delta > 127 || delta < -128 {
							err("branch is out of reach", line: line.linenum)
							abort()
						}
						let sbyte = Int8(delta)
						let byte = UInt8(bitPattern: sbyte)
						buf.append(byte)
					} else {
						fatal("unknown symbol '\(line.arg1)'")
					}
				}
				break
			// three byte ops
			case .indirect:  // absolute indirect, JMP only (e.g. JMP ($fffe))
				let w = wordForAddr(
					String(line.arg1.trimmingCharacters(in: CharacterSet(charactersIn: "()"))))
				// write output in little-endian byte order
				let high = highByte(w)
				let low = lowByte(w)
				buf.append(low)
				buf.append(high)
			case .absolute, .absoluteX, .absoluteY:  // adds Y to 16-bit address op (e.g. LDA $4200,Y)
				let w = wordForAddr(line.arg1)
				// write output in little-endian byte order
				let high = highByte(w)
				let low = lowByte(w)
				buf.append(low)
				buf.append(high)
			}
		}
	}

	// convert a string representing an immediate mode arg to its byte equivalent
	func byteForImmediate(_ immed: String) -> UInt8 {
		let optn = parseImmediate(immed)
		if let n = optn {
			return n
		}
		fatal("invalid immediate value: '\(immed)'")
	}

	// get a word for a symbol, respecting </> operators
	func wordForSymbol(_ sym: String) -> UInt16? {
		var getLow: Bool = false
		var getHigh: Bool = false
		var s: String
		if sym.first == "<" {
			getLow = true
			s = String(sym.trimmingPrefix("<"))
		} else if sym.first == ">" {
			getHigh = true
			s = String(sym.trimmingPrefix(">"))
		} else {
			s = sym
		}

		let optn = symbolTable[s]
		if let n = optn {
			if getLow {
				return UInt16(lowByte(n))
			} else if getHigh {
				return UInt16(highByte(n))
			} else {
				return n
			}
		} else {
			return nil
		}
	}

	// get a byte for a symbol, respecting </> operators and
	// checking to make sure a symbol is < 256
	// (used, for instance, by the branch instructions)
	func byteForSymbol(_ sym: String) -> UInt8? {
		var getLow: Bool = false
		var getHigh: Bool = false
		var s: String
		if sym.first == "<" {
			getLow = true
			s = String(sym.trimmingPrefix("<"))
		} else if sym.first == ">" {
			getHigh = true
			s = String(sym.trimmingPrefix(">"))
		} else {
			s = sym
		}

		let optn = symbolTable[s]
		if let n = optn {
			if getLow {
				return lowByte(n)
			} else if getHigh {
				return highByte(n)
			} else {
				if n < 256 { return UInt8(n) } else { return nil }
			}
		} else {
			return nil
		}
	}

	// convert a string representing an 8-bit address arg to its byte equivalent
	func byteForAddr(_ addr: String) -> UInt8 {
		let optn = parseNum(addr)
		if let n = optn {
			if n < 256 { return UInt8(n) }
			fatal("expected 8-bit address: '\(addr)'")
		} else {
			// symbol?
			let optn = byteForSymbol(addr)
			if let n = optn {
				return n
			} else {
				fatal("invalid symbol '\(addr)'")
			}
		}
	}

	// convert a string representing an 16-bit address arg to its byte equivalent
	func wordForAddr(_ addr: String) -> UInt16 {
		let optn = parseNum(addr)
		if let n = optn {
			// number?
			return n
		} else {
			// symbol?
			if let n = wordForSymbol(addr) {
				return n
			} else {
				fatal("invalid symbol '\(addr)'")
			}
		}
	}

	// MARK: output helper methods

	func fatal(_ msg: String) -> Never {
		print("\(input): fatal: \(msg)")
		abort()
	}

	func err(_ msg: String, line: UInt16) {
		print("\(input):\(line+1): error: \(msg)")
	}

	func warn(_ msg: String, line: UInt16) {
		print("\(input):\(line+1): warning: \(msg)")
	}

	func dbg(_ msg: String) {
		#if DEBUG
			print("debug: \(msg)")
		#endif
	}
}
