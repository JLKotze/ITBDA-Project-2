SELECT
    CASE
        WHEN word_count < 500 THEN 'Short'
        WHEN word_count BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Long'
    END AS article_length,
    COUNT(*) AS article_count,
    ROUND(AVG(word_count), 0) AS average_word_count
FROM mozilla_articles
WHERE word_count IS NOT NULL
GROUP BY article_length
ORDER BY article_count DESC;