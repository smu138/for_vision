//
//  CustomMapAnnotation.swift
//
//  Created by Admin on 23.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import MapKit

class CustomMapAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D!, title: String?, subtitle: String?) {

        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle

        super.init()
    }
}
