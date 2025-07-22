package com.bookreview.repository;

import com.bookreview.model.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BookRepository extends JpaRepository<Book, Long> {
    
    // Find books by title containing keyword (case insensitive)
    List<Book> findByTitleContainingIgnoreCase(String title);
    
    // Find books by author containing keyword (case insensitive)
    List<Book> findByAuthorContainingIgnoreCase(String author);
    
    // Find books by genre
    List<Book> findByGenreContainingIgnoreCase(String genre);
    
    // Find books by publication year
    List<Book> findByPublicationYear(Integer year);
    
    // Find books by publication year range
    List<Book> findByPublicationYearBetween(Integer startYear, Integer endYear);
    
    // Custom query to search books by title or author
    @Query("SELECT b FROM Book b WHERE LOWER(b.title) LIKE LOWER(CONCAT('%', :keyword, '%')) OR LOWER(b.author) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    List<Book> findByTitleOrAuthorContaining(@Param("keyword") String keyword);
    
    // Find books ordered by creation date (newest first)
    List<Book> findAllByOrderByCreatedAtDesc();
    
    // Find books by genre ordered by title
    List<Book> findByGenreContainingIgnoreCaseOrderByTitle(String genre);
}
