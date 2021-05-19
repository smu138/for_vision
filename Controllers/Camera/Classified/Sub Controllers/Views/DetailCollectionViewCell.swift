//
//  DetailCollectionViewCell.swift
//
//  Created by Admin on 23.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit

class DetailCollectionViewCell: UICollectionViewCell {
    
    static let identifier = String(describing: DetailCollectionViewCell.self)
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        imageView.image = nil
    }
    
}
