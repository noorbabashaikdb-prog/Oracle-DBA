# 06_quota_management.sql

# Oracle User Quota Management

# Oracle 12c / 19c

# Practical DBA Reference

# /*

# PURPOSE

This script covers practical Oracle DBA activities related to USER QUOTAS:

1. What is a quota?
2. Tablespace quota concepts
3. Check user quotas
4. Check unlimited quotas
5. Grant quota
6. Modify quota
7. Remove quota
8. Unlimited quota
9. Multiple tablespace quotas
10. User default tablespace
11. Tablespace vs quota
12. Quota troubleshooting
13. ORA-01536
14. Real-time production scenarios
15. DBA monitoring queries
16. Interview questions

===============================================================================
IMPORTANT
=========

A quota controls how much space a user can allocate for objects in a
specific tablespace.

A quota is NOT the same as:

* User privilege
* Tablespace size
* Datafile size
* Filesystem capacity
* ASM diskgroup capacity

Example:

DATABASE
|
+-- USERS TABLESPACE
|
+-- Datafiles
|
+-- USER SCOTT QUOTA
|
+-- 500 MB

===============================================================================
*/

-- ============================================================================
-- 1. CHECK DATABASE INFORMATION
-- ============================================================================

SELECT NAME,
OPEN_MODE,
DATABASE_ROLE
FROM V$DATABASE;

SELECT INSTANCE_NAME,
STATUS
FROM V$INSTANCE;

-- ============================================================================
-- 2. CHECK ALL USERS
-- ============================================================================

SELECT USERNAME,
ACCOUNT_STATUS,
DEFAULT_TABLESPACE,
TEMPORARY_TABLESPACE
FROM DBA_USERS
ORDER BY USERNAME;

-- ============================================================================
-- 3. CHECK USER QUOTAS
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
BYTES,
MAX_BYTES,
BLOCKS,
MAX_BLOCKS
FROM DBA_TS_QUOTAS
ORDER BY USERNAME,
TABLESPACE_NAME;

-- ============================================================================
-- 4. USER QUOTA IN MB
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
CASE
WHEN MAX_BYTES = -1 THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(MAX_BYTES / 1024 / 1024, 2)
)
END AS QUOTA_MB
FROM DBA_TS_QUOTAS
ORDER BY USERNAME,
TABLESPACE_NAME;

-- ============================================================================
-- 5. USER QUOTA IN GB
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024 / 1024, 2) AS USED_GB,
CASE
WHEN MAX_BYTES = -1 THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(MAX_BYTES / 1024 / 1024 / 1024, 2)
)
END AS QUOTA_GB
FROM DBA_TS_QUOTAS
ORDER BY USERNAME,
TABLESPACE_NAME;

-- ============================================================================
-- 6. CHECK UNLIMITED QUOTAS
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
'UNLIMITED' AS QUOTA
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES = -1
ORDER BY USERNAME,
TABLESPACE_NAME;

-- ============================================================================
-- 7. CHECK USERS WITH LIMITED QUOTA
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
ROUND(MAX_BYTES / 1024 / 1024, 2) AS QUOTA_MB
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES <> -1
ORDER BY USERNAME,
TABLESPACE_NAME;

-- ============================================================================
-- 8. CHECK USERS WITH QUOTA ABOVE 80%
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
ROUND(MAX_BYTES / 1024 / 1024, 2) AS QUOTA_MB,
ROUND(
BYTES / NULLIF(MAX_BYTES, 0) * 100,
2
) AS USED_PERCENT
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES > 0
AND BYTES / MAX_BYTES * 100 >= 80
ORDER BY USED_PERCENT DESC;

-- ============================================================================
-- 9. CHECK USERS WITH QUOTA ABOVE 90%
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
ROUND(MAX_BYTES / 1024 / 1024, 2) AS QUOTA_MB,
ROUND(
BYTES / NULLIF(MAX_BYTES, 0) * 100,
2
) AS USED_PERCENT
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES > 0
AND BYTES / MAX_BYTES * 100 >= 90
ORDER BY USED_PERCENT DESC;

-- ============================================================================
-- 10. CHECK USERS WITH QUOTA ABOVE 95%
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
ROUND(MAX_BYTES / 1024 / 1024, 2) AS QUOTA_MB,
ROUND(
BYTES / NULLIF(MAX_BYTES, 0) * 100,
2
) AS USED_PERCENT
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES > 0
AND BYTES / MAX_BYTES * 100 >= 95
ORDER BY USED_PERCENT DESC;

-- ============================================================================
-- 11. CHECK QUOTA FOR SPECIFIC USER
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
CASE
WHEN MAX_BYTES = -1 THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(MAX_BYTES / 1024 / 1024, 2)
)
END AS QUOTA_MB
FROM DBA_TS_QUOTAS
WHERE USERNAME = 'SCOTT';

-- ============================================================================
-- 12. CHECK QUOTA FOR SPECIFIC TABLESPACE
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
CASE
WHEN MAX_BYTES = -1 THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(MAX_BYTES / 1024 / 1024, 2)
)
END AS QUOTA_MB
FROM DBA_TS_QUOTAS
WHERE TABLESPACE_NAME = 'USERS'
ORDER BY USED_MB DESC;

-- ============================================================================
-- 13. GRANT 100 MB QUOTA
-- ============================================================================

ALTER USER SCOTT
QUOTA 100M ON USERS;

-- ============================================================================
-- 14. GRANT 500 MB QUOTA
-- ============================================================================

ALTER USER SCOTT
QUOTA 500M ON USERS;

-- ============================================================================
-- 15. GRANT 1 GB QUOTA
-- ============================================================================

ALTER USER SCOTT
QUOTA 1G ON USERS;

-- ============================================================================
-- 16. GRANT 5 GB QUOTA
-- ============================================================================

ALTER USER SCOTT
QUOTA 5G ON USERS;

-- ============================================================================
-- 17. GRANT UNLIMITED QUOTA
-- ============================================================================

ALTER USER SCOTT
QUOTA UNLIMITED ON USERS;

-- ============================================================================
-- 18. REMOVE USER QUOTA
-- ============================================================================

ALTER USER SCOTT
QUOTA 0 ON USERS;

-- ============================================================================
-- 19. GRANT QUOTA ON APPLICATION TABLESPACE
-- ============================================================================

ALTER USER APPUSER
QUOTA 2G ON APP_DATA;

-- ============================================================================
-- 20. GRANT QUOTA ON INDEX TABLESPACE
-- ============================================================================

ALTER USER APPUSER
QUOTA 1G ON APP_INDEX;

-- ============================================================================
-- 21. MULTIPLE TABLESPACE QUOTAS
-- ============================================================================

ALTER USER APPUSER
QUOTA 5G ON APP_DATA;

ALTER USER APPUSER
QUOTA 2G ON APP_INDEX;

ALTER USER APPUSER
QUOTA 500M ON REPORT_DATA;

-- ============================================================================
-- 22. VERIFY MULTIPLE QUOTAS
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
CASE
WHEN MAX_BYTES = -1 THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(MAX_BYTES / 1024 / 1024, 2)
)
END AS QUOTA_MB
FROM DBA_TS_QUOTAS
WHERE USERNAME = 'APPUSER'
ORDER BY TABLESPACE_NAME;

-- ============================================================================
-- 23. USER DEFAULT TABLESPACE
-- ============================================================================

SELECT USERNAME,
DEFAULT_TABLESPACE
FROM DBA_USERS
ORDER BY USERNAME;

-- ============================================================================
-- 24. CHANGE USER DEFAULT TABLESPACE
-- ============================================================================

ALTER USER APPUSER
DEFAULT TABLESPACE APP_DATA;

-- ============================================================================
-- 25. VERIFY DEFAULT TABLESPACE
-- ============================================================================

SELECT USERNAME,
DEFAULT_TABLESPACE,
TEMPORARY_TABLESPACE
FROM DBA_USERS
WHERE USERNAME = 'APPUSER';

-- ============================================================================
-- 26. CREATE USER WITH DEFAULT TABLESPACE
-- ============================================================================

CREATE USER APPUSER
IDENTIFIED BY "LabPassword123"
DEFAULT TABLESPACE APP_DATA
TEMPORARY TABLESPACE TEMP;

-- ============================================================================
-- 27. CREATE USER WITH QUOTA
-- ============================================================================

CREATE USER REPORTUSER
IDENTIFIED BY "LabPassword123"
DEFAULT TABLESPACE REPORT_DATA
TEMPORARY TABLESPACE TEMP
QUOTA 1G ON REPORT_DATA;

-- ============================================================================
-- 28. CREATE USER WITH MULTIPLE QUOTAS
-- ============================================================================

CREATE USER BATCHUSER
IDENTIFIED BY "LabPassword123"
DEFAULT TABLESPACE APP_DATA
TEMPORARY TABLESPACE TEMP
QUOTA 5G ON APP_DATA
QUOTA 2G ON APP_INDEX;

-- ============================================================================
-- 29. CREATE USER WITH UNLIMITED QUOTA
-- ============================================================================

/*
Use unlimited quota carefully.

Production applications should normally have an explicitly reviewed
quota rather than unrestricted growth.
*/

CREATE USER DEVUSER
IDENTIFIED BY "LabPassword123"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

-- ============================================================================
-- 30. GRANT RESOURCE PRIVILEGE
-- ============================================================================

/*
Important:

Having CREATE TABLE privilege does not automatically mean the user
can consume unlimited space in every tablespace.

Quota and privileges are separate concepts.

*/

GRANT CREATE SESSION TO APPUSER;
GRANT CREATE TABLE TO APPUSER;

-- ============================================================================
-- 31. CHECK SYSTEM PRIVILEGES
-- ============================================================================

SELECT GRANTEE,
PRIVILEGE
FROM DBA_SYS_PRIVS
WHERE GRANTEE IN
(
'APPUSER',
'REPORTUSER',
'BATCHUSER'
)
ORDER BY GRANTEE,
PRIVILEGE;

-- ============================================================================
-- 32. CHECK ROLE PRIVILEGES
-- ============================================================================

SELECT GRANTEE,
GRANTED_ROLE
FROM DBA_ROLE_PRIVS
WHERE GRANTEE IN
(
'APPUSER',
'REPORTUSER',
'BATCHUSER'
)
ORDER BY GRANTEE;

-- ============================================================================
-- 33. CHECK OBJECTS OWNED BY USER
-- ============================================================================

SELECT OWNER,
OBJECT_TYPE,
COUNT(*) AS OBJECT_COUNT
FROM DBA_OBJECTS
WHERE OWNER = 'APPUSER'
GROUP BY OWNER,
OBJECT_TYPE
ORDER BY OBJECT_TYPE;

-- ============================================================================
-- 34. CHECK SEGMENTS OWNED BY USER
-- ============================================================================

SELECT OWNER,
SEGMENT_NAME,
SEGMENT_TYPE,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE OWNER = 'APPUSER'
ORDER BY BYTES DESC;

-- ============================================================================
-- 35. USER SPACE USED BY TABLESPACE
-- ============================================================================

SELECT OWNER,
TABLESPACE_NAME,
ROUND(SUM(BYTES) / 1024 / 1024, 2) AS USED_MB
FROM DBA_SEGMENTS
WHERE OWNER = 'APPUSER'
GROUP BY OWNER,
TABLESPACE_NAME
ORDER BY USED_MB DESC;

-- ============================================================================
-- 36. COMPARE QUOTA WITH ACTUAL SEGMENT USAGE
-- ============================================================================

SELECT q.USERNAME,
q.TABLESPACE_NAME,
ROUND(q.BYTES / 1024 / 1024, 2) AS QUOTA_USED_MB,
CASE
WHEN q.MAX_BYTES = -1 THEN NULL
ELSE ROUND(q.MAX_BYTES / 1024 / 1024, 2)
END AS QUOTA_MB,
ROUND(
NVL(seg.SEGMENT_BYTES, 0) / 1024 / 1024,
2
) AS SEGMENT_USED_MB
FROM DBA_TS_QUOTAS q
LEFT JOIN
(
SELECT OWNER,
TABLESPACE_NAME,
SUM(BYTES) AS SEGMENT_BYTES
FROM DBA_SEGMENTS
GROUP BY OWNER,
TABLESPACE_NAME
) seg
ON seg.OWNER = q.USERNAME
AND seg.TABLESPACE_NAME = q.TABLESPACE_NAME
ORDER BY q.USERNAME,
q.TABLESPACE_NAME;

-- ============================================================================
-- 37. QUOTA REMAINING
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
ROUND(MAX_BYTES / 1024 / 1024, 2) AS QUOTA_MB,
ROUND(
(MAX_BYTES - BYTES) / 1024 / 1024,
2
) AS REMAINING_MB,
ROUND(
BYTES / NULLIF(MAX_BYTES, 0) * 100,
2
) AS USED_PERCENT
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES > 0
ORDER BY USED_PERCENT DESC;

-- ============================================================================
-- 38. QUOTA REMAINING BELOW 100 MB
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(
(MAX_BYTES - BYTES) / 1024 / 1024,
2
) AS REMAINING_MB
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES > 0
AND (MAX_BYTES - BYTES) < 100 * 1024 * 1024
ORDER BY REMAINING_MB;

-- ============================================================================
-- 39. QUOTA USAGE REPORT
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
CASE
WHEN MAX_BYTES = -1 THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(MAX_BYTES / 1024 / 1024, 2)
)
END AS QUOTA_MB,
CASE
WHEN MAX_BYTES = -1 THEN 'N/A'
ELSE TO_CHAR(
ROUND(
BYTES / NULLIF(MAX_BYTES, 0) * 100,
2
)
)
END AS USED_PERCENT
FROM DBA_TS_QUOTAS
ORDER BY USERNAME,
TABLESPACE_NAME;

-- ============================================================================
-- 40. TABLESPACE CAPACITY VS USER QUOTA
-- ============================================================================

SELECT t.TABLESPACE_NAME,
ROUND(
SUM(df.BYTES) / 1024 / 1024 / 1024,
2
) AS TABLESPACE_SIZE_GB,
COUNT(q.USERNAME) AS USERS_WITH_QUOTA
FROM DBA_TABLESPACES t
LEFT JOIN DBA_DATA_FILES df
ON df.TABLESPACE_NAME = t.TABLESPACE_NAME
LEFT JOIN DBA_TS_QUOTAS q
ON q.TABLESPACE_NAME = t.TABLESPACE_NAME
WHERE t.CONTENTS = 'PERMANENT'
GROUP BY t.TABLESPACE_NAME
ORDER BY t.TABLESPACE_NAME;

-- ============================================================================
-- 41. FIND USERS WITHOUT EXPLICIT QUOTA
-- ============================================================================

/*
A user may have no row in DBA_TS_QUOTAS for a tablespace.

This does not mean the user has access to that tablespace.

Quota is required before the user can allocate objects there unless
the user has an applicable unlimited-tablespace system privilege.
*/

SELECT u.USERNAME,
u.DEFAULT_TABLESPACE
FROM DBA_USERS u
WHERE u.ACCOUNT_STATUS LIKE 'OPEN%'
AND NOT EXISTS
(
SELECT 1
FROM DBA_TS_QUOTAS q
WHERE q.USERNAME = u.USERNAME
AND q.TABLESPACE_NAME = u.DEFAULT_TABLESPACE
)
ORDER BY u.USERNAME;

-- ============================================================================
-- 42. CHECK UNLIMITED TABLESPACE PRIVILEGE
-- ============================================================================

SELECT GRANTEE,
PRIVILEGE
FROM DBA_SYS_PRIVS
WHERE PRIVILEGE = 'UNLIMITED TABLESPACE'
ORDER BY GRANTEE;

-- ============================================================================
-- 43. CHECK USERS HAVING UNLIMITED TABLESPACE
-- ============================================================================

SELECT GRANTEE
FROM DBA_SYS_PRIVS
WHERE PRIVILEGE = 'UNLIMITED TABLESPACE'
ORDER BY GRANTEE;

-- ============================================================================
-- 44. GRANT UNLIMITED TABLESPACE
-- ============================================================================

/*
WARNING:

This is a powerful privilege.

It allows the user to use unlimited space in tablespaces subject to
other database/storage constraints.

Prefer specific quotas for normal application users.

*/

GRANT UNLIMITED TABLESPACE TO APPUSER;

-- ============================================================================
-- 45. REVOKE UNLIMITED TABLESPACE
-- ============================================================================

REVOKE UNLIMITED TABLESPACE FROM APPUSER;

-- ============================================================================
-- 46. QUOTA VS UNLIMITED TABLESPACE
-- ============================================================================

/*

Specific quota:

ALTER USER APPUSER QUOTA 5G ON APP_DATA;

Meaning:

APPUSER can allocate up to 5 GB in APP_DATA.

Unlimited quota:

ALTER USER APPUSER QUOTA UNLIMITED ON APP_DATA;

Meaning:

APPUSER has no per-tablespace quota limit on APP_DATA.

System privilege:

GRANT UNLIMITED TABLESPACE TO APPUSER;

Meaning:

The user is not constrained by normal per-tablespace quotas.

IMPORTANT:
This does not mean the underlying disk, ASM diskgroup or datafile can
grow forever.

*/

-- ============================================================================
-- 47. REMOVE SPECIFIC QUOTA
-- ============================================================================

ALTER USER APPUSER
QUOTA 0 ON APP_DATA;

-- ============================================================================
-- 48. REMOVE QUOTA FROM MULTIPLE TABLESPACES
-- ============================================================================

ALTER USER APPUSER
QUOTA 0 ON APP_DATA;

ALTER USER APPUSER
QUOTA 0 ON APP_INDEX;

-- ============================================================================
-- 49. CHECK TABLESPACE STATUS
-- ============================================================================

SELECT TABLESPACE_NAME,
STATUS,
CONTENTS,
LOGGING,
EXTENT_MANAGEMENT,
ALLOCATION_TYPE
FROM DBA_TABLESPACES
ORDER BY TABLESPACE_NAME;

-- ============================================================================
-- 50. CHECK TABLESPACE SPACE
-- ============================================================================

SELECT TABLESPACE_NAME,
ROUND(SUM(BYTES) / 1024 / 1024, 2) AS TOTAL_MB
FROM DBA_DATA_FILES
GROUP BY TABLESPACE_NAME
ORDER BY TOTAL_MB DESC;

-- ============================================================================
-- 51. USER QUOTA AND TABLESPACE FREE SPACE
-- ============================================================================

SELECT q.USERNAME,
q.TABLESPACE_NAME,
ROUND(q.BYTES / 1024 / 1024, 2) AS USER_USED_MB,
CASE
WHEN q.MAX_BYTES = -1 THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(q.MAX_BYTES / 1024 / 1024, 2)
)
END AS USER_QUOTA_MB,
ROUND(
NVL(fs.FREE_BYTES, 0) / 1024 / 1024,
2
) AS TABLESPACE_FREE_MB
FROM DBA_TS_QUOTAS q
LEFT JOIN
(
SELECT TABLESPACE_NAME,
SUM(BYTES) AS FREE_BYTES
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
) fs
ON fs.TABLESPACE_NAME = q.TABLESPACE_NAME
ORDER BY q.USERNAME,
q.TABLESPACE_NAME;

-- ============================================================================
-- 52. FIND LARGEST USERS BY SPACE
-- ============================================================================

SELECT OWNER,
ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS USED_GB
FROM DBA_SEGMENTS
GROUP BY OWNER
ORDER BY USED_GB DESC
FETCH FIRST 20 ROWS ONLY;

-- ============================================================================
-- 53. FIND LARGEST USER/TABLESPACE COMBINATIONS
-- ============================================================================

SELECT OWNER,
TABLESPACE_NAME,
ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS USED_GB
FROM DBA_SEGMENTS
GROUP BY OWNER,
TABLESPACE_NAME
ORDER BY USED_GB DESC
FETCH FIRST 20 ROWS ONLY;

-- ============================================================================
-- 54. FIND USERS CLOSE TO QUOTA LIMIT
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
ROUND(MAX_BYTES / 1024 / 1024, 2) AS QUOTA_MB,
ROUND(
BYTES / MAX_BYTES * 100,
2
) AS USED_PERCENT
FROM DBA_TS_QUOTAS
WHERE MAX_BYTES > 0
AND BYTES / MAX_BYTES >= 0.90
ORDER BY USED_PERCENT DESC;

-- ============================================================================
-- 55. REAL-TIME SCENARIO - ORA-01536
-- ============================================================================

/*

ERROR:

ORA-01536: space quota exceeded for table name

SCENARIO:

Application team reports:

"APPUSER is unable to insert data."

Example error:

ORA-01536: space quota exceeded for table APPUSER.TABLE_NAME

STEP 1:
Check user quota.

*/

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
ROUND(MAX_BYTES / 1024 / 1024, 2) AS QUOTA_MB,
ROUND(
BYTES / NULLIF(MAX_BYTES, 0) * 100,
2
) AS USED_PERCENT
FROM DBA_TS_QUOTAS
WHERE USERNAME = 'APPUSER';

/*
STEP 2:
Check actual segment usage.
*/

SELECT OWNER,
SEGMENT_NAME,
SEGMENT_TYPE,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM DBA_SEGMENTS
WHERE OWNER = 'APPUSER'
ORDER BY BYTES DESC;

/*
STEP 3:
Check tablespace capacity.
*/

SELECT TABLESPACE_NAME,
ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_GB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'APP_DATA'
GROUP BY TABLESPACE_NAME;

/*
STEP 4:
Check free space.
*/

SELECT TABLESPACE_NAME,
ROUND(SUM(BYTES) / 1024 / 1024, 2) AS FREE_MB
FROM DBA_FREE_SPACE
WHERE TABLESPACE_NAME = 'APP_DATA'
GROUP BY TABLESPACE_NAME;

/*
STEP 5:
If business approval is obtained, increase quota.

Example:
*/

ALTER USER APPUSER
QUOTA 10G ON APP_DATA;

/*
STEP 6:
Verify.
*/

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
ROUND(MAX_BYTES / 1024 / 1024, 2) AS QUOTA_MB
FROM DBA_TS_QUOTAS
WHERE USERNAME = 'APPUSER'
AND TABLESPACE_NAME = 'APP_DATA';

-- ============================================================================
-- 56. ORA-01536 DECISION FLOW
-- ============================================================================

/*

```
              ORA-01536
                  |
          Check user quota
                  |
        +---------+---------+
        |                   |
    Quota full          Quota available
        |                   |
  Check approval       Check other causes
        |
   Increase quota
        |
   Check tablespace
   free space
        |
 Check datafile/ASM
   capacity
        |
     Verify
```

*/

-- ============================================================================
-- 57. IMPORTANT: QUOTA FULL DOES NOT ALWAYS MEAN TABLESPACE FULL
-- ============================================================================

/*

Example:

APP_DATA tablespace = 500 GB

APPUSER quota       = 5 GB

APPUSER usage       = 5 GB

APP_DATA free space = 300 GB

APPUSER can still receive:

ORA-01536: space quota exceeded

Why?

Because APPUSER reached its 5 GB user quota.

Solution:

ALTER USER APPUSER QUOTA 10G ON APP_DATA;

The DBA does NOT necessarily need to add a datafile.

*/

-- ============================================================================
-- 58. IMPORTANT: TABLESPACE FULL DOES NOT EQUAL USER QUOTA FULL
-- ============================================================================

/*

Example:

APP_DATA tablespace = 500 GB
APPUSER quota       = 100 GB
APPUSER usage       = 50 GB

But:

APP_DATA used       = 500 GB

Another user/application may have consumed the remaining space.

APPUSER still has quota remaining, but the tablespace itself has no
space available.

Solution:

Investigate tablespace capacity, datafiles, autoextend, filesystem
or ASM capacity.

*/

-- ============================================================================
-- 59. QUOTA + AUTOEXTEND SCENARIO
-- ============================================================================

/*

Example:

User quota:

APPUSER = 10 GB

Tablespace datafile:

Current size = 20 GB
MAXSIZE      = 100 GB

APPUSER uses 10 GB.

Result:

APPUSER can receive ORA-01536 even though the datafile can still grow.

Reason:

User quota is the limiting factor.

*/

-- ============================================================================
-- 60. QUOTA MONITORING REPORT
-- ============================================================================

SELECT q.USERNAME,
q.TABLESPACE_NAME,
ROUND(q.BYTES / 1024 / 1024, 2) AS USED_MB,
CASE
WHEN q.MAX_BYTES = -1 THEN NULL
ELSE ROUND(q.MAX_BYTES / 1024 / 1024, 2)
END AS QUOTA_MB,
CASE
WHEN q.MAX_BYTES = -1 THEN NULL
ELSE ROUND(
q.MAX_BYTES / 1024 / 1024
-
q.BYTES / 1024 / 1024,
2
)
END AS REMAINING_MB,
CASE
WHEN q.MAX_BYTES = -1 THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(
q.BYTES /
NULLIF(q.MAX_BYTES, 0) * 100,
2
)
)
END AS USED_PERCENT
FROM DBA_TS_QUOTAS q
ORDER BY q.USERNAME,
q.TABLESPACE_NAME;

-- ============================================================================
-- 61. PRODUCTION DBA CHECK
-- ============================================================================

/*

Before increasing quota:

[ ] Confirm user
[ ] Confirm tablespace
[ ] Confirm current quota
[ ] Confirm current usage
[ ] Check ORA-01536
[ ] Check tablespace free space
[ ] Check datafile size
[ ] Check autoextend
[ ] Check MAXSIZE
[ ] Check filesystem/ASM free space
[ ] Confirm application/business requirement
[ ] Apply approved quota
[ ] Verify quota
[ ] Monitor growth

*/

-- ============================================================================
-- 62. QUOTA MANAGEMENT BEST PRACTICES
-- ============================================================================

/*

1. Prefer specific quotas over unlimited quota for application users.

2. Do not grant UNLIMITED TABLESPACE unnecessarily.

3. Monitor quota usage.

4. Monitor tablespace usage separately.

5. Check filesystem or ASM capacity before increasing quota.

6. Investigate unexpected growth.

7. Use separate tablespaces for important application data where
   appropriate.

8. Keep application data and indexes separated when required by design.

9. Document quota changes in production.

10. Follow change-management approval before modifying production quotas.

11. Avoid using unlimited quotas as a quick workaround.

12. Review large segments when quota usage increases unexpectedly.

*/

-- ============================================================================
-- 63. FINAL VERIFICATION
-- ============================================================================

SELECT USERNAME,
TABLESPACE_NAME,
ROUND(BYTES / 1024 / 1024, 2) AS USED_MB,
CASE
WHEN MAX_BYTES = -1 THEN 'UNLIMITED'
ELSE TO_CHAR(
ROUND(MAX_BYTES / 1024 / 1024, 2)
)
END AS QUOTA_MB
FROM DBA_TS_QUOTAS
ORDER BY USERNAME,
TABLESPACE_NAME;

-- ============================================================================
-- END OF FILE
-- ============================================================================

````

### Key concept for interviews

```text
                 USER STORAGE CONTROL
                         |
              +----------+----------+
              |                     |
        USER QUOTA              TABLESPACE
              |                     |
        Per-user limit        Total storage
              |                     |
       DBA_TS_QUOTAS          DBA_DATA_FILES
              |                     |
       User can allocate      Datafile capacity
              |                     |
              +----------+----------+
                         |
                  Physical Storage
                         |
                  FS / ASM Diskgroup
````

**Most important distinction:**

> `ORA-01536` = user quota problem, not automatically a tablespace-full problem.

For example, if `APP_DATA` has **500 GB free** but `APPUSER` has a **5 GB quota** and has already consumed 5 GB, `APPUSER` can still receive `ORA-01536`. Increasing the tablespace size alone will not fix the user's quota limit.
