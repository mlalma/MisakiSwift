import Foundation

/// Token representing a segmented Chinese word with POS tag and phoneme information
public struct ZHMToken {
    public var text: String
    public var tag: String
    public var whitespace: String
    public var phonemes: [String]

    public init(text: String = "", tag: String = "", whitespace: String = "", phonemes: [String] = []) {
        self.text = text
        self.tag = tag
        self.whitespace = whitespace
        self.phonemes = phonemes
    }
}
