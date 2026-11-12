library(rvest)
library(xml2)
library(lexRankr)
library(tidytext)
library(dplyr)
library(tm)
library(ggplot2)

#Question 3.1
# Read URL
page <- xml2::read_html("https://www.eurac.edu/en/blogs/connecting-the-dots/can-language-become-environmental-data")

# Read only the content of the article
texts <- page |>
  rvest::html_elements("p") |>
  rvest::html_text() |>
  (\(x) x[nchar(trimws(x)) > 0])()

# Elements of p which only contain the content of the article
texts <- texts[1:6]

# Creates data structure for texts
df <- data.frame(
  element_id = seq_along(texts),
  text = texts
)

#Question 3.2
# Text denoise
denoise_text <- function(text) {
  text <- as.character(text)
  
  # Remove URLs
  text <- stringr::str_remove_all(text, "https?://\\S+|www\\.\\S+")
  
  # Remove HTML tags
  text <- stringr::str_remove_all(text, "<[^>]+>")
  
  # Remove special characters, keeping punctuation
  text <- stringr::str_replace_all(text, "[^[:alnum:][:space:][:punct:]]", "")
  
  # Remove unneccesary whitespace
  text <- stringr::str_replace_all(text, "[\\s]+", " ")
  
  # Remove empty strings
  text <- text[text != ""]
  
  return(text)
}

df$text <- denoise_text(df$text)


#Question 3.3
# Summarization Technique 1: lexRankr i.e Graph-Based algorithm
top3 <- lexRankr::lexRank(df$text, docId = rep(1, length(df$text)), n = 3, continuous = TRUE)

ordered_summary <- top3 |>
  dplyr::mutate(
    sentenceId = as.numeric(stringr::str_remove_all(sentenceId, ".*_"))
  ) |>
  dplyr::arrange(sentenceId) |>
  dplyr::pull(sentence)

top3

#Print summary
cat(ordered_summary, sep = "\n")

top3_plot <- as.data.frame(top3)

#Sentence Importance plot
ggplot(top3_plot,
       aes(x = reorder(sentenceId, value),
           y = value)) +
  geom_col(fill = "steelblue") +
  labs(
    title = "Top 3 Sentence Importance Scores - LexRank",
    x = "Sentence",
    y = "LexRank Score"
  )

# Summarization Technique 2: TF-IDF
# Combine into full text
full_text <- paste(df$text, collapse = " ")

sentences <- unlist(
  strsplit(full_text, "(?<=[.!?])\\s+", perl = TRUE)
)
# Create a sentence-level data frame
sents_df <- data.frame(
  sentence_id = seq_along(sentences),
  text        = sentences,
  stringsAsFactors = FALSE
)

# Tokenise to word level
words_df <- sents_df |>
  tidytext::unnest_tokens(word, text) |>
  dplyr::filter(!word %in% tidytext::stop_words$word) |>  # remove stop words
  dplyr::count(sentence_id, word, name = "n")

# Compute TF-IDF (treating each sentence as a "document")
tfidf_df <- words_df |>
  tidytext::bind_tf_idf(word, sentence_id, n)

sent_scores <- tfidf_df |>
  dplyr::group_by(sentence_id) |>
  dplyr::summarise(tfidf_score = sum(tf_idf), .groups = "drop") |>
  dplyr::arrange(desc(tfidf_score))

top_indices <- head(sent_scores$sentence_id, 3)

# Extract the corresponding sentences
top_sentences <- sentences[top_indices]

# Print summary
cat(top_sentences, sep = "\n")

# Select top 3 sentences
top3_tfidf <- head(sent_scores, 3)

# Create sentence labels
top3_tfidf$sentence_label <- paste("Sentence", top3_tfidf$sentence_id)

# Plot
ggplot(top3_tfidf,
       aes(x = reorder(sentence_label, tfidf_score),
           y = tfidf_score)) +
  geom_col(fill = "darkorange") +
  labs(
    title = "Top 3 Sentence Importance Scores - TF-IDF",
    x = "Sentence",
    y = "TF-IDF Score"
  )



