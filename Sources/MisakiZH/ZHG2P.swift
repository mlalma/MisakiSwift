import Foundation
import MisakiSwift
import MLXUtilsLibrary

/// Errors for ZHG2P initialization
public enum ZHG2PError: Error, LocalizedError {
    case dictionaryNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .dictionaryNotFound(let msg): return msg
        }
    }
}

/// Chinese Grapheme-to-Phoneme: converts Chinese text to IPA phonemes.
public final class ZHG2P {

    // MARK: - Data Tables

    private static let initialMapping: [String: [String]] = [
        "b": ["p"], "c": ["ʦʰ"], "ch": ["ʈʂʰ"], "d": ["t"],
        "f": ["f"], "g": ["k"], "h": ["x"], "j": ["ʨ"],
        "k": ["kʰ"], "l": ["l"], "m": ["m"], "n": ["n"],
        "p": ["pʰ"], "q": ["ʨʰ"], "r": ["ɻ"], "s": ["s"],
        "sh": ["ʂ"], "t": ["tʰ"], "x": ["ɕ"], "z": ["ʦ"],
        "zh": ["ʈʂ"]
    ]

    private static let finalMapping: [String: [String]] = [
        "a": ["a0"], "ai": ["ai̯0"], "an": ["a0", "n"], "ang": ["a0", "ŋ"],
        "ao": ["au̯0"], "e": ["ɤ0"], "ei": ["ei̯0"], "en": ["ə0", "n"],
        "eng": ["ə0", "ŋ"], "er": ["ɚ0"], "i": ["i0"], "ia": ["j", "a0"],
        "ian": ["j", "ɛ0", "n"], "iang": ["j", "a0", "ŋ"], "iao": ["j", "au̯0"],
        "ie": ["j", "e0"], "in": ["i0", "n"], "ing": ["i0", "ŋ"],
        "iong": ["j", "ʊ0", "ŋ"], "iou": ["j", "ou̯0"], "ong": ["ʊ0", "ŋ"],
        "ou": ["ou̯0"], "o": ["o0"], "u": ["u0"], "ua": ["w", "a0"],
        "uai": ["w", "ai̯0"], "uan": ["w", "a0", "n"], "uang": ["w", "a0", "ŋ"],
        "ui": ["w", "ei̯0"], "un": ["w", "ə0", "n"], "ueng": ["w", "ə0", "ŋ"],
        "uo": ["w", "o0"], "ue": ["ɥ", "e0"], "uen": ["w", "ə0", "n"], "uei": ["w", "ei̯0"],
        "ü": ["y0"], "üe": ["ɥ", "e0"], "üan": ["ɥ", "ɛ0", "n"], "ün": ["y0", "n"],
        "van": ["ɥ", "ɛ0", "n"], "vn": ["y0", "n"], "ve": ["ɥ", "e0"], "v": ["y0"],
        "ii": ["ɹ̩0"],
        "iii": ["ɻ̩0"]
    ]

    private static let finalMappingZhChShR: [String: [String]] = [
        "i": ["ɻ̩0"]
    ]

    private static let finalMappingZCS: [String: [String]] = [
        "i": ["ɹ̩0"]
    ]

    private static let toneMapping: [Int: String] = [
        1: "˥", 2: "˧˥", 3: "˧˩˧", 4: "˥˩", 5: ""
    ]

    private static let toneVowels: [String: (base: String, tone: Int)] = [
        "ā": ("a", 1), "á": ("a", 2), "ǎ": ("a", 3), "à": ("a", 4),
        "ē": ("e", 1), "é": ("e", 2), "ě": ("e", 3), "è": ("e", 4),
        "ī": ("i", 1), "í": ("i", 2), "ǐ": ("i", 3), "ì": ("i", 4),
        "ō": ("o", 1), "ó": ("o", 2), "ǒ": ("o", 3), "ò": ("o", 4),
        "ū": ("u", 1), "ú": ("u", 2), "ǔ": ("u", 3), "ù": ("u", 4),
        "ǖ": ("v", 1), "ǘ": ("v", 2), "ǚ": ("v", 3), "ǜ": ("v", 4),
        "ń": ("n", 2), "ň": ("n", 3), "ǹ": ("n", 4),
        "ḿ": ("m", 2), "m̀": ("m", 4)
    ]

    private static let letterToIPA: [Character: String] = [
        "A": "ei̯", "B": "pi", "C": "si", "D": "ti", "E": "i",
        "F": "ef", "G": "tʂi", "H": "ei̯tʂ", "I": "ai̯", "J": "tʂei̯",
        "K": "kʰei̯", "L": "el", "M": "em", "N": "en", "O": "ou̯",
        "P": "pʰi", "Q": "kʰju", "R": "aɻ", "S": "es", "T": "tʰi",
        "U": "ju", "V": "vi", "W": "tʌplju", "X": "eks", "Y": "wai̯",
        "Z": "zi",
        "a": "ei̯", "b": "pi", "c": "si", "d": "ti", "e": "i",
        "f": "ef", "g": "tʂi", "h": "ei̯tʂ", "i": "ai̯", "j": "tʂei̯",
        "k": "kʰei̯", "l": "el", "m": "em", "n": "en", "o": "ou̯",
        "p": "pʰi", "q": "kʰju", "r": "aɻ", "s": "es", "t": "tʰi",
        "u": "ju", "v": "vi", "w": "tʌplju", "x": "eks", "y": "wai̯",
        "z": "zi"
    ]

    // MARK: - Instance

    private let version: String
    private let unk: String
    private let pinyinFinder: PinyinFinder
    private let jieba: JiebaWrapper
    private var frontend: ZHFrontend?
    private var engG2P: EnglishG2P?

    /// Convenience initializer that loads dictionaries from this module's resource bundle.
    /// Use this for iOS apps where resources are bundled.
    /// - Parameters:
    ///   - version: Version string (use "1.1" for frontend mode)
    ///   - unk: Unknown token marker
    public convenience init(version: String = "1.1", unk: String = "<unk>") throws {
        let bundle = Bundle.module
        guard let dictURL = bundle.url(forResource: "dict", withExtension: nil) else {
            throw ZHG2PError.dictionaryNotFound("dict directory not found in bundle")
        }
        try self.init(dictDir: dictURL.path, version: version, unk: unk)
    }

    /// Initialize ZHG2P
    /// - Parameters:
    ///   - dictDir: Path to dictionary directory containing jieba dicts, pinyin files, etc.
    ///   - version: Version string (use "1.1" for frontend mode)
    ///   - unk: Unknown token marker
    public init(dictDir: String, version: String = "1.1", unk: String = "<unk>") throws {
        self.version = version
        self.unk = unk

        let dir = dictDir.hasSuffix("/") ? dictDir : dictDir + "/"

        // Initialize Jieba
        jieba = try JiebaWrapper(
            dictPath: dir + "jieba.dict.utf8",
            hmmModelPath: dir + "hmm_model.utf8",
            userDictPath: dir + "user.dict.utf8",
            idfPath: dir + "idf.utf8",
            stopWordPath: dir + "stop_words.utf8"
        )

        // Initialize PinyinFinder
        pinyinFinder = PinyinFinder()
        let pinyinOK = pinyinFinder.loadDictionaries(
            singleCharPath: dir + "pinyin.txt",
            phrasePath: dir + "pinyin_phrase.txt"
        )
        if !pinyinOK {
            print("[WARN] PinyinFinder initialization failed")
        }

        // Initialize frontend
        if version == "1.1" {
            frontend = ZHFrontend(jieba: jieba, pinyinFinder: pinyinFinder, unk: unk)
        }

        // Initialize English G2P
        engG2P = EnglishG2P()
    }

    // MARK: - Public API

    /// Convert text to IPA phonemes
    /// - Returns: Tuple of (IPA string, MToken array for timestamp prediction)
    public func phonemize(_ text: String) -> (String, [MToken]) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return ("", []) }

        var processedText = StringUtils.convertNumbers(text)
        processedText = Self.mapPunctuation(processedText)

        if let frontend = frontend {
            let zhTokens = frontend.process(processedText)
            var result = ""
            var mTokens: [MToken] = []
            var lastWasEng = false

            for tk in zhTokens {
                let isEng = (tk.tag == "eng")

                // Space before English word
                if isEng && !result.isEmpty && result.last != " " {
                    result += " "
                }
                // Space after English word before non-punct
                if lastWasEng && !isEng && tk.tag != "x" && !result.isEmpty && result.last != " " {
                    result += " "
                }

                // Track whether this token adds content to result
                let resultLenBefore = result.count
                var tokenPhonemes = ""

                if tk.tag == "x" || tk.tag == "eng" {
                    for p in tk.phonemes {
                        var convertedPart = ""
                        if let eng = engG2P, tk.tag == "eng" {
                            let (phoneme, _) = eng.phonemize(text: p, performPreprocess: false)
                            convertedPart = phoneme
                        }

                        // Fallback for English: letter-by-letter IPA
                        if (convertedPart.isEmpty || convertedPart == p) && tk.tag == "eng" {
                            let allAlpha = p.allSatisfy { $0.isLetter }
                            if allAlpha {
                                convertedPart = ""
                                for c in p {
                                    if let ipa = Self.letterToIPA[c] {
                                        convertedPart += ipa
                                    } else {
                                        convertedPart.append(c)
                                    }
                                }
                            } else {
                                convertedPart = p
                            }
                        } else if convertedPart.isEmpty {
                            convertedPart = p
                        }
                        result += convertedPart
                        tokenPhonemes += convertedPart
                    }
                } else {
                    // Chinese: split phonemes into pinyin syllables
                    var pinyinAcc = ""
                    for p in tk.phonemes {
                        pinyinAcc += p
                        let hasDigit = p.contains(where: { $0.isNumber })
                        if hasDigit {
                            let ipa = Self.py2ipa(pinyinAcc)
                            result += ipa
                            tokenPhonemes += ipa
                            pinyinAcc = ""
                        }
                    }
                    if !pinyinAcc.isEmpty {
                        let ipa = Self.py2ipa(pinyinAcc)
                        result += ipa
                        tokenPhonemes += ipa
                    }
                }

                // Add space separator after each token that contributed content.
                // This provides word boundaries and post-punctuation pauses
                // (matching English behavior where each token is followed by whitespace).
                let hasContent = result.count > resultLenBefore
                var tokenWhitespace = ""
                if hasContent && result.last != " " {
                    result += " "
                    tokenWhitespace = " "
                }

                // Build MToken for timestamp prediction
                if hasContent {
                    let dummyRange = text.startIndex..<text.startIndex
                    let mToken = MToken(
                        text: tk.text,
                        tokenRange: dummyRange,
                        whitespace: tokenWhitespace,
                        phonemes: tokenPhonemes.isEmpty ? nil : tokenPhonemes
                    )
                    mTokens.append(mToken)
                }

                lastWasEng = isEng
            }

            let trimmedResult = result.trimmingCharacters(in: .whitespaces)

            // Fix whitespace on last token (trimmed trailing space)
            if let lastToken = mTokens.last, !trimmedResult.isEmpty {
                lastToken.whitespace = ""
            }

            return (trimmedResult, mTokens)
        }

        return (legacyCall(processedText), [])
    }

    // MARK: - Static methods

    /// Apply tone retoning: convert IPA tone diacritics to simplified arrows
    public static func retone(_ p: String) -> String {
        var result = p
        result = result.replacingOccurrences(of: "˧˩˧", with: "↓")
        result = result.replacingOccurrences(of: "˧˥", with: "↗")
        result = result.replacingOccurrences(of: "˥˩", with: "↘")
        result = result.replacingOccurrences(of: "˥", with: "→")
        // ɨ handling
        result = result.replacingOccurrences(of: "\u{027B}\u{0329}", with: "ɨ")
        result = result.replacingOccurrences(of: "\u{0279}\u{0329}", with: "ɨ")
        result = result.replacingOccurrences(of: "ɻ̩", with: "ɨ")
        result = result.replacingOccurrences(of: "ɹ̩", with: "ɨ")
        return result
    }

    /// Convert a pinyin syllable to IPA
    public static func py2ipa(_ py: String) -> String {
        let ipa = pinyinToIPAConvert(py)
        return retone(ipa)
    }

    /// Parse pinyin string into initial, final, and tone
    public struct PinyinParts {
        public var initial: String = ""
        public var final: String = ""
        public var tone: Int = 5
    }

    public static func parsePinyin(_ rawPinyin: String) -> PinyinParts {
        var parts = PinyinParts()
        let pinyin = rawPinyin.trimmingCharacters(in: .whitespaces)
        guard !pinyin.isEmpty else { return parts }

        // Normalize pinyin: expand tone marks
        var base = ""
        var detectedTone = 5

        var i = pinyin.startIndex
        while i < pinyin.endIndex {
            var matched = false
            for (key, value) in toneVowels {
                if pinyin[i...].hasPrefix(key) {
                    if detectedTone == 5 { detectedTone = value.tone }
                    base += value.base
                    i = pinyin.index(i, offsetBy: key.count)
                    matched = true
                    break
                }
            }
            if !matched {
                base.append(pinyin[i])
                i = pinyin.index(after: i)
            }
        }

        // Check explicitly written number tone (e.g., zhong1)
        if !base.isEmpty, let last = base.last, last.isNumber {
            parts.tone = Int(String(last))!
            base.removeLast()
        } else {
            parts.tone = detectedTone
        }

        base = base.replacingOccurrences(of: "v", with: "ü")

        // Handle y and w normalization
        if base.hasPrefix("yi") {
            base = String(base.dropFirst())  // yi -> i
        } else if base.hasPrefix("y") {
            if base.count > 1 && base[base.index(after: base.startIndex)] == "u" {
                base = "ü" + String(base.dropFirst(2))  // yu -> ü
            } else {
                base = "i" + String(base.dropFirst())  // ya -> ia
            }
        } else if base.hasPrefix("wu") {
            base = String(base.dropFirst())  // wu -> u
        } else if base.hasPrefix("w") {
            base = "u" + String(base.dropFirst())  // wa -> ua
        }

        // Extract initial
        var pInitial = ""
        let multiInitials = ["zh", "ch", "sh"]
        for ini in multiInitials {
            if base.hasPrefix(ini) {
                pInitial = ini
                break
            }
        }
        if pInitial.isEmpty {
            let firstChar = String(base.prefix(1))
            if initialMapping[firstChar] != nil {
                pInitial = firstChar
            }
        }

        parts.initial = pInitial
        parts.final = String(base.dropFirst(pInitial.count))

        return parts
    }

    /// Map Chinese punctuation to Western equivalents
    public static func mapPunctuation(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "、", with: ", ")
        result = result.replacingOccurrences(of: "，", with: ", ")
        result = result.replacingOccurrences(of: "。", with: ". ")
        result = result.replacingOccurrences(of: "．", with: ". ")
        result = result.replacingOccurrences(of: "！", with: "! ")
        result = result.replacingOccurrences(of: "：", with: ": ")
        result = result.replacingOccurrences(of: "；", with: "; ")
        result = result.replacingOccurrences(of: "？", with: "? ")
        result = result.replacingOccurrences(of: "«", with: " \u{201C}")
        result = result.replacingOccurrences(of: "»", with: "\u{201D} ")
        result = result.replacingOccurrences(of: "《", with: " \u{201C}")
        result = result.replacingOccurrences(of: "》", with: "\u{201D} ")
        result = result.replacingOccurrences(of: "「", with: " \u{201C}")
        result = result.replacingOccurrences(of: "」", with: "\u{201D} ")
        result = result.replacingOccurrences(of: "【", with: " \u{201C}")
        result = result.replacingOccurrences(of: "】", with: "\u{201D} ")
        result = result.replacingOccurrences(of: "（", with: " (")
        result = result.replacingOccurrences(of: "）", with: ") ")
        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Private

    /// Convert pinyin to IPA (internal)
    private static func pinyinToIPAConvert(_ pinyin: String) -> String {
        var parts = parsePinyin(pinyin)
        var ipaSegments: [String] = []

        // 1. Initial
        if !parts.initial.isEmpty, let mapping = initialMapping[parts.initial] {
            ipaSegments.append(mapping[0])
        }

        // 2. Final
        var finalPhonemes: [String] = []
        var handled = false
        var isErhua = false

        if !parts.final.isEmpty && parts.final.last == "R" {
            isErhua = true
            parts.final = String(parts.final.dropLast())
        }

        if ["zh", "ch", "sh", "r"].contains(parts.initial),
           let mapping = finalMappingZhChShR[parts.final] {
            finalPhonemes = mapping
            handled = true
        } else if ["z", "c", "s"].contains(parts.initial),
                  let mapping = finalMappingZCS[parts.final] {
            finalPhonemes = mapping
            handled = true
        }

        if !handled, let mapping = finalMapping[parts.final] {
            finalPhonemes = mapping
        }

        if finalPhonemes.isEmpty && !parts.final.isEmpty {
            finalPhonemes.append(parts.final)
        }

        // 3. Apply tone
        let toneMark = toneMapping[parts.tone] ?? ""
        for ph in finalPhonemes {
            let processed = ph.replacingOccurrences(of: "0", with: toneMark)
            ipaSegments.append(processed)
        }

        if isErhua {
            ipaSegments.append("ɚ")
        }

        return ipaSegments.joined()
    }

    /// Legacy call: simple word-by-word conversion without frontend
    private func legacyCall(_ text: String) -> String {
        var result = ""
        let words = jieba.tag(text)

        for (word, _) in words {
            if StringUtils.isChinese(word) {
                let pinyins = pinyinFinder.findBestPinyin(word)
                for py in pinyins {
                    result += Self.py2ipa(py)
                }
                result += " "
            } else {
                result += word
            }
        }

        // Trim trailing space
        result = result.trimmingCharacters(in: .whitespaces)
        // Remove combining inverted breve
        result = result.replacingOccurrences(of: "\u{032F}", with: "")

        return result
    }
}
