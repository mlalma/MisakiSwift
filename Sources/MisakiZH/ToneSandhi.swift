import Foundation

/// Implements Chinese tone sandhi rules.
public final class ToneSandhi {
    public typealias PinyinProvider = (String) -> [String]
    public typealias SplitWordProvider = (String) -> [String]  // jieba.cut_for_search

    private var pinyinProvider: PinyinProvider?
    private var splitWordProvider: SplitWordProvider?
    private let mustNeuralToneWords: Set<String>
    private let mustNotNeuralToneWords: Set<String>
    private let punc: Set<Character>

    public init() {
        punc = Set("、：，；。？！\u{201C}\u{201D}\u{2018}\u{2019}':,;.?!")

        mustNeuralToneWords = [
            "麻烦", "麻利", "鸳鸯", "高粱", "骨头", "骆驼", "马虎", "首饰", "馒头", "馄饨", "风筝",
            "难为", "队伍", "阔气", "闺女", "门道", "锄头", "铺盖", "铃铛", "铁匠", "钥匙", "里脊",
            "里头", "部分", "那么", "道士", "造化", "迷糊", "连累", "这么", "这个", "运气", "过去",
            "软和", "转悠", "踏实", "跳蚤", "跟头", "趔趄", "财主", "豆腐", "讲究", "记性", "记号",
            "认识", "规矩", "见识", "裁缝", "补丁", "衣裳", "衣服", "衙门", "街坊", "行李", "行当",
            "蛤蟆", "蘑菇", "薄荷", "葫芦", "葡萄", "萝卜", "荸荠", "苗条", "苗头", "苍蝇", "芝麻",
            "舒服", "舒坦", "舌头", "自在", "膏药", "脾气", "脑袋", "脊梁", "能耐", "胳膊", "胭脂",
            "胡萝", "胡琴", "胡同", "聪明", "耽误", "耽搁", "耷拉", "耳朵", "老爷", "老实", "老婆",
            "戏弄", "将军", "翻腾", "罗嗦", "罐头", "编辑", "结实", "红火", "累赘", "糨糊", "糊涂",
            "精神", "粮食", "簸箕", "篱笆", "算计", "算盘", "答应", "笤帚", "笑语", "笑话", "窟窿",
            "窝囊", "窗户", "稳当", "稀罕", "称呼", "秧歌", "秀气", "秀才", "福气", "祖宗", "砚台",
            "码头", "石榴", "石头", "石匠", "知识", "眼睛", "眯缝", "眨巴", "眉毛", "相声", "盘算",
            "白净", "痢疾", "痛快", "疟疾", "疙瘩", "疏忽", "畜生", "生意", "甘蔗", "琵琶", "琢磨",
            "琉璃", "玻璃", "玫瑰", "玄乎", "狐狸", "状元", "特务", "牲口", "牙碜", "牌楼", "爽快",
            "爱人", "热闹", "烧饼", "烟筒", "烂糊", "点心", "炊帚", "灯笼", "火候", "漂亮", "滑溜",
            "溜达", "温和", "清楚", "消息", "浪头", "活泼", "比方", "正经", "欺负", "模糊", "槟榔",
            "棺材", "棒槌", "棉花", "核桃", "栅栏", "柴火", "架势", "枕头", "枇杷", "机灵", "本事",
            "木头", "木匠", "朋友", "月饼", "月亮", "暖和", "明白", "时候", "新鲜", "故事", "收拾",
            "收成", "提防", "挖苦", "挑剔", "指甲", "指头", "拾掇", "拳头", "拨弄", "招牌", "招呼",
            "抬举", "护士", "折腾", "扫帚", "打量", "打算", "打扮", "打听", "打发", "扎实", "扁担",
            "戒指", "懒得", "意识", "意思", "悟性", "怪物", "思量", "怎么", "念头", "念叨", "别人",
            "快活", "忙活", "志气", "心思", "得罪", "张罗", "弟兄", "开通", "应酬", "庄稼", "干事",
            "帮手", "帐篷", "希罕", "师父", "师傅", "巴结", "巴掌", "差事", "工夫", "岁数", "屁股",
            "尾巴", "少爷", "小气", "小伙", "将就", "对头", "对付", "寡妇", "家伙", "客气", "实在",
            "官司", "学问", "字号", "嫁妆", "媳妇", "媒人", "婆家", "娘家", "委屈", "姑娘", "姐夫",
            "妯娌", "妥当", "妖精", "奴才", "女婿", "头发", "太阳", "大爷", "大方", "大意", "大夫",
            "多少", "多么", "外甥", "壮实", "地道", "地方", "在乎", "困难", "嘴巴", "嘱咐", "嘟囔",
            "嘀咕", "喜欢", "喇嘛", "喇叭", "商量", "唾沫", "哑巴", "哈欠", "哆嗦", "咳嗽", "和尚",
            "告诉", "告示", "含糊", "吓唬", "后头", "名字", "名堂", "合同", "吆喝", "叫唤", "口袋",
            "厚道", "厉害", "千斤", "包袱", "包涵", "匀称", "勤快", "动静", "动弹", "功夫", "力气",
            "前头", "刺猬", "刺激", "别扭", "利落", "利索", "利害", "分析", "出息", "凑合", "凉快",
            "冷战", "冤枉", "冒失", "养活", "关系", "先生", "兄弟", "便宜", "使唤", "佩服", "作坊",
            "体面", "位置", "似的", "伙计", "休息", "什么", "人家", "亲戚", "亲家", "交情", "云彩",
            "事情", "买卖", "主意", "丫头", "丧气", "两口", "东西", "东家", "世故", "不由", "下水",
            "下巴", "上头", "上司", "丈夫", "丈人", "一辈", "那个", "菩萨", "父亲", "母亲", "咕噜",
            "邋遢", "费用", "冤家", "甜头", "介绍", "荒唐", "大人", "泥鳅", "幸福", "熟悉", "计划",
            "扑腾", "蜡烛", "姥爷", "照顾", "喉咙", "吉他", "弄堂", "蚂蚱", "凤凰", "拖沓", "寒碜",
            "糟蹋", "倒腾", "报复", "逻辑", "盘缠", "喽啰", "牢骚", "咖喱", "扫把", "惦记"
        ]

        mustNotNeuralToneWords = [
            "男子", "女子", "分子", "原子", "量子", "莲子", "石子", "瓜子", "电子", "人人", "虎虎",
            "幺幺", "干嘛", "学子", "哈哈", "数数", "袅袅", "局地", "以下", "娃哈哈", "花花草草", "留得",
            "耕地", "想想", "熙熙", "攘攘", "卵子", "死死", "冉冉", "恳恳", "佼佼", "吵吵", "打打",
            "考考", "整整", "莘莘", "落地", "算子", "家家户户", "青青"
        ]
    }

    public func setPinyinProvider(_ provider: @escaping PinyinProvider) {
        pinyinProvider = provider
    }

    public func setSplitWordProvider(_ provider: @escaping SplitWordProvider) {
        splitWordProvider = provider
    }

    // MARK: - Pre-merge

    public func preMergeForModify(_ seg: [(String, String)]) -> [(String, String)] {
        var result = mergeBu(seg)
        result = mergeYi(result)
        result = mergeReducplication(result)
        result = mergeContinuousThreeTones(result)
        result = mergeContinuousThreeTones2(result)
        result = mergeEr(result)
        return result
    }

    // MARK: - Modified tone

    public func modifiedTone(word: String, pos: String, finals: [String]) -> [String] {
        var f = buSandhi(word: word, finals: finals)
        f = yiSandhi(word: word, finals: f)
        f = neuralSandhi(word: word, pos: pos, finals: f)
        f = threeSandhi(word: word, finals: f)
        return f
    }

    // MARK: - Private helpers

    private func isTone(_ final: String, _ tone: Character) -> Bool {
        return final.last == tone
    }

    private func setTone(_ final: inout String, _ tone: Character) {
        guard !final.isEmpty else { return }
        if final.last?.isNumber == true { final.removeLast() }
        final.append(tone)
    }

    private func allToneThree(_ finals: [String]) -> Bool {
        return !finals.isEmpty && finals.allSatisfy { $0.last == "3" }
    }

    private func isReduplication(_ word: String) -> Bool {
        let chars = Array(word)
        return chars.count == 2 && chars[0] == chars[1]
    }

    /// Returns finals (e.g. ["an3","hao3"]) for a word via pinyinProvider.
    private func getFinals(_ word: String, provider: PinyinProvider) -> [String] {
        let pinyins = provider(word)
        return pinyins.map { py in
            if let last = py.last, last.isNumber { return py }
            return py + "5"
        }
    }

    /// Split word using jieba cut_for_search: find shortest sub-word and split there.
    private func splitWord(_ word: String) -> [String] {
        let chars = Array(word)
        guard chars.count > 1 else { return [word] }
        if let provider = splitWordProvider {
            let subWords = provider(word)
            let sorted = subWords.filter { $0.count < word.count }.sorted { $0.count < $1.count }
            if let first = sorted.first {
                let firstChars = Array(first)
                if firstChars.count < chars.count {
                    if word.hasPrefix(first) {
                        return [first, String(chars[firstChars.count...])]
                    } else if word.hasSuffix(first) {
                        return [String(chars[0..<(chars.count - firstChars.count)]), first]
                    }
                }
            }
        }
        // Fallback: split at midpoint
        let splitIdx = chars.count >= 3 ? 2 : 1
        return [String(chars[0..<splitIdx]), String(chars[splitIdx...])]
    }

    // MARK: - Sandhi rules

    private func buSandhi(word: String, finals: [String]) -> [String] {
        var f = finals
        let chars = Array(word)
        // 3-char word with 不 in the middle → neutral tone
        if chars.count == 3 && chars[1] == "不" {
            if f.count > 1 { setTone(&f[1], "5") }
            return f
        }
        // 不 before tone-4 → becomes tone 2
        for i in 0..<chars.count {
            if chars[i] == "不" && i + 1 < chars.count,
               i + 1 < f.count, isTone(f[i + 1], "4") {
                if i < f.count { setTone(&f[i], "2") }
            }
        }
        return f
    }

    private func yiSandhi(word: String, finals: [String]) -> [String] {
        guard word.contains("一") else { return finals }
        var f = finals
        let chars = Array(word)
        // numeric sequences → no change
        let numericChars: Set<Character> = ["一","二","三","四","五","六","七","八","九","零","十",
                                             "0","1","2","3","4","5","6","7","8","9"]
        if chars.allSatisfy({ $0 == "一" || numericChars.contains($0) }) { return f }
        // ABA pattern: X一X (e.g. 看一看)
        if chars.count == 3 && chars[1] == "一" && chars[0] == chars[2] {
            if f.count > 1 { setTone(&f[1], "5") }
            return f
        }
        // 第一 → force 一 to tone 1
        if word.hasPrefix("第一") {
            if f.count > 1 { setTone(&f[1], "1") }
            return f
        }
        for i in 0..<chars.count {
            if chars[i] == "一" && i + 1 < chars.count, i + 1 < f.count {
                let nextTone = f[i + 1].last
                if nextTone == "4" || nextTone == "5" {
                    if i < f.count { setTone(&f[i], "2") }
                } else {
                    // tone 4 before anything else, but not before punctuation
                    if i + 1 < chars.count, !punc.contains(chars[i + 1]), i < f.count {
                        setTone(&f[i], "4")
                    }
                }
            }
        }
        return f
    }

    private func neuralSandhi(word: String, pos: String, finals: [String]) -> [String] {
        if mustNotNeuralToneWords.contains(word) { return finals }
        var f = finals
        let chars = Array(word)
        // Reduplication for n/v/a words (奶奶, 试试, 旺旺)
        for j in 1..<chars.count {
            if chars[j] == chars[j - 1] {
                if let p0 = pos.first, p0 == "n" || p0 == "v" || p0 == "a" {
                    if j < f.count { setTone(&f[j], "5") }
                }
            }
        }
        let last = chars[chars.count - 1]
        let particles: Set<Character> = Set("吧呢啊呐噻嘛吖嗨呐哦哒滴哩哟喽啰耶喔诶")
        if particles.contains(last) {
            if !f.isEmpty { setTone(&f[f.count - 1], "5") }
        } else if last == "的" || last == "地" || last == "得" {
            if !f.isEmpty { setTone(&f[f.count - 1], "5") }
        } else if chars.count == 1 && (last == "了" || last == "着" || last == "过") {
            if pos == "ul" || pos == "uz" || pos == "ug" {
                if !f.isEmpty { setTone(&f[f.count - 1], "5") }
            }
        } else if chars.count > 1 && (last == "们" || last == "子") && (pos == "r" || pos == "n") {
            if !f.isEmpty { setTone(&f[f.count - 1], "5") }
        } else if chars.count > 1 && (last == "上" || last == "下") && (pos == "s" || pos == "l" || pos == "f") {
            if !f.isEmpty { setTone(&f[f.count - 1], "5") }
        } else if chars.count > 1 && (last == "来" || last == "去") {
            let prev = chars[chars.count - 2]
            let dirs: Set<Character> = Set("上下进出回过起开")
            if dirs.contains(prev) {
                if !f.isEmpty { setTone(&f[f.count - 1], "5") }
            }
        // 个 as measure word (几个, 两个, etc.) - must be in elif chain like Python
        } else if word == "个" || word == "個" {
            if !f.isEmpty { setTone(&f[0], "5") }
        } else {
            // Find 个 in word
            let geNumPreceding: Set<Character> = Set("几有两半多各整每做是")
            for (gi, ch) in chars.enumerated() {
                if ch == "个" || ch == "個" {
                    let prevIsKey = gi >= 1 && (chars[gi - 1].isNumber || geNumPreceding.contains(chars[gi - 1]))
                    if prevIsKey {
                        if gi < f.count { setTone(&f[gi], "5") }
                        break
                    }
                }
            }
            // Check whole word and last-2-chars
            let last2 = chars.count >= 2 ? String(chars[(chars.count - 2)...]) : ""
            if mustNeuralToneWords.contains(word) || mustNeuralToneWords.contains(last2) {
                if !f.isEmpty { setTone(&f[f.count - 1], "5") }
            }
        }

        // Sub-word check runs unconditionally (outside the if/elif/else chain)
        let wordList = splitWord(word)
        let split1Count = Array(wordList[0]).count
        var finalsList: [[String]] = [Array(f.prefix(split1Count)), Array(f.dropFirst(split1Count))]
        for i in 0..<wordList.count {
            let subChars = Array(wordList[i])
            let last2sub = subChars.count >= 2 ? String(subChars[(subChars.count - 2)...]) : ""
            if mustNeuralToneWords.contains(wordList[i]) || mustNeuralToneWords.contains(last2sub) {
                if !finalsList[i].isEmpty { setTone(&finalsList[i][finalsList[i].count - 1], "5") }
            }
        }
        f = finalsList[0] + finalsList[1]

        return f
    }

    private func threeSandhi(word: String, finals: [String]) -> [String] {
        var f = finals
        let chars = Array(word)
        if chars.count == 2 && allToneThree(f) {
            setTone(&f[0], "2")
        } else if chars.count == 3 {
            let wordList = splitWord(word)
            let p1Len = Array(wordList[0]).count
            if allToneThree(f) {
                if p1Len == 2 {
                    if f.count > 1 { setTone(&f[0], "2"); setTone(&f[1], "2") }
                } else {
                    if f.count > 1 { setTone(&f[1], "2") }
                }
            } else {
                var sub0 = Array(f.prefix(p1Len))
                var sub1 = Array(f.dropFirst(p1Len))
                // e.g. 所有/人: both sub[0] are all tone three and len==2
                if allToneThree(sub0) && sub0.count >= 2 { setTone(&sub0[0], "2") }
                if allToneThree(sub1) && sub1.count >= 2 { setTone(&sub1[0], "2") }
                // e.g. 好/喜欢: sub1 is NOT all tone three, but sub1[0] is tone-3 and sub0's last is tone-3
                else if !sub1.isEmpty && !allToneThree(sub1) &&
                        sub1[0].last == "3" && !sub0.isEmpty && sub0[sub0.count - 1].last == "3" {
                    setTone(&sub0[sub0.count - 1], "2")
                }
                f = sub0 + sub1
            }
        } else if chars.count == 4 {
            var front = Array(f.prefix(2))
            var back = Array(f.dropFirst(2))
            if allToneThree(front) { setTone(&front[0], "2") }
            if allToneThree(back)  { setTone(&back[0], "2") }
            f = front + back
        }
        return f
    }

    // MARK: - Merge rules

    private let xEng: Set<String> = ["x", "eng"]

    /// Merge "不" with following word so tone sandhi applies across the boundary.
    private func mergeBu(_ seg: [(String, String)]) -> [(String, String)] {
        var newSeg: [(String, String)] = []
        for i in 0..<seg.count {
            let (word, pos) = seg[i]
            var mergedWord = word
            if !xEng.contains(pos) {
                // Check if prior word in original seg was 不
                if i > 0 && seg[i - 1].0 == "不" {
                    mergedWord = "不" + word
                }
            }
            // Only append if word is not 不 that should be merged forward,
            // i.e., skip 不 if the next word exists and its pos allows merging.
            let nextPos: String? = (i + 1 < seg.count) ? seg[i + 1].1 : nil
            if mergedWord != "不" || nextPos == nil || xEng.contains(nextPos!) {
                newSeg.append((mergedWord, pos))
            }
        }
        return newSeg
    }

    /// Merge 一 patterns: A-一-A reduplication, and standalone 一 + next word.
    private func mergeYi(_ seg: [(String, String)]) -> [(String, String)] {
        var result = seg
        // Pass 1: A一A (verb reduplication like 看一看)
        var pass1: [(String, String)] = []
        var i = 0
        while i < result.count {
            let (word, pos) = result[i]
            if word == "一", i > 0, i + 1 < result.count,
               result[i - 1].0 == result[i + 1].0, result[i - 1].1 == "v",
               !xEng.contains(result[i + 1].1) {
                pass1[pass1.count - 1].0 += "一" + result[i + 1].0
                i += 2
            } else {
                pass1.append((word, pos))
                i += 1
            }
        }
        result = pass1
        // Pass 2: standalone 一 + following word
        var pass2: [(String, String)] = []
        for (word, pos) in result {
            if !pass2.isEmpty && pass2.last!.0 == "一" && !xEng.contains(pos) {
                pass2[pass2.count - 1].0 += word
            } else {
                pass2.append((word, pos))
            }
        }
        return pass2
    }

    /// Merge adjacent identical words: (听,v),(听,v) → (听听,v)
    private func mergeReducplication(_ seg: [(String, String)]) -> [(String, String)] {
        var newSeg: [(String, String)] = []
        for (word, pos) in seg {
            if !newSeg.isEmpty && word == newSeg.last!.0 && !xEng.contains(pos) {
                newSeg[newSeg.count - 1].0 += word
            } else {
                newSeg.append((word, pos))
            }
        }
        return newSeg
    }

    /// Merge consecutive all-tone-3 adjacent words (combined length ≤ 3).
    private func mergeContinuousThreeTones(_ seg: [(String, String)]) -> [(String, String)] {
        guard let provider = pinyinProvider else { return seg }
        let subFinals: [[String]] = seg.map { item in
            if xEng.contains(item.1) { return ["0"] }
            return getFinals(item.0, provider: provider)
        }
        var newSeg: [(String, String)] = []
        var merged = [Bool](repeating: false, count: seg.count)
        for i in 0..<seg.count {
            if !xEng.contains(seg[i].1)
               && i > 0
               && allToneThree(subFinals[i - 1]) && allToneThree(subFinals[i])
               && !merged[i - 1]
               && !isReduplication(seg[i - 1].0)
               && Array(seg[i - 1].0).count + Array(seg[i].0).count <= 3 {
                newSeg[newSeg.count - 1].0 += seg[i].0
                merged[i] = true
            } else {
                newSeg.append(seg[i])
            }
        }
        return newSeg
    }

    /// Merge pairs where last syllable of prev and first syllable of next are both tone-3.
    private func mergeContinuousThreeTones2(_ seg: [(String, String)]) -> [(String, String)] {
        guard let provider = pinyinProvider else { return seg }
        let subFinals: [[String]] = seg.map { item in
            if xEng.contains(item.1) { return ["0"] }
            return getFinals(item.0, provider: provider)
        }
        var newSeg: [(String, String)] = []
        var merged = [Bool](repeating: false, count: seg.count)
        for i in 0..<seg.count {
            if !xEng.contains(seg[i].1)
               && i > 0,
               let prevLast = subFinals[i - 1].last?.last, prevLast == "3",
               let curFirst = subFinals[i].first?.last, curFirst == "3",
               !merged[i - 1],
               !isReduplication(seg[i - 1].0),
               Array(seg[i - 1].0).count + Array(seg[i].0).count <= 3 {
                newSeg[newSeg.count - 1].0 += seg[i].0
                merged[i] = true
            } else {
                newSeg.append(seg[i])
            }
        }
        return newSeg
    }

    /// Merge 儿 suffix with preceding word.
    private func mergeEr(_ seg: [(String, String)]) -> [(String, String)] {
        var newSeg: [(String, String)] = []
        for (i, item) in seg.enumerated() {
            if i > 0 && item.0 == "儿" && !newSeg.isEmpty && !xEng.contains(newSeg.last!.1) {
                newSeg[newSeg.count - 1].0 += item.0
            } else {
                newSeg.append(item)
            }
        }
        return newSeg
    }
}
