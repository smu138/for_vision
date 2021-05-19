//
//  BaseLocationService.swift
//
//  Created by Admin on 03.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit


class BaseLocationService: NSObject {

    public var locationDispatchQueue: DispatchQueue = DispatchQueue(label: "base.location.service.queue")
    public let locationDispathGroup = DispatchGroup()

    //делегат для показа уведомлений и колбеков
    public var delegate: UIViewController?
    
    private var completion: (_ locations: [CLLocation]?, _ error: Error?)->() = {_,_ in }
    
    public let locationManager: CLLocationManager! = {
        let lm = CLLocationManager()
        
        lm.desiredAccuracy = kCLLocationAccuracyBest
        lm.allowsBackgroundLocationUpdates = true

        return lm
    }()
    
    override init() {
        super.init()
        locationManager?.delegate = self
    }
    
    // MARK: ГЛАВНЫЙ МЕТОД ИНИЦИАЛИЗАЦИИ - ДОЛЖЕН БЫТЬ В КАЖДОМ СЕРВИСЕ
    public func initService(completionOnUpdate: @escaping (_ locations: [CLLocation]?, _ error: Error?)->()) {
        
        self.completion = completionOnUpdate

        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            startService()
        } else {
            locationManager?.requestAlwaysAuthorization()
        }
        
    }
    
    //MARK: МЕТОД ДЛЯ НАСЛЕДУЕМЫХ КЛАССОВ ПОД ПЕРЕЗАПИСЬ В СЛУЧАЕ НУЖДЫ
    public func startService() {
        locationDispatchQueue.async(group: locationDispathGroup, qos: .background, flags: .inheritQoS) {
            self.locationManager?.startUpdatingLocation()
        }
    }
    
    //MARK: МЕТОД ДЛЯ НАСЛЕДУЕМЫХ КЛАССОВ ПОД ПЕРЕЗАПИСЬ В СЛУЧАЕ НУЖДЫ
    public func stopService() {
        locationDispatchQueue.async(group: locationDispathGroup, qos: .background, flags: .inheritQoS) {
            self.locationManager?.stopUpdatingLocation()
        }
    }
}

extension BaseLocationService: CLLocationManagerDelegate {
    
    //здесь автоматическое сохранение будет только при вызове метода saveSingleLocation()
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startService()
        }
    }
    
    //MARK: Получение локаций и выполнение колбека происходят здесь
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationDispatchQueue.async(group: locationDispathGroup, qos: .background, flags: .inheritQoS) {
            self.completion(locations, nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.completion(nil, error)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    }
}
