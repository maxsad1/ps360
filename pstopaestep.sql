REM pstopaestep.sql
DEF recname = 'BAT_TIMINGS_DTL'
@@psrecdefn
DEF lrecname = '&&lrecname._top&&date_filter_suffix'
DEF recdescr = '&&recdescr. Application Engine steps profiled by time &&date_filter_desc'
DEF descrlong = 'Application Engine step batch timings, aggregated by step and profiled by total time &&date_filter_desc'

BEGIN
  :sql_text_stub := '
WITH a AS (
SELECT a.bat_program_name||''.''||a.detail_id detail_id
,      COUNT(distinct a.process_instance) executions
,      SUM(a.compile_time)/1000 compile_time
,      SUM(a.compile_count) compile_count
,      SUM(a.fetch_time)/1000 fetch_time
,      SUM(a.fetch_count) fetch_count
,      SUM(a.retrieve_time)/1000 retrieve_time
,      SUM(a.retrieve_count) retrieve_count
,      SUM(a.execute_time)/1000 execute_time
,      SUM(a.execute_count) execute_count
,      SUM(a.peoplecodesqltime)/1000 pc_sqltime
,      SUM(a.peoplecodetime)/1000 pc_time
,      SUM(a.peoplecodecount) pc_count
,      SUM(a.execute_time +a.compile_time +a.fetch_time +a.retrieve_time)/1000 ae_sqltime
,      SUM(a.execute_time +a.compile_time +a.fetch_time +a.retrieve_time+a.peoplecodesqltime)/1000 sqltime
,      SUM(a.execute_time +a.compile_time +a.fetch_time +a.retrieve_time+a.peoplecodesqltime +a.peoplecodetime)/1000 total_time
FROM   ps_bat_timings_dtl a, ps_bat_timings_log b
WHERE  a.process_instance = b.process_instance &&date_filter_sql
GROUP BY a.bat_program_name, a.detail_id
), b AS (
SELECT rank() OVER (ORDER BY total_time desc, sqltime desc) as stmtrank
,      a.*
,      RATIO_TO_REPORT(sqltime) OVER () as ratio_sqltime
,      RATIO_TO_REPORT(total_time) OVER () as ratio_total_time
FROM   a
WHERE  sqltime >0 OR execute_count >0
), x AS (
SELECT stmtrank
,      detail_id
,      execute_count
,      ae_sqltime
,      pc_sqltime
,      pc_time
,      total_time
,      100*ratio_sqltime pct_sqltime
,      100*SUM(ratio_sqltime) OVER (ORDER BY stmtrank RANGE UNBOUNDED PRECEDING) cum_pc_sqltime
,      100*ratio_total_time pct_total_time
,      100*SUM(ratio_total_time) OVER (ORDER BY stmtrank RANGE UNBOUNDED PRECEDING) cum_pc_total_time
FROM   b
)';
END;
/

COLUMN stmtrank          HEADING 'Stmt|Rank'        NEW_VALUE row_num
COLUMN detail_id         HEADING 'Statement ID'   
COLUMN pct_sqltime       HEADING '%|SQL|Time'       FORMAT 990.0 
COLUMN pct_total_time    HEADING '%|Total|Time'     FORMAT 990.0 
COLUMN cum_pc_sqltime    HEADING 'Cum %|SQL|Time'   FORMAT 990.0 
COLUMN cum_pc_total_time HEADING 'Cum %|Total|Time' FORMAT 990.0 
COLUMN executions        HEADING 'Num|Execs'        FORMAT 99990
COLUMN compile_time      HEADING 'Compile|Time'     FORMAT 99990.0
COLUMN compile_count     HEADING 'Compile|Count'    FORMAT 99990
COLUMN fetch_time        HEADING 'Fetch|Time'       FORMAT 99990.0
COLUMN fetch_count       HEADING 'Fetch|Count'      FORMAT 99990
COLUMN retrieve_time     HEADING 'Retrieve|Time'    FORMAT 99990.0
COLUMN retrieve_count    HEADING 'Retrieve|Count'   FORMAT 99990
COLUMN execute_time      HEADING 'Exec|Time'        FORMAT 99990.0
COLUMN execute_count     HEADING 'Exec|Count'       FORMAT 99990
COLUMN ae_sqltime        HEADING 'AE|SQL|Time'      FORMAT 99990.0
COLUMN pc_sqltime        HEADING 'PC|SQL|Time'      FORMAT 99990.0
COLUMN pc_time           HEADING 'PC|Time'          FORMAT 99990.0
COLUMN pc_count          HEADING 'PC|Count'         FORMAT 99990
COLUMN total_time        HEADING 'Total|Time'       FORMAT 99990.0

DEF piex="Statement ID"
DEF piey="Total Time (seconds)"

BEGIN
  :sql_text := :sql_text_stub||'
SELECT '',[''''''||x.detail_id||'''''',''||x.total_time||'']''
FROM   x
ORDER BY x.total_time desc
'; 
END;				
/

REM DECODE(rownum,1,'''','','')||
@@psgenericpie.sql


BEGIN
  :sql_text := :sql_text_stub||'
SELECT x.*
FROM   x
ORDER BY stmtrank
'; 
END;				
/

@@psgenerichtml.sql
