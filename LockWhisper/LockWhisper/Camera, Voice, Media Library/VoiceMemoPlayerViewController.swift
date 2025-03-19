import UIKit
import AVFoundation

class VoiceMemoPlayerViewController: UIViewController {
    
    // MARK: - Properties
    
    var memoURL: URL?
    private var audioPlayer: AVAudioPlayer?
    private let mediaManager = MediaManager.shared
    private var timer: Timer?
    private var isPlaying = false
    
    // MARK: - UI Elements
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00 / 00:00"
        label.textAlignment = .center
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        return label
    }()
    
    private let progressSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .systemGray4
        slider.thumbTintColor = .systemBlue
        slider.value = 0
        return slider
    }()
    
    private let waveformView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Voice Memo"
        view.backgroundColor = .systemBackground
        setupUI()
        loadMemo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayback()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        let safeArea = view.safeAreaLayoutGuide
        
        // Add views
        view.addSubview(waveformView)
        view.addSubview(timeLabel)
        view.addSubview(progressSlider)
        view.addSubview(playButton)
        view.addSubview(dateLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            waveformView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            waveformView.heightAnchor.constraint(equalToConstant: 120),
            
            dateLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 20),
            dateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 40),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            progressSlider.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20),
            progressSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            playButton.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 40),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 80),
            playButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Add targets
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderTouchUp), for: [.touchUpInside, .touchUpOutside])
    }
    
    private func setupWaveform() {
        // Add a decorative waveform (not responsive to audio)
        waveformView.subviews.forEach { $0.removeFromSuperview() }
        
        for i in 0..<30 {
            let bar = UIView()
            bar.backgroundColor = .systemBlue
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.layer.cornerRadius = 2
            
            waveformView.addSubview(bar)
            
            let barWidth: CGFloat = 5
            let spacing: CGFloat = 3
            let maxBarHeight = waveformView.bounds.height - 20
            let height = CGFloat.random(in: 10...maxBarHeight)
            
            let x = 10 + CGFloat(i) * (barWidth + spacing)
            
            NSLayoutConstraint.activate([
                bar.bottomAnchor.constraint(equalTo: waveformView.centerYAnchor, constant: maxBarHeight/2),
                bar.leadingAnchor.constraint(equalTo: waveformView.leadingAnchor, constant: x),
                bar.widthAnchor.constraint(equalToConstant: barWidth),
                bar.heightAnchor.constraint(equalToConstant: height)
            ])
        }
    }
    
    // MARK: - Audio Methods
    
    private func loadMemo() {
        guard let url = memoURL else {
            dismiss(animated: true)
            return
        }
        
        // Show creation date from filename
        if let timestamp = extractTimestampFromFilename(url: url) {
            let date = Date(timeIntervalSince1970: timestamp)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            dateLabel.text = formatter.string(from: date)
        } else {
            dateLabel.text = "Unknown Date"
        }
        
        // Load and decrypt the audio
        mediaManager.loadAudio(from: url) { [weak self] tempURL in
            guard let self = self, let tempURL = tempURL else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to load voice memo")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.setupAudioPlayer(with: tempURL)
                self.setupWaveform()
            }
        }
    }
    
    private func extractTimestampFromFilename(url: URL) -> TimeInterval? {
        let filename = url.lastPathComponent
        let parts = filename.split(separator: "_")
        
        if parts.count >= 2 {
            // Use the entire second part (index 1) as the timestamp string
            if let timestamp = Double(parts[1]) {
                return timestamp
            }
        }
        
        return nil
    }
    
    private func setupAudioPlayer(with url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            // Update UI
            updateTimeLabel()
        } catch {
            print("Failed to set up audio player: \(error)")
            showAlert(title: "Error", message: "Failed to prepare audio for playback")
        }
    }
    
    private func startPlayback() {
        guard let player = audioPlayer else { return }
        
        player.play()
        isPlaying = true
        
        // Start timer for UI updates
        startTimer()
        
        // Update UI
        playButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
    }
    
    private func stopPlayback() {
        guard let player = audioPlayer else { return }
        
        player.pause()
        isPlaying = false
        
        // Stop timer
        stopTimer()
        
        // Update UI
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackProgress()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        
        // Update slider
        let progress = Float(player.currentTime / player.duration)
        progressSlider.value = progress
        
        // Update time label
        updateTimeLabel()
    }
    
    private func updateTimeLabel() {
        guard let player = audioPlayer else {
            timeLabel.text = "00:00 / 00:00"
            return
        }
        
        let currentTime = formatTime(player.currentTime)
        let duration = formatTime(player.duration)
        timeLabel.text = "\(currentTime) / \(duration)"
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    
    @objc private func playButtonTapped() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    @objc private func sliderValueChanged() {
        // Update time label while dragging
        guard let player = audioPlayer else { return }
        
        let time = TimeInterval(progressSlider.value * Float(player.duration))
        let currentTime = formatTime(time)
        let duration = formatTime(player.duration)
        timeLabel.text = "\(currentTime) / \(duration)"
    }
    
    @objc private func sliderTouchUp() {
        // Set playback position when slider is released
        guard let player = audioPlayer else { return }
        
        let time = TimeInterval(progressSlider.value * Float(player.duration))
        player.currentTime = time
        
        // If it was playing, continue playing
        if isPlaying {
            player.play()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceMemoPlayerViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTimer()
        
        // Reset UI
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        progressSlider.value = 0
        updateTimeLabel()
    }
}