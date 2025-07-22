package com.bookreview.service;

import com.bookreview.model.Review;
import com.bookreview.repository.ReviewRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ReviewService {
    
    @Autowired
    private ReviewRepository reviewRepository;
    
    public List<Review> getAllReviews() {
        return reviewRepository.findLatestReviews();
    }
    
    public Optional<Review> getReviewById(Long id) {
        return reviewRepository.findById(id);
    }
    
    public Review saveReview(Review review) {
        return reviewRepository.save(review);
    }
    
    public void deleteReview(Long id) {
        reviewRepository.deleteById(id);
    }
    
    public List<Review> getReviewsByBookId(Long bookId) {
        return reviewRepository.findByBookIdOrderByCreatedAtDesc(bookId);
    }
    
    public List<Review> getReviewsByReviewerName(String reviewerName) {
        return reviewRepository.findByReviewerNameContainingIgnoreCase(reviewerName);
    }
    
    public List<Review> getReviewsByRating(Integer rating) {
        return reviewRepository.findByRating(rating);
    }
    
    public List<Review> getReviewsByMinRating(Integer minRating) {
        return reviewRepository.findByRatingGreaterThanEqual(minRating);
    }
    
    public Long getReviewCountByBookId(Long bookId) {
        return reviewRepository.countByBookId(bookId);
    }
    
    public Double getAverageRatingByBookId(Long bookId) {
        Double average = reviewRepository.getAverageRatingByBookId(bookId);
        return average != null ? average : 0.0;
    }
    
    public boolean existsById(Long id) {
        return reviewRepository.existsById(id);
    }
    
    public long getTotalReviewCount() {
        return reviewRepository.count();
    }
}
