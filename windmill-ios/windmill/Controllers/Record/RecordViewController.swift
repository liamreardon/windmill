//
//  RecordViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-06.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {

    @IBOutlet weak var camPreview: UIView!
    
    let cameraButton = UIView()

    let captureSession = AVCaptureSession()

    let movieOutput = AVCaptureMovieFileOutput()

    var previewLayer: AVCaptureVideoPreviewLayer!

    var activeInput: AVCaptureDeviceInput!

    var outputURL: URL!
    
    var screenHeight = UIScreen.main.bounds.size.height
    var screenWidth = UIScreen.main.bounds.size.width

    override func viewDidLoad() {
        super.viewDidLoad()

        if setupSession() {
            setupPreview()
            startSession()
        }
        
        initGraphics()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = camPreview.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        camPreview.layer.addSublayer(previewLayer)
    }

    //MARK:- Setup Camera

    func setupSession() -> Bool {

        captureSession.sessionPreset = AVCaptureSession.Preset.high

        // Setup Camera
        let camera = AVCaptureDevice.default(for: AVMediaType.video)!

        do {

            let input = try AVCaptureDeviceInput(device: camera)

            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }

        // Setup Microphone
        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!

        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }


        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }

        return true
    }

    func setupCaptureMode(_ mode: Int) {
        // Video Mode
    }

    //MARK:- Camera Session
    func startSession() {

        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }

    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }

    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }

    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation

        orientation = AVCaptureVideoOrientation.portrait

        return orientation
     }

    @objc func startCapture() {

        startRecording()

    }

    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString

        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let vc = segue.destination as! VideoEditViewController

        vc.videoURL = sender as? URL

    }

    func startRecording() {

        if movieOutput.isRecording == false {

            let connection = movieOutput.connection(with: AVMediaType.video)

            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = currentVideoOrientation()
            }

            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }

            let device = activeInput.device

            if (device.isSmoothAutoFocusSupported) {

                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                   print("Error setting configuration: \(error)")
                }

            }

            outputURL = tempURL()
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)

            }
            else {
                stopRecording()
            }

       }

   func stopRecording() {

       if movieOutput.isRecording == true {
           movieOutput.stopRecording()
        }
   }

    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {

    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        if (error != nil) {

            print("Error recording movie: \(error!.localizedDescription)")

        } else {

            let videoRecorded = outputURL! as URL

            performSegue(withIdentifier: "editVideo", sender: videoRecorded)

        }

    }
    
    // MARK: User Interface
    
    func setupRecordButton() {
        cameraButton.isUserInteractionEnabled = true

        let cameraButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(RecordViewController.startCapture))

        cameraButton.addGestureRecognizer(cameraButtonRecognizer)

        cameraButton.frame = CGRect(x: 50, y: screenHeight - 200, width: 100, height: 100)
        cameraButton.center.x = self.view.center.x

        cameraButton.backgroundColor = UIColor.red

        camPreview.addSubview(cameraButton)
    }
    
    func initGraphics() {
        setupRecordButton()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    

}
