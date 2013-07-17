/*

Tablespace Size Summary
Created by Seth Miller 2013/07
Version 1.0


This script is used to report the total tablespace size in an Oracle database.
It includes the autoextend space as an aggregate of currently used space and
autoextend space available.

The output denomination of MB, GB or TB can be changed by adding it as a
parameter to the script (i.e. @tbsize.sql GB). MB is the default.


=========  Summary of output  =========  

TBLSPC_NAME =		Tablespace Name
TOTAL_(MB|GB|TB) =	Total currently allocated space
USED_(MB|GB|TB) =	Total currently used space
FREE_(MB|GB|TB) =	Total currently free space
PCT_FREE =		Total currently free percent
MX_FREE_(MB|GB|TB) =	Total autoextensible free space (including currently allocated)
PC_MX_FREE =		Total autoextensible free percent (including currently allocated)

TBLSPC_NAME               TOTAL_MB  USED_MB  FREE_MB PCT_FREE MX_FREE_MB PCT_MX_FREE
------------------------- -------- -------- -------- -------- ---------- -----------
SYSAUX                         690      628       62      9.0      32140        98.0
USERS                          689      655       34      5.0      32113        98.0
SYSTEM                         800      796        4      1.0      31972        98.0
EXAMPLE                        110        2      108     98.0      32866       100.0
UNDOTBS1                       235       13      222     95.0      32755       100.0
TEMP                            93
                          -------- -------- --------          ----------
TOTAL                         2617     2094      430              161846

*/




SET FEEDBACK OFF
SET VERIFY OFF
SET SERVEROUTPUT ON
SET TERMOUT OFF
SET PAGESIZE 100
SET LINESIZE 150

-- Prevent prompting for parameter values
COLUMN p1 new_value 1
COLUMN p2 new_value 2
COLUMN p3 new_value vardenom
SELECT NULL p1, NULL p2, NULL p3 FROM DUAL WHERE  1=2;

-- Format the parameter for consistency
SELECT CASE 
WHEN UPPER('&1') IN ('G','GB') THEN 'GB'
WHEN UPPER('&1') IN ('T','TB') THEN 'TB'
ELSE 'MB'
END p3
FROM DUAL;

SET TERMOUT ON

COLUMN USED_&vardenom FORMAT 9999999
COLUMN FREE_&vardenom FORMAT 9999999
COLUMN TOTAL_&vardenom FORMAT 9999999
COLUMN PCT_USED FORMAT 999.9
COLUMN PCT_FREE FORMAT 999.9
COLUMN PCT_MX_FREE FORMAT 999.9
COLUMN TBLSPC_NAME FORMAT A25
BREAK ON REPORT
COMPUTE SUM LABEL TOTAL OF total_&vardenom used_&vardenom free_&vardenom mx_free_&vardenom ON REPORT

SELECT
  df.tablespace_name										"TBLSPC_NAME",
  CASE '&vardenom'
  WHEN 'GB'
    THEN ROUND (df.totalspace / 1024 / 1024 / 1024)
  WHEN 'TB'
    THEN ROUND (df.totalspace / 1024 / 1024 / 1024 / 1024)
  ELSE
    ROUND (df.totalspace / 1024 / 1024)
  END												"TOTAL_&vardenom",
  CASE '&vardenom'
  WHEN 'GB'
    THEN ROUND ((df.totalspace - fs.freespace) / 1024 / 1024 / 1024)
  WHEN 'TB'
    THEN ROUND ((df.totalspace - fs.freespace) / 1024 / 1024 / 1024 / 1024)
  ELSE
    ROUND ((df.totalspace - fs.freespace) / 1024 / 1024)
  END												"USED_&vardenom",
  CASE '&vardenom'
  WHEN 'GB'
    THEN ROUND (fs.freespace / 1024 / 1024 / 1024)
  WHEN 'TB'
    THEN ROUND (fs.freespace / 1024 / 1024 / 1024 / 1024)
  ELSE
    ROUND (fs.freespace / 1024 / 1024)
  END												"FREE_&vardenom",
  ROUND (100 * (fs.freespace / df.totalspace))							"PCT_FREE",
  CASE '&vardenom'
  WHEN 'GB'
    THEN ROUND ((df.totalmaxspace - (df.totalspace - fs.freespace)) / 1024 / 1024 / 1024)
  WHEN 'TB'
    THEN ROUND ((df.totalmaxspace - (df.totalspace - fs.freespace)) / 1024 / 1024 / 1024 / 1024)
  ELSE
    ROUND ((df.totalmaxspace - (df.totalspace - fs.freespace)) / 1024 / 1024)
  END												"MX_FREE_&vardenom",
  ROUND (100 * ((df.totalmaxspace - (df.totalspace - fs.freespace)) / df.totalmaxspace))	"PCT_MX_FREE"
FROM
   (SELECT
      tablespace_name,
      SUM(bytes) TotalSpace,
      SUM(CASE WHEN maxbytes != 0 THEN maxbytes ELSE bytes END) TotalMaxSpace
   FROM
      dba_data_files
   GROUP BY
      tablespace_name
   UNION
   SELECT
      tablespace_name,
      SUM(bytes) TotalSpace,
      CASE WHEN SUM(maxbytes) = 0 THEN SUM(bytes) END TotalMaxSpace
   FROM
      dba_temp_files
   GROUP BY
      tablespace_name
   ) df,
   (SELECT
      tablespace_name,
      SUM(bytes) FreeSpace,
      0
   FROM
      dba_free_space
   GROUP BY
      tablespace_name
   ) fs
WHERE
   df.tablespace_name = fs.tablespace_name(+)
order by pct_mx_free
/

-- Reset a few sqlplus parameters
SET FEEDBACK ON
SET VERIFY ON
UNDEFINE 1
UNDEFINE 2
UNDEFINE 3
UNDEFINE vardenom
