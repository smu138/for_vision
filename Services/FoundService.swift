//
//  FoundService.swift
//
//  Сервис для сохранения и получения моделей из бд найденных
//
//  Created by Admin on 05.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import RealmSwift
import KDCalendar

class FoundService: NSObject {
    
    public weak var mServiceDelegate: MService?
    public weak var singleLocationRequestServiceDelegate: SingleLocationRequestService?
    public weak var mainService: MainService?
    
    //MARK: GET ONE BY ID
    public func getOneByCode(code: String!, completion: @escaping (FoundM?, Error?)->()) -> Void
    {
        DispatchQueue(label: "services.foundService.getOneByCode").async {
            do {
                
                let realm = try Realm(configuration: RealmConfig.founded.configuration)
                let m = realm.objects(FoundM.self)
                    .filter("code = %@", code!)
                    .first
                
                completion(m, nil)
                
            } catch let error as NSError {
                completion(nil, error)
            }
            
        }
        
    }
    
    //MARK: GET ONE BY CODE
    public func getOneByid(id: Int!, completion: @escaping (FoundM?, Error?)->()) -> Void
    {
        DispatchQueue(label: "services.foundService.getOneByid").async {
            do {
                let realm = try Realm(configuration: RealmConfig.founded.configuration)
                let m = realm.object(ofType: FoundM.self, forPrimaryKey: id)
                
                completion(m, nil)
                
            } catch let error as NSError {
                completion(nil, error)
            }
        }
    }
    
    //MARK: GET ALL
    public func getAll(completion: @escaping (Results<FoundM>?, Error?)->()) ->Void
    {
        DispatchQueue(label: "services.foundService.getAll").async {
            do {
                let realm = try Realm(configuration: RealmConfig.founded.configuration)
                let m = realm.objects(FoundM.self).sorted(byKeyPath: "id", ascending: true)
                
                completion(m, nil)
                
            } catch let error as NSError{
                completion(nil, error)
            }
        }
    }
    
    public func getAllImagesFromImagesBundle(folderName: String, completion: @escaping (_ catchedImages: [UIImage]?)->()) {
        
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        let assetURL = bundleURL.appendingPathComponent("images.bundle").appendingPathComponent(folderName)
        
        var images = [UIImage]()
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: assetURL, includingPropertiesForKeys: [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles)
            
            for item in contents
            {
                
                let data = try? Data(contentsOf: item.absoluteURL)
                if
                    let data = data,
                    let image = UIImage(data: data)
                {
                    images.append(image)
                }
                
            }
            
        } catch {
            completion(images)
        }
        
        completion(images)
    }
    
    public func getFirstImageFromImagesBundle(folderName: String, completion: @escaping (_ catchedImage: UIImage?)->()) {
        
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        let assetURL = bundleURL.appendingPathComponent("images.bundle").appendingPathComponent(folderName)
        
        do {
            if let content = try fileManager.contentsOfDirectory(at: assetURL, includingPropertiesForKeys: [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles).first {
                
                let data = try? Data(contentsOf: content.absoluteURL)
                if let data = data {
                    completion(UIImage(data: data))
                    return
                }
            }
            
        } catch {
            completion(nil)
        }
        
        completion(nil)
    }
    
    //MARK: Создает и сохраняет в базу
    public func addToFounded(code: String!, image: UIImage?, groupLocationId: Int!, completion: @escaping (Int?, Error?) -> ()) -> Void
    {
        mServiceDelegate?.getByCode(code: code, completion: { (classifiedM, error) in
            if error != nil {
                completion(nil, error)
                return
            }
            
            if classifiedM == nil {
                completion(nil, MServiceError.unknownError)
                return
            }
            
            //получить текущую локацию
            self.singleLocationRequestServiceDelegate?.initService(completion: { (clLocation, locationError) in
                if locationError != nil {
                    completion(nil, locationError ?? SingleRequestError.unknownError)
                    return
                }
                
                guard let clLocation = clLocation else {
                    completion(nil, SingleRequestError.locationNotAvailable)
                    return
                }
                
                //проверяем чтобы это не находилось на одном месте (возможно надо ДОБАВИТЬ эту проверку - или проверять что на одних координатах сохранялись только разные)
                
                //create new object
                DispatchQueue(label: "services.foundService.addToFounded").async {
                    
                    do {
                        let realm = try Realm(configuration: RealmConfig.founded.configuration)
                        let found = FoundM(clLocation: clLocation)
                        
                        found.code = code
                        found.date = Date().addingTimeInterval(TimeInterval.init( TimeZone.current.secondsFromGMT() ))
                        
                        //добавить группу TODO
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyyMMddHHmmss"
                        
                        guard let formattedId = Int( dateFormatter.string(from: Date()) ) else {
                            completion(nil, MServiceError.unknownError)
                            return
                        }
                        found.id = formattedId
                        
                        found.accuracy = abs(min(clLocation.verticalAccuracy, clLocation.horizontalAccuracy))
                        found.latitude = clLocation.coordinate.latitude
                        found.longitude = clLocation.coordinate.longitude
                        
                        try realm.write {
                            realm.add(found)
                        }
                        
                        completion(formattedId, error)
                        
                    } catch let error as NSError {
                        completion(nil, error)
                    }
                }
                
            })
        })
        
    }
    
    //создает аннотации на основе дат календаря
    public func getByDates(dates: [Date]!, completion: @escaping ([CustomMapAnnotation], Error?) -> ()) -> Void
    {
        var customMapAnnotations: [CustomMapAnnotation] = []
        
        let sorted = dates.sorted { (dateOne, dateTwo) -> Bool in
            return dateOne <= dateTwo
        }
        
        let firstDate = sorted.first!
        let lastDate = sorted.last!
        
        DispatchQueue(label: "services.foundService.getByDates").async {
            do {
                let realm = try Realm(configuration: RealmConfig.founded.configuration)
                let mObjcts = realm.objects(FoundM.self)
                    .filter("date BETWEEN %@", [firstDate, lastDate])
                
                mObjcts.forEach { (foundObj) in
                    let annotation = CustomMapAnnotation(coordinate: foundObj.clLocation.coordinate, title: foundObj.code, subtitle: foundObj.date?.toString(format: "yyyy-MM-dd"))
                    
                    customMapAnnotations.append(annotation)
                }
                
                completion(customMapAnnotations, nil)
                
            } catch let error as NSError {
                completion([], error)
            }
        }
    }
    
    //delete single object from founded
    public func deleteByCode(code: String!, completion: @escaping (Error?) -> ()) -> Void
    {
        
    }
    
    //delete multy objects from founded
    public func deleteByCodes(codes: [String]!, completion: @escaping (Error?) -> ()) -> Void
    {
        
    }
    
    public func deleteById(id: Int!, completion: @escaping (Error?) -> ()) -> Void
    {
        DispatchQueue(label: "services.foundService.deleteById").async {
            do {
                let realm = try Realm(configuration: RealmConfig.founded.configuration)
                
                if let m = realm.object(ofType: FoundM.self, forPrimaryKey: id) {
                    try realm.write {
                        realm.delete(m)
                    }
                    completion(nil)
                    return
                }
                
                completion(FounServiceError.notFound)
                
            } catch let error as NSError {
                completion(error)
            }
        }
    }
    
    //MARK: Получает последний найденный по времени
    public func getLastFound(completion: @escaping (FoundM?, Error?)->()) -> Void
    {
        DispatchQueue(label: "services.foundService.getLastFound").async {
            do {
                let realm = try Realm(configuration: RealmConfig.founded.configuration)
                let lastOne = realm.objects(FoundM.self).sorted(byKeyPath: "id", ascending: false).first
                
                completion(lastOne, nil)
                
            } catch let error as NSError {
                completion(nil, error)
            }
        }
    }
    
}
