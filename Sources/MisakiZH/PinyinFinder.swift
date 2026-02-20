import Foundation

/// Finds the best pinyin for Chinese text using character and phrase dictionaries.
public final class PinyinFinder {
    /// Dictionary mapping UTF-16 substrings to pinyin strings
    private var wordPinyinDict: [String: String] = [:]
    private let maxChars = 8

    public init() {}

    /// Initialize from dictionary files
    /// - Parameters:
    ///   - singleCharPath: Path to single character pinyin file (pinyin.txt, format: U+XXXX: pinyin)
    ///   - phrasePath: Path to phrase pinyin file (pinyin_phrase.txt, format: word: pinyin1 pinyin2)
    public func loadDictionaries(singleCharPath: String, phrasePath: String) -> Bool {
        // Load single character dictionary
        guard let charData = try? String(contentsOfFile: singleCharPath, encoding: .utf8) else {
            print("[WARN] Failed to open file: \(singleCharPath)")
            return false
        }

        var charCount = 0
        for line in charData.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), trimmed.hasPrefix("U+") else { continue }

            guard let colonIdx = trimmed.firstIndex(of: ":") else { continue }

            let hexStr = String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 2)..<colonIdx])
            guard let unicode = UInt32(hexStr, radix: 16),
                  let scalar = Unicode.Scalar(unicode) else { continue }

            var pinyinPart = String(trimmed[trimmed.index(after: colonIdx)...])
                .trimmingCharacters(in: .whitespaces)

            // Remove comment
            if let hashIdx = pinyinPart.firstIndex(of: "#") {
                pinyinPart = String(pinyinPart[..<hashIdx])
                    .trimmingCharacters(in: .whitespaces)
            }

            guard !pinyinPart.isEmpty else { continue }

            // Take first pinyin if comma-separated
            let firstPinyin = pinyinPart.components(separatedBy: ",").first ?? pinyinPart
            let key = String(Character(scalar))
            wordPinyinDict[key] = firstPinyin.trimmingCharacters(in: .whitespaces)
            charCount += 1
        }
        print("[INFO] total pinyin character count: \(charCount)")

        // Load phrase dictionary
        guard let phraseData = try? String(contentsOfFile: phrasePath, encoding: .utf8) else {
            print("[WARN] Failed to open file: \(phrasePath)")
            return false
        }

        var phraseCount = 0
        for line in phraseData.components(separatedBy: .newlines) {
            var cleanLine = line
            // Strip comments
            if let hashIdx = cleanLine.firstIndex(of: "#") {
                cleanLine = String(cleanLine[..<hashIdx])
            }
            let trimmed = cleanLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            guard let colonIdx = trimmed.firstIndex(of: ":") else { continue }

            let word = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
            let pinyin = String(trimmed[trimmed.index(after: colonIdx)...])
                .trimmingCharacters(in: .whitespaces)

            guard !word.isEmpty, !pinyin.isEmpty else { continue }

            wordPinyinDict[word] = pinyin
            phraseCount += 1
        }
        print("[INFO] total pinyin phrase count: \(phraseCount)")

        return true
    }

    /// Find the best pinyin for a Chinese phrase using dynamic programming
    public func findBestPinyin(_ phrase: String) -> [String] {
        let chars = Array(phrase)
        let n = chars.count
        guard n > 0 else { return [] }

        // dp[i][j] = minimum cost for substring chars[i...j]
        // opts[i][j] = optimal split point
        var dp = Array(repeating: Array(repeating: Int.max, count: n), count: n)
        var opts = Array(repeating: Array(repeating: -1, count: n), count: n)

        for length in 1...n {
            for i in 0...(n - length) {
                let j = i + length - 1
                if length == 1 {
                    dp[i][j] = 1
                    opts[i][j] = j
                } else {
                    let maxTry = min(length, maxChars)
                    for k in stride(from: maxTry, through: 1, by: -1) {
                        let to = i + k - 1
                        let sub = String(chars[i...to])

                        if wordPinyinDict[sub] != nil {
                            if to == j {
                                dp[i][j] = k == 1 ? 1 : 0
                                opts[i][j] = j
                            } else {
                                let cost = (k == 1) ? (dp[to + 1][j] + 1) : dp[to + 1][j]
                                if dp[i][j] > cost {
                                    dp[i][j] = cost
                                    opts[i][j] = to
                                }
                            }
                        }
                    }
                }
            }
        }

        // Reconstruct the best pinyin
        var pinyins: [String] = []
        var i = 0
        let j = n - 1
        while i <= j {
            var opt = opts[i][j]
            if opt == -1 {
                opt = i
            }
            let sub = String(chars[i...opt])
            if let py = wordPinyinDict[sub] {
                let parts = py.split(separator: " ").map(String.init)
                pinyins.append(contentsOf: parts)
            } else {
                pinyins.append(sub)
            }
            i = opt + 1
        }

        return pinyins
    }
}
