import Foundation
import Testing
@testable import MisakiSwift

@Test func cardinalNumbersInTheTwentiesIncludeTheTensWord() {
  let numberConverter = EnglishNum2Word()

  #expect(numberConverter.convert(Decimal(22)) == "twenty-two")
  #expect(numberConverter.convert(Decimal(26)) == "twenty-six")
}

@Test func fourDigitYearIncludesBothTwoDigitGroups() {
  let numberConverter = EnglishNum2Word()

  #expect(numberConverter.convert(Decimal(2026), to: .year) == "twenty twenty-six")
}

@Test func threeDigitNumberKeepsCardinalHundredsPronunciation() {
  let numberConverter = EnglishNum2Word()

  #expect(numberConverter.convert(Decimal(376)) == "three hundred and seventy-six")
}

@Test func decimalPointSeparatesTheFractionalDigits() {
  let numberConverter = EnglishNum2Word()

  #expect(numberConverter.convert(Decimal(string: "20.26") ?? 0) == "twenty point two six")
}
