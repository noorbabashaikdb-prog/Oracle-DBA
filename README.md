# Oracle DBA Notes

![Oracle DBA](https://img.shields.io/badge/Oracle-DBA-red)
![Oracle Database](https://img.shields.io/badge/Oracle%20Database-12c%20%7C%2019c-orange)
![Linux](https://img.shields.io/badge/Linux-RHEL%20%7C%20Oracle%20Linux-blue)
![RAC](https://img.shields.io/badge/RAC-Administration-green)
![Data Guard](https://img.shields.io/badge/Data%20Guard-HA%20%26%20DR-purple)
![ASM](https://img.shields.io/badge/ASM-Storage-yellow)

## 📚 Oracle DBA Complete Learning & Practical Repository

This repository contains **complete Oracle Database Administration notes, practical commands, troubleshooting procedures, real-time production scenarios, diagrams, interview questions, and SQL scripts**.

The content is designed for:

* Beginner Oracle DBAs
* 3–5 years experienced DBAs
* 5–8 years experienced Oracle DBAs
* Senior Oracle DBAs
* Production support DBAs
* RAC DBAs
* Database migration teams
* Database upgrade and patching teams
* Oracle DBA interview preparation

---

# 📖 Table of Contents

1. [About This Repository](#-about-this-repository)
2. [Oracle DBA Learning Roadmap](#-oracle-dba-learning-roadmap)
3. [Repository Structure](#-repository-structure)
4. [Oracle Database Architecture](#-oracle-database-architecture)
5. [Database Creation](#-database-creation)
6. [Startup and Shutdown](#-startup-and-shutdown)
7. [Tablespace Management](#-tablespace-management)
8. [Datafile Management](#-datafile-management)
9. [Temporary and Undo Management](#-temporary-and-undo-management)
10. [User and Privilege Management](#-user-and-privilege-management)
11. [Control File Management](#-control-file-management)
12. [Redo Log Management](#-redo-log-management)
13. [PFILE and SPFILE](#-pfile-and-spfile)
14. [OMF](#-oracle-managed-files-omf)
15. [ASM](#-automatic-storage-management-asm)
16. [RMAN Backup and Recovery](#-rman-backup-and-recovery)
17. [Data Pump](#-data-pump)
18. [Database Refresh and Cloning](#-database-refresh-and-cloning)
19. [Data Guard](#-oracle-data-guard)
20. [RAC](#-oracle-rac)
21. [Performance Tuning](#-performance-tuning)
22. [SQL Troubleshooting](#-sql-troubleshooting)
23. [Oracle Patching](#-oracle-patching)
24. [Oracle Upgrades](#-oracle-upgrades)
25. [Database Migration](#-database-migration)
26. [ASM Tablespace Management](#-asm-tablespace-management)
27. [Production Monitoring](#-production-monitoring)
28. [Real-Time Production Scenarios](#-real-time-production-scenarios)
29. [Oracle Errors](#-common-oracle-errors)
30. [Daily DBA Activities](#-daily-oracle-dba-checklist)
31. [Interview Preparation](#-oracle-dba-interview-preparation)
32. [Linux Commands](#-linux-commands-for-oracle-dba)
33. [Useful Oracle Views](#-important-oracle-views)
34. [Best Practices](#-oracle-dba-best-practices)
35. [Learning Path](#-recommended-learning-path)

---

# 🎯 About This Repository

The goal of this repository is to provide a **single Oracle DBA reference guide** containing both:

```text
THEORY
   ↓
CONCEPT
   ↓
SQL COMMAND
   ↓
PRACTICAL LAB
   ↓
MONITORING
   ↓
TROUBLESHOOTING
   ↓
REAL-TIME SCENARIO
   ↓
INTERVIEW ANSWER
```

The repository focuses on practical Oracle DBA responsibilities rather than only theoretical concepts.

---

# 🗺️ Oracle DBA Learning Roadmap

```text
                         ORACLE DBA
                             |
        +--------------------+--------------------+
        |                    |                    |
    DATABASE              STORAGE              HA / DR
        |                    |                    |
 Architecture              ASM               Data Guard
 Database Creation         Tablespace         RAC
 Startup/Shutdown          Datafiles          RMAN
 Users                     TEMP               Backup
 Security                  UNDO               Recovery
        |
        +--------------------+
        |
    PERFORMANCE
        |
   AWR / ADDM / ASH
        |
   SQL Tuning
        |
   Wait Events
        |
   Blocking Sessions
        |
   Long Running SQL
        |
   Execution Plans
        |
        +--------------------+
        |
   MAINTENANCE
        |
 Patching
 Upgrades
 Migration
 Cloning
 Refresh
```

---

# 📁 Repository Structure

```text
Oracle-DBA-Notes/
│
├── README.md
│
├── database-architecture/
│   ├── README.md
│   ├── architecture_theory.md
│   ├── architecture_commands.sql
│   └── architecture_diagram.png
│
├── database-creation/
│   ├── README.md
│   ├── database_creation.sql
│   ├── dbca_creation.md
│   └── database_creation_diagram.png
│
├── startup-shutdown/
│   ├── README.md
│   └── startup_shutdown.sql
│
├── tablespace-management/
│   ├── README.md
│   ├── 01_tablespace_theory.md
│   ├── 02_tablespace_creation.sql
│   ├── 03_tablespace_monitoring.sql
│   ├── 04_tablespace_resize_add_datafile.sql
│   ├── 05_temp_undo_management.sql
│   ├── 06_quota_management.sql
│   ├── 07_space_troubleshooting.sql
│   ├── 08_large_segments.sql
│   ├── 09_asm_tablespaces.sql
│   ├── 10_interview_scenarios.md
│   ├── tablespace_architecture.png
│   ├── tablespace_space_allocation.png
│   └── tablespace_full_troubleshooting.png
│
├── user-management/
│   ├── README.md
│   ├── users.sql
│   ├── privileges.sql
│   ├── roles.sql
│   └── profiles.sql
│
├── controlfile/
│   ├── README.md
│   └── controlfile_management.sql
│
├── redo-log/
│   ├── README.md
│   └── redo_management.sql
│
├── pfile-spfile/
│   ├── README.md
│   └── parameter_management.sql
│
├── omf/
│   ├── README.md
│   └── omf_commands.sql
│
├── asm/
│   ├── README.md
│   ├── asm_architecture.md
│   ├── asm_configuration.md
│   ├── asm_disk_management.sql
│   └── asm_troubleshooting.md
│
├── rman/
│   ├── README.md
│   ├── backup_commands.sql
│   ├── restore_recovery.md
│   └── rman_scenarios.md
│
├── data-pump/
│   ├── README.md
│   ├── expdp_commands.sql
│   ├── impdp_commands.sql
│   └── refresh_scenarios.md
│
├── cloning/
│   ├── README.md
│   ├── rman_clone.md
│   └── duplicate_commands.sql
│
├── data-guard/
│   ├── README.md
│   ├── primary_standby_setup.md
│   ├── broker_configuration.md
│   ├── switchover.md
│   ├── failover.md
│   └── troubleshooting.md
│
├── rac/
│   ├── README.md
│   ├── rac_installation.md
│   ├── srvctl_commands.md
│   ├── crsctl_commands.md
│   └── rac_troubleshooting.md
│
├── performance-tuning/
│   ├── README.md
│   ├── awr.md
│   ├── ash.md
│   ├── addm.md
│   ├── sql_tuning.md
│   ├── execution_plan.md
│   └── db_slowness_scenarios.md
│
├── patching/
│   ├── README.md
│   ├── opatch.md
│   ├── opatchauto.md
│   └── rac_patching.md
│
├── upgrades/
│   ├── README.md
│   ├── 11g_to_12c.md
│   ├── 12c_to_19c.md
│   └── autoupgrade.md
│
├── migration/
│   ├── README.md
│   ├── migration_methods.md
│   └── migration_scenarios.md
│
├── troubleshooting/
│   ├── README.md
│   ├── ora_errors.md
│   ├── listener_issues.md
│   ├── database_issues.md
│   └── performance_issues.md
│
├── linux/
│   ├── README.md
│   ├── linux_commands.md
│   └── oracle_linux_setup.md
│
└── interview/
    ├── README.md
    ├── oracle_dba_interview_questions.md
    ├── scenario_based_questions.md
    └── project_explanation.md
```

---

# 🏛️ Oracle Database Architecture

Oracle architecture can be broadly divided into:

```text
                  ORACLE DATABASE
                         |
             +-----------+-----------+
             |                       |
         INSTANCE                 DATABASE
             |                       |
       +-----+-----+           +-----+-----+
       |           |           |           |
      SGA        Processes   Datafiles   Controlfiles
       |                       |
 Shared Pool                  Redo Logs
 Buffer Cache                 Tempfiles
 Large Pool                   Undo
 Java Pool
```

## Main SGA Components

* Database Buffer Cache
* Shared Pool
* Large Pool
* Java Pool
* Streams Pool
* Result Cache

## Important Background Processes

* DBWn
* LGWR
* CKPT
* SMON
* PMON
* ARCn
* MMON
* MMNL
* RECO
* LREG

---

# 🏗️ Database Creation

Topics covered:

* DBCA database creation
* Manual database creation
* ORACLE_SID
* ORACLE_HOME
* Initialization parameters
* PFILE
* SPFILE
* Control files
* Redo log groups
* Datafiles
* SYSTEM
* SYSAUX
* UNDO
* TEMP
* USERS

Basic verification:

```sql
SELECT name, open_mode, database_role
FROM v$database;

SELECT instance_name, status
FROM v$instance;
```

---

# 🔄 Startup and Shutdown

## Startup Modes

```text
STARTUP NOMOUNT
      ↓
STARTUP MOUNT
      ↓
STARTUP OPEN
```

### NOMOUNT

Instance is started and SGA/processes are available.

### MOUNT

Control files are opened.

### OPEN

Database datafiles and online redo logs are opened.

## Shutdown

```sql
SHUTDOWN NORMAL;
SHUTDOWN TRANSACTIONAL;
SHUTDOWN IMMEDIATE;
SHUTDOWN ABORT;
```

Production environments generally prefer:

```sql
SHUTDOWN IMMEDIATE;
```

when a controlled shutdown is required.

---

# 📦 Tablespace Management

A tablespace is a **logical storage container** that consists of one or more physical datafiles.

```text
DATABASE
   |
   +-- SYSTEM
   |      |
   |      +-- SYSTEM01.DBF
   |
   +-- SYSAUX
   |      |
   |      +-- SYSAUX01.DBF
   |
   +-- USERS
   |      |
   |      +-- USERS01.DBF
   |
   +-- TEMP
   |      |
   |      +-- TEMP01.DBF
   |
   +-- UNDO
          |
          +-- UNDO01.DBF
```

## Space Hierarchy

```text
Tablespace
    ↓
Datafile
    ↓
Free Space
    ↓
Extent
    ↓
Segment
    ↓
Oracle Block
```

## Important Tablespace Topics

* Tablespace creation
* Datafiles
* Autoextend
* MAXSIZE
* Resize
* Add datafile
* Drop datafile
* Offline/online
* Read-only/read-write
* Locally managed tablespaces
* ASSM
* Uniform extents
* Autoallocate
* Bigfile tablespaces
* Smallfile tablespaces
* Temporary tablespaces
* Undo tablespaces
* Tablespace quotas
* Space monitoring
* Large segments
* ASM tablespaces
* Tablespace troubleshooting

---

# 📊 Tablespace Space Allocation

```text
TABLESPACE
     |
     +----------------------+
     |                      |
 DATAFILE 1              DATAFILE 2
     |                      |
     +----------+-----------+
                |
            FREE SPACE
                |
        +-------+-------+
        |       |       |
     EXTENT  EXTENT  EXTENT
        |
      SEGMENT
        |
   TABLE / INDEX / LOB
```

Monitor:

```sql
SELECT tablespace_name,
       ROUND(SUM(bytes)/1024/1024,2) AS free_mb
FROM dba_free_space
GROUP BY tablespace_name;
```

---

# 💾 Datafile Management

Important operations:

```sql
ALTER TABLESPACE USERS
ADD DATAFILE '/u01/oradata/USERS02.DBF'
SIZE 1G;

ALTER DATABASE DATAFILE
'/u01/oradata/USERS01.DBF'
RESIZE 2G;

ALTER DATABASE DATAFILE
'/u01/oradata/USERS01.DBF'
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;
```

Always check:

```sql
SELECT file_name,
       bytes/1024/1024 AS size_mb,
       autoextensible,
       maxbytes/1024/1024 AS max_mb
FROM dba_data_files;
```

---

# 🌡️ Temporary and Undo Management

## TEMP

TEMP is used for operations such as:

* Sort
* Hash joins
* Temporary tables
* Create index operations
* Large SQL operations

Monitor:

```sql
SELECT tablespace_name,
       SUM(bytes_used)/1024/1024 AS used_mb,
       SUM(bytes_free)/1024/1024 AS free_mb
FROM v$temp_space_header
GROUP BY tablespace_name;
```

## UNDO

UNDO stores information required for:

* Transaction rollback
* Read consistency
* Flashback-related operations
* Recovery of uncommitted transactions

Important views:

```sql
SELECT *
FROM v$undostat;
```

---

# 👤 User and Privilege Management

Topics:

* CREATE USER
* ALTER USER
* DROP USER
* Password management
* Roles
* System privileges
* Object privileges
* Profiles
* Tablespace quota
* Default tablespace
* Temporary tablespace
* Account locking/unlocking

Example:

```sql
CREATE USER app_user
IDENTIFIED BY "LabPassword123";

ALTER USER app_user
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;

ALTER USER app_user
QUOTA 1G ON USERS;

GRANT CREATE SESSION TO app_user;
```

---

# 📑 Control File Management

Control files contain critical database metadata such as:

* Database name
* DBID
* Datafile information
* Redo log information
* Checkpoint information
* Backup information

Check:

```sql
SHOW PARAMETER control_files;
```

or:

```sql
SELECT name
FROM v$controlfile;
```

Best practice:

```text
CONTROL01.CTL
CONTROL02.CTL
```

should preferably be multiplexed across different physical storage locations.

---

# 🔴 Redo Log Management

Redo logs record database changes.

Architecture:

```text
            REDO LOG
               |
       +-------+-------+
       |               |
   GROUP 1          GROUP 2
       |               |
   MEMBER 1         MEMBER 1
   MEMBER 2         MEMBER 2
```

Check:

```sql
SELECT group#,
       thread#,
       bytes/1024/1024 AS size_mb,
       members,
       status
FROM v$log;
```

Members:

```sql
SELECT group#, member
FROM v$logfile;
```

---

# ⚙️ PFILE and SPFILE

## PFILE

Text-based initialization parameter file.

Example:

```text
initORCL.ora
```

## SPFILE

Binary server parameter file.

Check:

```sql
SHOW PARAMETER spfile;
```

Create:

```sql
CREATE SPFILE FROM PFILE;
```

Create PFILE:

```sql
CREATE PFILE='/tmp/initORCL.ora'
FROM SPFILE;
```

---

# 📁 Oracle Managed Files — OMF

OMF allows Oracle to automatically manage database file names and locations.

Example:

```sql
ALTER SYSTEM SET
db_create_file_dest='+DATA'
SCOPE=BOTH;
```

Then:

```sql
CREATE TABLESPACE APP_DATA
DATAFILE '+DATA'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;
```

Benefits:

* Simplified file management
* Automatic naming
* Easier database administration
* Useful with ASM

---

# 💿 Automatic Storage Management — ASM

ASM provides Oracle-integrated storage management.

```text
                 ASM
                  |
       +----------+----------+
       |                     |
     +DATA                  +FRA
       |                     |
   DB Files              Recovery Files
       |
 +-----------+
 |           |
Disk 1     Disk 2
```

Important ASM concepts:

* Disk group
* ASM disk
* Allocation unit
* Failure group
* Redundancy
* External redundancy
* Normal redundancy
* High redundancy
* Rebalancing
* ASM instance

Important views:

```sql
SELECT name,
       type,
       total_mb,
       free_mb,
       usable_file_mb,
       state
FROM v$asm_diskgroup;
```

ASM operations:

```sql
ALTER DISKGROUP DATA
ADD DISK '/dev/oracleasm/disks/DISK05';

ALTER DISKGROUP DATA
DROP DISK DATA_0004;
```

---

# 💾 RMAN Backup and Recovery

RMAN is Oracle's primary backup and recovery utility.

Topics:

* Full backup
* Incremental backup
* Level 0
* Level 1
* Archive log backup
* Control file backup
* SPFILE backup
* Restore
* Recovery
* Point-in-time recovery
* Database recovery
* Datafile recovery
* Block recovery
* RMAN catalog
* RMAN duplicate
* Backup validation
* Crosscheck
* Delete expired
* Delete obsolete

Example:

```rman
BACKUP DATABASE PLUS ARCHIVELOG;
```

Validation:

```rman
RESTORE DATABASE VALIDATE;
```

---

# 📦 Data Pump

Oracle Data Pump provides logical export/import.

Tools:

```text
EXPDP
IMPDP
```

Export:

```bash
expdp system/password \
schemas=APP_USER \
directory=DP_DIR \
dumpfile=app_user.dmp \
logfile=app_user_exp.log
```

Import:

```bash
impdp system/password \
directory=DP_DIR \
dumpfile=app_user.dmp \
logfile=app_user_imp.log
```

Important use cases:

* Schema refresh
* Object migration
* Database migration
* Table export/import
* Schema cloning
* Development refresh

---

# 🔄 Database Refresh and Cloning

Common methods:

```text
Schema Refresh
    |
    +-- Data Pump
    |
Database Refresh
    |
    +-- RMAN
    |
Database Clone
    |
    +-- RMAN DUPLICATE
```

## RMAN Duplicate

Common use cases:

* Production → Test
* Production → Development
* Standby creation
* Clone database
* Refresh environments

---

# 🛡️ Oracle Data Guard

Data Guard provides high availability and disaster recovery.

```text
             PRIMARY
                |
        Redo Transport
                |
                ↓
             STANDBY
                |
        Redo Apply
                |
                ↓
          DR DATABASE
```

Important concepts:

* Primary database
* Physical standby
* Logical standby
* Redo transport
* Redo apply
* Archive gap
* Switchover
* Failover
* Reinstate
* Data Guard Broker
* Fast-start failover
* Protection modes

Check:

```sql
SELECT database_role,
       open_mode,
       protection_mode
FROM v$database;
```

---

# 🔁 Data Guard Switchover

Typical flow:

```text
PRIMARY
   |
   | Switchover
   ↓
STANDBY
   |
   ↓
NEW PRIMARY
```

Broker:

```bash
dgmgrl /
```

Common commands:

```text
SHOW CONFIGURATION;

SHOW DATABASE VERBOSE <db_unique_name>;

VALIDATE DATABASE VERBOSE <db_unique_name>;

SWITCHOVER TO <db_unique_name>;
```

---

# 🚨 Data Guard Failover

Failover is performed when the primary database is unavailable or cannot be recovered within the required business timeframe.

Typical flow:

```text
PRIMARY FAILURE
       ↓
CHECK STANDBY
       ↓
CHECK APPLY / GAP
       ↓
PERFORM FAILOVER
       ↓
STANDBY BECOMES PRIMARY
       ↓
REBUILD / REINSTATE OLD PRIMARY
```

---

# 🖥️ Oracle RAC

Real Application Clusters allow multiple instances to access the same database.

```text
             RAC DATABASE
                  |
        +---------+---------+
        |                   |
      NODE 1              NODE 2
        |                   |
    INSTANCE 1          INSTANCE 2
        |                   |
        +---------+---------+
                  |
             ASM STORAGE
```

Important RAC components:

* Grid Infrastructure
* Clusterware
* ASM
* OCR
* Voting disks
* SCAN
* VIP
* Public network
* Private interconnect
* CRS
* CSS
* EVMD
* GPNPD

Important commands:

```bash
crsctl status resource -t

crsctl check cluster

srvctl status database -d ORCL

srvctl status instance -d ORCL

srvctl status listener
```

---

# 📈 Performance Tuning

Performance troubleshooting flow:

```text
USER REPORTS SLOW DATABASE
          ↓
CHECK DATABASE AVAILABILITY
          ↓
CHECK CPU / MEMORY / IO
          ↓
CHECK WAIT EVENTS
          ↓
CHECK BLOCKING SESSIONS
          ↓
CHECK LONG RUNNING SQL
          ↓
CHECK EXECUTION PLAN
          ↓
CHECK AWR / ASH
          ↓
IDENTIFY ROOT CAUSE
          ↓
FIX
          ↓
VALIDATE
          ↓
RCA
```

Important areas:

* AWR
* ASH
* ADDM
* SQL Monitor
* Execution plans
* Wait events
* CPU
* I/O
* Memory
* Locks
* Blocking sessions
* Long-running SQL
* High CPU SQL
* High I/O SQL
* Parse issues
* Statistics
* Indexes

---

# 🔍 SQL Execution Plan

Basic command:

```sql
EXPLAIN PLAN FOR
SELECT *
FROM employees
WHERE employee_id = 100;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);
```

For an executed cursor:

```sql
SELECT *
FROM TABLE(
  DBMS_XPLAN.DISPLAY_CURSOR(
    NULL,
    NULL,
    'ALLSTATS LAST'
  )
);
```

Look for:

* Full table scans
* Index access
* High cardinality mismatch
* Large row estimates
* Expensive joins
* Sort operations
* Hash operations
* Excessive logical reads
* Excessive physical reads

---

# 🔧 Database Slowness Troubleshooting

When an application reports database slowness:

## Step 1 — Check database status

```sql
SELECT instance_name,
       status,
       database_status
FROM v$instance;
```

## Step 2 — Check blocking sessions

```sql
SELECT blocking_session,
       sid,
       serial#,
       username,
       event
FROM v$session
WHERE blocking_session IS NOT NULL;
```

## Step 3 — Check active sessions

```sql
SELECT sid,
       serial#,
       username,
       status,
       event,
       sql_id
FROM v$session
WHERE status='ACTIVE';
```

## Step 4 — Check SQL

```sql
SELECT sql_id,
       executions,
       elapsed_time,
       cpu_time,
       buffer_gets,
       disk_reads
FROM v$sql
ORDER BY elapsed_time DESC;
```

## Step 5 — Check execution plan

```sql
SELECT *
FROM TABLE(
  DBMS_XPLAN.DISPLAY_CURSOR(
    '<SQL_ID>',
    NULL,
    'ALLSTATS LAST'
  )
);
```

---

# 🩹 Oracle Patching

Important tools:

```text
OPatch
OPatchAuto
```

## OPatch

Used mainly for Oracle Database home patching.

Check:

```bash
$ORACLE_HOME/OPatch/opatch version

$ORACLE_HOME/OPatch/opatch lspatches

$ORACLE_HOME/OPatch/opatch lsinventory
```

## OPatchAuto

Used primarily for Grid Infrastructure/RAC automated patching workflows.

Typical production approach:

```text
PATCH PLANNING
      ↓
BACKUP
      ↓
CHECK OPATCH
      ↓
CHECK CONFLICTS
      ↓
PATCH NON-PRODUCTION
      ↓
TEST
      ↓
PRODUCTION CHANGE
      ↓
PATCH
      ↓
VALIDATE
      ↓
MONITOR
```

---

# ⬆️ Oracle Upgrades

Common upgrade paths:

```text
11g
 ↓
12c
 ↓
19c
```

Upgrade methods:

* DBUA
* Manual upgrade
* AutoUpgrade
* Data Pump migration
* RMAN migration
* Transportable technologies

## AutoUpgrade

Typical phases:

```text
ANALYZE
   ↓
FIXUPS
   ↓
DEPLOY
   ↓
POST-UPGRADE VALIDATION
```

---

# 🚚 Database Migration

Common migration methods:

| Method                    | Use Case                                   |
| ------------------------- | ------------------------------------------ |
| Data Pump                 | Logical migration                          |
| RMAN                      | Physical migration                         |
| RMAN Duplicate            | Clone                                      |
| Transportable Tablespaces | Large databases                            |
| Data Guard                | Minimal downtime / standby-based migration |
| GoldenGate                | Near-zero downtime logical replication     |

Migration planning:

```text
SOURCE
  ↓
ASSESSMENT
  ↓
DEPENDENCY CHECK
  ↓
BACKUP
  ↓
MIGRATION
  ↓
VALIDATION
  ↓
APPLICATION TEST
  ↓
CUTOVER
  ↓
POST-CUTOVER MONITORING
```

---

# 🗄️ ASM Tablespace Management

ASM-backed tablespaces use ASM disk groups instead of normal filesystem datafile paths.

```text
DATABASE
    |
TABLESPACE
    |
DATAFILE
    |
ASM DISKGROUP
    |
+DATA
    |
ASM DISKS
```

Example:

```sql
CREATE TABLESPACE APP_DATA
DATAFILE '+DATA'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;
```

Check ASM capacity:

```sql
SELECT name,
       total_mb,
       free_mb,
       usable_file_mb,
       state
FROM v$asm_diskgroup;
```

---

# 📊 Production Monitoring

Important monitoring areas:

```text
DATABASE
 ├── Instance status
 ├── Database status
 ├── Tablespace
 ├── TEMP
 ├── UNDO
 ├── ASM
 ├── FRA
 ├── Archive logs
 ├── RMAN backups
 ├── Data Guard
 ├── RAC
 ├── CPU
 ├── Memory
 ├── Sessions
 ├── Blocking
 └── Long-running SQL
```

Typical tools:

* Oracle Enterprise Manager
* OEM Cloud Control
* SQL*Plus
* SQL Developer
* ServiceNow
* Linux monitoring
* RMAN
* Data Guard Broker

---

# 🚨 Real-Time Production Scenarios

## Scenario 1 — Tablespace 95% Full

```text
ALERT
 ↓
Identify tablespace
 ↓
Check free space
 ↓
Check datafiles
 ↓
Check AUTOEXTEND
 ↓
Check MAXSIZE
 ↓
Check filesystem / ASM
 ↓
Find large segments
 ↓
Add/resize datafile if appropriate
 ↓
Validate
```

---

## Scenario 2 — ORA-01653

```text
ORA-01653:
unable to extend table
```

Check:

```sql
SELECT tablespace_name,
       SUM(bytes)/1024/1024 AS free_mb
FROM dba_free_space
GROUP BY tablespace_name;
```

Then:

```sql
SELECT file_name,
       bytes/1024/1024 AS size_mb,
       autoextensible,
       maxbytes/1024/1024 AS max_mb
FROM dba_data_files
WHERE tablespace_name='USERS';
```

Possible causes:

* No free space
* Autoextend disabled
* MAXSIZE reached
* ASM full
* Filesystem full

---

# ⚠️ Common Oracle Errors

| Error     | Meaning / Common Cause                           |
| --------- | ------------------------------------------------ |
| ORA-01653 | Unable to extend table                           |
| ORA-01654 | Unable to extend index                           |
| ORA-01652 | Unable to extend TEMP segment                    |
| ORA-30036 | Unable to extend UNDO                            |
| ORA-01536 | User quota exceeded                              |
| ORA-03297 | File contains used data beyond requested RESIZE  |
| ORA-01555 | Snapshot too old                                 |
| ORA-00060 | Deadlock detected                                |
| ORA-00054 | Resource busy                                    |
| ORA-01017 | Invalid username/password                        |
| ORA-01033 | Oracle initialization/startup in progress        |
| ORA-01109 | Database not open                                |
| ORA-00205 | Error identifying control file                   |
| ORA-00313 | Error opening redo log                           |
| ORA-12514 | Listener does not currently know service         |
| ORA-12541 | No listener                                      |
| ORA-16047 | Data Guard DBID mismatch                         |
| ORA-16698 | Member has LOG_ARCHIVE_DEST parameter configured |
| ORA-16789 | Standby redo logs not configured correctly       |
| ORA-15041 | ASM diskgroup space exhausted                    |
| ORA-15032 | Not all alterations performed                    |
| ORA-15017 | Diskgroup cannot be mounted                      |

---

# 🧑‍💻 Daily Oracle DBA Checklist

## Morning Health Check

```text
☐ Database availability
☐ Instance status
☐ Tablespace usage
☐ TEMP usage
☐ UNDO usage
☐ FRA usage
☐ ASM diskgroup usage
☐ RMAN backup status
☐ Archive log generation
☐ Data Guard status
☐ RAC status
☐ Blocking sessions
☐ Long-running sessions
☐ Invalid objects
☐ Listener status
☐ Alert log
☐ OEM alerts
☐ Filesystem usage
```

---

# 📋 24×7 Production DBA Workflow

```text
SHIFT START
    ↓
CHECK HANDOVER
    ↓
CHECK PENDING INCIDENTS
    ↓
CHECK OEM ALERTS
    ↓
CHECK DATABASE HEALTH
    ↓
CHECK RMAN
    ↓
CHECK DATA GUARD
    ↓
CHECK ASM / STORAGE
    ↓
CHECK TABLESPACES
    ↓
CHECK PERFORMANCE
    ↓
WORK ON INCIDENTS
    ↓
DOCUMENT ACTIONS
    ↓
SHIFT HANDOVER
```

---

# 🎤 Oracle DBA Interview Preparation

Interview topics covered in this repository:

## Basic

* What is Oracle Database?
* What is an instance?
* What is a database?
* Explain Oracle architecture.
* Explain SGA.
* Explain PGA.
* What is a background process?
* Explain startup modes.
* Explain shutdown modes.

## Tablespace

* What is a tablespace?
* Difference between tablespace and datafile.
* What is a segment?
* What is an extent?
* What is an Oracle block?
* Bigfile vs smallfile tablespace.
* LMT vs DMT.
* ASSM.
* Autoextend.
* MAXSIZE.
* Tablespace 90% full scenario.
* ORA-01653 troubleshooting.

## RMAN

* Full backup
* Incremental backup
* Level 0 vs Level 1
* Restore vs recovery
* Complete recovery
* Incomplete recovery
* Point-in-time recovery
* RMAN duplicate
* Control file restore
* SPFILE restore
* Archive log backup

## Data Guard

* Physical standby
* Logical standby
* Redo transport
* Redo apply
* Switchover
* Failover
* Reinstate
* Archive gap
* Broker
* Protection modes
* Standby redo logs

## RAC

* RAC architecture
* OCR
* Voting disk
* SCAN
* VIP
* Private interconnect
* CRSCTL
* SRVCTL
* RAC patching
* RAC troubleshooting

## Performance

* AWR
* ASH
* ADDM
* SQL ID
* Execution plan
* Blocking sessions
* Locks
* Wait events
* High CPU SQL
* High I/O SQL
* Long-running SQL

## Patching

* OPatch
* OPatchAuto
* Patch conflict
* Inventory
* PSU/RU
* RAC patching
* GI patching
* Rollback

## Upgrade

* 11g → 12c
* 12c → 19c
* AutoUpgrade
* Pre-upgrade checks
* Post-upgrade validation
* Invalid objects
* Application validation

---

# 🧠 Real-Time Interview Answer Framework

For production scenario questions, use:

```text
1. UNDERSTAND THE ISSUE
        ↓
2. CHECK IMPACT
        ↓
3. COLLECT EVIDENCE
        ↓
4. IDENTIFY ROOT CAUSE
        ↓
5. TAKE SAFE ACTION
        ↓
6. VALIDATE
        ↓
7. MONITOR
        ↓
8. DOCUMENT RCA
```

Example:

> "First I understand the issue and check the business impact. Then I validate the database, instance, sessions, storage and relevant alert messages. Based on the evidence, I identify the root cause and take the appropriate change-controlled action. After the fix, I validate database health and application functionality, continue monitoring, and document the RCA."

---

# 🐧 Linux Commands for Oracle DBA

## Filesystem

```bash
df -h
df -i
du -sh *
du -sh /u01/*
```

## Memory

```bash
free -g
vmstat 2 5
```

## CPU

```bash
top
uptime
mpstat
```

## Processes

```bash
ps -ef | grep pmon
ps -ef | grep tns
ps -ef | grep oracle
```

## Disk

```bash
lsblk
blkid
mount
```

## Network

```bash
ip addr
ip route
ping <host>
ss -lntp
```

## Oracle Environment

```bash
echo $ORACLE_HOME
echo $ORACLE_SID
which sqlplus
which rman
```

---

# 👀 Important Oracle Views

## Database

```text
V$DATABASE
V$INSTANCE
V$PARAMETER
V$SYSTEM_PARAMETER
```

## Storage

```text
DBA_TABLESPACES
DBA_DATA_FILES
DBA_TEMP_FILES
DBA_FREE_SPACE
DBA_SEGMENTS
DBA_EXTENTS
```

## Users

```text
DBA_USERS
DBA_ROLES
DBA_SYS_PRIVS
DBA_TAB_PRIVS
DBA_ROLE_PRIVS
DBA_TS_QUOTAS
```

## Performance

```text
V$SESSION
V$SQL
V$SQLAREA
V$SESSION_WAIT
V$SYSTEM_EVENT
V$SESSION_EVENT
V$LOCK
V$LOCKED_OBJECT
```

## Undo

```text
V$UNDOSTAT
V$TRANSACTION
DBA_UNDO_EXTENTS
```

## ASM

```text
V$ASM_DISKGROUP
V$ASM_DISK
V$ASM_OPERATION
```

## Data Guard

```text
V$DATABASE
V$DATAGUARD_STATS
V$ARCHIVE_DEST
V$ARCHIVE_DEST_STATUS
V$MANAGED_STANDBY
V$ARCHIVED_LOG
```

---

# 🔐 Oracle DBA Best Practices

## Backup

* Always maintain valid RMAN backups.
* Regularly test restore procedures.
* Monitor failed backups.
* Monitor archive log backups.
* Validate backup availability.

## Storage

* Monitor tablespace utilization.
* Monitor filesystem utilization.
* Monitor ASM disk groups.
* Review autoextend and MAXSIZE.
* Plan capacity before storage becomes critical.

## Security

* Do not share SYS credentials.
* Use least privilege.
* Avoid unnecessary `UNLIMITED TABLESPACE`.
* Review inactive accounts.
* Follow password policies.

## Production Changes

Always follow:

```text
Change Request
      ↓
Impact Analysis
      ↓
Approval
      ↓
Backup
      ↓
Implementation
      ↓
Validation
      ↓
Monitoring
      ↓
Closure
```

---

# 📝 Production RCA Template

```text
Incident:
----------

Date:
------

Database:
---------

Environment:
------------

Application:
------------

Severity:
---------

Start Time:
-----------

End Time:
---------

Business Impact:
----------------

Issue:
------

Root Cause:
-----------

Investigation Performed:
------------------------

Commands / Evidence:
--------------------

Resolution:
----------

Validation:
----------

Preventive Action:
------------------

Monitoring Added:
-----------------

Change Reference:
-----------------
```

---

# 🧪 Recommended Oracle DBA Lab Environment

A practical learning environment can contain:

```text
                    LAB
                     |
        +------------+------------+
        |                         |
   Oracle Linux              RHEL Linux
        |                         |
      19c                       12c
        |                         |
       ASM                  Data Guard
        |                         |
       RAC                   Primary
                                  |
                               Standby
```

Suggested lab components:

```text
Oracle Linux 8.x
RHEL 7.x
Oracle 12c
Oracle 19c
ASM
RMAN
Data Guard
Data Pump
RAC concepts
OEM
Linux administration
```

---

# 📚 Suggested Learning Order

## Level 1 — Fundamentals

```text
Oracle Architecture
       ↓
Instance / Database
       ↓
SGA / PGA
       ↓
Background Processes
       ↓
Startup / Shutdown
```

## Level 2 — Storage

```text
Tablespace
   ↓
Datafile
   ↓
Segment
   ↓
Extent
   ↓
Block
   ↓
ASM
```

## Level 3 — Administration

```text
Users
Privileges
Roles
Profiles
Control Files
Redo Logs
PFILE / SPFILE
OMF
```

## Level 4 — Backup

```text
RMAN
 ↓
Backup
 ↓
Restore
 ↓
Recovery
 ↓
Duplicate
```

## Level 5 — HA / DR

```text
Data Guard
   ↓
Switchover
   ↓
Failover
   ↓
Broker
   ↓
RAC
```

## Level 6 — Performance

```text
AWR
 ↓
ASH
 ↓
ADDM
 ↓
SQL
 ↓
Execution Plan
 ↓
Wait Events
```

## Level 7 — Maintenance

```text
Patching
   ↓
OPatch
   ↓
OPatchAuto
   ↓
Upgrade
   ↓
AutoUpgrade
   ↓
Migration
```

---

# ⭐ Important DBA Commands Quick Reference

## Database

```sql
SELECT name, open_mode, database_role
FROM v$database;

SELECT instance_name, status
FROM v$instance;
```

## Tablespaces

```sql
SELECT tablespace_name,
       status,
       contents,
       extent_management,
       segment_space_management
FROM dba_tablespaces;
```

## Datafiles

```sql
SELECT file_name,
       tablespace_name,
       bytes/1024/1024 AS size_mb,
       autoextensible
FROM dba_data_files;
```

## Sessions

```sql
SELECT sid,
       serial#,
       username,
       status,
       event,
       sql_id
FROM v$session;
```

## Blocking

```sql
SELECT sid,
       serial#,
       blocking_session,
       event
FROM v$session
WHERE blocking_session IS NOT NULL;
```

## Invalid Objects

```sql
SELECT owner,
       object_type,
       COUNT(*)
FROM dba_objects
WHERE status='INVALID'
GROUP BY owner, object_type;
```

## Database Role

```sql
SELECT database_role,
       open_mode,
       protection_mode
FROM v$database;
```

---

# 🚀 Production DBA Golden Rules

```text
1. Never make a production change without understanding the impact.

2. Always check the current configuration before modifying it.

3. Always maintain valid backups.

4. Never assume that a tablespace alert means only "add a datafile".

5. Check datafile size, free space, AUTOEXTEND, MAXSIZE,
   filesystem/ASM capacity and segment growth.

6. Never kill a session without understanding the business impact.

7. For performance issues, collect evidence before changing parameters.

8. For Data Guard issues, check transport, gap, apply and role status.

9. For RAC issues, distinguish database problems from cluster/GI problems.

10. Always validate after performing a change.

11. Document production incidents and create RCA.

12. Monitor trends instead of waiting for critical alerts.
```

---

# 🔎 DBA Troubleshooting Philosophy

The most important principle in production support is:

```text
DO NOT GUESS
    ↓
CHECK
    ↓
ANALYZE
    ↓
IDENTIFY ROOT CAUSE
    ↓
FIX
    ↓
VALIDATE
```

For example:

```text
Tablespace 95% Full
       |
       +-- Is free space actually low?
       |
       +-- Is AUTOEXTEND enabled?
       |
       +-- Has MAXSIZE been reached?
       |
       +-- Is filesystem full?
       |
       +-- Is ASM full?
       |
       +-- Which segment is growing?
       |
       +-- Is application batch causing growth?
       |
       +-- Is temporary/undo space involved?
       |
       +-- What is the safest corrective action?
```

---

# 📌 Repository Goals

This repository aims to provide:

* ✅ Oracle DBA theory
* ✅ Practical SQL
* ✅ Linux commands
* ✅ Production troubleshooting
* ✅ ASM administration
* ✅ RMAN backup/recovery
* ✅ Data Pump
* ✅ Data Guard
* ✅ RAC
* ✅ Performance tuning
* ✅ Patching
* ✅ Upgrades
* ✅ Migration
* ✅ Database refresh
* ✅ Cloning
* ✅ Real-time scenarios
* ✅ Interview questions
* ✅ Production RCA examples
* ✅ Architecture diagrams
* ✅ GitHub-ready documentation

---

# 📊 Oracle DBA Skill Map

```text
                       ORACLE DBA
                           |
       +-------------------+-------------------+
       |                   |                   |
    CORE DBA             STORAGE             HA/DR
       |                   |                   |
 Architecture             ASM              Data Guard
 Tablespace               Files             RAC
 Users                    TEMP              RMAN
 Redo                     UNDO              Backup
 Control File             OMF               Recovery
 PFILE/SPFILE
       |
       +-------------------+-------------------+
                           |
                      PERFORMANCE
                           |
                 +---------+---------+
                 |         |         |
                AWR       ASH       ADDM
                 |
             SQL Tuning
                 |
          Execution Plans
                 |
            Wait Events
                           |
                           ↓
                     MAINTENANCE
                           |
              +------------+------------+
              |            |            |
           Patching     Upgrade      Migration
              |            |            |
           OPatch      AutoUpgrade   Data Pump
           OPatchAuto                 RMAN
```

---

# 🎓 Final Oracle DBA Checklist

Before considering yourself production-ready, you should be comfortable with:

```text
DATABASE
☐ Architecture
☐ Instance
☐ SGA/PGA
☐ Background processes

STORAGE
☐ Tablespaces
☐ Datafiles
☐ TEMP
☐ UNDO
☐ ASM
☐ OMF

SECURITY
☐ Users
☐ Roles
☐ Privileges
☐ Profiles
☐ Quotas

BACKUP
☐ RMAN
☐ Restore
☐ Recovery
☐ Duplicate
☐ Backup validation

HA / DR
☐ Data Guard
☐ Switchover
☐ Failover
☐ Broker
☐ RAC

PERFORMANCE
☐ AWR
☐ ASH
☐ ADDM
☐ SQL tuning
☐ Execution plans
☐ Blocking sessions
☐ Wait events

MAINTENANCE
☐ Patching
☐ OPatch
☐ OPatchAuto
☐ Upgrades
☐ AutoUpgrade
☐ Migration
☐ Cloning
☐ Refresh

PRODUCTION
☐ OEM monitoring
☐ Incident management
☐ Change management
☐ RCA
☐ Capacity planning
☐ 24×7 support
☐ Shift handover
```

---

# ⭐ Conclusion

Oracle Database Administration is not only about knowing SQL commands. A production Oracle DBA must understand:

```text
DATABASE
   +
STORAGE
   +
BACKUP
   +
RECOVERY
   +
HIGH AVAILABILITY
   +
PERFORMANCE
   +
SECURITY
   +
PATCHING
   +
UPGRADE
   +
MIGRATION
   +
TROUBLESHOOTING
   +
PRODUCTION SUPPORT
```

The objective of this repository is to connect **Oracle DBA theory with real production operations**.

```text
LEARN
  ↓
PRACTICE
  ↓
TROUBLESHOOT
  ↓
UNDERSTAND ROOT CAUSE
  ↓
AUTOMATE
  ↓
DOCUMENT
  ↓
BECOME PRODUCTION READY
```

---

## 📚 Oracle DBA Notes Repository

**Core Focus:**

```text
Oracle 12c
Oracle 19c
Linux
ASM
RAC
Data Guard
RMAN
Data Pump
Performance Tuning
Patching
Upgrades
Migration
Production Support
Interview Preparation
```

**Status:** 🚧 Continuously expanding with practical Oracle DBA scenarios and production troubleshooting examples.
