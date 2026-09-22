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

        #expect(chasmcmd.globals.preprocInput.count == 1)
        switch chasmcmd.globals.preprocInput[0] {
        case .directive(let directive):
            #expect(directive.name == ".ORG")
            #expect(directive.content == "$1000")
            #expect(directive.newPC == 4096)
        case .code(let _):
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
        // TODO: re-enable once test is stable
        #expect(chasmcmd.globals.preprocInput.count == 20)

        // line 1 (lea $42)
        switch chasmcmd.globals.preprocInput[0] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .zeroPage)
            #expect(code.op.hex == 0xA5)
            #expect(code.arg1 == "$42")
            #expect(code.arg2 == "")
        }
        // line 2 (lea $43 ; comment)
        switch chasmcmd.globals.preprocInput[1] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .zeroPage)
            #expect(code.op.hex == 0xA5)
            #expect(code.arg1 == "$43")
            #expect(code.arg2 == "")
        }
        // line 3 (lab1:    lea $44)
        switch chasmcmd.globals.preprocInput[2] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .zeroPage)
            #expect(code.op.hex == 0xA5)
            #expect(code.arg1 == "$44")
            #expect(code.arg2 == "")
            #expect(code.label == "lab1")
        }
        // line 4 (lab1:    lea $45     ; comment)
        switch chasmcmd.globals.preprocInput[3] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .zeroPage)
            #expect(code.op.hex == 0xA5)
            #expect(code.arg1 == "$45")
            #expect(code.arg2 == "")
            #expect(code.label == "lab2")
        }

        // line 5 blank
        // line 6 comment only (blank)
        // line 7 blank

        // line 8 (tax             ; implied)
        switch chasmcmd.globals.preprocInput[4] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "TAX")
            #expect(code.op.mode == .implied)
            #expect(code.op.hex == 0xAA)
            #expect(code.arg1 == "")
            #expect(code.arg2 == "")
        }
        // line 9 (asl a           ; accumulator)
        switch chasmcmd.globals.preprocInput[5] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "ASL")
            #expect(code.op.mode == .accumulator)
            #expect(code.op.hex == 0x0A)
            #expect(code.arg1 == "A")
            #expect(code.arg2 == "")
        }
        // line 10 (lda #$ff        ; immediate)
        switch chasmcmd.globals.preprocInput[6] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .immediate)
            #expect(code.op.hex == 0xA9)
            #expect(code.arg1 == "#$FF")
            #expect(code.arg2 == "")
        }
        //line 11 (LDA $42, x      ; zero-page,x)
        switch chasmcmd.globals.preprocInput[7] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .zeroPageX)
            #expect(code.op.hex == 0xB5)
            #expect(code.arg1 == "$42")
            #expect(code.arg2 == "X")
        }
        // line 12 (ldx $42, Y      ; zero-page,y)
        switch chasmcmd.globals.preprocInput[8] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDX")
            #expect(code.op.mode == .zeroPageY)
            #expect(code.op.hex == 0xB6)
            #expect(code.arg1 == "$42")
            #expect(code.arg2 == "Y")
        }
        // line 13 - blank

        // line 14 (jmp ($fffe)      ; (absolute) indirect)
        switch chasmcmd.globals.preprocInput[9] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "JMP")
            #expect(code.op.mode == .indirect)
            #expect(code.op.hex == 0x6C)
            #expect(code.arg1 == "($FFFE)")
            #expect(code.arg2 == "")
        }

        // line 15 (;JMP lab2       ; absolute, handle labels COMMENTED OUT)

        // line 16 (JMP lab2       ; absolute, handle labels)
        switch chasmcmd.globals.preprocInput[10] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "JMP")
            #expect(code.op.mode == .absolute)
            #expect(code.op.hex == 0x4C)
            #expect(code.arg1 == "LAB2")
            #expect(code.arg2 == "")
        }

        // line 17 (lda ($20, X)    ; indexed indirect)
        switch chasmcmd.globals.preprocInput[11] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .indexedIndirect)
            #expect(code.op.hex == 0xA1)
            #expect(code.arg1 == "($20")
            #expect(code.arg2 == "X)")
        }

        // line 18 (lda ($20), Y    ; indirect indexed)
        switch chasmcmd.globals.preprocInput[12] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .indirectIndexed)
            #expect(code.op.hex == 0xB1)
            #expect(code.arg1 == "($20)")
            #expect(code.arg2 == "Y")
        }

        // line 19 (lda $4200       ; absolute)
        switch chasmcmd.globals.preprocInput[13] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .absolute)
            #expect(code.op.hex == 0xAD)
            #expect(code.arg1 == "$4200")
            #expect(code.arg2 == "")
        }

        // line 20 (lda $4200, x    ; absolute x)
        switch chasmcmd.globals.preprocInput[14] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .absoluteX)
            #expect(code.op.hex == 0xBD)
            #expect(code.arg1 == "$4200")
            #expect(code.arg2 == "X")
        }
        // line 21 (lda $4200, y    ; absolute y)
        switch chasmcmd.globals.preprocInput[15] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .absoluteY)
            #expect(code.op.hex == 0xB9)
            #expect(code.arg1 == "$4200")
            #expect(code.arg2 == "Y")
        }

        // TODO: relative (branch) addressing
        // line 22 (BEQ lab1       ; TBD - relative, handle labels)
        switch chasmcmd.globals.preprocInput[16] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "BEQ")
            #expect(code.op.mode == .relative)
            #expect(code.op.hex == 0xF0)
            #expect(code.arg1 == "LAB1")
            #expect(code.arg2 == "")
        }

        // line 23 (BCS $80       ; relative)
        switch chasmcmd.globals.preprocInput[17] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "BCS")
            #expect(code.op.mode == .relative)
            #expect(code.op.hex == 0xB0)
            #expect(code.arg1 == "$80")
            #expect(code.arg2 == "")
        }

        // line 24 (lda not_yet_declared, x)
        switch chasmcmd.globals.preprocInput[18] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .absoluteX)
            #expect(code.op.hex == 0xBD)
            #expect(code.arg1 == "NOT_YET_DECLARED")
            #expect(code.arg2 == "X")
        }

        // line 25 (lda also_not_yet_declared, y)
        switch chasmcmd.globals.preprocInput[19] {
        case .directive(let _):
            #expect(Bool(false))
        case .code(let code):
            #expect(code.op.mnemonic == "LDA")
            #expect(code.op.mode == .absoluteY)
            #expect(code.op.hex == 0xB9)
            #expect(code.arg1 == "ALSO_NOT_YET_DECLARED")
            #expect(code.arg2 == "Y")
        }
    }

    @Test func passTwoDirectivesTest() async throws {
        let fnurl = try fileURL("passonetest01", withExtension: "chasm")
        let args = [fnurl.path()]
        let cmd = try Chasm.parseAsRoot(args)
        var chasmcmd = try #require(cmd as? Chasm)
        try chasmcmd.run()

        // verify that the output of pass two is 256 bytes of zeros
        #expect(chasmcmd.buf.count == 256)
        #expect(chasmcmd.buf.allSatisfy{ $0 == 0 })
    }
}
