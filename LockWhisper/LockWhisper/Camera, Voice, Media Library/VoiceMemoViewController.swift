import UIKit
import AVFoundation

class VoiceMemoViewController: UIViewController {
    
    // MARK: - Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    private var isRecording = false
    private var recordingURL: URL?
    private let mediaManager = MediaManager.shared
    private var recordingDuration: TimeInterval = 0
    private var timer: Timer?
    
    // MARK: - UI Elements
    
    private let recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
        button.tintColor = .systemRed
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00"
        label.textAlignment = .center
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .medium)
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tap to Record"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let controlsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 40
        return stackView
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.isEnabled = false
        button.isHidden = true
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "square.and.arrow.down.fill"), for: .normal)
        button.tintColor = .systemGreen
        button.isEnabled = false
        button.isHidden = true
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        button.tintColor = .systemRed
        button.isEnabled = false
        button.isHidden = true
        return button
    }()
    
    private let waveformView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Voice Memo"
        view.backgroundColor = .systemBackground
        setupAudioSession()
        setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isRecording {
            stopRecording()
        }
        audioPlayer?.stop()
    }
    
    // MARK: - Setup Methods
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
            
            recordingSession?.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        self?.showPermissionAlert()
                    }
                }
            }
        } catch {
            print("Recording setup failed: \(error)")
        }
    }
    
    private func setupUI() {
        let safeArea = view.safeAreaLayoutGuide
        
        // Add views
        view.addSubview(recordButton)
        view.addSubview(timeLabel)
        view.addSubview(statusLabel)
        view.addSubview(waveformView)
        view.addSubview(controlsStackView)
        
        // Add controls to stack view
        controlsStackView.addArrangedSubview(playButton)
        controlsStackView.addArrangedSubview(saveButton)
        controlsStackView.addArrangedSubview(deleteButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            waveformView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            waveformView.heightAnchor.constraint(equalToConstant: 120),
            
            timeLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 40),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            recordButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80),
            
            controlsStackView.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 40),
            controlsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            playButton.widthAnchor.constraint(equalToConstant: 60),
            playButton.heightAnchor.constraint(equalToConstant: 60),
            
            saveButton.widthAnchor.constraint(equalToConstant: 60),
            saveButton.heightAnchor.constraint(equalToConstant: 60),
            
            deleteButton.widthAnchor.constraint(equalToConstant: 60),
            deleteButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Add targets to buttons
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Microphone Access Required",
            message: "Please allow microphone access in Settings to use voice memo feature",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Recording Methods
    
    private func startRecording() {
        // Create a temporary URL for recording
        let tempDir = FileManager.default.temporaryDirectory
        let filename = UUID().uuidString + ".m4a"
        let url = tempDir.appendingPathComponent(filename)
        recordingURL = url
        
        // Set up the recorder
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingDuration = 0
            startTimer()
            
            // Update UI for recording state
            UIView.animate(withDuration: 0.3) {
                self.recordButton.tintColor = .systemRed
                self.recordButton.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
                self.statusLabel.text = "Recording..."
                
                // Hide control buttons during recording
                self.playButton.isHidden = true
                self.saveButton.isHidden = true
                self.deleteButton.isHidden = true
            }
            
            startWaveformAnimation()
        } catch {
            print("Failed to start recording: \(error)")
            showAlert(title: "Error", message: "Failed to start recording")
        }
    }
    
    private func stopRecording() {
        // Stop recording
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        stopTimer()
        
        // Update UI for stopped state
        UIView.animate(withDuration: 0.3) {
            self.recordButton.tintColor = .systemBlue
            self.recordButton.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
            self.statusLabel.text = "Recording Stopped"
            
            // Show control buttons
            self.playButton.isHidden = false
            self.saveButton.isHidden = false
            self.deleteButton.isHidden = false
            self.playButton.isEnabled = true
            self.saveButton.isEnabled = true
            self.deleteButton.isEnabled = true
        }
        
        stopWaveformAnimation()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 1
            self.updateTimeLabel()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimeLabel() {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startWaveformAnimation() {
        // Add simple waveform animation
        waveformView.subviews.forEach { $0.removeFromSuperview() }
        
        for i in 0..<30 {
            let bar = UIView()
            bar.backgroundColor = .systemBlue
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.layer.cornerRadius = 2
            
            waveformView.addSubview(bar)
            
            let barWidth: CGFloat = 5
            let spacing: CGFloat = 3
            let totalWidth = waveformView.bounds.width - 20
            let availableWidth = totalWidth - (CGFloat(30) * spacing)
            let maxBarHeight = waveformView.bounds.height - 20
            
            let x = 10 + CGFloat(i) * (barWidth + spacing)
            
            NSLayoutConstraint.activate([
                bar.bottomAnchor.constraint(equalTo: waveformView.centerYAnchor, constant: 20),
                bar.leadingAnchor.constraint(equalTo: waveformView.leadingAnchor, constant: x),
                bar.widthAnchor.constraint(equalToConstant: barWidth)
            ])
            
            // Create random height animation
            let heightConstraint = bar.heightAnchor.constraint(equalToConstant: 10)
            heightConstraint.isActive = true
            
            // Animate continuously
            UIView.animate(withDuration: 0.5, delay: Double.random(in: 0...0.5), options: [.repeat, .autoreverse], animations: {
                heightConstraint.constant = CGFloat.random(in: 10...maxBarHeight/2)
                self.waveformView.layoutIfNeeded()
            })
        }
    }
    
    private func stopWaveformAnimation() {
        waveformView.subviews.forEach { bar in
            bar.layer.removeAllAnimations()
        }
    }
    
    // MARK: - Playback Methods
    
    private func playRecording() {
        guard let url = recordingURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            // Update UI for playback
            playButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            statusLabel.text = "Playing..."
        } catch {
            print("Failed to play recording: \(error)")
            showAlert(title: "Error", message: "Failed to play recording")
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Update UI
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        statusLabel.text = "Ready"
    }
    
    // MARK: - Saving Methods
    
    private func saveRecording() {
        guard let url = recordingURL else {
            showAlert(title: "Error", message: "No recording to save")
            return
        }
        
        do {
            let audioData = try Data(contentsOf: url)
            
            // Use MediaManager to save encrypted audio
            let (encryptedData, success) = mediaManager.encryptData(audioData)
            
            if success {
                // Save to app's media library
                guard let mediaDirectory = mediaManager.mediaDirectoryURL else {
                    showAlert(title: "Error", message: "Failed to access media directory")
                    return
                }
                
                let filename = "voiceMemo_\(Date().timeIntervalSince1970)_\(UUID().uuidString).enc"
                let fileURL = mediaDirectory.appendingPathComponent(filename)
                
                try encryptedData.write(to: fileURL)
                
                showAlert(title: "Success", message: "Voice memo saved successfully")
                
                // Reset UI after saving
                resetUI()
            } else {
                showAlert(title: "Error", message: "Failed to encrypt recording")
            }
        } catch {
            print("Failed to save recording: \(error)")
            showAlert(title: "Error", message: "Failed to save recording")
        }
    }
    
    private func resetUI() {
        // Reset recording state
        recordingURL = nil
        recordingDuration = 0
        timeLabel.text = "00:00"
        statusLabel.text = "Tap to Record"
        
        // Hide control buttons
        playButton.isHidden = true
        saveButton.isHidden = true
        deleteButton.isHidden = true
        playButton.isEnabled = false
        saveButton.isEnabled = false
        deleteButton.isEnabled = false
        
        // Reset record button
        recordButton.tintColor = .systemRed
        recordButton.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
        
        // Clear waveform
        waveformView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    // MARK: - Actions
    
    @objc private func recordButtonTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @objc private func playButtonTapped() {
        if audioPlayer?.isPlaying == true {
            stopPlayback()
        } else {
            playRecording()
        }
    }
    
    @objc private func saveButtonTapped() {
        saveRecording()
    }
    
    @objc private func deleteButtonTapped() {
        // Confirm deletion
        let alert = UIAlertController(
            title: "Delete Recording",
            message: "Are you sure you want to delete this recording?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.resetUI()
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceMemoViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            showAlert(title: "Recording Failed", message: "Something went wrong with the recording")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceMemoViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        statusLabel.text = "Ready"
    }
}