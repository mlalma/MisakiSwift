import Foundation

/// Chinese text frontend: handles segmentation, pinyin lookup, tone sandhi, and erhua.
public final class ZHFrontend {
    private let unk: String
    private let pinyinFinder: PinyinFinder
    private let jieba: JiebaWrapper
    private let toneModifier: ToneSandhi

    private let punc: Set<String> = [";", ":", ",", ".", "!", "?", "—", "…", "\"", "(", ")", "\u{201C}", "\u{201D}"]

    private let mustErhua: Set<String> = [
        "小院儿", "胡同儿", "范儿", "老汉儿", "撒欢儿", "寻老礼儿", "妥妥儿", "媳妇儿"
    ]
    private let notErhua: Set<String> = [
        "虐儿", "为儿", "护儿", "瞒儿", "救儿", "替儿", "有儿", "一儿", "我儿", "俺儿", "妻儿",
        "拐儿", "聋儿", "乞儿", "患儿", "幼儿", "孤儿", "婴儿", "婴幼儿", "连体儿", "脑瘫儿",
        "流浪儿", "体弱儿", "混血儿", "蜜雪儿", "舫儿", "祖儿", "美儿", "应采儿", "可儿", "侄儿",
        "孙儿", "侄孙儿", "女儿", "男儿", "红孩儿", "花儿", "虫儿", "马儿", "鸟儿", "猪儿", "猫儿",
        "狗儿", "少儿"
    ]

    public init(jieba: JiebaWrapper, pinyinFinder: PinyinFinder, unk: String = "?") {
        self.jieba = jieba
        self.pinyinFinder = pinyinFinder
        self.unk = unk
        self.toneModifier = ToneSandhi()
        self.toneModifier.setPinyinProvider { [pinyinFinder] word in
            pinyinFinder.findBestPinyin(word)
        }
        self.toneModifier.setSplitWordProvider { [jieba] word in
            jieba.cutForSearch(word)
        }
    }

    /// Main entry: convert text to ZHMTokens with phonemes
    public func process(_ text: String, withErhua: Bool = true) -> [ZHMToken] {
        var tokens: [ZHMToken] = []

        let segCut = cutWithTag(text)
        let merged = toneModifier.preMergeForModify(segCut)

        for (word, pos) in merged {
            var tk = ZHMToken(text: word, tag: pos)

            if pos == "x" || pos == "eng" {
                if pos == "x" && punc.contains(word) {
                    tk.phonemes.append(word)
                }
                if pos == "eng" {
                    tk.phonemes.append(word)
                }
                tokens.append(tk)
                continue
            }

            // G2P
            var (initials, finals) = getInitialsFinals(word)

            // Tone sandhi
            var modifiedFinals = toneModifier.modifiedTone(word: word, pos: pos, finals: finals)

            // Erhua
            if withErhua {
                (initials, modifiedFinals) = mergeErhua(initials: initials, finals: modifiedFinals, word: word, pos: pos)
            }

            // Build phonemes
            for i in 0..<initials.count {
                if i < modifiedFinals.count {
                    if !initials[i].isEmpty {
                        tk.phonemes.append(initials[i])
                    }
                    tk.phonemes.append(modifiedFinals[i])
                }
            }
            tokens.append(tk)
        }

        return tokens
    }

    // MARK: - Private

    /// Cut text with POS tags using Jieba, fixing tag issues
    private func cutWithTag(_ text: String) -> [(String, String)] {
        let tagWords = jieba.tag(text)
        var result: [(String, String)] = []

        for (word, rawTag) in tagWords {
            var tag = rawTag
            // jieba may return 'w' for punctuation
            if tag == "w" { tag = "x" }

            // If tagged as 'x' but contains Chinese, fix to 'n'
            if tag == "x" && StringUtils.isChinese(word) {
                tag = "n"
            }

            // Detect English words: pure ASCII alpha → tag as "eng"
            if tag != "x" || !punc.contains(word) {
                let isAllAlpha = !word.isEmpty && word.allSatisfy { $0.isASCII && $0.isLetter }
                if isAllAlpha {
                    tag = "eng"
                }
            }

            result.append((word, tag))
        }
        return result
    }

    /// Get initials and finals for a word from pinyin
    private func getInitialsFinals(_ word: String) -> (initials: [String], finals: [String]) {
        let pinyins = pinyinFinder.findBestPinyin(word)
        var initials: [String] = []
        var finals: [String] = []

        // Handle '嗯' special case: after pypinyin>=0.44.0, '嗯' needs final to be 'n2'
        let wordChars = Array(word)
        var enIndices: Set<Int> = []
        for (idx, c) in wordChars.enumerated() {
            if c == "嗯" { enIndices.insert(idx) }
        }

        for (pyIdx, py) in pinyins.enumerated() {
            let parts = ZHG2P.parsePinyin(py)
            var finalWithTone = parts.final + "\(parts.tone)"

            // Handle 嗯: set final to n2
            if enIndices.contains(pyIdx) {
                initials.append("")
                finals.append("n2")
                continue
            }

            // Special handling for zi, ci, si, zhi, chi, shi, ri
            if parts.final == "i" {
                if ["z", "c", "s"].contains(parts.initial) {
                    finalWithTone = "ii\(parts.tone)"
                } else if ["zh", "ch", "sh", "r"].contains(parts.initial) {
                    finalWithTone = "iii\(parts.tone)"
                }
            }

            initials.append(parts.initial)
            finals.append(finalWithTone)
        }

        return (initials, finals)
    }

    /// Merge erhua suffixes
    private func mergeErhua(initials: [String], finals: [String], word: String, pos: String) -> ([String], [String]) {
        var newFinals = finals
        let chars = Array(word)

        guard chars.count == finals.count else {
            return (initials, finals)
        }

        // Fix er1 -> er2
        for i in 0..<newFinals.count {
            if i == newFinals.count - 1 && chars[i] == "儿" && newFinals[i] == "er1" {
                newFinals[i] = "er2"
            }
        }

        if !mustErhua.contains(word) && (notErhua.contains(word) || pos == "a" || pos == "j" || pos == "nr") {
            return (initials, newFinals)
        }

        var mergedInitials: [String] = []
        var mergedFinals: [String] = []

        for i in 0..<newFinals.count {
            if i == newFinals.count - 1 && chars[i] == "儿" &&
               (newFinals[i] == "er2" || newFinals[i] == "er5") &&
               !mergedFinals.isEmpty {
                // Merge: modify previous final
                var prev = mergedFinals[mergedFinals.count - 1]
                if !prev.isEmpty && prev.last!.isNumber {
                    let tone = prev.removeLast()
                    prev += "R"
                    prev.append(tone)
                    mergedFinals[mergedFinals.count - 1] = prev
                } else {
                    mergedFinals[mergedFinals.count - 1] += "R5"
                }
            } else {
                mergedInitials.append(initials[i])
                mergedFinals.append(newFinals[i])
            }
        }

        return (mergedInitials, mergedFinals)
    }
}
