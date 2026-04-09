-- DATABASE DESIGN
-- ========================================================================================
-- Create dimension tables
-- ========================================================================================
-- dim_city
create table dim_city (
	city_id SERIAL primary key,
	city_name TEXT unique
);

insert into dim_city (city_name)
select distinct city
from stg_foreign_spouse;

select * from dim_city;

-- dim_gender
create table dim_gender (
	gender_id SERIAL primary key,
	gender_name TEXT unique
);

insert into dim_gender (gender_name)
select distinct gender
from stg_foreign_spouse;

select * from dim_gender;

-- dim_date
create table dim_date (
	date_id SERIAL primary key,
	year INT not null,
	quarter INT not null,
	month_name CHAR(3) not null,
	month_no INT not null,
	unique(year, month_no)
);

insert into dim_date (year, quarter, month_name, month_no)
select distinct 
	year,
	((month - 1) / 3 + 1) as quarter,
	to_char(to_date(month::text, 'MM'), 'Mon') as month_name,
	month as month_no
from stg_foreign_spouse
order by year asc, month_no asc;

select * from dim_date;

-- dim_nationality
create table dim_nationality (
	nationality_id SERIAL primary key,
	nationality_name TEXT unique
);

insert into dim_nationality (nationality_name)
select distinct nationality
from stg_foreign_spouse;

select * from dim_nationality;

-- ========================================================================================
-- Create fact table
-- ========================================================================================
create table fact_foreign_spouse as 
select
d.date_id,
c.city_id,
g.gender_id,
n.nationality_id,
s.count
from stg_foreign_spouse s
join dim_date d on s.year = d.year and s.month = d.month_no
join dim_city c on s.city = c.city_name
join dim_gender g on s.gender = g.gender_name
join dim_nationality n on s.nationality = n.nationality_name;

select * from fact_foreign_spouse;

-- ========================================================================================
-- Add constraints
-- ========================================================================================
-- date
alter table fact_foreign_spouse
add constraint fk_date foreign key (date_id)
references dim_date(date_id);

-- city
alter table fact_foreign_spouse
add constraint fk_city foreign key (city_id)
references dim_city(city_id);

-- gender
alter table fact_foreign_spouse
add constraint fk_gender foreign key (gender_id)
references dim_gender(gender_id);

-- nationality
alter table fact_foreign_spouse
add constraint fk_nationality foreign key (nationality_id)
references dim_nationality(nationality_id);

-- fact table
alter table fact_foreign_spouse
alter column count set not null;

-- ========================================================================================
-- Index
-- ========================================================================================
-- foreign keys in fact table
create index idx_fact_date on fact_foreign_spouse(date_id);
create index idx_fact_city on fact_foreign_spouse(city_id);
create index idx_fact_gender on fact_foreign_spouse(gender_id);
create index idx_fact_nationality on fact_foreign_spouse(nationality_id);

-- check existed indexes
SELECT schemaname, indexname, indexdef
FROM pg_indexes
WHERE tablename = 'fact_foreign_spouse';

EXPLAIN ANALYZE
SELECT *
FROM fact_foreign_spouse
WHERE nationality_id = 1;

SELECT conname AS constraint_name,
       contype AS constraint_type,
       conrelid::regclass AS table_name,
       pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'dim_city'::regclass;
