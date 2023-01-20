//
//  FilPathFunctions.swift
//  
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import Foundation

/// Find a command in the current path.
///
/// This function searches the provided, colon-separated search path
/// for an executable `command` and returns its filesystem URL.
///
/// - Parameters:
///   - command: The command base name to search for.
///   - searchPath: The colon-separated search path.
/// - Returns: The command URL, or `nil` if not found.
public func search(for command: String, in searchPath: String) -> URL? {
    let fm = FileManager.default
    let cwd = fm.currentDirectoryPath
    var pathIterator = searchPath.split(separator: ":").lazy.map(String.init).makeIterator()
    var commandURL: URL?
    while let searchDirectory = pathIterator.next() {
        let directoryURL: URL
        let cmdURL: URL
        let cmdPath: String
#if os(Linux)
        directoryURL = URL(fileURLWithPath: searchDirectory, isDirectory: true)
        cmdURL = directoryURL.appendingPathComponent(command, isDirectory: false)
        cmdPath = cmdURL.path
#else
        if #available(macOS 13.0, *) {
            directoryURL = URL(filePath: searchDirectory, directoryHint: .isDirectory)
            cmdURL = directoryURL.appending(path: command, directoryHint: .notDirectory)
            cmdPath = cmdURL.path(percentEncoded: false)
        } else {
            directoryURL = URL(fileURLWithPath: cwd, isDirectory: true)
            cmdURL = directoryURL.appendingPathComponent(command, isDirectory: false)
            cmdPath = cmdURL.path
        }
#endif
        if fm.isExecutableFile(atPath: cmdPath) {
            commandURL = cmdURL
            break
        }
    }
    return commandURL
}
