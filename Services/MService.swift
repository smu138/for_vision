//
//  MService.swift
//
//  Сервис для сохранения и получения моделей из бд
//
//  Created by Admin on 05.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import CoreData
import RealmSwift

class MService: NSObject {
    
    public weak var singleLocationRequestServiceDelegate: SingleLocationRequestService?
    public weak var mainService: MainService?
    
    public func getByCode(code: String!, completion: @escaping (Mshr?, Error?)->()) -> Void
    {
        DispatchQueue(label: "services.mService.getByCode").async {
            do {
                let realm = try Realm(configuration: RealmConfig.staticBase.configuration)
                let m = realm.object(ofType: Mshr.self, forPrimaryKey: code)
 
                completion(m, nil)
                                
            } catch {
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
               
           } catch let error as NSError {
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
               
           } catch let error as NSError {
               print(error.localizedDescription)
               completion(nil)
           }

           completion(nil)
    }

}
