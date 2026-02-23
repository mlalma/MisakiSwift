import Foundation

/// Utility functions for number-to-Chinese conversion and other string helpers.
/// Based on https://zh.wikipedia.org/wiki/中文数字#現代中文
public enum StringUtils {
    
    // MARK: - Constants
    
    /// Chinese digits mapping
    private static let digits: [Character: String] = [
        "0": "零", "1": "一", "2": "二", "3": "三", "4": "四",
        "5": "五", "6": "六", "7": "七", "8": "八", "9": "九"
    ]
    
    /// Units for powers of 10 (1=十, 2=百, 3=千, 4=万, 8=亿)
    private static let units: [(power: Int, char: String)] = [
        (8, "亿"), (4, "万"), (3, "千"), (2, "百"), (1, "十")
    ]
    
    /// Common Chinese quantifiers/measure words
    private static let quantifiersPattern = "(封|艘|把|目|套|段|人|所|朵|匹|张|座|回|场|尾|条|个|首|阙|阵|网|炮|顶|丘|棵|只|支|袭|辆|挑|担|颗|壳|窠|曲|墙|群|腔|砣|客|贯|扎|捆|刀|令|打|手|罗|坡|山|岭|江|溪|钟|队|单|双|对|出|口|头|脚|板|跳|枝|件|贴|针|线|管|名|位|身|堂|课|本|页|家|户|层|丝|毫|厘|分|钱|两|斤|铢|石|钧|锱|忽|千克|毫克|微克|公分|厘米|分米|毫米|微米|千米|米|寸|尺|丈|里|寻|常|铺|程|撮|勺|合|升|斗|盘|碗|碟|叠|桶|笼|盆|盒|杯|斛|锅|簋|篮|罐|瓶|壶|卮|盏|箩|箱|煲|啖|袋|钵|年|月|日|季|刻|时|周|天|秒|小时|旬|纪|岁|世|更|夜|春|夏|秋|冬|代|伏|辈|丸|泡|粒|幢|堆|根|道|面|片|块|亿元|千万元|百万元|万元|千元|百元|美元|元|亿吨|千万吨|百万吨|万吨|千吨|百吨|十吨|吨|亿块|千万块|百万块|万块|千块|百块|角|毛|公里|公引|公丈|公尺|公寸|公分|公釐)"
    
    // MARK: - Public Methods
    
    /// Convert a decimal digit character to Chinese
    public static func digitToChinese(_ c: Character) -> String {
        return digits[c] ?? ""
    }
    
    /// Read digits one by one, optionally replacing 一 with 幺 (for phone numbers, IDs, etc.)
    public static func verbalizeDigit(_ s: String, altOne: Bool = false) -> String {
        var result = s.map { digitToChinese($0) }.joined()
        if altOne {
            result = result.replacingOccurrences(of: "一", with: "幺")
        }
        return result
    }
    
    /// Convert cardinal number (integer) to Chinese using proper units
    /// e.g., 123 → 一百二十三, 1000 → 一千, 10 → 十
    public static func verbalizeCardinal(_ s: String) -> String {
        guard !s.isEmpty else { return "" }
        
        // Strip leading zeros: 000 → 零, 0 → 零
        let stripped = String(s.drop(while: { $0 == "0" }))
        guard !stripped.isEmpty else { return "零" }
        
        let resultSymbols = getValue(stripped, useZero: true)
        
        // Abbreviate 一十* as 十* (e.g., 12 → 十二 instead of 一十二)
        if resultSymbols.count >= 2 && resultSymbols[0] == "一" && resultSymbols[1] == "十" {
            return resultSymbols.dropFirst().joined()
        }
        
        return resultSymbols.joined()
    }
    
    /// Convert a number string (integer or decimal) to Chinese
    /// Handles: integers, decimals, pure decimals (.22)
    /// Examples: 123 → 一百二十三, 3.14 → 三点一四, .22 → 零点二二, 3.20 → 三点二
    public static func num2str(_ valueString: String) -> String {
        let parts = valueString.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        
        let integerPart: String
        var decimalPart: String
        
        if parts.count == 1 {
            integerPart = String(parts[0])
            decimalPart = ""
        } else if parts.count == 2 {
            integerPart = String(parts[0])
            decimalPart = String(parts[1])
        } else {
            return valueString // Invalid format
        }
        
        // Convert integer part
        var result = verbalizeCardinal(integerPart)
        
        // Strip trailing zeros from decimal part: 3.20 → 三点二
        while decimalPart.hasSuffix("0") {
            decimalPart.removeLast()
        }
        
        // Convert decimal part (digit by digit)
        if !decimalPart.isEmpty {
            // '.22' is verbalized as '零点二二'
            if result.isEmpty {
                result = "零"
            }
            result += "点" + verbalizeDigit(decimalPart)
        }
        
        return result.isEmpty ? "零" : result
    }
    
    /// Convert a number string to Chinese text (legacy API)
    /// Supports integers, negative numbers, decimals, and IP-like dotted notation
    public static func numberToChinese(_ numStr: String) -> String {
        guard !numStr.isEmpty else { return "" }
        
        let dotCount = numStr.filter { $0 == "." }.count
        
        // IP/version style: 1.2.3.4 → 一点二点三点四
        if dotCount > 1 {
            var result = ""
            for c in numStr {
                if c == "." {
                    result += "点"
                } else if c.isNumber {
                    result += digitToChinese(c)
                } else {
                    result.append(c)
                }
            }
            return result
        }
        
        var result = ""
        var startIdx = numStr.startIndex
        if numStr.first == "-" {
            result += "负"
            startIdx = numStr.index(after: startIdx)
        } else if numStr.first == "+" {
            startIdx = numStr.index(after: startIdx)
        }
        
        let remaining = String(numStr[startIdx...])
        result += num2str(remaining)
        
        return result
    }
    
    /// Convert numbers in text to Chinese
    /// Handles percentages, fractions, ranges, quantifiers, and regular numbers
    public static func convertNumbers(_ text: String) -> String {
        var result = text
        
        // 1. Handle percentages: 90% → 百分之九十, -50.5% → 负百分之五十点五
        result = replaceMatches(
            in: result,
            pattern: "(-?)(\\d+(?:\\.\\d+)?)%"
        ) { match, nsString in
            let sign = match.range(at: 1).length > 0 ? "负" : ""
            let numStr = nsString.substring(with: match.range(at: 2))
            return "\(sign)百分之\(num2str(numStr))"
        }
        
        // 2. Handle fractions: 1/2 → 二分之一, -3/4 → 负四分之三
        result = replaceMatches(
            in: result,
            pattern: "(-?)(\\d+)/(\\d+)"
        ) { match, nsString in
            let sign = match.range(at: 1).length > 0 ? "负" : ""
            let numerator = nsString.substring(with: match.range(at: 2))
            let denominator = nsString.substring(with: match.range(at: 3))
            return "\(sign)\(num2str(denominator))分之\(num2str(numerator))"
        }
        
        // 3. Handle ranges: 1-10 or 1~10 → 一到十
        result = replaceMatches(
            in: result,
            pattern: "((?:-?\\d+(?:\\.\\d+)?)|(?:\\.\\d+))[-~]((?:-?\\d+(?:\\.\\d+)?)|(?:\\.\\d+))"
        ) { match, nsString in
            let first = nsString.substring(with: match.range(at: 1))
            let second = nsString.substring(with: match.range(at: 2))
            return "\(numberToChinese(first))到\(numberToChinese(second))"
        }
        
        // 4. Handle numbers with quantifiers: 3个 → 三个, 10+人 → 十多人
        result = replaceMatches(
            in: result,
            pattern: "(\\d+)([多余几+])?" + quantifiersPattern
        ) { match, nsString in
            let number = nsString.substring(with: match.range(at: 1))
            var modifier = ""
            if match.range(at: 2).location != NSNotFound && match.range(at: 2).length > 0 {
                modifier = nsString.substring(with: match.range(at: 2))
                if modifier == "+" {
                    modifier = "多"
                }
            }
            let quantifier = nsString.substring(with: match.range(at: 3))
            return "\(num2str(number))\(modifier)\(quantifier)"
        }
        
        // 5. Handle pure decimals: .22 → 零点二二
        result = replaceMatches(
            in: result,
            pattern: "(?<!\\d)\\.(\\d+)"
        ) { match, nsString in
            let decimalPart = nsString.substring(with: match.range(at: 1))
            // Strip trailing zeros
            var stripped = decimalPart
            while stripped.hasSuffix("0") {
                stripped.removeLast()
            }
            if stripped.isEmpty {
                return "零"
            }
            return "零点\(verbalizeDigit(stripped))"
        }
        
        // 6. Handle regular numbers (negative numbers, decimals, integers)
        // This includes all remaining numbers: 1234 → 一千二百三十四
        result = replaceMatches(
            in: result,
            pattern: "-?\\d+(?:\\.\\d+)?"
        ) { match, nsString in
            let numStr = nsString.substring(with: match.range)
            return numberToChinese(numStr)
        }
        
        return result
    }
    
    /// Check if a string contains Chinese characters
    public static func isChinese(_ str: String) -> Bool {
        for scalar in str.unicodeScalars {
            if (scalar.value >= 0x4E00 && scalar.value <= 0x9FFF) ||
               (scalar.value >= 0x3400 && scalar.value <= 0x4DBF) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Private Helpers
    
    /// Recursive helper to build Chinese number representation
    private static func getValue(_ valueString: String, useZero: Bool) -> [String] {
        let stripped = String(valueString.drop(while: { $0 == "0" }))
        
        if stripped.isEmpty {
            return []
        } else if stripped.count == 1 {
            if useZero && stripped.count < valueString.count {
                return ["零", digitToChinese(stripped.first!)]
            } else {
                return [digitToChinese(stripped.first!)]
            }
        } else {
            // Find the largest unit that applies
            guard let (power, unitChar) = units.first(where: { $0.power < stripped.count }) else {
                // No unit applies, read digit by digit
                return stripped.map { digitToChinese($0) }
            }
            
            let splitIndex = stripped.index(stripped.endIndex, offsetBy: -power)
            let firstPart = String(stripped[..<splitIndex])
            let secondPart = String(stripped[splitIndex...])
            
            return getValue(firstPart, useZero: true) + [unitChar] + getValue(secondPart, useZero: true)
        }
    }
    
    /// Helper to apply regex replacement with a closure
    private static func replaceMatches(
        in text: String,
        pattern: String,
        replacer: (NSTextCheckingResult, NSString) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        guard !matches.isEmpty else { return text }
        
        var result = text
        // Process in reverse to preserve indices
        for match in matches.reversed() {
            let replacement = replacer(match, result as NSString)
            result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
        }
        
        return result
    }
}
