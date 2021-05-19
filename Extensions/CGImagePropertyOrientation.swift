//
//  CImage.swift
//
//  Created by Admin on 04.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import UIKit

extension CGImagePropertyOrientation {
    var toUIImageOrientetion: UIImage.Orientation {
        get {
            switch self {
            case .up:               return .up
            case .upMirrored:       return .left
            case .down:             return .right
            case .downMirrored:     return .downMirrored
            case .left:             return .downMirrored
            case .leftMirrored:     return .leftMirrored
            case .right:            return .right
            case .rightMirrored:    return .rightMirrored
            }
        }
    }
}


