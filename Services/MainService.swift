//
//  MainService.swift
//  ГЛАВНЫЙ СЕРВИС - РАСПРЕДЕЛЯЕТ ЗАДАЧИ ПО СООТВЕТСТВУЮЗИМ СЕРВИСАМ
//
//  Created by Admin on 04.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Vision

class MainService: NSObject {

    lazy var singleLocationRequestService = SingleLocationRequestService()
    
    lazy var locationMonitorService = LocationMonitoringService()
    
    lazy var baseLocationService = BaseLocationService()
    
    lazy var groupLocationService = GroupLocationServiceCD()
    
    lazy var mService = MService()
    
    lazy var foundService = FoundService()
    
    lazy var regionService = RegionService()
    
    //MARK: MAP KIT DELEGATES
    lazy var mapViewDelegate = MapViewDelegate()
    
    override init() {
        super.init()
        
        //обратная связь для получения других сервисов
        bundleServices()
    }
    
    //MARK: Связь сервисов между собой
    private func bundleServices() -> Void
    {
        mService.singleLocationRequestServiceDelegate = singleLocationRequestService
        mService.mainService = self
        
        foundService.mServiceDelegate = mService
        foundService.singleLocationRequestServiceDelegate = singleLocationRequestService
        foundService.mainService = self
       
        groupLocationService.mainService = self
        groupLocationService.mServiceDelegate = mService
        groupLocationService.foundMServiceDelegate = foundService
        groupLocationService.singleLocationRequestServiceDelegate = singleLocationRequestService
        
        regionService.locationMoritoringServiceDelegate = locationMonitorService
        
        //map view delegate
        mapViewDelegate.mainService = self
    }

    //MARK: Создает и созраняет регион и начинает его мониторить 
    /**
        Специально вынесен метод определения текущих координат - потому что возможно потребуетс язадавать произвольный регион прямо на карте и координаты будут не текущие
        Поэтому метод принимает уже готовые координаты
        В данном случае тестовый метод подставляет текущие координаты
     */
    public func addRegionForMonitoring() {
        //получим текущие координаты
        singleLocationRequestService.initService(completion: { [unowned self] (clLocation, error) in
            if error != nil {
                print(error?.localizedDescription ?? SingleRequestError.unknownError.localizedDescription)
                return
            }

            guard let clLocation = clLocation else {
                print(SingleRequestError.locationNotAvailable.localizedDescription)
                return
            }

            //создаем и добавляем регион в мониторинг для полученной локации
            //mainTabBarController?.mainService.addRegionForMonitoring()
            if let newRegion = self.regionService.addRegion(code: "testCode", centerCoords: clLocation.coordinate, radius: 30, name: "Тестовый регион для проверки", smallDescription: "Краткое описание которое введет юзер", notifyOnEntry: true, notifyOnExit: nil) {
                
                self.regionService.startMonitoringRegion(region: newRegion)
            }
  
        })
    }
    
}
