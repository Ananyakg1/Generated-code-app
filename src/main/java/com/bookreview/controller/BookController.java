package com.bookreview.controller;

import com.bookreview.model.Book;
import com.bookreview.service.BookService;
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
@RequestMapping("/books")
public class BookController {
    
    @Autowired
    private BookService bookService;
    
    @GetMapping
    public String listBooks(@RequestParam(required = false) String search, Model model) {
        List<Book> books;
        if (search != null && !search.trim().isEmpty()) {
            books = bookService.searchBooks(search);
            model.addAttribute("search", search);
        } else {
            books = bookService.getAllBooks();
        }
        model.addAttribute("books", books);
        return "books/list";
    }
    
    @GetMapping("/new")
    public String showCreateForm(Model model) {
        model.addAttribute("book", new Book());
        return "books/create";
    }
    
    @PostMapping("/new")
    public String createBook(@Valid @ModelAttribute Book book, 
                           BindingResult result, 
                           RedirectAttributes redirectAttributes) {
        if (result.hasErrors()) {
            return "books/create";
        }
        
        bookService.saveBook(book);
        redirectAttributes.addFlashAttribute("successMessage", "Book created successfully!");
        return "redirect:/books";
    }
    
    @GetMapping("/{id}")
    public String viewBook(@PathVariable Long id, Model model) {
        Optional<Book> bookOpt = bookService.getBookById(id);
        if (bookOpt.isEmpty()) {
            return "redirect:/books";
        }
        
        model.addAttribute("book", bookOpt.get());
        return "books/view";
    }
    
    @GetMapping("/{id}/edit")
    public String showEditForm(@PathVariable Long id, Model model) {
        Optional<Book> bookOpt = bookService.getBookById(id);
        if (bookOpt.isEmpty()) {
            return "redirect:/books";
        }
        
        model.addAttribute("book", bookOpt.get());
        return "books/edit";
    }
    
    @PostMapping("/{id}/edit")
    public String updateBook(@PathVariable Long id, 
                           @Valid @ModelAttribute Book book, 
                           BindingResult result,
                           RedirectAttributes redirectAttributes) {
        if (result.hasErrors()) {
            return "books/edit";
        }
        
        book.setId(id);
        bookService.saveBook(book);
        redirectAttributes.addFlashAttribute("successMessage", "Book updated successfully!");
        return "redirect:/books/" + id;
    }
    
    @PostMapping("/{id}/delete")
    public String deleteBook(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        if (bookService.existsById(id)) {
            bookService.deleteBook(id);
            redirectAttributes.addFlashAttribute("successMessage", "Book deleted successfully!");
        }
        return "redirect:/books";
    }
    
    @GetMapping("/genre/{genre}")
    public String booksByGenre(@PathVariable String genre, Model model) {
        List<Book> books = bookService.getBooksByGenre(genre);
        model.addAttribute("books", books);
        model.addAttribute("genre", genre);
        return "books/list";
    }
}
