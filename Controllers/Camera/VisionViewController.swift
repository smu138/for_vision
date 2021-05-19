//
//  VisionViewController.swift
//
//  Created by Admin on 24.04.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class VisionViewController: BaseCameraViewController {

    @IBOutlet weak var textLabel: UILabel!
    
    private var modelName = "CatAndDog"
    private var modelExtension = "mlmodel"
    private let captureSpeed = 10
    
    //здесь лежат классифицированные объекты
    public var classifiedObservations: [VNClassificationObservation]?
    public var classifyStatus = Statuses.unstableCamera
    var currentKadr: Int = 0
    weak var overlayControlsViewController: OverlayControlsViewController?
    private var detectionOverlay: CALayer! = nil
    
    // MARK: Vision parts
    private var analysisRequests = [VNRequest]()
    private let sequenceRequestHandler = VNSequenceRequestHandler()
    
    // MARK: Registration history
    private let maximumHistoryLength = 15
    private var transpositionHistoryPoints: [CGPoint] = [ ]
    private var previousPixelBuffer: CVPixelBuffer?
    public var convertedImageFromPixelBuffer: UIImage? //для проброса захваченной картинки в другие контроллеры
    private var requestHandler: VNImageRequestHandler?
    
    // The current pixel buffer undergoing analysis. Run requests in a serial fashion, one after another.
    private var currentlyAnalyzedPixelBuffer: CVPixelBuffer?
    
    // Queue for dispatching vision classification and barcode requests
    private let visionQueue = DispatchQueue(label: "com.mr.serial.vision.queue")
    var productViewOpen = false
    
    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.currentlyAnalyzedPixelBuffer = nil
        self.classifyStatus = .unstableCamera
        self.teardownAVCapture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupAVCapture()
    }

    // MARK: Открывает окно инфо для определенного объекта
    fileprivate func showFoundInfo(classificationObservation: [VNClassificationObservation]) {

        if self.classifyStatus == .infoViewPresented {
            return
        }
        //робрасываем в оверлей для показа быстрой инфо
        self.overlayControlsViewController?.classificationObservation = classificationObservation
        
        //одновременно сохраняем для себя чтобы показать детальное инфо
        self.classifiedObservations = classificationObservation
    }
    
    // MARK: SetupVisionRequest
    @discardableResult
    func setupVision() -> NSError? {
        let error: NSError! = nil
        
        //не создаем больше одного реквеста
        if self.analysisRequests.count > 0 {
            return error
        }

        guard let objectRecognition = createClassificationRequest() else {
            fatalError("Cant create MLModel")
        }
        
        self.analysisRequests.append(objectRecognition)
        return error
    }
   
    private func createClassificationRequest() -> VNCoreMLRequest? {
        do {
            let objectClassifier = try VNCoreMLModel(for: MClassifier().model)
            let classificationRequest = VNCoreMLRequest(model: objectClassifier, completionHandler: { (request, error) in
                self.classifyStatus = Statuses.classifyingInProgress
                
                if let results = request.results as? [VNClassificationObservation] {
                    self.classifyStatus = Statuses.classified
                    self.showFoundInfo(classificationObservation: results)
                }
            })
            
            classificationRequest.imageCropAndScaleOption = .centerCrop
            return classificationRequest
        } catch let _ as NSError {
            return nil
        }
    }
    
    private func convertImage(pixelBufer: CVPixelBuffer?, orientation: UIImage.Orientation) -> UIImage?
    {
        guard let pixelBufer = pixelBufer else {
            return nil
        }

        let ciimage : CIImage = CIImage(cvPixelBuffer: pixelBufer)
        let context: CIContext = CIContext.init(options: nil)
        let cgImage: CGImage = context.createCGImage(ciimage, from: ciimage.extent)!
        let image: UIImage = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
        return image
    }
    
    /// - Tag: AnalyzeImage
    private func analyzeCurrentImage() {
        let orientation = exifOrientationFromDeviceOrientation()
        requestHandler = VNImageRequestHandler(cvPixelBuffer: currentlyAnalyzedPixelBuffer!, orientation: orientation)
        
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentlyAnalyzedPixelBuffer = nil }
                
                if let convertedImage = self.convertImage(pixelBufer: self.currentlyAnalyzedPixelBuffer, orientation: orientation.toUIImageOrientetion) {
                    self.convertedImageFromPixelBuffer = convertedImage
                }
                
                try self.requestHandler?.perform(self.analysisRequests)
            } catch {
                //print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    fileprivate func resetTranspositionHistory() {
        transpositionHistoryPoints.removeAll()
    }
    
    fileprivate func recordTransposition(_ point: CGPoint) {
        transpositionHistoryPoints.append(point)
        
        if transpositionHistoryPoints.count > maximumHistoryLength {
            transpositionHistoryPoints.removeFirst()
        }
    }
    /// - Tag: CheckSceneStability
    fileprivate func sceneStabilityAchieved() -> Bool {
        // Determine if we have enough evidence of stability.
        if transpositionHistoryPoints.count == maximumHistoryLength {
            // Calculate the moving average.
            var movingAverage: CGPoint = CGPoint.zero
            for currentPoint in transpositionHistoryPoints {
                movingAverage.x += currentPoint.x
                movingAverage.y += currentPoint.y
            }
            let distance = abs(movingAverage.x) + abs(movingAverage.y)
            if distance < 20 {
                return true
            }
        }
        return false
    }
    
    // MARK: Захват изображения
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        guard previousPixelBuffer != nil else {
            previousPixelBuffer = pixelBuffer
            self.resetTranspositionHistory()
            return
        }
        
        if classifyStatus == .classifyingInProgress {
            return
        }
        
        if classifyStatus == .infoViewPresented {
            return
        }

        let registrationRequest = VNTranslationalImageRegistrationRequest(targetedCVPixelBuffer: pixelBuffer)
        do {
            try sequenceRequestHandler.perform([ registrationRequest ], on: previousPixelBuffer!)
        } catch let _ as NSError {
            return
        }
        
        previousPixelBuffer = pixelBuffer
        
        if let results = registrationRequest.results {
            if let alignmentObservation = results.first as? VNImageTranslationAlignmentObservation {
                let alignmentTransform = alignmentObservation.alignmentTransform
                self.recordTransposition(CGPoint(x: alignmentTransform.tx, y: alignmentTransform.ty))
            }
        }

        if self.sceneStabilityAchieved() {
            classifyStatus = Statuses.stableCamera
        } else {
            classifyStatus = Statuses.unstableCamera
        }

        doClassify(cvImageBuffer: pixelBuffer)
    }
    
    // MARK: Главный цикл логики
    private func doClassify(cvImageBuffer: CVImageBuffer) {
        switch self.classifyStatus {
            case Statuses.unstableCamera:
                //отправляем пустой результат чтобы сбросить данные на оверлее
                self.overlayControlsViewController?.classificationObservation = []
                showDetectionOverlay(false)
            case Statuses.stableCamera:
                showDetectionOverlay(true)
                if currentlyAnalyzedPixelBuffer == nil {
                    currentKadr += 1
                    if currentKadr != captureSpeed {
                        return
                    }
                    currentKadr = 0
                    
                    // Retain the image buffer for Vision processing.
                    currentlyAnalyzedPixelBuffer = cvImageBuffer
                    analyzeCurrentImage()
                }

            case Statuses.classifyingInProgress:
                showDetectionOverlay(false)
                
            case Statuses.classified:
                showDetectionOverlay(false)
                
            case Statuses.showingClassifiedInfo:
                self.showDetectionOverlay(false)
            case Statuses.infoViewPresented:
                self.showDetectionOverlay(false)
            }
    }

    private func showDetectionOverlay(_ visible: Bool) {
        DispatchQueue.main.async(execute: {
            // perform all the UI updates on the main queue
            self.detectionOverlay.isHidden = !visible
        })
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // start the capture
        startCaptureSession()
        
        // setup Vision parts
        setupLayers()
        setupVision()
    }
    
    func setupLayers() {
        DispatchQueue.main.async(execute: {
            self.detectionOverlay = CALayer()
            self.detectionOverlay.frame = self.previewView.bounds.insetBy(dx: 20, dy: 20)
            self.detectionOverlay.position = CGPoint(x: self.previewView.bounds.midX, y: self.previewView.bounds.midY)
            self.detectionOverlay.borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.7])
            self.detectionOverlay.borderWidth = 3
            self.detectionOverlay.cornerRadius = 2
            self.detectionOverlay.isHidden = true

            self.previewLayer.addSublayer(self.detectionOverlay)
        })
    }
    
    @IBAction func unwindToScanning(unwindSegue: UIStoryboardSegue) {
        productViewOpen = false
        self.resetTranspositionHistory() // reset scene stability
    }

    // MARK: - Navigation
    //In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //сохраняем линк на оверлей из контейнер вью
        if let overlayControlsViewController = segue.destination as? OverlayControlsViewController {
            self.overlayControlsViewController = overlayControlsViewController
            
            //назначим делегата для проброса статусов
            self.overlayControlsViewController?.visionControllerDelegate = self
        }
 
        if let classifiedViewController = segue.destination as? ClassifiedViewController {
            //назначим делегата для проброса статусов
            classifiedViewController.visionViewControllerDelegate = self
            
            //проброс делегата для сохранения локаций
            guard let mainTabBarController = tabBarController as? MainTabBarController else {
                fatalError("Main Tab Bar is not initialized")
            }
            classifiedViewController.mainTabBarControllerDelegate = mainTabBarController
            
            //проброс найденной инфы
            classifiedViewController.observationResults = self.classifiedObservations
        }
    }

}
