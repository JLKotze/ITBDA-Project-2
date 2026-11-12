SELECT
    TO_CHAR(publication_date, 'Day') AS day_of_week,
    COUNT(*) AS article_count
FROM mozilla_articles
WHERE publication_date IS NOT NULL
GROUP BY TO_CHAR(publication_date, 'Day'),
         EXTRACT(DOW FROM publication_date)
ORDER BY EXTRACT(DOW FROM publication_date);