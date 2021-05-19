//
//  ClassifiedMapViewController.swift
//
//  Created by Admin on 26.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit
import CoreData

class ClassifiedMapViewController: UIViewController {
    
    public weak var classifiedViewControllerDelegate: ClassifiedViewController?
    public weak var msr: Mshr?

    @IBAction func addToGathered(_ sender: Any) {
        let alert = UIAlertController(title: "Сохранить",
                                       message: "Добавить описание ?",
                                       preferredStyle: .alert)
         
         let saveAction = UIAlertAction(title: "Добавить", style: .default) { [unowned self] action in

           guard let textField = alert.textFields?.first,
             let nameToSave = textField.text else {
               return
           }
         }
         
         let cancelAction = UIAlertAction(title: "Отмена",
                                          style: .cancel)

         alert.addTextField()

         alert.addAction(saveAction)
         alert.addAction(cancelAction)
         
         present(alert, animated: true)
    }
   
}
