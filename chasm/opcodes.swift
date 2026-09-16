//
//  opcodes.swift
//  chasm
//
//  Created by Josh Shepard on 9/15/26.
//

import Foundation


enum AddressingMode {
	// one byte ops
    case implied		// no operands (e.g. INX)
    case accumulator	// A as operand (e.g. ASL A)
    // two byte ops
    case immediate		// immediate operand (e.g. LDA #$FF)
    case zeroPage		// one byte address operand (e.g. LDA $42)
    case zeroPageX		// adds X to zero-page address (e.g. LDA $42,X)
    case zeroPageY		// adds Y to zero-page address (e.g. LDA $42,Y)
    case indirect		// absolute indirect, JMP only (e.g. JMP $fffe)
    case indexedIndirect // index ZP addres with X, fetch address from there (e.g. LDA ($20,X))
    case indirectIndexed // fetch 16-bit address from ZP, then add & to it (e.g. LDA($20), Y)
    case relative		// branch opcodes only (e.g. BEQ .label, where label is -128 to +127 one byte signed offset)
    // three byte ops
    case absolute		// full 16-bit address operand (e.g. LDA $4200)
    case absoluteX		// adds X to 16-bit address op (e.g. LDA $4200,X)
    case absoluteY		// adds Y to 16-bit address op (e.g. LDA $4200,Y)
    
    var byteSize: Int {
        switch self {
        case .implied, .accumulator: return 1
        case .immediate, .zeroPage, .zeroPageX, .zeroPageY, .indexedIndirect, .indirectIndexed, .relative: return 2
        case .absolute, .absoluteX, .absoluteY, .indirect: return 3
        }
    }
}

struct Opcode {
    let hex: UInt8
    let mnemonic: String
    let mode: AddressingMode
}

struct OpcodeTable {
    static let allOpcodes: [Opcode] = [
        // MARK: - 0x00 to 0x0F
        Opcode(hex: 0x00, mnemonic: "BRK", mode: .implied),
        Opcode(hex: 0x01, mnemonic: "ORA", mode: .indexedIndirect),
        Opcode(hex: 0x05, mnemonic: "ORA", mode: .zeroPage),
        Opcode(hex: 0x06, mnemonic: "ASL", mode: .zeroPage),
        Opcode(hex: 0x08, mnemonic: "PHP", mode: .implied),
        Opcode(hex: 0x09, mnemonic: "ORA", mode: .immediate),
        Opcode(hex: 0x0A, mnemonic: "ASL", mode: .accumulator),
        Opcode(hex: 0x0D, mnemonic: "ORA", mode: .absolute),
        Opcode(hex: 0x0E, mnemonic: "ASL", mode: .absolute),

        // MARK: - 0x10 to 0x1F
        Opcode(hex: 0x10, mnemonic: "BPL", mode: .relative),
        Opcode(hex: 0x11, mnemonic: "ORA", mode: .indirectIndexed),
        Opcode(hex: 0x15, mnemonic: "ORA", mode: .zeroPageX),
        Opcode(hex: 0x16, mnemonic: "ASL", mode: .zeroPageX),
        Opcode(hex: 0x18, mnemonic: "CLC", mode: .implied),
        Opcode(hex: 0x1D, mnemonic: "ORA", mode: .absoluteX),
        Opcode(hex: 0x1E, mnemonic: "ASL", mode: .absoluteX),

        // MARK: - 0x20 to 0x2F
        Opcode(hex: 0x20, mnemonic: "JSR", mode: .absolute),
        Opcode(hex: 0x21, mnemonic: "AND", mode: .indexedIndirect),
        Opcode(hex: 0x24, mnemonic: "BIT", mode: .zeroPage),
        Opcode(hex: 0x25, mnemonic: "AND", mode: .zeroPage),
        Opcode(hex: 0x26, mnemonic: "ROL", mode: .zeroPage),
        Opcode(hex: 0x28, mnemonic: "PLP", mode: .implied),
        Opcode(hex: 0x29, mnemonic: "AND", mode: .immediate),
        Opcode(hex: 0x2A, mnemonic: "ROL", mode: .accumulator),
        Opcode(hex: 0x2C, mnemonic: "BIT", mode: .absolute),
        Opcode(hex: 0x2D, mnemonic: "AND", mode: .absolute),
        Opcode(hex: 0x2E, mnemonic: "ROL", mode: .absolute),

        // MARK: - 0x30 to 0x3F
        Opcode(hex: 0x30, mnemonic: "BMI", mode: .relative),
        Opcode(hex: 0x31, mnemonic: "AND", mode: .indirectIndexed),
        Opcode(hex: 0x35, mnemonic: "AND", mode: .zeroPageX),
        Opcode(hex: 0x36, mnemonic: "ROL", mode: .zeroPageX),
        Opcode(hex: 0x38, mnemonic: "SEC", mode: .implied),
        Opcode(hex: 0x3D, mnemonic: "AND", mode: .absoluteX),
        Opcode(hex: 0x3E, mnemonic: "ROL", mode: .absoluteX),

        // MARK: - 0x40 to 0x4F
        Opcode(hex: 0x40, mnemonic: "RTI", mode: .implied),
        Opcode(hex: 0x41, mnemonic: "EOR", mode: .indexedIndirect),
        Opcode(hex: 0x45, mnemonic: "EOR", mode: .zeroPage),
        Opcode(hex: 0x46, mnemonic: "LSR", mode: .zeroPage),
        Opcode(hex: 0x48, mnemonic: "PHA", mode: .implied),
        Opcode(hex: 0x49, mnemonic: "EOR", mode: .immediate),
        Opcode(hex: 0x4A, mnemonic: "LSR", mode: .accumulator),
        Opcode(hex: 0x4C, mnemonic: "JMP", mode: .absolute),
        Opcode(hex: 0x4D, mnemonic: "EOR", mode: .absolute),
        Opcode(hex: 0x4E, mnemonic: "LSR", mode: .absolute),

        // MARK: - 0x50 to 0x5F
        Opcode(hex: 0x50, mnemonic: "BVC", mode: .relative),
        Opcode(hex: 0x51, mnemonic: "EOR", mode: .indirectIndexed),
        Opcode(hex: 0x55, mnemonic: "EOR", mode: .zeroPageX),
        Opcode(hex: 0x56, mnemonic: "LSR", mode: .zeroPageX),
        Opcode(hex: 0x58, mnemonic: "CLI", mode: .implied),
        Opcode(hex: 0x5D, mnemonic: "EOR", mode: .absoluteX),
        Opcode(hex: 0x5E, mnemonic: "LSR", mode: .absoluteX),

        // MARK: - 0x60 to 0x6F
        Opcode(hex: 0x60, mnemonic: "RTS", mode: .implied),
        Opcode(hex: 0x61, mnemonic: "ADC", mode: .indexedIndirect),
        Opcode(hex: 0x65, mnemonic: "ADC", mode: .zeroPage),
        Opcode(hex: 0x66, mnemonic: "ROR", mode: .zeroPage),
        Opcode(hex: 0x68, mnemonic: "PLA", mode: .implied),
        Opcode(hex: 0x69, mnemonic: "ADC", mode: .immediate),
        Opcode(hex: 0x6A, mnemonic: "ROR", mode: .accumulator),
        Opcode(hex: 0x6C, mnemonic: "JMP", mode: .indirect),
        Opcode(hex: 0x6D, mnemonic: "ADC", mode: .absolute),
        Opcode(hex: 0x6E, mnemonic: "ROR", mode: .absolute),

        // MARK: - 0x70 to 0x7F
        Opcode(hex: 0x70, mnemonic: "BVS", mode: .relative),
        Opcode(hex: 0x71, mnemonic: "ADC", mode: .indirectIndexed),
        Opcode(hex: 0x75, mnemonic: "ADC", mode: .zeroPageX),
        Opcode(hex: 0x76, mnemonic: "ROR", mode: .zeroPageX),
        Opcode(hex: 0x78, mnemonic: "SEI", mode: .implied),
        Opcode(hex: 0x7D, mnemonic: "ADC", mode: .absoluteX),
        Opcode(hex: 0x7E, mnemonic: "ROR", mode: .absoluteX),

        // MARK: - 0x80 to 0x8F
        Opcode(hex: 0x81, mnemonic: "STA", mode: .indexedIndirect),
        Opcode(hex: 0x84, mnemonic: "STY", mode: .zeroPage),
        Opcode(hex: 0x85, mnemonic: "STA", mode: .zeroPage),
        Opcode(hex: 0x86, mnemonic: "STX", mode: .zeroPage),
        Opcode(hex: 0x88, mnemonic: "DEY", mode: .implied),
        Opcode(hex: 0x8A, mnemonic: "TXA", mode: .implied),
        Opcode(hex: 0x8C, mnemonic: "STY", mode: .absolute),
        Opcode(hex: 0x8D, mnemonic: "STA", mode: .absolute),
        Opcode(hex: 0x8E, mnemonic: "STX", mode: .absolute),

        // MARK: - 0x90 to 0x9F
        Opcode(hex: 0x90, mnemonic: "BCC", mode: .relative),
        Opcode(hex: 0x91, mnemonic: "STA", mode: .indirectIndexed),
        Opcode(hex: 0x94, mnemonic: "STY", mode: .zeroPageX),
        Opcode(hex: 0x95, mnemonic: "STA", mode: .zeroPageX),
        Opcode(hex: 0x96, mnemonic: "STX", mode: .zeroPageY),
        Opcode(hex: 0x98, mnemonic: "TYA", mode: .implied),
        Opcode(hex: 0x99, mnemonic: "STA", mode: .absoluteY),
        Opcode(hex: 0x9A, mnemonic: "TXS", mode: .implied),
        Opcode(hex: 0x9D, mnemonic: "STA", mode: .absoluteX),

        // MARK: - 0xA0 to 0xAF
        Opcode(hex: 0xA0, mnemonic: "LDY", mode: .immediate),
        Opcode(hex: 0xA1, mnemonic: "LDA", mode: .indexedIndirect),
        Opcode(hex: 0xA2, mnemonic: "LDX", mode: .immediate),
        Opcode(hex: 0xA4, mnemonic: "LDY", mode: .zeroPage),
        Opcode(hex: 0xA5, mnemonic: "LDA", mode: .zeroPage),
        Opcode(hex: 0xA6, mnemonic: "LDX", mode: .zeroPage),
        Opcode(hex: 0xA8, mnemonic: "TAY", mode: .implied),
        Opcode(hex: 0xA9, mnemonic: "LDA", mode: .immediate),
        Opcode(hex: 0xAA, mnemonic: "TAX", mode: .implied),
        Opcode(hex: 0xAC, mnemonic: "LDY", mode: .absolute),
        Opcode(hex: 0xAD, mnemonic: "LDA", mode: .absolute),
        Opcode(hex: 0xAE, mnemonic: "LDX", mode: .absolute),

        // MARK: - 0xB0 to 0xBF
        Opcode(hex: 0xB0, mnemonic: "BCS", mode: .relative),
        Opcode(hex: 0xB1, mnemonic: "LDA", mode: .indirectIndexed),
        Opcode(hex: 0xB4, mnemonic: "LDY", mode: .zeroPageX),
        Opcode(hex: 0xB5, mnemonic: "LDA", mode: .zeroPageX),
        Opcode(hex: 0xB6, mnemonic: "LDX", mode: .zeroPageY),
        Opcode(hex: 0xB8, mnemonic: "CLV", mode: .implied),
        Opcode(hex: 0xB9, mnemonic: "LDA", mode: .absoluteY),
        Opcode(hex: 0xBA, mnemonic: "TSX", mode: .implied),
        Opcode(hex: 0xBC, mnemonic: "LDY", mode: .absoluteX),
        Opcode(hex: 0xBD, mnemonic: "LDA", mode: .absoluteX),
        Opcode(hex: 0xBE, mnemonic: "LDX", mode: .absoluteY),

        // MARK: - 0xC0 to 0xCF
        Opcode(hex: 0xC0, mnemonic: "CPY", mode: .immediate),
        Opcode(hex: 0xC1, mnemonic: "CMP", mode: .indexedIndirect),
        Opcode(hex: 0xC4, mnemonic: "CPY", mode: .zeroPage),
        Opcode(hex: 0xC5, mnemonic: "CMP", mode: .zeroPage),
        Opcode(hex: 0xC6, mnemonic: "DEC", mode: .zeroPage),
        Opcode(hex: 0xC8, mnemonic: "INY", mode: .implied),
        Opcode(hex: 0xC9, mnemonic: "CMP", mode: .immediate),
        Opcode(hex: 0xCA, mnemonic: "DEX", mode: .implied),
        Opcode(hex: 0xCC, mnemonic: "CPY", mode: .absolute),
        Opcode(hex: 0xCD, mnemonic: "CMP", mode: .absolute),
        Opcode(hex: 0xCE, mnemonic: "DEC", mode: .absolute),

        // MARK: - 0xD0 to 0xDF
        Opcode(hex: 0xD0, mnemonic: "BNE", mode: .relative),
        Opcode(hex: 0xD1, mnemonic: "CMP", mode: .indirectIndexed),
        Opcode(hex: 0xD5, mnemonic: "CMP", mode: .zeroPageX),
        Opcode(hex: 0xD6, mnemonic: "DEC", mode: .zeroPageX),
        Opcode(hex: 0xD8, mnemonic: "CLD", mode: .implied),
        Opcode(hex: 0xDD, mnemonic: "CMP", mode: .absoluteX),
        Opcode(hex: 0xDE, mnemonic: "DEC", mode: .absoluteX),

        // MARK: - 0xE0 to 0xEF
        Opcode(hex: 0xE0, mnemonic: "CPX", mode: .immediate),
        Opcode(hex: 0xE1, mnemonic: "SBC", mode: .indexedIndirect),
        Opcode(hex: 0xE4, mnemonic: "CPX", mode: .zeroPage),
        Opcode(hex: 0xE5, mnemonic: "SBC", mode: .zeroPage),
        Opcode(hex: 0xE6, mnemonic: "INC", mode: .zeroPage),
        Opcode(hex: 0xE8, mnemonic: "INX", mode: .implied),
        Opcode(hex: 0xE9, mnemonic: "SBC", mode: .immediate),
        Opcode(hex: 0xEA, mnemonic: "NOP", mode: .implied),
        Opcode(hex: 0xEC, mnemonic: "CPX", mode: .absolute),
        Opcode(hex: 0xED, mnemonic: "SBC", mode: .absolute),
        Opcode(hex: 0xEE, mnemonic: "INC", mode: .absolute),

        // MARK: - 0xF0 to 0xFF
        Opcode(hex: 0xF0, mnemonic: "BEQ", mode: .relative),
        Opcode(hex: 0xF1, mnemonic: "SBC", mode: .indirectIndexed),
        Opcode(hex: 0xF5, mnemonic: "SBC", mode: .zeroPageX),
        Opcode(hex: 0xF6, mnemonic: "INC", mode: .zeroPageX),
        Opcode(hex: 0xF8, mnemonic: "SED", mode: .implied),
        Opcode(hex: 0xFD, mnemonic: "SBC", mode: .absoluteX),
        Opcode(hex: 0xFE, mnemonic: "INC", mode: .absoluteX)
    ]
    
    // Quick lookups optimized for compiling/decompiling
    static let assemblerLookup: [String: [AddressingMode: UInt8]] = {
        var map = [String: [AddressingMode: UInt8]]()
        for op in allOpcodes {
            map[op.mnemonic, default: [:]][op.mode] = op.hex
        }
        return map
    }()
}

/*
func compileInstruction(mnemonic: String, mode: AddressingMode) -> UInt8? {
    let cleanMnemonic = mnemonic.uppercased()
    return OpcodeTable.assemblerLookup[cleanMnemonic]?[mode]
}

// Example evaluation:
if let hexOpcode = compileInstruction(mnemonic: "LDA", mode: .immediate) {
    print(String(format: "Machine code: 0x%02X", hexOpcode)) // Outputs: 0xA9
} else {
    print("Invalid instruction or addressing mode pairing.")
}
*/
