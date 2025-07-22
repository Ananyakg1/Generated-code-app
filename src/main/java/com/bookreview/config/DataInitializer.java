package com.bookreview.config;

import com.bookreview.model.Book;
import com.bookreview.model.Review;
import com.bookreview.repository.BookRepository;
import com.bookreview.repository.ReviewRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {
    
    @Autowired
    private BookRepository bookRepository;
    
    @Autowired
    private ReviewRepository reviewRepository;
    
    @Override
    public void run(String... args) throws Exception {
        // Check if data already exists
        if (bookRepository.count() > 0) {
            return; // Data already initialized
        }
        
        // Initialize sample books
        Book book1 = new Book();
        book1.setTitle("The Great Gatsby");
        book1.setAuthor("F. Scott Fitzgerald");
        book1.setGenre("Classic Fiction");
        book1.setPublicationYear(1925);
        book1.setIsbn("978-0-7432-7356-5");
        book1.setDescription("A classic American novel that explores themes of decadence, idealism, resistance to change, social upheaval, and excess, creating a portrait of the Jazz Age.");
        book1.setCreatedAt(LocalDateTime.now().minusDays(30));
        
        Book book2 = new Book();
        book2.setTitle("To Kill a Mockingbird");
        book2.setAuthor("Harper Lee");
        book2.setGenre("Classic Fiction");
        book2.setPublicationYear(1960);
        book2.setIsbn("978-0-06-112008-4");
        book2.setDescription("A gripping, heart-wrenching, and wholly remarkable tale of coming-of-age in a South poisoned by virulent prejudice.");
        book2.setCreatedAt(LocalDateTime.now().minusDays(25));
        
        Book book3 = new Book();
        book3.setTitle("1984");
        book3.setAuthor("George Orwell");
        book3.setGenre("Dystopian Fiction");
        book3.setPublicationYear(1949);
        book3.setIsbn("978-0-452-28423-4");
        book3.setDescription("A dystopian social science fiction novel that follows the life of Winston Smith, a low ranking member of 'the Party', who is frustrated by the omnipresent eyes of the party.");
        book3.setCreatedAt(LocalDateTime.now().minusDays(20));
        
        Book book4 = new Book();
        book4.setTitle("Pride and Prejudice");
        book4.setAuthor("Jane Austen");
        book4.setGenre("Romance");
        book4.setPublicationYear(1813);
        book4.setIsbn("978-0-14-143951-8");
        book4.setDescription("A romantic novel of manners that follows the character development of Elizabeth Bennet, the dynamic protagonist who learns about the repercussions of hasty judgments.");
        book4.setCreatedAt(LocalDateTime.now().minusDays(15));
        
        Book book5 = new Book();
        book5.setTitle("The Catcher in the Rye");
        book5.setAuthor("J.D. Salinger");
        book5.setGenre("Coming-of-age Fiction");
        book5.setPublicationYear(1951);
        book5.setIsbn("978-0-316-76948-0");
        book5.setDescription("A controversial novel originally published for adults, it has since become popular with adolescent readers for its themes of teenage rebellion and alienation.");
        book5.setCreatedAt(LocalDateTime.now().minusDays(10));
        
        // Save books
        List<Book> books = bookRepository.saveAll(List.of(book1, book2, book3, book4, book5));
        
        // Initialize sample reviews
        Review review1 = new Review();
        review1.setReviewerName("Alice Johnson");
        review1.setRating(5);
        review1.setComment("A masterpiece of American literature! Fitzgerald's prose is absolutely beautiful, and the story of Jay Gatsby is both tragic and captivating. The themes of the American Dream and social class are explored with incredible depth.");
        review1.setBook(books.get(0));
        review1.setCreatedAt(LocalDateTime.now().minusDays(28));
        
        Review review2 = new Review();
        review2.setReviewerName("Bob Smith");
        review2.setRating(4);
        review2.setComment("Great book with beautiful writing, though sometimes the pacing felt a bit slow. The symbolism is rich and the characters are well-developed. Definitely worth reading for anyone interested in American classics.");
        review2.setBook(books.get(0));
        review2.setCreatedAt(LocalDateTime.now().minusDays(26));
        
        Review review3 = new Review();
        review3.setReviewerName("Carol Williams");
        review3.setRating(5);
        review3.setComment("To Kill a Mockingbird is a powerful and moving story that deals with important themes of racism and moral growth. Harper Lee's storytelling is masterful, and Scout is an unforgettable narrator.");
        review3.setBook(books.get(1));
        review3.setCreatedAt(LocalDateTime.now().minusDays(23));
        
        Review review4 = new Review();
        review4.setReviewerName("David Brown");
        review4.setRating(5);
        review4.setComment("Orwell's 1984 is more relevant today than ever. The concept of Big Brother and thoughtcrime are chilling. A must-read that makes you think about surveillance and freedom in our modern world.");
        review4.setBook(books.get(2));
        review4.setCreatedAt(LocalDateTime.now().minusDays(18));
        
        Review review5 = new Review();
        review5.setReviewerName("Emma Davis");
        review5.setRating(4);
        review5.setComment("1984 is definitely a thought-provoking read. While some parts were intense and disturbing, that's exactly what Orwell intended. The world-building is incredible and the warnings about totalitarianism are important.");
        review5.setBook(books.get(2));
        review5.setCreatedAt(LocalDateTime.now().minusDays(17));
        
        Review review6 = new Review();
        review6.setReviewerName("Frank Miller");
        review6.setRating(4);
        review6.setComment("Jane Austen's wit and social commentary shine in Pride and Prejudice. Elizabeth Bennet is a wonderful character, and the romance with Mr. Darcy is beautifully developed. The dialogue is sharp and entertaining.");
        review6.setBook(books.get(3));
        review6.setCreatedAt(LocalDateTime.now().minusDays(13));
        
        Review review7 = new Review();
        review7.setReviewerName("Grace Wilson");
        review7.setRating(3);
        review7.setComment("The Catcher in the Rye is an interesting character study of teenage angst. Holden Caulfield can be frustrating at times, but that's the point. Not for everyone, but it captures the alienation of adolescence well.");
        review7.setBook(books.get(4));
        review7.setCreatedAt(LocalDateTime.now().minusDays(8));
        
        Review review8 = new Review();
        review8.setReviewerName("Henry Taylor");
        review8.setRating(5);
        review8.setComment("A timeless classic that perfectly captures the confusion and rebellion of teenage years. Salinger's voice through Holden is authentic and memorable. This book stays with you long after you finish reading.");
        review8.setBook(books.get(4));
        review8.setCreatedAt(LocalDateTime.now().minusDays(7));
        
        Review review9 = new Review();
        review9.setReviewerName("Isabel Anderson");
        review9.setRating(5);
        review9.setComment("Pride and Prejudice is simply delightful! The characters are vivid, the plot is engaging, and Austen's writing is both witty and insightful. This book never gets old no matter how many times you read it.");
        review9.setBook(books.get(3));
        review9.setCreatedAt(LocalDateTime.now().minusDays(5));
        
        Review review10 = new Review();
        review10.setReviewerName("Jack Thompson");
        review10.setRating(4);
        review10.setComment("The Great Gatsby is beautifully written with rich symbolism. The green light, the eyes of Doctor T.J. Eckleburg - these images are unforgettable. A profound meditation on the American Dream.");
        review10.setBook(books.get(0));
        review10.setCreatedAt(LocalDateTime.now().minusDays(3));
        
        // Save reviews
        reviewRepository.saveAll(List.of(
            review1, review2, review3, review4, review5,
            review6, review7, review8, review9, review10
        ));
        
        System.out.println("Sample data initialized successfully!");
        System.out.println("Added " + books.size() + " books and 10 reviews.");
    }
}
