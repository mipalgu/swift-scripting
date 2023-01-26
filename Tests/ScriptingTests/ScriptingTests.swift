//
//  ScriptingTests.swift
//
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import XCTest
@testable import Scripting

final class ScriptingTests: XCTestCase {
    func testPathSearch() {
        let result = search(for: "ls", in: "/bin")
#if os(Linux)
        XCTAssertEqual(result?.path, "/bin/ls")
#else
        if #available(macOS 13.0, *) {
            XCTAssertEqual(result?.path(percentEncoded: false), "/bin/ls")
        } else {
            XCTAssertEqual(result?.path, "/bin/ls")
        }
#endif
    }

    func testEcho() async throws {
        var string = String()
        await "echo hello" > string
        XCTAssertEqual(string, "hello\n")
    }

    func testCat() async throws {
        var string = String()
        await "echo hello" | "cat" > string
        XCTAssertEqual(string, "hello\n")
    }

    func testSed() async throws {
        var string = String()
        await "echo no" | "sed -e s/no/yes/" | "cat" > string
        XCTAssertEqual(string, "yes\n")
    }

    func testTripePipe() async throws {
        var string = String()
        await "echo no no" | "wc" | "cat -n" | "sed -e 's/[ \t][ \t]*/ /g' -e 's/^  *//'" > string
        XCTAssertEqual(string, "1 1 2 6\n")
    }

    func testFileOutputStringLiteral() async throws {
        defer { try? FileManager.default.removeItem(atPath: "/tmp/scriptingTestFile") }
        await "echo hello" > "/tmp/scriptingTestFile"
        let contentData = try? NSData(contentsOfFile: "/tmp/scriptingTestFile") as Data
        let stringContent = contentData.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(stringContent, "hello\n")
    }

    func testFileOutput() async throws {
        let tmpURL = FileManager.default.temporaryDirectory
        let file = UUID().description
        let fileURL: URL
#if os(Linux)
        fileURL = tmpURL.appendingPathComponent(file, isDirectory: false)
#else
        if #available(macOS 13.0, *) {
            fileURL = tmpURL.appending(path: file, directoryHint: .notDirectory)
        } else {
            fileURL = tmpURL.appendingPathComponent(file, isDirectory: false)
        }
#endif
        let outputFile = FileIO(fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        await "echo hello" > outputFile
        let contentData = try? Data(contentsOf: fileURL, options: .mappedIfSafe)
        let stringContent = contentData.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(stringContent, "hello\n")
    }
}
