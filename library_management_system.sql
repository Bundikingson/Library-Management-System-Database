-- Library Management System Database
-- This database tracks books, authors, publishers, library members, and borrowing activities

-- Create database
CREATE DATABASE IF NOT EXISTS LibraryManagementSystem;
USE LibraryManagementSystem;

-- Publisher table (1-M relationship with Books)
CREATE TABLE Publisher (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(100),
    established_date DATE,
    CONSTRAINT chk_publisher_email CHECK (email LIKE '%@%.%')
);

-- Author table (M-M relationship with Books through Book_Author)
CREATE TABLE Author (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    CONSTRAINT unq_author_name UNIQUE (first_name, last_name)
);

-- Genre table (M-M relationship with Books through Book_Genre)
CREATE TABLE Genre (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

-- Book table (1-M with Publisher, M-M with Author and Genre)
CREATE TABLE Book (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    publisher_id INT NOT NULL,
    publication_date DATE,
    edition INT DEFAULT 1,
    page_count INT,
    language VARCHAR(30),
    description TEXT,
    price DECIMAL(10,2),
    stock_quantity INT NOT NULL DEFAULT 0,
    available_quantity INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES Publisher(publisher_id),
    CONSTRAINT chk_book_quantities CHECK (available_quantity <= stock_quantity AND available_quantity >= 0),
    CONSTRAINT chk_book_isbn CHECK (LENGTH(isbn) >= 10)
);

-- Book_Author junction table (M-M relationship)
CREATE TABLE Book_Author (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    contribution_type VARCHAR(50) DEFAULT 'Primary',
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book FOREIGN KEY (book_id) REFERENCES Book(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES Author(author_id) ON DELETE CASCADE
);

-- Book_Genre junction table (M-M relationship)
CREATE TABLE Book_Genre (
    book_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (book_id, genre_id),
    CONSTRAINT fk_bg_book FOREIGN KEY (book_id) REFERENCES Book(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_bg_genre FOREIGN KEY (genre_id) REFERENCES Genre(genre_id) ON DELETE CASCADE
);

-- Member table (1-M relationship with Borrowing)
CREATE TABLE Member (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    library_card_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other'),
    address VARCHAR(200) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'United States',
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    registration_date DATE NOT NULL,
    membership_expiry_date DATE NOT NULL,
    membership_status ENUM('Active', 'Expired', 'Suspended') DEFAULT 'Active',
    CONSTRAINT chk_member_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_member_dates CHECK (membership_expiry_date >= registration_date)
);

-- Staff table
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    address VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    last_login DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_staff_email CHECK (email LIKE '%@%.%')
);

-- Borrowing table (M-M relationship between Member and Book)
CREATE TABLE Borrowing (
    borrowing_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    staff_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    late_fee DECIMAL(10,2) DEFAULT 0.00,
    status ENUM('Borrowed', 'Returned', 'Overdue', 'Lost') DEFAULT 'Borrowed',
    notes TEXT,
    CONSTRAINT fk_borrowing_book FOREIGN KEY (book_id) REFERENCES Book(book_id),
    CONSTRAINT fk_borrowing_member FOREIGN KEY (member_id) REFERENCES Member(member_id),
    CONSTRAINT fk_borrowing_staff FOREIGN KEY (staff_id) REFERENCES Staff(staff_id),
    CONSTRAINT chk_borrowing_dates CHECK (due_date >= borrow_date AND (return_date IS NULL OR return_date >= borrow_date))
);

-- Fine table (1-M relationship with Member)
CREATE TABLE Fine (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    borrowing_id INT,
    amount DECIMAL(10,2) NOT NULL,
    issue_date DATE NOT NULL,
    payment_date DATE,
    status ENUM('Pending', 'Paid', 'Waived') DEFAULT 'Pending',
    reason VARCHAR(200) NOT NULL,
    CONSTRAINT fk_fine_member FOREIGN KEY (member_id) REFERENCES Member(member_id),
    CONSTRAINT fk_fine_borrowing FOREIGN KEY (borrowing_id) REFERENCES Borrowing(borrowing_id),
    CONSTRAINT chk_fine_amount CHECK (amount >= 0)
);

-- Reservation table (M-M relationship between Member and Book)
CREATE TABLE Reservation (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATETIME NOT NULL,
    expiry_date DATETIME NOT NULL,
    status ENUM('Pending', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Pending',
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) REFERENCES Book(book_id),
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) REFERENCES Member(member_id),
    CONSTRAINT chk_reservation_dates CHECK (expiry_date > reservation_date)
);

-- Audit log table
CREATE TABLE AuditLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    action_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id INT,
    old_values JSON,
    new_values JSON
);

-- Create indexes for better performance
CREATE INDEX idx_book_title ON Book(title);
CREATE INDEX idx_author_name ON Author(last_name, first_name);
CREATE INDEX idx_member_name ON Member(last_name, first_name);
CREATE INDEX idx_member_card ON Member(library_card_number);
CREATE INDEX idx_borrowing_dates ON Borrowing(borrow_date, due_date, return_date);
CREATE INDEX idx_borrowing_status ON Borrowing(status);
CREATE INDEX idx_fine_status ON Fine(status);
