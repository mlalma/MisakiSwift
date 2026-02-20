import Foundation
import CppJieba

/// Swift wrapper around the C bridge to cppjieba
public final class JiebaWrapper {
    private let handle: JiebaHandle

    /// Initialize Jieba with dictionary file paths
    public init(dictPath: String, hmmModelPath: String, userDictPath: String,
                idfPath: String, stopWordPath: String) throws {
        guard let h = jieba_create(dictPath, hmmModelPath, userDictPath, idfPath, stopWordPath) else {
            throw JiebaError.initializationFailed
        }
        self.handle = h
    }

    deinit {
        jieba_destroy(handle)
    }

    /// POS tagging: returns array of (word, tag) pairs
    public func tag(_ sentence: String) -> [(word: String, tag: String)] {
        let result = jieba_tag(handle, sentence)
        defer { jieba_free_tag_result(result) }

        var pairs: [(String, String)] = []
        pairs.reserveCapacity(result.count)

        for i in 0..<result.count {
            let w = result.words[i]
            let word = String(cString: w.word)
            let tag = String(cString: w.tag)
            pairs.append((word, tag))
        }
        return pairs
    }

    /// Word segmentation
    public func cut(_ sentence: String, useHMM: Bool = true) -> [String] {
        let result = jieba_cut(handle, sentence, useHMM ? 1 : 0)
        defer { jieba_free_cut_result(result) }

        var words: [String] = []
        words.reserveCapacity(result.count)

        for i in 0..<result.count {
            if let w = result.words[i] {
                words.append(String(cString: w))
            }
        }
        return words
    }

    /// Cut for search (sub-word segmentation, like jieba.cut_for_search in Python)
    public func cutForSearch(_ sentence: String, useHMM: Bool = true) -> [String] {
        let result = jieba_cut_for_search(handle, sentence, useHMM ? 1 : 0)
        defer { jieba_free_cut_result(result) }

        var words: [String] = []
        words.reserveCapacity(result.count)

        for i in 0..<result.count {
            if let w = result.words[i] {
                words.append(String(cString: w))
            }
        }
        return words
    }
}

public enum JiebaError: Error {
    case initializationFailed
}
