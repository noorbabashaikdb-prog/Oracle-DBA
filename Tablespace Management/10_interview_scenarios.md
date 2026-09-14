# Oracle DBA Interview Scenarios

## 1. Purpose

This document contains **real-time, scenario-based Oracle DBA interview questions and answers** for 5–7 years experience.

Topics covered:

* Oracle database architecture
* Tablespace management
* ASM
* RAC
* Data Guard
* RMAN
* Data Pump
* Database refresh
* Patching
* Upgrades
* Performance tuning
* Blocking sessions
* Long-running SQL
* ORA errors
* Backup failures
* Listener issues
* Space management
* User/privilege issues
* Production incidents
* RCA and change management

---

# 2. Interview Answer Framework

For any production scenario, use this approach:

```text
                PRODUCTION ISSUE
                       |
                       v
                1. UNDERSTAND
                       |
                       v
                2. CHECK IMPACT
                       |
                       v
                3. COLLECT EVIDENCE
                       |
                       v
                4. IDENTIFY ROOT CAUSE
                       |
                       v
                5. TAKE SAFE ACTION
                       |
                       v
                6. VERIFY
                       |
                       v
                7. MONITOR
                       |
                       v
                8. RCA / PREVENTION
```

### Strong interview statement

> "First I understand the business impact, then I collect database and OS-level evidence. I identify the root cause before taking corrective action. After the fix, I validate the database and application, monitor the environment, and document the RCA and preventive action."

---

# 3. Database Is Slow

## Scenario

Application team reports:

> "The database is very slow."

## Step 1: Understand the impact

Ask:

* Which application?
* Which database?
* Which SQL/module?
* Since when?
* All users or specific users?
* Production or non-production?
* Is the issue intermittent or continuous?
* Was there any recent deployment/change?

## Step 2: Check database availability

```sql
SELECT
    INSTANCE_NAME,
    STATUS,
    DATABASE_STATUS
FROM V$INSTANCE;
```

```sql
SELECT
    NAME,
    OPEN_MODE,
    DATABASE_ROLE
FROM V$DATABASE;
```

## Step 3: Check active sessions

```sql
SELECT
    SID,
    SERIAL#,
    USERNAME,
    STATUS,
    EVENT,
    WAIT_CLASS,
    SQL_ID,
    BLOCKING_SESSION
FROM V$SESSION
WHERE STATUS = 'ACTIVE'
ORDER BY SID;
```

## Step 4: Check blocking sessions

```sql
SELECT
    SID,
    SERIAL#,
    USERNAME,
    BLOCKING_SESSION,
    EVENT,
    SQL_ID
FROM V$SESSION
WHERE BLOCKING_SESSION IS NOT NULL;
```

## Step 5: Find expensive SQL

```sql
SELECT
    SQL_ID,
    EXECUTIONS,
    ROUND(ELAPSED_TIME / 1000000, 2) AS ELAPSED_SEC,
    ROUND(CPU_TIME / 1000000, 2) AS CPU_SEC,
    BUFFER_GETS,
    DISK_READS,
    ROWS_PROCESSED
FROM V$SQL
ORDER BY ELAPSED_TIME DESC
FETCH FIRST 20 ROWS ONLY;
```

## Step 6: Check waits

```sql
SELECT
    EVENT,
    WAIT_CLASS,
    COUNT(*) AS SESSIONS
FROM V$SESSION
WHERE STATUS = 'ACTIVE'
GROUP BY EVENT, WAIT_CLASS
ORDER BY SESSIONS DESC;
```

## Step 7: Check tablespace

```sql
SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES)/1024/1024/1024,2) AS SIZE_GB
FROM DBA_DATA_FILES
GROUP BY TABLESPACE_NAME;
```

## Possible root causes

```text
DB Slowness
 |
 +-- Blocking session
 |
 +-- High CPU
 |
 +-- Expensive SQL
 |
 +-- Full table scan
 |
 +-- Missing/incorrect index
 |
 +-- Stale statistics
 |
 +-- I/O latency
 |
 +-- TEMP pressure
 |
 +-- UNDO pressure
 |
 +-- Lock contention
 |
 +-- Storage issue
 |
 +-- Application issue
```

### Interview answer

> "When the application reports database slowness, I first identify the scope and business impact. Then I check active sessions, wait events, blocking sessions and top SQL. I also check CPU, I/O, TEMP, UNDO and storage. Once I identify the bottleneck, I coordinate with the appropriate application or development team if SQL tuning is required. After remediation, I validate response time and continue monitoring."

---

# 4. Blocking Session

## Scenario

A business transaction is hanging.

## Find blocking sessions

```sql
SELECT
    SID,
    SERIAL#,
    USERNAME,
    STATUS,
    EVENT,
    SQL_ID,
    BLOCKING_SESSION
FROM V$SESSION
WHERE BLOCKING_SESSION IS NOT NULL;
```

## Find blocker and waiter

```sql
SELECT
    s1.SID AS BLOCKER_SID,
    s1.SERIAL# AS BLOCKER_SERIAL,
    s1.USERNAME AS BLOCKER_USER,
    s2.SID AS WAITER_SID,
    s2.SERIAL# AS WAITER_SERIAL,
    s2.USERNAME AS WAITER_USER,
    s2.EVENT,
    s2.SQL_ID
FROM V$SESSION s1
JOIN V$SESSION s2
ON s2.BLOCKING_SESSION = s1.SID;
```

## Check transaction

```sql
SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.SQL_ID,
    t.START_TIME,
    t.USED_UBLK,
    t.USED_UREC
FROM V$TRANSACTION t
JOIN V$SESSION s
ON t.SES_ADDR = s.SADDR
ORDER BY t.USED_UBLK DESC;
```

## DBA action

Do not immediately kill the session.

First determine:

1. Who owns the session?
2. What SQL is running?
3. Is it a batch?
4. Is it an application transaction?
5. How many sessions are blocked?
6. What is the business impact?
7. Is the transaction expected to complete?

If approved:

```sql
ALTER SYSTEM KILL SESSION 'SID,SERIAL#' IMMEDIATE;
```

### Interview answer

> "I first identify the blocker, waiting sessions, SQL_ID and transaction details. I check the business impact and coordinate with the application team. If the blocker is confirmed as the cause and killing the session is approved, I terminate it and verify that waiting sessions recover. I then document the RCA."

---

# 5. ORA-01653 — Unable to Extend Table

## Scenario

Application receives:

```text
ORA-01653: unable to extend table
```

## Check tablespace

```sql
SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES)/1024/1024/1024,2) AS FREE_GB
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME
ORDER BY FREE_GB;
```

## Check datafiles

```sql
SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES/1024/1024/1024,2) AS CURRENT_GB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES/1024/1024/1024,2) AS MAX_GB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = UPPER('&TABLESPACE_NAME');
```

## Check largest segments

```sql
SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES/1024/1024/1024,2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = UPPER('&TABLESPACE_NAME')
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;
```

## If ASM

```sql
SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB
FROM V$ASM_DISKGROUP;
```

## Possible causes

* Tablespace is full
* Datafile reached MAXSIZE
* AUTOEXTEND disabled
* ASM has insufficient capacity
* Filesystem is full
* Unexpected segment growth

### Interview answer

> "For ORA-01653, I first identify the affected tablespace and check free space. Then I check datafile size, autoextend and MAXSIZE. If the database uses ASM, I check ASM usable capacity. I also identify the segment causing rapid growth. Depending on the root cause, I add or resize the datafile, increase capacity, or investigate the application growth."

---

# 6. ORA-01654 — Unable to Extend Index

## Check index

```sql
SELECT
    OWNER,
    INDEX_NAME,
    TABLE_NAME,
    TABLESPACE_NAME,
    STATUS
FROM DBA_INDEXES
WHERE INDEX_NAME = UPPER('&INDEX_NAME');
```

## Check tablespace

```sql
SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES)/1024/1024/1024,2) AS FREE_GB
FROM DBA_FREE_SPACE
WHERE TABLESPACE_NAME = UPPER('&TABLESPACE_NAME')
GROUP BY TABLESPACE_NAME;
```

## Find large indexes

```sql
SELECT
    OWNER,
    SEGMENT_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES/1024/1024/1024,2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE LIKE 'INDEX%'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;
```

### Interview answer

> "ORA-01654 means an index cannot allocate the required extent. I check the index tablespace, free space, datafile capacity, autoextend and ASM capacity. I don't rebuild the index blindly. First I resolve the actual space allocation problem and then investigate whether the index itself has a valid maintenance requirement."

---

# 7. ORA-01652 — TEMP Full

## Check TEMP

```sql
SELECT
    TABLESPACE_NAME,
    ROUND(TABLESPACE_SIZE/1024/1024/1024,2) AS TOTAL_GB,
    ROUND(FREE_SPACE/1024/1024/1024,2) AS FREE_GB
FROM DBA_TEMP_FREE_SPACE;
```

## Find TEMP consumers

```sql
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
```

## Root causes

* Large sort
* Hash join
* Missing/inefficient index
* Large report/query
* Parallel query
* Bad execution plan
* Insufficient TEMP

### Interview answer

> "For ORA-01652, I check TEMP utilization and identify sessions consuming TEMP. I capture SQL_ID and investigate the SQL execution plan. If the workload is legitimate and TEMP capacity is insufficient, I increase TEMP capacity after checking ASM or filesystem capacity."

---

# 8. ORA-30036 — UNDO Full

## Check UNDO

```sql
SELECT
    TABLESPACE_NAME,
    STATUS,
    ROUND(SUM(BYTES)/1024/1024/1024,2) AS SIZE_GB
FROM DBA_UNDO_EXTENTS
GROUP BY TABLESPACE_NAME, STATUS
ORDER BY TABLESPACE_NAME, STATUS;
```

## Check UNDO workload

```sql
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
```

## Find transactions

```sql
SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    t.START_TIME,
    t.USED_UBLK,
    t.USED_UREC
FROM V$TRANSACTION t
JOIN V$SESSION s
ON t.SES_ADDR = s.SADDR
ORDER BY t.USED_UBLK DESC;
```

### Interview answer

> "For ORA-30036, I check UNDO utilization, active transactions, transaction duration and V$UNDOSTAT. I also check whether the UNDO datafile has reached MAXSIZE and whether ASM has sufficient capacity. Then I determine whether the issue is workload-related or storage-related."

---

# 9. ORA-01536 — Quota Exceeded

## Check quota

```sql
SELECT
    USERNAME,
    TABLESPACE_NAME,
    BYTES,
    MAX_BYTES
FROM DBA_TS_QUOTAS
WHERE USERNAME = UPPER('&USERNAME');
```

## Resolution

If approved:

```sql
ALTER USER APPUSER
QUOTA 5G ON APP_DATA;
```

Or:

```sql
ALTER USER APPUSER
QUOTA UNLIMITED ON APP_DATA;
```

### Important

Do not confuse:

```text
ORA-01536
```

with:

```text
ORA-01653
```

### Difference

```text
ORA-01536
    |
    +--> User quota problem

ORA-01653
    |
    +--> Tablespace/datafile allocation problem
```

---

# 10. Tablespace 95% Full

## Scenario

Monitoring reports:

```text
APP_DATA = 95%
```

## Investigation

```sql
SELECT
    df.TABLESPACE_NAME,
    ROUND(SUM(df.BYTES)/1024/1024/1024,2) AS ALLOCATED_GB,
    ROUND(NVL(fs.FREE_BYTES,0)/1024/1024/1024,2) AS FREE_GB
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
```

Then:

```sql
SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES/1024/1024/1024,2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'APP_DATA'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;
```

### Interview answer

> "I don't simply add space because the alert is 95%. I first determine why the tablespace grew. I check segment growth, datafile capacity, autoextend, ASM capacity and recent application activity. If the growth is expected, I provision capacity. If unexpected, I investigate the segment or application causing the growth."

---

# 11. ASM Diskgroup 90% Full

## Check ASM

```sql
SELECT
    NAME,
    STATE,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB,
    OFFLINE_DISKS
FROM V$ASM_DISKGROUP;
```

## Check ASM disks

```sql
SELECT
    GROUP_NUMBER,
    NAME,
    PATH,
    STATE,
    MODE_STATUS,
    HEADER_STATUS,
    TOTAL_MB,
    FREE_MB
FROM V$ASM_DISK
ORDER BY GROUP_NUMBER;
```

## Investigation

```text
ASM 90%+
 |
 +--> Check USABLE_FILE_MB
 |
 +--> Identify affected diskgroup
 |
 +--> Check database datafiles
 |
 +--> Check FRA
 |
 +--> Check TEMP/UNDO
 |
 +--> Check other databases
 |
 +--> Review growth
 |
 +--> Storage expansion if required
```

### Interview answer

> "When ASM reaches a critical threshold, I check diskgroup state, FREE_MB and especially USABLE_FILE_MB. I identify what is consuming the diskgroup, including database files and FRA. I don't blindly enable unlimited autoextend. If capacity is genuinely insufficient, I coordinate storage expansion and monitor ASM rebalance."

---

# 12. Datafile Reached MAXSIZE

## Check

```sql
SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES/1024/1024/1024,2) AS CURRENT_GB,
    ROUND(MAXBYTES/1024/1024/1024,2) AS MAX_GB,
    AUTOEXTENSIBLE
FROM DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'YES'
ORDER BY BYTES DESC;
```

## Possible solution

If ASM/storage has capacity:

```sql
ALTER DATABASE DATAFILE
'<exact_file_name>'
AUTOEXTEND ON
NEXT 1G
MAXSIZE 200G;
```

Or add another datafile where appropriate.

### Interview answer

> "AUTOEXTEND being enabled does not mean the file can grow forever. I check current size against MAXSIZE and also validate ASM or filesystem capacity before increasing the limit."

---

# 13. Datafile Resize Fails — ORA-03297

## Scenario

You try:

```sql
ALTER DATABASE DATAFILE
'<file>'
RESIZE 20G;
```

and receive:

```text
ORA-03297
```

## Meaning

There are allocated extents beyond the requested resize boundary.

## Find highest extents

```sql
SELECT
    FILE_ID,
    MAX(BLOCK_ID + BLOCKS) AS HIGH_WATER_BLOCK
FROM DBA_EXTENTS
WHERE FILE_ID = &FILE_ID
GROUP BY FILE_ID;
```

## Find segments near the end

```sql
SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    BLOCK_ID,
    BLOCKS
FROM DBA_EXTENTS
WHERE FILE_ID = &FILE_ID
ORDER BY BLOCK_ID DESC
FETCH FIRST 20 ROWS ONLY;
```

### Interview answer

> "ORA-03297 means there are used extents beyond the target resize point. I identify the highest allocated extents first. I don't force the resize. If space reclamation is required, I evaluate segment movement or shrink options and then retry the resize after validation."

---

# 14. RMAN Backup Failed

## Scenario

Nightly backup failed.

## Check RMAN backup status

```sql
SELECT
    SESSION_KEY,
    INPUT_TYPE,
    STATUS,
    START_TIME,
    END_TIME
FROM V$RMAN_BACKUP_JOB_DETAILS
ORDER BY START_TIME DESC;
```

## Check backup pieces

```sql
SELECT
    BS_KEY,
    PIECES,
    START_TIME,
    COMPLETION_TIME,
    STATUS,
    DEVICE_TYPE
FROM V$BACKUP_SET
ORDER BY COMPLETION_TIME DESC;
```

## Investigation

```text
RMAN FAILURE
     |
     +--> RMAN log
     |
     +--> ORA error
     |
     +--> FRA/storage
     |
     +--> Archive destination
     |
     +--> Backup destination
     |
     +--> Media Manager
     |
     +--> Permissions
     |
     +--> Network
```

### Common causes

* FRA full
* Backup destination full
* Archive log issue
* RMAN channel failure
* Media manager failure
* Network issue
* Database/file corruption
* Permission problem

### Interview answer

> "I first check the RMAN job status and detailed RMAN log to identify the exact failure. Then I validate FRA, archive logs, backup destination, channels and media manager. I fix the root cause and rerun the required backup. Finally I validate that the backup completed successfully."

---

# 15. Archive Destination Full

## Check archive destinations

```sql
SELECT
    DEST_ID,
    DEST_NAME,
    STATUS,
    TARGET,
    DESTINATION,
    ERROR
FROM V$ARCHIVE_DEST
WHERE STATUS <> 'INACTIVE';
```

## Check FRA

```sql
SELECT
    NAME,
    ROUND(SPACE_LIMIT/1024/1024/1024,2) AS LIMIT_GB,
    ROUND(SPACE_USED/1024/1024/1024,2) AS USED_GB,
    ROUND(SPACE_RECLAIMABLE/1024/1024/1024,2) AS RECLAIMABLE_GB
FROM V$RECOVERY_FILE_DEST;
```

### Interview answer

> "I first identify whether the archive destination or FRA is full and check the exact error. I verify backup status and archive-log retention before removing or reclaiming anything. I never manually delete files from an ASM-managed location."

---

# 16. Listener Is Down

## Check listener

From Linux:

```bash
lsnrctl status
```

```bash
lsnrctl services
```

## Check process/port

```bash
ps -ef | grep tns
```

```bash
ss -lntp | grep 1521
```

## Start listener

```bash
lsnrctl start
```

## Verify

```bash
lsnrctl status
```

### Interview answer

> "I first check listener status, listener log and whether the configured port is listening. I verify listener.ora and service registration. If the listener is down, I start it and verify service registration. If the listener is up but the service is not registered, I investigate LOCAL_LISTENER, service configuration and database status."

---

# 17. ORA-12514

## Error

```text
ORA-12514: TNS:listener does not currently know of service requested
```

## Check

```bash
lsnrctl services
```

## Database services

```sql
SHOW PARAMETER service_names;
```

For RAC:

```bash
srvctl status service -d <db_unique_name>
```

### Possible causes

* Service not registered
* Wrong SERVICE_NAME
* Listener configuration issue
* Database/PDB not open
* LOCAL_LISTENER issue

### Interview answer

> "For ORA-12514, I verify that the requested service exists and is registered with the listener. I check listener services, service_names, database or PDB status, and LOCAL_LISTENER configuration."

---

# 18. ORA-12541

## Error

```text
ORA-12541: TNS:no listener
```

## Check

```bash
lsnrctl status
```

```bash
ss -lntp | grep 1521
```

### Root cause

Usually:

* Listener down
* Wrong host
* Wrong port
* Network/firewall issue
* Incorrect connect descriptor

---

# 19. Data Guard Archive Gap

## Check primary

```sql
SELECT
    DEST_ID,
    STATUS,
    ERROR,
    DESTINATION
FROM V$ARCHIVE_DEST
WHERE TARGET = 'STANDBY';
```

## Standby

```sql
SELECT
    THREAD#,
    LOW_SEQUENCE#,
    HIGH_SEQUENCE#
FROM V$ARCHIVE_GAP;
```

## Check received/applied logs

```sql
SELECT
    THREAD#,
    SEQUENCE#,
    APPLIED,
    COMPLETION_TIME
FROM V$ARCHIVED_LOG
ORDER BY THREAD#, SEQUENCE# DESC
FETCH FIRST 30 ROWS ONLY;
```

### Interview answer

> "For an archive gap, I first identify the missing sequence and thread. Then I verify whether the archive exists on the primary. If required, I transfer the missing archive or use an incremental recovery approach depending on the situation. After resolving the gap, I verify redo apply and transport status."

---

# 20. Data Guard Apply Lag

## Check

```sql
SELECT
    NAME,
    VALUE,
    TIME_COMPUTED
FROM V$DATAGUARD_STATS;
```

## Check managed recovery

```sql
SELECT
    PROCESS,
    STATUS,
    THREAD#,
    SEQUENCE#
FROM V$MANAGED_STANDBY;
```

## Check database role

```sql
SELECT
    DATABASE_ROLE,
    OPEN_MODE,
    PROTECTION_MODE,
    PROTECTION_LEVEL
FROM V$DATABASE;
```

### Possible causes

* Archive transport delay
* Network issue
* High primary redo generation
* Standby I/O bottleneck
* Apply process issue
* Missing archive logs

---

# 21. Data Guard Switchover

## Pre-check

```sql
SELECT
    DATABASE_ROLE,
    OPEN_MODE,
    SWITCHOVER_STATUS
FROM V$DATABASE;
```

## Broker

```bash
dgmgrl /
```

```text
SHOW CONFIGURATION;
SHOW DATABASE VERBOSE '<db_unique_name>';
```

## Switchover

Broker example:

```text
SWITCHOVER TO '<standby_db_unique_name>';
```

## Post-check

```sql
SELECT
    DATABASE_ROLE,
    OPEN_MODE
FROM V$DATABASE;
```

### Interview answer

> "Before switchover, I validate Data Guard transport, apply status, archive gaps, database roles and switchover status. I prefer Broker when it is configured and healthy. After the switchover, I verify the new primary and standby roles, services, redo transport and application connectivity."

---

# 22. Data Guard Failover

## Scenario

Primary database is unavailable and cannot be recovered within the required business time.

## Steps

```text
PRIMARY FAILURE
      |
      v
Assess outage
      |
      v
Check standby health
      |
      v
Confirm redo/apply status
      |
      v
Business approval
      |
      v
FAILOVER
      |
      v
Open standby as primary
      |
      v
Validate services
      |
      v
Validate application
      |
      v
Rebuild/reinstate old primary
```

### Interview answer

> "Failover is different from switchover because it is performed when the primary is unavailable or cannot continue serving the business. I verify standby readiness, determine the data-loss exposure, obtain the required business approval, perform failover using the approved Data Guard procedure, and validate application connectivity afterward."

---

# 23. Data Guard Broker Shows WARNING

## Check

```text
DGMGRL> SHOW CONFIGURATION;
```

Then:

```text
DGMGRL> SHOW DATABASE VERBOSE '<database>';
```

Look for:

* ORA errors
* Transport errors
* Apply errors
* Missing standby redo logs
* Listener/connectivity problems
* Configuration mismatch

### Interview answer

> "I don't ignore a Broker warning. I drill down from SHOW CONFIGURATION to SHOW DATABASE VERBOSE and identify the exact ORA error. Then I correct the underlying Data Guard issue and recheck the configuration."

---

# 24. RAC Instance Down

## Check

```bash
srvctl status database -d <db_unique_name>
```

```bash
srvctl status instance -d <db_unique_name>
```

## Check CRS

```bash
crsctl status resource -t
```

## Check cluster

```bash
crsctl check cluster
```

### Interview answer

> "For a RAC instance issue, I check database and instance status using SRVCTL and cluster resources using CRSCTL. I review the alert log and clusterware logs to determine whether the problem is database, instance, ASM, listener, node or cluster-related."

---

# 25. RAC Service Not Running

## Check

```bash
srvctl status service -d <db_unique_name>
```

## Configuration

```bash
srvctl config service -d <db_unique_name>
```

## Start

```bash
srvctl start service -d <db_unique_name> -s <service_name>
```

## Verify

```bash
srvctl status service -d <db_unique_name>
```

---

# 26. ASM Disk Failure

## Check

```sql
SELECT
    GROUP_NUMBER,
    NAME,
    PATH,
    STATE,
    MODE_STATUS,
    HEADER_STATUS
FROM V$ASM_DISK
ORDER BY GROUP_NUMBER;
```

## Diskgroup

```sql
SELECT
    NAME,
    STATE,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB,
    OFFLINE_DISKS
FROM V$ASM_DISKGROUP;
```

### Interview answer

> "I first identify the affected disk and diskgroup and determine the ASM redundancy type. I check whether the disk is offline, missing or failed and whether the diskgroup remains healthy. I coordinate with the storage team and follow the approved ASM disk replacement or drop/add procedure."

---

# 27. ASM Rebalance Running

## Check

```sql
SELECT
    GROUP_NUMBER,
    OPERATION,
    STATE,
    POWER,
    SOFAR,
    EST_WORK,
    EST_MINUTES
FROM V$ASM_OPERATION;
```

### Interview answer

> "When an ASM rebalance is running, I monitor V$ASM_OPERATION and assess its impact on production I/O. I avoid unnecessary concurrent storage operations and monitor completion and diskgroup health."

---

# 28. User Cannot Connect

## Check database

```sql
SELECT
    STATUS,
    ACCOUNT_STATUS
FROM DBA_USERS
WHERE USERNAME = UPPER('&USERNAME');
```

## Check privilege

```sql
SELECT
    GRANTEE,
    PRIVILEGE
FROM DBA_SYS_PRIVS
WHERE GRANTEE = UPPER('&USERNAME');
```

## Check roles

```sql
SELECT
    GRANTEE,
    GRANTED_ROLE
FROM DBA_ROLE_PRIVS
WHERE GRANTEE = UPPER('&USERNAME');
```

## Check quota

```sql
SELECT
    USERNAME,
    TABLESPACE_NAME,
    BYTES,
    MAX_BYTES
FROM DBA_TS_QUOTAS
WHERE USERNAME = UPPER('&USERNAME');
```

### Possible causes

* Account locked
* Password expired
* Invalid password
* Listener problem
* Service unavailable
* Wrong connect descriptor
* Database/PDB unavailable

---

# 29. User Cannot Create Table

## Check privilege

```sql
SELECT
    PRIVILEGE
FROM DBA_SYS_PRIVS
WHERE GRANTEE = UPPER('&USERNAME')
AND PRIVILEGE = 'CREATE TABLE';
```

## Check quota

```sql
SELECT
    USERNAME,
    TABLESPACE_NAME,
    BYTES,
    MAX_BYTES
FROM DBA_TS_QUOTAS
WHERE USERNAME = UPPER('&USERNAME');
```

### Important

The user needs:

```text
CREATE TABLE privilege
        +
Tablespace quota
        +
Available tablespace space
```

---

# 30. Schema Refresh Using Data Pump

## Export

```bash
expdp system/<password> \
schemas=APPUSER \
directory=DP_DIR \
dumpfile=appuser.dmp \
logfile=appuser_exp.log
```

## Import

```bash
impdp system/<password> \
directory=DP_DIR \
dumpfile=appuser.dmp \
logfile=appuser_imp.log \
remap_schema=APPUSER:APPUSER_TEST
```

## Monitor

```sql
SELECT
    SID,
    SERIAL#,
    OPNAME,
    SOFAR,
    TOTALWORK,
    ROUND(SOFAR/TOTALWORK*100,2) AS PCT
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE 'SYS_IMPORT%'
OR OPNAME LIKE 'SYS_EXPORT%';
```

### Interview answer

> "For a schema refresh, I first validate source and target compatibility, storage, users, tablespaces and directory objects. I take the Data Pump export, transfer or make the dump available on the target, perform the import with the required remapping or transformation, monitor the job and validate object counts, invalid objects and application connectivity."

---

# 31. Database Refresh Using RMAN

## High-level flow

```text
SOURCE DATABASE
      |
      v
RMAN BACKUP
      |
      v
BACKUP TRANSFER
      |
      v
TARGET SERVER
      |
      v
RMAN RESTORE
      |
      v
RECOVER
      |
      v
OPEN RESETLOGS
      |
      v
VALIDATE DATABASE
```

### Interview answer

> "For a database refresh, I confirm source and target requirements, take or use an appropriate RMAN backup, restore the database on the target, recover it using the required archived logs, rename or relocate files if necessary, open it according to the refresh requirement and perform post-refresh validation."

---

# 32. Index Rebuild Requirement

## Check status

```sql
SELECT
    OWNER,
    INDEX_NAME,
    TABLE_NAME,
    STATUS
FROM DBA_INDEXES
WHERE STATUS <> 'VALID';
```

### Interview answer

> "I don't rebuild indexes simply because they are old or large. First I determine the actual issue. I check index status, segment growth, execution plans and application behavior. If there is a valid reason for rebuild or online maintenance, I perform it under change control."

---

# 33. Database Patch Using OPatch

## Check Oracle version

```bash
$ORACLE_HOME/OPatch/opatch lsinventory
```

## Check OPatch version

```bash
$ORACLE_HOME/OPatch/opatch version
```

## Conflict check

```bash
$ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -phBaseDir <PATCH_DIR>
```

### High-level production flow

```text
PATCH PLAN
    |
    v
Backup / rollback plan
    |
    v
Pre-check
    |
    v
Non-production validation
    |
    v
Conflict check
    |
    v
Apply patch
    |
    v
Datapatch
    |
    v
Post-check
    |
    v
Application validation
```

---

# 34. OPatch vs OPatchAuto

## OPatch

Used for patching Oracle software homes manually.

## OPatchAuto

Used in supported Oracle Grid Infrastructure / RAC patching workflows to coordinate patching across relevant GI/database components.

### Interview answer

> "OPatch is the standard Oracle patching utility for Oracle homes. OPatchAuto automates supported patching workflows, particularly in Grid Infrastructure environments, and helps coordinate the required components."

---

# 35. PSU/RU Patching

## Pre-check

```bash
opatch lsinventory
```

Check:

* Database version
* GI version
* OPatch version
* Disk space
* Backup
* Cluster status
* Data Guard status
* Application dependency
* Patch conflict

## Post-check

```bash
opatch lsinventory
```

Then:

```sql
SELECT
    PATCH_ID,
    ACTION,
    STATUS,
    ACTION_TIME
FROM DBA_REGISTRY_SQLPATCH
ORDER BY ACTION_TIME DESC;
```

---

# 36. Oracle Upgrade 12c to 19c

## Typical approach

```text
SOURCE 12c
    |
    v
Pre-upgrade checks
    |
    v
Backup
    |
    v
19c Oracle Home
    |
    v
AutoUpgrade
    |
    v
Upgrade
    |
    v
Post-upgrade checks
    |
    v
Application validation
```

## Check invalid objects

```sql
SELECT
    OWNER,
    OBJECT_TYPE,
    COUNT(*)
FROM DBA_OBJECTS
WHERE STATUS <> 'VALID'
GROUP BY OWNER, OBJECT_TYPE
ORDER BY OWNER, OBJECT_TYPE;
```

### Interview answer

> "For a 12c to 19c upgrade, I start with compatibility and pre-upgrade checks, validate backups and application dependencies, prepare the 19c Oracle Home, execute the approved upgrade method such as AutoUpgrade, and then perform post-upgrade validation including database status, components, invalid objects, SQL behavior and application connectivity."

---

# 37. ORA-01078

## Error

```text
ORA-01078: failure in processing system parameters
```

## Check

```bash
echo $ORACLE_SID
echo $ORACLE_HOME
```

```sql
SHOW PARAMETER spfile;
```

## Check parameter files

```bash
ls -l $ORACLE_HOME/dbs/
```

### Possible causes

* Incorrect ORACLE_SID
* Missing parameter file
* Wrong SPFILE location
* Incorrect startup configuration

---

# 38. ORA-00205 — Error Identifying Control File

## Check

```sql
SHOW PARAMETER control_files;
```

From OS:

```bash
ls -l <control_file_path>
```

### Interview answer

> "I check the CONTROL_FILES parameter and verify that the specified files exist and are accessible. I also review the alert log for the exact reason and validate the storage path or ASM diskgroup before taking recovery action."

---

# 39. ORA-10458 — Standby Requires Recovery

## Check

```sql
SELECT
    DATABASE_ROLE,
    OPEN_MODE
FROM V$DATABASE;
```

### Typical situation

Standby was opened incorrectly or requires recovery.

### Interview answer

> "I first confirm the database role and open mode. I check managed recovery and apply status, then resume the appropriate recovery process according to the Data Guard configuration. I validate redo apply afterward."

---

# 40. ORA-16789 — Missing Standby Redo Logs

## Check

```sql
SELECT
    GROUP#,
    THREAD#,
    SEQUENCE#,
    BYTES,
    STATUS
FROM V$STANDBY_LOG
ORDER BY THREAD#, GROUP#;
```

### Rule of thumb

For each primary redo thread, configure an appropriate number and size of standby redo logs according to the Data Guard design.

### Interview answer

> "ORA-16789 indicates that the standby redo log configuration does not satisfy the Broker's requirements. I check V$STANDBY_LOG, compare the configuration with the primary redo threads and add appropriately sized standby redo logs according to the environment design."

---

# 41. Controlfile Lost

## Check

```sql
SHOW PARAMETER control_files;
```

### Recovery approach

```text
CONTROLFILE LOSS
       |
       v
Check multiplexed copies
       |
       +---- Available?
       |       |
       |       v
       |   Replace/reconfigure
       |
       v
No usable copy
       |
       v
Restore/recreate using approved recovery procedure
       |
       v
Validate database
```

---

# 42. Redo Log Group Issue

## Check

```sql
SELECT
    GROUP#,
    THREAD#,
    SEQUENCE#,
    BYTES,
    MEMBERS,
    STATUS
FROM V$LOG
ORDER BY GROUP#;
```

## Members

```sql
SELECT
    GROUP#,
    MEMBER,
    STATUS
FROM V$LOGFILE
ORDER BY GROUP#;
```

### Interview answer

> "I first determine whether the issue affects an active, current or inactive redo group and whether multiplexed members are available. I never remove an active/current group without validating the database state and following the correct redo-log maintenance procedure."

---

# 43. Archive Log Sequence Missing

## Check

```sql
SELECT
    THREAD#,
    SEQUENCE#,
    FIRST_TIME,
    NEXT_TIME,
    APPLIED
FROM V$ARCHIVED_LOG
ORDER BY THREAD#, SEQUENCE# DESC;
```

For Data Guard:

```sql
SELECT *
FROM V$ARCHIVE_GAP;
```

### Action

* Identify missing sequence
* Verify source archive exists
* Transfer/register if required
* Recover/apply
* Validate gap cleared

---

# 44. Database Mounts but Does Not Open

## Check

```sql
SELECT
    STATUS
FROM V$INSTANCE;
```

```sql
SELECT
    OPEN_MODE,
    DATABASE_ROLE
FROM V$DATABASE;
```

## Check alert log

```bash
tail -100 $ORACLE_BASE/diag/rdbms/*/*/trace/alert_*.log
```

### Possible causes

* Datafile issue
* Redo issue
* Controlfile issue
* Recovery required
* Parameter issue
* Corruption

### Interview answer

> "I don't force OPEN. I first check the alert log and database state to determine why OPEN is failing. Then I identify whether recovery, media repair or parameter correction is required."

---

# 45. Database Startup Failure

## Check environment

```bash
echo $ORACLE_SID
echo $ORACLE_HOME
which sqlplus
```

## Connect

```bash
sqlplus / as sysdba
```

## Startup

```sql
STARTUP;
```

If failure occurs, inspect:

* ORA error
* alert log
* SPFILE/PFILE
* control files
* redo logs
* datafiles
* ASM
* filesystem

---

# 46. Filesystem Full

## Linux

```bash
df -h
```

```bash
df -i
```

## Largest directories

```bash
du -sh /u01/* 2>/dev/null
```

### Important

Do not delete Oracle files blindly.

Check:

* Alert logs
* Trace files
* Listener logs
* Audit files
* Diagnostic files
* Old application files
* Backup files

### Interview answer

> "I first identify which filesystem is full and whether the issue is blocks or inodes. I determine what is consuming space before deleting anything. Oracle-managed files and recovery files are handled through Oracle-supported procedures rather than arbitrary OS deletion."

---

# 47. ASM vs Filesystem Full

```text
STORAGE ISSUE
     |
     +------------------+
     |                  |
     v                  v
FILESYSTEM            ASM
     |                  |
df -h                 V$ASM_DISKGROUP
     |                  |
du -sh                USABLE_FILE_MB
     |                  |
OS files              ASM files
```

---

# 48. User Account Locked

## Check

```sql
SELECT
    USERNAME,
    ACCOUNT_STATUS,
    LOCK_DATE
FROM DBA_USERS
WHERE USERNAME = UPPER('&USERNAME');
```

## Unlock

After authorization:

```sql
ALTER USER APPUSER ACCOUNT UNLOCK;
```

---

# 49. Password Expired

## Check

```sql
SELECT
    USERNAME,
    ACCOUNT_STATUS,
    EXPIRY_DATE,
    PROFILE
FROM DBA_USERS
WHERE USERNAME = UPPER('&USERNAME');
```

### Interview answer

> "I verify the account status and profile before changing anything. If the password has expired, I follow the approved password-reset process and validate application connectivity."

---

# 50. Invalid Objects After Deployment

## Check

```sql
SELECT
    OWNER,
    OBJECT_NAME,
    OBJECT_TYPE
FROM DBA_OBJECTS
WHERE STATUS = 'INVALID'
ORDER BY OWNER, OBJECT_TYPE;
```

## Recompile schema

Where approved:

```sql
EXEC DBMS_UTILITY.COMPILE_SCHEMA(
    schema => 'APPUSER'
);
```

## Verify

```sql
SELECT
    OWNER,
    OBJECT_TYPE,
    COUNT(*)
FROM DBA_OBJECTS
WHERE STATUS = 'INVALID'
GROUP BY OWNER, OBJECT_TYPE;
```

---

# 51. Statistics Are Stale

## Check

```sql
SELECT
    OWNER,
    TABLE_NAME,
    NUM_ROWS,
    LAST_ANALYZED,
    STALE_STATS
FROM DBA_TAB_STATISTICS
WHERE OWNER = UPPER('&OWNER')
AND STALE_STATS = 'YES';
```

### Interview answer

> "I check whether stale statistics are actually contributing to the performance problem. I review SQL plans and workload before gathering statistics. I don't gather statistics blindly on every object during a production incident."

---

# 52. High CPU

## Check

```sql
SELECT
    SQL_ID,
    EXECUTIONS,
    CPU_TIME,
    ELAPSED_TIME,
    BUFFER_GETS
FROM V$SQL
ORDER BY CPU_TIME DESC
FETCH FIRST 20 ROWS ONLY;
```

## Active sessions

```sql
SELECT
    SID,
    SERIAL#,
    USERNAME,
    SQL_ID,
    EVENT,
    CPU_TIME
FROM V$SESSION
WHERE STATUS = 'ACTIVE';
```

### Investigation

```text
HIGH CPU
   |
   v
Find top SQL
   |
   v
Check execution plan
   |
   v
Check executions
   |
   v
Check application change
   |
   +--> SQL tuning
   +--> Plan issue
   +--> Statistics
   +--> Excessive workload
```

---

# 53. Long-Running SQL

## Check

```sql
SELECT
    SID,
    SERIAL#,
    USERNAME,
    SQL_ID,
    EVENT,
    LAST_CALL_ET,
    STATUS
FROM V$SESSION
WHERE STATUS = 'ACTIVE'
ORDER BY LAST_CALL_ET DESC;
```

### Interview answer

> "I identify the SQL_ID and session, check elapsed time, wait event, execution plan and business impact. I determine whether it is legitimately long-running or abnormal before taking action."

---

# 54. Execution Plan Changed Suddenly

## Investigation

Check:

```sql
SELECT
    SQL_ID,
    CHILD_NUMBER,
    PLAN_HASH_VALUE,
    EXECUTIONS,
    ELAPSED_TIME,
    CPU_TIME,
    BUFFER_GETS
FROM V$SQL
WHERE SQL_ID = '&SQL_ID'
ORDER BY CHILD_NUMBER;
```

Possible reasons:

* Statistics changed
* Different bind values
* Different execution plan
* Object changes
* Index changes
* Data distribution changed
* Optimizer environment changed

### Interview answer

> "I compare the current and previous execution plans and plan hash values. Then I investigate statistics, bind behavior, object changes and optimizer conditions before recommending a fix."

---

# 55. Database Alert Log Shows ORA Error

## Check alert log

```bash
tail -100 alert_<SID>.log
```

Modern diagnostic location can be identified using:

```sql
SELECT
    VALUE
FROM V$DIAG_INFO
WHERE NAME = 'Diag Trace';
```

### Interview approach

```text
ORA ERROR
   |
   v
Capture exact error
   |
   v
Check alert log
   |
   v
Check trace
   |
   v
Identify component
   |
   v
Root cause
   |
   v
Corrective action
   |
   v
Validation
```

---

# 56. Database Connection Suddenly Fails

Check in this order:

```text
Client
  |
  v
DNS / Host
  |
  v
Network
  |
  v
Listener
  |
  v
Service
  |
  v
Database
  |
  v
User
```

Commands:

```bash
tnsping <service>
```

```bash
lsnrctl status
```

```bash
lsnrctl services
```

Then database:

```sql
SELECT
    STATUS,
    INSTANCE_NAME
FROM V$INSTANCE;
```

---

# 57. Application Reports ORA-01555

## Error

```text
ORA-01555: snapshot too old
```

## Check UNDO

```sql
SELECT
    BEGIN_TIME,
    UNDOBLKS,
    TXNCOUNT,
    MAXQUERYLEN,
    SSOLDERRCNT,
    TUNED_UNDORETENTION
FROM V$UNDOSTAT
ORDER BY BEGIN_TIME DESC
FETCH FIRST 24 ROWS ONLY;
```

### Investigation

* Long-running query
* Heavy DML
* Insufficient UNDO
* Undo retention
* Workload spike

### Interview answer

> "I investigate the long-running query and UNDO workload first. I review V$UNDOSTAT for snapshot-too-old errors and query duration, then determine whether UNDO sizing or workload optimization is required."

---

# 58. Database Hangs

## First response

```text
DATABASE HANG
      |
      v
Check availability
      |
      v
Active sessions
      |
      v
Blocking
      |
      v
Wait events
      |
      v
CPU
      |
      v
I/O
      |
      v
Locks
      |
      v
Top SQL
      |
      v
Alert log
```

### Important

Do not restart the database immediately.

First collect evidence.

---

# 59. Production Database Restart Required

## Pre-check

```sql
SELECT
    NAME,
    OPEN_MODE,
    DATABASE_ROLE
FROM V$DATABASE;
```

```sql
SELECT
    INSTANCE_NAME,
    STATUS
FROM V$INSTANCE;
```

Check:

* Active sessions
* Batch jobs
* Data Guard
* RAC
* Application dependency
* Backup
* Change approval

## Restart

```sql
SHUTDOWN IMMEDIATE;

STARTUP;
```

## Post-check

```sql
SELECT
    NAME,
    OPEN_MODE,
    DATABASE_ROLE
FROM V$DATABASE;
```

Then validate:

* Listener
* Services
* Application
* Data Guard
* Jobs
* Invalid objects

---

# 60. Real-Time Incident — Application Deployment Caused Errors

## Scenario

Application team deployed a new release and database errors started immediately.

## DBA approach

```text
DEPLOYMENT
    |
    v
Error begins
    |
    v
Compare timestamp
    |
    v
Check SQL_ID / errors
    |
    v
Check invalid objects
    |
    v
Check execution plans
    |
    v
Check locks
    |
    v
Check database changes
    |
    v
Coordinate with application team
```

### Interview answer

> "I correlate the incident start time with the application deployment. I capture the database errors, SQL_IDs and affected objects, then compare database behavior before and after deployment. I work with the application team to determine whether rollback, SQL correction or database remediation is required."

---

# 61. Real-Time Incident — Tablespace Growing Rapidly

## Investigation

```sql
SELECT
    OWNER,
    SEGMENT_NAME,
    SEGMENT_TYPE,
    TABLESPACE_NAME,
    ROUND(BYTES/1024/1024/1024,2) AS SIZE_GB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'APP_DATA'
ORDER BY BYTES DESC
FETCH FIRST 20 ROWS ONLY;
```

Then investigate:

* Table growth
* LOB growth
* Index growth
* Partition growth
* Temporary staging objects
* Application batch

### RCA

> "The tablespace itself is only the symptom. I identify the object responsible for the growth and determine whether the growth is expected."

---

# 62. Real-Time Incident — Mass DELETE but Tablespace Did Not Shrink

## Explanation

```text
DELETE
  |
  v
Rows removed
  |
  v
Space becomes reusable
  |
  v
Segment allocation may remain
  |
  v
Tablespace does not automatically shrink
```

Possible maintenance:

* SHRINK
* MOVE
* Tablespace reorganization

Only after validating requirements and dependencies.

---

# 63. RMAN Restore Required

## High-level approach

```text
Identify failure
      |
      v
Determine recovery objective
      |
      v
Check backup availability
      |
      v
Validate backup
      |
      v
Restore
      |
      v
Recover
      |
      v
Open
      |
      v
Validate
```

### Interview answer

> "I first determine whether the requirement is a complete restore, datafile recovery, point-in-time recovery or block recovery. Then I verify the required RMAN backups and archived logs, restore and recover according to the recovery objective, and perform post-recovery validation."

---

# 64. RMAN Backup Validation

```rman
RESTORE DATABASE VALIDATE;
```

Or appropriate validation commands based on the recovery requirement.

### Purpose

Checks whether RMAN can read and validate required backup pieces/data.

---

# 65. Data Pump Job Is Slow

## Check

```sql
SELECT
    SID,
    SERIAL#,
    OPNAME,
    SOFAR,
    TOTALWORK,
    ROUND(SOFAR/TOTALWORK*100,2) AS PCT
FROM V$SESSION_LONGOPS
WHERE TOTALWORK > 0
ORDER BY START_TIME DESC;
```

Investigate:

* Object count
* Large tables
* LOBs
* Index creation
* Network
* Disk I/O
* Parallelism
* Target storage

---

# 66. PDB Is Not Open

## Check

```sql
SELECT
    CON_ID,
    NAME,
    OPEN_MODE
FROM V$PDBS
ORDER BY CON_ID;
```

## Open

From CDB:

```sql
ALTER PLUGGABLE DATABASE <PDB_NAME> OPEN;
```

For persistent state:

```sql
ALTER PLUGGABLE DATABASE <PDB_NAME>
SAVE STATE;
```

### Interview answer

> "I check the PDB open mode and alert log first. If the PDB is mounted and there is no underlying error, I open it and save its state if the requirement is for it to automatically open after restart."

---

# 67. CDB vs PDB

```text
                CDB
                 |
       +---------+---------+
       |                   |
      CDB$ROOT            PDB
                           |
                       Application
```

### Interview answer

> "A Container Database contains the root container and one or more Pluggable Databases. PDBs provide logical isolation while sharing the Oracle instance and common infrastructure of the CDB."

---

# 68. RAC vs Standalone

| Feature      | Standalone        | RAC                             |
| ------------ | ----------------- | ------------------------------- |
| Instances    | One               | Multiple                        |
| Database     | One               | One shared database             |
| Availability | Server dependent  | Multiple instances              |
| Clusterware  | Not required      | Required                        |
| ASM          | Optional          | Commonly used                   |
| Services     | Database services | Cluster services                |
| Patching     | Individual        | Rolling options where supported |

### Interview answer

> "In RAC, multiple instances access the same database and provide high availability and workload distribution. Clusterware manages cluster resources, while SRVCTL is commonly used for RAC database, instance and service administration."

---

# 69. RMAN vs Data Pump

| RMAN                       | Data Pump                   |
| -------------------------- | --------------------------- |
| Physical backup            | Logical export/import       |
| Database/datafile recovery | Object/schema movement      |
| Disaster recovery          | Refresh/migration           |
| PITR                       | Schema/table-level movement |
| Backup/recovery            | Logical migration           |

### Interview answer

> "RMAN is primarily a physical backup and recovery technology, while Data Pump is a logical export/import technology. I choose based on whether the requirement is recovery or logical object movement."

---

# 70. Physical vs Logical Backup

```text
BACKUP
 |
 +---- Physical
 |       |
 |       +--> RMAN
 |
 +---- Logical
         |
         +--> Data Pump
```

---

# 71. Switchover vs Failover

| Switchover                             | Failover                                                  |
| -------------------------------------- | --------------------------------------------------------- |
| Planned                                | Usually unplanned                                         |
| Primary available                      | Primary unavailable/unsuitable                            |
| Controlled role reversal               | Emergency role transition                                 |
| Minimal/no data loss when synchronized | Potential data loss depending on protection/configuration |
| Used for maintenance/DR testing        | Used for disaster                                         |

---

# 72. RAC SRVCTL vs CRSCTL

## SRVCTL

Used for Oracle resources such as:

```text
Database
Instance
Service
Listener
ASM
```

## CRSCTL

Used for clusterware/resource-level administration and diagnostics.

### Interview answer

> "I use SRVCTL for Oracle RAC resource management such as database, instance and services. CRSCTL is used for Clusterware-level resource and cluster administration."

---

# 73. OEM Monitoring Scenario

## Scenario

OEM raises:

```text
Tablespace 90%
```

### DBA response

```text
OEM Alert
   |
   v
Validate in SQL
   |
   v
Check actual usage
   |
   v
Check datafile capacity
   |
   v
Check ASM
   |
   v
Find growth
   |
   v
Take action
   |
   v
Verify
   |
   v
Close alert
```

### Interview answer

> "I always validate monitoring alerts directly from the database before taking action. I identify whether the alert is a genuine capacity issue, then investigate the growth and resolve it according to the approved procedure."

---

# 74. ServiceNow Production Incident

## Scenario

Application team creates an incident:

> "Production database error."

### DBA process

```text
ServiceNow Incident
        |
        v
Understand impact
        |
        v
Check DB
        |
        v
Collect evidence
        |
        v
Identify RCA
        |
        v
Fix
        |
        v
Validate
        |
        v
Update ticket
        |
        v
Closure
```

### Ticket update should include

```text
Issue:
Root Cause:
Impact:
Investigation:
Action Taken:
Validation:
Downtime:
Preventive Action:
```

---

# 75. Production Change Example — Add Datafile

## Change request

```text
Tablespace APP_DATA reached 92%.
```

## Pre-check

```sql
SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES/1024/1024/1024,2) AS SIZE_GB,
    AUTOEXTENSIBLE,
    ROUND(MAXBYTES/1024/1024/1024,2) AS MAX_GB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'APP_DATA';
```

ASM:

```sql
SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB
FROM V$ASM_DISKGROUP
WHERE NAME = 'DATA';
```

## Change

```sql
ALTER TABLESPACE APP_DATA
ADD DATAFILE '+DATA'
SIZE 20G
AUTOEXTEND ON
NEXT 1G
MAXSIZE 100G;
```

## Post-check

```sql
SELECT
    FILE_ID,
    FILE_NAME,
    TABLESPACE_NAME,
    ROUND(BYTES/1024/1024/1024,2) AS SIZE_GB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME = 'APP_DATA';
```

---

# 76. Production Change — Resize Datafile

## Pre-check

```sql
SELECT
    FILE_ID,
    FILE_NAME,
    BYTES,
    AUTOEXTENSIBLE,
    MAXBYTES
FROM DBA_DATA_FILES
WHERE FILE_ID = &FILE_ID;
```

## Change

```sql
ALTER DATABASE DATAFILE
'<exact_file_name>'
RESIZE 50G;
```

## Post-check

```sql
SELECT
    FILE_NAME,
    ROUND(BYTES/1024/1024/1024,2) AS SIZE_GB
FROM DBA_DATA_FILES
WHERE FILE_ID = &FILE_ID;
```

---

# 77. Production Patch Failure

## Scenario

Patch fails halfway.

### DBA response

```text
PATCH FAILURE
      |
      v
STOP further changes
      |
      v
Capture OPatch logs
      |
      v
Check inventory
      |
      v
Check patch status
      |
      v
Determine rollback/recovery plan
      |
      v
Follow Oracle-supported procedure
      |
      v
Validate Oracle Home
      |
      v
Validate database
```

### Interview answer

> "I would not continue applying commands blindly. I capture the OPatch logs, inventory and exact error, determine whether the Oracle Home is in a consistent state, and follow the approved rollback or recovery procedure. Afterward I validate the inventory and database SQL patch status."

---

# 78. Production Data Guard Transport Error

## Check

```sql
SELECT
    DEST_ID,
    STATUS,
    ERROR,
    DESTINATION
FROM V$ARCHIVE_DEST
WHERE TARGET = 'STANDBY';
```

Check Broker:

```text
DGMGRL> SHOW CONFIGURATION;
```

Then:

```text
DGMGRL> SHOW DATABASE VERBOSE '<standby>';
```

### Investigation

* Listener
* Network
* TNS
* Service
* Password file
* Archive destination
* Standby state
* Diskgroup/filesystem
* Archive sequence

---

# 79. Production Incident — Database Is Available but Application Cannot Connect

## Investigation

```text
DATABASE UP
    |
    v
Listener?
    |
    v
Service registered?
    |
    v
PDB open?
    |
    v
Network?
    |
    v
TNS?
    |
    v
User account?
    |
    v
Application connection pool?
```

### Interview answer

> "A database being OPEN does not guarantee application connectivity. I verify the listener, service registration, PDB state, network connectivity, connect descriptor and user account before concluding that the database itself is the problem."

---

# 80. Production Incident — Application Cannot Create Object

Check:

```sql
SELECT
    USERNAME,
    DEFAULT_TABLESPACE
FROM DBA_USERS
WHERE USERNAME = UPPER('&USERNAME');
```

Privilege:

```sql
SELECT
    PRIVILEGE
FROM DBA_SYS_PRIVS
WHERE GRANTEE = UPPER('&USERNAME');
```

Quota:

```sql
SELECT
    USERNAME,
    TABLESPACE_NAME,
    BYTES,
    MAX_BYTES
FROM DBA_TS_QUOTAS
WHERE USERNAME = UPPER('&USERNAME');
```

Tablespace:

```sql
SELECT
    TABLESPACE_NAME,
    STATUS
FROM DBA_TABLESPACES
WHERE TABLESPACE_NAME = UPPER('&TABLESPACE_NAME');
```

---

# 81. How I Handle a Production Incident

A strong 5–7 year DBA answer:

> "My first priority is business impact and service availability. I acknowledge the incident, understand the exact symptoms and affected users, and start collecting evidence. I check database availability, sessions, waits, blocking, storage, listener, application connectivity and alert logs depending on the issue. I avoid risky changes until I identify the root cause. Once the corrective action is approved, I execute it, validate the database and application, monitor the environment, and document the RCA and preventive actions."

---

# 82. RCA Template

```text
=========================================================
PRODUCTION INCIDENT RCA
=========================================================

Incident:
---------------------------------------------------------
Application reported database slowness.

Business Impact:
---------------------------------------------------------
Application response time increased.

Start Time:
---------------------------------------------------------
<DATE/TIME>

End Time:
---------------------------------------------------------
<DATE/TIME>

Root Cause:
---------------------------------------------------------
<ROOT CAUSE>

Technical Investigation:
---------------------------------------------------------
1. Checked database availability.
2. Checked active sessions.
3. Identified blocking session.
4. Captured SQL_ID.
5. Reviewed transaction information.
6. Confirmed blocking transaction.

Corrective Action:
---------------------------------------------------------
<Action>

Validation:
---------------------------------------------------------
Application connectivity validated.
Database performance returned to normal.

Preventive Action:
---------------------------------------------------------
<Query/application/process improvement>

=========================================================
```

---

# 83. DBA Troubleshooting Master Flow

```text
                         INCIDENT
                            |
                            v
                    BUSINESS IMPACT
                            |
                            v
                    DATABASE AVAILABLE?
                       /          \
                     NO            YES
                     |              |
                     v              v
               DB / INSTANCE    PERFORMANCE?
                  CHECK             |
                                    v
                              SESSIONS / WAITS
                                    |
                  +-----------------+----------------+
                  |                 |                |
                  v                 v                v
               BLOCKING          CPU              I/O
                  |                 |                |
                  +-----------------+----------------+
                                    |
                                    v
                                TOP SQL
                                    |
                                    v
                              STORAGE CHECK
                                    |
                   +----------------+----------------+
                   |                |               |
                   v                v               v
               TABLESPACE         TEMP            UNDO
                   |                |               |
                   v                v               v
                 ASM            TEMP SQL         TRANSACTIONS
                   |
                   v
                  RCA
                   |
                   v
                ACTION
                   |
                   v
               VALIDATION
                   |
                   v
                MONITOR
                   |
                   v
                 RCA
```

---

# 84. Top 25 Interview Questions — Short Answers

## Q1. How do you troubleshoot database slowness?

> Check scope, active sessions, waits, blocking, CPU, I/O, top SQL, locks, TEMP, UNDO and storage.

## Q2. ORA-01653?

> Tablespace segment cannot allocate required extent. Check free space, datafiles, MAXSIZE, AUTOEXTEND and ASM.

## Q3. ORA-01652?

> TEMP segment cannot extend. Check TEMP usage and SQL/session consuming TEMP.

## Q4. ORA-30036?

> UNDO cannot extend. Check UNDO, transactions, retention and ASM/storage capacity.

## Q5. ORA-01536?

> User quota exceeded.

## Q6. How do you troubleshoot ASM?

> Check V$ASM_DISKGROUP, V$ASM_DISK and V$ASM_OPERATION.

## Q7. FREE_MB vs USABLE_FILE_MB?

> USABLE_FILE_MB considers ASM redundancy and is important for determining usable file capacity.

## Q8. What is ASM?

> Oracle storage management technology providing disk pooling, striping, mirroring and rebalancing.

## Q9. RMAN vs Data Pump?

> RMAN is physical backup/recovery; Data Pump is logical export/import.

## Q10. Switchover vs failover?

> Switchover is planned; failover is generally used when the primary is unavailable.

## Q11. How do you check Data Guard lag?

```sql
SELECT *
FROM V$DATAGUARD_STATS;
```

## Q12. How do you check archive gap?

```sql
SELECT *
FROM V$ARCHIVE_GAP;
```

## Q13. How do you check RAC instance status?

```bash
srvctl status instance -d <db_unique_name>
```

## Q14. How do you check cluster resources?

```bash
crsctl status resource -t
```

## Q15. How do you check listener?

```bash
lsnrctl status
```

## Q16. ORA-12514?

> Requested service is not known to the listener.

## Q17. ORA-12541?

> No listener is available at the specified endpoint.

## Q18. How do you check invalid objects?

```sql
SELECT *
FROM DBA_OBJECTS
WHERE STATUS = 'INVALID';
```

## Q19. How do you check RMAN backup status?

```sql
SELECT *
FROM V$RMAN_BACKUP_JOB_DETAILS
ORDER BY START_TIME DESC;
```

## Q20. How do you check patch status?

```sql
SELECT *
FROM DBA_REGISTRY_SQLPATCH
ORDER BY ACTION_TIME DESC;
```

## Q21. How do you identify large segments?

```sql
SELECT *
FROM DBA_SEGMENTS
ORDER BY BYTES DESC;
```

## Q22. What is HWM?

> High Water Mark is the point up to which blocks in a segment have been formatted/used for segment operations.

## Q23. Does DELETE automatically shrink a table?

> No. DELETE makes blocks reusable but does not automatically return all allocated segment space to the tablespace.

## Q24. What do you check before adding a datafile?

> Tablespace usage, existing files, autoextend/MAXSIZE, ASM/filesystem capacity, growth trend and change approval.

## Q25. What is your production troubleshooting approach?

> Impact → evidence → root cause → approved corrective action → validation → monitoring → RCA/prevention.

---

# 85. Scenario-Based Interview Formula

When the interviewer gives any scenario, answer in this sequence:

```text
1. IDENTIFY
   What exactly is failing?

2. IMPACT
   How many users/applications are affected?

3. CHECK
   Database + sessions + logs + storage + network as applicable.

4. ISOLATE
   Identify the component causing the problem.

5. RCA
   Determine why it happened.

6. ACTION
   Take the safest approved corrective action.

7. VALIDATE
   Confirm database and application recovery.

8. MONITOR
   Watch for recurrence.

9. PREVENT
   Implement monitoring/change/process improvement.
```

---

# 86. Strong Production DBA Keywords

Use these naturally during interviews:

```text
Business Impact
Incident Priority
Root Cause Analysis
Pre-check
Post-check
Change Management
Rollback Plan
Validation
Monitoring
Application Team
Storage Team
Network Team
OEM
ServiceNow
RMAN
Data Pump
ASM
RAC
Data Guard
Broker
OPatch
OPatchAuto
AutoUpgrade
AWR
ASH
ADDM
SQL_ID
Execution Plan
Wait Events
Blocking Session
Tablespace
TEMP
UNDO
FRA
Archive Gap
Switchover
Failover
RCA
Preventive Action
```

---

# 87. Final Interview Strategy

For a 5+ year Oracle DBA interview, avoid answering only with definitions.

Use:

```text
THEORY
   +
COMMAND
   +
REAL-TIME SCENARIO
   +
TROUBLESHOOTING
   +
RCA
   +
VALIDATION
```

Example:

> "If a tablespace reaches 95%, I first validate the alert from the database. I check free space, datafile size, autoextend and MAXSIZE, then ASM capacity if it is ASM-managed. I identify the largest segments and recent growth. If the growth is expected, I provision additional capacity after approval. If the growth is abnormal, I investigate the application or segment causing it. After the change I verify tablespace capacity and application health."

This style demonstrates **hands-on production DBA experience**, rather than only theoretical knowledge.

---

# 88. Final Production DBA Checklist

```text
DATABASE
[ ] Instance status
[ ] Database role
[ ] Open mode
[ ] Alert log

PERFORMANCE
[ ] Active sessions
[ ] Wait events
[ ] Blocking
[ ] CPU
[ ] I/O
[ ] Top SQL
[ ] Execution plans

STORAGE
[ ] Tablespace
[ ] Datafiles
[ ] TEMP
[ ] UNDO
[ ] ASM
[ ] FRA
[ ] Filesystem

HIGH AVAILABILITY
[ ] RAC
[ ] ASM
[ ] Data Guard
[ ] Broker
[ ] Services

BACKUP
[ ] RMAN
[ ] Archive logs
[ ] Backup status
[ ] FRA

SECURITY
[ ] User status
[ ] Privileges
[ ] Roles
[ ] Quota

MAINTENANCE
[ ] Patching
[ ] Upgrades
[ ] Data Pump
[ ] Refresh
[ ] Statistics
[ ] Invalid objects

INCIDENT
[ ] Impact
[ ] Evidence
[ ] RCA
[ ] Corrective action
[ ] Validation
[ ] Monitoring
[ ] Preventive action
```

---

# 89. Final Interview Statement

> "As an Oracle DBA, my approach is not just to fix the immediate error. I first understand the business impact, collect technical evidence, identify the root cause, take the safest approved corrective action, validate the database and application, monitor the environment and document the RCA with preventive measures. This helps restore service quickly while also reducing the chance of recurrence."

# END



