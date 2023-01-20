//
//  Scripting.swift
//
//  Copyright © 2022, 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import SystemPackage
import Foundation

/// The result code of running a shell command.
public typealias Status = CInt

/// The termination reason for a shell command.
public typealias TerminationReason = Process.TerminationReason

extension Errno {
    /// Correctly spelt error number.
    @usableFromInline
    static var alreadyInProgress = Errno.alreadyInProcess
}
