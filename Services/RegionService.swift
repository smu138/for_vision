//
//  RegionService.swift
//
//  Created by Admin on 06.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class RegionService: NSObject {
    
    public weak var locationMoritoringServiceDelegate: LocationMonitoringService?
    public weak var mainServiceDelegate: MainService? //для вывода инфы в основном потоке
    
    private let dispatchQueue = DispatchQueue(label: "region.service.dispatch.queue")
    private let dispatchGroup = DispatchGroup()
    
    //Проверяет- существуе ли в сохраненных регион с таким же кодом - чтобы не добавлять его два раза - рефаторить под CoreData
    public func isExist(code: String!) -> Bool
    {
        return false
    }
    
    //MARK: Достает из базы регион по его коду
    public func getRegionByCode(code: String!) -> Region_cls?
    {
        return TestData.shared.regions.first { $0.code == code }
    }
    
    //MARK: Создает и сохраняет регион в базу
    public func addRegion(code: String!, centerCoords: CLLocationCoordinate2D!, radius: CLLocationDistance?, name: String!, smallDescription: String?, notifyOnEntry: Bool?, notifyOnExit: Bool?) -> Region_cls?
    {
        if !isExist(code: code) {
            //создали регион с определенным радиусом
            let circularRegion = Region_cls(code: code, name: name, smallDescription: smallDescription, center: centerCoords, radius: radius ?? 150)

            circularRegion.notifyOnEntry = notifyOnEntry ?? true
            circularRegion.notifyOnExit = notifyOnExit ?? false //по дефолту не надо сообщать о выходе из зоны
            
            //сохраняем его в базу
            TestData.shared.regions.append(circularRegion)
            
            return circularRegion
        }
        
        return nil
    }
    
    //MARK: Мониторинг региона и реакция на пересечение
    public func startMonitoringRegion(region: Region_cls) -> Void
    {
        locationMoritoringServiceDelegate?.initService(region: region, crossedCompletion: { [unowned self] (crossedRegion, error) in
            guard error == nil else {
                //print(error?.localizedDescription ?? SingleRequestError.unknownError.localizedDescription)
                return
            }

            guard
                let crossedRegion = crossedRegion,
                let savedRegion = self.getRegionByCode(code: crossedRegion.identifier)
            else {
                //print(SingleRequestError.typeMismatch.localizedDescription)
                return
            }
            
            //при пересечении границы будет высвечиваться это
            //print("Триггер региона мониторнга = \(String(describing: savedRegion.name))")
        })
    }
    
    //MARK: Остановка мониторинга
    public func stopMonitoringRegion(region: Region_cls) -> Void
    {
        self.locationMoritoringServiceDelegate?.stopMonitoring(region: region)
    }

}
