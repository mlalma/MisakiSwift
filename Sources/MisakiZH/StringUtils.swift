import Foundation

/// Utility functions for number-to-Chinese conversion and other string helpers.
public enum StringUtils {
    /// Convert a decimal digit character to Chinese
    public static func digitToChinese(_ c: Character) -> String {
        switch c {
        case "0": return "零"
        case "1": return "一"
        case "2": return "二"
        case "3": return "三"
        case "4": return "四"
        case "5": return "五"
        case "6": return "六"
        case "7": return "七"
        case "8": return "八"
        case "9": return "九"
        default: return ""
        }
    }

    /// Convert a number string to Chinese text
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
        let parts = remaining.split(separator: ".", maxSplits: 1)
        let integerPart = String(parts[0])
        let decimalPart = parts.count > 1 ? String(parts[1]) : nil

        // Convert integer part
        result += integerToChineseString(integerPart)

        // Convert decimal part
        if let dec = decimalPart {
            result += "点"
            for c in dec {
                result += digitToChinese(c)
            }
        }

        return result
    }

    private static func integerToChineseString(_ s: String) -> String {
        guard !s.isEmpty else { return "零" }

        // Remove leading zeros
        let stripped = String(s.drop(while: { $0 == "0" }))
        guard !stripped.isEmpty else { return "零" }

        // For very long numbers, read digit by digit
        if stripped.count > 12 {
            return stripped.map { digitToChinese($0) }.joined()
        }

        let units = ["", "十", "百", "千"]
        let bigUnits = ["", "万", "亿", "兆"]
        let chars = Array(stripped)
        let len = chars.count

        var result = ""
        var needZero = false

        for i in 0..<len {
            let digit = Int(String(chars[i]))!
            let pos = len - 1 - i // power of 10
            let unitIdx = pos % 4
            let bigUnitIdx = pos / 4

            if digit == 0 {
                needZero = true
            } else {
                if needZero {
                    result += "零"
                    needZero = false
                }
                // Handle 十 prefix: 12 → 十二 instead of 一十二
                if digit == 1 && unitIdx == 1 && len == 2 && i == 0 {
                    // Skip "一"
                } else {
                    result += digitToChinese(chars[i])
                }
                result += units[unitIdx]
            }

            if unitIdx == 0 && bigUnitIdx > 0 {
                // Check if this 4-digit group had any non-zero
                let startChk = max(0, i - 3)
                var groupHasValue = false
                for k in startChk...i {
                    if chars[k] != "0" { groupHasValue = true; break }
                }
                if groupHasValue {
                    result += bigUnits[bigUnitIdx]
                    needZero = false
                }
            }
        }

        return result.isEmpty ? "零" : result
    }

    /// Convert numbers in text to Chinese
    public static func convertNumbers(_ text: String) -> String {
        let pattern = "[-+]?\\d+(?:\\.\\d+)*"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        guard !matches.isEmpty else { return text }

        var result = ""
        var lastPos = 0
        for match in matches {
            let range = match.range
            // Append text before match
            result += nsText.substring(with: NSRange(location: lastPos, length: range.location - lastPos))
            // Convert the number
            let numStr = nsText.substring(with: range)
            result += numberToChinese(numStr)
            lastPos = range.location + range.length
        }
        // Append remaining
        if lastPos < nsText.length {
            result += nsText.substring(from: lastPos)
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
}
