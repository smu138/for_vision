//
//  AVCaptureVideoOrientation.swift
//
//  Created by Admin on 05.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit
import AVFoundation

extension AVCaptureVideoOrientation {
    var uiInterfaceOrientation: UIDeviceOrientation {
        get {
            switch self {
            case .landscapeLeft:        return .landscapeLeft
            case .landscapeRight:       return .landscapeRight
            case .portrait:             return .portrait
            case .portraitUpsideDown:   return .portraitUpsideDown
            @unknown default:
                fatalError("Unknown device orientation")
            }
        }
    }

    init(ui:UIDeviceOrientation) {
        switch ui {
        case .landscapeRight:       self = .landscapeRight
        case .landscapeLeft:        self = .landscapeLeft
        case .portrait:             self = .portrait
        case .portraitUpsideDown:   self = .portraitUpsideDown
        default:                    self = .portrait
        }
    }
}
