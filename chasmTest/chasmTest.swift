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

        //var globals = Globals(preprocInput:[])
        //passOne([".org $1000"], with: &globals)
        
        let fnurl = try fileURL("directivetest01", withExtension: "chasm")
        let args = [fnurl.path()]
        let cmd = try Chasm.parseAsRoot(args)
        var chasmcmd = try #require(cmd as? Chasm)
        try chasmcmd.run()

        #expect(chasmcmd.globals.preprocInput.count == 1)
        switch chasmcmd.globals.preprocInput[0] {
        case .directive(let directive):
            #expect(directive.name == ".org")
            #expect(directive.content == "$1000")
            #expect(directive.newPC == 4096)
        case .code(let code):
            #expect(false)
        }
    }

}
