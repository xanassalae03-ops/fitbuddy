CREATE TABLE IF NOT EXISTS event_reviews (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    event_id INT NOT NULL,
    reviewer_id INT NOT NULL,
    reviewee_id INT NOT NULL,
    rating TINYINT UNSIGNED NOT NULL,
    comment VARCHAR(500) NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_event_review (event_id, reviewer_id, reviewee_id),
    KEY idx_event_reviews_reviewee (reviewee_id),
    KEY idx_event_reviews_event (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;