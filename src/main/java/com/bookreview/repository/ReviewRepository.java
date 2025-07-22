package com.bookreview.repository;

import com.bookreview.model.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {
    
    // Find reviews by book ID
    List<Review> findByBookIdOrderByCreatedAtDesc(Long bookId);
    
    // Find reviews by reviewer name
    List<Review> findByReviewerNameContainingIgnoreCase(String reviewerName);
    
    // Find reviews by rating
    List<Review> findByRating(Integer rating);
    
    // Find reviews with rating greater than or equal to specified value
    List<Review> findByRatingGreaterThanEqual(Integer rating);
    
    // Find latest reviews (limit not directly supported in method names, use custom query)
    @Query("SELECT r FROM Review r ORDER BY r.createdAt DESC")
    List<Review> findLatestReviews();
    
    // Count reviews for a specific book
    Long countByBookId(Long bookId);
    
    // Get average rating for a book
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.book.id = :bookId")
    Double getAverageRatingByBookId(@Param("bookId") Long bookId);
}
