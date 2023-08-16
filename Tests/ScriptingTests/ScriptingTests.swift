//
//  ScriptingTests.swift
//
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import XCTest
@testable import Scripting

final class ScriptingTests: XCTestCase {

    actor SharedData {

        var shouldContinue = false

        func setTrue() {
            shouldContinue = true
        }

    }

    struct CommandError: Error {}

    func testCommandInterruptExecutableFail() throws {
        let command: Command = .error(CommandError.init())
        XCTAssertFalse(command.interrupt())
    }

    func testCommandInterruptShellCommandFail() throws {
        let command = Command(file: "hello")
        XCTAssertFalse(command.interrupt())
    }

    func testInterruptIsSentToShellCommand() async throws {
        // Create a new script.
        let sleepAmount = 10
        let shouldEnd = SharedData()
        // Run the command on a separate thread and wait for it to exit.
        #if os(macOS)
        let command: Command = "/bin/cat"
        #else
        let command: Command = "/usr/bin/cat"
        #endif
        Task {
            async let result = command.run()
            guard
                case Command.executable(let executable) = command,
                let shellCommand = executable as? ShellCommand
            else {
                XCTFail("command is not a ShellCommand")
                return
            }
            for _ in 0..<sleepAmount * 10 {
                if shellCommand.isRunning {
                    break
                }
                usleep(100000)
            }
            guard shellCommand.isRunning else {
                XCTFail("shell command is not running.")
                return
            }
            XCTAssertTrue(command.interrupt())
            let exitCode = try await result
            XCTAssertEqual(exitCode, 0)
            await shouldEnd.setTrue()
        }
        // Periodically check to see if the command has finished executing, or time out.
        for _ in 0..<sleepAmount * 20 {
            if await shouldEnd.shouldContinue {
                break
            }
            usleep(100000)
        }
        let finished = await shouldEnd.shouldContinue
        XCTAssertTrue(finished)
    }

    func createFile(named name: String, contents: String, inDirectory path: String) throws -> String? {
        let filePath = path + "/process.sh"
        let fm = FileManager.default
        try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
        guard let data = contents.data(using: .utf8) else {
            XCTFail("Unable to create file data.")
            return nil
        }
        guard fm.createFile(atPath: filePath, contents: data, attributes: [.posixPermissions: 0o775]) else {
            XCTFail("Unable to create file.")
            return nil
        }
        return filePath
    }

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

    func testFilePipeStringLiteral() async throws {
        defer { try? FileManager.default.removeItem(atPath: "/tmp/scriptingCatTestFile") }
        await "echo hello" | "cat" > "/tmp/scriptingCatTestFile"
        let contentData = try? NSData(contentsOfFile: "/tmp/scriptingCatTestFile") as Data
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
