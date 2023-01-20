//
//  AsyncDataSequence.swift.swift
//  
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import Foundation

/// A trivial `AsyncSequence` returning the provided data
public struct AsyncDataSequence: AsyncSequence {
    /// The element type of this sequence.
    public typealias Element = Data

    public struct AsyncIterator: AsyncIteratorProtocol {
        @usableFromInline var data: Data?
        /// Designated initialiser.
        /// - Parameter data: The data to provide.
        public init(_ data: Data? = nil) {
            self.data = data
        }
        /// Return the provided data.
        /// - Returns: The provided data on first call, `nil` afterwards.
        public mutating func next() async throws -> Element? {
            defer { data = nil }
            return data
        }
    }

    /// The data to provide.
    @usableFromInline var data: Element
    /// Designated initialiser.
    /// - Parameter data: The data to provide.
    @inlinable
    public init(_ data: Element) {
        self.data = data
    }
    /// Create an iterator for the provided data.
    /// - Returns: The new iterator.
    @inlinable
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(data)
    }
}
