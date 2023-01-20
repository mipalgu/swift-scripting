//
//  ParsingTests.swift
//
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 21/1/2023.
//
import XCTest
@testable import Scripting

final class ParsingTests: XCTestCase {
    func testSimpleCommand() {
        let commandArguments = ["Test"]
        let parameter = commandArguments.joined(separator: " ")
        XCTAssertEqual(parse(command: parameter), commandArguments)
    }

    func testSimpleCommandArg() {
        let commandArguments = ["Hello", "world"]
        let parameter = commandArguments.joined(separator: " ")
        XCTAssertEqual(parse(command: parameter), commandArguments)
    }

    func testQuotedCommandArg() {
        let commandArguments = ["Hello", "world out there"]
        XCTAssertEqual(parse(command: #"Hello "world out there""#), commandArguments)
    }

    func testEscapedCommandArg() {
        let commandArguments = ["Hello", "world out there", "\\"]
        XCTAssertEqual(parse(command: #"Hello world\ out\ there \\"#), commandArguments)
    }

    func testEnvironment() {
        let env = ["CMD": "cmd", "VAR": "val"]
        let commandArguments = ["cmd", "val", "$VAR", "$VAR", "val", "$VAR"]
        XCTAssertEqual(parse(command: #"$CMD $VAR '$VAR' \$VAR "$VAR" "\$VAR"#, environment: env), commandArguments)
    }
}
