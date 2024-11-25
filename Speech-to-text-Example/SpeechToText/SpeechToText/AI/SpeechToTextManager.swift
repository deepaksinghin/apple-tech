//
//  SpeechToTextManager.swift
//  SpeechToText
//
//  Created by Deepak Singh on 25/11/24.
//

import Speech
import AVFoundation
import Combine

/// Constants for speech recognition configuration
private enum SpeechConstants {
    static let silenceThresholdSeconds = 4.0
    static let audioBufferSize: UInt32 = 1024
    static let localeIdentifier = "en-US"
}

/// Manages speech-to-text conversion using Apple's Speech Framework
class SpeechToTextManager: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = SpeechToTextManager()
    
    // MARK: - Published Properties
    @Published private(set) var transcriptionState: TranscriptionState = .idle
    @Published private(set) var error: SpeechRecognitionError?
    @Published var volumeLevel: Float = 0.0
    
    // MARK: - Public Properties
    let transcriptionCompleted = PassthroughSubject<String, Never>()
    let recognitionStateChanged = PassthroughSubject<Bool, Never>()
    
    // MARK: - Private Properties
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var isRecognitionActive = Atomic<Bool>(false)
    
    private override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: SpeechConstants.localeIdentifier))
        super.init()
        configureRecognizer()
    }
}

// MARK: - Public Interface
extension SpeechToTextManager {
    enum TranscriptionState {
        case idle
        case recording(partialText: String?)
        case finished(finalText: String)
    }
    
    enum SpeechRecognitionError: LocalizedError {
        case permissionDenied
        case recognitionRestricted
        case recognitionNotAuthorized
        case audioEngineError
        case recognitionRequestCreationFailed
        case recognitionError(String)
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Speech recognition permission denied"
            case .recognitionRestricted:
                return "Speech recognition restricted on this device"
            case .recognitionNotAuthorized:
                return "Speech recognition not yet authorized"
            case .audioEngineError:
                return "Audio engine error occurred"
            case .recognitionRequestCreationFailed:
                return "Unable to create speech recognition request"
            case .recognitionError(let message):
                return message
            }
        }
    }
    
    /// Starts the speech recognition process
    func startRecognition() {
        guard !isRecognitionActive.value else {
            print("Speech recognition already active")
            return
        }
        isRecognitionActive.mutate { $0 = true }
        do {
            try setupAudioSession()
            try setupRecognitionRequest()
            try startAudioEngine()
            beginRecognitionTask()
            recognitionStateChanged.send(true)
        } catch {
            handleError(error)
        }
    }
    
    /// Stops the speech recognition process
    func stopRecognition(finalizeSession: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.cleanupRecognitionSession()
            self.isRecognitionActive.mutate { $0 = false }
            
            if finalizeSession {
                self.recognitionStateChanged.send(false)
            }
        }
    }
}

// MARK: - Private Setup Methods
private extension SpeechToTextManager {
   private func configureRecognizer() {
        speechRecognizer?.delegate = self
        requestRecognitionAuthorization()
    }
    
    private func requestRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.handleAuthorizationStatus(status)
            }
        }
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func setupRecognitionRequest() throws {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.recognitionRequestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        configureAudioInput(for: recognitionRequest)
    }
    
    private func configureAudioInput(for request: SFSpeechAudioBufferRecognitionRequest) {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0,
                             bufferSize: SpeechConstants.audioBufferSize,
                             format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate and update volume level
            let volume = self?.calculateVolume(buffer: buffer)
            DispatchQueue.main.async { [weak self] in
                self?.volumeLevel = volume ?? 0.0
            }
        }
    }
    
    private func startAudioEngine() throws {
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func calculateVolume(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = UInt(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<Int(frameLength) {
            let sample = channelData[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameLength)) // Root Mean Square
        return rms
    }
}

// MARK: - Recognition Task Handling
private extension SpeechToTextManager {
    func beginRecognitionTask() {
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            self?.handleRecognitionResult(result, error: error)
        }
    }
    
    func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            handleError(SpeechRecognitionError.recognitionError(error.localizedDescription))
            return
        }
        
        guard let result = result else { return }
        
        let transcription = result.bestTranscription.formattedString
        
        if result.isFinal {
            //handleFinalTranscription(transcription)
        } else {
            handlePartialTranscription(transcription)
        }
    }
    
    func handlePartialTranscription(_ text: String) {
        transcriptionState = .recording(partialText: text)
        resetSilenceTimer()
    }
    
    func handleFinalTranscription(_ text: String) {
        transcriptionState = .finished(finalText: text)
        transcriptionCompleted.send(text)
        stopRecognition()
    }
}

// MARK: - Error Handling
private extension SpeechToTextManager {
    func handleError(_ error: Error) {
        let recognitionError = error as? SpeechRecognitionError ?? .recognitionError(error.localizedDescription)
        self.error = recognitionError
        stopRecognition()
    }
    
    func handleAuthorizationStatus(_ status: SFSpeechRecognizerAuthorizationStatus) {
        switch status {
        case .authorized:
            print("Speech recognition authorised")
        case .denied:
            error = .permissionDenied
        case .restricted:
            error = .recognitionRestricted
        case .notDetermined:
            error = .recognitionNotAuthorized
        @unknown default:
            break
        }
    }
}

// MARK: - Silence Detection
private extension SpeechToTextManager {
    func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: SpeechConstants.silenceThresholdSeconds,
                                          repeats: false) { [weak self] _ in
            self?.finalizeSilentTranscription()
        }
    }
    
    func finalizeSilentTranscription() {
        if case .recording(let partialText) = transcriptionState,
           let text = partialText,
           !text.isEmpty {
            handleFinalTranscription(text)
        }
    }
    
    func cleanupRecognitionSession() {
        transcriptionState = .idle
        error = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechToTextManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle availability changes if needed
    }
}
