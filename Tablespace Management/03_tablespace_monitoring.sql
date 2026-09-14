# 03_tablespace_monitoring.sql

# Oracle Tablespace Monitoring — Practical DBA Script

-- ============================================================
-- Oracle DBA Notes
-- Module   : Tablespace Management
-- File     : 03_tablespace_monitoring.sql
-- Purpose  : Tablespace, Datafile, Tempfile and Space Monitoring
-- Versions : Oracle 12c / 19c
-- ============================================================

-- ============================================================
-- 1. DATABASE INFORMATION
-- ============================================================

SELECT
NAME AS DATABASE_NAME,
OPEN_MODE,
DATABASE_ROLE
FROM V$DATABASE;

SELECT
INSTANCE_NAME,
STATUS,
DATABASE_STATUS
FROM V$INSTANCE;

-- ============================================================
-- 2. LIST ALL TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
CONTENTS,
STATUS,
EXTENT_MANAGEMENT,
ALLOCATION_TYPE,
SEGMENT_SPACE_MANAGEMENT
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 3. PERMANENT TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
STATUS,
CONTENTS,
LOGGING,
EXTENT_MANAGEMENT,
ALLOCATION_TYPE,
SEGMENT_SPACE_MANAGEMENT
FROM DBA_TABLESPACES
WHERE CONTENTS = 'PERMANENT'
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 4. TEMPORARY TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
STATUS,
CONTENTS,
EXTENT_MANAGEMENT
FROM DBA_TABLESPACES
WHERE CONTENTS = 'TEMPORARY'
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 5. UNDO TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
STATUS,
CONTENTS
FROM DBA_TABLESPACES
WHERE CONTENTS = 'UNDO'
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 6. DATAFILE INFORMATION
-- ============================================================

SELECT
FILE_ID,
FILE_NAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
AUTOEXTENSIBLE,
ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_SIZE_MB,
ONLINE_STATUS
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;

-- ============================================================
-- 7. DATAFILE SIZE IN GB
-- ============================================================

SELECT
FILE_ID,
TABLESPACE_NAME,
FILE_NAME,
ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB,
AUTOEXTENSIBLE,
ROUND(MAXBYTES / 1024 / 1024 / 1024, 2) AS MAX_SIZE_GB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;

-- ============================================================
-- 8. AUTOEXTEND STATUS
-- ============================================================

SELECT
TABLESPACE_NAME,
FILE_NAME,
AUTOEXTENSIBLE,
ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_SIZE_MB,
ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_SIZE_MB,
ROUND(INCREMENT_BY * BLOCK_SIZE / 1024 / 1024, 2)
AS INCREMENT_MB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 9. DATAFILE AUTOEXTEND CHECK
-- ============================================================

SELECT
TABLESPACE_NAME,
FILE_NAME,
AUTOEXTENSIBLE,
ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB,
CASE
WHEN AUTOEXTENSIBLE = 'YES'
THEN ROUND((MAXBYTES - BYTES) / 1024 / 1024, 2)
ELSE 0
END AS AUTOEXTEND_AVAILABLE_MB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 10. TEMPFILE INFORMATION
-- ============================================================

SELECT
FILE_ID,
FILE_NAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
AUTOEXTENSIBLE,
ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_SIZE_MB
FROM DBA_TEMP_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;

-- ============================================================
-- 11. TEMPFILE AUTOEXTEND CHECK
-- ============================================================

SELECT
TABLESPACE_NAME,
FILE_NAME,
AUTOEXTENSIBLE,
ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_TEMP_FILES
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 12. FREE SPACE BY TABLESPACE
-- ============================================================

SELECT
TABLESPACE_NAME,
ROUND(SUM(BYTES) / 1024 / 1024, 2) AS FREE_SPACE_MB
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 13. USED SPACE BY TABLESPACE
-- ============================================================

SELECT
DF.TABLESPACE_NAME,
ROUND(SUM(DF.BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
ROUND(
(SUM(DF.BYTES) - NVL(FS.FREE_BYTES, 0)) / 1024 / 1024,
2
) AS USED_MB,
ROUND(
NVL(FS.FREE_BYTES, 0) / 1024 / 1024,
2
) AS FREE_MB
FROM DBA_DATA_FILES DF
LEFT JOIN
(
SELECT
TABLESPACE_NAME,
SUM(BYTES) AS FREE_BYTES
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
) FS
ON DF.TABLESPACE_NAME = FS.TABLESPACE_NAME
GROUP BY
DF.TABLESPACE_NAME,
FS.FREE_BYTES
ORDER BY DF.TABLESPACE_NAME;

-- ============================================================
-- 14. TABLESPACE USAGE PERCENTAGE
-- ============================================================

SELECT
DF.TABLESPACE_NAME,
ROUND(SUM(DF.BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
ROUND(
(SUM(DF.BYTES) - NVL(FS.FREE_BYTES, 0))
/ 1024 / 1024,
2
) AS USED_MB,
ROUND(
NVL(FS.FREE_BYTES, 0)
/ 1024 / 1024,
2
) AS FREE_MB,
ROUND(
(
(SUM(DF.BYTES) - NVL(FS.FREE_BYTES, 0))
/ SUM(DF.BYTES)
) * 100,
2
) AS USED_PERCENT
FROM DBA_DATA_FILES DF
LEFT JOIN
(
SELECT
TABLESPACE_NAME,
SUM(BYTES) AS FREE_BYTES
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
) FS
ON DF.TABLESPACE_NAME = FS.TABLESPACE_NAME
GROUP BY
DF.TABLESPACE_NAME,
FS.FREE_BYTES
ORDER BY USED_PERCENT DESC;

-- ============================================================
-- 15. TABLESPACES ABOVE 80% USED
-- ============================================================

SELECT *
FROM
(
SELECT
DF.TABLESPACE_NAME,
ROUND(SUM(DF.BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
ROUND(
(
SUM(DF.BYTES)
- NVL(FS.FREE_BYTES, 0)
) / 1024 / 1024,
2
) AS USED_MB,
ROUND(
NVL(FS.FREE_BYTES, 0) / 1024 / 1024,
2
) AS FREE_MB,
ROUND(
(
(
SUM(DF.BYTES)
- NVL(FS.FREE_BYTES, 0)
) / SUM(DF.BYTES)
) * 100,
2
) AS USED_PERCENT
FROM DBA_DATA_FILES DF
LEFT JOIN
(
SELECT
TABLESPACE_NAME,
SUM(BYTES) AS FREE_BYTES
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
) FS
ON DF.TABLESPACE_NAME = FS.TABLESPACE_NAME
GROUP BY
DF.TABLESPACE_NAME,
FS.FREE_BYTES
)
WHERE USED_PERCENT >= 80
ORDER BY USED_PERCENT DESC;

-- ============================================================
-- 16. CRITICAL TABLESPACES ABOVE 90%
-- ============================================================

SELECT *
FROM
(
SELECT
DF.TABLESPACE_NAME,
ROUND(SUM(DF.BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
ROUND(
(
SUM(DF.BYTES)
- NVL(FS.FREE_BYTES, 0)
) / 1024 / 1024,
2
) AS USED_MB,
ROUND(
NVL(FS.FREE_BYTES, 0) / 1024 / 1024,
2
) AS FREE_MB,
ROUND(
(
(
SUM(DF.BYTES)
- NVL(FS.FREE_BYTES, 0)
) / SUM(DF.BYTES)
) * 100,
2
) AS USED_PERCENT
FROM DBA_DATA_FILES DF
LEFT JOIN
(
SELECT
TABLESPACE_NAME,
SUM(BYTES) AS FREE_BYTES
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
) FS
ON DF.TABLESPACE_NAME = FS.TABLESPACE_NAME
GROUP BY
DF.TABLESPACE_NAME,
FS.FREE_BYTES
)
WHERE USED_PERCENT >= 90
ORDER BY USED_PERCENT DESC;

-- ============================================================
-- 17. TABLESPACES ABOVE 95% — CRITICAL ALERT
-- ============================================================

SELECT
TABLESPACE_NAME,
USED_PERCENT,
CASE
WHEN USED_PERCENT >= 95
THEN 'CRITICAL - IMMEDIATE ACTION REQUIRED'
WHEN USED_PERCENT >= 90
THEN 'WARNING - PLAN SPACE ADDITION'
WHEN USED_PERCENT >= 80
THEN 'WARNING'
ELSE 'NORMAL'
END AS STATUS
FROM
(
SELECT
DF.TABLESPACE_NAME,
ROUND(
(
(
SUM(DF.BYTES)
- NVL(FS.FREE_BYTES, 0)
) / SUM(DF.BYTES)
) * 100,
2
) AS USED_PERCENT
FROM DBA_DATA_FILES DF
LEFT JOIN
(
SELECT
TABLESPACE_NAME,
SUM(BYTES) AS FREE_BYTES
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
) FS
ON DF.TABLESPACE_NAME = FS.TABLESPACE_NAME
GROUP BY
DF.TABLESPACE_NAME,
FS.FREE_BYTES
)
ORDER BY USED_PERCENT DESC;

-- ============================================================
-- 18. DATAFILE FREE SPACE
-- ============================================================

SELECT
DF.FILE_ID,
DF.TABLESPACE_NAME,
DF.FILE_NAME,
ROUND(DF.BYTES / 1024 / 1024, 2) AS TOTAL_MB,
ROUND(NVL(FS.FREE_BYTES, 0) / 1024 / 1024, 2) AS FREE_MB
FROM DBA_DATA_FILES DF
LEFT JOIN
(
SELECT
FILE_ID,
SUM(BYTES) AS FREE_BYTES
FROM DBA_FREE_SPACE
GROUP BY FILE_ID
) FS
ON DF.FILE_ID = FS.FILE_ID
ORDER BY DF.TABLESPACE_NAME, DF.FILE_ID;

-- ============================================================
-- 19. LARGEST DATAFILES
-- ============================================================

SELECT
TABLESPACE_NAME,
FILE_NAME,
ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_DATA_FILES
ORDER BY BYTES DESC;

-- ============================================================
-- 20. LARGEST FREE EXTENTS
-- ============================================================

SELECT
TABLESPACE_NAME,
FILE_ID,
BLOCK_ID,
BLOCKS,
ROUND(BYTES / 1024 / 1024, 2) AS FREE_MB
FROM DBA_FREE_SPACE
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;

-- ============================================================
-- 21. FREE SPACE FRAGMENTATION
-- ============================================================

SELECT
TABLESPACE_NAME,
COUNT(*) AS FREE_EXTENTS,
ROUND(SUM(BYTES) / 1024 / 1024, 2) AS TOTAL_FREE_MB,
ROUND(MAX(BYTES) / 1024 / 1024, 2) AS LARGEST_FREE_EXTENT_MB
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
ORDER BY TOTAL_FREE_MB DESC;

-- ============================================================
-- 22. LARGEST SEGMENTS BY TABLESPACE
-- ============================================================

SELECT
TABLESPACE_NAME,
OWNER,
SEGMENT_NAME,
SEGMENT_TYPE,
ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
ORDER BY BYTES DESC
FETCH FIRST 30 ROWS ONLY;

-- ============================================================
-- 23. TOP 10 SEGMENTS IN A SPECIFIC TABLESPACE
-- ============================================================

SELECT
OWNER,
SEGMENT_NAME,
SEGMENT_TYPE,
ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'USERS'
ORDER BY BYTES DESC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================
-- 24. TABLESPACE SEGMENT SUMMARY
-- ============================================================

SELECT
TABLESPACE_NAME,
SEGMENT_TYPE,
COUNT(*) AS SEGMENT_COUNT,
ROUND(SUM(BYTES) / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
GROUP BY
TABLESPACE_NAME,
SEGMENT_TYPE
ORDER BY
TABLESPACE_NAME,
SIZE_MB DESC;

-- ============================================================
-- 25. USERS AND THEIR DEFAULT TABLESPACES
-- ============================================================

SELECT
USERNAME,
DEFAULT_TABLESPACE,
TEMPORARY_TABLESPACE,
ACCOUNT_STATUS
FROM DBA_USERS
ORDER BY USERNAME;

-- ============================================================
-- 26. USERS USING A PARTICULAR TABLESPACE
-- ============================================================

SELECT
OWNER,
COUNT(*) AS SEGMENT_COUNT,
ROUND(SUM(BYTES) / 1024 / 1024, 2) AS USED_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'USERS'
GROUP BY OWNER
ORDER BY USED_MB DESC;

-- ============================================================
-- 27. TABLESPACE QUOTA MONITORING
-- ============================================================

SELECT
USERNAME,
TABLESPACE_NAME,
BYTES,
MAX_BYTES,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
CASE
WHEN MAX_BYTES = -1
THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(MAX_BYTES / 1024 / 1024, 2)
)
END AS MAX_QUOTA_MB
FROM DBA_TS_QUOTAS
ORDER BY TABLESPACE_NAME, USERNAME;

-- ============================================================
-- 28. USERS WITH LIMITED QUOTA
-- ============================================================

SELECT
USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
ROUND(MAX_BYTES / 1024 / 1024, 2) AS MAX_QUOTA_MB,
ROUND(
(BYTES / NULLIF(MAX_BYTES, 0)) * 100,
2
) AS QUOTA_USED_PERCENT
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES > 0
ORDER BY QUOTA_USED_PERCENT DESC;

-- ============================================================
-- 29. TABLESPACE STATUS
-- ============================================================

SELECT
TABLESPACE_NAME,
STATUS,
CONTENTS
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 30. READ ONLY TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
STATUS,
CONTENTS
FROM DBA_TABLESPACES
WHERE STATUS = 'READ ONLY';

-- ============================================================
-- 31. OFFLINE TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
STATUS,
CONTENTS
FROM DBA_TABLESPACES
WHERE STATUS <> 'ONLINE';

-- ============================================================
-- 32. DEFAULT TABLESPACES
-- ============================================================

SELECT
PROPERTY_NAME,
PROPERTY_VALUE
FROM DATABASE_PROPERTIES
WHERE PROPERTY_NAME IN
(
'DEFAULT_PERMANENT_TABLESPACE',
'DEFAULT_TEMP_TABLESPACE'
);

-- ============================================================
-- 33. TABLESPACE BLOCK SIZE
-- ============================================================

SELECT
TABLESPACE_NAME,
BLOCK_SIZE,
STATUS,
CONTENTS
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 34. EXTENT MANAGEMENT
-- ============================================================

SELECT
TABLESPACE_NAME,
EXTENT_MANAGEMENT,
ALLOCATION_TYPE,
PLUGGED_IN,
SEGMENT_SPACE_MANAGEMENT
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 35. ASSM TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
SEGMENT_SPACE_MANAGEMENT
FROM DBA_TABLESPACES
WHERE SEGMENT_SPACE_MANAGEMENT = 'AUTO';

-- ============================================================
-- 36. LOCALLY MANAGED TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
EXTENT_MANAGEMENT,
ALLOCATION_TYPE
FROM DBA_TABLESPACES
WHERE EXTENT_MANAGEMENT = 'LOCAL'
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 37. BIGFILE TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
BIGFILE,
CONTENTS
FROM DBA_TABLESPACES
WHERE BIGFILE = 'YES';

-- ============================================================
-- 38. LOGGING / NOLOGGING TABLESPACES
-- ============================================================

SELECT
TABLESPACE_NAME,
LOGGING
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 39. DATAFILES NEAR MAXSIZE
-- ============================================================

SELECT
TABLESPACE_NAME,
FILE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB,
ROUND(
(BYTES / NULLIF(MAXBYTES, 0)) * 100,
2
) AS MAXSIZE_USED_PERCENT
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'YES'
AND MAXBYTES > 0
ORDER BY MAXSIZE_USED_PERCENT DESC;

-- ============================================================
-- 40. AUTOEXTEND DATAFILES WITH LOW REMAINING SPACE
-- ============================================================

SELECT
TABLESPACE_NAME,
FILE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB,
ROUND(
(MAXBYTES - BYTES) / 1024 / 1024,
2
) AS REMAINING_AUTOEXTEND_MB
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'YES'
ORDER BY REMAINING_AUTOEXTEND_MB;

-- ============================================================
-- 41. DATAFILES WITH AUTOEXTEND DISABLED
-- ============================================================

SELECT
TABLESPACE_NAME,
FILE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
AUTOEXTENSIBLE
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'NO'
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 42. TEMP TABLESPACE USAGE
-- ============================================================

SELECT
TABLESPACE_NAME,
ROUND(SUM(BYTES_USED) / 1024 / 1024, 2) AS USED_MB,
ROUND(SUM(BYTES_FREE) / 1024 / 1024, 2) AS FREE_MB,
ROUND(
SUM(BYTES_USED)
/ NULLIF(SUM(BYTES_USED + BYTES_FREE), 0)
* 100,
2
) AS USED_PERCENT
FROM V$TEMP_SPACE_HEADER
GROUP BY TABLESPACE_NAME
ORDER BY USED_PERCENT DESC;

-- ============================================================
-- 43. TEMPFILE DETAILS
-- ============================================================

SELECT
TABLESPACE_NAME,
FILE_ID,
FILE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
AUTOEXTENSIBLE
FROM DBA_TEMP_FILES
ORDER BY TABLESPACE_NAME;

-- ============================================================
-- 44. TEMP USAGE BY SESSION
-- ============================================================

SELECT
S.SID,
S.SERIAL#,
S.USERNAME,
S.STATUS,
ROUND(T.TABLESPACE_BLOCKS * TS.BLOCK_SIZE / 1024 / 1024, 2)
AS TEMP_USED_MB
FROM V$SESSION S
JOIN V$SORT_USAGE T
ON S.SADDR = T.SESSION_ADDR
JOIN DBA_TABLESPACES TS
ON T.TABLESPACE = TS.TABLESPACE_NAME
ORDER BY TEMP_USED_MB DESC;

-- ============================================================
-- 45. CURRENTLY USED TEMP BY SQL
-- ============================================================

SELECT
S.SID,
S.SERIAL#,
S.USERNAME,
S.SQL_ID,
ROUND(
U.BLOCKS * TS.BLOCK_SIZE / 1024 / 1024,
2
) AS TEMP_USED_MB
FROM V$SESSION S
JOIN V$SORT_USAGE U
ON S.SADDR = U.SESSION_ADDR
JOIN DBA_TABLESPACES TS
ON U.TABLESPACE = TS.TABLESPACE_NAME
ORDER BY TEMP_USED_MB DESC;

-- ============================================================
-- 46. UNDO TABLESPACE CONFIGURATION
-- ============================================================

SELECT
TABLESPACE_NAME,
STATUS,
CONTENTS
FROM DBA_TABLESPACES
WHERE CONTENTS = 'UNDO';

SELECT
NAME,
VALUE
FROM V$PARAMETER
WHERE NAME = 'undo_tablespace';

-- ============================================================
-- 47. UNDO USAGE
-- ============================================================

SELECT
TABLESPACE_NAME,
STATUS,
ROUND(
SUM(BYTES_USED) / 1024 / 1024,
2
) AS USED_MB,
ROUND(
SUM(BYTES_FREE) / 1024 / 1024,
2
) AS FREE_MB
FROM V$UNDOSTAT
GROUP BY TABLESPACE_NAME, STATUS;

-- ============================================================
-- 48. DATAFILE HEADER INFORMATION
-- ============================================================

SELECT
FILE#,
STATUS,
CHECKPOINT_CHANGE#,
CHECKPOINT_TIME
FROM V$DATAFILE_HEADER
ORDER BY FILE#;

-- ============================================================
-- 49. DATAFILE STATUS
-- ============================================================

SELECT
FILE#,
NAME,
STATUS,
ENABLED
FROM V$DATAFILE
ORDER BY FILE#;

-- ============================================================
-- 50. FINAL DBA TABLESPACE HEALTH CHECK
-- ============================================================

SELECT
DF.TABLESPACE_NAME,

```
ROUND(
    SUM(DF.BYTES) / 1024 / 1024,
    2
) AS TOTAL_MB,

ROUND(
    (
        SUM(DF.BYTES)
        - NVL(FS.FREE_BYTES, 0)
    ) / 1024 / 1024,
    2
) AS USED_MB,

ROUND(
    NVL(FS.FREE_BYTES, 0) / 1024 / 1024,
    2
) AS FREE_MB,

ROUND(
    (
        (
            SUM(DF.BYTES)
            - NVL(FS.FREE_BYTES, 0)
        )
        / SUM(DF.BYTES)
    ) * 100,
    2
) AS USED_PERCENT,

CASE
    WHEN
        (
            (
                SUM(DF.BYTES)
                - NVL(FS.FREE_BYTES, 0)
            )
            / SUM(DF.BYTES)
        ) * 100 >= 95
    THEN 'CRITICAL'

    WHEN
        (
            (
                SUM(DF.BYTES)
                - NVL(FS.FREE_BYTES, 0)
            )
            / SUM(DF.BYTES)
        ) * 100 >= 90
    THEN 'WARNING'

    WHEN
        (
            (
                SUM(DF.BYTES)
                - NVL(FS.FREE_BYTES, 0)
            )
            / SUM(DF.BYTES)
        ) * 100 >= 80
    THEN 'WATCH'

    ELSE 'NORMAL'
END AS HEALTH_STATUS
```

FROM DBA_DATA_FILES DF

LEFT JOIN
(
SELECT
TABLESPACE_NAME,
SUM(BYTES) AS FREE_BYTES
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
) FS
ON DF.TABLESPACE_NAME = FS.TABLESPACE_NAME

GROUP BY
DF.TABLESPACE_NAME,
FS.FREE_BYTES

ORDER BY USED_PERCENT DESC;

-- ============================================================
-- 51. REAL-TIME DBA MONITORING WORKFLOW
-- ============================================================

/*
OEM / Monitoring Alert
|
v
Tablespace > 80%
|
v
Check DBA_TABLESPACES
|
v
Check DBA_DATA_FILES
|
v
Check DBA_FREE_SPACE
|
v
Check AUTOEXTEND
|
+--------------------+
|                    |
v                    v
Autoextend YES          Autoextend NO
|                    |
v                    v
Check MAXSIZE          Add/resize datafile
|                    |
v                    v
Check filesystem/ASM   Verify available space
|
v
Check largest segments
|
v
Identify space-consuming object
|
v
Take corrective action
|
v
Recheck tablespace usage
|
v
Close monitoring alert
*/

-- ============================================================
-- 52. COMMON DBA ACTIONS
-- ============================================================

/*

IF TABLESPACE IS 80%:
Monitor closely.

IF TABLESPACE IS 90%:
Investigate and plan capacity addition.

IF TABLESPACE IS 95%:
Take immediate action.

Possible actions:

1. Add datafile

ALTER TABLESPACE app_data
ADD DATAFILE '/u01/oradata/ORCL/app_data02.dbf'
SIZE 1G;

2. Resize existing datafile

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
RESIZE 2G;

3. Enable autoextend

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;

4. Investigate large segments

SELECT
OWNER,
SEGMENT_NAME,
SEGMENT_TYPE,
BYTES
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'APP_DATA'
ORDER BY BYTES DESC;

5. Check filesystem

Linux:

df -h

6. If ASM is used:

SELECT
NAME,
TOTAL_MB,
FREE_MB,
USABLE_FILE_MB
FROM V$ASM_DISKGROUP;

*/

-- ============================================================
-- 53. IMPORTANT ORA ERRORS
-- ============================================================

/*

ORA-01653
Unable to extend table

Cause:
Tablespace does not have enough free space.

Check:
DBA_FREE_SPACE
DBA_DATA_FILES

Action:
Add/resize datafile or enable autoextend.

ORA-01654
Unable to extend index

Cause:
Insufficient tablespace space for index extent.

Action:
Add/resize datafile and check index tablespace.

ORA-01652
Unable to extend temp segment

Cause:
TEMP tablespace does not have sufficient space.

Action:
Check V$TEMP_SPACE_HEADER and DBA_TEMP_FILES.

ORA-30036
Unable to extend segment by ... in undo tablespace

Cause:
UNDO tablespace is insufficient.

Action:
Add/resize undo datafile and investigate long-running transactions.

ORA-01536
Space quota exceeded for tablespace

Cause:
User quota is insufficient.

Action:
Check DBA_TS_QUOTAS.

ORA-03297
File contains used data beyond requested RESIZE value

Cause:
Datafile cannot be reduced because allocated extents exist
beyond the requested size.

Action:
Identify objects/extents before resizing.
*/

-- ============================================================
-- 54. DAILY TABLESPACE DBA CHECKLIST
-- ============================================================

/*

[ ] Check tablespace usage
[ ] Check >80% tablespaces
[ ] Check >90% tablespaces
[ ] Check >95% critical tablespaces
[ ] Check datafile autoextend
[ ] Check datafile MAXSIZE
[ ] Check filesystem space
[ ] Check ASM free space
[ ] Check TEMP usage
[ ] Check UNDO usage
[ ] Check largest segments
[ ] Check free extent fragmentation
[ ] Check tablespace status
[ ] Check quota usage
[ ] Review OEM alerts
[ ] Take corrective action
[ ] Recheck after action
[ ] Update incident/change ticket

*/

-- ============================================================
-- END OF FILE
-- ============================================================
