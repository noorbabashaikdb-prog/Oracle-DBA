```sql
/*
===============================================================================
FILE NAME : 08_large_segments.sql
MODULE    : Tablespace Management
TOPIC     : Large Segment Management & Space Analysis
VERSION   : Oracle 12c / 19c

PURPOSE
-------
This script helps Oracle DBAs identify, analyze and troubleshoot:

1. Large tables
2. Large indexes
3. Large LOB segments
4. Segment growth
5. Extent allocation
6. High Water Mark (HWM)
7. Segment fragmentation
8. Space reclamation
9. SHRINK / MOVE / REBUILD
10. Tablespace growth caused by large objects
11. Top space-consuming schemas
12. Real-time production scenarios

IMPORTANT
---------
- Always verify the object before moving/shrinking/rebuilding it.
- Check application impact and locking requirements.
- Take change approval before production maintenance.
- Space used by a segment is different from logical row/data volume.
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
3. LIST ALL SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
ORDER BY BYTES DESC;


/*******************************************************************************
4. TOP 20 LARGEST SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


/*******************************************************************************
5. TOP 50 LARGEST SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
ORDER BY BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
6. LARGEST TABLE SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME AS TABLE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE = 'TABLE'
ORDER BY BYTES DESC
FETCH FIRST 30 ROWS ONLY;


/*******************************************************************************
7. LARGEST INDEX SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME AS INDEX_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE LIKE 'INDEX%'
ORDER BY BYTES DESC
FETCH FIRST 30 ROWS ONLY;


/*******************************************************************************
8. LARGEST LOB SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE LIKE 'LOB%'
ORDER BY BYTES DESC
FETCH FIRST 30 ROWS ONLY;


/*******************************************************************************
9. SPACE BY SEGMENT TYPE
*******************************************************************************/

SELECT
    SEGMENT_TYPE,
    COUNT(*) AS SEGMENT_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
    ROUND(MAX(BYTES) / 1024 / 1024, 2) AS LARGEST_MB
FROM DBA_SEGMENTS
GROUP BY SEGMENT_TYPE
ORDER BY TOTAL_MB DESC;


/*******************************************************************************
10. SPACE BY OWNER
*******************************************************************************/

SELECT
    OWNER,
    COUNT(*) AS SEGMENT_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
    ROUND(MAX(BYTES) / 1024 / 1024, 2) AS LARGEST_SEGMENT_MB
FROM DBA_SEGMENTS
GROUP BY OWNER
ORDER BY TOTAL_MB DESC;


/*******************************************************************************
11. SPACE BY TABLESPACE
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    COUNT(*) AS SEGMENT_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
    ROUND(MAX(BYTES) / 1024 / 1024, 2) AS LARGEST_SEGMENT_MB
FROM DBA_SEGMENTS
GROUP BY TABLESPACE_NAME
ORDER BY TOTAL_MB DESC;


/*******************************************************************************
12. FIND SEGMENTS ABOVE 1 GB
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE BYTES >= 1024 * 1024 * 1024
ORDER BY BYTES DESC;


/*******************************************************************************
13. FIND SEGMENTS ABOVE 10 GB
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE BYTES >= 10 * 1024 * 1024 * 1024
ORDER BY BYTES DESC;


/*******************************************************************************
14. FIND SEGMENTS ABOVE 50 GB
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE BYTES >= 50 * 1024 * 1024 * 1024
ORDER BY BYTES DESC;


/*******************************************************************************
15. TABLES WITH HIGH NUM_ROWS
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    NUM_ROWS,
    BLOCKS,
    EMPTY_BLOCKS,
    AVG_ROW_LEN,
    LAST_ANALYZED
FROM DBA_TABLES
WHERE NUM_ROWS IS NOT NULL
ORDER BY NUM_ROWS DESC
FETCH FIRST 30 ROWS ONLY;


/*
NOTE:
DBA_TABLES statistics are statistics gathered by DBMS_STATS.
They should not be treated as real-time row counts.
*/


/*******************************************************************************
16. LARGE TABLES WITH SEGMENT SIZE
*******************************************************************************/

SELECT
    t.OWNER,
    t.TABLE_NAME,
    t.NUM_ROWS,
    t.BLOCKS,
    ROUND(s.BYTES / 1024 / 1024, 2) AS SEGMENT_MB,
    t.LAST_ANALYZED
FROM DBA_TABLES t
JOIN DBA_SEGMENTS s
ON t.OWNER = s.OWNER
AND t.TABLE_NAME = s.SEGMENT_NAME
WHERE s.SEGMENT_TYPE = 'TABLE'
ORDER BY s.BYTES DESC
FETCH FIRST 30 ROWS ONLY;


/*******************************************************************************
17. TABLE SIZE VS INDEX SIZE
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE OWNER = UPPER('&OWNER')
ORDER BY BYTES DESC;


/*******************************************************************************
18. INDEX INFORMATION
*******************************************************************************/

SELECT
    OWNER,
    INDEX_NAME,
    TABLE_NAME,
    TABLESPACE_NAME,
    STATUS,
    NUM_ROWS,
    LEAF_BLOCKS,
    DISTINCT_KEYS,
    LAST_ANALYZED
FROM DBA_INDEXES
WHERE OWNER = UPPER('&OWNER')
ORDER BY LEAF_BLOCKS DESC;


/*******************************************************************************
19. LARGEST INDEXES
*******************************************************************************/

SELECT
    i.OWNER,
    i.INDEX_NAME,
    i.TABLE_NAME,
    i.TABLESPACE_NAME,
    i.STATUS,
    ROUND(s.BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_INDEXES i
JOIN DBA_SEGMENTS s
ON i.OWNER = s.OWNER
AND i.INDEX_NAME = s.SEGMENT_NAME
WHERE s.SEGMENT_TYPE = 'INDEX'
ORDER BY s.BYTES DESC
FETCH FIRST 30 ROWS ONLY;


/*******************************************************************************
20. LARGEST INDEXES BY TABLE
*******************************************************************************/

SELECT
    i.OWNER,
    i.TABLE_NAME,
    i.INDEX_NAME,
    ROUND(s.BYTES / 1024 / 1024, 2) AS INDEX_MB
FROM DBA_INDEXES i
JOIN DBA_SEGMENTS s
ON i.OWNER = s.OWNER
AND i.INDEX_NAME = s.SEGMENT_NAME
WHERE i.OWNER = UPPER('&OWNER')
ORDER BY s.BYTES DESC;


/*******************************************************************************
21. TABLE + INDEX TOTAL SPACE
*******************************************************************************/

SELECT
    t.OWNER,
    t.TABLE_NAME,
    ROUND(
        SUM(s.BYTES) / 1024 / 1024,
        2
    ) AS TOTAL_OBJECT_MB
FROM DBA_TABLES t
JOIN DBA_SEGMENTS s
ON t.OWNER = s.OWNER
AND (
       s.SEGMENT_NAME = t.TABLE_NAME
       OR s.SEGMENT_NAME IN
          (
              SELECT INDEX_NAME
              FROM DBA_INDEXES i
              WHERE i.TABLE_OWNER = t.OWNER
              AND i.TABLE_NAME = t.TABLE_NAME
          )
)
WHERE t.OWNER = UPPER('&OWNER')
GROUP BY
    t.OWNER,
    t.TABLE_NAME
ORDER BY TOTAL_OBJECT_MB DESC;


/*******************************************************************************
22. EXTENT INFORMATION
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    COUNT(*) AS EXTENT_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS TOTAL_MB,
    ROUND(MAX(BYTES) / 1024 / 1024, 2) AS LARGEST_EXTENT_MB
FROM DBA_EXTENTS
GROUP BY
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME
ORDER BY TOTAL_MB DESC;


/*******************************************************************************
23. SEGMENTS WITH MANY EXTENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    COUNT(*) AS EXTENT_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_EXTENTS
GROUP BY
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME
HAVING COUNT(*) > 100
ORDER BY EXTENT_COUNT DESC;


/*******************************************************************************
24. SEGMENTS WITH MORE THAN 1000 EXTENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    COUNT(*) AS EXTENT_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_EXTENTS
GROUP BY
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME
HAVING COUNT(*) > 1000
ORDER BY EXTENT_COUNT DESC;


/*
IMPORTANT:
A high extent count alone does NOT automatically mean a performance problem.

Locally managed tablespaces with AUTOALLOCATE can have many extents without
causing the old dictionary-managed fragmentation problems.
*/


/*******************************************************************************
25. EXTENT DETAILS FOR ONE SEGMENT
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    EXTENT_ID,
    FILE_ID,
    BLOCK_ID,
    BLOCKS,
    ROUND(BYTES / 1024 / 1024, 2) AS EXTENT_MB
FROM DBA_EXTENTS
WHERE OWNER = UPPER('&OWNER')
AND SEGMENT_NAME = UPPER('&SEGMENT_NAME')
ORDER BY EXTENT_ID;


/*******************************************************************************
26. FIRST EXTENT
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    EXTENT_ID,
    FILE_ID,
    BLOCK_ID,
    BLOCKS,
    ROUND(BYTES / 1024 / 1024, 2) AS EXTENT_MB
FROM DBA_EXTENTS
WHERE OWNER = UPPER('&OWNER')
AND SEGMENT_NAME = UPPER('&SEGMENT_NAME')
AND EXTENT_ID = 0;


/*******************************************************************************
27. LAST EXTENT
*******************************************************************************/

SELECT *
FROM
(
    SELECT
        OWNER,
        SEGMENT_NAME,
        SEGMENT_TYPE,
        TABLESPACE_NAME,
        EXTENT_ID,
        FILE_ID,
        BLOCK_ID,
        BLOCKS,
        ROUND(BYTES / 1024 / 1024, 2) AS EXTENT_MB
    FROM DBA_EXTENTS
    WHERE OWNER = UPPER('&OWNER')
    AND SEGMENT_NAME = UPPER('&SEGMENT_NAME')
    ORDER BY EXTENT_ID DESC
)
WHERE ROWNUM = 1;


/*******************************************************************************
28. SEGMENT SIZE FROM DBA_SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    BYTES,
    BLOCKS,
    EXTENTS,
    INITIAL_EXTENT,
    NEXT_EXTENT,
    MIN_EXTENTS,
    MAX_EXTENTS
FROM DBA_SEGMENTS
WHERE OWNER = UPPER('&OWNER')
AND SEGMENT_NAME = UPPER('&SEGMENT_NAME');


/*******************************************************************************
29. SEGMENT SPACE MANAGEMENT
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    SEGMENT_SPACE_MANAGEMENT,
    EXTENT_MANAGEMENT,
    BLOCK_SIZE,
    BIGFILE
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
30. ASSM TABLESPACES
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    SEGMENT_SPACE_MANAGEMENT,
    EXTENT_MANAGEMENT
FROM DBA_TABLESPACES
WHERE SEGMENT_SPACE_MANAGEMENT = 'AUTO'
ORDER BY TABLESPACE_NAME;


/*******************************************************************************
31. FIND SEGMENTS IN ASSM TABLESPACES
*******************************************************************************/

SELECT
    s.OWNER,
    s.SEGMENT_NAME,
    s.SEGMENT_TYPE,
    s.TABLESPACE_NAME,
    ROUND(s.BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS s
JOIN DBA_TABLESPACES t
ON s.TABLESPACE_NAME = t.TABLESPACE_NAME
WHERE t.SEGMENT_SPACE_MANAGEMENT = 'AUTO'
ORDER BY s.BYTES DESC;


/*******************************************************************************
32. TABLE STORAGE ATTRIBUTES
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    TABLESPACE_NAME,
    PCT_FREE,
    PCT_USED,
    INITRANS,
    MAX_TRANS,
    LOGGING,
    NUM_ROWS,
    BLOCKS,
    EMPTY_BLOCKS
FROM DBA_TABLES
WHERE OWNER = UPPER('&OWNER')
AND TABLE_NAME = UPPER('&TABLE_NAME');


/*******************************************************************************
33. CHECK ROW MOVEMENT
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    ROW_MOVEMENT
FROM DBA_TABLES
WHERE OWNER = UPPER('&OWNER')
AND TABLE_NAME = UPPER('&TABLE_NAME');


/*******************************************************************************
34. ENABLE ROW MOVEMENT
*******************************************************************************/

/*
Required before many SHRINK operations.

Execute only after application impact analysis.

Example:

ALTER TABLE APP.ORDERS ENABLE ROW MOVEMENT;
*/


/*******************************************************************************
35. TABLE SHRINK - THEORY
*******************************************************************************/

/*
SHRINK SPACE:

    ALTER TABLE APP.ORDERS ENABLE ROW MOVEMENT;

    ALTER TABLE APP.ORDERS SHRINK SPACE;

Benefits:
---------
- Reclaims unused space.
- Can reduce HWM.
- Can compact rows.
- Segment remains in the same tablespace.
- Does not require a new segment location.

Requirements / considerations:
------------------------------
- ASSM tablespace is required.
- Row movement must be enabled.
- Object restrictions must be checked.
- Application impact must be evaluated.

Do not blindly shrink production tables.
*/


/*******************************************************************************
36. SHRINK COMPACT
*******************************************************************************/

/*
COMPACT phase reorganizes rows but does not necessarily lower HWM immediately.

Example:

ALTER TABLE APP.ORDERS SHRINK SPACE COMPACT;

Then:

ALTER TABLE APP.ORDERS SHRINK SPACE;
*/


/*******************************************************************************
37. SHRINK SPACE
*******************************************************************************/

/*
Example:

ALTER TABLE APP.ORDERS SHRINK SPACE;
*/


/*******************************************************************************
38. DISABLE ROW MOVEMENT
*******************************************************************************/

/*
After maintenance, if application requirements require it:

ALTER TABLE APP.ORDERS DISABLE ROW MOVEMENT;

Verify application design before disabling it.
*/


/*******************************************************************************
39. TABLE MOVE
*******************************************************************************/

/*
MOVE can relocate the table segment.

Example:

ALTER TABLE APP.ORDERS MOVE TABLESPACE DATA_NEW;

Important:
---------
- Indexes associated with the table may become UNUSABLE depending on
  operation/version.
- Application impact and locking must be considered.
- Rebuild required indexes if necessary.
*/


/*******************************************************************************
40. ONLINE TABLE MOVE
*******************************************************************************/

/*
Oracle versions/options support online table movement in appropriate
situations.

Example:

ALTER TABLE APP.ORDERS MOVE ONLINE TABLESPACE DATA_NEW;

Always verify object type, Oracle version, licensing and application impact
before using ONLINE operations.
*/


/*******************************************************************************
41. CHECK INDEX STATUS AFTER TABLE MOVE
*******************************************************************************/

SELECT
    OWNER,
    INDEX_NAME,
    TABLE_NAME,
    STATUS
FROM DBA_INDEXES
WHERE TABLE_OWNER = UPPER('&OWNER')
AND TABLE_NAME = UPPER('&TABLE_NAME')
ORDER BY INDEX_NAME;


/*******************************************************************************
42. REBUILD INDEX
*******************************************************************************/

/*
Example:

ALTER INDEX APP.IDX_ORDERS_CUSTOMER REBUILD;

Rebuild into another tablespace:

ALTER INDEX APP.IDX_ORDERS_CUSTOMER
REBUILD TABLESPACE INDEX_DATA;
*/


/*******************************************************************************
43. ONLINE INDEX REBUILD
*******************************************************************************/

/*
Example:

ALTER INDEX APP.IDX_ORDERS_CUSTOMER
REBUILD ONLINE;

Check availability and licensing/version considerations before production use.
*/


/*******************************************************************************
44. INDEX SIZE BEFORE REBUILD
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE = 'INDEX'
AND OWNER = UPPER('&OWNER')
AND SEGMENT_NAME = UPPER('&INDEX_NAME');


/*******************************************************************************
45. INDEX SIZE AFTER REBUILD
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE = 'INDEX'
AND OWNER = UPPER('&OWNER')
AND SEGMENT_NAME = UPPER('&INDEX_NAME');


/*******************************************************************************
46. INDEX REBUILD VS SHRINK
*******************************************************************************/

/*
INDEX REBUILD:
--------------
Creates/reorganizes an index segment and can be useful when there is a
specific reason such as moving an index to another tablespace.

SHRINK:
-------
Can compact a segment and potentially lower the HWM for eligible objects.

Do not rebuild every index simply because its size is large.

A large index can be perfectly normal and required by the application.
*/


/*******************************************************************************
47. UNUSED SPACE INSIDE A TABLE
*******************************************************************************/

/*
A table may have allocated blocks that are not currently occupied by rows.

Use segment and table statistics together:

*/

SELECT
    OWNER,
    TABLE_NAME,
    NUM_ROWS,
    BLOCKS,
    AVG_ROW_LEN,
    LAST_ANALYZED
FROM DBA_TABLES
WHERE OWNER = UPPER('&OWNER')
AND TABLE_NAME = UPPER('&TABLE_NAME');


/*******************************************************************************
48. ANALYZE TABLE STATISTICS
*******************************************************************************/

/*
Preferred approach for optimizer statistics:

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        OWNNAME => 'APP',
        TABNAME => 'ORDERS'
    );
END;
/
*/


/*******************************************************************************
49. ESTIMATE TABLE SIZE
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    NUM_ROWS,
    AVG_ROW_LEN,
    ROUND(
        NUM_ROWS * AVG_ROW_LEN / 1024 / 1024,
        2
    ) AS APPROX_DATA_MB
FROM DBA_TABLES
WHERE OWNER = UPPER('&OWNER')
AND NUM_ROWS IS NOT NULL
ORDER BY APPROX_DATA_MB DESC;


/*
NOTE:
This is an approximate logical row-data calculation.
It is NOT the same as the physical segment size.
*/


/*******************************************************************************
50. COMPARE APPROX DATA SIZE VS SEGMENT SIZE
*******************************************************************************/

SELECT
    t.OWNER,
    t.TABLE_NAME,
    t.NUM_ROWS,
    t.AVG_ROW_LEN,
    ROUND(
        t.NUM_ROWS * t.AVG_ROW_LEN / 1024 / 1024,
        2
    ) AS APPROX_DATA_MB,
    ROUND(
        s.BYTES / 1024 / 1024,
        2
    ) AS SEGMENT_MB
FROM DBA_TABLES t
JOIN DBA_SEGMENTS s
ON t.OWNER = s.OWNER
AND t.TABLE_NAME = s.SEGMENT_NAME
WHERE s.SEGMENT_TYPE = 'TABLE'
AND t.NUM_ROWS IS NOT NULL
ORDER BY s.BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
51. LOB SEGMENT DETAILS
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    COLUMN_NAME,
    SEGMENT_NAME,
    TABLESPACE_NAME,
    INDEX_NAME,
    SECUREFILE
FROM DBA_LOBS
WHERE OWNER = UPPER('&OWNER')
ORDER BY TABLE_NAME;


/*******************************************************************************
52. LARGEST LOB OBJECTS
*******************************************************************************/

SELECT
    l.OWNER,
    l.TABLE_NAME,
    l.COLUMN_NAME,
    l.SEGMENT_NAME,
    l.TABLESPACE_NAME,
    ROUND(s.BYTES / 1024 / 1024, 2) AS LOB_MB
FROM DBA_LOBS l
JOIN DBA_SEGMENTS s
ON l.OWNER = s.OWNER
AND l.SEGMENT_NAME = s.SEGMENT_NAME
ORDER BY s.BYTES DESC
FETCH FIRST 30 ROWS ONLY;


/*******************************************************************************
53. LOB INDEX SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE = 'LOBINDEX'
ORDER BY BYTES DESC;


/*******************************************************************************
54. SECUREFILE LOBS
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    COLUMN_NAME,
    SEGMENT_NAME,
    SECUREFILE,
    COMPRESSION,
    DEDUPLICATION,
    ENCRYPT
FROM DBA_LOBS
WHERE SECUREFILE = 'YES'
ORDER BY OWNER, TABLE_NAME;


/*******************************************************************************
55. BASICFILE LOBS
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    COLUMN_NAME,
    SEGMENT_NAME,
    SECUREFILE
FROM DBA_LOBS
WHERE SECUREFILE = 'NO'
ORDER BY OWNER, TABLE_NAME;


/*******************************************************************************
56. LOB RETENTION
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    COLUMN_NAME,
    RETENTION,
    PCTVERSION
FROM DBA_LOBS
WHERE OWNER = UPPER('&OWNER')
ORDER BY TABLE_NAME;


/*******************************************************************************
57. PARTITIONED TABLE SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    PARTITION_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE IN
(
    'TABLE PARTITION',
    'TABLE SUBPARTITION'
)
ORDER BY BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
58. PARTITIONED INDEX SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    PARTITION_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE IN
(
    'INDEX PARTITION',
    'INDEX SUBPARTITION'
)
ORDER BY BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
59. LARGEST TABLE PARTITIONS
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    PARTITION_NAME,
    TABLESPACE_NAME,
    NUM_ROWS,
    BLOCKS,
    ROUND(
        BLOCKS * 8192 / 1024 / 1024,
        2
    ) AS APPROX_MB
FROM DBA_TAB_PARTITIONS
WHERE BLOCKS IS NOT NULL
ORDER BY BLOCKS DESC
FETCH FIRST 50 ROWS ONLY;


/*
For exact physical segment size, prefer DBA_SEGMENTS.
The above calculation assumes 8K and is therefore only an approximation.
*/


/*******************************************************************************
60. EXACT TABLE PARTITION SEGMENT SIZE
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    PARTITION_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE = 'TABLE PARTITION'
ORDER BY BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
61. FIND TABLES WITH MANY EXTENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    COUNT(*) AS EXTENT_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_EXTENTS
WHERE SEGMENT_TYPE = 'TABLE'
GROUP BY OWNER, SEGMENT_NAME
HAVING COUNT(*) > 500
ORDER BY EXTENT_COUNT DESC;


/*******************************************************************************
62. INITIAL / NEXT EXTENT ATTRIBUTES
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    INITIAL_EXTENT,
    NEXT_EXTENT,
    MIN_EXTENTS,
    MAX_EXTENTS,
    PCT_INCREASE
FROM DBA_SEGMENTS
WHERE OWNER = UPPER('&OWNER')
ORDER BY BYTES DESC;


/*
NOTE:
For modern locally managed tablespaces, extent allocation is generally
managed by Oracle. Do not apply old dictionary-managed fragmentation rules
without understanding the tablespace configuration.
*/


/*******************************************************************************
63. SEGMENT CREATION INFORMATION
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB,
    EXTENTS
FROM DBA_SEGMENTS
WHERE OWNER = UPPER('&OWNER')
ORDER BY BYTES DESC;


/*******************************************************************************
64. FIND EMPTY SEGMENTS
*******************************************************************************/

/*
Segments with no allocated segment are not present in DBA_SEGMENTS.

For tables:

*/

SELECT
    OWNER,
    TABLE_NAME,
    SEGMENT_CREATED
FROM DBA_TABLES
WHERE OWNER = UPPER('&OWNER')
AND SEGMENT_CREATED = 'NO'
ORDER BY TABLE_NAME;


/*******************************************************************************
65. TEMPORARY SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE LIKE '%TEMPORARY%'
ORDER BY OWNER;


/*******************************************************************************
66. RECYCLEBIN SPACE
*******************************************************************************/

SELECT
    OWNER,
    OBJECT_NAME,
    ORIGINAL_NAME,
    TYPE,
    ROUND(SPACE * 8192 / 1024 / 1024, 2) AS APPROX_MB
FROM DBA_RECYCLEBIN
ORDER BY SPACE DESC;


/*
IMPORTANT:
SPACE is reported in blocks. The above example assumes 8K blocks.

For exact calculations, use the relevant block size.
*/


/*******************************************************************************
67. RECYCLEBIN BY OWNER
*******************************************************************************/

SELECT
    OWNER,
    COUNT(*) AS OBJECT_COUNT,
    SUM(SPACE) AS BLOCKS
FROM DBA_RECYCLEBIN
GROUP BY OWNER
ORDER BY BLOCKS DESC;


/*******************************************************************************
68. PURGE RECYCLEBIN
*******************************************************************************/

/*
If approved:

PURGE DBA_RECYCLEBIN;

Or for a user:

PURGE RECYCLEBIN;

Do not purge production objects without confirming retention/recovery
requirements.
*/


/*******************************************************************************
69. TABLESPACE AND LARGE SEGMENT CORRELATION
*******************************************************************************/

SELECT
    s.TABLESPACE_NAME,
    ROUND(SUM(s.BYTES) / 1024 / 1024 / 1024, 2) AS SEGMENT_GB,
    ROUND(
        (
            SELECT SUM(df.BYTES)
            FROM DBA_DATA_FILES df
            WHERE df.TABLESPACE_NAME = s.TABLESPACE_NAME
        ) / 1024 / 1024 / 1024,
        2
    ) AS ALLOCATED_GB
FROM DBA_SEGMENTS s
GROUP BY s.TABLESPACE_NAME
ORDER BY SEGMENT_GB DESC;


/*******************************************************************************
70. TOP OWNERS WITH LARGE SEGMENTS
*******************************************************************************/

SELECT
    OWNER,
    COUNT(*) AS SEGMENT_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_GB
FROM DBA_SEGMENTS
GROUP BY OWNER
HAVING SUM(BYTES) > 10 * 1024 * 1024 * 1024
ORDER BY TOTAL_GB DESC;


/*******************************************************************************
71. FIND TABLES IN A PARTICULAR TABLESPACE
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = UPPER('&TABLESPACE_NAME')
ORDER BY BYTES DESC;


/*******************************************************************************
72. LARGE SEGMENTS ABOVE 90% TABLESPACE USAGE
*******************************************************************************/

SELECT
    s.OWNER,
    s.SEGMENT_NAME,
    s.SEGMENT_TYPE,
    s.TABLESPACE_NAME,
    ROUND(s.BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS s
WHERE s.TABLESPACE_NAME IN
(
    SELECT df.TABLESPACE_NAME
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
    HAVING
        (
            SUM(df.BYTES) - NVL(MAX(fs.FREE_BYTES), 0)
        )
        / SUM(df.BYTES) * 100 >= 90
)
ORDER BY s.BYTES DESC;


/*******************************************************************************
73. IDENTIFY SPACE CONSUMER FOR A GROWING TABLESPACE
*******************************************************************************/

/*
Step 1:
Find top segments.
*/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = UPPER('&TABLESPACE_NAME')
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


/*
Step 2:
Check object statistics.
*/

SELECT
    OWNER,
    TABLE_NAME,
    NUM_ROWS,
    BLOCKS,
    AVG_ROW_LEN,
    LAST_ANALYZED
FROM DBA_TABLES
WHERE OWNER = UPPER('&OWNER')
ORDER BY BLOCKS DESC
FETCH FIRST 20 ROWS ONLY;


/*******************************************************************************
74. SEGMENT GROWTH - CURRENT SNAPSHOT
*******************************************************************************/

/*
The following gives the current size.

For actual historical growth, compare this result with previous snapshots
or use AWR/OEM/your monitoring repository.
*/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS CURRENT_MB
FROM DBA_SEGMENTS
ORDER BY BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
75. AWR SEGMENT STATISTICS - HISTORICAL GROWTH
*******************************************************************************/

/*
If Diagnostics Pack/AWR is licensed and available, historical segment growth
can be investigated through DBA_HIST_SEG_STAT and related views.

Example:

SELECT
    OWNER,
    OBJ#,
    SUM(SPACE_ALLOCATED_DELTA) AS SPACE_ALLOCATED_DELTA
FROM DBA_HIST_SEG_STAT
GROUP BY OWNER, OBJ#
ORDER BY SPACE_ALLOCATED_DELTA DESC;

Verify the columns available in your Oracle version before using this query.
*/


/*******************************************************************************
76. HIGH WATER MARK - CONCEPT
*******************************************************************************/

/*

SEGMENT

+------------------------------------+
| Used blocks                        |
| Used blocks                        |
| Used blocks                        |
| Used blocks                        |
|------------------------------------| <- HWM
| Previously allocated/free blocks   |
|                                    |
|                                    |
+------------------------------------+

HWM = High Water Mark

It represents the boundary up to which Oracle considers blocks in a segment
to have been formatted/used for segment operations.

Deleting rows does not automatically return all allocated blocks below the
HWM to the tablespace.

Segment shrink/move can be used in appropriate situations to reclaim space.
*/


/*******************************************************************************
77. DELETE VS SHRINK
*******************************************************************************/

/*

DELETE
------
DELETE FROM APP.ORDERS;

Rows are removed.

But:
    Segment allocation may remain.
    HWM may remain.

SHRINK
------
ALTER TABLE APP.ORDERS ENABLE ROW MOVEMENT;

ALTER TABLE APP.ORDERS SHRINK SPACE;

Can compact the segment and reduce HWM for eligible segments.

MOVE
----
ALTER TABLE APP.ORDERS MOVE TABLESPACE DATA_NEW;

Moves the segment and can reclaim the old segment space after successful
completion.
*/


/*******************************************************************************
78. DELETE + PURGE + SHRINK FLOW
*******************************************************************************/

/*

Large Table
    |
    v
Delete old data
    |
    v
Commit
    |
    v
Check segment size
    |
    v
Is space needed back at tablespace level?
    |
    +------ NO ------> No shrink required
    |
    +------ YES
             |
             v
       Check eligibility
             |
             v
       Enable ROW MOVEMENT
             |
             v
       SHRINK SPACE
             |
             v
       Verify DBA_SEGMENTS
*/


/*******************************************************************************
79. TABLE SHRINK EXAMPLE
*******************************************************************************/

/*
Pre-check:

SELECT
    OWNER,
    SEGMENT_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE OWNER = 'APP'
AND SEGMENT_NAME = 'ORDERS';

Then:

ALTER TABLE APP.ORDERS ENABLE ROW MOVEMENT;

ALTER TABLE APP.ORDERS SHRINK SPACE;

Post-check:

SELECT
    OWNER,
    SEGMENT_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE OWNER = 'APP'
AND SEGMENT_NAME = 'ORDERS';
*/


/*******************************************************************************
80. SEGMENT MOVE EXAMPLE
*******************************************************************************/

/*
Pre-check:

SELECT
    OWNER,
    SEGMENT_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE OWNER = 'APP'
AND SEGMENT_NAME = 'ORDERS';

Move:

ALTER TABLE APP.ORDERS
MOVE TABLESPACE DATA_NEW;

Post-check:

SELECT
    OWNER,
    SEGMENT_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE OWNER = 'APP'
AND SEGMENT_NAME = 'ORDERS';
*/


/*******************************************************************************
81. CHECK OBJECT DEPENDENCIES BEFORE MOVE
*******************************************************************************/

SELECT
    OWNER,
    NAME,
    TYPE,
    REFERENCED_OWNER,
    REFERENCED_NAME,
    REFERENCED_TYPE
FROM DBA_DEPENDENCIES
WHERE OWNER = UPPER('&OWNER')
AND NAME = UPPER('&OBJECT_NAME')
ORDER BY TYPE;


/*******************************************************************************
82. CHECK INVALID OBJECTS
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
83. CHECK TABLE INDEXES AFTER MOVE
*******************************************************************************/

SELECT
    OWNER,
    INDEX_NAME,
    TABLE_NAME,
    STATUS,
    TABLESPACE_NAME
FROM DBA_INDEXES
WHERE TABLE_OWNER = UPPER('&OWNER')
AND TABLE_NAME = UPPER('&TABLE_NAME')
ORDER BY INDEX_NAME;


/*******************************************************************************
84. REBUILD UNUSABLE INDEX
*******************************************************************************/

/*
Example:

ALTER INDEX APP.IDX_ORDERS_CUSTOMER REBUILD;

Verify:

*/

SELECT
    OWNER,
    INDEX_NAME,
    STATUS
FROM DBA_INDEXES
WHERE OWNER = UPPER('&OWNER')
AND STATUS <> 'VALID';


/*******************************************************************************
85. LARGE TABLE + LOB + INDEX ANALYSIS
*******************************************************************************/

SELECT
    t.OWNER,
    t.TABLE_NAME,
    ROUND(
        NVL(ts.BYTES, 0) / 1024 / 1024,
        2
    ) AS TABLE_MB,
    ROUND(
        NVL(ix.BYTES, 0) / 1024 / 1024,
        2
    ) AS INDEX_MB,
    ROUND(
        NVL(lb.BYTES, 0) / 1024 / 1024,
        2
    ) AS LOB_MB
FROM DBA_TABLES t
LEFT JOIN
(
    SELECT
        OWNER,
        SEGMENT_NAME,
        SUM(BYTES) BYTES
    FROM DBA_SEGMENTS
    WHERE SEGMENT_TYPE = 'TABLE'
    GROUP BY OWNER, SEGMENT_NAME
) ts
ON t.OWNER = ts.OWNER
AND t.TABLE_NAME = ts.SEGMENT_NAME
LEFT JOIN
(
    SELECT
        i.TABLE_OWNER AS OWNER,
        i.TABLE_NAME,
        SUM(s.BYTES) BYTES
    FROM DBA_INDEXES i
    JOIN DBA_SEGMENTS s
    ON i.OWNER = s.OWNER
    AND i.INDEX_NAME = s.SEGMENT_NAME
    GROUP BY
        i.TABLE_OWNER,
        i.TABLE_NAME
) ix
ON t.OWNER = ix.OWNER
AND t.TABLE_NAME = ix.TABLE_NAME
LEFT JOIN
(
    SELECT
        l.OWNER,
        l.TABLE_NAME,
        SUM(s.BYTES) BYTES
    FROM DBA_LOBS l
    JOIN DBA_SEGMENTS s
    ON l.OWNER = s.OWNER
    AND l.SEGMENT_NAME = s.SEGMENT_NAME
    GROUP BY
        l.OWNER,
        l.TABLE_NAME
) lb
ON t.OWNER = lb.OWNER
AND t.TABLE_NAME = lb.TABLE_NAME
WHERE t.OWNER = UPPER('&OWNER')
ORDER BY
    (
        NVL(ts.BYTES,0)
        + NVL(ix.BYTES,0)
        + NVL(lb.BYTES,0)
    ) DESC;


/*******************************************************************************
86. FIND TABLES WITH LARGE LOB DATA
*******************************************************************************/

SELECT
    l.OWNER,
    l.TABLE_NAME,
    l.COLUMN_NAME,
    l.SEGMENT_NAME,
    ROUND(s.BYTES / 1024 / 1024 / 1024, 2) AS LOB_GB
FROM DBA_LOBS l
JOIN DBA_SEGMENTS s
ON l.OWNER = s.OWNER
AND l.SEGMENT_NAME = s.SEGMENT_NAME
ORDER BY s.BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
87. PARTITION SPACE DISTRIBUTION
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    PARTITION_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE PARTITION_NAME IS NOT NULL
ORDER BY BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
88. FIND LARGE SINGLE PARTITION
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    PARTITION_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE PARTITION_NAME IS NOT NULL
AND BYTES >= 10 * 1024 * 1024 * 1024
ORDER BY BYTES DESC;


/*******************************************************************************
89. PARTITIONED TABLE INFORMATION
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    PARTITIONING_TYPE,
    SUBPARTITIONING_TYPE,
    PARTITION_COUNT
FROM DBA_PART_TABLES
WHERE OWNER = UPPER('&OWNER')
ORDER BY TABLE_NAME;


/*******************************************************************************
90. FIND TABLES WITH MANY PARTITIONS
*******************************************************************************/

SELECT
    OWNER,
    TABLE_NAME,
    PARTITIONING_TYPE,
    PARTITION_COUNT
FROM DBA_PART_TABLES
WHERE PARTITION_COUNT > 100
ORDER BY PARTITION_COUNT DESC;


/*******************************************************************************
91. OLD PARTITIONS CANDIDATE FOR HOUSEKEEPING
*******************************************************************************/

/*
Review partition metadata:

*/

SELECT
    TABLE_OWNER,
    TABLE_NAME,
    PARTITION_NAME,
    HIGH_VALUE,
    TABLESPACE_NAME,
    NUM_ROWS
FROM DBA_TAB_PARTITIONS
WHERE TABLE_OWNER = UPPER('&OWNER')
ORDER BY TABLE_NAME, PARTITION_POSITION;


/*
Do not automatically drop partitions.
First confirm:
    - retention policy
    - business requirements
    - backup/recovery requirements
    - legal requirements
    - application dependencies
*/


/*******************************************************************************
92. SPACE RECLAMATION DECISION
*******************************************************************************/

/*

Large Segment
      |
      v
Is the growth expected?
      |
   +--+--+
   |     |
  YES    NO
   |     |
   v     v
Capacity  Investigate
planning   root cause
   |          |
   |          v
   |       Data growth?
   |       LOB growth?
   |       Index growth?
   |       Purge issue?
   |       Partition issue?
   |
   v
Need to reclaim space?
      |
   +--+--+
   |     |
  NO     YES
   |      |
   v      v
Monitor  Check eligibility
            |
            +--> SHRINK
            |
            +--> MOVE
            |
            +--> REBUILD
            |
            +--> PARTITION PURGE
*/


/*******************************************************************************
93. REAL-TIME SCENARIO 1
    TABLESPACE GROWING RAPIDLY
*******************************************************************************/

/*
Issue:
------
DATA tablespace grew from 500 GB to 700 GB.

DBA approach:

1. Identify tablespace.
2. Compare current and historical growth.
3. Find largest segments.
4. Compare with previous segment snapshots.
5. Identify newly growing tables/LOBs/indexes.
6. Check application batch jobs.
7. Check partition creation.
8. Check temporary staging data.
9. Check audit/history tables.
10. Check retention/housekeeping jobs.
11. Resolve root cause.
12. Increase capacity if required.

Query:
*/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'DATA'
ORDER BY BYTES DESC
FETCH FIRST 30 ROWS ONLY;


/*******************************************************************************
94. REAL-TIME SCENARIO 2
    LARGE TABLE AFTER MASS DELETE
*******************************************************************************/

/*
Situation:
---------
A 500 GB table had 400 GB of old records deleted.

But DBA_SEGMENTS still shows approximately 500 GB.

Reason:
-------
DELETE removes rows but does not automatically return all allocated segment
space to the tablespace.

Possible solution:
------------------
If eligible and approved:

ALTER TABLE APP.HISTORY ENABLE ROW MOVEMENT;

ALTER TABLE APP.HISTORY SHRINK SPACE;

Then verify DBA_SEGMENTS.

Alternative:
------------
Move the table if shrink is not appropriate.
*/


/*******************************************************************************
95. REAL-TIME SCENARIO 3
    INDEX LARGER THAN EXPECTED
*******************************************************************************/

/*
Do not immediately rebuild.

Check:

1. Index purpose.
2. Number of rows.
3. Number of distinct keys.
4. Index columns.
5. Partitioning.
6. Growth history.
7. Application workload.
8. Whether the index is actually required.
9. Segment size.
10. Invalid/unusable status.

Queries:
*/

SELECT
    OWNER,
    INDEX_NAME,
    TABLE_NAME,
    STATUS,
    NUM_ROWS,
    DISTINCT_KEYS,
    LEAF_BLOCKS,
    BLEVEL
FROM DBA_INDEXES
WHERE OWNER = UPPER('&OWNER')
AND INDEX_NAME = UPPER('&INDEX_NAME');


/*******************************************************************************
96. REAL-TIME SCENARIO 4
    LARGE LOB GROWTH
*******************************************************************************/

/*
Situation:
---------
Database storage increased rapidly.

Investigation finds a LOB segment consuming 300 GB.

Check:

*/

SELECT
    l.OWNER,
    l.TABLE_NAME,
    l.COLUMN_NAME,
    l.SEGMENT_NAME,
    l.SECUREFILE,
    l.COMPRESSION,
    l.DEDUPLICATION,
    ROUND(s.BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_LOBS l
JOIN DBA_SEGMENTS s
ON l.OWNER = s.OWNER
AND l.SEGMENT_NAME = s.SEGMENT_NAME
WHERE l.OWNER = UPPER('&OWNER')
ORDER BY s.BYTES DESC;


/*
Then discuss with application team:

- Is LOB data expected?
- Is old LOB data purged?
- Is retention policy working?
- Is SecureFile used?
- Is compression appropriate?
- Is deduplication appropriate?
- Is partitioning required?
*/


/*******************************************************************************
97. REAL-TIME SCENARIO 5
    MANY EXTENTS
*******************************************************************************/

/*
Issue:
------
A DBA notices a table with 2,000 extents.

Do not immediately claim:
"Many extents = fragmentation/performance issue."

First check:

1. Locally managed tablespace?
2. AUTOALLOCATE or UNIFORM?
3. Segment size?
4. Oracle version?
5. Growth pattern?
6. Actual performance symptoms?

Query:
*/

SELECT
    s.OWNER,
    s.SEGMENT_NAME,
    s.SEGMENT_TYPE,
    s.TABLESPACE_NAME,
    s.EXTENTS,
    ROUND(s.BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB,
    t.EXTENT_MANAGEMENT
FROM DBA_SEGMENTS s
JOIN DBA_TABLESPACES t
ON s.TABLESPACE_NAME = t.TABLESPACE_NAME
WHERE s.EXTENTS > 1000
ORDER BY s.EXTENTS DESC;


/*******************************************************************************
98. REAL-TIME SCENARIO 6
    DATAFILE CANNOT SHRINK
*******************************************************************************/

/*
Error:
------
ORA-03297

Approach:

1. Identify datafile.
2. Find highest used extent.
3. Identify object.
4. Check whether object can be moved/shrunk.
5. Reorganize if approved.
6. Recheck highest used extent.
7. Resize datafile.

Query:
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
        * ts.BLOCK_SIZE
        / 1024 / 1024,
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
99. REAL-TIME SCENARIO 7
    INDEX TABLESPACE FULL
*******************************************************************************/

/*
ORA-01654

Approach:

1. Identify index.
2. Identify index tablespace.
3. Check tablespace usage.
4. Check datafile capacity.
5. Check filesystem/ASM.
6. Check index growth.
7. Add/resize capacity if required.
8. Rebuild only if there is a valid reason.

Do not use index rebuild as a generic tablespace-space fix.
*/


/*******************************************************************************
100. REAL-TIME SCENARIO 8
     LARGE PARTITION
*******************************************************************************/

/*
Situation:
---------
One partition consumes 200 GB while other partitions are small.

Check:

*/

SELECT
    OWNER,
    SEGMENT_NAME,
    PARTITION_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE SEGMENT_NAME = UPPER('&TABLE_NAME')
ORDER BY BYTES DESC;


/*
Possible solutions:

- Partition pruning / design review
- Partition exchange
- Archive old partition
- Drop/truncate expired partition
- Move partition
- Compress where appropriate
- Review retention policy
*/


/*******************************************************************************
101. REAL-TIME SCENARIO 9
     APPLICATION REPORTS "DATABASE SPACE FULL"
*******************************************************************************/

/*
Never assume "database space full" means datafile full.

Determine:

DATABASE SPACE
      |
      +--> DATA TABLESPACE
      |
      +--> INDEX TABLESPACE
      |
      +--> TEMP
      |
      +--> UNDO
      |
      +--> ARCHIVE LOG DESTINATION
      |
      +--> ASM
      |
      +--> FILESYSTEM
      |
      +--> USER QUOTA

Then identify the exact resource.
*/


/*******************************************************************************
102. LARGE SEGMENT TROUBLESHOOTING FLOW
*******************************************************************************/

/*

SPACE ALERT
     |
     v
Identify TABLESPACE
     |
     v
Find TOP SEGMENTS
     |
     v
+----------------------+
| TABLE / INDEX / LOB |
| PARTITION / OTHER   |
+----------------------+
     |
     v
Check historical growth
     |
     v
Expected growth?
   /       \
 YES        NO
 |           |
 v           v
Capacity   Investigate
planning   root cause
 |           |
 v           v
Monitor    Purge / archive /
           application fix
     |
     v
Need reclaim?
     |
   +---+---+
   |       |
  NO      YES
   |       |
   v       v
Monitor  SHRINK / MOVE /
         REBUILD / PARTITION
              |
              v
          Verify space
              |
              v
          Monitor
*/


/*******************************************************************************
103. LARGE SEGMENT DAILY CHECK
*******************************************************************************/

SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
ORDER BY BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
104. LARGE OBJECTS BY OWNER
*******************************************************************************/

SELECT
    OWNER,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_GB
FROM DBA_SEGMENTS
GROUP BY OWNER
ORDER BY TOTAL_GB DESC;


/*******************************************************************************
105. LARGE OBJECTS BY TABLESPACE
*******************************************************************************/

SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_GB
FROM DBA_SEGMENTS
GROUP BY TABLESPACE_NAME
ORDER BY TOTAL_GB DESC;


/*******************************************************************************
106. SPACE USED BY TABLE / INDEX / LOB
*******************************************************************************/

SELECT
    SEGMENT_TYPE,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_GB
FROM DBA_SEGMENTS
GROUP BY SEGMENT_TYPE
ORDER BY TOTAL_GB DESC;


/*******************************************************************************
107. FINAL LARGE SEGMENT HEALTH CHECK
*******************************************************************************/

SELECT
    s.OWNER,
    s.SEGMENT_NAME,
    s.SEGMENT_TYPE,
    s.TABLESPACE_NAME,
    ROUND(s.BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB,
    s.EXTENTS,
    ts.SEGMENT_SPACE_MANAGEMENT,
    ts.EXTENT_MANAGEMENT,
    ts.BIGFILE
FROM DBA_SEGMENTS s
JOIN DBA_TABLESPACES ts
ON s.TABLESPACE_NAME = ts.TABLESPACE_NAME
ORDER BY s.BYTES DESC
FETCH FIRST 50 ROWS ONLY;


/*******************************************************************************
108. INTERVIEW QUESTIONS
*******************************************************************************/

/*
===============================================================================
Q1. What is a large segment?
===============================================================================

A large segment is a table, index, LOB, partition or other database segment
that consumes significant storage relative to the database workload.

I identify large segments using DBA_SEGMENTS and investigate their growth,
purpose and storage requirements.


===============================================================================
Q2. How do you find the largest table?
===============================================================================

SELECT
    OWNER,
    SEGMENT_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE = 'TABLE'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


===============================================================================
Q3. How do you find the largest index?
===============================================================================

SELECT
    OWNER,
    SEGMENT_NAME,
    ROUND(BYTES / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE LIKE 'INDEX%'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;


===============================================================================
Q4. DELETE removed 400 GB but tablespace did not reduce. Why?
===============================================================================

DELETE removes rows but does not automatically reduce the segment's allocated
space back to the tablespace.

For eligible objects, I can investigate SHRINK or MOVE after checking
application impact and taking the required approval.


===============================================================================
Q5. What is HWM?
===============================================================================

HWM stands for High Water Mark.

It represents the boundary associated with blocks that have been used/formatted
within a segment. Deleting rows does not necessarily lower the HWM.

Appropriate segment reorganization can lower the HWM and reclaim space.


===============================================================================
Q6. SHRINK vs MOVE?
===============================================================================

SHRINK:
- Works for eligible segments in ASSM.
- Requires row movement for tables.
- Can compact the segment.
- Can reduce HWM.
- Keeps the segment in the same tablespace.

MOVE:
- Relocates the segment.
- Can move it to another tablespace.
- Associated indexes may require attention/rebuild depending on operation.


===============================================================================
Q7. Does a large index mean it is bad?
===============================================================================

No.

A large index may be completely normal for a large table and required by
application queries.

I investigate index design, growth, workload, columns, partitioning and
business requirements before considering any maintenance.


===============================================================================
Q8. Does a high extent count mean fragmentation?
===============================================================================

Not necessarily.

Modern locally managed tablespaces and automatic extent allocation can
legitimately produce many extents. I check the tablespace configuration,
segment size and actual symptoms before taking action.


===============================================================================
Q9. How do you troubleshoot rapid segment growth?
===============================================================================

I compare current segment sizes with historical snapshots, identify the
fastest-growing objects, determine whether they are tables, indexes, LOBs
or partitions, and correlate the growth with application jobs, data loads,
retention and business activity.


===============================================================================
Q10. How do you troubleshoot a large LOB?
===============================================================================

I query DBA_LOBS and DBA_SEGMENTS, identify the table and LOB column, review
SecureFile/BasicFile characteristics, retention and application data growth,
and then work with the application team on retention, archival and storage
strategy.


===============================================================================
Q11. How do you troubleshoot ORA-03297?
===============================================================================

I identify the datafile and find the highest used extent using DBA_EXTENTS.
Then I identify the object occupying the space. If appropriate, I move or
shrink the object and then resize the datafile to a safe target.


===============================================================================
Q12. Would you rebuild all indexes monthly?
===============================================================================

No.

Index rebuilds should be driven by a valid technical requirement, such as
relocation, recovery from certain structural situations, or a specific
space/design requirement. I do not rebuild indexes simply because they are
old or large.


===============================================================================
Q13. How do you find space consumed by one application schema?
===============================================================================

SELECT
    OWNER,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_GB
FROM DBA_SEGMENTS
WHERE OWNER = UPPER('&OWNER')
GROUP BY OWNER;


===============================================================================
Q14. What is your production approach for a large segment?
===============================================================================

My approach is:

1. Identify the object.
2. Confirm business ownership.
3. Check current and historical growth.
4. Determine whether growth is expected.
5. Check tablespace and storage capacity.
6. Check object type.
7. Review retention/archival.
8. Determine whether space reclamation is required.
9. Select SHRINK/MOVE/partition maintenance only if appropriate.
10. Take change approval.
11. Execute during an appropriate maintenance window.
12. Perform post-checks.
13. Monitor afterward.


===============================================================================
Q15. What are the main views you use?
===============================================================================

DBA_SEGMENTS
    -> Segment size and allocation

DBA_EXTENTS
    -> Extent-level information

DBA_TABLES
    -> Table metadata/statistics

DBA_INDEXES
    -> Index metadata/statistics

DBA_LOBS
    -> LOB metadata

DBA_TAB_PARTITIONS
    -> Table partition information

DBA_SEGMENTS
    -> Partition segment sizes

DBA_TABLESPACES
    -> Tablespace storage configuration


/*******************************************************************************
109. GOLDEN RULES
*******************************************************************************/

/*
1. Use DBA_SEGMENTS to identify large segments.
2. Use DBA_EXTENTS for extent-level analysis.
3. Large does not automatically mean bad.
4. High extent count does not automatically mean fragmentation.
5. DELETE does not automatically return all segment space to the tablespace.
6. SHRINK can reclaim space for eligible segments.
7. MOVE can relocate segments.
8. Rebuild indexes only for a valid reason.
9. Investigate LOB growth separately.
10. Investigate partition growth separately.
11. Compare current size with historical growth.
12. Check application retention policies.
13. Always verify filesystem/ASM capacity.
14. Use change management for production operations.
15. Perform pre-check and post-check.
16. Monitor segment growth continuously.
*/


/*******************************************************************************
110. FINAL DBA WORKFLOW
*******************************************************************************/

/*

                    SPACE GROWTH ALERT
                            |
                            v
                    DBA_SEGMENTS
                            |
                            v
                    Identify Object
                            |
          +-----------------+-----------------+
          |                 |                 |
          v                 v                 v
        TABLE             INDEX              LOB
          |                 |                 |
          v                 v                 v
       Growth?           Growth?           Growth?
          |                 |                 |
          +-----------------+-----------------+
                            |
                            v
                   Check Historical Data
                            |
                            v
                    Expected Growth?
                       /          \
                     YES           NO
                      |             |
                      v             v
                Capacity Plan    RCA
                      |             |
                      |       +-----+------+
                      |       |            |
                      |       v            v
                      |     Data        Application
                      |     Growth      /Retention
                      |       |            |
                      +-------+------------+
                              |
                              v
                      Need Space Reclaim?
                         /           \
                       NO             YES
                       |               |
                       v               v
                    Monitor      Check Eligibility
                                      |
                         +------------+------------+
                         |            |            |
                         v            v            v
                       SHRINK        MOVE       REBUILD
                         |            |            |
                         +------------+------------+
                                      |
                                      v
                                  Verify
                                      |
                                      v
                                  Monitor
*/


/*******************************************************************************
END OF FILE
*******************************************************************************/

/*
===============================================================================
08_large_segments.sql COMPLETE

KEY VIEWS
---------
DBA_SEGMENTS
DBA_EXTENTS
DBA_TABLES
DBA_INDEXES
DBA_LOBS
DBA_TAB_PARTITIONS
DBA_TABLESPACES

KEY CONCEPTS
------------
Large Segment
Extent
HWM
Segment Growth
SHRINK
MOVE
REBUILD
LOB
Partition
Space Reclamation

NEXT MODULE
-----------
09_asm_tablespaces.sql

Recommended topics:
    ASM tablespace creation
    ASM datafiles
    OMF + ASM
    Diskgroup monitoring
    ASM resize
    ASM add disk
    Bigfile tablespace on ASM
    TEMP on ASM
    UNDO on ASM
    ASM space troubleshooting
===============================================================================
*/
```
