//
//  RealmConfig.swift
//
//  Created by Admin on 21.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import RealmSwift


enum RealmConfig {

    // MARK: - private configurations
    private static let foundedConfig = Realm.Configuration(
        fileURL: Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent().appendingPathComponent("found.realm"),
        schemaVersion: 0,
        migrationBlock: { migration, oldSchemaVersion in
            // We haven’t migrated anything yet, so oldSchemaVersion == 0
            if (oldSchemaVersion < 1) {
                // Nothing to do!
                // Realm will automatically detect new properties and removed properties
                // And will update the schema on disk automatically
            }
        },
        objectTypes: [FoundM.self]
    )
    
    private static let staticConfig = Realm.Configuration(
        fileURL: Bundle.main.url(forResource: "mshr", withExtension: "realm"),
        readOnly: true,
        objectTypes: [Mshr.self]
    )

    // MARK: - enum cases
    case founded
    //case sharedLocations
    case staticBase

    // MARK: - current configuration
    var configuration: Realm.Configuration {
        switch self {
            case .founded:
                return RealmConfig.foundedConfig
            case .staticBase:
                return RealmConfig.staticConfig
        }
    }
}


