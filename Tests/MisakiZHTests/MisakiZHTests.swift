import XCTest
import MLXUtilsLibrary
@testable import MisakiZH

final class MisakiZHTests: XCTestCase {

    nonisolated(unsafe) static var g2p: ZHG2P!

    override class func setUp() {
        super.setUp()
        do {
            g2p = try ZHG2P()
        } catch {
            XCTFail("Failed to initialize ZHG2P: \(error)")
        }
    }

    // MARK: - Pinyin Parsing

    func testParsePinyin() {
        let parts = ZHG2P.parsePinyin("zhong1")
        XCTAssertEqual(parts.initial, "zh")
        XCTAssertEqual(parts.final, "ong")
        XCTAssertEqual(parts.tone, 1)
    }

    func testParsePinyinWithToneMark() {
        let parts = ZHG2P.parsePinyin("nǐ")
        XCTAssertEqual(parts.initial, "n")
        XCTAssertEqual(parts.final, "i")
        XCTAssertEqual(parts.tone, 3)
    }

    func testParsePinyinYu() {
        let parts = ZHG2P.parsePinyin("yu3")
        XCTAssertEqual(parts.initial, "")
        XCTAssertEqual(parts.final, "ü")
        XCTAssertEqual(parts.tone, 3)
    }

    func testParsePinyinWo() {
        let parts = ZHG2P.parsePinyin("wo3")
        XCTAssertEqual(parts.initial, "")
        XCTAssertEqual(parts.final, "uo")
        XCTAssertEqual(parts.tone, 3)
    }

    // MARK: - Py2IPA

    func testPy2IPA_Simple() {
        let ipa = ZHG2P.py2ipa("ni3")
        XCTAssertFalse(ipa.isEmpty, "IPA should not be empty for ni3")
        // ni3 should produce something like: n + i + third tone marker → ni↓
        XCTAssertTrue(ipa.contains("n"), "Should contain 'n'")
        print("ni3 -> \(ipa)")
    }

    func testPy2IPA_Zhong1() {
        let ipa = ZHG2P.py2ipa("zhong1")
        XCTAssertFalse(ipa.isEmpty)
        print("zhong1 -> \(ipa)")
    }

    // MARK: - Map Punctuation

    func testMapPunctuation() {
        let result = ZHG2P.mapPunctuation("你好，世界！")
        // Swift converts Chinese punctuation to ASCII equivalents
        XCTAssertTrue(result.contains(","), "Should convert ， to ,")
        XCTAssertTrue(result.contains("!"), "Should convert ！ to !")
    }

    // MARK: - Number Conversion

    func testNumberToChinese() {
        XCTAssertEqual(StringUtils.numberToChinese("123"), "一百二十三")
        XCTAssertEqual(StringUtils.numberToChinese("0"), "零")
        XCTAssertEqual(StringUtils.numberToChinese("-5"), "负五")
        XCTAssertEqual(StringUtils.numberToChinese("3.14"), "三点一四")
    }

    func testConvertNumbers() {
        let result = StringUtils.convertNumbers("这里有500个苹果")
        XCTAssertTrue(result.contains("五百"), "Should convert 500 to 五百")
        XCTAssertFalse(result.contains("500"), "Should not contain original number")
    }

    // MARK: - Full G2P Pipeline

    func testChineseG2P() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("你好")
        XCTAssertEqual(result, "ni↗xau̯↓")
        print("你好 -> \(result)")
    }

    func testChineseSentence() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("你好世界")
        XCTAssertEqual(result, "ni↗xau̯↓ ʂɨ↘ʨje↘")
        print("你好世界 -> \(result)")
    }

    func testChineseWithPunctuation() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("你好，世界！")
        // Punctuation should be surrounded by spaces for proper TTS pauses
        XCTAssertTrue(result.contains(","), "Should contain comma for pause")
        XCTAssertTrue(result.contains("!"), "Should contain exclamation for pause")
        // Verify phoneme content is correct (space-agnostic)
        let stripped = result.replacingOccurrences(of: " ", with: "")
        XCTAssertEqual(stripped, "ni↗xau̯↓,ʂɨ↘ʨje↘!")
        // Verify spaces exist around punctuation
        XCTAssertTrue(result.contains(" ,") || result.contains(", "), "Comma should have adjacent spaces for TTS pause")
        print("你好，世界！ -> \(result)")
    }

    func testChineseWithNumbers() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("这里有500个苹果")
        print(result)

        // Compare phoneme content (space-agnostic, since word boundaries may vary)
        let stripped = result.replacingOccurrences(of: " ", with: "")
        XCTAssertEqual(stripped, "ʈʂɤ↘li↓jou̯↓u↗pai̯↓kɤpʰi↗ŋkwo↓")
        print("这里有500个苹果 -> \(result)")
    }

    func testMixedChineseEnglish() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("你好Hello世界")
        XCTAssertEqual(result, "ni↗xau̯↓ həlˈO ʂɨ↘ʨje↘")
        print("你好Hello世界 -> \(result)")
    }

    func testLongerText() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("中华人民共和国是一个伟大的国家")
        // Compare phoneme content (space-agnostic, since word boundaries may vary)
        let stripped = result.replacingOccurrences(of: " ", with: "")
        XCTAssertEqual(stripped, "ʈʂʊ→ŋxwa↗ɻə↗nmi↗nkʊ↘ŋxɤ↗kwo↗ʂɨ↘i↗kɤwei̯↓ta↘tɤkwo↗ʨja→")
        // Verify that spaces are present (word boundaries)
        XCTAssertTrue(result.contains(" "), "Should contain spaces between words for natural TTS phrasing")
        print("中华人民共和国是一个伟大的国家 -> \(result)")
    }

    func testEmptyString() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("")
        XCTAssertTrue(result.isEmpty)
    }

    func testRetone() {
        let result = ZHG2P.retone("ni˧˩˧")
        XCTAssertEqual(result, "ni↓")

        let result2 = ZHG2P.retone("ma˥")
        XCTAssertEqual(result2, "ma→")

        let result3 = ZHG2P.retone("ma˧˥")
        XCTAssertEqual(result3, "ma↗")

        let result4 = ZHG2P.retone("ma˥˩")
        XCTAssertEqual(result4, "ma↘")
    }

    func testToneSandhi_BuBeforeTone4() {
        // 不对 (bù duì) → Python output
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("不对")
        XCTAssertEqual(result, "pu↗twei̯↘")
        print("不对 -> \(result)")
    }

    func testToneSandhi_ThirdTone() {
        // 你好 (nǐ hǎo) → Swift applies 3+3 sandhi: first tone 3 becomes tone 2 (↗)
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("你好")
        XCTAssertEqual(result, "ni↗xau̯↓", "你好: first 3rd tone becomes 2nd (↗) before another 3rd tone")
        print("你好 (tone sandhi) -> \(result)")
    }

    // MARK: - MToken Array (Timestamp Support)

    func testMTokenArrayReturned() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, tokens) = g2p.phonemize("你好世界")
        XCTAssertFalse(tokens.isEmpty, "Should return MToken array for timestamp prediction")
        XCTAssertTrue(tokens.count >= 2, "Should have at least 2 tokens for 你好 and 世界")

        // Verify phonemes are set on tokens
        for token in tokens {
            XCTAssertNotNil(token.phonemes, "Each word token should have phonemes set")
            XCTAssertFalse(token.phonemes!.isEmpty, "Phonemes should not be empty")
        }

        // Verify the concatenation of token phonemes + whitespace matches the result
        let reconstructed = tokens.map { ($0.phonemes ?? "") + $0.whitespace }.joined()
        XCTAssertEqual(reconstructed, result, "Concatenated tokens should match the phoneme string")
        print("MToken test: \(tokens.count) tokens for '你好世界'")
    }

    func testMTokenArrayWithPunctuation() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, tokens) = g2p.phonemize("你好，世界！")
        XCTAssertFalse(tokens.isEmpty, "Should return MToken array")

        // Should have tokens for: 你好, comma, 世界, exclamation
        XCTAssertTrue(tokens.count >= 3, "Should have tokens for words and punctuation")

        // Verify punctuation tokens exist
        let hasComma = tokens.contains { $0.phonemes?.contains(",") == true }
        let hasExclamation = tokens.contains { $0.phonemes?.contains("!") == true }
        XCTAssertTrue(hasComma, "Should have a comma token")
        XCTAssertTrue(hasExclamation, "Should have an exclamation token")

        // Verify reconstruction
        let reconstructed = tokens.map { ($0.phonemes ?? "") + $0.whitespace }.joined()
        XCTAssertEqual(reconstructed, result, "Concatenated tokens should match the phoneme string")
        print("MToken punct test: \(tokens.count) tokens for '你好，世界！'")
    }
    
    func testPercentage() {
        guard let g2p = Self.g2p else {
            XCTFail("G2P not initialized")
            return
        }
        let (result, _) = g2p.phonemize("是 90%")
        XCTAssertEqual(result, "ʂɨ↘ pai̯↓fə→nʈʂɨ→ʨiuʂɨ↗")
        print("90% -> \(result)")
    }
}
