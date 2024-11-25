
SpeechToText

The SpeechToTextManager class provides an efficient and easy-to-use implementation for converting spoken language into text using Apple’s Speech framework. This module is part of a broader set of utilities aimed at enhancing app capabilities with voice interactions.

Features

    •    Real-time Speech Recognition: Converts live audio into text as it’s spoken.
    •    Silence Detection: Automatically detects silence to finalize speech input, enhancing the start and stop of user interactions.
    •    Error Handling: Robust handling of common speech recognition errors.
    •    Volume Monitoring: Provides real-time feedback on the input audio volume, useful for visual volume indicators.

Installation

To incorporate the SpeechToTextManager into your project, clone the repo and integrate the relevant files into your project structure.

Usage

Starting the Speech Recognition

To start speech recognition, simply call the startRecognition() method on the shared instance of SpeechToTextManager.

SpeechToTextManager.shared.startRecognition()

Handling Transcription

You can observe changes in transcription state and handle the transcribed text as follows:

SpeechToTextManager.shared.$transcriptionState
    .sink { state in
        switch state {
        case .idle:
            print("Idle")
        case .recording(let partialText):
            print("Partial text: \(partialText)")
        case .finished(let finalText):
            print("Final text: \(finalText)")
        }
    }
    .store(in: &cancellables)

Stopping the Recognition

To stop the recognition process, use:

SpeechToTextManager.shared.stopRecognition()

Configuration

Modify SpeechConstants within SpeechToTextManager.swift to adjust the behavior of the speech recognition, such as buffer size and silence threshold.

Permissions

To use speech recognition features, you must include the following key in your Info.plist:
    •    Privacy - Speech Recognition Usage Description: This key explains to the user why your app requires access to speech recognition, which is necessary for iOS to allow access.

<key>NSSpeechRecognitionUsageDescription</key>
<string>This app requires access to speech recognition to process your voice commands.</string>

Ensure this key is included in your Info.plist to prevent app crashes and ensure compliance with App Store guidelines.

Contributions

Contributions are welcome! Please fork this repository and open a pull request to add more features, fix bugs, or propose improvements.

License

SpeechToText is released under the MIT license. See LICENSE for more information.
