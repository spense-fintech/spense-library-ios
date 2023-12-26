//
//  File.swift
//  
//
//  Created by Varun on 26/12/23.
//

import Foundation

@available(iOS 15.0, *)
class SpenseLibrarySingleton {
    static let shared = SpenseLibrarySingleton()

    private var spenseLibrary: SpenseLibrary?

    func initialize(withHostName hostName: String) {
        guard spenseLibrary == nil else {
            print("Error: SpenseLibrary is already initialized. Call reset() to reinitialize.")
            return
        }
        spenseLibrary = SpenseLibrary(hostName: hostName)
    }

    var instance: SpenseLibrary {
        guard let library = spenseLibrary else {
            fatalError("SpenseLibrarySingleton is not initialized. Call initialize(withHostName:) first.")
        }
        return library
    }

    func reset() {
        spenseLibrary = nil
    }
}
