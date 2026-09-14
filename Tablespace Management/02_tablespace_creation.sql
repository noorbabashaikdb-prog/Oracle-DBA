-- ============================================================
-- Oracle DBA Notes
-- Module     : Tablespace Management
-- File       : 02_tablespace_creation.sql
-- Purpose    : Tablespace Creation - Practical Examples
-- ============================================================

-- ============================================================
-- 1. CHECK DATABASE INFORMATION
-- ============================================================

-- Database name and open mode
SELECT name, open_mode, database_role
FROM v$database;

-- Instance information
SELECT instance_name, status
FROM v$instance;

-- ============================================================
-- 2. CHECK EXISTING TABLESPACES
-- ============================================================

SELECT
tablespace_name,
status,
contents,
extent_management,
segment_space_management,
bigfile
FROM dba_tablespaces
ORDER BY tablespace_name;

-- ============================================================
-- 3. CREATE BASIC PERMANENT TABLESPACE
-- ============================================================

CREATE TABLESPACE app_data
DATAFILE '/u01/oradata/ORCL/app_data01.dbf'
SIZE 1G;

-- Verify
SELECT
tablespace_name,
status,
contents
FROM dba_tablespaces
WHERE tablespace_name = 'APP_DATA';

-- ============================================================
-- 4. CREATE TABLESPACE WITH AUTOEXTEND
-- ============================================================

CREATE TABLESPACE app_data_auto
DATAFILE '/u01/oradata/ORCL/app_data_auto01.dbf'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 5G;

-- Verify datafile
SELECT
file_id,
file_name,
tablespace_name,
bytes / 1024 / 1024 AS size_mb,
autoextensible,
increment_by,
maxbytes / 1024 / 1024 AS max_size_mb
FROM dba_data_files
WHERE tablespace_name = 'APP_DATA_AUTO';

-- ============================================================
-- 5. CREATE TABLESPACE WITH MULTIPLE DATAFILES
-- ============================================================

CREATE TABLESPACE app_data_multi
DATAFILE
'/u01/oradata/ORCL/app_data_multi01.dbf' SIZE 1G,
'/u01/oradata/ORCL/app_data_multi02.dbf' SIZE 1G;

-- Verify
SELECT
file_id,
file_name,
tablespace_name,
bytes / 1024 / 1024 AS size_mb
FROM dba_data_files
WHERE tablespace_name = 'APP_DATA_MULTI'
ORDER BY file_id;

-- ============================================================
-- 6. CREATE LOCALLY MANAGED TABLESPACE
-- ============================================================

CREATE TABLESPACE lmt_data
DATAFILE '/u01/oradata/ORCL/lmt_data01.dbf'
SIZE 1G
EXTENT MANAGEMENT LOCAL;

-- Verify
SELECT
tablespace_name,
extent_management
FROM dba_tablespaces
WHERE tablespace_name = 'LMT_DATA';

-- ============================================================
-- 7. CREATE LOCALLY MANAGED TABLESPACE
--    WITH AUTOALLOCATE
-- ============================================================

CREATE TABLESPACE autoallocate_data
DATAFILE '/u01/oradata/ORCL/autoallocate01.dbf'
SIZE 1G
EXTENT MANAGEMENT LOCAL
AUTOALLOCATE;

-- ============================================================
-- 8. CREATE LOCALLY MANAGED TABLESPACE
--    WITH UNIFORM EXTENT SIZE
-- ============================================================

CREATE TABLESPACE uniform_data
DATAFILE '/u01/oradata/ORCL/uniform_data01.dbf'
SIZE 1G
EXTENT MANAGEMENT LOCAL
UNIFORM SIZE 1M;

-- ============================================================
-- 9. CREATE TABLESPACE WITH ASSM
--    AUTOMATIC SEGMENT SPACE MANAGEMENT
-- ============================================================

CREATE TABLESPACE assm_data
DATAFILE '/u01/oradata/ORCL/assm_data01.dbf'
SIZE 1G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

-- ============================================================
-- 10. CREATE TABLESPACE WITH LOGGING
-- ============================================================

CREATE TABLESPACE logging_data
DATAFILE '/u01/oradata/ORCL/logging_data01.dbf'
SIZE 1G
LOGGING;

-- ============================================================
-- 11. CREATE TABLESPACE WITH NOLOGGING
-- ============================================================

CREATE TABLESPACE nologging_data
DATAFILE '/u01/oradata/ORCL/nologging_data01.dbf'
SIZE 1G
NOLOGGING;

-- ============================================================
-- 12. CREATE BIGFILE TABLESPACE
-- ============================================================

CREATE BIGFILE TABLESPACE big_data
DATAFILE '/u01/oradata/ORCL/big_data01.dbf'
SIZE 10G
AUTOEXTEND ON
NEXT 500M
MAXSIZE 50G;

-- Verify
SELECT
tablespace_name,
bigfile,
status,
contents
FROM dba_tablespaces
WHERE tablespace_name = 'BIG_DATA';

-- ============================================================
-- 13. CREATE TEMPORARY TABLESPACE
-- ============================================================

CREATE TEMPORARY TABLESPACE temp_app
TEMPFILE '/u01/oradata/ORCL/temp_app01.dbf'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;

-- Verify
SELECT
tablespace_name,
status,
contents
FROM dba_tablespaces
WHERE tablespace_name = 'TEMP_APP';

-- Check tempfile
SELECT
file_id,
file_name,
tablespace_name,
bytes / 1024 / 1024 AS size_mb,
autoextensible,
maxbytes / 1024 / 1024 AS max_size_mb
FROM dba_temp_files
WHERE tablespace_name = 'TEMP_APP';

-- ============================================================
-- 14. CREATE UNDO TABLESPACE
-- ============================================================

CREATE UNDO TABLESPACE undo_app
DATAFILE '/u01/oradata/ORCL/undo_app01.dbf'
SIZE 2G
AUTOEXTEND ON
NEXT 200M
MAXSIZE 10G;

-- Verify
SELECT
tablespace_name,
status,
contents
FROM dba_tablespaces
WHERE tablespace_name = 'UNDO_APP';

-- ============================================================
-- 15. CREATE TABLESPACE IN ASM
-- ============================================================

-- Prerequisite:
-- ASM disk group +DATA must already exist.

CREATE TABLESPACE asm_app_data
DATAFILE '+DATA'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;

-- Verify ASM datafile
SELECT
file_id,
file_name,
tablespace_name,
bytes / 1024 / 1024 AS size_mb
FROM dba_data_files
WHERE tablespace_name = 'ASM_APP_DATA';

-- ============================================================
-- 16. CREATE BIGFILE TABLESPACE IN ASM
-- ============================================================

CREATE BIGFILE TABLESPACE asm_big_data
DATAFILE '+DATA'
SIZE 10G
AUTOEXTEND ON
NEXT 500M
MAXSIZE 100G;

-- ============================================================
-- 17. CREATE TABLESPACE USING OMF
--    ORACLE MANAGED FILES
-- ============================================================

-- This requires DB_CREATE_FILE_DEST to be configured.

SHOW PARAMETER db_create_file_dest;

CREATE TABLESPACE omf_data
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 5G;

-- ============================================================
-- 18. CHECK DATAFILE DETAILS
-- ============================================================

SELECT
file_id,
file_name,
tablespace_name,
ROUND(bytes / 1024 / 1024, 2) AS size_mb,
autoextensible,
ROUND(maxbytes / 1024 / 1024, 2) AS max_size_mb
FROM dba_data_files
ORDER BY tablespace_name, file_id;

-- ============================================================
-- 19. CHECK TEMPFILE DETAILS
-- ============================================================

SELECT
file_id,
file_name,
tablespace_name,
ROUND(bytes / 1024 / 1024, 2) AS size_mb,
autoextensible,
ROUND(maxbytes / 1024 / 1024, 2) AS max_size_mb
FROM dba_temp_files
ORDER BY tablespace_name, file_id;

-- ============================================================
-- 20. CHECK FREE SPACE
-- ============================================================

SELECT
tablespace_name,
ROUND(SUM(bytes) / 1024 / 1024, 2) AS free_mb
FROM dba_free_space
GROUP BY tablespace_name
ORDER BY tablespace_name;

-- ============================================================
-- 21. CHECK TABLESPACE STATUS
-- ============================================================

SELECT
tablespace_name,
status,
contents,
logging,
extent_management,
segment_space_management,
bigfile
FROM dba_tablespaces
ORDER BY tablespace_name;

-- ============================================================
-- 22. SET DEFAULT PERMANENT TABLESPACE
-- ============================================================

ALTER DATABASE DEFAULT TABLESPACE app_data;

-- Verify
SELECT property_name, property_value
FROM database_properties
WHERE property_name = 'DEFAULT_PERMANENT_TABLESPACE';

-- ============================================================
-- 23. SET DEFAULT TEMPORARY TABLESPACE
-- ============================================================

ALTER DATABASE DEFAULT TEMPORARY TABLESPACE temp_app;

-- Verify
SELECT property_name, property_value
FROM database_properties
WHERE property_name = 'DEFAULT_TEMP_TABLESPACE';

-- ============================================================
-- 24. ADD DATAFILE TO EXISTING TABLESPACE
-- ============================================================

ALTER TABLESPACE app_data
ADD DATAFILE
'/u01/oradata/ORCL/app_data02.dbf'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 5G;

-- ============================================================
-- 25. RESIZE EXISTING DATAFILE
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
RESIZE 2G;

-- ============================================================
-- 26. ENABLE AUTOEXTEND
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
AUTOEXTEND ON
NEXT 100M
MAXSIZE 5G;

-- ============================================================
-- 27. DISABLE AUTOEXTEND
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
AUTOEXTEND OFF;

-- ============================================================
-- 28. TAKE TABLESPACE OFFLINE
-- ============================================================

ALTER TABLESPACE app_data OFFLINE;

-- ============================================================
-- 29. BRING TABLESPACE ONLINE
-- ============================================================

ALTER TABLESPACE app_data ONLINE;

-- ============================================================
-- 30. MAKE TABLESPACE READ ONLY
-- ============================================================

ALTER TABLESPACE app_data READ ONLY;

-- ============================================================
-- 31. MAKE TABLESPACE READ WRITE
-- ============================================================

ALTER TABLESPACE app_data READ WRITE;

-- ============================================================
-- 32. CHECK TABLESPACE USAGE
-- ============================================================

SELECT
df.tablespace_name,
ROUND(df.total_mb, 2) AS total_mb,
ROUND(NVL(fs.free_mb, 0), 2) AS free_mb,
ROUND(df.total_mb - NVL(fs.free_mb, 0), 2) AS used_mb,
ROUND(
((df.total_mb - NVL(fs.free_mb, 0)) / df.total_mb) * 100,
2
) AS used_pct
FROM
(
SELECT
tablespace_name,
SUM(bytes) / 1024 / 1024 AS total_mb
FROM dba_data_files
GROUP BY tablespace_name
) df
LEFT JOIN
(
SELECT
tablespace_name,
SUM(bytes) / 1024 / 1024 AS free_mb
FROM dba_free_space
GROUP BY tablespace_name
) fs
ON df.tablespace_name = fs.tablespace_name
ORDER BY used_pct DESC;

-- ============================================================
-- 33. FIND LARGEST SEGMENTS IN A TABLESPACE
-- ============================================================

SELECT
owner,
segment_name,
segment_type,
tablespace_name,
ROUND(bytes / 1024 / 1024, 2) AS size_mb
FROM dba_segments
WHERE tablespace_name = 'APP_DATA'
ORDER BY bytes DESC;

-- ============================================================
-- 34. CHECK USERS USING A TABLESPACE
-- ============================================================

SELECT
owner,
segment_name,
segment_type,
ROUND(bytes / 1024 / 1024, 2) AS size_mb
FROM dba_segments
WHERE tablespace_name = 'APP_DATA'
ORDER BY bytes DESC;

-- ============================================================
-- 35. DROP TEST TABLESPACE
-- ============================================================

-- WARNING:
-- This permanently removes objects and datafiles.

-- DROP TABLESPACE app_data
-- INCLUDING CONTENTS
-- AND DATAFILES;

-- ============================================================
-- 36. PRACTICAL PRODUCTION-STYLE TABLESPACE
-- ============================================================

CREATE TABLESPACE prod_app_data
DATAFILE
'/u01/oradata/ORCL/prod_app_data01.dbf'
SIZE 5G
AUTOEXTEND ON
NEXT 500M
MAXSIZE 20G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO
LOGGING;

-- ============================================================
-- 37. PRACTICAL INDEX TABLESPACE
-- ============================================================

CREATE TABLESPACE prod_app_index
DATAFILE
'/u01/oradata/ORCL/prod_app_index01.dbf'
SIZE 2G
AUTOEXTEND ON
NEXT 200M
MAXSIZE 10G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO
LOGGING;

-- ============================================================
-- 38. CREATE USER WITH DEFAULT TABLESPACE
-- ============================================================

CREATE USER appuser
IDENTIFIED BY "Password123"
DEFAULT TABLESPACE prod_app_data
TEMPORARY TABLESPACE temp_app;

-- Grant basic privileges for lab testing only.
GRANT CREATE SESSION, CREATE TABLE TO appuser;

-- ============================================================
-- 39. ASSIGN TABLESPACE QUOTA
-- ============================================================

ALTER USER appuser
QUOTA 5G ON prod_app_data;

-- Verify
SELECT
username,
default_tablespace,
temporary_tablespace
FROM dba_users
WHERE username = 'APPUSER';

-- ============================================================
-- 40. FINAL VERIFICATION
-- ============================================================

SELECT
tablespace_name,
status,
contents,
logging,
extent_management,
segment_space_management,
bigfile
FROM dba_tablespaces
ORDER BY tablespace_name;

SELECT
tablespace_name,
file_name,
ROUND(bytes / 1024 / 1024, 2) AS size_mb,
autoextensible,
ROUND(maxbytes / 1024 / 1024, 2) AS max_size_mb
FROM dba_data_files
ORDER BY tablespace_name, file_id;

-- ============================================================
-- END OF 02_tablespace_creation.sql
-- ============================================================
