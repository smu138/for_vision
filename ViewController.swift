//
//  ViewController.swift
//  TODO : Под полный рефакторинг и вынос в viewModel
//
//  Created by Admin on 13.03.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var pickedImageView: UIImageView!
    @IBOutlet weak var imageLabel: UILabel!
    
    // MARK: - Image Classification
    
    /// - Tag: MLModelSetup
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MClassifier().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    // Updates the UI with the results of the classification.
    // ЗАмыкание вызываемое при выполнении реквеста
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.imageLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            let classifications = results as! [VNClassificationObservation]
        
            if classifications.isEmpty {
                self.imageLabel.text = "Nothing recognized."
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                   return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                
                let text = descriptions.joined(separator: " - ")
                self.imageLabel.text = text
            }
        }
    }
    
    // MARK: Классифицируем при выборе картинки
    /// - Tag: PerformRequests
    func updateClassifications(for image: UIImage) {

        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                //здесь запускается колбек processClassifications() для созданного Request
                try handler.perform([self.classificationRequest])
            } catch {
                //пока ничего
            }
        }
    }
}

// MARK: - Methods
extension ViewController {

    @IBAction func pickImage(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            //predictionLayer.hide()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true)
        } else {
            //showAlert(title: "Error!", msg: "Photo library is not available!")
        }
    }

  func detectScene(image: CIImage) {
    imageLabel.text = "detecting scene..."
  }
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)

        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
          fatalError("couldn't load image from Photos")
        }

        pickedImageView.image = image
        guard let mainTabBarController = tabBarController as? MainTabBarController else { return }
        //mainTabBarController.pickedImage = image

        updateClassifications(for: image)
    }
}

// MARK: Orientation Competibility Extensions
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        }
    }
}
extension UIImage.Orientation {
    init(_ cgOrientation: UIImage.Orientation) {
        switch cgOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        }
    }
}
