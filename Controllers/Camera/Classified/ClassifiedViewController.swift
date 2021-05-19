//
//  ClassifiedViewController.swift
//
// Открывается для показа инфо по обнаруженному объекту
//
//  Created by Admin on 01.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit
import Vision
import CoreLocation

class ClassifiedViewController: UIViewController {
    
    public static let segueIdentifier = String(describing: ClassifiedViewController.self)
    
    @IBOutlet weak var removeFromFound: UIButton!
    @IBOutlet weak var addToGatheredBtn: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var descriptionScrollView: UIScrollView!
    @IBOutlet weak var fakesView: UIView!
    @IBOutlet weak var fakesTable: UITableView!
    
    @IBOutlet weak var galleryView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapControlsView: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var textField: UITextView!

    public var mCode: String?
    public weak var visionViewControllerDelegate: VisionViewController?
    public weak var mainTabBarControllerDelegate: MainTabBarController?
    
    private var galleryImages: [UIImage?] = []
    private var fakes: [String] = []
    private var mId: Int?

    //MARK: OBSERVATION
    public var observationResults: [VNClassificationObservation]?

    //MARK: VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSegmentControl()
        
        //defaul description view in segment control
        switchSegmentedViews(indexToShow: 0)
        
        fakesTable.delegate = self
        fakesTable.dataSource = self
        
        //MARK: заполняем инфой
        if let firstResult = observationResults?.first {
            mainTabBarControllerDelegate?.mainService.mService.getByCode(code: firstResult.identifier, completion: { [unowned self] (m, error) in
                if error != nil {
                    return
                }
                
                guard let mr = m else {
                    return
                }
    
                self.mCode = mr.code

                guard let name = mr.name,
                    let description = mr.bigDescription
                    else {
                        return
                }
 
                //название и описание
                DispatchQueue.main.async {
                    self.textField.text = description
                    self.mainLabel.text = name
                }
                
                //заполнение таба с fakes
                if let fakes = mr.fakes {

                    DispatchQueue.main.async {
                        //заполнение для data source
                        self.fakes = fakes.components(separatedBy: ",")
                        
                        self.segmentControl.setEnabled(true, forSegmentAt: 1)
                        self.fakesTable.reloadData()
                    }

                }
                
                //MARK: заполнение галереи
                self.mainTabBarControllerDelegate?.mainService.mService.getAllImagesFromImagesBundle(folderName: mr.code, completion: { [unowned self] (allImages) in
                    if let allImages = allImages, allImages.count > 0 {

                        //прикрепление захваченной фото
                        if let cameraImage = self.visionViewControllerDelegate?.convertedImageFromPixelBuffer {
                            DispatchQueue.main.async {
                                self.mainImage.image = cameraImage
                            }
                        }

                        //заполнение галереи картинок
                        self.galleryImages = allImages
                    } else { //пришел пустой результат - нет картинок ВООБЩЕ
                        DispatchQueue.main.async {
                            //если картинок нет иконка галереи неактивна
                            self.segmentControl.setEnabled(false, forSegmentAt: 3)
                        }
                    }

                    //обновляем после того как добавлены картинки в галерею
                    DispatchQueue.main.async {
                        self.setupCollectionView()
                    }
                })
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard let visionViewController = visionViewControllerDelegate else {
            fatalError("Unexpected Error: Vision Controller not found !")
        }
        visionViewController.classifyStatus = Statuses.unstableCamera
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if
            let indexPath = fakesTable.indexPathForSelectedRow,
            let detailVC = segue.destination as? DetailViewController
        {
            detailVC.mCode = self.fakes[indexPath.row]
            
            //проброс ссылок на главные контроллеры
            detailVC.mainTabBarControllerDelegate = mainTabBarControllerDelegate
            detailVC.visionViewControllerDelegate = visionViewControllerDelegate
        }
        
        //проброс делегата
        if let mapVC = segue.destination as? ClassifiedMapViewController {
            mapVC.classifiedViewControllerDelegate = self
        }
    }
}


//MARK: Segment Control
extension ClassifiedViewController {
    func setupSegmentControl() {
        segmentControl.addTarget(self, action: #selector(segmentedValueChanged(_:)), for: .valueChanged)
        
        //фейки будут активны тол о если придут с классификатором
        segmentControl.setEnabled(false, forSegmentAt: 1)
    }
    
    //callback for segement control
    @objc func segmentedValueChanged(_ sender:UISegmentedControl!) {
        switchSegmentedViews(indexToShow: sender.selectedSegmentIndex)
    }
    
    //меняет видимость вью в зависимости от выбранного пункта в сегмент контроле
    private func switchSegmentedViews(indexToShow: Int!) {
       
        switch indexToShow {
            case 0:
                DispatchQueue.main.async {
                    self.descriptionScrollView.isHidden = false
                    self.fakesView.isHidden = true
                    self.mapControlsView.isHidden = true
                    self.galleryView.isHidden = true
                }
            
            case 1:
                DispatchQueue.main.async {
                    self.descriptionScrollView.isHidden = true
                    self.fakesView.isHidden = false
                    self.mapControlsView.isHidden = true
                    self.galleryView.isHidden = true
                }
                
            case 2:
                DispatchQueue.main.async {
                    self.descriptionScrollView.isHidden = true
                    self.fakesView.isHidden = true
                    self.mapControlsView.isHidden = false
                    self.galleryView.isHidden = true
                }
            
            case 3:
            DispatchQueue.main.async {
                self.descriptionScrollView.isHidden = true
                self.fakesView.isHidden = true
                self.mapControlsView.isHidden = true
                self.galleryView.isHidden = false
            }
        
            default:
                DispatchQueue.main.async {
                    self.descriptionScrollView.isHidden = true
                    self.fakesView.isHidden = false
                    self.mapControlsView.isHidden = true
                    self.galleryView.isHidden = true
                }
        }
    }
}

//MARK: Таблица FAKES 
extension ClassifiedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fakes.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableCell = tableView.dequeueReusableCell(withIdentifier: FakesTableViewCell.reuseIdentifier) else {
            fatalError("Unexpected return type")
        }

        let code = fakes[indexPath.row]
        
        //получить по ключу из текущего массива
        mainTabBarControllerDelegate?.mainService.mService.getByCode(code: code, completion: { (mr, error) in
            if let m = mr {
                if let name = m.name {
                    //заполнить название
                    DispatchQueue.main.async {
                        tableCell.textLabel?.text = name
                    }
                }
            } else {
                DispatchQueue.main.async {
                    tableCell.textLabel?.text = code
                }
            }
        })
        
        mainTabBarControllerDelegate?.mainService.mService.getFirstImageFromImagesBundle(folderName: code, completion: { (mainImage) in
            //главная картинка
            DispatchQueue.main.async {
                tableCell.imageView?.image = mainImage
            }
        })
        
        return tableCell
    }
}

//MARK: COllection View
extension ClassifiedViewController {
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        collectionView.allowsMultipleSelection = false
    }
}

//MARK: Collection View Data Source
extension ClassifiedViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return galleryImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailCollectionViewCell.identifier, for: indexPath) as? DetailCollectionViewCell else { fatalError("Unknown Cell Type") }
        
        if galleryImages[indexPath.item] != nil {
            itemCell.imageView.image = galleryImages[indexPath.item]
        }
        
        return itemCell
    }
}

//MARK: Collection View Action Delegate
extension ClassifiedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxWidth = collectionView.frame.width
        let maxHeight = collectionView.frame.height

        return CGSize(width: maxWidth, height: maxHeight)

    }
}


//MARK: ACTION BTN-s
extension ClassifiedViewController {
    
    @IBAction func addToGathered(_ sender: Any) {
        guard
            let code = mCode,
            let cameraImage = mainImage.image
        else {
            return
        }
        
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = false
            self.addToGatheredBtn.isHidden = true
        }
 
        mainTabBarControllerDelegate?.mainService.foundService.addToFounded(code: code, image: cameraImage, groupLocationId: 1, completion: { [weak self] (shId ,error) in
            if error != nil || shId == nil {
                DispatchQueue.main.async {
                    self?.activityIndicator.isHidden = true
                    self?.addToGatheredBtn.isHidden = false
                    
                    let alert = UIAlertController(title: "Ошибка", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
                
                return
            }
            
            self?.mId = shId
            
            //высветить подтверждение что сохранены
            DispatchQueue.main.async {
                self?.activityIndicator.isHidden = true
                self?.addToGatheredBtn.isHidden = true
                self?.removeFromFound.isHidden = false
                
                let alert = UIAlertController(title: "Успешно", message: "Добавлено в сохраненные", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func removeFromFound(_ sender: Any) {
        guard let id = self.mId else {
            return
        }
        
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = false
            self.addToGatheredBtn.isHidden = true
            self.removeFromFound.isHidden = true
        }
        
        mainTabBarControllerDelegate?.mainService.foundService.deleteById(id: id, completion: { (error) in
            if error != nil {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Ошибка", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    
                    self.present(alert, animated: true) {
                        self.activityIndicator.isHidden = true
                        self.removeFromFound.isHidden = false
                    }
                }
                
                return
            }
            
            self.mId = nil
            
            //высветить подтверждение что сохранены
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Успешно", message: "Удалено из сохраненных", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true) {
                    self.activityIndicator.isHidden = true
                    self.addToGatheredBtn.isHidden = false
                    self.removeFromFound.isHidden = true
                }
            }
        })
    }
}
