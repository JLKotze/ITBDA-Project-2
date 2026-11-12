library(stopwords)
library(tm)
library(topicmodels)
library(wordcloud)
library(RColorBrewer)
library(ggplot2)

#Question 2.1
file2textprep <- function(file_name) {
  t_file <- file(file_name, "r")
  text <- readLines(t_file, warn = FALSE)
  close(t_file)
  
  text_rep <- ""
  n <- length(text)
  for (i in 1:n) {
    text_line <- text[i]
    #lowercase
    text_line <- tolower(text_line)
    #remove non letters
    text_line <- stringr::str_replace_all(text_line, "[^a-zA-Z\\s]", " ")
    #remove unneccesary whitespace
    text_line <- stringr::str_replace_all(text_line, "[\\s]+", " ")
    #remove leading and trailing whitespace
    text_line <- trimws(text_line, which = c("both"))
    if (nchar(text_line) > 1) {
      text_rep <- paste(text_rep, text_line, sep = " ")
    }
  }
  text_rep <- trimws(text_rep, which = c("both"))
  word_list <- stringr::str_split(text_rep, " ")[[1]]
  stop_words <- stopwords("en")
  n_sw <- length(stop_words)
  for (i in 1:n_sw) {
    indexes <- which(word_list == stop_words[i])
    if (length(indexes) > 0){
      word_list <- word_list[-indexes]
    }
  }
  bag_of_words <- unique(word_list)
  res <- list("bag" = bag_of_words, "words" = word_list)
  return(res)
}

prefix <- "D:\\Eduvos Honours\\Big Data Analytics Techniques\\Project 2\\Code\\news\\sa_news\\news_"
filenames <- c("1.txt", "2.txt", "3.txt", "4.txt", "5.txt", 
               "6.txt", "7.txt", "8.txt", "9.txt", "10.txt")

nDoc <- length(filenames)
text_list <- c()
file_list <- c()

for (i in 1:nDoc) {
  file_name <- paste(prefix, filenames[i], sep =  "")
  DocWords <- file2textprep(file_name)
  text_line <- paste(DocWords$bag, collapse = " ")
  text_list <- append(text_list, text_line)
  file_list <- append(file_list, filenames[i])
}

#Dataframe
df <- data.frame(file_name = file_list, content = text_list, stringsAsFactors = FALSE)

corpus <- Corpus(VectorSource(df$content))
dtm <- DocumentTermMatrix(corpus)

#Question 2.2
num_topics <- 5
lda_model <- LDA(dtm, k = num_topics, control = list(seed = 42))
topic_probs <- posterior(lda_model)$terms

topic_dfs <- list()
terms <- terms(lda_model,10)

for(i in 1:num_topics) {
  topic_df <- data.frame(term = terms[, i], probability = as.numeric(topic_probs[i, terms[, i]]))
  topic_df <- topic_df[order(-topic_df$probability), ]
  topic_dfs[[paste("Topic ", i)]] <- topic_df
}

#List top 5 words and their probability
for (i in 1:num_topics) {
  cat("\nTopic", i, ":\n")
  print(head(topic_dfs[[paste("Topic ", i)]], 5))
}

#Question 2.3
#Word cloud
for(i in 1:num_topics) {
  topics <- topic_dfs[[i]]
  
  par(mar = c(1, 1, 4, 1))
  
  wordcloud(words = topic_df$term,
            freq = topic_df$probability,
            min.freq = 1,
            max.words = 30,
            random.order = FALSE,
            rot.per =  0.35,
            colors = brewer.pal(8, "Dark2")
            )
  
  title(main = paste("Word Cloud - Topic", i))
}

#Word importance per topic
for (i in 1:num_topics) {
  topic_df <- topic_dfs[[i]][1:10, ]
  p <- ggplot(topic_df,
              aes(x = reorder(term, probability),
                  y = probability)) +
    geom_col(fill = "steelblue") +
    labs(
      title = paste("Top 10 Words - Topic", i),
      x = "Word",
      y = "Probability"
    )
  print(p)
}
