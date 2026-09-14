# Oracle Tablespace Management

A complete Oracle DBA guide covering **Tablespace Management Theory, SQL Practical, Monitoring, Space Management, TEMP/UNDO, Quotas, Troubleshooting, ASM Tablespaces, and Real-Time DBA Scenarios**.

---

## 📚 Module Overview

A **tablespace** is a logical storage unit in an Oracle Database used to organize and manage database objects such as:

* Tables
* Indexes
* LOBs
* Materialized Views
* Undo segments
* Temporary segments

Physical database files such as **datafiles** and **tempfiles** are associated with tablespaces.

```text
                    ORACLE DATABASE
                           │
            ┌──────────────┴──────────────┐
            │                             │
       TABLESPACES                   CONTROL FILE
            │
     ┌──────┼─────────┐
     │      │         │
   SYSTEM  SYSAUX    USERS
     │      │         │
 Datafiles Datafiles Datafiles
```

# 1. Tablespace Architecture

The Oracle storage hierarchy can be represented as:

```text
DATABASE
   │
   └── TABLESPACE
          │
          ├── DATAFILE
          │
          ├── SEGMENT
          │
          │    ├── TABLE
          │    ├── INDEX
          │    └── LOB
          │
          └── EXTENTS
                 │
                 └── BLOCKS
```

### Logical Storage Hierarchy

```text
Database
   ↓
Tablespace
   ↓
Segment
   ↓
Extent
   ↓
Oracle Block
```

---

# 2. Types of Tablespaces

Oracle commonly uses the following tablespace types:

| Type           | Purpose                     |
| -------------- | --------------------------- |
| SYSTEM         | Data dictionary             |
| SYSAUX         | Auxiliary system components |
| USERS          | User/application objects    |
| TEMP           | Temporary operations        |
| UNDO           | Undo information            |
| Application TS | Application data            |
| Index TS       | Index segments              |
| Bigfile TS     | Large-scale storage         |

Oracle distinguishes permanent, temporary, and undo tablespaces. Permanent tablespaces store persistent objects, temporary tablespaces use tempfiles for temporary operations, and undo tablespaces store undo data.

---

# 3. Locally Managed Tablespace

A locally managed tablespace stores extent management information in bitmap structures inside the tablespace.

```text
DATAFILE
┌───────────────────────────────────────┐
│ Header                                │
├───────────────────────────────────────┤
│ Extent Bitmap                         │
├───────────────────────────────────────┤
│ Extent                                │
├───────────────────────────────────────┤
│ Extent                                │
├───────────────────────────────────────┤
│ Free Space                            │
└───────────────────────────────────────┘
```

Advantages:

* Better space management
* Reduced dictionary contention
* Faster extent allocation
* No manual free-space coalescing
* Supports automatic extent allocation

Locally managed tablespaces are the standard approach for modern Oracle databases.

---

# 4. Segment Space Management

There are two segment space management methods:

```text
SEGMENT SPACE MANAGEMENT
          │
     ┌────┴────┐
     │         │
    AUTO     MANUAL
     │         │
  Bitmaps    Freelist
```

## AUTO

Recommended for normal permanent tablespaces.

```sql
CREATE TABLESPACE app_data
DATAFILE '/u01/oradata/APP/app_data01.dbf'
SIZE 1G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;
```

Automatic segment-space management uses bitmaps to track free space. Oracle recommends AUTO rather than MANUAL.

---

# 5. Creating a Tablespace

## Smallfile Tablespace

```sql
CREATE TABLESPACE app_data
DATAFILE '/u01/oradata/APP/app_data01.dbf'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;
```

---

# 6. Adding a Datafile

```sql
ALTER TABLESPACE app_data
ADD DATAFILE '/u01/oradata/APP/app_data02.dbf'
SIZE 1G
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;
```

---

# 7. Resize Datafile

```sql
ALTER DATABASE DATAFILE
'/u01/oradata/APP/app_data01.dbf'
RESIZE 2G;
```

Before resizing downward, verify that allocated extents do not exist beyond the desired size.

---

# 8. Autoextend

Enable autoextend:

```sql
ALTER DATABASE DATAFILE
'/u01/oradata/APP/app_data01.dbf'
AUTOEXTEND ON
NEXT 100M
MAXSIZE 10G;
```

Disable:

```sql
ALTER DATABASE DATAFILE
'/u01/oradata/APP/app_data01.dbf'
AUTOEXTEND OFF;
```

### Important DBA Point

Autoextend does **not** mean unlimited growth.

Always check:

```text
Filesystem / ASM Capacity
        ↓
Datafile MAXSIZE
        ↓
Tablespace Capacity
        ↓
Application Growth
```

---

# 9. Monitoring Tablespace Usage

## Basic Tablespace Information

```sql
SELECT
    tablespace_name,
    status,
    contents,
    extent_management,
    segment_space_management
FROM dba_tablespaces
ORDER BY tablespace_name;
```

---

## Datafile Information

```sql
SELECT
    tablespace_name,
    file_name,
    ROUND(bytes/1024/1024) AS size_mb,
    autoextensible,
    ROUND(maxbytes/1024/1024) AS max_size_mb
FROM dba_data_files
ORDER BY tablespace_name;
```

---

# 10. Tablespace Usage Query

```sql
SELECT
    df.tablespace_name,
    ROUND(df.total_mb,2) total_mb,
    ROUND(df.total_mb - NVL(fs.free_mb,0),2) used_mb,
    ROUND(NVL(fs.free_mb,0),2) free_mb,
    ROUND(
        ((df.total_mb - NVL(fs.free_mb,0)) / df.total_mb) * 100,
        2
    ) used_pct
FROM
(
    SELECT tablespace_name,
           SUM(bytes)/1024/1024 total_mb
    FROM dba_data_files
    GROUP BY tablespace_name
) df
LEFT JOIN
(
    SELECT tablespace_name,
           SUM(bytes)/1024/1024 free_mb
    FROM dba_free_space
    GROUP BY tablespace_name
) fs
ON df.tablespace_name = fs.tablespace_name
ORDER BY used_pct DESC;
```

---

# 11. Recommended Alert Thresholds

Typical DBA monitoring:

```text
0 ───────── 80% ─────── 90% ─────── 95% ─────── 100%
             │           │
```
