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

    func testInterruptIsSentToShellCommand() async throws {
        // Create a new script.
        let path = "/tmp/\(UUID())"
        let sleepAmount = 60
        let contents = """
            #! /bin/sh

            function sigint_handler() {
                exit 0
            }

            trap 'sigint_handler' SIGINT
            echo "start"
            counter=0
            while [ $counter -le \(sleepAmount) ]
            do
                sleep 1
                ((counter++))
            done
            exit 1
            """
        guard let filePath = try createFile(named: "process.sh", contents: contents, inDirectory: path) else {
            return
        }
        defer {
            let fm = FileManager.default
            try? fm.removeItem(atPath: filePath)
            try? fm.removeItem(atPath: path)
        }
        // Setup the command to run.
        let sharedData = SharedData()
        let command = Command(filePath)
        command.onOutput {
            guard
                let str = String(data: $0, encoding: .utf8),
                str.trimmingCharacters(in: .whitespacesAndNewlines) == "start"
            else {
                return
            }
            await sharedData.setTrue()
        }
        let shouldEnd = SharedData()
        // Run the command on a separate thread and wait for it to exit.
        Task {
            async let result = command.run()
            for _ in 0..<(sleepAmount * 10) {
                if await sharedData.shouldContinue {
                    break
                }
                usleep(100000)
            }
            guard await sharedData.shouldContinue else {
                command.terminate()
                XCTFail("Start message was never received.")
                await shouldEnd.setTrue()
                return
            }
            XCTAssertTrue(command.interrupt())
            let exitCode = try await result
            XCTAssertEqual(exitCode, 0)
            await shouldEnd.setTrue()
        }
        // Periodically check to see if the command has finished executing, or time out.
        for _ in 0..<sleepAmount * 10 {
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