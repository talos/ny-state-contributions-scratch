-- to start `sqlite3 state.db`

--select count(*) from indiv where employer is not null;
--

-- attach database 'indiv.db' as federal;

-- Simple analysis on raw state contributions:

-- SELECT
--   `Filer Id`,
--   `Report Id`,
--   `Transaction Code`,
--   `Election Year`,
--   `Transaction Id`,
--   COUNT(*) from state
-- GROUP BY
--   `Filer Id`,
--   `Report Id`,
--   `Transaction Code`,
--   `Election Year`,
--   `Transaction Id`
-- ORDER BY COUNT(*) DESC
-- LIMIT 100;

SELECT COUNT(*), cnt
FROM (
SELECT
  `Filer Id`,
  `Election Year`,
  `Corporation Name`,
  `Amount on Schedule(s)`,
  `Check Number`,
  `Transaction Id`,
  `Date of Schedule Transaction`,
  COUNT(*) cnt
FROM state
WHERE `Corporation Name` IS NOT NULL AND
  `Amount on Schedule(s)` IS NOT NULL AND
  `Date of Schedule Transaction` IS NOT NULL AND
  `Check Number` IS NOT NULL AND
  `Amount on Schedule(s)` != '$0.00' AND
  `Transaction Id` IS NOT NULL
GROUP BY
  `Filer Id`,
  `Election Year`,
  `Corporation Name`,
  `Amount on Schedule(s)`,
  `Check Number`,
  `Transaction Id`,
  `Date of Schedule Transaction`
)
GROUP BY cnt;


-- SELECT * FROM state WHERE
-- `Filer Id` = 'A00281'
-- AND `Election Year` = 2002
-- AND `Corporation Name` = 'HEALTH CARE PROVIDER PAC'
-- AND `Amount on Schedule(s)` = '$1500.00'
-- AND `Check Number` = '2240'
-- AND `Transaction Id` = 2
-- AND `Date of Schedule Transaction` = '10/04/2002';
-- ;

-- SELECT
--    `election year`,
--    COUNT(*) as all_count,,
--    SUM(CASE WHEN `Corporation Name` IS NOT NULL THEN 1 ELSE 0 END) AS corp_count,
--    SUM(CASE WHEN `Contributor First Name` IS NOT NULL THEN 1 ELSE 0 END) AS indiv_count,
--    SUM(CAST(SUBSTR(`Amount on Schedule(s)`, 2) AS FLOAT)) as all_sum,
--    SUM(CASE WHEN `Corporation Name` IS NOT NULL
--     THEN CAST(SUBSTR(`Amount on Schedule(s)`, 2) AS FLOAT) ELSE 0 END) AS corp_sum,
--    SUM(CASE WHEN `Contributor First Name` IS NOT NULL
--     THEN CAST(SUBSTR(`Amount on Schedule(s)`, 2) AS FLOAT) ELSE 0 END) AS indiv_sum
--    FROM state
--    GROUP BY `election year`
--    WHERE `Transaction Id` IS NOT NULL;


-- CREATE TABLE state_contributions (
--   name TEXT,
--   zip TEXT,
--   year INT,
--   amount REAL,
--   candidate TEXT
-- );
-- 
-- INSERT INTO state_contributions
-- SELECT
--   CASE WHEN `Corporation Name` IS NOT NULL THEN
--            TRIM(REPLACE(REPLACE(`Corporation Name`, '"', ''), "'", ''))
--        ELSE
--            TRIM(REPLACE(REPLACE(`Contributor Last Name`, '"', ''), "'", ''))
--            || '%' ||
--            TRIM(REPLACE(REPLACE(`Contributor First Name`, '"', ''), "'", ''))
--   END AS name,
--   `Contributor Zip`,
--   CASE WHEN `date of schedule transaction` IS NOT NULL THEN
--      SUBSTR(`date of schedule transaction`, 7,4)
--   ELSE SUBSTR(`Record Create Date`, 7,4)
--   END AS year,
--   SUM(CAST(SUBSTR(`Amount on Schedule(s)`, 2) AS INT)),
--   GROUP_CONCAT(DISTINCT `Candidate or Committee Name (Filer Name)`)
-- FROM state
-- GROUP BY
--   `name`, `Contributor Zip`, year
-- ;
-- 
-- CREATE UNIQUE INDEX state_contributions_unique_index ON state_contributions(name, zip, year);
-- 
-- DELETE FROM state_contributions WHERE
--       name IS NULL OR
--       zip IS NULL OR
--       trim(name) = '' OR
--       trim(name) = '"' OR
--       trim(name) = "'";

--CREATE TABLE employers (
--  name TEXT,
--  zip TEXT,
--  employer TEXT,
--  num
--);
--
--INSERT INTO employers
--SELECT
--  NAME,
--  SUBSTR(ZIP_CODE, 0, 6) zip,
--  EMPLOYER,
--  COUNT(*)
--FROM federal.indiv
--WHERE NAME IS NOT NULL
--      AND EMPLOYER IS NOT NULL
--GROUP BY NAME, zip, EMPLOYER
--;

-- CREATE UNIQUE INDEX
-- employers_unique_index on employers
-- (name, zip, employer);

-- CREATE TABLE state_contributions_with_employer (
--   state_name TEXT,
--   state_zip TEXT,
--   federal_name TEXT,
--   federal_zip TEXT,
--   employer TEXT,
--   amount REAL,
--   year INT,
--   candidate TEXT
-- );
-- 
-- INSERT INTO state_contributions_with_employer
-- SELECT state.name,
--        state.zip,
--        employers.name,
--        employers.zip,
--        employers.employer,
--        state.amount,
--        state.year,
--        state.candidate
-- FROM state_contributions state
--      JOIN employers ON employers.name LIKE state.name
--                     AND employers.zip = state.zip
-- ;
-- 
-- ALTER TABLE state_contributions_with_employer ADD COLUMN dupe_num REAL;
-- CREATE INDEX name_name_zip ON state_contributions_with_employer
--   (state_name, federal_name, state_zip);

-- CREATE TABLE state_contributions_with_employer_dupe_nums (
--   state_name TEXT,
--   federal_name TEXT,
--   state_zip TEXT,
--   dupe_num REAL,
--   PRIMARY KEY (state_name, federal_name, state_zip)
-- );
-- 
-- INSERT INTO state_contributions_with_employer_dupe_nums
-- SELECT state_name, federal_name, state_zip, count(distinct employer)
-- FROM state_contributions_with_employer
-- GROUP BY federal_name, state_zip;

-- UPDATE state_contributions_with_employer
-- SET dupe_num = (
--   SELECT dupe_num FROM state_contributions_with_employer_dupe_nums inside
--   WHERE state_contributions_with_employer.state_name = inside.state_name AND
--         state_contributions_with_employer.federal_name = inside.federal_name AND
--         state_contributions_with_employer.state_zip = inside.state_zip
-- );
-- 
-- .mode csv
-- .headers on
-- .output processed.csv
-- CREATE TABLE processed AS
-- SELECT
--   employer,
--   --soundex(employer),
--   count(distinct state_name) num_state_names,
--   count(distinct federal_name) num_fed_names,
--   count(distinct candidate) num_candidates,
--   group_concat(distinct federal_name || ':' || federal_zip) fed_names,
--   group_concat(distinct employer) employers_full,
--   group_concat(distinct candidate) candidates,
--   group_concat(distinct year) years,
--   sum(amount / dupe_num) AS total
-- FROM state_contributions_with_employer
-- GROUP BY --SOUNDEX(employer), SUBSTR(employer, 1, 8)
--   SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
--     employer, ' ', ''), '/', ''), ':', ''), ',', ''), '&', ''), '-', ''), '@', ''), ';', ''), '''', ''),'"' , ''), 0, 20)
-- ORDER BY total desc
-- --LIMIT 100
-- ;
