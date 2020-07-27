# 注意:以下的部分脚本会有参数,所有参数会以**{参数}**标注,请勿直接复制粘贴

### 查找可能的死锁进程(查找锁进程)

```sql
SELECT request_session_id spid,OBJECT_NAME(resource_associated_entity_id)tableName
FROM sys.dm_tran_locks
WHERE resource_type='OBJECT '
```
### 查找对应连接会话所执行的sql

```sql
SELECT session_id, TEXT
FROM sys.dm_exec_connections c
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) AS ST 
WHERE c.session_id = **{session_id}**
```
### 通过mdf和ldf创建数据库

```sql
CREATE DATABASE **{name of db}**   
-- eg: 'C:\workspace\data\mydb_new.mdf'
ON (FILENAME = '**{path to mdf file}'),   
-- eg: 'C:\workspace\data\mydb_new_log.ldf'
(FILENAME = 'C:\Users\lulus\workspace\data\AppsDB_new_log.ldf')   
FOR ATTACH;  
```

### 批量禁用外键 Foreign key(用于临时脏数据清理)

```sql
-- Disable all the constraint in database
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
**{your maintenance sql goes here}**
-- Enable all the constraint in database
EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
```
