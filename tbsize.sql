column USED_MB format 9999999.9
column FREE_MB format 9999999.9
column TOTAL_MB format 9999999
column PCT_USED format 999.9
column PCT_FREE format 999.9
column PCT_MX_FREE format 999.9
COLUMN TBLSPC_NAME FORMAT A15
break on report
compute sum label TOTAL of total_mb used_mb free_mb mx_free_mb on report

SET PAGESIZE 100
SET LINESIZE 150

select
  df.tablespace_name                          "TBLSPC_NAME",
  round (df.totalspace/1024/1024)                                "TOTAL_MB",
  round ((df.totalspace - fs.freespace)/1024/1024,1)               "USED_MB",
  round (fs.freespace/1024/1024,1)                                 "FREE_MB",
--  round (100 * ((df.totalspace - fs.freespace) / df.totalspace),1) "PCT_USED",
  round (100 * (fs.freespace / df.totalspace),1) "PCT_FREE",
  case when ( df.totalmaxspace = 0 OR df.tablespace_name like 'UNDO%' )
    then 0
    else round ((df.totalmaxspace - (df.totalspace - fs.freespace))/1024/1024,1)
    end "MX_FREE_MB",
  case when ( df.totalmaxspace = 0 OR df.tablespace_name like 'UNDO%' )
    then 0
    else round (100 * ((df.totalmaxspace - (df.totalspace - fs.freespace))/df.totalmaxspace),1)
    end "PCT_MX_FREE"
from
   (select
      tablespace_name,
      sum(bytes) TotalSpace,
      sum(maxbytes) TotalMaxSpace
   from
      dba_data_files
   group by
      tablespace_name
   union
   select
      tablespace_name,
      sum(bytes) TotalSpace,
      sum(maxbytes) TotalMaxSpace
   from
      dba_temp_files
   group by
      tablespace_name
   ) df,
   (select
      tablespace_name,
      sum(bytes) FreeSpace,
      0
   from
      dba_free_space
   group by
      tablespace_name
   ) fs
where
   df.tablespace_name = fs.tablespace_name(+)
order by ((df.TotalSpace-fs.FreeSpace)/df.TotalSpace) desc
/
