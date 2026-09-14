```sql
/*
===============================================================================
FILE NAME : 09_asm_tablespaces.sql
MODULE    : Tablespace Management
TOPIC     : ASM Tablespace Management
VERSION   : Oracle 12c / 19c

PURPOSE
-------
This script covers:

1. ASM architecture for tablespaces
2. ASM diskgroup discovery
3. ASM space monitoring
4. Tablespace creation on ASM
5. OMF + ASM
6. Multiple ASM datafiles
7. Bigfile tablespaces on ASM
8. TEMP on ASM
9. UNDO on ASM
10. Resize / autoextend
11. Add datafiles
12. Drop datafiles
13. ASM diskgroup capacity analysis
14. Tablespace vs ASM space troubleshooting
15. ORA-01653 / ORA-01654 / ORA-01652 / ORA-30036
16. Real-time production scenarios
17. Interview questions

IMPORTANT
---------
- ASM SQL views are normally queried from the database instance.
- ASM diskgroup management itself is normally performed using ASM tools/views
  such as V$ASM_DISKGROUP and V$ASM_DISK.
- Do not resize or drop production files without change approval.
- Always check ASM free space before adding/autoextending files.
===============================================================================
*/


/*******************************************************************************
1. DATABASE INFORMATION
*******************************************************************************/

SELECT
    NAME,
    DB_UNIQUE_NAME,
    OPEN_MODE,
    DATABASE_ROLE
FROM V$DATABASE;


/*******************************************************************************
2. INSTANCE INFORMATION
*******************************************************************************/

SELECT
    INSTANCE_NAME,
    HOST_NAME,
    VERSION,
    STATUS
FROM V$INSTANCE;


/*******************************************************************************
3. DATABASE DATAFILE LOCATIONS
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;


/*******************************************************************************
4. IDENTIFY ASM DATAFILES
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+%'
ORDER BY TABLESPACE_NAME, FILE_ID;


/*******************************************************************************
5. IDENTIFY FILES ON FILESYSTEM
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_DATA_FILES
WHERE FILE_NAME NOT LIKE '+%'
ORDER BY TABLESPACE_NAME, FILE_ID;


/*******************************************************************************
6. ASM DISKGROUP OVERVIEW
*******************************************************************************/

SELECT
    NAME,
    STATE,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    ROUND(
        (TOTAL_MB - FREE_MB) / TOTAL_MB * 100,
        2
    ) AS USED_PCT
FROM V$ASM_DISKGROUP
ORDER BY NAME;


/*******************************************************************************
7. ASM DISKGROUP DETAILS
*******************************************************************************/

SELECT
    GROUP_NUMBER,
    NAME,
    STATE,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    REQUIRED_MIRROR_FREE_MB,
    USABLE_FILE_MB,
    OFFLINE_DISKS
FROM V$ASM_DISKGROUP
ORDER BY GROUP_NUMBER;


/*
IMPORTANT
---------
USABLE_FILE_MB is especially useful in ASM because it considers mirroring
requirements.

Do not interpret FREE_MB alone as the amount of application data that can
always be safely added.
*/


/*******************************************************************************
8. ASM DISKGROUP USAGE PERCENTAGE
*******************************************************************************/

SELECT
    NAME,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    ROUND(
        (TOTAL_MB - FREE_MB) / TOTAL_MB * 100,
        2
    ) AS USED_PCT,
    ROUND(
        FREE_MB / TOTAL_MB * 100,
        2
    ) AS FREE_PCT
FROM V$ASM_DISKGROUP
ORDER BY USED_PCT DESC;


/*******************************************************************************
9. ASM DISKGROUPS ABOVE 80%
*******************************************************************************/

SELECT
    NAME,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    ROUND(
        (TOTAL_MB - FREE_MB) / TOTAL_MB * 100,
        2
    ) AS USED_PCT
FROM V$ASM_DISKGROUP
WHERE
    (TOTAL_MB - FREE_MB) / TOTAL_MB * 100 >= 80
ORDER BY USED_PCT DESC;


/*******************************************************************************
10. ASM DISKGROUPS ABOVE 90%
*******************************************************************************/

SELECT
    NAME,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB,
    ROUND(
        (TOTAL_MB - FREE_MB) / TOTAL_MB * 100,
        2
    ) AS USED_PCT
FROM V$ASM_DISKGROUP
WHERE
    (TOTAL_MB - FREE_MB) / TOTAL_MB * 100 >= 90
ORDER BY USED_PCT DESC;


/*******************************************************************************
11. ASM DISKS
*******************************************************************************/

SELECT
    GROUP_NUMBER,
    DISK_NUMBER,
    NAME,
    PATH,
    HEADER_STATUS,
    MODE_STATUS,
    STATE,
    TOTAL_MB,
    FREE_MB
FROM V$ASM_DISK
ORDER BY GROUP_NUMBER, DISK_NUMBER;


/*******************************************************************************
12. ASM DISKS BY DISKGROUP
*******************************************************************************/

SELECT
    d.GROUP_NUMBER,
    g.NAME AS DISKGROUP_NAME,
    d.DISK_NUMBER,
    d.NAME AS DISK_NAME,
    d.PATH,
    d.STATE,
    d.HEADER_STATUS,
    d.MODE_STATUS,
    d.TOTAL_MB,
    d.FREE_MB
FROM V$ASM_DISK d
LEFT JOIN V$ASM_DISKGROUP g
ON d.GROUP_NUMBER = g.GROUP_NUMBER
ORDER BY d.GROUP_NUMBER, d.DISK_NUMBER;


/*******************************************************************************
13. ASM DISKS NOT IN USE
*******************************************************************************/

SELECT
    GROUP_NUMBER,
    NAME,
    PATH,
    HEADER_STATUS,
    MODE_STATUS,
    STATE,
    TOTAL_MB
FROM V$ASM_DISK
WHERE GROUP_NUMBER = 0
ORDER BY PATH;


/*
GROUP_NUMBER = 0 commonly identifies disks that are not currently assigned
to a diskgroup from the ASM instance perspective.
*/


/*******************************************************************************
14. ASM DISKS WITH PROBLEM STATES
*******************************************************************************/

SELECT
    GROUP_NUMBER,
    NAME,
    PATH,
    STATE,
    HEADER_STATUS,
    MODE_STATUS,
    TOTAL_MB,
    FREE_MB
FROM V$ASM_DISK
WHERE STATE <> 'NORMAL'
   OR MODE_STATUS <> 'ONLINE'
ORDER BY GROUP_NUMBER, NAME;


/*******************************************************************************
15. TABLESPACE OVERVIEW
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    STATUS,
    CONTENTS,
    EXTENT_MANAGEMENT,
    ALLOCATION_TYPE,
    SEGMENT_SPACE_MANAGEMENT,
    BIGFILE,
    LOGGING
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
16. ASM TABLESPACES
*******************************************************************************/

SELECT DISTINCT
    TABLESPACE_NAME
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+%'
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
17. ASM DATAFILE SIZE
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    FILE_ID,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+%'
ORDER BY TABLESPACE_NAME, FILE_ID;


/*******************************************************************************
18. CREATE ASM TABLESPACE
*******************************************************************************/

/*
If ASM diskgroup +DATA exists:

CREATE TABLESPACE APP_DATA
DATAFILE '+DATA'
SIZE 10G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 50G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

IMPORTANT:
---------
When only the ASM diskgroup is specified and OMF is enabled/configured,
Oracle can generate the ASM filename.
*/


/*******************************************************************************
19. CREATE ASM TABLESPACE WITH EXPLICIT OMF
*******************************************************************************/

/*
If DB_CREATE_FILE_DEST is configured:

SHOW PARAMETER db_create_file_dest;

Then:

CREATE TABLESPACE APP_DATA
DATAFILE SIZE 10G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 50G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

Oracle creates the datafile using the configured OMF destination.
*/


/*******************************************************************************
20. CHECK OMF CONFIGURATION
*******************************************************************************/

SELECT
    NAME,
    VALUE
FROM V$PARAMETER
WHERE NAME IN
(
    'db_create_file_dest',
    'db_recovery_file_dest'
);


/*******************************************************************************
21. SET OMF DESTINATION - EXAMPLE
*******************************************************************************/

/*
Example:

ALTER SYSTEM SET DB_CREATE_FILE_DEST='+DATA' SCOPE=BOTH;

Verify:

SHOW PARAMETER db_create_file_dest;

Only perform parameter changes after validating your environment.
*/


/*******************************************************************************
22. CREATE TABLESPACE USING ASM DISKGROUP
*******************************************************************************/

/*
Example:

CREATE TABLESPACE USERS_DATA
DATAFILE '+DATA/DBPROD/DATAFILE/users_data01.dbf'
SIZE 20G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;
*/


/*******************************************************************************
23. ADD SECOND ASM DATAFILE
*******************************************************************************/

/*
ALTER TABLESPACE USERS_DATA
ADD DATAFILE '+DATA'
SIZE 20G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G;
*/


/*******************************************************************************
24. ADD MULTIPLE ASM DATAFILES
*******************************************************************************/

/*
ALTER TABLESPACE USERS_DATA
ADD DATAFILE '+DATA' SIZE 20G
AUTOEXTEND ON NEXT 1G MAXSIZE 100G;

ALTER TABLESPACE USERS_DATA
ADD DATAFILE '+DATA' SIZE 20G
AUTOEXTEND ON NEXT 1G MAXSIZE 100G;
*/


/*******************************************************************************
25. CHECK DATAFILE COUNT
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    COUNT(*) AS DATAFILE_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_GB
FROM DBA_DATA_FILES
GROUP BY TABLESPACE_NAME
ORDER BY TOTAL_GB DESC;


/*******************************************************************************
26. RESIZE ASM DATAFILE
*******************************************************************************/

/*
Example:

ALTER DATABASE DATAFILE
'+DATA/DBPROD/DATAFILE/users_data01.dbf'
RESIZE 30G;

Use the exact FILE_NAME returned by DBA_DATA_FILES.
*/


/*******************************************************************************
27. CHECK CURRENT DATAFILE SIZE BEFORE RESIZE
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+%'
AND TABLESPACE_NAME = UPPER('&TABLESPACE_NAME')
ORDER BY FILE_ID;


/*******************************************************************************
28. ENABLE AUTOEXTEND
*******************************************************************************/

/*
ALTER DATABASE DATAFILE
'+DATA/DBPROD/DATAFILE/users_data01.dbf'
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G;
*/


/*******************************************************************************
29. DISABLE AUTOEXTEND
*******************************************************************************/

/*
ALTER DATABASE DATAFILE
'+DATA/DBPROD/DATAFILE/users_data01.dbf'
AUTOEXTEND OFF;
*/


/*******************************************************************************
30. CHECK AUTOEXTEND CONFIGURATION
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    AUTOEXTENSIBLE,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS CURRENT_GB,
    ROUND(MAXBYTES / 1024 / 1024 / 1024, 2) AS MAX_GB,
    ROUND(INCREMENT_BY * 8192 / 1024 / 1024, 2) AS NEXT_MB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;


/*
NOTE:
The NEXT_MB calculation assumes an 8K database block size.

For a generic version, join DBA_TABLESPACES and use BLOCK_SIZE.
*/


/*******************************************************************************
31. GENERIC AUTOEXTEND QUERY
*******************************************************************************/

SELECT
    df.FILE_ID,
    df.FILE_NAME,
    df.TABLESPACE_NAME,
    df.AUTOEXTENSIBLE,
    ROUND(df.BYTES / 1024 / 1024 / 1024, 2) AS CURRENT_GB,
    ROUND(
        CASE
            WHEN df.AUTOEXTENSIBLE = 'YES'
            THEN df.MAXBYTES
            ELSE df.BYTES
        END / 1024 / 1024 / 1024,
        2
    ) AS EFFECTIVE_MAX_GB,
    ROUND(
        df.INCREMENT_BY * ts.BLOCK_SIZE / 1024 / 1024,
        2
    ) AS NEXT_MB
FROM DBA_DATA_FILES df
JOIN DBA_TABLESPACES ts
ON df.TABLESPACE_NAME = ts.TABLESPACE_NAME
ORDER BY df.TABLESPACE_NAME, df.FILE_ID;


/*******************************************************************************
32. BIGFILE TABLESPACE ON ASM
*******************************************************************************/

/*
Example:

CREATE BIGFILE TABLESPACE BIG_DATA
DATAFILE '+DATA'
SIZE 50G
AUTOEXTEND ON
NEXT 5G
MAXSIZE 500G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

BIGFILE:
--------
One datafile represents the entire tablespace.

Do NOT normally use ADD DATAFILE for a bigfile tablespace.
Use RESIZE or AUTOEXTEND instead.
*/


/*******************************************************************************
33. CHECK BIGFILE TABLESPACES
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    BIGFILE,
    BLOCK_SIZE,
    STATUS,
    CONTENTS
FROM DBA_TABLESPACES
WHERE BIGFILE = 'YES';


/*******************************************************************************
34. RESIZE BIGFILE TABLESPACE
*******************************************************************************/

/*
ALTER TABLESPACE BIG_DATA
RESIZE 100G;
*/


/*******************************************************************************
35. ENABLE BIGFILE AUTOEXTEND
*******************************************************************************/

/*
ALTER TABLESPACE BIG_DATA
AUTOEXTEND ON
NEXT 5G
MAXSIZE 500G;
*/


/*******************************************************************************
36. TEMP TABLESPACE ON ASM
*******************************************************************************/

/*
Create:

CREATE TEMPORARY TABLESPACE TEMP_ASM
TEMPFILE '+DATA'
SIZE 20G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G
EXTENT MANAGEMENT LOCAL
UNIFORM SIZE 1M;
*/


/*******************************************************************************
37. TEMPFILE INFORMATION
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024 / 1024, 2) AS MAX_GB
FROM DBA_TEMP_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;


/*******************************************************************************
38. ASM TEMPFILES
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_TEMP_FILES
WHERE FILE_NAME LIKE '+%'
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
39. ADD ASM TEMPFILE
*******************************************************************************/

/*
ALTER TABLESPACE TEMP_ASM
ADD TEMPFILE '+DATA'
SIZE 20G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G;
*/


/*******************************************************************************
40. RESIZE ASM TEMPFILE
*******************************************************************************/

/*
ALTER DATABASE TEMPFILE
'+DATA/DBPROD/TEMPFILE/temp01.dbf'
RESIZE 30G;
*/


/*******************************************************************************
41. AUTOEXTEND TEMPFILE
*******************************************************************************/

/*
ALTER DATABASE TEMPFILE
'+DATA/DBPROD/TEMPFILE/temp01.dbf'
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G;
*/


/*******************************************************************************
42. TEMP SPACE USAGE
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    ROUND(TABLESPACE_SIZE / 1024 / 1024, 2) AS TOTAL_MB,
    ROUND(FREE_SPACE / 1024 / 1024, 2) AS FREE_MB,
    ROUND(
        (TABLESPACE_SIZE - FREE_SPACE)
        / TABLESPACE_SIZE * 100,
        2
    ) AS USED_PCT
FROM DBA_TEMP_FREE_SPACE
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
43. TEMP SPACE HEADER
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    TABLESPACE_SIZE,
    FREE_SPACE,
    ROUND(
        (TABLESPACE_SIZE - FREE_SPACE)
        / TABLESPACE_SIZE * 100,
        2
    ) AS USED_PCT
FROM V$TEMP_SPACE_HEADER
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
44. TEMP USAGE BY SESSION
*******************************************************************************/

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.SQL_ID,
    u.TABLESPACE,
    ROUND(u.BLOCKS * ts.BLOCK_SIZE / 1024 / 1024, 2) AS TEMP_MB
FROM V$SORT_USAGE u
JOIN V$SESSION s
ON u.SESSION_ADDR = s.SADDR
JOIN DBA_TABLESPACES ts
ON u.TABLESPACE = ts.TABLESPACE_NAME
ORDER BY TEMP_MB DESC;


/*******************************************************************************
45. UNDO TABLESPACES
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    STATUS,
    CONTENTS,
    EXTENT_MANAGEMENT,
    SEGMENT_SPACE_MANAGEMENT,
    BIGFILE
FROM DBA_TABLESPACES
WHERE CONTENTS = 'UNDO';


*******************************************************************************
46. CURRENT UNDO CONFIGURATION
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
47. UNDO DATAFILES ON ASM
*******************************************************************************/

SELECT
    df.FILE_ID,
    df.FILE_NAME,
    df.TABLESPACE_NAME,
    ROUND(df.BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB,
    df.AUTOEXTENSIBLE,
    ROUND(df.MAXBYTES / 1024 / 1024 / 1024, 2) AS MAX_GB
FROM DBA_DATA_FILES df
JOIN DBA_TABLESPACES ts
ON df.TABLESPACE_NAME = ts.TABLESPACE_NAME
WHERE ts.CONTENTS = 'UNDO'
AND df.FILE_NAME LIKE '+%'
ORDER BY df.FILE_ID;


/*******************************************************************************
48. CREATE UNDO TABLESPACE ON ASM
*******************************************************************************/

/*
CREATE UNDO TABLESPACE UNDOTBS2
DATAFILE '+DATA'
SIZE 20G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G;
*/


/*******************************************************************************
49. SWITCH TO NEW UNDO TABLESPACE
*******************************************************************************/

/*
ALTER SYSTEM SET UNDO_TABLESPACE=UNDOTBS2 SCOPE=BOTH;

Verify:

SHOW PARAMETER undo_tablespace;
*/


/*******************************************************************************
50. CHECK UNDO USAGE
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    STATUS,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_UNDO_EXTENTS
GROUP BY TABLESPACE_NAME, STATUS
ORDER BY TABLESPACE_NAME, STATUS;


/*******************************************************************************
51. UNDO WORKLOAD MONITORING
*******************************************************************************/

SELECT
    BEGIN_TIME,
    END_TIME,
    UNDOTSN,
    UNDOBLKS,
    TXNCOUNT,
    MAXQUERYLEN,
    SSOLDERRCNT,
    NOSPACEERRCNT,
    TUNED_UNDORETENTION
FROM V$UNDOSTAT
ORDER BY BEGIN_TIME DESC
FETCH FIRST 24 ROWS ONLY;


/*******************************************************************************
52. ASM FILE LOCATION FOR UNDO
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME LIKE 'UNDO%'
AND FILE_NAME LIKE '+%'
ORDER BY FILE_ID;


/*******************************************************************************
53. TABLESPACE USAGE FOR ASM TABLESPACES
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    ROUND(SUM(df.BYTES) / 1024 / 1024 / 1024, 2) AS ALLOCATED_GB,
    ROUND(NVL(fs.FREE_BYTES,0) / 1024 / 1024 / 1024, 2) AS FREE_GB,
    ROUND(
        (
            SUM(df.BYTES) - NVL(fs.FREE_BYTES,0)
        )
        / SUM(df.BYTES) * 100,
        2
    ) AS USED_PCT
FROM DBA_DATA_FILES df
LEFT JOIN
(
    SELECT
        TABLESPACE_NAME,
        SUM(BYTES) AS FREE_BYTES
    FROM DBA_FREE_SPACE
    GROUP BY TABLESPACE_NAME
) fs
ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
WHERE df.FILE_NAME LIKE '+%'
GROUP BY
    df.TABLESPACE_NAME,
    fs.FREE_BYTES
ORDER BY USED_PCT DESC;


/*******************************************************************************
54. TABLESPACE CAPACITY VS ASM CAPACITY
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    ROUND(SUM(df.BYTES) / 1024 / 1024 / 1024, 2) AS TS_ALLOCATED_GB,
    ROUND(
        SUM(
            CASE
                WHEN df.AUTOEXTENSIBLE = 'YES'
                THEN df.MAXBYTES
                ELSE df.BYTES
            END
        ) / 1024 / 1024 / 1024,
        2
    ) AS TS_EFFECTIVE_MAX_GB
FROM DBA_DATA_FILES df
WHERE df.FILE_NAME LIKE '+%'
GROUP BY df.TABLESPACE_NAME
ORDER BY TS_ALLOCATED_GB DESC;


/*
This query shows database-file capacity.

ASM capacity must be checked separately using V$ASM_DISKGROUP.
*/


/*******************************************************************************
55. ASM DISKGROUP + DATABASE FILE CORRELATION
*******************************************************************************/

/*
A common operational approach:

DATABASE
   |
   +---- TABLESPACE
   |         |
   |         +---- DATAFILE
   |                  |
   |                  v
   |              +DATA
   |                  |
   |                  v
   |             ASM DISKGROUP
   |                  |
   |                  v
   |             ASM DISKS
*/


/*******************************************************************************
56. ASM ARCHITECTURE DIAGRAM
*******************************************************************************/

/*

                  ORACLE DATABASE
                         |
              +----------+----------+
              |                     |
         Tablespaces             TEMP/UNDO
              |                     |
              v                     v
          Datafiles             Tempfiles
              |                     |
              +----------+----------+
                         |
                         v
                    ASM DISKGROUP
                       +DATA
                         |
              +----------+----------+
              |          |          |
             Disk1      Disk2      Disk3
              |          |          |
              +----------+----------+
                         |
                   Physical Storage


ASM provides:
-------------
- Striping
- Mirroring
- Rebalancing
- Centralized storage management
- Automatic file placement
- Diskgroup-level capacity management
*/


/*******************************************************************************
57. ASM REDUNDANCY
*******************************************************************************/

SELECT
    NAME,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    REQUIRED_MIRROR_FREE_MB,
    USABLE_FILE_MB
FROM V$ASM_DISKGROUP
ORDER BY NAME;


/*
Common redundancy types:

EXTERNAL
--------
ASM does not provide mirroring.
Storage array is expected to provide redundancy.

NORMAL
------
Two-way mirroring.

HIGH
----
Three-way mirroring.

Actual configuration depends on the storage architecture.
*/


/*******************************************************************************
58. ASM REBALANCE INFORMATION
*******************************************************************************/

SELECT
    GROUP_NUMBER,
    OPERATION,
    STATE,
    POWER,
    ACTUAL,
    SOFAR,
    EST_WORK,
    EST_RATE,
    EST_MINUTES
FROM V$ASM_OPERATION
ORDER BY GROUP_NUMBER, OPERATION;


/*******************************************************************************
59. ASM REBALANCE MONITORING
*******************************************************************************/

/*
When adding/removing disks, monitor:

SELECT
    GROUP_NUMBER,
    OPERATION,
    STATE,
    POWER,
    SOFAR,
    EST_WORK,
    EST_MINUTES
FROM V$ASM_OPERATION;
*/


/*******************************************************************************
60. ASM DISKGROUP ATTRIBUTE INFORMATION
*******************************************************************************/

SELECT
    NAME,
    VALUE,
    READ_ONLY
FROM V$ASM_ATTRIBUTE
ORDER BY NAME;


/*******************************************************************************
61. ASM DISKGROUP STATE CHECK
*******************************************************************************/

SELECT
    NAME,
    STATE,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB,
    OFFLINE_DISKS
FROM V$ASM_DISKGROUP
ORDER BY NAME;


/*******************************************************************************
62. ASM DISK FAILURE CHECK
*******************************************************************************/

SELECT
    GROUP_NUMBER,
    NAME,
    PATH,
    STATE,
    MODE_STATUS,
    HEADER_STATUS
FROM V$ASM_DISK
WHERE STATE IN
(
    'OFFLINE',
    'UNKNOWN',
    'NORMAL'
)
ORDER BY GROUP_NUMBER, NAME;


/*
For production monitoring, investigate any unexpected disk state immediately.
*/


/*******************************************************************************
63. ASM FILE NAME DISCOVERY
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+DATA%'
ORDER BY TABLESPACE_NAME, FILE_ID;


/*******************************************************************************
64. ASM TEMPFILE DISCOVERY
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME
FROM DBA_TEMP_FILES
WHERE FILE_NAME LIKE '+%'
ORDER BY TABLESPACE_NAME, FILE_ID;


/*******************************************************************************
65. ASM CONTROLFILE LOCATION
*******************************************************************************/

SHOW PARAMETER control_files;


/*******************************************************************************
66. ASM REDO LOG LOCATION
*******************************************************************************/

SELECT
    GROUP#,
    THREAD#,
    SEQUENCE#,
    BYTES,
    STATUS,
    MEMBER
FROM V$LOG l
JOIN V$LOGFILE lf
ON l.GROUP# = lf.GROUP#
ORDER BY GROUP#, MEMBER;


/*******************************************************************************
67. ASM FRA LOCATION
*******************************************************************************/

SELECT
    NAME,
    VALUE
FROM V$PARAMETER
WHERE NAME IN
(
    'db_recovery_file_dest',
    'db_recovery_file_dest_size'
);


/*******************************************************************************
68. FRA USAGE
*******************************************************************************/

SELECT
    NAME,
    SPACE_LIMIT,
    SPACE_USED,
    SPACE_RECLAIMABLE,
    NUMBER_OF_FILES
FROM V$RECOVERY_FILE_DEST;


/*******************************************************************************
69. FRA USAGE PERCENTAGE
*******************************************************************************/

SELECT
    NAME,
    ROUND(SPACE_LIMIT / 1024 / 1024 / 1024, 2) AS LIMIT_GB,
    ROUND(SPACE_USED / 1024 / 1024 / 1024, 2) AS USED_GB,
    ROUND(
        SPACE_USED / SPACE_LIMIT * 100,
        2
    ) AS USED_PCT,
    ROUND(
        SPACE_RECLAIMABLE / 1024 / 1024 / 1024,
        2
    ) AS RECLAIMABLE_GB
FROM V$RECOVERY_FILE_DEST;


/*******************************************************************************
70. ASM + FRA DIFFERENCE
*******************************************************************************/

/*
ASM DISKGROUP
-------------
Physical storage pool used by ASM-managed files.

FRA
---
Database recovery area configured through:

DB_RECOVERY_FILE_DEST
DB_RECOVERY_FILE_DEST_SIZE

FRA can itself reside in an ASM diskgroup.
*/


/*******************************************************************************
71. CHECK TABLESPACE DATAFILES AND ASM
*******************************************************************************/

SELECT
    t.TABLESPACE_NAME,
    t.BIGFILE,
    df.FILE_ID,
    df.FILE_NAME,
    ROUND(df.BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB,
    df.AUTOEXTENSIBLE
FROM DBA_TABLESPACES t
JOIN DBA_DATA_FILES df
ON t.TABLESPACE_NAME = df.TABLESPACE_NAME
WHERE df.FILE_NAME LIKE '+%'
ORDER BY t.TABLESPACE_NAME, df.FILE_ID;


/*******************************************************************************
72. FIND TABLESPACES CLOSE TO DATAFILE MAXSIZE
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS CURRENT_GB,
    ROUND(MAXBYTES / 1024 / 1024 / 1024, 2) AS MAX_GB,
    ROUND(
        BYTES / NULLIF(MAXBYTES,0) * 100,
        2
    ) AS MAXSIZE_USED_PCT
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'YES'
AND MAXBYTES > 0
ORDER BY MAXSIZE_USED_PCT DESC;


/*******************************************************************************
73. AUTOEXTEND FILES WITH LIMITED HEADROOM
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS CURRENT_GB,
    ROUND(MAXBYTES / 1024 / 1024 / 1024, 2) AS MAX_GB,
    ROUND(
        (MAXBYTES - BYTES) / 1024 / 1024 / 1024,
        2
    ) AS REMAINING_GB
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'YES'
AND MAXBYTES > BYTES
ORDER BY REMAINING_GB;


/*******************************************************************************
74. DATAFILES WITH AUTOEXTEND DISABLED
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+%'
AND AUTOEXTENSIBLE = 'NO'
ORDER BY BYTES DESC;


/*******************************************************************************
75. CHECK FREE SPACE INSIDE ASM TABLESPACE
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS FREE_GB
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
ORDER BY FREE_GB;


/*******************************************************************************
76. TOP SEGMENTS IN ASM TABLESPACE
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = UPPER('&TABLESPACE_NAME')
ORDER BY BYTES DESC
FETCH FIRST 30 ROWS ONLY;


/*******************************************************************************
77. ASM TABLESPACE FULL - TROUBLESHOOTING FLOW
*******************************************************************************/

/*

                 ORA-01653
                     |
                     v
              TABLESPACE FULL
                     |
          +----------+----------+
          |                     |
          v                     v
     Free space?           Datafile max?
          |                     |
       YES/NO                 YES/NO
          |                     |
          v                     v
   Check segment       Check AUTOEXTEND
                            |
                            v
                     Check ASM space
                            |
                 +----------+----------+
                 |                     |
                 v                     v
             ASM FREE              ASM FULL
                 |                     |
                 v                     v
          Add/resize file       Add ASM capacity
          if appropriate        / rebalance
*/


/*******************************************************************************
78. ORA-01653
*******************************************************************************/

/*
ORA-01653: unable to extend table

Meaning:
--------
A segment could not allocate the required next extent.

Check:

1. Tablespace free space
2. Datafile current size
3. Datafile MAXSIZE
4. AUTOEXTEND
5. ASM USABLE_FILE_MB
6. Underlying storage
7. Segment growth

Queries:

*/

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS FREE_MB
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
ORDER BY FREE_MB;


/*******************************************************************************
79. ORA-01654
*******************************************************************************/

/*
ORA-01654: unable to extend index

Check:

1. Index tablespace
2. Free space
3. Datafile capacity
4. AUTOEXTEND
5. ASM usable capacity
6. Index growth

Query:

*/

SELECT
    OWNER,
    INDEX_NAME,
    TABLE_NAME,
    TABLESPACE_NAME,
    STATUS
FROM DBA_INDEXES
WHERE OWNER = UPPER('&OWNER')
AND INDEX_NAME = UPPER('&INDEX_NAME');


/*******************************************************************************
80. ORA-01652
*******************************************************************************/

/*
ORA-01652: unable to extend temp segment

Check TEMP:

*/

SELECT
    TABLESPACE_NAME,
    ROUND(TABLESPACE_SIZE / 1024 / 1024 / 1024, 2) AS TOTAL_GB,
    ROUND(FREE_SPACE / 1024 / 1024 / 1024, 2) AS FREE_GB
FROM DBA_TEMP_FREE_SPACE;


/*******************************************************************************
81. ORA-30036
*******************************************************************************/

/*
ORA-30036: unable to extend segment by ... in undo tablespace

Check:

1. UNDO size
2. UNDO autoextend
3. ASM capacity
4. Long-running transactions
5. UNDO retention
6. Transaction workload
7. NOSPACEERRCNT

Query:
*/

SELECT
    BEGIN_TIME,
    END_TIME,
    UNDOBLKS,
    TXNCOUNT,
    MAXQUERYLEN,
    SSOLDERRCNT,
    NOSPACEERRCNT,
    TUNED_UNDORETENTION
FROM V$UNDOSTAT
ORDER BY BEGIN_TIME DESC
FETCH FIRST 24 ROWS ONLY;


/*******************************************************************************
82. ASM SPACE FULL
*******************************************************************************/

/*
If:

V$ASM_DISKGROUP.USABLE_FILE_MB

is critically low:

Do NOT simply keep enabling AUTOEXTEND.

First determine:

1. Which diskgroup is full?
2. Which database files consume space?
3. Is FRA consuming space?
4. Are archived logs retained unnecessarily?
5. Are backups occupying the diskgroup?
6. Is another database using the diskgroup?
7. Is diskgroup expansion required?
8. Is rebalancing required?

Then follow the approved storage/change process.
*/


/*******************************************************************************
83. FIND ALL ASM FILES
*******************************************************************************/

/*
From the database:

*/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+%'
ORDER BY FILE_NAME;


/*******************************************************************************
84. ASM SPACE INVESTIGATION
*******************************************************************************/

/*

ASM DISKGROUP
     |
     v
V$ASM_DISKGROUP
     |
     +--> TOTAL_MB
     +--> FREE_MB
     +--> USABLE_FILE_MB
     |
     v
DATABASE FILES
     |
     +--> DBA_DATA_FILES
     +--> DBA_TEMP_FILES
     +--> CONTROL_FILES
     +--> REDO LOGS
     +--> FRA
     |
     v
TOP SPACE CONSUMERS
     |
     v
RCA
*/


/*******************************************************************************
85. REAL-TIME SCENARIO 1
    TABLESPACE 95% FULL
*******************************************************************************/

/*
Situation:
---------
APP_DATA = 95%

Step 1:
Check tablespace:

*/

SELECT
    df.TABLESPACE_NAME,
    ROUND(SUM(df.BYTES) / 1024 / 1024 / 1024, 2) AS ALLOCATED_GB,
    ROUND(NVL(fs.FREE_BYTES,0) / 1024 / 1024 / 1024, 2) AS FREE_GB
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
WHERE df.TABLESPACE_NAME = 'APP_DATA'
GROUP BY
    df.TABLESPACE_NAME,
    fs.FREE_BYTES;


/*
Step 2:
Find largest segments.
*/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'APP_DATA'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


/*
Step 3:
Check ASM capacity.
*/

SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB
FROM V$ASM_DISKGROUP
WHERE NAME = 'DATA';


/*******************************************************************************
86. REAL-TIME SCENARIO 2
    DATAFILE REACHED MAXSIZE
*******************************************************************************/

/*
Check:

*/

SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS CURRENT_GB,
    ROUND(MAXBYTES / 1024 / 1024 / 1024, 2) AS MAX_GB,
    AUTOEXTENSIBLE
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'APP_DATA';


/*
If ASM has capacity and change is approved:

ALTER DATABASE DATAFILE
'<exact_asm_file_name>'
AUTOEXTEND ON
NEXT 1G
MAXSIZE 200G;

or resize/add another datafile as appropriate.
*/


/*******************************************************************************
87. REAL-TIME SCENARIO 3
    ASM DISKGROUP 92% FULL
*******************************************************************************/

/*
Approach:

1. Check V$ASM_DISKGROUP.
2. Check USABLE_FILE_MB.
3. Identify files/databases using diskgroup.
4. Check FRA.
5. Check backup/archive retention.
6. Check datafile growth.
7. Check TEMP/UNDO growth.
8. Coordinate with storage team if expansion is needed.
9. Add capacity using approved ASM procedure.
10. Monitor rebalance.

Never delete ASM files manually from the operating system.
*/


/*******************************************************************************
88. REAL-TIME SCENARIO 4
    TEMP TABLESPACE ON ASM FULL
*******************************************************************************/

/*
Check:

*/

SELECT
    TABLESPACE_NAME,
    ROUND(TABLESPACE_SIZE / 1024 / 1024 / 1024, 2) AS TOTAL_GB,
    ROUND(FREE_SPACE / 1024 / 1024 / 1024, 2) AS FREE_GB
FROM DBA_TEMP_FREE_SPACE;


/*
Then identify consumers:

*/

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.SQL_ID,
    u.TABLESPACE,
    ROUND(
        u.BLOCKS * ts.BLOCK_SIZE / 1024 / 1024,
        2
    ) AS TEMP_MB
FROM V$SORT_USAGE u
JOIN V$SESSION s
ON u.SESSION_ADDR = s.SADDR
JOIN DBA_TABLESPACES ts
ON u.TABLESPACE = ts.TABLESPACE_NAME
ORDER BY TEMP_MB DESC;


/*******************************************************************************
89. REAL-TIME SCENARIO 5
    UNDO TABLESPACE ON ASM FULL
*******************************************************************************/

/*
Check:

*/

SELECT
    BEGIN_TIME,
    UNDOBLKS,
    TXNCOUNT,
    MAXQUERYLEN,
    SSOLDERRCNT,
    NOSPACEERRCNT,
    TUNED_UNDORETENTION
FROM V$UNDOSTAT
ORDER BY BEGIN_TIME DESC
FETCH FIRST 24 ROWS ONLY;


/*
Then:

1. Check long transactions.
2. Check batch activity.
3. Check UNDO size.
4. Check autoextend.
5. Check ASM capacity.
6. Increase capacity if required.
7. Review UNDO sizing/retention.


Long-running transaction:

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.SQL_ID,
    t.START_TIME,
    t.USED_UBLK,
    t.USED_UREC
FROM V$TRANSACTION t
JOIN V$SESSION s
ON t.SES_ADDR = s.SADDR
ORDER BY t.USED_UBLK DESC;
*/


/*******************************************************************************
90. REAL-TIME SCENARIO 6
    NEED TO ADD ASM DATAFILE
*******************************************************************************/

/*
Pre-check:

*/

SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB
FROM V$ASM_DISKGROUP
WHERE NAME = 'DATA';


/*
Check tablespace:

*/

SELECT
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'APP_DATA';


/*
Then, if approved:

ALTER TABLESPACE APP_DATA
ADD DATAFILE '+DATA'
SIZE 20G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G;
*/


/*******************************************************************************
91. REAL-TIME SCENARIO 7
    BIGFILE ASM TABLESPACE FULL
*******************************************************************************/

/*
For a BIGFILE tablespace:

Do NOT add another datafile.

Check:

SELECT
    TABLESPACE_NAME,
    BIGFILE
FROM DBA_TABLESPACES
WHERE TABLESPACE_NAME = 'BIG_DATA';

Then check:

SELECT
    FILE_ID,
    FILE_NAME,
    BYTES,
    AUTOEXTENSIBLE,
    MAXBYTES
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'BIG_DATA';


If ASM has capacity and change is approved:

ALTER TABLESPACE BIG_DATA
AUTOEXTEND ON
NEXT 5G
MAXSIZE 500G;

or:

ALTER TABLESPACE BIG_DATA
RESIZE 200G;
*/


/*******************************************************************************
92. REAL-TIME SCENARIO 8
    AUTOEXTEND ON BUT TABLESPACE STILL FULL
*******************************************************************************/

/*
Possible reasons:

1. Datafile reached MAXSIZE.
2. ASM diskgroup has insufficient usable space.
3. Underlying storage capacity is exhausted.
4. Another datafile reached MAXSIZE.
5. AUTOEXTEND is disabled on other files.
6. Bigfile reached its configured limit.
7. User quota was reached.
8. Temp/undo has a separate issue.

Therefore always check all layers.
*/


/*******************************************************************************
93. REAL-TIME SCENARIO 9
    USER QUOTA VS ASM SPACE
*******************************************************************************/

/*
A user may receive:

ORA-01536: space quota exceeded

even when ASM has plenty of free space.

Check:

*/

SELECT
    USERNAME,
    TABLESPACE_NAME,
    BYTES,
    MAX_BYTES
FROM DBA_TS_QUOTAS
WHERE USERNAME = UPPER('&USERNAME');


/*
Storage hierarchy:

USER QUOTA
    |
    v
TABLESPACE
    |
    v
DATAFILE
    |
    v
ASM DISKGROUP
    |
    v
PHYSICAL STORAGE

Every layer must have sufficient capacity/permission.
*/


/*******************************************************************************
94. DROP ASM DATAFILE - WARNING
*******************************************************************************/

/*
Do NOT manually delete ASM datafiles.

Never do:

rm <asm-file>

ASM-managed database files must be managed using Oracle commands/tools.

For eligible cases:

ALTER TABLESPACE <tablespace>
DROP DATAFILE '<file_name>';

Before dropping:
----------------
1. Confirm exact file.
2. Confirm file is empty/eligible.
3. Confirm it is not the only required file.
4. Check application impact.
5. Take change approval.
6. Verify ASM and database afterward.
*/


/*******************************************************************************
95. DATAFILE HEADER STATUS
*******************************************************************************/

SELECT
    FILE_ID,
    FILE_NAME,
    STATUS,
    ONLINE_STATUS,
    ENABLED
FROM V$DATAFILE
ORDER BY FILE_ID;


/*******************************************************************************
96. ASM TABLESPACE HEALTH CHECK
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    COUNT(*) AS FILE_COUNT,
    ROUND(SUM(df.BYTES) / 1024 / 1024 / 1024, 2) AS ALLOCATED_GB,
    ROUND(
        SUM(
            CASE
                WHEN df.AUTOEXTENSIBLE = 'YES'
                THEN df.MAXBYTES
                ELSE df.BYTES
            END
        ) / 1024 / 1024 / 1024,
        2
    ) AS EFFECTIVE_MAX_GB
FROM DBA_DATA_FILES df
WHERE df.FILE_NAME LIKE '+%'
GROUP BY df.TABLESPACE_NAME
ORDER BY ALLOCATED_GB DESC;


/*******************************************************************************
97. ASM DISKGROUP HEALTH CHECK
*******************************************************************************/

SELECT
    NAME,
    STATE,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB,
    OFFLINE_DISKS,
    ROUND(
        (TOTAL_MB - FREE_MB) / TOTAL_MB * 100,
        2
    ) AS USED_PCT
FROM V$ASM_DISKGROUP
ORDER BY USED_PCT DESC;


/*******************************************************************************
98. ASM OPERATION HEALTH CHECK
*******************************************************************************/

SELECT
    GROUP_NUMBER,
    OPERATION,
    STATE,
    POWER,
    ACTUAL,
    SOFAR,
    EST_WORK,
    EST_RATE,
    EST_MINUTES
FROM V$ASM_OPERATION;


/*******************************************************************************
99. ASM DISK HEALTH CHECK
*******************************************************************************/

SELECT
    GROUP_NUMBER,
    DISK_NUMBER,
    NAME,
    PATH,
    STATE,
    MODE_STATUS,
    HEADER_STATUS,
    TOTAL_MB,
    FREE_MB
FROM V$ASM_DISK
ORDER BY GROUP_NUMBER, DISK_NUMBER;


/*******************************************************************************
100. FINAL ASM TABLESPACE REPORT
*******************************************************************************/

SELECT
    df.TABLESPACE_NAME,
    COUNT(*) AS DATAFILES,
    ROUND(SUM(df.BYTES) / 1024 / 1024 / 1024, 2) AS ALLOCATED_GB,
    ROUND(
        SUM(
            CASE
                WHEN df.AUTOEXTENSIBLE = 'YES'
                THEN df.MAXBYTES
                ELSE df.BYTES
            END
        ) / 1024 / 1024 / 1024,
        2
    ) AS EFFECTIVE_MAX_GB,
    SUM(
        CASE
            WHEN df.AUTOEXTENSIBLE = 'YES'
            THEN 1
            ELSE 0
        END
    ) AS AUTOEXTEND_FILES
FROM DBA_DATA_FILES df
WHERE df.FILE_NAME LIKE '+%'
GROUP BY df.TABLESPACE_NAME
ORDER BY ALLOCATED_GB DESC;


/*******************************************************************************
101. INTERVIEW QUESTIONS
*******************************************************************************/

/*
===============================================================================
Q1. What is ASM?
===============================================================================

ASM stands for Automatic Storage Management.

It is Oracle's storage management technology that provides storage pooling,
striping, mirroring and automatic rebalancing for Oracle database files.


===============================================================================
Q2. How do you identify ASM datafiles?
===============================================================================

SELECT
    FILE_NAME,
    TABLESPACE_NAME
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+%';


===============================================================================
Q3. Which view shows ASM diskgroup information?
===============================================================================

V$ASM_DISKGROUP

Important columns:

NAME
TYPE
STATE
TOTAL_MB
FREE_MB
USABLE_FILE_MB
OFFLINE_DISKS


===============================================================================
Q4. What is the difference between FREE_MB and USABLE_FILE_MB?
===============================================================================

FREE_MB represents free space in the diskgroup.

USABLE_FILE_MB represents space that can be safely used for files while
considering the diskgroup redundancy/mirroring requirements.

For capacity decisions, USABLE_FILE_MB is particularly important.


===============================================================================
Q5. How do you monitor ASM?
===============================================================================

I normally check:

V$ASM_DISKGROUP
V$ASM_DISK
V$ASM_OPERATION

I monitor:
- Diskgroup state
- Used/free capacity
- Usable file space
- Disk states
- Rebalance operations
- Offline disks


===============================================================================
Q6. How do you create a tablespace on ASM?
===============================================================================

Example:

CREATE TABLESPACE APP_DATA
DATAFILE '+DATA'
SIZE 20G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;


===============================================================================
Q7. How do you add a datafile to ASM?
===============================================================================

ALTER TABLESPACE APP_DATA
ADD DATAFILE '+DATA'
SIZE 20G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G;


===============================================================================
Q8. How do you resize an ASM datafile?
===============================================================================

ALTER DATABASE DATAFILE
'<exact ASM file name>'
RESIZE 30G;


===============================================================================
Q9. How do you troubleshoot ORA-01653 on ASM?
===============================================================================

My approach:

1. Identify the affected tablespace.
2. Check DBA_FREE_SPACE.
3. Check datafile current size.
4. Check AUTOEXTEND.
5. Check MAXSIZE.
6. Check ASM USABLE_FILE_MB.
7. Check segment growth.
8. If ASM has capacity, add/resize a datafile or increase max capacity.
9. If ASM is full, coordinate storage expansion/cleanup according to policy.
10. Verify after the change.


===============================================================================
Q10. What happens if AUTOEXTEND is ON but ASM is full?
===============================================================================

AUTOEXTEND does not create physical storage.

Oracle still needs ASM diskgroup capacity to extend the datafile.

If ASM cannot allocate the required space, the file cannot grow.


===============================================================================
Q11. Can you add datafiles to a BIGFILE tablespace?
===============================================================================

Normally no.

A BIGFILE tablespace is designed around a single datafile.

For growth, use RESIZE or AUTOEXTEND.


===============================================================================
Q12. How do you troubleshoot ORA-01652?
===============================================================================

ORA-01652 is generally related to TEMP space allocation.

I check:

1. TEMP size
2. TEMP free space
3. TEMPFILES
4. Sessions consuming TEMP
5. SQL_ID consuming TEMP
6. ASM capacity
7. Whether the SQL needs optimization
8. Whether additional TEMP capacity is required


===============================================================================
Q13. How do you troubleshoot ORA-30036?
===============================================================================

I check:

1. UNDO tablespace size
2. AUTOEXTEND
3. ASM capacity
4. V$UNDOSTAT
5. Long-running transactions
6. UNDO retention
7. NOSPACEERRCNT
8. Transaction workload

Then I decide whether capacity increase or workload/query investigation is
required.


===============================================================================
Q14. How do you monitor ASM rebalance?
===============================================================================

SELECT
    GROUP_NUMBER,
    OPERATION,
    STATE,
    SOFAR,
    EST_WORK,
    EST_MINUTES
FROM V$ASM_OPERATION;


===============================================================================
Q15. Can we delete ASM files from Linux?
===============================================================================

No.

ASM-managed database files should not be deleted using operating-system
commands.

Use Oracle-supported database/ASM commands and procedures.


===============================================================================
Q16. What is OMF?
===============================================================================

OMF stands for Oracle Managed Files.

Oracle can automatically create and manage database file names and locations
when appropriate initialization parameters or ASM destinations are configured.


===============================================================================
Q17. How do ASM, tablespace and datafile relate?

DATABASE
   |
TABLESPACE
   |
DATAFILE
   |
ASM DISKGROUP
   |
ASM DISKS
   |
STORAGE


===============================================================================
Q18. What is your production approach when ASM is 90% full?
===============================================================================

I don't immediately increase every datafile.

I first:

1. Identify the diskgroup.
2. Check USABLE_FILE_MB.
3. Identify databases/files consuming capacity.
4. Check FRA.
5. Check datafile growth.
6. Check TEMP/UNDO.
7. Check backup/archive retention.
8. Review recent growth.
9. Determine whether cleanup or storage expansion is appropriate.
10. Take change approval.
11. Execute.
12. Monitor ASM rebalance and capacity afterward.


/*******************************************************************************
102. GOLDEN RULES
*******************************************************************************/

/*
1. Always monitor V$ASM_DISKGROUP.
2. Pay attention to USABLE_FILE_MB.
3. Check V$ASM_DISK for disk health.
4. Check V$ASM_OPERATION during rebalance.
5. Never delete ASM files using rm.
6. AUTOEXTEND requires ASM capacity.
7. MAXSIZE limits datafile growth.
8. Bigfile tablespaces normally use resize/autoextend.
9. TEMP must be monitored separately.
10. UNDO must be monitored separately.
11. FRA may consume ASM capacity.
12. Large tablespaces should be correlated with large segments.
13. Always check ASM capacity before adding datafiles.
14. Do not blindly use MAXSIZE UNLIMITED.
15. Use change management for production.
16. Perform pre-check and post-check.
*/


/*******************************************************************************
103. COMPLETE ASM TROUBLESHOOTING FLOW
*******************************************************************************/

/*

                    TABLESPACE ALERT
                          |
                          v
                  DBA_DATA_FILES
                          |
                          v
                  Check FREE SPACE
                          |
              +-----------+-----------+
              |                       |
              v                       v
          Free Space               No/Low Free
              |                       |
              v                       v
           Monitor            Check Datafile
                                  |
                         +--------+--------+
                         |                 |
                         v                 v
                    MAXSIZE OK?       MAXSIZE REACHED
                         |                 |
                         v                 v
                    Check ASM        Check ASM
                         |                 |
                  +------+-------+         |
                  |              |         |
                  v              v         v
               Enough         Low/Full   Expand capacity
                ASM             ASM
                  |              |
                  v              v
             Resize/Add      Storage/ASM
              Datafile        Expansion
                  |
                  v
              Verify
                  |
                  v
              Monitor


FOR TEMP:
---------
TEMP usage
   |
   v
V$TEMP_SPACE_HEADER
   |
   v
V$SORT_USAGE
   |
   v
Find SQL/Session
   |
   +--> SQL tuning
   +--> Add TEMP capacity if required


FOR UNDO:
---------
UNDO usage
   |
   v
V$UNDOSTAT
   |
   v
Check transactions
   |
   v
Check ASM capacity
   |
   +--> Increase UNDO
   +--> Investigate workload
*/


/*******************************************************************************
104. DAILY ASM DBA CHECKLIST
*******************************************************************************/

/*
[ ] Check ASM diskgroup state
[ ] Check TOTAL_MB
[ ] Check FREE_MB
[ ] Check USABLE_FILE_MB
[ ] Check offline disks
[ ] Check disk states
[ ] Check rebalance operations
[ ] Check ASM tablespace growth
[ ] Check datafile autoextend
[ ] Check datafile MAXSIZE
[ ] Check TEMP usage
[ ] Check UNDO usage
[ ] Check FRA usage
[ ] Check large segments
[ ] Check tablespace usage
[ ] Review alerts
[ ] Review recent storage growth
*/


/*******************************************************************************
105. END OF FILE
*******************************************************************************/

/*
===============================================================================
09_asm_tablespaces.sql COMPLETE

KEY VIEWS
---------
V$ASM_DISKGROUP
V$ASM_DISK
V$ASM_OPERATION
V$ASM_ATTRIBUTE

DBA_DATA_FILES
DBA_TEMP_FILES
DBA_TABLESPACES
DBA_FREE_SPACE
DBA_SEGMENTS
DBA_UNDO_EXTENTS
V$UNDOSTAT
V$TEMP_SPACE_HEADER
V$SORT_USAGE
V$RECOVERY_FILE_DEST

KEY CONCEPTS
------------
ASM
Diskgroup
ASM Disk
Redundancy
Striping
Mirroring
Rebalance
USABLE_FILE_MB
OMF
ASM Datafile
ASM TEMP
ASM UNDO
Bigfile Tablespace
Autoextend
ASM Capacity

NEXT MODULE
-----------
10_tablespace_backup_recovery.sql

Recommended topics:
    Tablespace backup
    Datafile backup
    RMAN backup
    Tablespace recovery
    Datafile recovery
    Offline/online recovery
    SYSTEM/SYSAUX recovery
    ASM datafile recovery
    Point-in-time recovery
    Block recovery
    RMAN validation
===============================================================================
*/
```
