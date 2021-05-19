//
//  LocationMonitoringService.swift
//
//  Created by Admin on 03.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import CoreLocation

class LocationMonitoringService: BaseLocationService {
    
    //для каждого серивиса completion разный по функционалу
    private var completion: (_ crossedRegion: CLRegion?,_ error: Error?)->() = {_,_ in }
    
    private var monitoredRegion: Region_cls?

    override init() {
        super.init()
        self.locationDispatchQueue = DispatchQueue(label: "location.monitor.service.queue")
    }
        
    public func initService(region: Region_cls, crossedCompletion: @escaping (_ crossedRegion: CLRegion?,_ error: Error?)->()) {
        self.completion = crossedCompletion
        self.monitoredRegion = region
        
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                startService()
            }
            
        } else {
            locationManager?.requestAlwaysAuthorization()
        }
    }

    //запускает колбек didUpdateLocations
    override public func startService() {
        if let clRegion = self.monitoredRegion {
            self.locationManager?.startMonitoring(for: clRegion)
        }
    }

    // MARK: Стоп мониторгина
    public func stopMonitoring(region: Region_cls) -> Void
    {
        self.locationManager?.stopMonitoring(for: region)
    }
}

// MARK: DELEGATES HERE
extension LocationMonitoringService {
    override func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.completion(region, nil)
    }
    
    override func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        self.completion(nil, error)
    }
}
