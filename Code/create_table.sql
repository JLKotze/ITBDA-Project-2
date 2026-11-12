CREATE TABLE mozilla_articles (
    article_id INTEGER PRIMARY KEY,
    title TEXT,
    url TEXT,
    publication_date TIMESTAMPTZ,
    author TEXT,
    article_text TEXT,
    word_count INTEGER
);