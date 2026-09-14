```sql
/*
===============================================================================
FILE NAME : 07_space_troubleshooting.sql
MODULE    : Tablespace Management
TOPIC     : Oracle Space Troubleshooting
VERSION   : Oracle 12c / 19c
AUTHOR    : Oracle DBA Notes

PURPOSE
-------
This script provides practical SQL commands for troubleshooting:

1. Tablespace space issues
2. Datafile full conditions
3. Autoextend problems
4. ORA-01653
5. ORA-01654
6. ORA-01652
7. ORA-30036
8. ORA-01536
9. ORA-03297
10. TEMP space issues
11. UNDO space issues
12. ASM space issues
13. Filesystem space issues
14. Segment growth
15. High Water Mark
16. Bigfile / Smallfile tablespaces
17. Real-time DBA troubleshooting
18. RCA and production change approach

IMPORTANT
---------
Review every command before executing it in production.
Do NOT blindly use AUTOEXTEND ON / MAXSIZE UNLIMITED.
Always verify filesystem or ASM capacity before increasing datafiles.
===============================================================================
*/


/*******************************************************************************
1. DATABASE INFORMATION
*******************************************************************************/

SELECT
    NAME,
    DB_UNIQUE_NAME,
    OPEN_MODE,
    DATABASE_ROLE,
    LOG_MODE
FROM V$DATABASE;


/*******************************************************************************
2. DATABASE INSTANCE INFORMATION
*******************************************************************************/

SELECT
    INSTANCE_NAME,
    HOST_NAME,
    VERSION,
    STATUS
FROM V$INSTANCE;


/*******************************************************************************
3. LIST ALL TABLESPACES
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    STATUS,
    CONTENTS,
    EXTENT_MANAGEMENT,
    SEGMENT_SPACE_MANAGEMENT,
    BIGFILE
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
4. CHECK TABLESPACE USAGE
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    ROUND(df.BYTES / 1024 / 1024, 2) AS ALLOCATED_MB,
    ROUND(NVL(fs.FREE_BYTES, 0) / 1024 / 1024, 2) AS FREE_MB,
    ROUND(
        (df.BYTES - NVL(fs.FREE_BYTES, 0))
        / df.BYTES * 100,
        2
    ) AS USED_PCT
FROM
    (
        SELECT
            TABLESPACE_NAME,
            SUM(BYTES) BYTES
        FROM DBA_DATA_FILES
        GROUP BY TABLESPACE_NAME
    ) df
LEFT JOIN
    (
        SELECT
            TABLESPACE_NAME,
            SUM(BYTES) FREE_BYTES
        FROM DBA_FREE_SPACE
        GROUP BY TABLESPACE_NAME
    ) fs
ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
ORDER BY USED_PCT DESC;


/*******************************************************************************
5. TABLESPACES ABOVE 80%
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    ROUND(df.BYTES / 1024 / 1024, 2) AS ALLOCATED_MB,
    ROUND(NVL(fs.FREE_BYTES, 0) / 1024 / 1024, 2) AS FREE_MB,
    ROUND(
        (df.BYTES - NVL(fs.FREE_BYTES, 0))
        / df.BYTES * 100,
        2
    ) AS USED_PCT
FROM
    (
        SELECT TABLESPACE_NAME, SUM(BYTES) BYTES
        FROM DBA_DATA_FILES
        GROUP BY TABLESPACE_NAME
    ) df
LEFT JOIN
    (
        SELECT TABLESPACE_NAME, SUM(BYTES) FREE_BYTES
        FROM DBA_FREE_SPACE
        GROUP BY TABLESPACE_NAME
    ) fs
ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
WHERE
    (df.BYTES - NVL(fs.FREE_BYTES, 0))
    / df.BYTES * 100 >= 80
ORDER BY USED_PCT DESC;


/*******************************************************************************
6. TABLESPACES ABOVE 90%
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    ROUND(df.BYTES / 1024 / 1024, 2) AS ALLOCATED_MB,
    ROUND(NVL(fs.FREE_BYTES, 0) / 1024 / 1024, 2) AS FREE_MB,
    ROUND(
        (df.BYTES - NVL(fs.FREE_BYTES, 0))
        / df.BYTES * 100,
        2
    ) AS USED_PCT
FROM
    (
        SELECT TABLESPACE_NAME, SUM(BYTES) BYTES
        FROM DBA_DATA_FILES
        GROUP BY TABLESPACE_NAME
    ) df
LEFT JOIN
    (
        SELECT TABLESPACE_NAME, SUM(BYTES) FREE_BYTES
        FROM DBA_FREE_SPACE
        GROUP BY TABLESPACE_NAME
    ) fs
ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
WHERE
    (df.BYTES - NVL(fs.FREE_BYTES, 0))
    / df.BYTES * 100 >= 90
ORDER BY USED_PCT DESC;


/*******************************************************************************
7. TABLESPACES ABOVE 95%
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    ROUND(df.BYTES / 1024 / 1024, 2) AS ALLOCATED_MB,
    ROUND(NVL(fs.FREE_BYTES, 0) / 1024 / 1024, 2) AS FREE_MB,
    ROUND(
        (df.BYTES - NVL(fs.FREE_BYTES, 0))
        / df.BYTES * 100,
        2
    ) AS USED_PCT
FROM
    (
        SELECT TABLESPACE_NAME, SUM(BYTES) BYTES
        FROM DBA_DATA_FILES
        GROUP BY TABLESPACE_NAME
    ) df
LEFT JOIN
    (
        SELECT TABLESPACE_NAME, SUM(BYTES) FREE_BYTES
        FROM DBA_FREE_SPACE
        GROUP BY TABLESPACE_NAME
    ) fs
ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
WHERE
    (df.BYTES - NVL(fs.FREE_BYTES, 0))
    / df.BYTES * 100 >= 95
ORDER BY USED_PCT DESC;


/*******************************************************************************
8. CHECK DATAFILES
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB,
    STATUS
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;


/*******************************************************************************
9. DATAFILES WITH AUTOEXTEND ENABLED
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB,
    ROUND(
        (MAXBYTES - BYTES) / 1024 / 1024,
        2
    ) AS REMAINING_AUTOEXTEND_MB
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'YES'
ORDER BY REMAINING_AUTOEXTEND_MB;


/*******************************************************************************
10. DATAFILES WITH AUTOEXTEND DISABLED
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'NO'
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
11. DATAFILES NEAR MAXIMUM AUTOEXTEND SIZE
*******************************************************************************/

SELECT
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB,
    ROUND(
        BYTES / NULLIF(MAXBYTES, 0) * 100,
        2
    ) AS MAXSIZE_USED_PCT
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'YES'
AND MAXBYTES > 0
AND BYTES / MAXBYTES * 100 >= 90
ORDER BY MAXSIZE_USED_PCT DESC;


/*******************************************************************************
12. CHECK DATAFILE INCREMENT
*******************************************************************************/

SELECT
    FILE_NAME,
    TABLESPACE_NAME,
    AUTOEXTENSIBLE,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    ROUND(INCREMENT_BY * 8192 / 1024 / 1024, 2) AS INCREMENT_MB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME;


/*
NOTE:
The exact block size should be obtained from DBA_TABLESPACES rather than
assuming 8 KB if the database uses a different block size.

For a more accurate calculation:
*/

SELECT
    df.FILE_NAME,
    df.TABLESPACE_NAME,
    df.AUTOEXTENSIBLE,
    ROUND(df.BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    ts.BLOCK_SIZE,
    ROUND(
        df.INCREMENT_BY * ts.BLOCK_SIZE / 1024 / 1024,
        2
    ) AS INCREMENT_MB
FROM DBA_DATA_FILES df
JOIN DBA_TABLESPACES ts
ON df.TABLESPACE_NAME = ts.TABLESPACE_NAME
ORDER BY df.TABLESPACE_NAME;


/*******************************************************************************
13. CHECK FREE SPACE EXTENTS
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    COUNT(*) AS FREE_EXTENTS,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS FREE_MB,
    ROUND(MAX(BYTES) / 1024 / 1024, 2) AS LARGEST_FREE_EXTENT_MB
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
ORDER BY FREE_MB DESC;


/*******************************************************************************
14. FIND TABLESPACES WITH SMALL LARGEST FREE EXTENT
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS TOTAL_FREE_MB,
    ROUND(MAX(BYTES) / 1024 / 1024, 2) AS LARGEST_FREE_EXTENT_MB
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
ORDER BY LARGEST_FREE_EXTENT_MB;


/*******************************************************************************
15. FIND TOP SEGMENTS BY SIZE
*******************************************************************************/

SELECT *
FROM
(
    SELECT
        OWNER,
        SEGMENT_NAME,
        SEGMENT_TYPE,
        TABLESPACE_NAME,
        ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
    FROM DBA_SEGMENTS
    ORDER BY BYTES DESC
)
WHERE ROWNUM <= 20;


/*******************************************************************************
16. TOP SEGMENTS IN A PARTICULAR TABLESPACE
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = UPPER('&TABLESPACE_NAME')
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


/*******************************************************************************
17. SEGMENT GROWTH BY OWNER
*******************************************************************************/

SELECT
    OWNER,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS TOTAL_MB
FROM DBA_SEGMENTS
GROUP BY OWNER
ORDER BY TOTAL_MB DESC;


/*******************************************************************************
18. SEGMENT GROWTH BY TABLESPACE
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS SEGMENT_MB
FROM DBA_SEGMENTS
GROUP BY TABLESPACE_NAME
ORDER BY SEGMENT_MB DESC;


/*******************************************************************************
19. TOP TABLES BY SIZE
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME AS TABLE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE = 'TABLE'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


/*******************************************************************************
20. TOP INDEXES BY SIZE
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME AS INDEX_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE LIKE 'INDEX%'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


/*******************************************************************************
21. SEGMENT EXTENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    COUNT(*) AS EXTENT_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_EXTENTS
WHERE TABLESPACE_NAME = UPPER('&TABLESPACE_NAME')
GROUP BY
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME
ORDER BY SIZE_MB DESC;


/*******************************************************************************
22. FIND HIGHEST USED EXTENT IN A DATAFILE
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    ROUND(MAX(BLOCK_ID + BLOCKS) * 8192 / 1024 / 1024, 2)
        AS APPROX_USED_END_MB
FROM DBA_EXTENTS e
JOIN DBA_DATA_FILES df
ON e.FILE_ID = df.FILE_ID
GROUP BY
    FILE_ID,
    FILE_NAME
ORDER BY APPROX_USED_END_MB DESC;


/*
For databases with a non-8K block size, use:

MAX(BLOCK_ID + BLOCKS) * tablespace block size

The query below avoids assuming 8K.
*/

SELECT
    e.FILE_ID,
    df.FILE_NAME,
    e.TABLESPACE_NAME,
    ROUND(
        MAX(e.BLOCK_ID + e.BLOCKS)
        * ts.BLOCK_SIZE
        / 1024 / 1024,
        2
    ) AS USED_END_MB
FROM DBA_EXTENTS e
JOIN DBA_DATA_FILES df
ON e.FILE_ID = df.FILE_ID
JOIN DBA_TABLESPACES ts
ON e.TABLESPACE_NAME = ts.TABLESPACE_NAME
GROUP BY
    e.FILE_ID,
    df.FILE_NAME,
    e.TABLESPACE_NAME,
    ts.BLOCK_SIZE
ORDER BY USED_END_MB DESC;


/*******************************************************************************
23. ORA-03297 TROUBLESHOOTING
*******************************************************************************/

/*
ERROR:
ORA-03297: file contains used data beyond requested RESIZE value

MEANING:
Oracle cannot shrink the datafile because allocated extents exist beyond
the requested target size.
*/

SELECT
    e.FILE_ID,
    df.FILE_NAME,
    e.OWNER,
    e.SEGMENT_NAME,
    e.SEGMENT_TYPE,
    e.BLOCK_ID,
    e.BLOCKS,
    ROUND(
        (e.BLOCK_ID + e.BLOCKS)
        * ts.BLOCK_SIZE / 1024 / 1024,
        2
    ) AS END_POSITION_MB
FROM DBA_EXTENTS e
JOIN DBA_DATA_FILES df
ON e.FILE_ID = df.FILE_ID
JOIN DBA_TABLESPACES ts
ON e.TABLESPACE_NAME = ts.TABLESPACE_NAME
WHERE e.FILE_ID = &FILE_ID
ORDER BY END_POSITION_MB DESC
FETCH FIRST 20 ROWS ONLY;


/*******************************************************************************
24. SAFE DATAFILE RESIZE CHECK
*******************************************************************************/

/*
DO NOT execute RESIZE immediately.

First determine the highest used extent.
*/

SELECT
    df.FILE_NAME,
    ROUND(df.BYTES / 1024 / 1024, 2) AS CURRENT_SIZE_MB,
    ROUND(
        NVL(MAX(
            (e.BLOCK_ID + e.BLOCKS)
            * ts.BLOCK_SIZE
        ), 0) / 1024 / 1024,
        2
    ) AS HIGHEST_USED_MB
FROM DBA_DATA_FILES df
JOIN DBA_TABLESPACES ts
ON df.TABLESPACE_NAME = ts.TABLESPACE_NAME
LEFT JOIN DBA_EXTENTS e
ON df.FILE_ID = e.FILE_ID
GROUP BY
    df.FILE_NAME,
    df.BYTES
ORDER BY df.FILE_NAME;


/*******************************************************************************
25. ORA-01653 TROUBLESHOOTING
*******************************************************************************/

/*
ORA-01653:
unable to extend table in tablespace

Typical causes:
1. Tablespace has insufficient free space
2. Datafile reached MAXSIZE
3. AUTOEXTEND disabled
4. Filesystem is full
5. ASM diskgroup is full
6. Datafile cannot grow
7. Segment needs a larger extent
*/

SELECT
    df.TABLESPACE_NAME,
    ROUND(SUM(df.BYTES) / 1024 / 1024, 2) AS ALLOCATED_MB,
    ROUND(NVL(SUM(fs.FREE_BYTES),0) / 1024 / 1024, 2) AS FREE_MB
FROM DBA_DATA_FILES df
LEFT JOIN
(
    SELECT
        TABLESPACE_NAME,
        SUM(BYTES) FREE_BYTES
    FROM DBA_FREE_SPACE
    GROUP BY TABLESPACE_NAME
) fs
ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
GROUP BY df.TABLESPACE_NAME
ORDER BY ALLOCATED_MB DESC;


/*******************************************************************************
26. ORA-01654 TROUBLESHOOTING
*******************************************************************************/

/*
ORA-01654:
unable to extend index

First identify the index.
Then check:
1. Index tablespace
2. Tablespace free space
3. Datafile capacity
4. AUTOEXTEND
5. ASM/filesystem capacity
*/

SELECT
    OWNER,
    SEGMENT_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE LIKE 'INDEX%'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


/*******************************************************************************
27. ORA-01652 TEMPORARY SPACE TROUBLESHOOTING
*******************************************************************************/

/*
ORA-01652:
unable to extend temp segment

Common causes:
1. TEMP tablespace full
2. Large ORDER BY
3. Large GROUP BY
4. Hash joins
5. CREATE INDEX
6. Sort operations
7. Poor SQL execution plan
8. Large parallel operations
*/

SELECT
    TABLESPACE_NAME,
    ROUND(TABLESPACE_SIZE * BLOCK_SIZE / 1024 / 1024, 2)
        AS TOTAL_MB,
    ROUND(FREE_SPACE * BLOCK_SIZE / 1024 / 1024, 2)
        AS FREE_MB
FROM V$TEMP_SPACE_HEADER;


/*******************************************************************************
28. TEMPFILE INFORMATION
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_TEMP_FILES
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
29. TEMP USAGE BY SESSION
*******************************************************************************/

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.SQL_ID,
    su.TABLESPACE,
    ROUND(su.BLOCKS * ts.BLOCK_SIZE / 1024 / 1024, 2)
        AS TEMP_MB
FROM V$SORT_USAGE su
JOIN V$SESSION s
ON su.SESSION_ADDR = s.SADDR
JOIN DBA_TABLESPACES ts
ON su.TABLESPACE = ts.TABLESPACE_NAME
ORDER BY TEMP_MB DESC;


/*******************************************************************************
30. TOP TEMP USERS
*******************************************************************************/

SELECT
    s.USERNAME,
    ROUND(
        SUM(su.BLOCKS * ts.BLOCK_SIZE)
        / 1024 / 1024,
        2
    ) AS TEMP_MB
FROM V$SORT_USAGE su
JOIN V$SESSION s
ON su.SESSION_ADDR = s.SADDR
JOIN DBA_TABLESPACES ts
ON su.TABLESPACE = ts.TABLESPACE_NAME
GROUP BY s.USERNAME
ORDER BY TEMP_MB DESC;


/*******************************************************************************
31. TEMP SQL_ID CONSUMPTION
*******************************************************************************/

SELECT
    s.SQL_ID,
    s.USERNAME,
    ROUND(
        SUM(su.BLOCKS * ts.BLOCK_SIZE)
        / 1024 / 1024,
        2
    ) AS TEMP_MB
FROM V$SORT_USAGE su
JOIN V$SESSION s
ON su.SESSION_ADDR = s.SADDR
JOIN DBA_TABLESPACES ts
ON su.TABLESPACE = ts.TABLESPACE_NAME
GROUP BY
    s.SQL_ID,
    s.USERNAME
ORDER BY TEMP_MB DESC;


/*******************************************************************************
32. TEMPFILE AUTOEXTEND
*******************************************************************************/

SELECT
    FILE_NAME,
    TABLESPACE_NAME,
    AUTOEXTENSIBLE,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_TEMP_FILES
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
33. ORA-30036 UNDO TROUBLESHOOTING
*******************************************************************************/

/*
ORA-30036:
unable to extend segment by ... in undo tablespace

Check:
1. UNDO tablespace size
2. Datafile autoextend
3. Filesystem/ASM capacity
4. Long-running transactions
5. Undo generation rate
6. UNDO_RETENTION
7. Current transactions
*/

SELECT
    TABLESPACE_NAME,
    STATUS,
    CONTENTS,
    EXTENT_MANAGEMENT,
    SEGMENT_SPACE_MANAGEMENT
FROM DBA_TABLESPACES
WHERE CONTENTS = 'UNDO';


/*******************************************************************************
34. UNDO DATAFILES
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME IN
(
    SELECT VALUE
    FROM V$PARAMETER
    WHERE NAME = 'undo_tablespace'
);


/*******************************************************************************
35. CURRENT UNDO CONFIGURATION
*******************************************************************************/

SELECT
    NAME,
    VALUE
FROM V$PARAMETER
WHERE NAME IN
(
    'undo_management',
    'undo_tablespace',
    'undo_retention'
);


/*******************************************************************************
36. V$UNDOSTAT MONITORING
*******************************************************************************/

SELECT
    BEGIN_TIME,
    END_TIME,
    TXNCOUNT,
    UNDOBLKS,
    MAXQUERYLEN,
    SSOLDERRCNT,
    NOSPACEERRCNT,
    TUNED_UNDORETENTION
FROM V$UNDOSTAT
ORDER BY BEGIN_TIME DESC;


/*******************************************************************************
37. CHECK UNDO SPACE ERRORS
*******************************************************************************/

SELECT
    BEGIN_TIME,
    END_TIME,
    NOSPACEERRCNT,
    SSOLDERRCNT,
    MAXQUERYLEN,
    TUNED_UNDORETENTION
FROM V$UNDOSTAT
WHERE NOSPACEERRCNT > 0
   OR SSOLDERRCNT > 0
ORDER BY BEGIN_TIME DESC;


/*******************************************************************************
38. CURRENT TRANSACTIONS
*******************************************************************************/

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.SQL_ID,
    t.USED_UBLK,
    t.USED_UREC,
    t.START_TIME
FROM V$TRANSACTION t
JOIN V$SESSION s
ON t.SES_ADDR = s.SADDR
ORDER BY t.USED_UBLK DESC;


/*******************************************************************************
39. TOP UNDO-CONSUMING TRANSACTIONS
*******************************************************************************/

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.SQL_ID,
    t.USED_UBLK,
    t.USED_UREC
FROM V$TRANSACTION t
JOIN V$SESSION s
ON t.SES_ADDR = s.SADDR
ORDER BY t.USED_UBLK DESC;


/*******************************************************************************
40. ORA-01555 TROUBLESHOOTING
*******************************************************************************/

/*
ORA-01555:
snapshot too old

Common space-related causes:
1. Insufficient UNDO
2. High DML rate
3. Long-running query
4. Undo overwritten too quickly
5. Poor UNDO sizing

Check:
*/

SELECT
    BEGIN_TIME,
    END_TIME,
    MAXQUERYLEN,
    TUNED_UNDORETENTION,
    SSOLDERRCNT,
    UNDOBLKS,
    TXNCOUNT
FROM V$UNDOSTAT
ORDER BY BEGIN_TIME DESC;


/*******************************************************************************
41. ORA-01536 USER QUOTA ISSUE
*******************************************************************************/

/*
ORA-01536:
space quota exceeded for tablespace

This is NOT necessarily a tablespace-full problem.

The user may have:
    TABLESPACE FREE SPACE = 500 GB
but:
    USER QUOTA = 5 GB
    USER USAGE = 5 GB

Check DBA_TS_QUOTAS.
*/

SELECT
    USERNAME,
    TABLESPACE_NAME,
    BYTES,
    MAX_BYTES
FROM DBA_TS_QUOTAS
WHERE USERNAME = UPPER('&USERNAME');


/*******************************************************************************
42. QUOTA USAGE
*******************************************************************************/

SELECT
    USERNAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
    CASE
        WHEN MAX_BYTES = -1 THEN 'UNLIMITED'
        ELSE TO_CHAR(
            ROUND(MAX_BYTES / 1024 / 1024, 2)
        )
    END AS QUOTA_MB
FROM DBA_TS_QUOTAS
ORDER BY USERNAME, TABLESPACE_NAME;


/*******************************************************************************
43. QUOTA ALERT ABOVE 90%
*******************************************************************************/

SELECT
    USERNAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
    ROUND(MAX_BYTES / 1024 / 1024, 2) AS QUOTA_MB,
    ROUND(BYTES / MAX_BYTES * 100, 2) AS USED_PCT
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES > 0
AND BYTES / MAX_BYTES * 100 >= 90
ORDER BY USED_PCT DESC;


/*******************************************************************************
44. UNLIMITED TABLESPACE PRIVILEGE
*******************************************************************************/

SELECT
    GRANTEE,
    PRIVILEGE
FROM DBA_SYS_PRIVS
WHERE PRIVILEGE = 'UNLIMITED TABLESPACE'
ORDER BY GRANTEE;


/*******************************************************************************
45. USERS WITHOUT UNLIMITED TABLESPACE
*******************************************************************************/

SELECT
    USERNAME,
    ACCOUNT_STATUS,
    DEFAULT_TABLESPACE,
    TEMPORARY_TABLESPACE
FROM DBA_USERS
WHERE ORACLE_MAINTAINED = 'N'
ORDER BY USERNAME;


/*******************************************************************************
46. CHECK DEFAULT TABLESPACE
*******************************************************************************/

SELECT
    PROPERTY_NAME,
    PROPERTY_VALUE
FROM DATABASE_PROPERTIES
WHERE PROPERTY_NAME IN
(
    'DEFAULT_PERMANENT_TABLESPACE',
    'DEFAULT_TEMP_TABLESPACE'
);


/*******************************************************************************
47. BIGFILE TABLESPACE CHECK
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    BIGFILE,
    STATUS,
    CONTENTS
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;


/*
BIGFILE = YES

Typical management:
    ALTER TABLESPACE <TS> RESIZE ...;
    ALTER DATABASE DATAFILE ... AUTOEXTEND ON ...;

Do not normally add multiple datafiles to a bigfile tablespace.
*/


/*******************************************************************************
48. FIND SMALLFILE TABLESPACES
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    BIGFILE
FROM DBA_TABLESPACES
WHERE BIGFILE = 'NO'
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
49. READ-ONLY TABLESPACE CHECK
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    STATUS
FROM DBA_TABLESPACES
WHERE STATUS <> 'ONLINE';


/*******************************************************************************
50. OFFLINE TABLESPACE CHECK
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    STATUS
FROM DBA_TABLESPACES
WHERE STATUS = 'OFFLINE';


/*******************************************************************************
51. DATAFILE STATUS CHECK
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    STATUS,
    ONLINE_STATUS
FROM V$DATAFILE
ORDER BY FILE_ID;


/*******************************************************************************
52. FILESYSTEM CHECK - LINUX
*******************************************************************************/

/*
Run at OS level:

df -h
df -i

Examples:

df -h /u01
df -h /prod
df -h /stage

Check inode usage:

df -i /u01

IMPORTANT:
Oracle may have enough logical tablespace free space but the filesystem
may not have enough physical space to extend the datafile.
*/


/*******************************************************************************
53. FIND DATAFILE LOCATIONS
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_DATA_FILES
ORDER BY FILE_NAME;


/*******************************************************************************
54. ASM SPACE CHECK
*******************************************************************************/

/*
Run from SQL*Plus if ASM views are available:

*/

SELECT
    NAME,
    STATE,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB
FROM V$ASM_DISKGROUP
ORDER BY NAME;


/*******************************************************************************
55. ASM DISKGROUP USAGE
*******************************************************************************/

SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    ROUND(
        (TOTAL_MB - FREE_MB)
        / TOTAL_MB * 100,
        2
    ) AS USED_PCT,
    USABLE_FILE_MB
FROM V$ASM_DISKGROUP
ORDER BY USED_PCT DESC;


/*******************************************************************************
56. ASM DISKGROUP ABOVE 90%
*******************************************************************************/

SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB,
    ROUND(
        (TOTAL_MB - FREE_MB)
        / TOTAL_MB * 100,
        2
    ) AS USED_PCT
FROM V$ASM_DISKGROUP
WHERE
    (TOTAL_MB - FREE_MB)
    / TOTAL_MB * 100 >= 90
ORDER BY USED_PCT DESC;


/*******************************************************************************
57. OMF DATAFILE LOCATIONS
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    FILE_NAME
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+%'
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
58. CHECK TEMP TABLESPACE GROUPS
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    TABLESPACE_GROUP
FROM DBA_TABLESPACES
WHERE CONTENTS = 'TEMPORARY'
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
59. CHECK TABLESPACE LOGGING
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    LOGGING,
    FORCE_LOGGING
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
60. SPACE TROUBLESHOOTING DECISION TREE
*******************************************************************************/

/*

                     SPACE ALERT
                          |
                          v
                +-------------------+
                | Which space type? |
                +-------------------+
                    /      |       \
                   /       |        \
                  v        v         v
             PERMANENT   TEMP       UNDO
                 |         |          |
                 v         v          v
           DBA_DATA_FILES V$TEMP   V$UNDOSTAT
           DBA_FREE_SPACE SPACE_HDR V$TRANSACTION
                 |         |          |
                 v         v          v
          Check free MB   Check SQL   Check transactions
                 |         |          |
                 v         v          v
           Check datafile Check temp  Check undo size
                 |         |          |
                 v         v          v
           Autoextend?   Add tempfile Autoextend?
                 |                    |
                 v                    v
           FS / ASM full?       FS / ASM full?
                 |
                 v
              Resolve
                 |
                 v
             Verify
*/


/*******************************************************************************
61. PERMANENT TABLESPACE TROUBLESHOOTING FLOW
*******************************************************************************/

/*

ORA-01653 / ORA-01654
        |
        v
Identify TABLESPACE
        |
        v
Check DBA_FREE_SPACE
        |
        +---- FREE SPACE AVAILABLE ----+
        |                               |
        v                               v
Check largest free extent          Check segment growth
        |
        v
Check datafiles
        |
        v
AUTOEXTEND?
   /          \
 YES           NO
 |             |
 v             v
Check MAXBYTES  Add/resize datafile
 |
 v
Reached MAXSIZE?
   /       \
 YES       NO
 |          |
 v          v
Increase    Check filesystem/ASM
MAXSIZE     capacity
 |
 v
Verify OS/ASM space
 |
 v
Resolve
 |
 v
Retry application
*/


/*******************************************************************************
62. REAL-TIME SCENARIO 1
    TABLESPACE 95% FULL
*******************************************************************************/

/*
Scenario:
Application team reports:

"USERS tablespace is 95% full."

Step 1:
*/

SELECT
    df.TABLESPACE_NAME,
    ROUND(df.BYTES / 1024 / 1024, 2) AS ALLOCATED_MB,
    ROUND(NVL(fs.FREE_BYTES, 0) / 1024 / 1024, 2) AS FREE_MB,
    ROUND(
        (df.BYTES - NVL(fs.FREE_BYTES, 0))
        / df.BYTES * 100,
        2
    ) AS USED_PCT
FROM
(
    SELECT TABLESPACE_NAME, SUM(BYTES) BYTES
    FROM DBA_DATA_FILES
    GROUP BY TABLESPACE_NAME
) df
LEFT JOIN
(
    SELECT TABLESPACE_NAME, SUM(BYTES) FREE_BYTES
    FROM DBA_FREE_SPACE
    GROUP BY TABLESPACE_NAME
) fs
ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
WHERE df.TABLESPACE_NAME = 'USERS';


/*
Step 2:
Find largest segments.
*/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'USERS'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


/*
Step 3:
Check datafiles.
*/

SELECT
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'USERS';


/*
Step 4:
Check filesystem or ASM capacity.

Step 5:
If approved, increase capacity.

Example:
*/

-- ALTER TABLESPACE USERS
-- ADD DATAFILE '/u01/oradata/DB/USERS02.dbf'
-- SIZE 10G
-- AUTOEXTEND ON
-- NEXT 1G
-- MAXSIZE 50G;


/*******************************************************************************
63. REAL-TIME SCENARIO 2
    ORA-01653
*******************************************************************************/

/*
Application:
ORA-01653: unable to extend table APP.ORDERS in tablespace DATA

Interview answer:

1. Identify the affected tablespace.
2. Check current tablespace usage.
3. Check free extents.
4. Check the affected segment size.
5. Check datafile AUTOEXTEND.
6. Check datafile MAXSIZE.
7. Check filesystem or ASM free space.
8. If required, resize or add a datafile after approval.
9. Verify tablespace usage.
10. Monitor application recovery.

Commands:
*/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE OWNER = 'APP'
AND SEGMENT_NAME = 'ORDERS';


/*******************************************************************************
64. REAL-TIME SCENARIO 3
    ORA-01654 INDEX EXTENSION FAILURE
*******************************************************************************/

/*
ORA-01654: unable to extend index

Check:
*/

SELECT
    OWNER,
    SEGMENT_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_NAME = UPPER('&INDEX_NAME');


/*
Then check the index tablespace:

*/

SELECT
    TABLESPACE_NAME,
    STATUS,
    CONTENTS
FROM DBA_TABLESPACES
WHERE TABLESPACE_NAME =
(
    SELECT TABLESPACE_NAME
    FROM DBA_SEGMENTS
    WHERE SEGMENT_NAME = UPPER('&INDEX_NAME')
    AND ROWNUM = 1
);


/*******************************************************************************
65. REAL-TIME SCENARIO 4
    ORA-01652 TEMP FULL
*******************************************************************************/

/*
Step 1:
Check TEMP.
*/

SELECT
    TABLESPACE_NAME,
    ROUND(TABLESPACE_SIZE * BLOCK_SIZE / 1024 / 1024, 2)
        AS TOTAL_MB,
    ROUND(FREE_SPACE * BLOCK_SIZE / 1024 / 1024, 2)
        AS FREE_MB
FROM V$TEMP_SPACE_HEADER;


/*
Step 2:
Find sessions consuming TEMP.
*/

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.SQL_ID,
    ROUND(
        su.BLOCKS * ts.BLOCK_SIZE / 1024 / 1024,
        2
    ) AS TEMP_MB
FROM V$SORT_USAGE su
JOIN V$SESSION s
ON su.SESSION_ADDR = s.SADDR
JOIN DBA_TABLESPACES ts
ON su.TABLESPACE = ts.TABLESPACE_NAME
ORDER BY TEMP_MB DESC;


/*
Step 3:
Find SQL_ID.

Step 4:
Investigate execution plan / sort / hash operation.

Step 5:
If required and approved, add tempfile.

Example:

ALTER TABLESPACE TEMP
ADD TEMPFILE '/u01/oradata/DB/temp02.dbf'
SIZE 10G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 30G;
*/


/*******************************************************************************
66. REAL-TIME SCENARIO 5
    ORA-30036 UNDO FULL
*******************************************************************************/

/*
Step 1:
Check current UNDO tablespace.
*/

SELECT VALUE
FROM V$PARAMETER
WHERE NAME = 'undo_tablespace';


/*
Step 2:
Check UNDO datafiles.
*/

SELECT
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME =
(
    SELECT VALUE
    FROM V$PARAMETER
    WHERE NAME = 'undo_tablespace'
);


/*
Step 3:
Check V$UNDOSTAT.
*/

SELECT
    BEGIN_TIME,
    TXNCOUNT,
    UNDOBLKS,
    MAXQUERYLEN,
    SSOLDERRCNT,
    NOSPACEERRCNT,
    TUNED_UNDORETENTION
FROM V$UNDOSTAT
ORDER BY BEGIN_TIME DESC;


/*
Step 4:
Check active transactions.
*/

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.SQL_ID,
    t.USED_UBLK,
    t.USED_UREC
FROM V$TRANSACTION t
JOIN V$SESSION s
ON t.SES_ADDR = s.SADDR
ORDER BY t.USED_UBLK DESC;


/*
Step 5:
Check filesystem/ASM.

Step 6:
Resize/add datafile if required and approved.
*/


/*******************************************************************************
67. REAL-TIME SCENARIO 6
    ORA-01536 QUOTA EXCEEDED
*******************************************************************************/

/*
Application:
ORA-01536: space quota exceeded for tablespace APP_DATA

Check:
*/

SELECT
    USERNAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
    CASE
        WHEN MAX_BYTES = -1 THEN 'UNLIMITED'
        ELSE TO_CHAR(
            ROUND(MAX_BYTES / 1024 / 1024, 2)
        )
    END AS QUOTA_MB
FROM DBA_TS_QUOTAS
WHERE USERNAME = UPPER('&USERNAME')
AND TABLESPACE_NAME = UPPER('&TABLESPACE_NAME');


/*
If approved:

ALTER USER APP_USER
QUOTA 10G ON APP_DATA;

OR:

ALTER USER APP_USER
QUOTA UNLIMITED ON APP_DATA;

Use UNLIMITED carefully.
*/


/*******************************************************************************
68. REAL-TIME SCENARIO 7
    ORA-03297
*******************************************************************************/

/*
Scenario:
DBA tries:

ALTER DATABASE DATAFILE
'/u01/oradata/DB/users01.dbf'
RESIZE 10G;

Oracle returns:

ORA-03297: file contains used data beyond requested RESIZE value

Solution:

1. Identify highest used extent.
2. Identify object occupying the space.
3. Determine whether object can be moved/reorganized.
4. Move/rebuild object if appropriate.
5. Recheck highest used extent.
6. Resize only to a safe value.

Never repeatedly reduce the datafile size without checking extents.
*/


/*******************************************************************************
69. REAL-TIME SCENARIO 8
    TABLESPACE FREE BUT DATAFILE CANNOT GROW
*******************************************************************************/

/*
Example:

TABLESPACE:
    100 GB allocated
    20 GB free

Datafile:
    AUTOEXTEND = YES
    MAXSIZE = 100 GB
    CURRENT SIZE = 100 GB

Result:
Tablespace has free space, but the individual datafile has reached MAXSIZE.

Action:
1. Add another datafile, OR
2. Increase MAXSIZE if infrastructure capacity permits.

For smallfile:
*/

-- ALTER DATABASE DATAFILE
-- '/u01/oradata/DB/users01.dbf'
-- AUTOEXTEND ON
-- MAXSIZE 150G;


/*******************************************************************************
70. REAL-TIME SCENARIO 9
    FILESYSTEM FULL
*******************************************************************************/

/*
Oracle:

ORA-03297 / ORA-01114 / datafile extension failure
or application errors may occur depending on operation.

Check OS:

df -h
df -i

Find large directories:

du -sh /u01/*
du -sh /prod/*
du -sh /stage/*

DO NOT delete Oracle files manually.

Do not delete:
    *.dbf
    control files
    online redo logs
    archived logs

unless following an approved recovery/cleanup procedure.
*/


/*******************************************************************************
71. REAL-TIME SCENARIO 10
    ASM DISKGROUP FULL
*******************************************************************************/

/*
Check:

*/

SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB,
    ROUND(
        (TOTAL_MB - FREE_MB)
        / TOTAL_MB * 100,
        2
    ) AS USED_PCT
FROM V$ASM_DISKGROUP
ORDER BY USED_PCT DESC;


/*
Possible actions:

1. Add ASM disk capacity.
2. Remove obsolete files using supported Oracle/ASM procedures.
3. Investigate database growth.
4. Review archive log destination usage.
5. Check RMAN backup/archivelog retention.
6. Coordinate with storage team.

Never manually delete ASM files from the operating system.
*/


/*******************************************************************************
72. DATAFILE CAPACITY VS TABLESPACE CAPACITY
*******************************************************************************/

/*

TABLESPACE CAPACITY

+------------------------------------------+
|             TABLESPACE                   |
|                                          |
|  Datafile 1        Datafile 2            |
|  50 GB             50 GB                 |
|                                          |
|  Free = 5 GB       Free = 10 GB          |
+------------------------------------------+

Total allocated = 100 GB
Total free      = 15 GB

But if Datafile 1 reached MAXSIZE and Datafile 2 is not autoextensible,
Oracle may still need a datafile resize/addition depending on the extent
allocation request.

Always check individual datafiles.
*/


/*******************************************************************************
73. CURRENT VS MAXIMUM CAPACITY
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS CURRENT_MB,
    ROUND(
        SUM(
            CASE
                WHEN AUTOEXTENSIBLE = 'YES'
                THEN MAXBYTES
                ELSE BYTES
            END
        ) / 1024 / 1024,
        2
    ) AS MAX_CAPACITY_MB
FROM DBA_DATA_FILES
GROUP BY TABLESPACE_NAME
ORDER BY CURRENT_MB DESC;


/*******************************************************************************
74. DATAFILE GROWTH HEADROOM
*******************************************************************************/

SELECT
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    AUTOEXTENSIBLE,
    ROUND(
        CASE
            WHEN AUTOEXTENSIBLE = 'YES'
            THEN MAXBYTES - BYTES
            ELSE 0
        END / 1024 / 1024,
        2
    ) AS AUTOEXTEND_HEADROOM_MB
FROM DBA_DATA_FILES
ORDER BY AUTOEXTEND_HEADROOM_MB;


/*******************************************************************************
75. TABLESPACE HEALTH CHECK
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    ROUND(df.BYTES / 1024 / 1024, 2) AS ALLOCATED_MB,
    ROUND(NVL(fs.FREE_BYTES, 0) / 1024 / 1024, 2) AS FREE_MB,
    ROUND(
        (df.BYTES - NVL(fs.FREE_BYTES, 0))
        / df.BYTES * 100,
        2
    ) AS USED_PCT,
    ts.STATUS,
    ts.CONTENTS,
    ts.BIGFILE
FROM
(
    SELECT
        TABLESPACE_NAME,
        SUM(BYTES) BYTES
    FROM DBA_DATA_FILES
    GROUP BY TABLESPACE_NAME
) df
JOIN DBA_TABLESPACES ts
ON df.TABLESPACE_NAME = ts.TABLESPACE_NAME
LEFT JOIN
(
    SELECT
        TABLESPACE_NAME,
        SUM(BYTES) FREE_BYTES
    FROM DBA_FREE_SPACE
    GROUP BY TABLESPACE_NAME
) fs
ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
ORDER BY USED_PCT DESC;


/*******************************************************************************
76. FIND TABLESPACES WITH NO AUTOEXTEND DATAFILES
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    COUNT(*) AS DATAFILE_COUNT
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'NO'
GROUP BY TABLESPACE_NAME
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
77. CHECK DATAFILE MAXSIZE
*******************************************************************************/

SELECT
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB,
    AUTOEXTENSIBLE
FROM DBA_DATA_FILES
ORDER BY
    TABLESPACE_NAME,
    CURRENT_MB DESC;


/*******************************************************************************
78. FIND LARGEST TABLESPACE
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_DATA_FILES
GROUP BY TABLESPACE_NAME
ORDER BY SIZE_GB DESC;


/*******************************************************************************
79. FIND FAST-GROWING OBJECTS
*******************************************************************************/

/*
Current database views provide current size, not historical growth.

For historical growth, use:
    AWR
    Statspack
    OEM
    Monitoring repository
    DBA_SEGMENTS snapshots

Example current snapshot:
*/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
ORDER BY BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
80. SEGMENT TYPES CONSUMING SPACE
*******************************************************************************/

SELECT
    SEGMENT_TYPE,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
GROUP BY SEGMENT_TYPE
ORDER BY SIZE_MB DESC;


/*******************************************************************************
81. OWNER-WISE SPACE CONSUMPTION
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_TYPE,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
GROUP BY
    OWNER,
    SEGMENT_TYPE
ORDER BY SIZE_MB DESC;


/*******************************************************************************
82. FIND OBJECTS IN USERS TABLESPACE
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'USERS'
ORDER BY BYTES DESC;


/*******************************************************************************
83. FIND TABLESPACE USERS
*******************************************************************************/

SELECT
    USERNAME,
    DEFAULT_TABLESPACE,
    TEMPORARY_TABLESPACE,
    ACCOUNT_STATUS
FROM DBA_USERS
WHERE DEFAULT_TABLESPACE = UPPER('&TABLESPACE_NAME')
ORDER BY USERNAME;


/*******************************************************************************
84. CHECK QUOTA AND TABLESPACE TOGETHER
*******************************************************************************/

SELECT
    q.USERNAME,
    q.TABLESPACE_NAME,
    ROUND(q.BYTES / 1024 / 1024, 2) AS USER_USED_MB,
    CASE
        WHEN q.MAX_BYTES = -1 THEN NULL
        ELSE ROUND(q.MAX_BYTES / 1024 / 1024, 2)
    END AS USER_QUOTA_MB,
    ROUND(
        (
            SELECT SUM(df.BYTES)
            FROM DBA_DATA_FILES df
            WHERE df.TABLESPACE_NAME = q.TABLESPACE_NAME
        ) / 1024 / 1024,
        2
    ) AS TS_ALLOCATED_MB
FROM DBA_TS_QUOTAS q
ORDER BY q.TABLESPACE_NAME, q.USERNAME;


/*******************************************************************************
85. CHECK UNUSABLE INDEXES AFTER SPACE ISSUES
*******************************************************************************/

SELECT
    OWNER,
    INDEX_NAME,
    TABLE_NAME,
    STATUS,
    TABLESPACE_NAME
FROM DBA_INDEXES
WHERE STATUS <> 'VALID'
ORDER BY OWNER, INDEX_NAME;


/*******************************************************************************
86. CHECK INVALID OBJECTS AFTER MAINTENANCE
*******************************************************************************/

SELECT
    OWNER,
    OBJECT_TYPE,
    COUNT(*) AS INVALID_COUNT
FROM DBA_OBJECTS
WHERE STATUS = 'INVALID'
GROUP BY OWNER, OBJECT_TYPE
ORDER BY OWNER, OBJECT_TYPE;


/*******************************************************************************
87. PRODUCTION CHANGE EXAMPLE
*******************************************************************************/

/*
Example change:

Requirement:
Increase USERS tablespace capacity by 10 GB.

Pre-check:
*/

SELECT
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024 / 1024, 2) AS MAX_GB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'USERS';


/*
Check:
    df -h <mount_point>

or ASM:

*/

SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB
FROM V$ASM_DISKGROUP;


/*
After approval:

-- ALTER TABLESPACE USERS
-- ADD DATAFILE '/u01/oradata/DB/users03.dbf'
-- SIZE 10G
-- AUTOEXTEND ON
-- NEXT 1G
-- MAXSIZE 50G;


/*
Post-check:
*/

SELECT
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB,
    AUTOEXTENSIBLE
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'USERS';


/*******************************************************************************
88. RCA TEMPLATE
*******************************************************************************/

/*

INCIDENT:
---------
Tablespace reached 95%.

IMPACT:
-------
Application insert/update operations started failing.

ERROR:
------
ORA-01653

ROOT CAUSE:
-----------
Application table growth exhausted available tablespace capacity.

INVESTIGATION:
--------------
1. Tablespace usage checked.
2. Datafile capacity checked.
3. Autoextend checked.
4. Filesystem/ASM capacity checked.
5. Largest segments identified.
6. Application growth reviewed.

RESOLUTION:
-----------
Additional datafile added / existing datafile resized.

PREVENTION:
-----------
1. Configure 80/90/95% monitoring.
2. Review autoextend configuration.
3. Monitor segment growth.
4. Review capacity planning.
5. Configure OEM alerts.
6. Perform periodic housekeeping.
*/


/*******************************************************************************
89. DAILY SPACE MONITORING CHECKLIST
*******************************************************************************/

/*

[ ] Check permanent tablespaces
[ ] Check TEMP
[ ] Check UNDO
[ ] Check datafile autoextend
[ ] Check datafile MAXSIZE
[ ] Check filesystem usage
[ ] Check ASM diskgroup usage
[ ] Check largest segments
[ ] Check tablespace growth
[ ] Check quota usage
[ ] Check long-running transactions
[ ] Check TEMP-consuming SQL
[ ] Check ORA-01653
[ ] Check ORA-01654
[ ] Check ORA-01652
[ ] Check ORA-30036
[ ] Check ORA-01536
[ ] Check ORA-03297
[ ] Review OEM alerts
[ ] Review application growth
*/


/*******************************************************************************
90. INTERVIEW QUICK ANSWERS
*******************************************************************************/

/*

Q1. How do you troubleshoot ORA-01653?

Answer:
I first identify the affected tablespace and check DBA_FREE_SPACE and
DBA_DATA_FILES. Then I check datafile AUTOEXTEND, MAXBYTES, and filesystem
or ASM capacity. I also identify the segment causing the growth. Based on
the available infrastructure capacity and change approval, I either resize
the datafile or add a new datafile. Finally, I verify the tablespace usage
and application recovery.


Q2. What is ORA-01652?

Answer:
ORA-01652 means Oracle cannot extend a temporary segment because sufficient
TEMP space is unavailable. I check TEMP usage, identify sessions and SQL_IDs
consuming TEMP, investigate large sorts/hash operations, and then add or
resize tempfile capacity if required.


Q3. What is ORA-30036?

Answer:
ORA-30036 occurs when Oracle cannot extend an undo segment because the UNDO
tablespace does not have sufficient space. I check UNDO datafiles,
V$UNDOSTAT, active transactions, undo generation, and storage capacity.


Q4. What is ORA-01536?

Answer:
ORA-01536 is a user quota problem. I check DBA_TS_QUOTAS. The tablespace
itself may still have plenty of free space, but the user may have reached
the assigned quota.


Q5. What is ORA-03297?

Answer:
ORA-03297 occurs when a datafile cannot be resized smaller because used
extents exist beyond the requested size. I identify the highest used extent
and determine which objects occupy that area before attempting any resize.


Q6. Tablespace is 95% full. What will you do?

Answer:
I do not immediately add space. First I check whether the growth is expected,
identify the largest segments, check datafile autoextend and MAXSIZE, and
verify filesystem or ASM capacity. Then I take the appropriate approved
capacity action and monitor the growth afterward.


Q7. Tablespace has free space but application gets ORA-01653. Why?

Answer:
Possible reasons include the datafile reaching MAXSIZE, inability of the
datafile to grow because of filesystem/ASM limitations, or an extent
allocation requirement that cannot be satisfied by available space.


Q8. How do you troubleshoot TEMP full?

Answer:
I check V$TEMP_SPACE_HEADER and DBA_TEMP_FILES, identify sessions consuming
TEMP through V$SORT_USAGE, identify SQL_IDs, investigate sorts/hash joins,
and add tempfile capacity if required.


Q9. How do you troubleshoot filesystem full?

Answer:
I check df -h and df -i, identify the mount containing Oracle files, check
large files/directories, and coordinate storage or cleanup. I never manually
delete Oracle datafiles, control files, or redo logs.


Q10. How do you troubleshoot ASM full?

Answer:
I check V$ASM_DISKGROUP for TOTAL_MB, FREE_MB and USABLE_FILE_MB. Then I
identify database/storage growth and coordinate ASM disk addition or
approved cleanup.


Q11. Bigfile vs smallfile troubleshooting?

Answer:
For a smallfile tablespace, multiple datafiles can be added. For a bigfile
tablespace, the normal approach is to resize or autoextend the single
datafile rather than adding multiple datafiles.


Q12. What is your space troubleshooting approach?

Answer:

ALERT
  |
  v
IDENTIFY SPACE TYPE
  |
  +--> PERMANENT
  |
  +--> TEMP
  |
  +--> UNDO
  |
  +--> QUOTA
  |
  v
CHECK DATABASE SPACE
  |
  v
CHECK DATAFILE/TEMPFILE
  |
  v
CHECK AUTOEXTEND/MAXSIZE
  |
  v
CHECK FS/ASM
  |
  v
IDENTIFY SPACE CONSUMER
  |
  v
TAKE APPROVED ACTION
  |
  v
VERIFY
  |
  v
MONITOR


/*******************************************************************************
91. GOLDEN RULES
*******************************************************************************/

/*
1. Never blindly use MAXSIZE UNLIMITED.
2. Always check filesystem/ASM capacity.
3. Check individual datafiles, not only tablespace percentage.
4. Check segment growth for unexpected space consumption.
5. Separate permanent, TEMP, UNDO and quota problems.
6. Use DBA_FREE_SPACE for permanent tablespace free space.
7. Use V$TEMP_SPACE_HEADER for TEMP monitoring.
8. Use V$UNDOSTAT for UNDO workload monitoring.
9. Use DBA_TS_QUOTAS for user quota problems.
10. For ORA-03297, identify the highest used extent before shrinking.
11. For bigfile tablespaces, use resize/autoextend.
12. Do not manually delete Oracle files from the OS.
13. Follow change-management procedures in production.
14. Always perform pre-check and post-check.
15. Monitor space growth continuously.
*/


/*******************************************************************************
92. FINAL SPACE HEALTH CHECK
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    ROUND(df.BYTES / 1024 / 1024, 2) AS ALLOCATED_MB,
    ROUND(NVL(fs.FREE_BYTES, 0) / 1024 / 1024, 2) AS FREE_MB,
    ROUND(
        (df.BYTES - NVL(fs.FREE_BYTES, 0))
        / df.BYTES * 100,
        2
    ) AS USED_PCT,
    ts.STATUS,
    ts.CONTENTS,
    ts.BIGFILE
FROM
(
    SELECT
        TABLESPACE_NAME,
        SUM(BYTES) BYTES
    FROM DBA_DATA_FILES
    GROUP BY TABLESPACE_NAME
) df
JOIN DBA_TABLESPACES ts
ON df.TABLESPACE_NAME = ts.TABLESPACE_NAME
LEFT JOIN
(
    SELECT
        TABLESPACE_NAME,
        SUM(BYTES) FREE_BYTES
    FROM DBA_FREE_SPACE
    GROUP BY TABLESPACE_NAME
) fs
ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
ORDER BY USED_PCT DESC;


/*******************************************************************************
END OF FILE
*******************************************************************************/

/*
===============================================================================
SPACE TROUBLESHOOTING SUMMARY

Permanent Tablespace
-------------------
DBA_DATA_FILES
DBA_FREE_SPACE
DBA_SEGMENTS
DBA_EXTENTS

TEMP
----
DBA_TEMP_FILES
V$TEMP_SPACE_HEADER
V$SORT_USAGE

UNDO
----
DBA_DATA_FILES
V$UNDOSTAT
V$TRANSACTION

QUOTA
-----
DBA_TS_QUOTAS
DBA_SYS_PRIVS

ASM
---
V$ASM_DISKGROUP

OS
--
df -h
df -i

COMMON ERRORS
-------------
ORA-01653  -> Unable to extend table/segment
ORA-01654  -> Unable to extend index
ORA-01652  -> Unable to extend temp segment
ORA-30036  -> Unable to extend undo segment
ORA-01536  -> User quota exceeded
ORA-03297  -> Used extents exist beyond resize target

STANDARD DBA FLOW
-----------------
Identify
   ↓
Measure
   ↓
Find Consumer
   ↓
Check Capacity
   ↓
Check Autoextend
   ↓
Check FS / ASM
   ↓
Resolve
   ↓
Verify
   ↓
Monitor
===============================================================================
*/
```
