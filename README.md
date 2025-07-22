# Book Review Application

# Java Book Review Application

A comprehensive full-stack Java web application for book reviews, built with Spring Boot, Thymeleaf, and Bootstrap. Features secure Docker containerization and enterprise-grade Kubernetes deployment with automated CI/CD pipelines.

## Features

### 📚 Book Management
- **Add Books**: Create new book entries with detailed information (title, author, genre, publication year, ISBN, description)
- **Edit Books**: Update existing book information
- **Delete Books**: Remove books from the library (also removes associated reviews)
- **Search Books**: Find books by title, author, or use the general search functionality
- **Browse by Genre**: Filter books by genre categories

### ⭐ Review System
- **Write Reviews**: Add detailed reviews with 1-5 star ratings
- **Edit Reviews**: Modify existing reviews
- **Delete Reviews**: Remove reviews when needed
- **View Reviews**: Browse all reviews or filter by book
- **Rating Aggregation**: Automatic calculation of average ratings and review counts

### 🎨 User Interface
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Modern UI**: Clean, intuitive interface built with Bootstrap 5
- **Interactive Elements**: Star rating system, hover effects, and smooth transitions
- **Accessibility**: Proper labeling and keyboard navigation support

### 🔍 Discovery Features
- **Dashboard**: Overview of library statistics and recent activity
- **Search Functionality**: Quick search across books and reviews
- **Related Content**: Suggestions for similar books and reviews
- **Sorting Options**: Various ways to organize and browse content

## Technology Stack

### Backend
- **Java 17** - Modern Java features and performance
- **Spring Boot 3.2.0** - Application framework and auto-configuration
- **Spring Data JPA** - Database abstraction and ORM
- **Spring Web** - RESTful web services and MVC
- **Spring Validation** - Input validation and error handling
- **H2 Database** - In-memory database for development
- **Maven** - Dependency management and build tool

### Frontend
- **Thymeleaf** - Server-side templating engine
- **Bootstrap 5.3.0** - CSS framework for responsive design
- **jQuery 3.7.0** - JavaScript library for DOM manipulation
- **WebJars** - Client-side dependency management
- **Custom CSS** - Additional styling for enhanced user experience

## Quick Start

### Prerequisites
- Java 17 or higher
- Maven 3.6+ (optional, wrapper included)
- Any modern web browser

### Installation & Setup

1. **Clone or download the project**
   ```bash
   cd Generated_java_test
   ```

2. **Install dependencies**
   ```bash
   ./mvnw clean install
   ```

3. **Run the application**
   ```bash
   ./mvnw spring-boot:run
   ```

4. **Access the application**
   - Open your browser and navigate to: `http://localhost:8080`
   - The application will automatically initialize with sample data

### Alternative: Using IDE
1. Import the project into your favorite IDE (IntelliJ IDEA, Eclipse, VS Code)
2. Run the `BookReviewApplication.java` main class
3. Open `http://localhost:8080` in your browser

## Application Structure

```
book-review-app/
├── src/main/java/com/bookreview/
│   ├── BookReviewApplication.java          # Main application class
│   ├── model/
│   │   ├── Book.java                       # Book entity
│   │   └── Review.java                     # Review entity
│   ├── repository/
│   │   ├── BookRepository.java             # Book data access
│   │   └── ReviewRepository.java           # Review data access
│   ├── service/
│   │   ├── BookService.java                # Book business logic
│   │   └── ReviewService.java              # Review business logic
│   ├── controller/
│   │   ├── HomeController.java             # Home page controller
│   │   ├── BookController.java             # Book management
│   │   └── ReviewController.java           # Review management
│   └── config/
│       └── DataInitializer.java            # Sample data setup
├── src/main/resources/
│   ├── application.properties              # Configuration settings
│   └── templates/                          # Thymeleaf templates
│       ├── home.html                       # Dashboard/home page
│       ├── about.html                      # About page
│       ├── layout.html                     # Common layout template
│       ├── books/                          # Book-related pages
│       │   ├── list.html                   # Book listing
│       │   ├── create.html                 # Add new book
│       │   ├── edit.html                   # Edit book
│       │   └── view.html                   # Book details
│       └── reviews/                        # Review-related pages
│           ├── list.html                   # Review listing
│           ├── create.html                 # Write review
│           ├── edit.html                   # Edit review
│           └── view.html                   # Review details
└── pom.xml                                 # Maven configuration
```

## Usage Guide

### Managing Books

1. **Adding a New Book**
   - Click "Add Book" from the navigation or home page
   - Fill in the book details (title and author are required)
   - Click "Add Book" to save

2. **Viewing Book Details**
   - Click on any book title from the books list
   - View complete information, average rating, and all reviews
   - Access edit and delete options from this page

3. **Searching for Books**
   - Use the search bar on the books page
   - Search by title, author, or keywords
   - Results update dynamically

### Writing Reviews

1. **Creating a Review**
   - Click "Write Review" from the navigation or book details page
   - Select a book (if not pre-selected)
   - Enter your name, select a rating (1-5 stars), and write your review
   - Click "Submit Review" to save

2. **Managing Your Reviews**
   - Edit reviews by clicking the "Edit" button on any review
   - Delete reviews using the "Delete" button (confirmation required)
   - View detailed review information on the review details page

### Navigation

- **Home**: Dashboard with statistics and recent activity
- **Books**: Browse all books, search, and add new ones
- **Reviews**: View all reviews and write new ones
- **About**: Information about the application

## Configuration

### Database Configuration
The application uses H2 in-memory database by default. You can access the H2 console at:
- URL: `http://localhost:8080/h2-console`
- JDBC URL: `jdbc:h2:mem:bookreviewdb`
- Username: `sa`
- Password: `password`

### Application Properties
Key configuration options in `application.properties`:
- `server.port=8080` - Application port
- `spring.h2.console.enabled=true` - Enable H2 console
- `spring.jpa.hibernate.ddl-auto=update` - Database schema management

### Sample Data
The application automatically initializes with sample books and reviews on first startup. This includes classic literature with realistic reviews to demonstrate the application's features.

## API Endpoints

### Book Management
- `GET /books` - List all books with search
- `GET /books/new` - Show add book form
- `POST /books/new` - Create new book
- `GET /books/{id}` - View book details
- `GET /books/{id}/edit` - Show edit book form
- `POST /books/{id}/edit` - Update book
- `POST /books/{id}/delete` - Delete book

### Review Management
- `GET /reviews` - List all reviews
- `GET /reviews/new` - Show write review form
- `POST /reviews/new` - Create new review
- `GET /reviews/{id}` - View review details
- `GET /reviews/{id}/edit` - Show edit review form
- `POST /reviews/{id}/edit` - Update review
- `POST /reviews/{id}/delete` - Delete review
- `GET /reviews/book/{bookId}` - List reviews for specific book

### Other Endpoints
- `GET /` - Home dashboard
- `GET /about` - About page

## Development

### Building the Project
```bash
./mvnw clean package
```

### Running Tests
```bash
./mvnw test
```

### Development Mode
The application includes Spring Boot DevTools for automatic restart during development.

## Troubleshooting

### Common Issues

1. **Port 8080 already in use**
   - Change the port in `application.properties`: `server.port=8081`
   - Or kill the process using port 8080

2. **Database connection issues**
   - Check H2 console configuration
   - Verify database URL and credentials

3. **Template not found errors**
   - Ensure Thymeleaf templates are in `src/main/resources/templates/`
   - Check template names match controller mappings

4. **CSS/JavaScript not loading**
   - Verify WebJars dependencies in `pom.xml`
   - Check browser console for 404 errors

### Logging
Enable debug logging by adding to `application.properties`:
```properties
logging.level.com.bookreview=DEBUG
logging.level.org.springframework.web=DEBUG
```

## Future Enhancements

Potential improvements for future versions:
- User authentication and authorization
- Book cover image upload
- Advanced search filters
- Review commenting system
- Book recommendations based on ratings
- Export functionality (PDF, CSV)
- REST API for mobile applications
- Social sharing features
- Reading progress tracking
- Book wishlists and favorites

## Contributing

This is a sample application demonstrating Spring Boot and web development best practices. Feel free to use it as a starting point for your own projects or extend it with additional features.

## License

This project is open source and available under the MIT License.

---

**Book Review Application** - Built with ❤️ using Spring Boot and Bootstrap
