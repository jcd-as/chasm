//
//  chasmTest.swift
//  chasmTest
//
//  Created by Josh Shepard on 9/20/26.
//

import Testing
import Foundation
import ArgumentParser
@testable import chasm

// dummy class to locate resource files for testing
private final class BundleFinder {}

private func fileURL(_ forFile: String, withExtension: String) throws -> URL {
    let bundle = Bundle(for: BundleFinder.self)
    let url = try #require(bundle.url(forResource: forFile, withExtension: withExtension))
    return url
}
struct chasmTest {

    @Test func directiveTest() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        // Swift Testing Documentation
        // https://developer.apple.com/documentation/testing

        let fnurl = try fileURL("directivetest01", withExtension: "chasm")
        let args = [fnurl.path()]
        let cmd = try Chasm.parseAsRoot(args)
        var chasmcmd = try #require(cmd as? Chasm)
        try chasmcmd.run()

        #expect(chasmcmd.preprocInput.count == 1)
        switch chasmcmd.preprocInput[0] {
        case .directive(let directive):
            #expect(directive.name == ".ORG")
            #expect(directive.content == "$1000")
            #expect(directive.newPC == 4096)
        case .code:
            #expect(Bool(false))
        }
    }

    @Test func opcodesTest() async throws {
        let fnurl = try fileURL("opcodestest01", withExtension: "chasm")
        let args = [fnurl.path()]
        let cmd = try Chasm.parseAsRoot(args)
        var chasmcmd = try #require(cmd as? Chasm)
        try chasmcmd.run()

        // number of non-blank (or comment-only) lines:
        // TODO: update as lines are added to test file...
        #expect(chasmcmd.preprocInput.count == 29)

        // line 1 (lea $42)
        switch chasmcmd.preprocInput[0] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .zeroPage)
            #expect(code.op!.hex == 0xA5)
            #expect(code.arg1 == "$42")
            #expect(code.arg2 == "")
        }
        // line 2 (lea $43 ; comment)
        switch chasmcmd.preprocInput[1] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .zeroPage)
            #expect(code.op!.hex == 0xA5)
            #expect(code.arg1 == "$43")
            #expect(code.arg2 == "")
        }
        // line 3 (lab1:    lea $44)
        switch chasmcmd.preprocInput[2] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .zeroPage)
            #expect(code.op!.hex == 0xA5)
            #expect(code.arg1 == "$44")
            #expect(code.arg2 == "")
            #expect(code.label == "LAB1")
        }
        // line 4 (lab1:    lea $45     ; comment)
        switch chasmcmd.preprocInput[3] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .zeroPage)
            #expect(code.op!.hex == 0xA5)
            #expect(code.arg1 == "$45")
            #expect(code.arg2 == "")
            #expect(code.label == "LAB2")
        }

        // line 5 blank
        // line 6 comment only (blank)
        // line 7 blank

        // line 8 (tax             ; implied)
        switch chasmcmd.preprocInput[4] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "TAX")
            #expect(code.op!.mode == .implied)
            #expect(code.op!.hex == 0xAA)
            #expect(code.arg1 == "")
            #expect(code.arg2 == "")
        }
        // line 9 (asl a           ; accumulator)
        switch chasmcmd.preprocInput[5] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "ASL")
            #expect(code.op!.mode == .accumulator)
            #expect(code.op!.hex == 0x0A)
            #expect(code.arg1 == "A")
            #expect(code.arg2 == "")
        }
        // line 10 (lda #$ff        ; immediate)
        switch chasmcmd.preprocInput[6] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .immediate)
            #expect(code.op!.hex == 0xA9)
            #expect(code.arg1 == "#$FF")
            #expect(code.arg2 == "")
        }
        //line 11 (LDA $42, x      ; zero-page,x)
        switch chasmcmd.preprocInput[7] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .zeroPageX)
            #expect(code.op!.hex == 0xB5)
            #expect(code.arg1 == "$42")
            #expect(code.arg2 == "X")
        }
        // line 12 (ldx $42, Y      ; zero-page,y)
        switch chasmcmd.preprocInput[8] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDX")
            #expect(code.op!.mode == .zeroPageY)
            #expect(code.op!.hex == 0xB6)
            #expect(code.arg1 == "$42")
            #expect(code.arg2 == "Y")
        }
        // line 13 - blank

        // line 14 (jmp ($fffe)      ; (absolute) indirect)
        switch chasmcmd.preprocInput[9] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "JMP")
            #expect(code.op!.mode == .indirect)
            #expect(code.op!.hex == 0x6C)
            #expect(code.arg1 == "($FFFE)")
            #expect(code.arg2 == "")
        }

        // line 15 (;JMP lab2       ; absolute, handle labels COMMENTED OUT)

        // line 16 (JMP lab2       ; absolute, handle labels)
        switch chasmcmd.preprocInput[10] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "JMP")
            #expect(code.op!.mode == .absolute)
            #expect(code.op!.hex == 0x4C)
            #expect(code.arg1 == "LAB2")
            #expect(code.arg2 == "")
        }

        // line 17 (lda ($20, X)    ; indexed indirect)
        switch chasmcmd.preprocInput[11] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .indexedIndirect)
            #expect(code.op!.hex == 0xA1)
            #expect(code.arg1 == "($20")
            #expect(code.arg2 == "X)")
        }

        // line 18 (lda ($20), Y    ; indirect indexed)
        switch chasmcmd.preprocInput[12] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .indirectIndexed)
            #expect(code.op!.hex == 0xB1)
            #expect(code.arg1 == "($20)")
            #expect(code.arg2 == "Y")
        }

        // line 19 (lda $4200       ; absolute)
        switch chasmcmd.preprocInput[13] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .absolute)
            #expect(code.op!.hex == 0xAD)
            #expect(code.arg1 == "$4200")
            #expect(code.arg2 == "")
        }

        // line 20 (lda $4200, x    ; absolute x)
        switch chasmcmd.preprocInput[14] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .absoluteX)
            #expect(code.op!.hex == 0xBD)
            #expect(code.arg1 == "$4200")
            #expect(code.arg2 == "X")
        }
        // line 21 (lda $4200, y    ; absolute y)
        switch chasmcmd.preprocInput[15] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .absoluteY)
            #expect(code.op!.hex == 0xB9)
            #expect(code.arg1 == "$4200")
            #expect(code.arg2 == "Y")
        }

        // line 22 (BEQ lab1       ; TBD - relative, handle labels)
        switch chasmcmd.preprocInput[16] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "BEQ")
            #expect(code.op!.mode == .relative)
            #expect(code.op!.hex == 0xF0)
            #expect(code.arg1 == "LAB1")
            #expect(code.arg2 == "")
        }

        // line 23 (BCS $80       ; relative)
        switch chasmcmd.preprocInput[17] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "BCS")
            #expect(code.op!.mode == .relative)
            #expect(code.op!.hex == 0xB0)
            #expect(code.arg1 == "$80")
            #expect(code.arg2 == "")
        }

        // line 24 (lda not_yet_declared, x)
        switch chasmcmd.preprocInput[18] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .absoluteX)
            #expect(code.op!.hex == 0xBD)
            #expect(code.arg1 == "NOT_YET_DECLARED")
            #expect(code.arg2 == "X")
        }

        // line 25 (lda also_not_yet_declared, y)
        switch chasmcmd.preprocInput[19] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .absoluteY)
            #expect(code.op!.hex == 0xB9)
            #expect(code.arg1 == "ALSO_NOT_YET_DECLARED")
            #expect(code.arg2 == "Y")
        }
        
        // line 26 - not_yet_declared:
        switch chasmcmd.preprocInput[20] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.linenum == 25)
            #expect(code.offset == 45)
            #expect(code.label == "NOT_YET_DECLARED")
            #expect(code.op == nil)
            #expect(code.arg1 == "")
            #expect(code.arg2 == "")
        }
        
        // line 27 - not_yet_declared:
        switch chasmcmd.preprocInput[21] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.linenum == 26)
            #expect(code.offset == 45)
            #expect(code.label == "ALSO_NOT_YET_DECLARED")
            #expect(code.op == nil)
            #expect(code.arg1 == "")
            #expect(code.arg2 == "")
        }
        
        // line 29 - jmp (lab1)
        switch chasmcmd.preprocInput[22] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "JMP")
            #expect(code.op!.mode == .indirect)
            #expect(code.op!.hex == 0x6C)
            #expect(code.arg1 == "(LAB1)")
            #expect(code.arg2 == "")
        }

        // line 30 - lda <ALSO_NOT_YET_DECLARED      ; low-byte of label
        switch chasmcmd.preprocInput[23] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .zeroPage)
            #expect(code.op!.hex == 0xA5)
            #expect(code.arg1 == "<ALSO_NOT_YET_DECLARED")
            #expect(code.arg2 == "")
        }

        // line 31 - lda >ALSO_NOT_YET_DECLARED      ; high-byte of label
        switch chasmcmd.preprocInput[24] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .zeroPage)
            #expect(code.op!.hex == 0xA5)
            #expect(code.arg1 == ">ALSO_NOT_YET_DECLARED")
            #expect(code.arg2 == "")
        }

        // line 32 - lda #<ALSO_NOT_YET_DECLARED      ; low-byte of label
        switch chasmcmd.preprocInput[25] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .immediate)
            #expect(code.op!.hex == 0xA9)
            #expect(code.arg1 == "#<ALSO_NOT_YET_DECLARED")
            #expect(code.arg2 == "")
        }

        // line 33 - lda #>ALSO_NOT_YET_DECLARED      ; high-byte of label
        switch chasmcmd.preprocInput[26] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDA")
            #expect(code.op!.mode == .immediate)
            #expect(code.op!.hex == 0xA9)
            #expect(code.arg1 == "#>ALSO_NOT_YET_DECLARED")
            #expect(code.arg2 == "")
        }

        // line 34 - ldx <not_yet_declared, y
        switch chasmcmd.preprocInput[27] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDX")
            #expect(code.op!.mode == .zeroPageY)
            #expect(code.op!.hex == 0xB6)
            #expect(code.arg1 == "<NOT_YET_DECLARED")
            #expect(code.arg2 == "Y")
        }

        // line 35 - ldx >not_yet_declared, y
        switch chasmcmd.preprocInput[28] {
        case .directive:
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op!.mnemonic == "LDX")
            #expect(code.op!.mode == .zeroPageY)
            #expect(code.op!.hex == 0xB6)
            #expect(code.arg1 == ">NOT_YET_DECLARED")
            #expect(code.arg2 == "Y")
        }
    }

    @Test func passOneTest01() async throws {
        let fnurl = try fileURL("passonetest01", withExtension: "chasm")
        let args = [fnurl.path()]
        let cmd = try Chasm.parseAsRoot(args)
        var chasmcmd = try #require(cmd as? Chasm)
        try chasmcmd.run()

        #expect(chasmcmd.preprocInput.count == 9)
        
        // line 1 - ORG
        switch chasmcmd.preprocInput[0] {
        case .directive(let d):
            #expect(d.linenum == 0)
            #expect(d.name == ".ORG")
            #expect(d.content == "$0000")
        case .code:
            #expect(Bool(false))
        }
        // line 2 - BYTE
        switch chasmcmd.preprocInput[1] {
        case .directive(let d):
            #expect(d.linenum == 1)
            #expect(d.name == ".BYTE")
            #expect(d.content == "$00, $100")
        case .code:
            #expect(Bool(false))
        }
        // line 3 - cli
        switch chasmcmd.preprocInput[2] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.linenum == 3)
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CLI")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x58)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }
        // line 4 - loop:   lda #$ea
        switch chasmcmd.preprocInput[3] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.linenum == 4)
            #expect(c.label == "LOOP")
            #expect(c.op!.mnemonic == "LDA")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xA9)
            #expect(c.arg1 == "#$EA")
            #expect(c.arg2 == "")
        }
        // line 5 - ldx #255
        switch chasmcmd.preprocInput[4] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.linenum == 5)
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDX")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xA2)
            #expect(c.arg1 == "#255")
            #expect(c.arg2 == "")
        }
        // line 6 - sta $00, x
        switch chasmcmd.preprocInput[5] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.linenum == 6)
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STA")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x95)
            #expect(c.arg1 == "$00")
            #expect(c.arg2 == "X")
        }
        // line 7 - cpx #0
        switch chasmcmd.preprocInput[6] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.linenum == 7)
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CPX")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xE0)
            #expect(c.arg1 == "#0")
            #expect(c.arg2 == "")
        }
        // line 8 - BnE loop
        switch chasmcmd.preprocInput[7] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.linenum == 8)
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "BNE")
            #expect(c.op!.mode == .relative)
            #expect(c.op!.hex == 0xD0)
            #expect(c.arg1 == "LOOP")
            #expect(c.arg2 == "")
        }
        // line 9 - BRK
        switch chasmcmd.preprocInput[8] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.linenum == 9)
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "BRK")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x00)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }
    }
    
    @Test func passTwoTest01() async throws {
        let fnurl = try fileURL("passtwotest01", withExtension: "chasm")
        let args = [fnurl.path()]
        let cmd = try Chasm.parseAsRoot(args)
        var chasmcmd = try #require(cmd as? Chasm)
        try chasmcmd.run()

        // verify that the output of pass two is 256 bytes of zeros
        #expect(chasmcmd.buf.count == 256)
        #expect(chasmcmd.buf.allSatisfy{ $0 == 0 })
    }
    
    @Test func passTwoTest02() async throws {
        let fnurl = try fileURL("passonetest01", withExtension: "chasm")
        let args = [fnurl.path()]
        let cmd = try Chasm.parseAsRoot(args)
        var chasmcmd = try #require(cmd as? Chasm)
        try chasmcmd.run()

        
        // verify that the output of pass two is 256 bytes of zeros
        #expect(chasmcmd.buf.count == 268)
        //#expect(chasmcmd.buf.allSatisfy{ $0 == 0 })
        // spot check some in the first page for zero
        #expect(chasmcmd.buf[0] == 0x00)
        #expect(chasmcmd.buf[16] == 0x00)
        #expect(chasmcmd.buf[64] == 0x00)
        #expect(chasmcmd.buf[192] == 0x00)
        #expect(chasmcmd.buf[255] == 0x00)

        // TODO: verify the rest of the bytes
        #expect(chasmcmd.buf[256] == 0x58)
        #expect(chasmcmd.buf[257] == 0xA9)
        #expect(chasmcmd.buf[258] == 0xEA)
        #expect(chasmcmd.buf[259] == 0xA2)
        #expect(chasmcmd.buf[260] == 0xFF)
        #expect(chasmcmd.buf[261] == 0x95)
        #expect(chasmcmd.buf[262] == 0x00)
        #expect(chasmcmd.buf[263] == 0xE0)
        #expect(chasmcmd.buf[264] == 0x00)
        #expect(chasmcmd.buf[265] == 0xD0)
        #expect(chasmcmd.buf[266] == 0xF6)
        #expect(chasmcmd.buf[267] == 0x00)
    }
    
    @Test func opcodestest02() async throws {
        let fnurl = try fileURL("opcodestest02", withExtension: "chasm")
        let args = [fnurl.path()]
        let cmd = try Chasm.parseAsRoot(args)
        var chasmcmd = try #require(cmd as? Chasm)
        try chasmcmd.run()

        //; 0x00 to 0x0F
        //;Opcode(hex: 0x00, mnemonic: "BRK", mode: .implied),
        //brk
        switch chasmcmd.preprocInput[0] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "BRK")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x00)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }
        
        //;Opcode(hex: 0x01, mnemonic: "ORA", mode: .indexedIndirect),
        //ora ($20, x)
        switch chasmcmd.preprocInput[1] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ORA")
            #expect(c.op!.mode == .indexedIndirect)
            #expect(c.op!.hex == 0x01)
            #expect(c.arg1 == "($20")
            #expect(c.arg2 == "X)")
        }

        //;Opcode(hex: 0x05, mnemonic: "ORA", mode: .zeroPage),
        //ora $20
        switch chasmcmd.preprocInput[2] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ORA")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x05)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x06, mnemonic: "ASL", mode: .zeroPage),
        //asl $20
        switch chasmcmd.preprocInput[3] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ASL")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x06)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x08, mnemonic: "PHP", mode: .implied),
        //php
        switch chasmcmd.preprocInput[4] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "PHP")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x08)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x09, mnemonic: "ORA", mode: .immediate),
        //ora #$20
         switch chasmcmd.preprocInput[5] {
         case .directive:
             #expect(Bool(false))
         case .code(let c):
             #expect(c.label == "")
             #expect(c.op!.mnemonic == "ORA")
             #expect(c.op!.mode == .immediate)
             #expect(c.op!.hex == 0x09)
             #expect(c.arg1 == "#$20")
             #expect(c.arg2 == "")
         }

        //;Opcode(hex: 0x0A, mnemonic: "ASL", mode: .accumulator),
        //asl a
        switch chasmcmd.preprocInput[6] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ASL")
            #expect(c.op!.mode == .accumulator)
            #expect(c.op!.hex == 0x0a)
            #expect(c.arg1 == "A")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x0D, mnemonic: "ORA", mode: .absolute),
        //ora $a000
        switch chasmcmd.preprocInput[7] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ORA")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x0d)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x0E, mnemonic: "ASL", mode: .absolute),
        //asl $a000
        switch chasmcmd.preprocInput[8] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ASL")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x0e)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }
        
        //; 0x10 to 0x1F

        //;Opcode(hex: 0x10, mnemonic: "BPL", mode: .relative),
        //label1: bpl label1
        switch chasmcmd.preprocInput[9] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "LABEL1")
            #expect(c.op!.mnemonic == "BPL")
            #expect(c.op!.mode == .relative)
            #expect(c.op!.hex == 0x10)
            #expect(c.arg1 == "LABEL1")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x11, mnemonic: "ORA", mode: .indirectIndexed),
        //ora ($20), y
        switch chasmcmd.preprocInput[10] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ORA")
            #expect(c.op!.mode == .indirectIndexed)
            #expect(c.op!.hex == 0x11)
            #expect(c.arg1 == "($20)")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0x15, mnemonic: "ORA", mode: .zeroPageX),
        //ora $20,x
        switch chasmcmd.preprocInput[11] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ORA")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x15)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x16, mnemonic: "ASL", mode: .zeroPageX),
        //asl $20,x
        switch chasmcmd.preprocInput[12] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ASL")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x16)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x18, mnemonic: "CLC", mode: .implied),
        //clc
        switch chasmcmd.preprocInput[13] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CLC")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x18)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x1D, mnemonic: "ORA", mode: .absoluteX),
        //ora $a000, x
        switch chasmcmd.preprocInput[14] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ORA")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0x1D)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x1E, mnemonic: "ASL", mode: .absoluteX),
        //asl $a000, x
        switch chasmcmd.preprocInput[15] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ASL")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0x1E)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        // 0x20 to 0x2F

        //;Opcode(hex: 0x20, mnemonic: "JSR", mode: .absolute),
        //jsr $a000
        switch chasmcmd.preprocInput[16] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "JSR")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x20)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x21, mnemonic: "AND", mode: .indexedIndirect),
        //and ($20, x)
        switch chasmcmd.preprocInput[17] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "AND")
            #expect(c.op!.mode == .indexedIndirect)
            #expect(c.op!.hex == 0x21)
            #expect(c.arg1 == "($20")
            #expect(c.arg2 == "X)")
        }

        //;Opcode(hex: 0x24, mnemonic: "BIT", mode: .zeroPage),
        //bit $20
        switch chasmcmd.preprocInput[18] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "BIT")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x24)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x25, mnemonic: "AND", mode: .zeroPage),
        //and $20
        switch chasmcmd.preprocInput[19] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "AND")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x25)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x26, mnemonic: "ROL", mode: .zeroPage),
        //rol $20
        switch chasmcmd.preprocInput[20] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROL")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x26)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x28, mnemonic: "PLP", mode: .implied),
        //plp
        switch chasmcmd.preprocInput[21] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "PLP")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x28)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x29, mnemonic: "AND", mode: .immediate),
        //and #$20
        switch chasmcmd.preprocInput[22] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "AND")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0x29)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x2A, mnemonic: "ROL", mode: .accumulator),
        //rol a
        switch chasmcmd.preprocInput[23] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROL")
            #expect(c.op!.mode == .accumulator)
            #expect(c.op!.hex == 0x2a)
            #expect(c.arg1 == "A")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x2C, mnemonic: "BIT", mode: .absolute),
        //bit $a000
        switch chasmcmd.preprocInput[24] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "BIT")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x2c)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x2D, mnemonic: "AND", mode: .absolute),
        //and $a000
        switch chasmcmd.preprocInput[25] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "AND")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x2d)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x2E, mnemonic: "ROL", mode: .absolute),
        //rol $a000
        switch chasmcmd.preprocInput[26] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROL")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x2e)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        // 0x30 to 0x3F

        //;Opcode(hex: 0x30, mnemonic: "BMI", mode: .relative),
        //label2: bmi label2
        switch chasmcmd.preprocInput[27] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "LABEL2")
            #expect(c.op!.mnemonic == "BMI")
            #expect(c.op!.mode == .relative)
            #expect(c.op!.hex == 0x30)
            #expect(c.arg1 == "LABEL2")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x31, mnemonic: "AND", mode: .indirectIndexed),
        //and ($20),y
        switch chasmcmd.preprocInput[28] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "AND")
            #expect(c.op!.mode == .indirectIndexed)
            #expect(c.op!.hex == 0x31)
            #expect(c.arg1 == "($20)")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0x35, mnemonic: "AND", mode: .zeroPageX),
        //and $20,x
        switch chasmcmd.preprocInput[29] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "AND")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x35)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x36, mnemonic: "ROL", mode: .zeroPageX),
        //rol $20, x
        switch chasmcmd.preprocInput[30] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROL")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x36)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x38, mnemonic: "SEC", mode: .implied),
        //sec
        switch chasmcmd.preprocInput[31] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SEC")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x38)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x3D, mnemonic: "AND", mode: .absoluteX),
        //and $a000,x
        switch chasmcmd.preprocInput[32] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "AND")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0x3D)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x3E, mnemonic: "ROL", mode: .absoluteX),
        //rol $a000, x
        switch chasmcmd.preprocInput[33] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROL")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0x3e)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        // 0x40 to 0x4F

        //;Opcode(hex: 0x40, mnemonic: "RTI", mode: .implied),
        //rti
        switch chasmcmd.preprocInput[34] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "RTI")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x40)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x41, mnemonic: "EOR", mode: .indexedIndirect),
        //eor ($20, x)
        switch chasmcmd.preprocInput[35] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "EOR")
            #expect(c.op!.mode == .indexedIndirect)
            #expect(c.op!.hex == 0x41)
            #expect(c.arg1 == "($20")
            #expect(c.arg2 == "X)")
        }

        //;Opcode(hex: 0x45, mnemonic: "EOR", mode: .zeroPage),
        //eor $20
        switch chasmcmd.preprocInput[36] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "EOR")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x45)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x46, mnemonic: "LSR", mode: .zeroPage),
        //lsr $20
        switch chasmcmd.preprocInput[37] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LSR")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x46)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x48, mnemonic: "PHA", mode: .implied),
        //pha
        switch chasmcmd.preprocInput[38] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "PHA")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x48)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x49, mnemonic: "EOR", mode: .immediate),
        //eor #$20
        switch chasmcmd.preprocInput[39] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "EOR")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0x49)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x4A, mnemonic: "LSR", mode: .accumulator),
        //lsr a
        switch chasmcmd.preprocInput[40] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LSR")
            #expect(c.op!.mode == .accumulator)
            #expect(c.op!.hex == 0x4A)
            #expect(c.arg1 == "A")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x4C, mnemonic: "JMP", mode: .absolute),
        //jmp $a000
        switch chasmcmd.preprocInput[41] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "JMP")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x4c)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x4D, mnemonic: "EOR", mode: .absolute),
        //eor $a000
        switch chasmcmd.preprocInput[42] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "EOR")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x4d)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x4E, mnemonic: "LSR", mode: .absolute),
        //lsr $a000
        switch chasmcmd.preprocInput[43] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LSR")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x4e)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        // 0x50 to 0x5F

        //;Opcode(hex: 0x50, mnemonic: "BVC", mode: .relative),
        //label3:     bvc  label3
        switch chasmcmd.preprocInput[44] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "LABEL3")
            #expect(c.op!.mnemonic == "BVC")
            #expect(c.op!.mode == .relative)
            #expect(c.op!.hex == 0x50)
            #expect(c.arg1 == "LABEL3")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x51, mnemonic: "EOR", mode: .indirectIndexed),
        //eor ($20),y
        switch chasmcmd.preprocInput[45] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "EOR")
            #expect(c.op!.mode == .indirectIndexed)
            #expect(c.op!.hex == 0x51)
            #expect(c.arg1 == "($20)")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0x55, mnemonic: "EOR", mode: .zeroPageX),
        //eor $20,x
        switch chasmcmd.preprocInput[46] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "EOR")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x55)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x56, mnemonic: "LSR", mode: .zeroPageX),
        //lsr $20, x
        switch chasmcmd.preprocInput[47] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LSR")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x56)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x58, mnemonic: "CLI", mode: .implied),
        //cli
        switch chasmcmd.preprocInput[48] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CLI")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x58)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x5D, mnemonic: "EOR", mode: .absoluteX),
        //eor $a000, x
        switch chasmcmd.preprocInput[49] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "EOR")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0x5D)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x5E, mnemonic: "LSR", mode: .absoluteX),
        //lsr $a000,x
        switch chasmcmd.preprocInput[50] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LSR")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0x5e)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        // 0x60 to 0x6F

        //;Opcode(hex: 0x60, mnemonic: "RTS", mode: .implied),
        //rts
        switch chasmcmd.preprocInput[51] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "RTS")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x60)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x61, mnemonic: "ADC", mode: .indexedIndirect),
        //adc ($20, x)
        switch chasmcmd.preprocInput[52] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ADC")
            #expect(c.op!.mode == .indexedIndirect)
            #expect(c.op!.hex == 0x61)
            #expect(c.arg1 == "($20")
            #expect(c.arg2 == "X)")
        }

        //;Opcode(hex: 0x65, mnemonic: "ADC", mode: .zeroPage),
        //adc $20
        switch chasmcmd.preprocInput[53] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ADC")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x65)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x66, mnemonic: "ROR", mode: .zeroPage),
        //ror $20
        switch chasmcmd.preprocInput[54] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROR")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x66)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x68, mnemonic: "PLA", mode: .implied),
        //pla
        switch chasmcmd.preprocInput[55] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "PLA")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x68)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x69, mnemonic: "ADC", mode: .immediate),
        //adc #$20
        switch chasmcmd.preprocInput[56] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ADC")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0x69)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x6A, mnemonic: "ROR", mode: .accumulator),
        //ror A
        switch chasmcmd.preprocInput[57] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROR")
            #expect(c.op!.mode == .accumulator)
            #expect(c.op!.hex == 0x6a)
            #expect(c.arg1 == "A")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x6C, mnemonic: "JMP", mode: .indirect),
        //jmp ($a000)
        switch chasmcmd.preprocInput[58] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "JMP")
            #expect(c.op!.mode == .indirect)
            #expect(c.op!.hex == 0x6c)
            #expect(c.arg1 == "($A000)")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x6D, mnemonic: "ADC", mode: .absolute),
        //adc $a000
        switch chasmcmd.preprocInput[59] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ADC")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x6d)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x6E, mnemonic: "ROR", mode: .absolute),
        //ror $a000
        switch chasmcmd.preprocInput[60] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROR")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x6e)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        // 0x70 to 0x7F

        //;Opcode(hex: 0x70, mnemonic: "BVS", mode: .relative),
        //label4: bvs label4
        switch chasmcmd.preprocInput[61] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "LABEL4")
            #expect(c.op!.mnemonic == "BVS")
            #expect(c.op!.mode == .relative)
            #expect(c.op!.hex == 0x70)
            #expect(c.arg1 == "LABEL4")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x71, mnemonic: "ADC", mode: .indirectIndexed),
        //adc ($20), y
        switch chasmcmd.preprocInput[62] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ADC")
            #expect(c.op!.mode == .indirectIndexed)
            #expect(c.op!.hex == 0x71)
            #expect(c.arg1 == "($20)")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0x75, mnemonic: "ADC", mode: .zeroPageX),
        //adc $20, x
        switch chasmcmd.preprocInput[63] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ADC")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x75)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x76, mnemonic: "ROR", mode: .zeroPageX),
        //ror $20, x
        switch chasmcmd.preprocInput[64] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROR")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x76)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x78, mnemonic: "SEI", mode: .implied),
        //sei
        switch chasmcmd.preprocInput[65] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SEI")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x78)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x7D, mnemonic: "ADC", mode: .absoluteX),
        //adc $a000,x
        switch chasmcmd.preprocInput[66] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ADC")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0x7D)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x7E, mnemonic: "ROR", mode: .absoluteX),
        //ror $a000, x
        switch chasmcmd.preprocInput[67] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "ROR")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0x7e)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        // 0x80 to 0x8F

        //;Opcode(hex: 0x81, mnemonic: "STA", mode: .indexedIndirect),
        //sta ($20, x)
        switch chasmcmd.preprocInput[68] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STA")
            #expect(c.op!.mode == .indexedIndirect)
            #expect(c.op!.hex == 0x81)
            #expect(c.arg1 == "($20")
            #expect(c.arg2 == "X)")
        }

        //;Opcode(hex: 0x84, mnemonic: "STY", mode: .zeroPage),
        //sty $20
        switch chasmcmd.preprocInput[69] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STY")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x84)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x85, mnemonic: "STA", mode: .zeroPage),
        //sta $20
        switch chasmcmd.preprocInput[70] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STA")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x85)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x86, mnemonic: "STX", mode: .zeroPage),
        //stx $20
        switch chasmcmd.preprocInput[71] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STX")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0x86)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x88, mnemonic: "DEY", mode: .implied),
        //dey
        switch chasmcmd.preprocInput[72] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "DEY")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x88)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x8A, mnemonic: "TXA", mode: .implied),
        //txa
        switch chasmcmd.preprocInput[73] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "TXA")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x8a)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x8C, mnemonic: "STY", mode: .absolute),
        //sty $a000
        switch chasmcmd.preprocInput[74] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STY")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x8c)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x8D, mnemonic: "STA", mode: .absolute),
        //sta $a000
        switch chasmcmd.preprocInput[75] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STA")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x8d)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x8E, mnemonic: "STX", mode: .absolute),
        //stx $a000
        switch chasmcmd.preprocInput[76] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STX")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0x8e)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        // 0x90 to 0x9F

        //;Opcode(hex: 0x90, mnemonic: "BCC", mode: .relative),
        //label5:     bcc     label5
        switch chasmcmd.preprocInput[77] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "LABEL5")
            #expect(c.op!.mnemonic == "BCC")
            #expect(c.op!.mode == .relative)
            #expect(c.op!.hex == 0x90)
            #expect(c.arg1 == "LABEL5")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x91, mnemonic: "STA", mode: .indirectIndexed),
        //sta ($20), y
        switch chasmcmd.preprocInput[78] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STA")
            #expect(c.op!.mode == .indirectIndexed)
            #expect(c.op!.hex == 0x91)
            #expect(c.arg1 == "($20)")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0x94, mnemonic: "STY", mode: .zeroPageX),
        //sty $20, x
        switch chasmcmd.preprocInput[79] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STY")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x94)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x95, mnemonic: "STA", mode: .zeroPageX),
        //sta $20,x
        switch chasmcmd.preprocInput[80] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STA")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0x95)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0x96, mnemonic: "STX", mode: .zeroPageY),
        //stx $20, y
        switch chasmcmd.preprocInput[81] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STX")
            #expect(c.op!.mode == .zeroPageY)
            #expect(c.op!.hex == 0x96)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0x98, mnemonic: "TYA", mode: .implied),
        //tya
        switch chasmcmd.preprocInput[82] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "TYA")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x98)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x99, mnemonic: "STA", mode: .absoluteY),
        //sta $a000,y
        switch chasmcmd.preprocInput[83] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STA")
            #expect(c.op!.mode == .absoluteY)
            #expect(c.op!.hex == 0x99)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0x9A, mnemonic: "TXS", mode: .implied),
        //txs
        switch chasmcmd.preprocInput[84] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "TXS")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0x9a)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0x9D, mnemonic: "STA", mode: .absoluteX),
        //sta $a000, x
        switch chasmcmd.preprocInput[85] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "STA")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0x9d)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        // 0xA0 to 0xAF

        //;Opcode(hex: 0xA0, mnemonic: "LDY", mode: .immediate),
        //ldy #$20
        switch chasmcmd.preprocInput[86] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDY")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xa0)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xA1, mnemonic: "LDA", mode: .indexedIndirect),
        //lda ($20, x)
        switch chasmcmd.preprocInput[87] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDA")
            #expect(c.op!.mode == .indexedIndirect)
            #expect(c.op!.hex == 0xa1)
            #expect(c.arg1 == "($20")
            #expect(c.arg2 == "X)")
        }

        //;Opcode(hex: 0xA2, mnemonic: "LDX", mode: .immediate),
        //ldx #$20
        switch chasmcmd.preprocInput[88] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDX")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xa2)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xA4, mnemonic: "LDY", mode: .zeroPage),
        //ldy $20
        switch chasmcmd.preprocInput[89] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDY")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0xa4)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xA5, mnemonic: "LDA", mode: .zeroPage),
        //lda $20
        switch chasmcmd.preprocInput[90] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDA")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0xa5)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xA6, mnemonic: "LDX", mode: .zeroPage),
        //ldx $20
        switch chasmcmd.preprocInput[91] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDX")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0xa6)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xA8, mnemonic: "TAY", mode: .implied),
        //tay
        switch chasmcmd.preprocInput[92] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "TAY")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xa8)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xA9, mnemonic: "LDA", mode: .immediate),
        //lda #$20
        switch chasmcmd.preprocInput[93] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDA")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xa9)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xAA, mnemonic: "TAX", mode: .implied),
        //tax
        switch chasmcmd.preprocInput[94] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "TAX")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xaa)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xAC, mnemonic: "LDY", mode: .absolute),
        //ldy $a000
        switch chasmcmd.preprocInput[95] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDY")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0xac)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xAD, mnemonic: "LDA", mode: .absolute),
        //lda $a000
        switch chasmcmd.preprocInput[96] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDA")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0xad)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xAE, mnemonic: "LDX", mode: .absolute),
        //ldx $a000
        switch chasmcmd.preprocInput[97] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDX")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0xae)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        // 0xB0 to 0xBF

        //;Opcode(hex: 0xB0, mnemonic: "BCS", mode: .relative),
        //label6:bcs label6
        switch chasmcmd.preprocInput[98] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "LABEL6")
            #expect(c.op!.mnemonic == "BCS")
            #expect(c.op!.mode == .relative)
            #expect(c.op!.hex == 0xB0)
            #expect(c.arg1 == "LABEL6")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xB1, mnemonic: "LDA", mode: .indirectIndexed),
        //lda ($20), y
        switch chasmcmd.preprocInput[99] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDA")
            #expect(c.op!.mode == .indirectIndexed)
            #expect(c.op!.hex == 0xB1)
            #expect(c.arg1 == "($20)")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0xB4, mnemonic: "LDY", mode: .zeroPageX),
        //ldy $20,x
        switch chasmcmd.preprocInput[100] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDY")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0xB4)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xB5, mnemonic: "LDA", mode: .zeroPageX),
        //lda $20,x
        switch chasmcmd.preprocInput[101] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDA")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0xB5)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xB6, mnemonic: "LDX", mode: .zeroPageY),
        //ldx $20, y
        switch chasmcmd.preprocInput[102] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDX")
            #expect(c.op!.mode == .zeroPageY)
            #expect(c.op!.hex == 0xB6)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0xB8, mnemonic: "CLV", mode: .implied),
        //clv
        switch chasmcmd.preprocInput[103] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CLV")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xB8)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xB9, mnemonic: "LDA", mode: .absoluteY),
        //lda $a000, y
        switch chasmcmd.preprocInput[104] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDA")
            #expect(c.op!.mode == .absoluteY)
            #expect(c.op!.hex == 0xB9)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0xBA, mnemonic: "TSX", mode: .implied),
        //tsx
        switch chasmcmd.preprocInput[105] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "TSX")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xBa)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xBC, mnemonic: "LDY", mode: .absoluteX),
        //ldy $a000, x
        switch chasmcmd.preprocInput[106] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDY")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0xBc)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xBD, mnemonic: "LDA", mode: .absoluteX),
        //lda $a000,x
        switch chasmcmd.preprocInput[107] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDA")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0xBd)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xBE, mnemonic: "LDX", mode: .absoluteY),
        //ldx $a000,y
        switch chasmcmd.preprocInput[108] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "LDX")
            #expect(c.op!.mode == .absoluteY)
            #expect(c.op!.hex == 0xBe)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "Y")
        }

        // 0xC0 to 0xCF

        //;Opcode(hex: 0xC0, mnemonic: "CPY", mode: .immediate),
        //cpy #$20
        switch chasmcmd.preprocInput[109] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CPY")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xC0)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xC1, mnemonic: "CMP", mode: .indexedIndirect),
        //cmp ($20, x)
        switch chasmcmd.preprocInput[110] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CMP")
            #expect(c.op!.mode == .indexedIndirect)
            #expect(c.op!.hex == 0xC1)
            #expect(c.arg1 == "($20")
            #expect(c.arg2 == "X)")
        }

        //;Opcode(hex: 0xC4, mnemonic: "CPY", mode: .zeroPage),
        //cpy $20
        switch chasmcmd.preprocInput[111] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CPY")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0xC4)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xC5, mnemonic: "CMP", mode: .zeroPage),
        //cmp $20
        switch chasmcmd.preprocInput[112] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CMP")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0xC5)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xC6, mnemonic: "DEC", mode: .zeroPage),
        //dec $20
        switch chasmcmd.preprocInput[113] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "DEC")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0xC6)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xC8, mnemonic: "INY", mode: .implied),
        //iny
        switch chasmcmd.preprocInput[114] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "INY")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xC8)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xC9, mnemonic: "CMP", mode: .immediate),
        //cmp #$20
        switch chasmcmd.preprocInput[115] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CMP")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xC9)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xCA, mnemonic: "DEX", mode: .implied),
        //dex
        switch chasmcmd.preprocInput[116] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "DEX")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xCa)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xCC, mnemonic: "CPY", mode: .absolute),
        //cpy $a000
        switch chasmcmd.preprocInput[117] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CPY")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0xCC)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xCD, mnemonic: "CMP", mode: .absolute),
        //cmp $a000
        switch chasmcmd.preprocInput[118] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CMP")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0xCD)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xCE, mnemonic: "DEC", mode: .absolute),
        //dec $a000
        switch chasmcmd.preprocInput[119] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "DEC")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0xCE)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        // 0xD0 to 0xDF

        //;Opcode(hex: 0xD0, mnemonic: "BNE", mode: .relative),
        //label7:     bne label7
        switch chasmcmd.preprocInput[120] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "LABEL7")
            #expect(c.op!.mnemonic == "BNE")
            #expect(c.op!.mode == .relative)
            #expect(c.op!.hex == 0xD0)
            #expect(c.arg1 == "LABEL7")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xD1, mnemonic: "CMP", mode: .indirectIndexed),
        //cmp ($20), y
        switch chasmcmd.preprocInput[121] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CMP")
            #expect(c.op!.mode == .indirectIndexed)
            #expect(c.op!.hex == 0xD1)
            #expect(c.arg1 == "($20)")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0xD5, mnemonic: "CMP", mode: .zeroPageX),
        //cmp $20, x
        switch chasmcmd.preprocInput[122] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CMP")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0xD5)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xD6, mnemonic: "DEC", mode: .zeroPageX),
        //dec $20, x
        switch chasmcmd.preprocInput[123] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "DEC")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0xD6)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xD8, mnemonic: "CLD", mode: .implied),
        //cld
        switch chasmcmd.preprocInput[124] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CLD")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xD8)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xDD, mnemonic: "CMP", mode: .absoluteX),
        //cmp $a000, x
        switch chasmcmd.preprocInput[125] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CMP")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0xDD)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xDE, mnemonic: "DEC", mode: .absoluteX),
        //dec $a000,x
        switch chasmcmd.preprocInput[126] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "DEC")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0xDE)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        // 0xE0 to 0xEF

        //;Opcode(hex: 0xE0, mnemonic: "CPX", mode: .immediate),
        //cpx #$20
        switch chasmcmd.preprocInput[127] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CPX")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xE0)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xE1, mnemonic: "SBC", mode: .indexedIndirect),
        //sbc ($20, x)
        switch chasmcmd.preprocInput[128] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SBC")
            #expect(c.op!.mode == .indexedIndirect)
            #expect(c.op!.hex == 0xE1)
            #expect(c.arg1 == "($20")
            #expect(c.arg2 == "X)")
        }

        //;Opcode(hex: 0xE4, mnemonic: "CPX", mode: .zeroPage),
        //cpx $20
        switch chasmcmd.preprocInput[129] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CPX")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0xE4)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xE5, mnemonic: "SBC", mode: .zeroPage),
        //sbc $20
        switch chasmcmd.preprocInput[130] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SBC")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0xE5)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xE6, mnemonic: "INC", mode: .zeroPage),
        //inc $20
        switch chasmcmd.preprocInput[131] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "INC")
            #expect(c.op!.mode == .zeroPage)
            #expect(c.op!.hex == 0xE6)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xE8, mnemonic: "INX", mode: .implied),
        //inx
        switch chasmcmd.preprocInput[132] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "INX")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xE8)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xE9, mnemonic: "SBC", mode: .immediate),
        //sbc #$20
        switch chasmcmd.preprocInput[133] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SBC")
            #expect(c.op!.mode == .immediate)
            #expect(c.op!.hex == 0xE9)
            #expect(c.arg1 == "#$20")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xEA, mnemonic: "NOP", mode: .implied),
        //nop
        switch chasmcmd.preprocInput[134] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "NOP")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xEA)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xEC, mnemonic: "CPX", mode: .absolute),
        //cpx $a000
        switch chasmcmd.preprocInput[135] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "CPX")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0xEC)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xED, mnemonic: "SBC", mode: .absolute),
        //sbc $a000
        switch chasmcmd.preprocInput[136] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SBC")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0xED)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xEE, mnemonic: "INC", mode: .absolute),
        //inc $a000
        switch chasmcmd.preprocInput[137] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "INC")
            #expect(c.op!.mode == .absolute)
            #expect(c.op!.hex == 0xEE)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "")
        }

        // 0xF0 to 0xFF

        //;Opcode(hex: 0xF0, mnemonic: "BEQ", mode: .relative),
        //label8:beq label8
        switch chasmcmd.preprocInput[138] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "LABEL8")
            #expect(c.op!.mnemonic == "BEQ")
            #expect(c.op!.mode == .relative)
            #expect(c.op!.hex == 0xF0)
            #expect(c.arg1 == "LABEL8")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xF1, mnemonic: "SBC", mode: .indirectIndexed),
        //sbc ($20), y
        switch chasmcmd.preprocInput[139] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SBC")
            #expect(c.op!.mode == .indirectIndexed)
            #expect(c.op!.hex == 0xF1)
            #expect(c.arg1 == "($20)")
            #expect(c.arg2 == "Y")
        }

        //;Opcode(hex: 0xF5, mnemonic: "SBC", mode: .zeroPageX),
        //sbc $20, x
        switch chasmcmd.preprocInput[140] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SBC")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0xF5)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xF6, mnemonic: "INC", mode: .zeroPageX),
        //inc $20, x
        switch chasmcmd.preprocInput[141] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "INC")
            #expect(c.op!.mode == .zeroPageX)
            #expect(c.op!.hex == 0xF6)
            #expect(c.arg1 == "$20")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xF8, mnemonic: "SED", mode: .implied),
        //sed
        switch chasmcmd.preprocInput[142] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SED")
            #expect(c.op!.mode == .implied)
            #expect(c.op!.hex == 0xF8)
            #expect(c.arg1 == "")
            #expect(c.arg2 == "")
        }

        //;Opcode(hex: 0xFD, mnemonic: "SBC", mode: .absoluteX),
        //sbc $a000, x
        switch chasmcmd.preprocInput[143] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "SBC")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0xFD)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }

        //;Opcode(hex: 0xFE, mnemonic: "INC", mode: .absoluteX)
        //inc $a000,x
        switch chasmcmd.preprocInput[144] {
        case .directive:
            #expect(Bool(false))
        case .code(let c):
            #expect(c.label == "")
            #expect(c.op!.mnemonic == "INC")
            #expect(c.op!.mode == .absoluteX)
            #expect(c.op!.hex == 0xFE)
            #expect(c.arg1 == "$A000")
            #expect(c.arg2 == "X")
        }
    }
}
