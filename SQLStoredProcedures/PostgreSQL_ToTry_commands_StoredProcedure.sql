a#==================
# select into
#==================
do $$ 
<<first_block>>
declare
  account_count integer := 0;
begin
   -- get the number of accounts
   select count(*) 
   into account_count
   from account;
   -- display a message
   raise notice 'The number of accounts is %', account_count;
end first_block $$;

#===================
# Row Type
#===================
do $$
<<first_block>>
declare
   selected_account account%rowtype;
begin
   -- get the branch_name and balance of account number 4 
   select *
   into selected_account
   from account
   where account_number = '4';
   -- display a message
   raise notice 'The branch_name and balance is %, %', 
	selected_account.branch_name, 
	selected_account.balance;
end first_block;
$$;

#===================
# Record Type
#===================
do $$
<<first_block>>
declare
   selected_accounts record;
begin
   -- get all accounts with the balance >= 100
   for selected_accounts in select account_number, branch_name, balance 
   	from account
   	where balance >= 100
	order by balance
   loop
   	-- display a message
   	raise notice 'The account_number branch_name and balance is %, %, %', 
		selected_accounts.branch_name, 
		selected_accounts.balance,
		selected_accounts.balance;
   end loop;
end first_block $$;


#===================
# Constant Type
#===================
do $$
<<first_block>>
declare
   start_at constant time = now();
begin
   -- display a message
   raise notice 'The current time is %', start_at;
end first_block $$;

#==================
# Assert 
#==================
do $$ 
<<first_block>>
declare
  account_count integer := 0;
begin
   -- get the number of accounts
   select count(*) 
   into account_count
   from account;
   -- assert a message when the assert conditon is false or null
   assert account_count > 1000, 'Test assert ';
end first_block $$;

#==================
# if-then 
#==================
do $$ 
<<first_block>>
declare
  selected_account account%rowtype;
  input_account_number account.account_number%type := 0;
begin
   -- get the account with specific account number
   select * from account
   into selected_account
   where account_number = input_account_number;
   
   if not found then 
	raise notice 'The account number % could not be found', 
		input_account_number;
   end if;
end first_block $$;

#==================
# if-then-else 
#==================
do $$ 
<<first_block>>
declare
  selected_account account%rowtype;
  input_account_number account.account_number%type := 6;
begin
   -- get the account with specific account number
   select * from account
   into selected_account
   where account_number = input_account_number;
   
   if not found then 
	raise notice 'The account number % could not be found', 
		input_account_number;
   else
	raise notice 'The branch_name and balance is % and %', 
		selected_account.branch_name,
                selected_account.balance;
   end if;
end first_block $$;

#==================
# if-then-elsif
#==================
do $$
<<first_block>>
declare
  selected_account account%rowtype;
  input_account_number account.account_number%type := 6;
  account_level varchar(100);
begin
   select * from account
   into selected_account
   where account_number = input_account_number;

   if not found then
        raise notice 'The account number % could not be found',
                input_account_number;
   else
	if selected_account.balance > 0 and selected_account.balance <= 200 then
	    account_level := 'Standard';
        elsif selected_account.balance > 200 and selected_account.balance <= 400 then
	    account_level := 'Silver';
        elsif selected_account.balance > 400 and selected_account.balance <= 600 then
	    account_level := 'Gold';
	else
	    account_level := 'Platinum';
  	end if;
        raise notice 'The account number % is in level %',
                selected_account.branch_name,
                account_level;
   end if;
end first_block $$;

#================
# while loop
#================
do $$
declare 
   counter integer := 0;
begin
   while counter < 5 loop
      raise notice 'Counter %', counter;
	  counter := counter + 1;
   end loop;
end$$;

#================
# for loop
#================

do $$
begin
   for counter in 1..5 loop
	raise notice 'counter: %', counter;
   end loop;
end; $$


#===============================
# for loop 2 in dynamic query
#===============================
do $$
declare
        -- sort by 1: branch_name, 2: balance
        sort_type smallint := 1; 
	-- return the number of accounts
	rec_count int := 10;
	-- use to iterate over the account
	rec record;
	-- dynamic query
        query text;
begin
		
	query := 'select branch_name, balance from account ';
	
	if sort_type = 1 then
		query := query || 'order by branch_name';
	elsif sort_type = 2 then
	   query := query || 'order by balance';
	else 
	   raise 'invalid sort type %s', sort_type;
	end if;

	for rec in execute query using rec_count
        loop
	     raise notice '% - %', rec.balance, rec.branch_name;
	end loop;
end; $$
#==============
# Function 1
#==============
CREATE OR REPLACE FUNCTION customer_level(p_moneylevel FLOAT)
    RETURNS VARCHAR(10)
    LANGUAGE plpgsql
    AS
$$
DECLARE 
    lvl varchar(10);
BEGIN
    IF p_moneylevel > 500 THEN
        lvl := 'PLATINUM';
    ELSEIF (p_moneylevel <= 500 AND p_moneylevel >= 100) THEN
        lvl := 'GOLD';
    ELSEIF p_moneylevel < 100 THEN
        lvl := 'SILVER';
    END IF;
    RETURN (lvl);
END;
$$

# Try calling Function 1

SELECT C.customer_name, A.account_number, customer_level(A.balance) FROM account A, customer C, depositor D WHERE A.account_number = D.account_number AND C.customer_name = D.customer_name;

#=============
# Function 2
#=============
CREATE OR REPLACE FUNCTION get_account_balance_stat(
    OUT min_balance NUMERIC,
    OUT max_balance NUMERIC,
    OUT avg_balance NUMERIC)
    LANGUAGE plpgsql
    AS
$$
BEGIN
    SELECT MIN(balance)::numeric(6,2), MAX(balance)::numeric(6,2), AVG(balance)::numeric(6,2)
    INTO min_balance, max_balance, avg_balance
    FROM account;
END;
$$

# Try calling Function 2
select * from get_account_balance_stat();

#=============
# Function 3
#=============
CREATE OR REPLACE FUNCTION get_customers_with_pattern(
    p_pattern VARCHAR)
    RETURNS TABLE(
	cust_name VARCHAR,
        cust_street VARCHAR
    )
    LANGUAGE plpgsql
    AS
$$
BEGIN
    RETURN query
    SELECT customer_name, customer_street
    FROM customer
    WHERE customer_name LIKE p_pattern;
END;
$$

# Try calling Function 3
select get_customers_with_pattern('M%');
select * from get_customers_with_pattern('M%');


#===================
# Procedure 1
#===================
CREATE or REPLACE procedure transfer(
   from_acct VARCHAR(2),
   to_acct VARCHAR(2),
   amount NUMERIC
)
language plpgsql    
AS $$
BEGIN
    -- subtracting the amount from the sender's account 
    UPDATE account 
    SET balance = balance - amount 
    WHERE account_number = from_acct;

    -- adding the amount to the receiver's account
    UPDATE account 
    SET balance = balance + amount 
    WHERE account_number = to_acct;

    COMMIT;
END;$$

# Try call transfer()
call transfer('5','1',100);

#===================
# Procedure 2
#===================

CREATE OR REPLACE procedure open_new_saving_account(
	cust_name VARCHAR, 
	acct_number VARCHAR,
        branch_name VARCHAR,
        balance NUMERIC)
language plpgsql	
AS $$
BEGIN
    INSERT INTO customer(customer_name)
    SELECT cust_name
    WHERE
    NOT EXISTS (
        SELECT C.customer_name FROM customer C WHERE C.customer_name = cust_name);    

    INSERT INTO account VALUES(acct_number, branch_name, balance);
    INSERT INTO depositor VALUES(cust_name, acct_number);
    COMMIT;
END;
$$

# Try call open_new_saving_account
call open_new_saving_account('Babara', '11', 'B', 800.0)

#===================
# Procedure 3
#===================
CREATE OR REPLACE procedure close_saving_account(
        cust_name VARCHAR, 
        acct_number VARCHAR)
language plpgsql
AS $$
BEGIN
    DELETE FROM account A
    WHERE account_number = acct_number;
    DELETE FROM depositor D
    WHERE account_number = acct_number;
END;
$$

call close_saving_account('Babara', '11');

#===============
# Triggers
#===============
# List available triggers

\dS [table name]

or

SELECT  event_object_table AS table_name ,trigger_name 
FROM information_schema.triggers  
WHERE event_object_table = [table name]
GROUP BY table_name , trigger_name
ORDER BY table_name ,trigger_name

#======
CREATE TABLE TriggerTime(exec_time timestamp NOT NULL);
#======

CREATE OR REPLACE FUNCTION log_adding_new_account()
    RETURNS TRIGGER
language plpgsql
AS $$
BEGIN
    INSERT INTO TriggerTime VALUES(now());
    RETURN NULL;
END;
$$

CREATE TRIGGER adding_new_account
  BEFORE INSERT
  ON account
  FOR EACH ROW
  EXECUTE PROCEDURE log_adding_new_account();

# Try call open_new_saving_account()
call open_new_saving_account('Babara', '11', 'B', 800.0);

#=============
# VIEW
#=============
CREATE VIEW ordered_products AS
SELECT product_id, count(order_id) AS sum_products
FROM order_line
GROUP BY product_id;

CREATE VIEW top_product AS
SELECT product_id
FROM ordered_products
WHERE sum_products IN (SELECT MAX(sum_products) FROM ordered_products);

SELECT product_id, product_description
FROM PRODUCT
WHERE product_id IN (SELECT * FROM top_product);

# List all created views 
select table_name from INFORMATION_SCHEMA.views WHERE table_schema = ANY (current_schemas(false));

#===========
# INDEX
#===========
CREATE TABLE customer(
    idx INT,
    cid VARCHAR(40),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    company VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(80),
    phone_1 VARCHAR(40),
    phone_2 VARCHAR(40),
    email VARCHAR(50),
    subscription_date DATE,
    website VARCHAR(150))

\copy customer FROM '/home/customers-500000.csv' DELIMITER ',' CSV HEADER;

SELECT * FROM customer;

EXPLAIN ANALYZE SELECT * FROM customer WHERE country = 'Thailand';
EXPLAIN ANALYZE SELECT first_name, last_name, phone_1 FROM customer WHERE phone_1 LIKE '(449)%';
CREATE INDEX country_idx ON customer(country);
CREATE INDEX phone1_idx ON customer(phone_1);
EXPLAIN ANALYZE SELECT * FROM customer WHERE country = 'Thailand';
EXPLAIN ANALYZE SELECT first_name, last_name, phone_1 FROM customer WHERE phone_1 LIKE '(449)%';

#===============================================================================
# Explore the number of distinct values within columns of interest of a table
#===============================================================================
SELECT tablename AS table_name,attname AS column_name,n_distinct AS num_distinct_values
      FROM pg_stats
      WHERE tablename = 'customer'
      AND attname IN ('country','phone_1','subscription_date')
      ORDER BY num_distinct_values DESC;


#=========================================================================
# See distinct values of attributes of interest in a table via pg_stats
#=========================================================================
SELECT tablename AS table_name,attname AS column_name,n_distinct AS num_distinct_values
      FROM pg_stats
      WHERE tablename = 'customer'
      AND attname IN ('country','phone_1','subscription_date')
      ORDER BY num_distinct_values DESC;


# Transaction
#=================
** Session 1 **
START TRANSACTION;
INSERT INTO boat VALUES(120,'AAA','Black');
INSERT INTO boat VALUES(121,'BBB','Red');
SELECT * FROM boat;
SELECT * FROM boat;

** Session 2 **
SELECT * FROM boat;

** Session 1 **
COMMIT;

** Session 2 **
SELECT * FROM boat;
# Session 2 will see the two inserted records of IDs 112 and 113 from Session 1

** Session 1 **
START TRANSACTION;
INSERT INTO boat VALUES(115,'CCC','Yellow');
INSERT INTO boat VALUES(116,'DDD','Greeen');
SELECT * FROM boat;
SELECT * FROM boat;

** Session 2 **
SELECT * FROM boat;

** Session 1 **
ROLLBACK;
# Session 1 will not see the records 115 and 116 anymore. 



** Session 2 **
SELECT * FROM boat;
# Session 2 will see the two inserted records of IDs 112 and 113 from Session 1

#===================================================
# END of example codes shown in the presentation 
#===================================================

#===================================
# Do not use the following lines
#===================================
CREATE TABLE student_w_grade(
    sid varchar(10) PRIMARY KEY,
    Q1 numeric(10,2),
    Q2 numeric(10,2),
    Q3 numeric(10,2),
    Q4 numeric(10,2),
    Q5 numeric(10,2),
    total numeric(10,2),
    grade varchar(2));

\copy student_w_grade FROM '/Users/duangdaowichadakul/Desktop/2110322_DBSYS_2566_1/student_w_grade.csv' DELIMITER ',' CSV HEADER;

EXPLAIN select * from student_w_grade;

EXPLAIN select sid, total, grade from student_w_grade where grade = 'B';
CREATE INDEX grade_index ON student_w_grade(grade);
EXPLAIN select sid, total, grade from student_w_grade where grade = 'B';

DROP INDEX grade_index;
EXPLAIN ANALYZE select sid, total, grade from student_w_grade where grade = 'B';
CREATE INDEX grade_index ON student_w_grade(grade);
EXPLAIN ANALYZE select sid, total, grade from student_w_grade where grade = 'B';

DROP INDEX grade_index;
EXPLAIN ANALYZE select grade, count(*) from student_w_grade group by grade;
CREATE INDEX grade_index ON student_w_grade(grade);
EXPLAIN ANALYZE select grade, count(*) from student_w_grade group by grade;

#============
# Helper
#============

CREATE TABLE student(
    sid varchar(10) PRIMARY KEY,
	Q1 numeric(10,2),
	Q2 numeric(10,2),
	Q3 numeric(10,2),
	Q4 numeric(10,2),
	Q5 numeric(10,2))

\copy student FROM '/Users/duangdaowichadakul/Desktop/2110322_DBSYS_2566_1/scores.csv' DELIMITER ',' CSV HEADER; 

create table student_w_total as select sid,q1,q2,q3,q4,q5,q1+q2+q3+q4+q5 as total from student;

CREATE OR REPLACE FUNCTION map_score_to_grade(total_score NUMERIC)
    RETURNS VARCHAR
    LANGUAGE plpgsql
    AS
$$
DECLARE 
    grade varchar(2);
BEGIN
    IF total_score >= 30 THEN
        grade := 'A';
    ELSEIF (total_score < 30 AND total_score >= 25) THEN
        grade := 'B+';
    ELSEIF (total_score < 25 AND total_score >= 20) THEN
        grade := 'B';
    ELSEIF (total_score < 20 AND total_score >= 15) THEN
        grade := 'C+';
    ELSEIF (total_score < 15 AND total_score >= 10) THEN
        grade := 'C';
    ELSEIF (total_score < 10 AND total_score >= 5) THEN
        grade := 'D+';
    ELSEIF (total_score < 5) THEN
        grade := 'D';
    END IF;
    RETURN (grade);
END;
$$

create table student_w_grade as select sid,q1,q2,q3,q4,q5,q1+q2+q3+q4+q5 as total, map_score_to_grade(q1+q2+q3+q4+q5) as grade from student;

\d student_w_grade;

EXPLAIN select * from student_w_grade;

EXPLAIN select sid, total, grade from student_w_grade where grade = 'A';

CREATE INDEX grade_index ON student_w_grade(grade);


