//
//  FoundM.swift
//
//  Created by Admin on 20.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation
import MapKit

class FoundM: Object {
    
    @objc dynamic var id: Int = 0
    
    @objc dynamic var altitude: String?
    @objc dynamic var code: String?
    @objc dynamic var date: Date?
    
    //для работы с картой
    //@objc dynamic var location: CLLocation?
    
    //для вычисления в прямых запросах
    @objc dynamic var accuracy: Double = 0.0
    @objc dynamic var latitude: Double = 0.0
    @objc dynamic var longitude: Double = 0.0

    var clLocation: CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }

    convenience init(clLocation: CLLocation) {
        self.init()
        
        self.latitude = clLocation.coordinate.latitude
        self.longitude = clLocation.coordinate.longitude
    }

    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension FoundM: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        get {
            return self.clLocation.coordinate
        }
    }
    
    var title: String? {
        get {
            return self.code
        }
    }
    
    var subtitle: String? {
        get {
            return self.date?.description
        }
    }
    
}
