package com.bookreview.controller;

import com.bookreview.model.Book;
import com.bookreview.model.Review;
import com.bookreview.service.BookService;
import com.bookreview.service.ReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Optional;

@Controller
@RequestMapping("/reviews")
public class ReviewController {
    
    @Autowired
    private ReviewService reviewService;
    
    @Autowired
    private BookService bookService;
    
    @GetMapping
    public String listReviews(Model model) {
        List<Review> reviews = reviewService.getAllReviews();
        model.addAttribute("reviews", reviews);
        return "reviews/list";
    }
    
    @GetMapping("/book/{bookId}")
    public String reviewsByBook(@PathVariable Long bookId, Model model) {
        Optional<Book> bookOpt = bookService.getBookById(bookId);
        if (bookOpt.isEmpty()) {
            return "redirect:/books";
        }
        
        List<Review> reviews = reviewService.getReviewsByBookId(bookId);
        model.addAttribute("reviews", reviews);
        model.addAttribute("book", bookOpt.get());
        return "reviews/list";
    }
    
    @GetMapping("/new")
    public String showCreateForm(@RequestParam(required = false) Long bookId, Model model) {
        Review review = new Review();
        model.addAttribute("review", review);
        
        if (bookId != null) {
            Optional<Book> bookOpt = bookService.getBookById(bookId);
            if (bookOpt.isPresent()) {
                model.addAttribute("selectedBook", bookOpt.get());
            }
        }
        
        List<Book> books = bookService.getAllBooks();
        model.addAttribute("books", books);
        return "reviews/create";
    }
    
    @PostMapping("/new")
    public String createReview(@Valid @ModelAttribute Review review,
                             @RequestParam Long bookId,
                             BindingResult result,
                             Model model,
                             RedirectAttributes redirectAttributes) {
        
        if (result.hasErrors()) {
            List<Book> books = bookService.getAllBooks();
            model.addAttribute("books", books);
            Optional<Book> bookOpt = bookService.getBookById(bookId);
            if (bookOpt.isPresent()) {
                model.addAttribute("selectedBook", bookOpt.get());
            }
            return "reviews/create";
        }
        
        Optional<Book> bookOpt = bookService.getBookById(bookId);
        if (bookOpt.isEmpty()) {
            redirectAttributes.addFlashAttribute("errorMessage", "Book not found!");
            return "redirect:/books";
        }
        
        review.setBook(bookOpt.get());
        reviewService.saveReview(review);
        redirectAttributes.addFlashAttribute("successMessage", "Review created successfully!");
        return "redirect:/books/" + bookId;
    }
    
    @GetMapping("/{id}")
    public String viewReview(@PathVariable Long id, Model model) {
        Optional<Review> reviewOpt = reviewService.getReviewById(id);
        if (reviewOpt.isEmpty()) {
            return "redirect:/reviews";
        }
        
        model.addAttribute("review", reviewOpt.get());
        return "reviews/view";
    }
    
    @GetMapping("/{id}/edit")
    public String showEditForm(@PathVariable Long id, Model model) {
        Optional<Review> reviewOpt = reviewService.getReviewById(id);
        if (reviewOpt.isEmpty()) {
            return "redirect:/reviews";
        }
        
        model.addAttribute("review", reviewOpt.get());
        return "reviews/edit";
    }
    
    @PostMapping("/{id}/edit")
    public String updateReview(@PathVariable Long id,
                             @Valid @ModelAttribute Review review,
                             BindingResult result,
                             RedirectAttributes redirectAttributes) {
        
        if (result.hasErrors()) {
            return "reviews/edit";
        }
        
        Optional<Review> existingReviewOpt = reviewService.getReviewById(id);
        if (existingReviewOpt.isEmpty()) {
            return "redirect:/reviews";
        }
        
        Review existingReview = existingReviewOpt.get();
        review.setId(id);
        review.setBook(existingReview.getBook());
        review.setCreatedAt(existingReview.getCreatedAt());
        
        reviewService.saveReview(review);
        redirectAttributes.addFlashAttribute("successMessage", "Review updated successfully!");
        return "redirect:/reviews/" + id;
    }
    
    @PostMapping("/{id}/delete")
    public String deleteReview(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        Optional<Review> reviewOpt = reviewService.getReviewById(id);
        if (reviewOpt.isPresent()) {
            Long bookId = reviewOpt.get().getBook().getId();
            reviewService.deleteReview(id);
            redirectAttributes.addFlashAttribute("successMessage", "Review deleted successfully!");
            return "redirect:/books/" + bookId;
        }
        return "redirect:/reviews";
    }
}
