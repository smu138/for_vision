//
//  DetailViewController.swift
//
//  Created by Admin on 20.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    static let identifier = String(describing: DetailViewController.self)
    @IBOutlet weak var descriptionScrollView: UIScrollView!
    @IBOutlet weak var galleryView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var textField: UITextView!
    public weak var visionViewControllerDelegate: VisionViewController?
    public weak var mainTabBarControllerDelegate: MainTabBarController?
    private var galleryImages: [UIImage?] = []
    public var mCode: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSegmentControl()
        //заполняем инфой
        setupDetailInfo()
    }

    //MARK: SETUP COLLECTION VIEW
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        collectionView.allowsMultipleSelection = false
    }
    
    private func setupDetailInfo() -> Void
    {
        guard let code = self.mCode else {
            fatalError("Unexpected empty code")
        }
        
        mainTabBarControllerDelegate?.mainService.mService.getByCode(code: code, completion: { [unowned self] (mr, error) in
            if let mrs = mr,
                let name = mrs.name,
                let bigDescription = mrs.bigDescription {
                DispatchQueue.main.async {
                    self.textField.text = bigDescription
                    self.mainLabel.text = name
                }
            }
        })

        mainTabBarControllerDelegate?.mainService.mService.getAllImagesFromImagesBundle(folderName: code, completion: { [unowned self] (allImages) in
            if var allImages = allImages, allImages.count > 0 {
                let first = allImages.removeFirst()
                DispatchQueue.main.async {
                    self.mainImage.image = first
                }
                self.galleryImages = allImages
            } else { //пришел пустой результат - нет картинок ВООБЩЕ
                DispatchQueue.main.async {
                    //если картинок нет иконка галереи неактивна
                    self.segmentControl.setEnabled(false, forSegmentAt: 1)
                }
            }
            //обновляем после того как добавлены картинки в галерею
            DispatchQueue.main.async {
                self.setupCollectionView()
            }
        })
    }
}

//MARK: Collection View Data Source
extension DetailViewController: UICollectionViewDataSource {
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
extension DetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxWidth = collectionView.frame.width
        let maxHeight = collectionView.frame.height

        return CGSize(width: maxWidth, height: maxHeight)

    }
}

//MARK: Segment Control
extension DetailViewController {
    
    func setupSegmentControl() {
        segmentControl.addTarget(self, action: #selector(segmentedValueChanged(_:)), for: .valueChanged)
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
                    self.galleryView.isHidden = true
                }
            
            case 1:
                DispatchQueue.main.async {
                    self.descriptionScrollView.isHidden = true
                    self.galleryView.isHidden = false
                }
        
            default:
                DispatchQueue.main.async {
                    self.descriptionScrollView.isHidden = false
                    self.galleryView.isHidden = true
                }
            
        }
    }

}
