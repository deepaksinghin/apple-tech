# Speech-to-Text Example

This directory contains the SpeechToText library that utilizes Apple's Speech framework to recognize and transcribe spoken language in real-time.

## Features

- Real-time speech recognition.
- Silence detection for natural speech pauses.
- Volume level monitoring.

## Setup

### Requirements

- iOS 13.0+
- Xcode 11+
- Swift 5.3+

### Installation

No specific installation required. Simply open the `SpeechToText.xcodeproj` in Xcode and run the project.

## Usage

To use the SpeechToText library:

```swift
import SpeechToText

let speechManager = SpeechToTextManager.shared
speechManager.startRecognition()

// Handle transcribed text
speechManager.onTextTranscription = { text in
    print("Transcribed text: \(text)")
}
