import Testing
@testable import MisakiSwift

let texts: [(originalText: String, britishPhonetization: String, americanPhoneitization: String)] = [
  ("[Misaki](/misˈɑki/) is a G2P engine designed for [Kokoro](/kˈOkəɹO/) models.",
   "misˈɑki ɪz ɐ ʤˈiːtəpˈiː ˈɛnʤɪn dɪzˈInd fɔː kˈOkəɹO mˈɒdᵊlz.",
   "misˈɑki ɪz ɐ ʤˈitəpˈi ˈɛnʤən dəzˈInd fɔɹ kˈOkəɹO mˈɑdᵊlz."),
  ("“To James Mortimer, M.R.C.S., from his friends of the C.C.H.,” was engraved upon it, with the date “1884.”",
   "“tə ʤˈAmz mˈɔːtɪmə, ˌɛmˌɑːsˌiːˈɛs, fɹɒm hɪz fɹˈɛndz ɒv ðə sˌiːsˌiːˈAʧ,” wɒz ɪnɡɹˈAvd əpˈɒn ɪt, wɪð ðə dˈAt “ˌAtˈiːn ˈAti fˈɔː.”",
   "“tə ʤˈAmz mˈɔɹTəməɹ, ˌɛmˌɑɹsˌiˈɛs, fɹʌm hɪz fɹˈɛndz ʌv ðə sˌisˌiˈAʧ,” wʌz ɪnɡɹˈAvd əpˈɑn ɪt, wɪð ðə dˈAt “ˌAtˈin ˈATi fˈɔɹ.”")
]

@Test func testStrings_BritishPhonetization() async throws {
  let englishG2P = EnglishG2P(british: true)
  
  for pair in texts {
    #expect(englishG2P.phonemize(text: pair.0).0 == pair.1)
  }
}

@Test func testStrings_AmericanPhonetization() async throws {
  let englishG2P = EnglishG2P(british: false)

  for pair in texts {
    #expect(englishG2P.phonemize(text: pair.0).0 == pair.2)
  }
}

// Retokenize Currency Index Fix Tests
@Test func testRetokenize_CurrencyWithFollowingTokens() async throws {
  let englishG2P = EnglishG2P(british: true)
  let (result, _) = englishG2P.phonemize(text: "$50 is the price for this item")
  #expect(!result.isEmpty)
  #expect(result.contains("dˈɒlə"))  // "dollar" phoneme should be present
}

// Currency appearing mid-sentence with multiple tokens before and after
@Test func testRetokenize_CurrencyInMiddleOfSentence() async throws {
  let englishG2P = EnglishG2P(british: false)
  let (result, _) = englishG2P.phonemize(text: "The total cost was $100 and we paid it yesterday")
  #expect(!result.isEmpty)
  #expect(result.contains("dˈɑləɹz"))  // American "dollar" phoneme
}

// Multiple currency symbols trigger the currency code path multiple times
@Test func testRetokenize_MultipleCurrenciesInText() async throws {
  let englishG2P = EnglishG2P(british: true)
  let (result, _) = englishG2P.phonemize(text: "I exchanged $200 for €150 at the bank today")
  #expect(!result.isEmpty)
  #expect(result.contains("dˈɒlə"))    // "dollar" phoneme
  #expect(result.contains("jˈʊəɹQz"))  // "euro" phoneme
}

// Decimal Parsing Tests
//
// A written decimal must be parsed as base-10 text. Double("1971.13") is a
// binary approximation equal to 1971.130000000000512, and toDecimal reads
// every fractional digit it is given, so routing the text through Double made
// the voice say "point one three zero zero zero zero zero zero zero zero zero
// zero five one two".
@Test func testDecimal_FractionalDigitsAreReadAsWritten() async throws {
  let englishG2P = EnglishG2P(british: false)
  let (result, _) = englishG2P.phonemize(text: "The dose is 1971.13 mg")
  #expect(!result.isEmpty)
  // "zero" is zˈɪɹO. 1971.13 has no zero in it; the binary expansion had ten.
  #expect(!result.contains("zˈɪɹO"))
}

@Test func testDecimal_ZerosThatAreActuallyWrittenAreStillRead() async throws {
  let englishG2P = EnglishG2P(british: false)
  let (result, _) = englishG2P.phonemize(text: "100.001")
  #expect(result.contains("pYnt"))
  // Two written zeros, and exactly two.
  #expect(result.components(separatedBy: "zˈɪɹO").count - 1 == 2)
}
