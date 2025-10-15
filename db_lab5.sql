-- Serikov Rassul 24B032019
-- PART 1: CHECK
-- age must be 18-65, salary > 0
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

-- discount_price must be less than regular_price
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND discount_price > 0 AND discount_price < regular_price
    )
);

-- guests 1-10, check_out_date must be after check_in_date
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

-- test
INSERT INTO employees VALUES (1, 'John', 'Doe', 30, 2000);
INSERT INTO employees VALUES (2, 'Jane', 'Smith', 45, 3500);
-- wrong age
-- INSERT INTO employees VALUES (3, 'Mark', 'Lee', 17, 2500);
-- wrong salary
-- INSERT INTO employees VALUES (4, 'Mike', 'Brown', 40, -100);

INSERT INTO products_catalog VALUES (1, 'Phone', 1000, 800);
INSERT INTO products_catalog VALUES (2, 'Laptop', 2000, 1500);
-- wrong discount
-- INSERT INTO products_catalog VALUES (3, 'TV', 500, 600);

INSERT INTO bookings VALUES (1, '2025-05-01', '2025-05-10', 2);
INSERT INTO bookings VALUES (2, '2025-06-01', '2025-06-05', 5);
-- wrong dates
-- INSERT INTO bookings VALUES (3, '2025-05-10', '2025-05-01', 3);
-- too many guests
-- INSERT INTO bookings VALUES (4, '2025-05-01', '2025-05-05', 15);

-- PART 2: NOT NULL

-- some columns can't be NULL
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

-- quantity >= 0, price > 0
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO customers VALUES (1, 'john@example.com', '123456789', '2025-01-01');
-- null email
-- INSERT INTO customers VALUES (2, NULL, '123456789', '2025-01-01');

INSERT INTO inventory VALUES (1, 'Keyboard', 10, 50, NOW());
-- negative quantity
-- INSERT INTO inventory VALUES (2, 'Mouse', -5, 20, NOW());

-- PART 3: UNIQUE

-- no duplicates for username and email
CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

-- unique combination of 3 columns
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username);

ALTER TABLE users
ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO users VALUES (1, 'user1', 'user1@mail.com', NOW());
-- duplicate username
-- INSERT INTO users VALUES (2, 'user1', 'user2@mail.com', NOW());
-- duplicate email
-- INSERT INTO users VALUES (3, 'user3', 'user1@mail.com', NOW());

-- PART 4: PRIMARY KEY

-- primary key is unique and not null
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES (1, 'IT', 'Astana');
INSERT INTO departments VALUES (2, 'HR', 'Almaty');
INSERT INTO departments VALUES (3, 'Finance', 'Shymkent');
-- duplicate id
-- INSERT INTO departments VALUES (1, 'Support', 'Astana');
-- null id
-- INSERT INTO departments VALUES (NULL, 'Security', 'Astana');

-- composite primary key
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- PART 5: FOREIGN KEY

-- dept_id must exist in departments
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'John Doe', 1, '2025-01-01');
-- invalid dept_id
-- INSERT INTO employees_dept VALUES (2, 'Jane Doe', 99, '2025-01-01');

-- library schema
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES (1, 'Tolstoy', 'Russia');
INSERT INTO authors VALUES (2, 'Dostoevsky', 'Russia');

INSERT INTO publishers VALUES (1, 'AST', 'Moscow');
INSERT INTO publishers VALUES (2, 'Penguin', 'London');

INSERT INTO books VALUES (1, 'War and Peace', 1, 1, 1869, 'ISBN001');
INSERT INTO books VALUES (2, 'Crime and Punishment', 2, 2, 1866, 'ISBN002');

-- RESTRICT and CASCADE
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO products_fk VALUES (1, 'Smartphone', 1);
INSERT INTO orders VALUES (1, '2025-01-01');
INSERT INTO order_items VALUES (1, 1, 1, 2);

-- fail because of restrict
-- DELETE FROM categories WHERE category_id = 1;

-- cascade delete
DELETE FROM orders WHERE order_id = 1;

-- PART 6: E-COMMERCE

CREATE TABLE customers_ecom (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products_ecom (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ecom (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers_ecom(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC,
    status TEXT CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_ecom(product_id),
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);

-- sample data
INSERT INTO customers_ecom (name,email,phone,registration_date) VALUES
('Aruzhan','aru@mail.com','123456','2025-01-01'),
('Miras','miras@mail.com','987654','2025-01-02'),
('Dias','dias@mail.com','555555','2025-01-03'),
('Askar','askar@mail.com','111111','2025-01-04'),
('Dana','dana@mail.com','222222','2025-01-05');

INSERT INTO products_ecom (name,description,price,stock_quantity) VALUES
('Phone','Smartphone',150000,50),
('Laptop','Gaming Laptop',350000,30),
('Headphones','Wireless',30000,100),
('Mouse','Gaming Mouse',10000,80),
('Keyboard','Mechanical',20000,60);

INSERT INTO orders_ecom (customer_id,order_date,total_amount,status) VALUES
(1,'2025-02-01',150000,'pending'),
(2,'2025-02-02',350000,'processing'),
(3,'2025-02-03',30000,'shipped'),
(4,'2025-02-04',10000,'delivered'),
(5,'2025-02-05',20000,'cancelled');

INSERT INTO order_details (order_id,product_id,quantity,unit_price) VALUES
(1,1,1,150000),
(2,2,1,350000),
(3,3,1,30000),
(4,4,1,10000),
(5,5,1,20000);

