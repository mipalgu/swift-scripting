//
//  ShellCommandTests.swift
//
//  Copyright © 2023 Karan Naidu.  All rights reserved.
//  Created by Karan naidu on 27/6/2023.
//

import XCTest
@testable import Scripting
final class ShellCommandTests: XCTestCase {

    actor SharedData {

        var shouldContinue = false

        func setTrue() {
            shouldContinue = true
        }

    }

    struct CommandError: Error {

    }

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

}
