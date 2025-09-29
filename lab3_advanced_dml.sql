-- Task 1
CREATE DATABASE advanced_lab;
\c advanced_lab;

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50) DEFAULT 'General',
    salary INT DEFAULT 40000,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INT,
    manager_id INT
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    start_date DATE,
    end_date DATE,
    budget INT
);

-- Task 2
INSERT INTO employees (emp_id, first_name, last_name, department) 
VALUES (1, 'John', 'Smith', 'IT');

-- Task 3
INSERT INTO employees (first_name, last_name, hire_date) 
VALUES ('Alice', 'Brown', CURRENT_DATE);

-- Task 4
INSERT INTO departments (dept_name, budget, manager_id) VALUES
('HR', 80000, 1),
('IT', 120000, 2),
('Sales', 100000, 3);

-- Task 5
INSERT INTO employees (first_name, last_name, department, hire_date, salary) 
VALUES ('Mark', 'Taylor', 'Finance', CURRENT_DATE, 50000 * 1.1);

-- Task 6
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- Task 7
UPDATE employees SET salary = salary * 1.1;

-- Task 8
UPDATE employees 
SET status = 'Senior' 
WHERE salary > 60000 AND hire_date < '2020-01-01';

-- Task 9
UPDATE employees 
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- Task 10
UPDATE employees 
SET department = DEFAULT 
WHERE status = 'Inactive';

-- Task 11
UPDATE departments d
SET budget = (SELECT AVG(salary) * 1.2 FROM employees e WHERE e.department = d.dept_name);

-- Task 12
UPDATE employees 
SET salary = salary * 1.15, status = 'Promoted' 
WHERE department = 'Sales';

-- Task 13
DELETE FROM employees WHERE status = 'Terminated';

-- Task 14
DELETE FROM employees 
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

-- Task 15
DELETE FROM departments 
WHERE dept_id NOT IN (
    SELECT DISTINCT department::INT FROM employees WHERE department IS NOT NULL
);

-- Task 16
DELETE FROM projects 
WHERE end_date < '2023-01-01' 
RETURNING *;

-- Task 17
INSERT INTO employees (first_name, last_name, salary, department) 
VALUES ('NullGuy', 'Test', NULL, NULL);

-- Task 18
UPDATE employees 
SET department = 'Unassigned' 
WHERE department IS NULL;

-- Task 19
DELETE FROM employees 
WHERE salary IS NULL OR department IS NULL;

-- Task 20
INSERT INTO employees (first_name, last_name) 
VALUES ('James', 'Bond') 
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- Task 21
UPDATE employees 
SET salary = salary + 5000 
WHERE department = 'IT' 
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- Task 22
DELETE FROM employees 
WHERE hire_date < '2020-01-01' 
RETURNING *;

-- Task 23
INSERT INTO employees (first_name, last_name) 
SELECT 'Unique', 'Person'
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Unique' AND last_name = 'Person'
);

-- Task 24
UPDATE employees 
SET salary = salary * CASE 
    WHEN (SELECT budget FROM departments d WHERE d.dept_name = employees.department) > 100000 
    THEN 1.1 ELSE 1.05 END;

-- Task 25
INSERT INTO employees (first_name, last_name, department, salary, hire_date) VALUES
('Emp1','A','IT',40000,CURRENT_DATE),
('Emp2','B','IT',45000,CURRENT_DATE),
('Emp3','C','HR',42000,CURRENT_DATE),
('Emp4','D','Sales',50000,CURRENT_DATE),
('Emp5','E','Finance',55000,CURRENT_DATE);

UPDATE employees 
SET salary = salary * 1.1 
WHERE first_name IN ('Emp1','Emp2','Emp3','Emp4','Emp5');

-- Task 26
CREATE TABLE employee_archive AS TABLE employees WITH NO DATA;

INSERT INTO employee_archive 
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

-- Task 27
UPDATE projects 
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000 
AND dept_id IN (
    SELECT d.dept_id FROM departments d
    JOIN employees e ON e.department = d.dept_name
    GROUP BY d.dept_id
    HAVING COUNT(e.emp_id) > 3
);
