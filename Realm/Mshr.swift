//
//  Mshr.swift
//
//  Created by Admin on 18.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import RealmSwift

class Mshr: Object {
    
    @objc dynamic var bigDescription: String?
    @objc dynamic var code: String = ""
    @objc dynamic var commonNames: String?
    @objc dynamic var culinaryUses: String?
    @objc dynamic var descriptionUrl: String?
    @objc dynamic var distribution: String?
    @objc dynamic var fakes: String?
    @objc dynamic var habitatAndDistribution: String?
    @objc dynamic var identification: String?
    @objc dynamic var name: String?
    @objc dynamic var nutrition: String?
    @objc dynamic var relatedSpecies: String?
    @objc dynamic var smallDescription: String?
    
    override class func primaryKey() -> String? {
        return "code"
    }
    
    convenience init (code: String) {
        self.init()
        
        self.code = code
    }

    
}
