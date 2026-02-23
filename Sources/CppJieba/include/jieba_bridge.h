//
//  jieba_bridge.h
//  MisakiSwift
//
//  Created by mani on 20/02/26.
//

#ifndef JIEBA_BRIDGE_H
#define JIEBA_BRIDGE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle for Jieba instance
typedef void* JiebaHandle;

// A tagged word (word + POS tag)
typedef struct {
    const char* word;
    const char* tag;
} JiebaTaggedWord;

// Result of Tag() call
typedef struct {
    JiebaTaggedWord* words;
    size_t count;
} JiebaTagResult;

// Create a Jieba instance with dictionary paths
JiebaHandle jieba_create(const char* dict_path,
                         const char* hmm_model_path,
                         const char* user_dict_path,
                         const char* idf_path,
                         const char* stop_word_path);

// Destroy a Jieba instance
void jieba_destroy(JiebaHandle handle);

// POS tagging: returns tagged words
JiebaTagResult jieba_tag(JiebaHandle handle, const char* sentence);

// Free a tag result
void jieba_free_tag_result(JiebaTagResult result);

// Word segmentation (Cut)
typedef struct {
    char** words;
    size_t count;
} JiebaCutResult;

JiebaCutResult jieba_cut(JiebaHandle handle, const char* sentence, int use_hmm);
void jieba_free_cut_result(JiebaCutResult result);

// Cut for search (returns sub-word segmentation for longer words)
JiebaCutResult jieba_cut_for_search(JiebaHandle handle, const char* sentence, int use_hmm);

#ifdef __cplusplus
}
#endif

#endif // JIEBA_BRIDGE_H
