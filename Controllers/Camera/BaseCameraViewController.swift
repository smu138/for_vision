//
//  CameraViewController.swift
//
//  Created by Admin on 24.04.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit
import AVFoundation
import Vision


class BaseCameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var previewView: UIView!
    
    var rootLayer: CALayer! = nil
    var bufferSize: CGSize = .zero
    let previewViewManual: UIView! = UIView()
    private let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var deviceInput: AVCaptureDeviceInput?
    private var captureConnection: AVCaptureConnection?

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Implement this in the subclass.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupPreviewView() {
        previewViewManual.translatesAutoresizingMaskIntoConstraints = false
        previewViewManual.isHidden = false
        previewViewManual.clipsToBounds = true

        view.addSubview(previewViewManual)
        
        previewViewManual.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        previewViewManual.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        previewViewManual.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        previewViewManual.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor).isActive = true
    }

    func setupAVCapture() {
        // Select a video device and make an input.
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            return
        }
        guard let deviceInput = self.deviceInput else {
            return
        }

        session.beginConfiguration()
        
        // The model input size is smaller than 640x480, so better resolution won't help us.
        session.sessionPreset = .vga640x480
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output.
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            session.commitConfiguration()
            return
        }
        
        self.captureConnection = videoDataOutput.connection(with: .video)

        if let connection = captureConnection {
            
            connection.isEnabled = true
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = AVCaptureVideoOrientation.init(ui: UIDevice.current.orientation)
            }
        }

        session.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        previewView.layer.addSublayer(previewLayer)
    }
    
    func startCaptureSession() {
        DispatchQueue.main.async {
            self.previewLayer.frame = self.previewView.bounds
        }
        
        if !session.isRunning {
            DispatchQueue.global().async {
                self.session.startRunning()
            }
        }
    }

    func teardownAVCapture() {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
        
        session.beginConfiguration()
        
        captureConnection?.isEnabled = false
        if let deviceInput = self.deviceInput {
            session.removeInput(deviceInput)
        }
        
        session.removeOutput(videoDataOutput)
        
        session.commitConfiguration()
        
        if session.isRunning {
            DispatchQueue.global().async {
                self.session.stopRunning()
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("The capture output dropped a frame.")
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, Home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, Home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, Home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, Home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}
