//
//  FileIO.swift
//  
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 22/1/2023.
//
import Foundation
import SystemPackage

/// An actor representing file operations.
///
/// This actor allows reading or writing
/// of files.  It behaves like an executable,
/// whose only purpose is file I/O.
public final class FileIO {
    /// File operation mode.
    public enum ReadWriteMode: CaseIterable {
        /// Open the file for reading.
        case read
        /// Open the file for writing.
        case write
        /// Open the file for appending.
        case append
    }
    /// The path to the underlying file.
    public var path: FilePath
    /// The access mode to use.
    public var mode: ReadWriteMode?
    /// The last error.
    public var error: Error?
    /// Return whether the underlying file is open.
    public var isOpen: Bool { handle != nil }
    /// Return whether file I/O is active.
    public var isActive: Bool { task != nil }
    /// The detached I/O task.
    @usableFromInline var task: Task<Status,Error>?
    /// An I/O handle associated with the underlying file.
    @usableFromInline var handle: FileHandle?
    /// File input handler.
    ///
    /// This handler runs in the background and is called whenever
    /// file writing will require input.  A `nil` value denotes that
    /// the file should be closed.
    ///
    /// - Note: set to `nil` to disable output handling.
    @usableFromInline var inputHandler: (() async throws -> Data?)?
    /// File output handler.
    ///
    /// This handler runs in the background and is called whenever
    /// the file data available.
    ///
    /// - Note: set to `nil` to disable output handling.
    @usableFromInline var outputHandler: ((Data) async -> Void)?
    /// File error handler.
    ///
    /// This handler runs in the background and is called whenever
    /// file I/O has produced errors.
    ///
    /// - Note: set to `nil` to disable error handling.
    @usableFromInline var errorHandler: ((Data) async -> Void)?
    /// Designated initialiser.
    /// - Parameter path: The path to the file to open.
    public init(path: FilePath) {
        self.path = path
    }
    /// Open the underlying file.
    /// - Parameter mode: Whether to open the file for reading or writing.
    public func open(mode: ReadWriteMode = .read) throws {
        guard !isOpen else {
            if self.mode == mode { return }
            throw record(error: Errno.alreadyInProgress)
        }
        let fm = FileManager.default
        self.mode = mode
        let cwd = fm.currentDirectoryPath
        let fileURL: URL
#if os(Linux)
        fileURL = URL(fileURLWithPath: path.string, isDirectory: false)
#else
        if #available(macOS 13.0, *) {
            let wdURL = URL(filePath: cwd, directoryHint: .isDirectory)
            fileURL = URL(filePath: path.string, directoryHint: .notDirectory, relativeTo: wdURL)
        } else {
            fileURL = URL(fileURLWithPath: path.string, isDirectory: false)
        }
#endif
        switch mode {
        case .read:
            guard inputHandler == nil else {
                throw record(error: Errno.badFileTypeOrFormat)
            }
            handle = try FileHandle(forReadingFrom: fileURL)
        default:
            guard outputHandler == nil else {
                throw record(error: Errno.badFileTypeOrFormat)
            }
            print("File: '\(path.string)' exists: \(fm.fileExists(atPath: path.string))")
            guard fm.fileExists(atPath: path.string) ||
                  fm.createFile(atPath: path.string, contents: Data()) else {
                throw Errno(rawValue: CInt(errno))
            }
            print("File: '\(path.string)' exists: \(fm.fileExists(atPath: path.string)), opening \(fileURL)")
            handle = try FileHandle(forWritingTo: fileURL)
            if case .append = mode {
                if #available(macOS 10.15.4, *) {
                    try handle?.seekToEnd()
                } else {
                    handle?.seekToEndOfFile()
                }
            }
        }
    }
    /// Record and return an error.
    ///
    /// This method will record the given error,
    /// write a string representation to the error handler,
    /// return the error back to the caller.
    ///
    /// - Parameter error: The error to record.
    /// - Returns: The error passed in.
    @discardableResult @usableFromInline
    func record(error: Error) -> Error {
        self.error = error
        guard let errorHandler = errorHandler else { return error }
        Task {
            let description = path.string + ": " + error.localizedDescription + "\n"
            await errorHandler(description.data(using: .utf8) ?? Data())
        }
        return error
    }
}

/// Convenience Extensions.
public extension FileIO {
    /// Convenience file path initialiser.
    /// - Parameter file: A string representing the file path.
    @inlinable
    convenience init(_ file: String) {
        self.init(path: FilePath(file))
    }
    /// Convenience file URL initialiser.
    /// - Parameter url: A file URL.
    @inlinable
    convenience init(_ url: URL) {
#if os(Linux)
        self.init(path: FilePath(url.path))
#else
        if #available(macOS 13.0, *) {
            self.init(path: FilePath(url.path(percentEncoded: false)))
        } else {
            self.init(path: FilePath(url.path))
        }
#endif
    }
}

/// Executable conformance.
extension FileIO: Executable {
    /// The file handle represented as standard input.
    public var standardInput: IOHandle? {
        get { handle }
        set { handle = newValue as? FileHandle }
    }

    /// The file handle represented as standard output.
    public var standardOutput: IOHandle? {
        get { handle }
        set { handle = newValue as? FileHandle }
    }

    /// The file handle represented as standard error.
    public var standardError: IOHandle? {
        get { handle }
        set { handle = newValue as? FileHandle }
    }

    /// Launch file I/O.
    ///
    /// This call will commence file operations in the background.
    ///
    /// - Throws: `.noChildProcess` if no I/O handlers are installed.
    public func launch() throws {
        guard inputHandler != nil || outputHandler != nil || errorHandler != nil else {
            throw Errno.noChildProcess
        }
        if !isOpen {
            if mode == nil {
                mode = inputHandler == nil ? .read : .write
            }
            try open(mode: mode!)
        }
        if let inputHandler = inputHandler {
            task = Task {
                while !Task.isCancelled,
                      let data = try await inputHandler() {
                    if #available(macOS 10.15.4, *) {
                        try handle?.write(contentsOf: data)
                    } else {
                        handle?.write(data)
                    }
                }
                return 0
            }
        } else if let outputHandler = outputHandler {
            task = Task {
                while !Task.isCancelled,
                      let data = handle?.availableData {
                    await outputHandler(data)
                }
                return 0
            }
        }
    }

    /// Run the file I/O operation.
    ///
    /// This function launches an asychronous I/O
    /// operation and waits for completion.
    ///
    /// - Returns: The status of the operation (`0` if successful).
    public func run() async throws -> Status {
        if !isActive { try launch() }
        guard let result = await task?.result else {
            throw record(error: Errno.canceled)
        }
        switch result {
        case let .failure(error):
            throw record(error: error)
        case let .success(status):
            return status
        }
    }

    /// Set up an I/O input provider.
    /// - Parameter inputProvider: Function that provides input data to write.
    public func onInput(_ inputProvider: @escaping () async throws -> Data?) {
        if let inputHandler = inputHandler {
            self.inputHandler = {
                if let data = try await inputHandler() { return data }
                return try await inputProvider()
            }
        } else {
            inputHandler = inputProvider
        }
    }

    /// Set up an I/O output handler.
    /// - Parameter outputHandler: Function that takes the data read from the file.
    public func onOutput(call outputHandler: @escaping (Data) async -> Void) {
        if let originalHandler = self.outputHandler {
            self.outputHandler = {
                await originalHandler($0)
                await outputHandler($0)
            }
        } else {
            self.outputHandler = outputHandler
        }
    }

    /// Set up an I/O error handler.
    /// - Parameter errorHandler: Function that takes file I/O error data.
    public func onError(call errorHandler: @escaping (Data) async -> Void) {
        if let originalHandler = self.errorHandler {
            self.errorHandler = {
                await originalHandler($0)
                await errorHandler($0)
            }
        } else {
            self.errorHandler = errorHandler
        }
    }
}

/// Confirming File I/O to `ExpressibleByStringLiteral`.
extension FileIO: ExpressibleByStringLiteral {
    /// String literal initialiser.
    /// - Parameter stringLiteral: A string literal representing the file path.
    @inlinable
    public convenience init(stringLiteral filePath: String) {
        self.init(filePath)
    }
}
