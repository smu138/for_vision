//
//  GroupLocationService.swift
//
//  Сервис для сохранения и получения групп локаций
//
//  Created by Admin on 05.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import CoreData

class GroupLocationServiceCD: NSObject {
    
    private let maxGetLocationResults = 100 //max fetch result per query
    private let defaultGroupRadius = 100.0 //meters
    
    public weak var mServiceDelegate: MService?
    public weak var singleLocationRequestServiceDelegate: SingleLocationRequestService?
    public weak var foundMServiceDelegate: FoundService?
    public weak var mainService: MainService?

    //Добавляет к группе (если группы не существует - создает ее)
    public func addToGroup(code: String!, image: UIImage?, completion: @escaping (Error?) -> ()) -> Void
    {
        //получаем текущую локацию
        singleLocationRequestServiceDelegate?.initService(completion: { [unowned self] (currentClLocation, locationError) in
            
            if locationError != nil {
                completion(locationError)
                return
            }
            
            guard let currentClLocation = currentClLocation else {
                completion(GroupLocationServiceError.unknownLocation)
                return
            }
            
            //проверяем - есть ли группа для текущей локации
            //пройдем по всем группам и сравним расстояние до текущих координат
            let sort = NSSortDescriptor(key: "createDate", ascending: false)
            self.getByPredicate(predicate: nil, fetchLimit: self.maxGetLocationResults, sortDescriptors: [sort]) { [unowned self] (allGroupLocations, getByPredicateError) in
                
                if getByPredicateError != nil {
                    completion(getByPredicateError)
                    return
                }
                
                guard let allGroupLocations = allGroupLocations else {
                    completion(GroupLocationServiceError.cantAddToGroup)
                    return
                }

                if allGroupLocations.isEmpty { //групп нет НИ ОДНОЙ
                    
                    //создаем группу
                    self.createGroup(currentClLocation: currentClLocation) { (managedContext, groupLocation, createGroupError) in
                        
                        if createGroupError != nil {
                            completion(createGroupError)
                            return
                        }
                        
                        guard let groupLocation = groupLocation else {
                            completion(GroupLocationServiceError.cantAddToGroup)
                            return
                        }
                        
                        guard let managedContext = managedContext else {
                            completion(GroupLocationServiceError.cantAddToGroup)
                            return
                        }
                        
                        //добавляем в найденные с указанием этой группы
                        self.mainService?.foundService.addToFounded(code: code, image: image, groupLocationId: groupLocation.groupId, completion: { (fnd, addToFoundedError) in
                            
                            if addToFoundedError != nil {
                                completion(addToFoundedError)
                                return
                            }
                            
                            //сохраняем созданную группу (именно здесь - чтобы точно знать что в найденном сохранилось)
                            managedContext.perform {
                                do {
                                    try managedContext.save()
                                    completion(nil)
                                    return
                                } catch let error as NSError {
                                    completion(error)
                                    return
                                }
                            }
                        })
                    }
                    
                } else { //группы есть - но неизвестно входят ли текущие координаты в какую либо группу
                    
                    //проверяем - входят ли текущие координаты в радиус какой либо группы
                    var isInGroup = false
                    allGroupLocations.forEach({ [unowned self] (groupLocation) in
                        
                        if let clLocation = groupLocation.location {
                            
                            //входит в группу
                            if clLocation.distance(from: currentClLocation) <= self.defaultGroupRadius {
                                
                                isInGroup = true
                                
                                //добавляем в найденные с указанием этой группы
                                self.mainService?.foundService.addToFounded(code: code, image: image, groupLocationId: groupLocation.groupId, completion: { (_, error)  in
                                    
                                    if error != nil {
                                        completion(error)
                                        return
                                    }
                                    
                                    //выходим - все сделано
                                    completion(nil)
                                    return
                                })
                            }
                        }
                    })
                    
                    if !isInGroup {//не входит ни в одну группу
                        //создаем группу
                        self.createGroup(currentClLocation: currentClLocation) { (managedContext, groupLocation, createGroupError) in
                            if createGroupError != nil {
                                completion(createGroupError)
                                return
                            }
                            
                            guard let groupLocation = groupLocation else {
                                completion(GroupLocationServiceError.cantAddToGroup)
                                return
                            }
                            
                            guard let managedContext = managedContext else {
                                completion(GroupLocationServiceError.cantAddToGroup)
                                return
                            }
                            
                            self.mainService?.foundService.addToFounded(code: code, image: image, groupLocationId: groupLocation.groupId, completion: { (_, addToFoundedError) in
                                
                                if addToFoundedError != nil {
                                    completion(addToFoundedError)
                                    return
                                }
                                
                                //сохраняем созданную группу (именно здесь - чтобы точно знать что в найденном сохранилось)
                                managedContext.perform {
                                    do {
                                        try managedContext.save()
                                        completion(nil)
                                        return
                                    } catch let error as NSError {
                                        completion(error)
                                        return
                                    }
                                }
                            })
                            
                            //final completion - с ошибкой- если до этого не получилось добавить
                            completion(GroupLocationServiceError.cantAddToGroup)
                            return
                        }
                    }
                }
            }
        })
    }
}
