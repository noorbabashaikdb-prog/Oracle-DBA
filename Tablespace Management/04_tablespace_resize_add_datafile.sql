```sql
-- ============================================================
-- Oracle DBA Notes
-- Module   : Tablespace Management
-- File     : 04_tablespace_resize_add_datafile.sql
-- Purpose  : Resize / Add Datafile / Autoextend / MAXSIZE
-- Versions : Oracle 12c / 19c
-- ============================================================


-- ============================================================
-- 1. CHECK CURRENT DATAFILES
-- ============================================================

SELECT
    FILE_ID,
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_SIZE_MB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;


-- ============================================================
-- 2. CHECK CURRENT TABLESPACE USAGE
-- ============================================================

SELECT
    DF.TABLESPACE_NAME,
    ROUND(SUM(DF.BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
    ROUND(
        (
            SUM(DF.BYTES) - NVL(FS.FREE_BYTES, 0)
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
                SUM(DF.BYTES) - NVL(FS.FREE_BYTES, 0)
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
ORDER BY USED_PERCENT DESC;


-- ============================================================
-- 3. ADD A NEW DATAFILE
-- ============================================================

-- Example:

ALTER TABLESPACE APP_DATA
ADD DATAFILE '/u01/oradata/ORCL/app_data02.dbf'
SIZE 1G;


-- ============================================================
-- 4. ADD MULTIPLE DATAFILES
-- ============================================================

ALTER TABLESPACE APP_DATA
ADD
    DATAFILE '/u01/oradata/ORCL/app_data03.dbf' SIZE 1G
    DATAFILE '/u01/oradata/ORCL/app_data04.dbf' SIZE 1G;


-- ============================================================
-- 5. ADD DATAFILE WITH AUTOEXTEND
-- ============================================================

ALTER TABLESPACE APP_DATA
ADD DATAFILE '/u01/oradata/ORCL/app_data05.dbf'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;


-- ============================================================
-- 6. ADD DATAFILE WITH UNLIMITED AUTOEXTEND
-- ============================================================

-- Use carefully in production.
-- The underlying filesystem/ASM storage can become full.

ALTER TABLESPACE APP_DATA
ADD DATAFILE '/u01/oradata/ORCL/app_data06.dbf'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE UNLIMITED;


-- ============================================================
-- 7. RESIZE AN EXISTING DATAFILE
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
RESIZE 2G;


-- ============================================================
-- 8. RESIZE DATAFILE USING MB
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
RESIZE 2500M;


-- ============================================================
-- 9. ENABLE AUTOEXTEND
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;


-- ============================================================
-- 10. ENABLE AUTOEXTEND WITH UNLIMITED MAXSIZE
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
AUTOEXTEND ON
NEXT 100M
MAXSIZE UNLIMITED;


-- ============================================================
-- 11. DISABLE AUTOEXTEND
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
AUTOEXTEND OFF;


-- ============================================================
-- 12. CHANGE AUTOEXTEND NEXT SIZE
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
AUTOEXTEND ON
NEXT 200M
MAXSIZE 20G;


-- ============================================================
-- 13. CHANGE ONLY MAXSIZE
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
AUTOEXTEND ON
MAXSIZE 20G;


-- ============================================================
-- 14. CHECK AUTOEXTEND CONFIGURATION
-- ============================================================

SELECT
    FILE_ID,
    TABLESPACE_NAME,
    FILE_NAME,
    AUTOEXTENSIBLE,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB,
    INCREMENT_BY
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;


-- ============================================================
-- 15. DISPLAY AUTOEXTEND IN MB
-- ============================================================

SELECT
    FILE_ID,
    TABLESPACE_NAME,
    FILE_NAME,
    AUTOEXTENSIBLE,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB,
    ROUND(
        INCREMENT_BY * BLOCK_SIZE / 1024 / 1024,
        2
    ) AS NEXT_INCREMENT_MB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;


-- ============================================================
-- 16. FIND DATAFILES CLOSE TO MAXSIZE
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
-- 17. FIND DATAFILES WITH NO AUTOEXTEND
-- ============================================================

SELECT
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'NO'
ORDER BY TABLESPACE_NAME;


-- ============================================================
-- 18. CHECK FREE SPACE BEFORE RESIZE
-- ============================================================

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS FREE_MB
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
ORDER BY FREE_MB DESC;


-- ============================================================
-- 19. IMPORTANT: RESIZE DATAFILE DOWN
-- ============================================================

-- NEVER blindly reduce a datafile.
--
-- Example:
--
-- ALTER DATABASE DATAFILE
-- '/u01/oradata/ORCL/app_data01.dbf'
-- RESIZE 500M;
--
-- This can fail with:
--
-- ORA-03297:
-- file contains used data beyond requested RESIZE value
--
-- Always investigate used blocks/extents first.


-- ============================================================
-- 20. CHECK HIGH BLOCKS IN A DATAFILE
-- ============================================================

SELECT
    FILE_ID,
    MAX(BLOCK_ID + BLOCKS - 1) AS HIGHEST_USED_BLOCK
FROM DBA_EXTENTS
WHERE FILE_ID = 5
GROUP BY FILE_ID;


-- ============================================================
-- 21. CHECK DATAFILE HIGH WATER MARK
-- ============================================================

SELECT
    FILE_ID,
    FILE_NAME,
    BLOCKS,
    ROUND(BLOCKS * BLOCK_SIZE / 1024 / 1024, 2) AS FILE_SIZE_MB
FROM DBA_DATA_FILES
ORDER BY FILE_ID;


-- ============================================================
-- 22. FIND OBJECTS NEAR END OF DATAFILE
-- ============================================================

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    FILE_ID,
    BLOCK_ID,
    BLOCKS,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_EXTENTS
WHERE FILE_ID = 5
ORDER BY BLOCK_ID DESC
FETCH FIRST 20 ROWS ONLY;


-- ============================================================
-- 23. TOP SEGMENTS IN A TABLESPACE
-- ============================================================

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'APP_DATA'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


-- ============================================================
-- 24. ADD DATAFILE WHEN TABLESPACE IS 90% FULL
-- ============================================================

-- Typical production action:

ALTER TABLESPACE APP_DATA
ADD DATAFILE
'/u01/oradata/ORCL/app_data07.dbf'
SIZE 2G
AUTOEXTEND ON
NEXT 200M
MAXSIZE 20G;


-- Verify:

SELECT
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'APP_DATA';


-- ============================================================
-- 25. ADD DATAFILE IN ASM
-- ============================================================

-- ASM example:

ALTER TABLESPACE APP_DATA
ADD DATAFILE '+DATA'
SIZE 2G
AUTOEXTEND ON
NEXT 200M
MAXSIZE 20G;


-- ============================================================
-- 26. ADD DATAFILE TO SPECIFIC ASM DISKGROUP
-- ============================================================

ALTER TABLESPACE APP_DATA
ADD DATAFILE '+DATA'
SIZE 5G;


-- ============================================================
-- 27. CHECK ASM FREE SPACE BEFORE ADDING DATAFILE
-- ============================================================

SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB,
    OFFLINE_DISKS
FROM V$ASM_DISKGROUP
ORDER BY NAME;


-- ============================================================
-- 28. ASM TABLESPACE DATAFILE DETAILS
-- ============================================================

SELECT
    FILE_ID,
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '+%'
ORDER BY TABLESPACE_NAME;


-- ============================================================
-- 29. OMF DATAFILE
-- ============================================================

-- Requires DB_CREATE_FILE_DEST to be configured.

SHOW PARAMETER db_create_file_dest;


-- Add datafile using OMF:

ALTER TABLESPACE APP_DATA
ADD DATAFILE
SIZE 2G
AUTOEXTEND ON
NEXT 200M
MAXSIZE 20G;


-- ============================================================
-- 30. CHECK DB_CREATE_FILE_DEST
-- ============================================================

SELECT
    NAME,
    VALUE
FROM V$PARAMETER
WHERE NAME = 'db_create_file_dest';


-- ============================================================
-- 31. TEMPFILE RESIZE
-- ============================================================

SELECT
    FILE_ID,
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE
FROM DBA_TEMP_FILES
ORDER BY TABLESPACE_NAME;


-- Resize TEMP:

ALTER DATABASE TEMPFILE
'/u01/oradata/ORCL/temp01.dbf'
RESIZE 4G;


-- ============================================================
-- 32. ENABLE TEMPFILE AUTOEXTEND
-- ============================================================

ALTER DATABASE TEMPFILE
'/u01/oradata/ORCL/temp01.dbf'
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;


-- ============================================================
-- 33. DISABLE TEMPFILE AUTOEXTEND
-- ============================================================

ALTER DATABASE TEMPFILE
'/u01/oradata/ORCL/temp01.dbf'
AUTOEXTEND OFF;


-- ============================================================
-- 34. ADD TEMPFILE
-- ============================================================

ALTER TABLESPACE TEMP
ADD TEMPFILE
'/u01/oradata/ORCL/temp02.dbf'
SIZE 2G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;


-- ============================================================
-- 35. ADD TEMPFILE IN ASM
-- ============================================================

ALTER TABLESPACE TEMP
ADD TEMPFILE '+DATA'
SIZE 2G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;


-- ============================================================
-- 36. TEMP TABLESPACE USAGE
-- ============================================================

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES_USED) / 1024 / 1024, 2) AS USED_MB,
    ROUND(SUM(BYTES_FREE) / 1024 / 1024, 2) AS FREE_MB,
    ROUND(
        SUM(BYTES_USED)
        /
        NULLIF(
            SUM(BYTES_USED + BYTES_FREE),
            0
        ) * 100,
        2
    ) AS USED_PERCENT
FROM V$TEMP_SPACE_HEADER
GROUP BY TABLESPACE_NAME
ORDER BY USED_PERCENT DESC;


-- ============================================================
-- 37. UNDO DATAFILE CHECK
-- ============================================================

SELECT
    DF.FILE_ID,
    DF.TABLESPACE_NAME,
    DF.FILE_NAME,
    ROUND(DF.BYTES / 1024 / 1024, 2) AS SIZE_MB,
    DF.AUTOEXTENSIBLE,
    ROUND(DF.MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES DF
JOIN DBA_TABLESPACES TS
    ON DF.TABLESPACE_NAME = TS.TABLESPACE_NAME
WHERE TS.CONTENTS = 'UNDO';


-- ============================================================
-- 38. ADD SPACE TO UNDO TABLESPACE
-- ============================================================

ALTER TABLESPACE UNDOTBS1
ADD DATAFILE
'/u01/oradata/ORCL/undotbs02.dbf'
SIZE 2G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 20G;


-- ============================================================
-- 39. RESIZE UNDO DATAFILE
-- ============================================================

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/undotbs01.dbf'
RESIZE 4G;


-- ============================================================
-- 40. CHECK ALL DATAFILES AFTER CHANGE
-- ============================================================

SELECT
    FILE_ID,
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;


-- ============================================================
-- 41. VERIFY TABLESPACE TOTAL SIZE
-- ============================================================

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_GB
FROM DBA_DATA_FILES
GROUP BY TABLESPACE_NAME
ORDER BY TABLESPACE_NAME;


-- ============================================================
-- 42. CHECK TOTAL DATAFILE CAPACITY
-- ============================================================

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS CURRENT_MB,
    ROUND(SUM(MAXBYTES) / 1024 / 1024, 2) AS MAX_MB,
    ROUND(
        SUM(MAXBYTES - BYTES) / 1024 / 1024,
        2
    ) AS REMAINING_AUTOEXTEND_MB
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'YES'
GROUP BY TABLESPACE_NAME
ORDER BY TABLESPACE_NAME;


-- ============================================================
-- 43. FILESYSTEM CHECK - LINUX
-- ============================================================

/*
Run from Linux OS:

df -h

Example:

Filesystem      Size  Used Avail Use% Mounted on
/dev/mapper/ol-root
                 20G   18G  2G    90% /

/u01             90G   50G  40G   56%

Before adding/resizing a filesystem datafile,
always verify sufficient OS storage.
*/


-- ============================================================
-- 44. CHECK ORACLE DATAFILE LOCATION
-- ============================================================

SELECT
    FILE_NAME
FROM DBA_DATA_FILES
ORDER BY FILE_NAME;


-- ============================================================
-- 45. DATAFILE LOCATION SUMMARY
-- ============================================================

SELECT
    SUBSTR(FILE_NAME, 1, INSTR(FILE_NAME, '/', 1, 4)) AS LOCATION,
    COUNT(*) AS DATAFILE_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_GB
FROM DBA_DATA_FILES
WHERE FILE_NAME LIKE '/%'
GROUP BY SUBSTR(FILE_NAME, 1, INSTR(FILE_NAME, '/', 1, 4))
ORDER BY LOCATION;


-- ============================================================
-- 46. REAL-TIME SCENARIO
--     TABLESPACE 90% FULL
-- ============================================================

/*

INCIDENT:

Application team reports:

"Unable to insert data into application table."

Step 1:
Check tablespace usage.

Step 2:
Identify affected tablespace.

Step 3:
Check free space.

Step 4:
Check datafile size.

Step 5:
Check AUTOEXTEND.

Step 6:
Check MAXSIZE.

Step 7:
Check filesystem/ASM capacity.

Step 8:
Choose corrective action.

Possible actions:

A) Resize existing datafile

B) Add new datafile

C) Increase MAXSIZE

D) Enable AUTOEXTEND

E) Add ASM storage

F) Investigate abnormal segment growth

*/


-- ============================================================
-- 47. REAL-TIME SCENARIO
--     AUTOEXTEND ALREADY ENABLED
-- ============================================================

/*

Problem:

Tablespace = 95% used
AUTOEXTEND = YES

Do NOT immediately assume everything is fine.

Check:

1. CURRENT datafile size
2. MAXSIZE
3. Remaining autoextend capacity
4. Filesystem free space
5. ASM USABLE_FILE_MB
6. Segment growth

Example:

CURRENT SIZE = 9.5 GB
MAXSIZE      = 10 GB

Only approximately 0.5 GB growth remains.

Therefore:

AUTOEXTEND YES
does NOT mean
UNLIMITED SPACE AVAILABLE.
*/


-- ============================================================
-- 48. REAL-TIME SCENARIO
--     ORA-01653
-- ============================================================

/*

ORA-01653:
unable to extend table ... in tablespace ...

Troubleshooting:

1. Identify tablespace.
2. Check DBA_FREE_SPACE.
3. Check DBA_DATA_FILES.
4. Check AUTOEXTENSIBLE.
5. Check MAXBYTES.
6. Check filesystem/ASM.
7. Add or resize datafile.
8. Re-run failed operation.
9. Verify tablespace usage.

Example:

ALTER TABLESPACE APP_DATA
ADD DATAFILE
'/u01/oradata/ORCL/app_data08.dbf'
SIZE 2G
AUTOEXTEND ON
NEXT 200M
MAXSIZE 20G;


-- ============================================================
-- 49. REAL-TIME SCENARIO
--     ORA-01654
-- ============================================================

/*

ORA-01654:
unable to extend index ...

Typical reason:

INDEX tablespace does not have enough space.

Check:

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'APP_INDEX'
ORDER BY BYTES DESC;

Action:

ALTER TABLESPACE APP_INDEX
ADD DATAFILE
'/u01/oradata/ORCL/app_index02.dbf'
SIZE 2G
AUTOEXTEND ON
NEXT 200M
MAXSIZE 20G;

*/


-- ============================================================
-- 50. REAL-TIME SCENARIO
--     ORA-03297 DURING RESIZE
-- ============================================================

/*

Command:

ALTER DATABASE DATAFILE
'/u01/oradata/ORCL/app_data01.dbf'
RESIZE 1G;

Error:

ORA-03297:
file contains used data beyond requested RESIZE value

Meaning:

There are allocated extents beyond the new requested
datafile size.

Do NOT repeatedly retry the same resize.

Find objects:

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    BLOCK_ID,
    BLOCKS,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_EXTENTS
WHERE FILE_ID = 5
ORDER BY BLOCK_ID DESC;


Then determine whether:

- Object can be moved
- Object can be reorganized
- Space can be reclaimed
- Datafile should remain at its current size

*/


-- ============================================================
-- 51. REAL-TIME SCENARIO
--     FILESYSTEM FULL
-- ============================================================

/*

Oracle reports:

ORA-01653

But DBA_FREE_SPACE appears available.

Check:

df -h

Possible situation:

Oracle datafile is configured:

AUTOEXTEND ON
MAXSIZE UNLIMITED

But:

Filesystem = 100% full

Oracle cannot physically grow the datafile.

Action:

1. Stop uncontrolled growth if required.
2. Add filesystem storage.
3. Extend filesystem/LVM as appropriate.
4. Recheck df -h.
5. Verify Oracle datafile.
6. Reattempt application operation.

*/


-- ============================================================
-- 52. REAL-TIME SCENARIO
--     ASM SPACE FULL
-- ============================================================

/*

Check:

SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB
FROM V$ASM_DISKGROUP;

If:

USABLE_FILE_MB is very low

Do NOT simply keep adding datafiles.

First:

1. Check ASM capacity.
2. Check diskgroup usage.
3. Check rebalance.
4. Add ASM disk/storage if required.
5. Verify usable capacity.
6. Add/extend database datafile.
*/


-- ============================================================
-- 53. ADD DATAFILE - PRODUCTION CHANGE TEMPLATE
-- ============================================================

/*

Before change:

1. Confirm tablespace.
2. Confirm current usage.
3. Confirm datafile path.
4. Confirm filesystem free space.
5. Confirm ASM free space if applicable.
6. Confirm requested size.
7. Confirm MAXSIZE.
8. Confirm change approval.

Change:

ALTER TABLESPACE APP_DATA
ADD DATAFILE
'/u01/oradata/ORCL/app_data09.dbf'
SIZE 5G
AUTOEXTEND ON
NEXT 500M
MAXSIZE 50G;

After change:

SELECT
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024 / 1024, 2) AS MAX_GB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'APP_DATA';

*/


-- ============================================================
-- 54. FINAL TABLESPACE HEALTH CHECK
-- ============================================================

SELECT
    DF.TABLESPACE_NAME,

    ROUND(
        SUM(DF.BYTES) / 1024 / 1024 / 1024,
        2
    ) AS TOTAL_GB,

    ROUND(
        (
            SUM(DF.BYTES)
            - NVL(FS.FREE_BYTES, 0)
        ) / 1024 / 1024 / 1024,
        2
    ) AS USED_GB,

    ROUND(
        NVL(FS.FREE_BYTES, 0)
        / 1024 / 1024 / 1024,
        2
    ) AS FREE_GB,

    ROUND(
        (
            (
                SUM(DF.BYTES)
                - NVL(FS.FREE_BYTES, 0)
            )
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
-- 55. FINAL VERIFICATION
-- ============================================================

SELECT
    TABLESPACE_NAME,
    FILE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES / 1024 / 1024, 2) AS MAX_MB
FROM DBA_DATA_FILES
ORDER BY TABLESPACE_NAME, FILE_ID;


-- ============================================================
-- DBA GOLDEN RULES
-- ============================================================

/*

1. Never resize a datafile blindly.

2. Before adding a datafile, check filesystem/ASM capacity.

3. AUTOEXTEND ON does not mean unlimited physical storage.

4. Always define a sensible MAXSIZE in production.

5. Check datafile current size and MAXSIZE separately.

6. For ASM databases, monitor USABLE_FILE_MB.

7. For filesystem databases, monitor df -h.

8. Investigate abnormal segment growth.

9. After every storage change, verify DBA_DATA_FILES.

10. Always recheck tablespace usage after the change.

11. Do not resize below the highest allocated extent.

12. For ORA-03297, investigate extents before reducing size.

13. TEMP uses tempfiles, not normal datafiles.

14. UNDO uses datafiles.

15. Adding space is usually safer than emergency object reorganization
    when the immediate issue is production space exhaustion.

16. Follow your organization's change-management process before
    production storage changes.

-- ============================================================
-- END OF FILE
-- ============================================================
```
