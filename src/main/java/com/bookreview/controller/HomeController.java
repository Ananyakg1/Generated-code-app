package com.bookreview.controller;

import com.bookreview.service.BookService;
import com.bookreview.service.ReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {
    
    @Autowired
    private BookService bookService;
    
    @Autowired
    private ReviewService reviewService;
    
    @GetMapping("/")
    public String home(Model model) {
        // Get dashboard statistics
        long totalBooks = bookService.getTotalBookCount();
        long totalReviews = reviewService.getTotalReviewCount();
        
        // Get recent books and reviews
        var recentBooks = bookService.getAllBooks().stream().limit(5).toList();
        var recentReviews = reviewService.getAllReviews().stream().limit(5).toList();
        
        model.addAttribute("totalBooks", totalBooks);
        model.addAttribute("totalReviews", totalReviews);
        model.addAttribute("recentBooks", recentBooks);
        model.addAttribute("recentReviews", recentReviews);
        
        return "home";
    }
    
    @GetMapping("/about")
    public String about() {
        return "about";
    }
}
