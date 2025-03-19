import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var isRecording = false
    private var currentMode: CaptureMode = .photo
    private let mediaManager = MediaManager.shared
    
    enum CaptureMode {
        case photo
        case video
    }
    
    // MARK: - UI Elements
    
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()
    
    private let switchModeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Photo", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let libraryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "mediaLibrary")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Camera"
        view.backgroundColor = .black
        setupUI()
        checkCameraPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCaptureSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCaptureSession()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.addSubview(previewView)
        view.addSubview(captureButton)
        view.addSubview(switchModeButton)
        view.addSubview(libraryButton)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 15),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            switchModeButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            switchModeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            switchModeButton.widthAnchor.constraint(equalToConstant: 80),
            switchModeButton.heightAnchor.constraint(equalToConstant: 40),
            
            libraryButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            libraryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            libraryButton.widthAnchor.constraint(equalToConstant: 40),
            libraryButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        switchModeButton.addTarget(self, action: #selector(switchModeTapped), for: .touchUpInside)
        libraryButton.addTarget(self, action: #selector(libraryButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Camera Setup
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCaptureSession()
                    }
                }
            }
        case .denied, .restricted:
            let alert = UIAlertController(
                title: "Camera Access Required",
                message: "Please allow camera access in Settings to use this feature",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let captureSession = captureSession else { return }
        
        // Get the back camera
        guard let camera = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Setup photo output
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            // Setup video output
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            // Setup preview layer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.frame = previewView.bounds
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let previewLayer = self.videoPreviewLayer {
                    self.previewView.layer.addSublayer(previewLayer)
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
        }
    }
    
    private func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    // MARK: - Actions
    
    @objc private func captureButtonTapped() {
        switch currentMode {
        case .photo:
            capturePhoto()
        case .video:
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }
    }
    
    @objc private func switchModeTapped() {
        currentMode = currentMode == .photo ? .video : .photo
        
        // Update UI based on mode
        UIView.animate(withDuration: 0.3) {
            self.switchModeButton.setTitle(self.currentMode == .photo ? "Photo" : "Video", for: .normal)
            self.captureButton.backgroundColor = self.currentMode == .photo ? .white : .red
        }
    }
    
    @objc private func libraryButtonTapped() {
        let mediaLibraryVC = MediaLibraryViewController()
        navigationController?.pushViewController(mediaLibraryVC, animated: true)
    }
    
    // MARK: - Capture Methods
    
    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func startRecording() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        
        // Create temporary URL for the video
        let tempDir = FileManager.default.temporaryDirectory
        let videoFilename = UUID().uuidString + ".mov"
        let videoURL = tempDir.appendingPathComponent(videoFilename)
        
        // Start recording
        videoOutput.startRecording(to: videoURL, recordingDelegate: self)
        
        // Update UI to show recording state
        isRecording = true
        UIView.animate(withDuration: 0.3) {
            self.captureButton.backgroundColor = .red
            self.captureButton.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    private func stopRecording() {
        if videoOutput.isRecording {
            videoOutput.stopRecording()
        }
        
        // Update UI to show stopped state
        isRecording = false
        UIView.animate(withDuration: 0.3) {
            self.captureButton.backgroundColor = .white
            self.captureButton.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
    
    // MARK: - Save to Library
    
    private func savePhotoToLibrary(image: UIImage) {
        // Use MediaManager to save encrypted photo
        mediaManager.savePhoto(image) { [weak self] success, fileURL in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    self.showAlert(title: "Success", message: "Encrypted photo saved to media library")
                } else {
                    self.showAlert(title: "Error", message: "Failed to save encrypted photo")
                }
            }
        }
    }
    
    private func saveVideoToLibrary(videoURL: URL) {
        // Use MediaManager to save encrypted video
        mediaManager.saveVideo(from: videoURL) { [weak self] success, fileURL in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    self.showAlert(title: "Success", message: "Encrypted video saved to media library")
                } else {
                    self.showAlert(title: "Error", message: "Failed to save encrypted video")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Save to app's media library
        savePhotoToLibrary(image: image)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
            return
        }
        
        // Save to app's media library
        saveVideoToLibrary(videoURL: outputFileURL)
    }
}
