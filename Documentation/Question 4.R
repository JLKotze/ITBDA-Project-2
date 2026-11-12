library(rvest)
library(xml2)
library(purrr)
library(dplyr)
library(stringr)
library(readr)

install.packages("readr")


feed_url <- "https://blog.mozilla.org/en/feed/"

feed <- read_xml(feed_url)

articles <- xml_find_all(feed, ".//item")

article_data <- data.frame(
  title = xml_text(xml_find_first(articles, "./title")),
  url = xml_text(xml_find_first(articles, "./link")),
  publication_date = xml_text(xml_find_first(articles, "./pubDate")),
  stringsAsFactors = FALSE
)

article_data <- head(article_data, 20)

scrape_article <- function(url) {
    page <- xml2::read_html(url)
    
    # Extract paragraph text within the article
    paragraphs <- xml_find_all(page, ".//article//p")
    article_text <- paste(xml_text(paragraphs), collapse = " ")
    
    #Extract author
    author <- xml_text(xml_find_first(page, "//*[contains(@class, 'author')]"))
    
    text <- xml_text(paragraphs)
    
    return(c(author = author, article_text = article_text))
}

article_details <- map_dfr(article_data$url, \(url) {
  details <- scrape_article(url)
  
  data.frame(
    author = unname(details["author"]),
    article_text = unname(details["article_text"])
  )
})

article_data <- bind_cols(article_data, article_details)

#Add identifier
article_data <- article_data |>
  mutate(article_id = row_number())

#Make identifier first column
article_data <- article_data[
  , c("article_id", setdiff(names(article_data), "article_id"))
]

#Add numerical data in form of word count
article_data <- article_data |>
  mutate(
    word_count = str_count(
      coalesce(article_text, ""),
      "\\b[[:alpha:]]+\\b"
    )
  )

#Check if there are missing values
sum(is.na(article_data))


article_data$publication_date
head(article_data$publication_date)

#Change publication date to datetime
article_data$publication_date <- parse_datetime(
  article_data$publication_date,
  format = "%a, %d %b %Y %H:%M:%S %z"
)

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

#Apply text denoising
article_data$article_text <- denoise_text(article_data$article_text)


#Write CSV
write.csv(article_data, "mozilla_articles.csv", row.names = FALSE)
