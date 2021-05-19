//
//  FileManager.swift
//
//  Created by Admin on 01.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation

extension FileManager {
    
    private static func getDocumentsDirectory()-> URL {
        let paths = self.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    private static func getPlistContent <T : Codable> (anyClass: T.Type, storePath: String!) -> T?
    {
        if  let xml = self.default.contents(atPath: storePath) {
            return try? PropertyListDecoder().decode(anyClass.self, from: xml)
        }
        
        return nil
    }
    
    //сверяет сохраненную (локальную) и бандл версию конфигов и если есть расхождение то обновляет старую версию
    static func isUpdatedSettings(fileName: String!, fileExtension: String!) -> Bool
    {
        let directoryUrl = self.getDocumentsDirectory().appendingPathComponent(fileName + "." + fileExtension)
        
        guard
            let bundleStorePath = Bundle.main.path(forResource: fileName, ofType:fileExtension),
            let bundleSettings = self.getPlistContent(anyClass: CoreDataSettings.self, storePath: bundleStorePath)
        else {
            fatalError("Incorrect data settings")
        }
        
        //проверяем сохранены ли настройки в документах
        if (!self.default.fileExists(atPath: directoryUrl.path)) { //настройки не сохранены
            
            //сохраняем их в документах (возвращая тру - можно обновлять базы)
            do {
                try self.default.copyItem(atPath: bundleStorePath, toPath: directoryUrl.path)
            } catch let nserror as NSError {
                fatalError("Error: \(nserror.localizedDescription)")
            }

            return true
            
        } else { //настройки сохранены
        
            //сверяем настройки в документах и настройки в файле апп бандла
            guard let localDirectorySettings = self.getPlistContent(anyClass: CoreDataSettings.self, storePath: directoryUrl.path) else {
                fatalError("Data settings mismatch")
            }

            //настройки совпадают - ничего менять не надо - (возвращаем фалс)
            if bundleSettings.storeVersion == localDirectorySettings.storeVersion {
                return false
            } else {
                //версия в документах меньше чем версия в апп директори
                if bundleSettings.storeVersion < localDirectorySettings.storeVersion {
                    //копируем в директори текущий файл из апп бандла
                    _ = try? self.default.removeItem(at: directoryUrl)
                    do {
                        try self.default.copyItem(atPath: bundleStorePath, toPath: directoryUrl.path)
                    } catch let nserror as NSError {
                        fatalError("Error: \(nserror.localizedDescription)")
                    }
                    
                    //возвращаем тру - можно обновлять базы
                    return true
                }
            }

        }
        return false
    }
}
