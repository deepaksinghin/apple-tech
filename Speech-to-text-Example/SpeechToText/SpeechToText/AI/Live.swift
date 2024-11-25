//
//  Live.swift
//  SpeechToText
//
//  Created by Deepak Singh on 25/11/24.
//

import Foundation
import Combine
import UIKit

// MARK: - Constants
private enum SullyConstants {
    static let apiWaitTime = 3.0
    static let defaultSystemMessage = "Speech framework Demo, Test Response"
}

enum ListeningState {
    case active
    case processing
    case inactive
    case error(SullyError)
}

enum SullyError: LocalizedError {
    case speechRecognitionError(Error)
    case transcriptionFailed
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .speechRecognitionError(let error):
            return "Speech recognition error: \(error.localizedDescription)"
        case .transcriptionFailed:
            return "Failed to process speech transcription"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

/// Manages the live interaction between speech recognition and chat functionality
class Live: ObservableObject {
    // MARK: - Singleton
    static let shared = Live()
    
    // MARK: - Published Properties
    @Published private(set) var conversations: [ChatModel] = []
    @Published private(set) var currentTranscription: String?
    @Published private(set) var currentError: SullyError?
    @Published private(set) var listeningState: ListeningState = .inactive
    
    // MARK: - Public Properties
    let listeningStateChanged = PassthroughSubject<ListeningState, Never>()
    
    // MARK: - Private Properties
    private var subscriptions = Set<AnyCancellable>()
    private let speechManager = SpeechToTextManager.shared
    
    // MARK: - Initialisation
    private init() {
        setupSubscriptions()
    }
    
    deinit {
        print("SullyLive reinitialised")
    }
}

// MARK: - Public Interface
extension Live {
    /// Starts the live interaction session
    func startSession() {
        speechManager.startRecognition()
        updateListeningState(.active)
        print("\n---Started:\(Data())\nStarted listening session")
    }
    
    /// Stops the live interaction session
    func endSession() {
        speechManager.stopRecognition(finalizeSession: true)
        resetState()
        updateListeningState(.inactive)
    }
}

// MARK: - Private Methods
private extension Live {
    private func setupSubscriptions() {
        // Transcription updates
        speechManager.$transcriptionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleTranscriptionState(state)
            }
            .store(in: &subscriptions)
        
        // Error handling
        speechManager.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.handleError(.speechRecognitionError(error))
            }
            .store(in: &subscriptions)
        
        // Recognition state changes
        speechManager.recognitionStateChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.updateListeningState(isActive ? .active : .inactive)
            }
            .store(in: &subscriptions)
        
        // Completed transcriptions
        speechManager.transcriptionCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                Task { [weak self] in
                    print("Final transcription:\(text)")
                    await self?.processTranscription(text)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func handleTranscriptionState(_ state: SpeechToTextManager.TranscriptionState) {
        switch state {
        case .idle:
            currentTranscription = nil
        case .recording(let partialText):
            currentTranscription = partialText
        case .finished(let finalText):
            currentTranscription = finalText
        }
    }
    
    private func updateListeningState(_ newState: ListeningState) {
        listeningState = newState
        listeningStateChanged.send(newState)
    }
    
    private func resetState() {
        currentTranscription = nil
        currentError = nil
    }
    
    private func handleError(_ error: SullyError) {
        currentError = error
        updateListeningState(.error(error))
    }
    
    func waitForSeconds(_ seconds: Double) async  {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}

// MARK: - API Handling
extension Live {
    func processTranscription(_ text: String) async {
        guard !text.isEmpty else {
            updateListeningState(.active)
            return
        }
        
        updateListeningState(.processing)
        addMessage(text, type: .user)
        
        do {
            // Simulate API call
            await self.waitForSeconds(SullyConstants.apiWaitTime)
            try await processResponse()
        } catch {
            handleError(.apiError(error.localizedDescription))
        }
    }
    
    private func processResponse() async throws {
        updateListeningState(.active)
        startSession()
        addMessage(SullyConstants.defaultSystemMessage, type: .system)
    }
    
    private func addMessage(_ text: String, type: ChatType) {
        let message = ChatModel(type: type, message: text)
        conversations.append(message)
    }
    
    
}
