//
//  OverlayControlsViewController.swift
//
//  Created by Admin on 30.04.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit
import Vision

class OverlayControlsViewController: BaseOverlayViewController {

    @IBOutlet weak var classifierTextView: UITextView!
    @IBOutlet weak var progressBar: UIProgressView!
    weak var visionControllerDelegate: VisionViewController?
    private var successClassifiedCounts = 0
    private var classifiedIdentifier = ""

    private let colors: [UIColor] = [
        .systemGray,
        .systemRed,
        .systemYellow,
        .systemGreen
    ]
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        clearOverlay()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        clearOverlay()
    }
    
    public var classificationObservation: [VNClassificationObservation]? {
        didSet {
            guard
                let classificationObservation = classificationObservation,
                let firstResult = classificationObservation.first
            else {
                DispatchQueue.main.async {
                    self.classifierTextView.text = "Не определено"
                    self.progressBar.progress = 0
                }
                
                self.visionControllerDelegate?.classifyStatus = .unstableCamera
                self.classifiedIdentifier = ""
                
                return
            }

            var text = ""
            
            classificationObservation[..<3].forEach({ (result) in
                text += "\(result.identifier): \(String(format: "%.2f", result.confidence * 100))%\n"
            })

            //нашлось что то
            if firstResult.confidence > 0.6 {

                if successClassifiedCounts < 3 {
                    successClassifiedCounts += 1
                }
                
                //найденное то что нашлось в предыдущий раз ?
                if classifiedIdentifier == firstResult.identifier {
                    
                    //увеличиваем прогресс
                    DispatchQueue.main.async {
                        self.progressBar.progress += 0.3
                    }
                    
                } else {
                    //добавляем найденное
                    classifiedIdentifier = firstResult.identifier
                    
                    //обнуляем все счетчики поиска
                    successClassifiedCounts = 1
                    
                    //обнуляем прогресс
                    DispatchQueue.main.async {
                        self.progressBar.progress = 0.3
                    }
                }

                DispatchQueue.main.async {
                    //меняем цвет прогрессбара
                    self.progressBar.tintColor = self.colors[self.successClassifiedCounts]
                    
                    //ставим статус- показ инфо
                    //self.visionControllerDelegate?.classifyStatus = Statuses.showingClassifiedInfo
                    
                    //показываем найденный текст
                    self.classifierTextView.text = text
                }
                
                //подтвердилось 3 раза- открываем окно с детальным инфо
                if successClassifiedCounts == 3 {
                    
                    self.visionControllerDelegate?.classifyStatus = Statuses.infoViewPresented
                    successClassifiedCounts = 0

                    //MARK: ОТКРЫТИЕ ДЕТАЛЬНОЙ ИНФО
                    DispatchQueue.main.async {
                        self.progressBar.progress = 1
                        self.performSegue(withIdentifier: ClassifiedViewController.segueIdentifier, sender: self)
                    }
                } else {
                    //отпускаем захват на следующий заход
                    self.visionControllerDelegate?.classifyStatus = .unstableCamera
                }
            } else {
                //ничего не нашлось ( < 60%)
                clearOverlay()
            }
        }
    }
    
    //MARK: NAVIGATION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let classifiedViewController = segue.destination as? ClassifiedViewController {
               
            //назначим делегата для проброса статусов
            classifiedViewController.visionViewControllerDelegate = visionControllerDelegate

            //проброс делегата для сохранения локаций
            guard let mainTabBarController = tabBarController as? MainTabBarController else {
               fatalError("Main Tab Bar is not initialized")
            }

            //проброс таббар контроллера для действий с координатами, если потребуется
            classifiedViewController.mainTabBarControllerDelegate = mainTabBarController

            //проброс найденной инфы
            classifiedViewController.observationResults = self.classificationObservation
        }
    }

    private func clearOverlay() -> Void
    {
        //ничего не нашлось ( < 60%)
        successClassifiedCounts = 0
        classifiedIdentifier = ""
        
        DispatchQueue.main.async {
            self.progressBar.progress = 0
            self.progressBar.tintColor = self.colors[self.successClassifiedCounts]
            self.classifierTextView.text = "Не определено"
        }
        //отпускаем захват
        //self.visionControllerDelegate?.classifyStatus = .unstableCamera
    }
}

// MARK: ACTIONS
extension OverlayControlsViewController {
    //открыть детальное окно с распознанным объектом
    @IBAction func infoBtnPressed(_ sender: Any) {
        visionControllerDelegate?.classifyStatus = Statuses.infoViewPresented
        successClassifiedCounts = 3
        
        //MARK: ОТКРЫТИЕ ДЕТАЛЬНОЙ ИНФО
        DispatchQueue.main.async {
            self.progressBar.progress = 1
            self.performSegue(withIdentifier: ClassifiedViewController.segueIdentifier, sender: self)
        }
 
    }
}
