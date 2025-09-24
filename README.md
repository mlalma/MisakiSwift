# MisakiSwift

A Swift port of the [Misaki](https://github.com/hexgrad/misaki) grapheme-to-phoneme (G2P) library for converting English text to phonetic representations suitable for text-to-speech (TTS) engines.

## Supported Platforms

- iOS 18.0+
- macOS 15.0+
- (Other Apple platforms may work as well)

## Installation

Add MisakiSwift to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/mlalma/MisakiSwift", from: "1.0.0")
]
```

## Basic Usage

```swift
import MisakiSwift

// Create G2P converter (british = false for American English)
let g2p = EnglishG2P(british: false)

// Convert text to phonemes
let (phonemes, tokens) = g2p.phonemize(text: "Hello world!")
print(phonemes) // "həlˈO wˈɜɹld!"
```

## Custom Phoneme Override

Use Markdown-like syntax to specify exact pronunciations in case you don't want to use fallback network:

```swift
let g2p = EnglishG2P(british: false)
let text = "[Misaki](/misˈɑki/) is a G2P engine designed for [Kokoro](/kˈOkəɹO/) models."
let (phonemes, _) = g2p.phonemize(text: text)
// "misˈɑki ɪz ɐ ʤˈitəpˈi ˈɛnʤən dəzˈInd fɔɹ kˈOkəɹO mˈɑdᵊlz."
```
## For XCode UI users


If you want to experiment with this in Xcode, the following steps should save you some time.
- Upgrade to Xcode 26 (Swift 6.2), I had a lot of problems with dependencies until I did that. Just go to the AppStore on your Mac and "update" your Xcode.
- Open Xcode and: CREATE a "New Project", NEXT, Misaki (for Project Name), CREATE 
- Go to FILE / Add Packge Dependencies. Click on GitHub and paste this into the search-box: https://github.com/mlalma/MisakiSwift.git
- It should display details about the MisakiSwift package. Click Add Package, and Add Package on the next screen.
- There should now be 3 package dependencies listed in the left column. (MisakiSwift, mlx-swift, swift-numerics)
- Click on the Project icon (top icon in the left column). The "General Tab" should be selected in the main screen area.
- Scroll down about 2/3 on the main screen to: "Frameworks, Libraries, and Embedded Content". Change "Embed" to "Embed and Sign".
- In the left column, double-click on the "ContentView" file, it will open in the main window.

Replace the content of "ContentView" with the following
```swift
//
//  ContentView.swift
//  MisakiSwift
//
//  Created by Michael J. Ellis on 9/24/25.
//

import SwiftUI
import MisakiSwift

struct ContentView: View {
    @State private var inputText: String = "Hello Strange Olde World"
    @State private var phonemes: String = ""
    
    // Create G2P converter (british = false for American English)
    private let g2p = EnglishG2P(british: false)
    
    private func convertToPhoneme() {
        // The phonemize function returns a tuple: (phonemes, tokens)
        // We'll just use the phonemes string for display.
        let (phonemesResult, _) = g2p.phonemize(text: inputText)
        self.phonemes = phonemesResult
    }
    
    var body: some View {
        VStack {
            Text("Grapheme to Phoneme Converter")
                .font(.title)
            
            TextField("Enter text", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .padding(.top)
                .onSubmit {
                    convertToPhoneme()
                }
            
            Button("Convert to Phoneme") {
                convertToPhoneme()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            Text(phonemes)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

- COMMAND S to SAVE
- COMMAND R to RUN
- App should build and run.



## Overview

MisakiSwift is a high-quality English G2P conversion library that transforms written text into phonemes using both dictionary-based lookup and neural network fallback. It supports British and American English pronunciations and includes advanced features like stress pattern handling and custom phoneme overrides.

## Key Features

- **High Accuracy**: Combines extensive pronunciation dictionaries with neural network fallback for out-of-vocabulary words
- **Dual Dialect Support**: Supports both British and American English pronunciations
- **Advanced Text Processing**: Handles punctuation, numbers, acronyms, and complex formatting
- **Custom Phoneme Override**: Use Markdown-like syntax to specify exact pronunciations: `[word](/phonemes/)`
- **Stress Pattern Control**: Automatic stress assignment with manual override capabilities
- **Apple Ecosystem Integration**: Uses Apple's Natural Language framework instead of external dependencies like SpaCy

## Architecture

MisakiSwift consists of several key components:

- **`EnglishG2P`**: Main conversion pipeline that orchestrates tokenization, lexicon lookup, and neural network fallback
- **`Lexicon`**: Dictionary-based pronunciation lookup using gold and silver dictionaries
- **`EnglishFallbackNetwork`**: Transformer-based model (ported to run on MLX) for phoneme prediction for out-of-vocabulary words

### Key Differences from Python Misaki

1. **POS Tagging**: Uses Apple's `NaturalLanguage` framework instead of SpaCy for part-of-speech tagging
2. **Neural Network**: The BART-based fallback network is ported to run on [MLX](https://github.com/ml-explore/mlx)
3. **Resource Management**: All model weights and dictionaries are bundled as resources within the Swift package

## Dependencies

- **[MLX](https://github.com/ml-explore/mlx)**: Machine learning framework for the neural network component
- **NaturalLanguage**: Apple's built-in framework for text processing and POS tagging

## Model Resources

The package includes pre-trained models and dictionaries:

- **BART Model Weights**: Neural network weights for phoneme prediction (US and GB variants)
- **Gold Dictionary**: High-confidence pronunciation mappings
- **Silver Dictionary**: Additional pronunciation mappings with slightly lower confidence

These resources are automatically bundled with the package and loaded at runtime.

