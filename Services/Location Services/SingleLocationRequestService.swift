//
//  SingleLocationRequestService.swift
//
//  Created by Admin on 03.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit


class SingleLocationRequestService: BaseLocationService {

    //для каждого серивиса completion разный по функционалу
    private var completion: (_ currentLocation: CLLocation?, _ error: Error?)->() = {_,_ in }

    override init() {
        super.init()
        locationManager.delegate = self
        self.locationDispatchQueue = DispatchQueue(label: "single.location.request.queue")
    }

    // MARK : сохраняем текущее местоположение (единожды)
    public func initService(completion: @escaping (_ currentLocation: CLLocation?, _ error: Error?)->()) {

        self.completion = completion
        
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            startService()
        } else {
            locationManager?.requestAlwaysAuthorization()
        }
    }

    //запускает колбек didUpdateLocations ТОЛЬКО ОДИН РАЗ
    override public func startService() {
        self.locationManager?.requestLocation()
    }
    
}

extension SingleLocationRequestService {
    
    //здесь автоматическое сохранение будет только при вызове метода saveSingleLocation()
    override func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startService()
        }
    }
    
    //MARK: Получение локаций и выполнение колбека происходят здесь (возможно здесь их и надо сохранять в CoreData)
    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.first != nil {

            self.completion(locations.first, nil)
        } else {

            self.completion(nil, SingleRequestError.unknownError)
        }
    }

    override func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.completion(nil, error)
    }
}
