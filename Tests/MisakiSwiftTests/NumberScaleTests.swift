import Foundation
import Testing
@testable import MisakiSwift

@Test func testLargeNumberNormalization() {
  let converter = EnglishNum2Word()
  let cases: [(Int, String)] = [
    (1000, "one thousand"),
    (999_999, "nine hundred and ninety-nine thousand, nine hundred and ninety-nine"),
    (1_000_000, "one million"),
    (1_000_001, "one million, one"),
    (2_500_000, "two million, five hundred thousand"),
    (3_000_000_000, "three billion"),
    (5_000_000_000_000, "five trillion"),
  ]

  for (number, expected) in cases {
    #expect(converter.convert(Decimal(number)) == expected)
  }
}
