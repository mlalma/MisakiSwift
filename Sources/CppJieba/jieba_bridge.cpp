//
//  jieba_bridge.cpp
//  MisakiSwift
//
//  Created by mani on 20/02/26.
//

#include "jieba_bridge.h"
#include "cppjieba/include/cppjieba/Jieba.hpp"
#include <string>
#include <vector>
#include <cstring>
#include <cstdlib>

// Helper to duplicate a C string
static char* strdup_safe(const std::string& s) {
    char* result = (char*)malloc(s.size() + 1);
    if (result) {
        memcpy(result, s.c_str(), s.size() + 1);
    }
    return result;
}

extern "C" {

JiebaHandle jieba_create(const char* dict_path,
                         const char* hmm_model_path,
                         const char* user_dict_path,
                         const char* idf_path,
                         const char* stop_word_path) {
    try {
        auto* jieba = new cppjieba::Jieba(
            dict_path ? dict_path : "",
            hmm_model_path ? hmm_model_path : "",
            user_dict_path ? user_dict_path : "",
            idf_path ? idf_path : "",
            stop_word_path ? stop_word_path : ""
        );
        return (JiebaHandle)jieba;
    } catch (...) {
        return NULL;
    }
}

void jieba_destroy(JiebaHandle handle) {
    if (handle) {
        delete static_cast<cppjieba::Jieba*>(handle);
    }
}

JiebaTagResult jieba_tag(JiebaHandle handle, const char* sentence) {
    JiebaTagResult result = {NULL, 0};
    if (!handle || !sentence) return result;

    auto* jieba = static_cast<cppjieba::Jieba*>(handle);
    std::vector<std::pair<std::string, std::string>> tag_words;
    jieba->Tag(sentence, tag_words);

    if (tag_words.empty()) return result;

    result.count = tag_words.size();
    result.words = (JiebaTaggedWord*)malloc(sizeof(JiebaTaggedWord) * result.count);
    if (!result.words) {
        result.count = 0;
        return result;
    }

    for (size_t i = 0; i < tag_words.size(); ++i) {
        result.words[i].word = strdup_safe(tag_words[i].first);
        result.words[i].tag = strdup_safe(tag_words[i].second);
    }

    return result;
}

void jieba_free_tag_result(JiebaTagResult result) {
    if (result.words) {
        for (size_t i = 0; i < result.count; ++i) {
            free((void*)result.words[i].word);
            free((void*)result.words[i].tag);
        }
        free(result.words);
    }
}

static JiebaCutResult make_cut_result(const std::vector<std::string>& words) {
    JiebaCutResult result = {NULL, 0};
    if (words.empty()) return result;
    result.count = words.size();
    result.words = (char**)malloc(sizeof(char*) * result.count);
    if (!result.words) { result.count = 0; return result; }
    for (size_t i = 0; i < words.size(); ++i) {
        result.words[i] = strdup_safe(words[i]);
    }
    return result;
}

JiebaCutResult jieba_cut(JiebaHandle handle, const char* sentence, int use_hmm) {
    JiebaCutResult result = {NULL, 0};
    if (!handle || !sentence) return result;

    auto* jieba = static_cast<cppjieba::Jieba*>(handle);
    std::vector<std::string> words;
    jieba->Cut(sentence, words, use_hmm != 0);

    if (words.empty()) return result;

    result.count = words.size();
    result.words = (char**)malloc(sizeof(char*) * result.count);
    if (!result.words) {
        result.count = 0;
        return result;
    }

    for (size_t i = 0; i < words.size(); ++i) {
        result.words[i] = strdup_safe(words[i]);
    }

    return result;
}

void jieba_free_cut_result(JiebaCutResult result) {
    if (result.words) {
        for (size_t i = 0; i < result.count; ++i) {
            free(result.words[i]);
        }
        free(result.words);
    }
}

JiebaCutResult jieba_cut_for_search(JiebaHandle handle, const char* sentence, int use_hmm) {
    if (!handle || !sentence) { JiebaCutResult r = {NULL, 0}; return r; }
    auto* jieba = static_cast<cppjieba::Jieba*>(handle);
    std::vector<std::string> words;
    jieba->CutForSearch(sentence, words, use_hmm != 0);
    return make_cut_result(words);
}

} // extern "C"
