//
//  ViewController.swift
//  Scissors-ios
//
//  Created by Timothy Perfitt on 4/4/24.
//

import UIKit
import UIKit
import AVFoundation

class ViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraImageView: UIImageView!

    var device: AVCaptureDevice?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCamera()
//        setupTimer()
    }

    func setupCamera() {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: AVMediaType.video,
                                                                position: .front)
        device = discoverySession.devices[0]

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device!)
        } catch {
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true

        let queue = DispatchQueue(label: "cameraQueue")
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: kCVPixelFormatType_32BGRA]

        captureSession = AVCaptureSession()
        captureSession?.addInput(input)
        captureSession?.addOutput(output)
        captureSession?.sessionPreset = AVCaptureSession.Preset.photo

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: view.frame.height)

        view.layer.insertSublayer(previewLayer!, at: 0)

        captureSession?.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = UnsafeMutableRawPointer(CVPixelBufferGetBaseAddress(imageBuffer!))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let width = CVPixelBufferGetWidth(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let newContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo:
                                    CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)

        let newImage = newContext!.makeImage()
        cameraImage = UIImage(cgImage: newImage!)

        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    }

    func setupTimer() {
        _ = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(snapshot), userInfo: nil, repeats: true)
    }

    @IBAction func snapButtonPressed(_ sender: Any) {
        snapshot()
    }
    @objc func snapshot() {
        print("SNAPSHOT")
        cameraImageView.image = cameraImage
    }
}


