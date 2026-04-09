-- ========================================================================
-- 01. UNPIVOT COLUMNS
-- ========================================================================

-- step 1: decide the number of columns
-- SELECT string_to_array('a/b/c', '/') AS parts
SELECT array_length(string_to_array('a/b/c', '/'), 1) AS num_parts;

-- string_to_array() is a PostgreSQL function that converts a string into an array, using a separator you specify.
-- If the separator doesn’t exist in the string, you’ll get an array with one element, which is the original string.
-- SELECT string_to_array('123', '/');  -- Result: {123}

-- array_length(array, dimension)
-- since this is a column (1D array), the dimension number is 1 (rows). If want to specify the matrix column in an array, dimension is 2. 
SELECT
    外籍配偶人數,
    array_length(string_to_array(外籍配偶人數, '/'), 1) AS num_parts
FROM foreign_spouse
order by num_parts DESC;

-- step 2: rename the original table as raw (before doing anything)
alter table foreign_spouse rename to raw_foreign_spouse;

-- according to the results above, all rows in year_month column has 3 parts separated by '/'. 
SELECT
    外籍配偶人數,
    (string_to_array(外籍配偶人數, '/'))[1] AS year_month,
    (string_to_array(外籍配偶人數, '/'))[2] AS city,
    (string_to_array(外籍配偶人數, '/'))[3] AS gender
FROM raw_foreign_spouse;

-- test stg table
SELECT
    *,
    (string_to_array(外籍配偶人數, '/'))[1] AS year_month,
    (string_to_array(外籍配偶人數, '/'))[2] AS city,
    (string_to_array(外籍配偶人數, '/'))[3] AS gender
    
FROM raw_foreign_spouse;

-- step 3: create a staging table
CREATE table stg_foreign_spouse AS
SELECT
    *,
    (string_to_array(外籍配偶人數, '/'))[1] AS year_month,
    (string_to_array(外籍配偶人數, '/'))[2] AS city,
    (string_to_array(外籍配偶人數, '/'))[3] AS gender
    
FROM raw_foreign_spouse;

-- ========================================================================
-- 02. DATA CLEANING
-- ========================================================================

alter table stg_foreign_spouse
drop column 外籍配偶人數;

-- before reordering columns, list all the other columns
SELECT string_agg(column_name, ', ')
FROM information_schema.columns
WHERE table_name = 'stg_foreign_spouse'
  AND column_name NOT IN ('year_month', 'city', 'gender');

-- reorder columns (by copy and paste those 10 column names)
create table stg_foreign_spouse_tmpt as
select year_month, city, gender, 大陸配偶_統計, 港澳配偶_統計, 總計, 越南_統計, 印尼_統計, 泰國_統計, 菲律賓_統計, 柬埔寨_統計, 日本_統計, 韓國_統計, 其他_統計, 外籍配偶_統計
from stg_foreign_spouse;

-- drop and rename tables
drop table stg_foreign_spouse;

alter table stg_foreign_spouse_tmpt rename to stg_foreign_spouse;

-- drop two grand total columns, where '總計' is the total and '外籍配偶_統計' is the total of all except for 大陸配偶_統計 and 港澳配偶_統計
alter table stg_foreign_spouse
drop column 總計,
drop column "外籍配偶_統計";

-- delete total rows (check first)
SELECT *
FROM stg_foreign_spouse
WHERE year_month LIKE '%(1~10月)%';

DELETE FROM stg_foreign_spouse
WHERE year_month LIKE '%(1~10月)%';


SELECT *
FROM stg_foreign_spouse
WHERE gender LIKE '%性別總計%';

DELETE FROM stg_foreign_spouse
WHERE gender LIKE '%性別總計%';

SELECT *
FROM stg_foreign_spouse
WHERE city LIKE '%區域別總計%';

DELETE FROM stg_foreign_spouse
WHERE city LIKE '%區域別總計%';

-- split year_month column
SELECT
    year_month,
    array_length(string_to_array(year_month, ' '), 1) AS num_parts
FROM stg_foreign_spouse
order by num_parts DESC;

SELECT
     year_month,
    (string_to_array( year_month, ' '))[1] AS year,
    (string_to_array( year_month, ' '))[2] as month
FROM stg_foreign_spouse;

SELECT string_agg(column_name, ', ')
FROM information_schema.columns
WHERE table_name = 'stg_foreign_spouse'
  AND column_name NOT IN ('year', 'month');

create table stg_foreign_spouse_tmpt as
select 
	(string_to_array( year_month, ' '))[1] AS year,
	(string_to_array( year_month, ' '))[2] as month, 
	 city, gender, 
	 大陸配偶_統計, 港澳配偶_統計, 
	 越南_統計, 印尼_統計, 泰國_統計, 菲律賓_統計, 柬埔寨_統計, 日本_統計, 韓國_統計, 其他_統計
from stg_foreign_spouse;

select * from stg_foreign_spouse_tmpt;

-- replace all "-" with null: If the value is '-' → replace it with NULL. Otherwise → keep the original value
UPDATE stg_foreign_spouse_tmpt
SET
    "港澳配偶_統計" = NULLIF("港澳配偶_統計", '-'),
    "越南_統計" = NULLIF("越南_統計", '-'),
    "印尼_統計" = NULLIF("印尼_統計", '-'),
    "泰國_統計" = NULLIF("泰國_統計", '-'),
    "菲律賓_統計" = NULLIF("菲律賓_統計", '-'),
    "柬埔寨_統計" = NULLIF("柬埔寨_統計", '-'),
    "日本_統計" = NULLIF("日本_統計", '-'),
    "韓國_統計" = NULLIF("韓國_統計", '-'),
    "其他_統計" = NULLIF("其他_統計", '-');

-- convert column values into integer using 'Properties' GUI

-- unpivot 10 columns
SELECT
    year,
    month,
    city,
    gender,
    v.nationality,
    v.count
FROM stg_foreign_spouse_tmpt
CROSS JOIN LATERAL (
    VALUES
        ('大陸', "大陸配偶_統計"::bigint),
        ('港澳', "港澳配偶_統計"::bigint),
        ('越南', "越南_統計"::bigint),
        ('印尼', "印尼_統計"::bigint),
        ('泰國', "泰國_統計"::bigint),
        ('菲律賓', "菲律賓_統計"::bigint),
        ('柬埔寨', "柬埔寨_統計"::bigint),
        ('日本', "日本_統計"::bigint),
        ('韓國', "韓國_統計"::bigint),
        ('其他', "其他_統計"::bigint)
) AS v(nationality, count);

create table stg_foreign_spouse as
SELECT
    year,
    month,
    city,
    gender,
    v.nationality,
    v.count
FROM stg_foreign_spouse_tmpt
CROSS JOIN LATERAL (
    VALUES
        ('大陸', "大陸配偶_統計"::bigint),
        ('港澳', "港澳配偶_統計"::bigint),
        ('越南', "越南_統計"::bigint),
        ('印尼', "印尼_統計"::bigint),
        ('泰國', "泰國_統計"::bigint),
        ('菲律賓', "菲律賓_統計"::bigint),
        ('柬埔寨', "柬埔寨_統計"::bigint),
        ('日本', "日本_統計"::bigint),
        ('韓國', "韓國_統計"::bigint),
        ('其他', "其他_統計"::bigint)
) AS v(nationality, count);

select * from stg_foreign_spouse
order by month asc;