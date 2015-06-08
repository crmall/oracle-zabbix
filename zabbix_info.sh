#!/bin/sh

# ---------------------------------------------------#
# Oracle - Zabbix Info (CRMALL)							  #
#																	  #
# Josue Pirolo & Robson Mantovani - 03/2015			  #
# ---------------------------------------------------#
# Variables

# Oracle Paths
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export ORACLE_SID=XE
export NLS_LANG=`$ORACLE_HOME/bin/nls_lang.sh`
export PATH=$ORACLE_HOME/bin:$PATH

# Config File

CONFIG_FILE="/var/lib/zabbix/scripts/oracle-zabbix/zabbix_info_conf"

# Carrega configuracoes
if [ -f ${CONFIG_FILE} ]; then
   . ${CONFIG_FILE}
else
   echo "Sem arquivo de configuracao..."
   exit 1
fi


SQLPLUS=`which sqlplus`
DATA=$(date +%Y-%m-%d)
DATA_HORA=$(date +%Y-%m-%d-%H_%M_%S)

####

# functions



function show_options () {
LIST1=$(cat zabbix_info.sh | grep function | cut -d" " -f2 |sed -e 's/([^()]*)//g'  | sed 's/\<functions\>//g' | sed 's/\<show_options\>//g'| sed '/^$/d')
}


function total_size_tbs_crmall() {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT BYTES FROM DBA_DATA_FILES WHERE TABLESPACE_NAME LIKE '%CRMALL%';
EOF
}

function total_size_tbs_cliente() {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT BYTES FROM DBA_DATA_FILES WHERE TABLESPACE_NAME LIKE '%CLIENTE%';
EOF
}

function total_size_tbs_correio() {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT BYTES FROM DBA_DATA_FILES WHERE TABLESPACE_NAME LIKE '%CORREIO%';
EOF
}

function total_size_tbs_system() {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT BYTES FROM DBA_DATA_FILES WHERE TABLESPACE_NAME LIKE '%SYSTEM%';
EOF
}

function lista_tablespace() {
cd /var/lib/zabbix/scripts

$SQLPLUS -S $USERNAME/$PASSWORD>tablespaces_3 2>&1 <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT DISTINCT DT.TABLESPACE_NAME FROM DBA_TABLESPACES DT INNER JOIN
DBA_USERS U ON DT.TABLESPACE_NAME = U.DEFAULT_TABLESPACE AND  U.USERNAME IN (SELECT USERNAME FROM DBA_USERS WHERE USERNAME LIKE '%CRMALL%' OR USERNAME LIKE '%CLIENTE%' OR USERNAME LIKE '%CORREIO%' OR USERNAME LIKE '%SYSTEM%')
ORDER BY DT.TABLESPACE_NAME
/
EOF


TOTAL=`cat tablespaces_3 | wc -l`
i=0

# Cria lista JSON

echo "{" > lista_tablespaces_3
echo "  \"data\":[" >> lista_tablespaces_3

for X in `cat tablespaces_3`; do

i=$((i+1))


if [ $TOTAL -eq $i ]; then
echo "  { \"{#TABLESPACE}\":\"${X}\"}" >> lista_tablespaces_3
else
echo "  { \"{#TABLESPACE}\":\"${X}\"}," >> lista_tablespaces_3
fi
done

echo "   ]" >> lista_tablespaces_3
echo "}" >> lista_tablespaces_3

rm tablespaces_3

exit 0;

}

function used_tablespace_crmall() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT SUM(DS.BYTES) FROM DBA_SEGMENTS DS
INNER JOIN DBA_TABLESPACES DT
ON DT.TABLESPACE_NAME = DS.TABLESPACE_NAME
AND DS.TABLESPACE_NAME LIKE '%CRMALL%'
GROUP BY DS.TABLESPACE_NAME;
EOF
}

function used_tablespace_cliente() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT SUM(DS.BYTES) FROM DBA_SEGMENTS DS
INNER JOIN DBA_TABLESPACES DT
ON DT.TABLESPACE_NAME = DS.TABLESPACE_NAME
AND DS.TABLESPACE_NAME LIKE '%CLIENTE%'
GROUP BY DS.TABLESPACE_NAME;
EOF
}

function used_tablespace_correio() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT SUM(DS.BYTES) FROM DBA_SEGMENTS DS
INNER JOIN DBA_TABLESPACES DT
ON DT.TABLESPACE_NAME = DS.TABLESPACE_NAME
AND DS.TABLESPACE_NAME LIKE '%CORREIO%'
GROUP BY DS.TABLESPACE_NAME;
EOF
}

function used_tablespace_system() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT SUM(DS.BYTES) FROM DBA_SEGMENTS DS
INNER JOIN DBA_TABLESPACES DT
ON DT.TABLESPACE_NAME = DS.TABLESPACE_NAME
AND DS.TABLESPACE_NAME LIKE '%SYSTEM%'
GROUP BY DS.TABLESPACE_NAME;
EOF
}



function database_name() {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT NAME FROM V\$DATABASE;
EOF
}

function objetos_invalidos() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT OBJECT_NAME FROM DBA_OBJECTS WHERE STATUS = 'INVALID' AND OWNER = 'CRMALL_CPSAJ' AND OBJECT_NAME NOT LIKE '%SYS%' AND OBJECT_NAME NOT LIKE '%BIN%';
EOF
}

function usuarios_4c_conectados() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT VS.SID FROM DBA_USERS U INNER JOIN V\$SESSION VS
ON VS.USER# = U.USER_ID
AND U.PROFILE IN ('CRMALL_4C_CLIENTES','CRMALL_4C_CLIENTES_USER')
/
EOF
}

function usuarios_3_conectados () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT VS.SID FROM DBA_USERS U INNER JOIN V\$SESSION VS
ON VS.USER# = U.USER_ID
AND U.PROFILE IN ('CRMALL_3_CLIENTES')
/
EOF
}

function usuarios_antecipado_conectados () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT VS.SID FROM DBA_USERS U INNER JOIN V\$SESSION VS
ON VS.USER# = U.USER_ID
AND U.PROFILE = ('ANTECIPADO')
/
EOF
}

function usuarios_baseunica_conectados () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT VS.SID FROM DBA_USERS U INNER JOIN V\$SESSION VS
ON VS.USER# = U.USER_ID
AND U.PROFILE = ('BASE_UNICA')
/
EOF
}

function db_archivelog_status () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select (log_mode) from v\$database where log_mode = 'ARCHIVELOG';
EOF
}

function db_archived_last () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT NVL(MAX(TO_CHAR(COMPLETION_TIME,'DD/MM/YY HH24:MI:SS')),'None')
FROM V\$ARCHIVED_LOG
WHERE TO_CHAR(COMPLETION_TIME,'DD/MM/YY') = TO_CHAR(SYSDATE,'DD/MM/YY')
AND TO_CHAR(COMPLETION_TIME,'HH24')       = TO_CHAR(SYSDATE,'HH24');
EOF
}

function db_archivelog_last_seq () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT (SEQUENCE#) FROM V\$ARCHIVED_LOG WHERE TO_CHAR(COMPLETION_TIME,'DD/MM/YY') = TO_CHAR(SYSDATE,'DD/MM/YY') AND TO_CHAR(COMPLETION_TIME,'HH24') = TO_CHAR(SYSDATE,'HH24');
EOF
}

function db_alive () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT 'ALIVE' FROM DUAL;
EOF
}

function db_total_size () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
col SUM(BYTES) format 999999999999999
SELECT SUM(BYTES) FROM DBA_DATA_FILES;
EOF
}

function db_used_size () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
col SUM(BYTES) format 999999999999999
SELECT SUM(BYTES) FROM DBA_SEGMENTS;
EOF
}

function db_version () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT SUBSTR(BANNER,1,(INSTR(BANNER,'-',-4))) FROM V\$VERSION WHERE BANNER LIKE '%Oracle Database%';
EOF
}

function db_release () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT SUBSTR(BANNER,20,(INSTR(BANNER,' ',30))) FROM V\$VERSION WHERE BANNER LIKE '%Oracle%Release%';
EOF
}

function index_invalid () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT INDEX_NAME FROM DBA_INDEXES WHERE STATUS = 'UNUSABLE' AND OWNER = '$1';
EOF
}

function waits_controlfileio () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(sum(decode(event,'control file sequential read', total_waits, 'control file single write', total_waits, 'control file parallel write',total_waits,0))) ControlFileIO FROM V\$system_event WHERE 1=1 AND event not in ( 'SQL*Net message from client', 'SQL*Net more data from client','pmon timer', 'rdbms ipc message', 'rdbms ipc reply', 'smon timer');
EOF
}

function waits_directpath_read () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(sum(decode(event,'direct path read',total_waits,0))) DirectPathRead FROM V\$system_event WHERE 1=1 AND event not in (   'SQL*Net message from ', 'SQL*Net more data from client','pmon timer', 'rdbms ipc message', 'rdbms ipc reply', 'smon timer');
EOF
}

function waits_file_io () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(sum(decode(event,'file identify',total_waits, 'file open',total_waits,0))) FileIO FROM V\$system_event WHERE 1=1 AND event not in (   'SQL*Net message from client',   'SQL*Net more data from client', 'pmon timer', 'rdbms ipc message', 'rdbms ipc reply', 'smon timer');
EOF
}

function waits_latch () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(sum(decode(event,'control file sequential read', total_waits, 
'control file single write', total_waits, 'control file parallel write',total_waits,0))) ControlFileIO 
FROM V\$system_event WHERE 1=1 AND event not in ( 
  'SQL*Net message from client', 
  'SQL*Net more data from client', 
  'pmon timer', 'rdbms ipc message', 
  'rdbms ipc reply', 'smon timer');
EOF
 }
  
function waits_logwrite () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(sum(decode(event,'log file single write',total_waits, 'log file parallel write',total_waits,0))) LogWrite 
FROM V\$system_event WHERE 1=1 AND event not in ( 
  'SQL*Net message from client', 
  'SQL*Net more data from client', 
  'pmon timer', 'rdbms ipc message', 
  'rdbms ipc reply', 'smon timer');
EOF
}

function waits_multiblock_read () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(sum(decode(event,'db file scattered read',total_waits,0))) MultiBlockRead 
FROM V\$system_event WHERE 1=1 AND event not in ( 
  'SQL*Net message from client', 
  'SQL*Net more data from client', 
  'pmon timer', 'rdbms ipc message', 
  'rdbms ipc reply', 'smon timer');
EOF
}

function waits_other () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF  
SELECT to_char(sum(decode(event,'control file sequential read',0,'control file single write',0,'control file parallel write',0,'db file sequential read',0,'db file scattered read',0,'direct path read',0,'file identify',0,'file open',0,'SQL*Net message to client',0,'SQL*Net message to dblink',0, 'SQL*Net more data to client',0,'SQL*Net more data to dblink',0, 'SQL*Net break/reset to client',0,'SQL*Net break/reset to dblink',0, 'log file single write',0,'log file parallel write',0,total_waits))) Other FROM V\$system_event WHERE 1=1 AND event not in (  'SQL*Net message from client', 'SQL*Net more data from client', 'pmon timer', 'rdbms ipc message',  'rdbms ipc reply', 'smon timer');
EOF
}

function waits_singleblock_read () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(sum(decode(event,'db file sequential read',total_waits,0))) SingleBlockRead 
FROM V\$system_event WHERE 1=1 AND event not in ( 
  'SQL*Net message from client', 
  'SQL*Net more data from client', 
  'pmon timer', 'rdbms ipc message', 
  'rdbms ipc reply', 'smon timer');
EOF
}

function waits_sqlnet () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(sum(decode(event,'SQL*Net message to client',total_waits,'SQL*Net message to dblink',total_waits,'SQL*Net more data to client',total_waits,'SQL*Net more data to dblink',total_waits,'SQL*Net break/reset to client',total_waits,'SQL*Net break/reset to dblink',total_waits,0))) SQLNET FROM V\$system_event WHERE 1=1 AND event not in ( 'SQL*Net message from client','SQL*Net more data from client','pmon timer','rdbms ipc message','rdbms ipc reply', 'smon timer');
EOF
}

function pga_aggregat_target () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select decode( unit,'bytes', value, value) value from V\$PGASTAT where name in 'aggregate PGA target parameter';
EOF
}

function pga () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select decode( unit,'bytes', value, value) value from V\$PGASTAT where name in 'total PGA inuse';
EOF
}

function sga_buffer_cache () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(ROUND(SUM(decode(pool,NULL,decode(name,'db_block_buffers',(bytes),'buffer_cache',(bytes),0),0)),2)) sga_bufcache FROM V\$SGASTAT;
EOF
}

function sga_fixed () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT  (bytes) used_shard_pool  FROM V\$SGASTAT WHERE NAME ='free memory'  and pool = 'java pool';
EOF
}

function sga_java_pool () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT to_char(ROUND(SUM(decode(pool,'java pool',(bytes))),2)) sga_jpool FROM V\$SGASTAT;
EOF
}

function sga_large_pool () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT  bytes used_shard_pool  FROM V\$SGASTAT WHERE NAME ='free memory'  and pool = 'large pool';
EOF
}

function sga_log_buffer () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT TO_CHAR(ROUND(SUM(decode(pool,NULL,decode(name,'log_buffer',(bytes),0),0)),2)) sga_lbuffer FROM V\$SGASTAT;
EOF
}

function sga_shared_pool_total () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT (spu.BYTES)+(spf.BYTES) as " "
from
(SELECT  sum(bytes) as BYTES  FROM V\$SGASTAT WHERE NAME !='free memory'  and pool = 'shared pool') spu,
(SELECT sum(bytes) as BYTES FROM V\$SGASTAT WHERE NAME ='free memory'  and pool = 'shared pool') spf;
EOF
}

function sga_shared_pool_used () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT  sum(bytes) as " "  FROM V\$SGASTAT WHERE NAME !='free memory'  and pool = 'shared pool';
EOF
}

function sga_shared_pool_free () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT  (bytes) as " "  FROM V\$SGASTAT WHERE NAME ='free memory'  and pool = 'shared pool';
EOF
}

function sga_target () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT VALUE FROM V\$PARAMETER WHERE NAME = 'sga_target';
EOF
}

function sga_max_size () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT VALUE FROM V\$PARAMETER WHERE NAME = 'sga_max_size';
EOF
}

function sga_free () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select  sum(bytes) as " "
From V\$sgastat
Where Name Like '%free memory%';
EOF
}

function sga_used () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
select sum(bytes) as " " from v\$sgastat where name!='free memory';
EOF
}

function db_hit_rate () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT ROUND(((1 - (SUM(GETMISSES) / (SUM(GETS) + SUM(GETMISSES)))) * 100),0 ) "Hit Rate"
FROM V\$ROWCACHE
WHERE GETS                                           + GETMISSES <> 0;
EOF
}

function session_cached_cursor_value () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select
  -- 'session_cached_cursors'  parameter
   lpad(value, 5)  value
   -- ,used
   -- ,decode(value, 0, '  n/a', to_char(100 * used / value, '990') || '%')  usage
from
  ( select
      max(s.value)  used
    from
      v\$statname  n,
      v\$sesstat  s
    where
      n.name = 'session cursor cache count' and
      s.statistic# = n.statistic#
  ),
  ( select
      value
    from
      v\$parameter
    where
      name = 'session_cached_cursors'
  );
EOF
}

function session_cached_cursor_used () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select
  -- 'session_cached_cursors'  parameter
  --  lpad(value, 5)  value
     used
   -- ,decode(value, 0, '  n/a', to_char(100 * used / value, '990') || '%')  usage
from
  ( select
      max(s.value)  used
    from
      v\$statname  n,
      v\$sesstat  s
    where
      n.name = 'session cursor cache count' and
      s.statistic# = n.statistic#
  ),
  ( select
      value
    from
      v\$parameter
    where
      name = 'session_cached_cursors'
  );
EOF
}

function session_cached_cursor_pct_used () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select
  -- 'session_cached_cursors'  parameter
  --  lpad(value, 5)  value
 --    used
   decode(value, 0, '  n/a', to_char(100 * used / value, '990') /*|| '%'*/)  usage
from
  ( select
      max(s.value)  used
    from
      v\$statname  n,
      v\$sesstat  s
    where
      n.name = 'session cursor cache count' and
      s.statistic# = n.statistic#
  ),
  ( select
      value
    from
      v\$parameter
    where
      name = 'session_cached_cursors'
  );
EOF
}

function open_cursors_total () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select
--  'open_cursors',
    lpad(value, 5)
--  used,
--  to_char(100 * used / value,  '990') /*|| '%*/ AS PCT_USED
from
  ( select
      max(sum(s.value))  used
    from
      v\$statname  n,
      v\$sesstat  s
    where
      n.name in ('opened cursors current') and
      s.statistic# = n.statistic#
    group by
      s.sid
  ),
  ( select
      value
    from
      v\$parameter
    where
      name = 'open_cursors'
  )
;
EOF
}

function open_cursors_used () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select
--  'open_cursors',
--     lpad(value, 5)
  used
--  to_char(100 * used / value,  '990') /*|| '%*/ AS PCT_USED
from
  ( select
      max(sum(s.value))  used
    from
      v\$statname  n,
      v\$sesstat  s
    where
      n.name in ('opened cursors current') and
      s.statistic# = n.statistic#
    group by
      s.sid
  ),
  ( select
      value
    from
      v\$parameter
    where
      name = 'open_cursors'
  )
;
EOF
}

function open_cursors_pct_used () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
select
--  'open_cursors',
--     lpad(value, 5)
--  used
  to_char(100 * used / value,  '990')  AS PCT_USED
from
  ( select
      max(sum(s.value))  used
    from
      v\$statname  n,
      v\$sesstat  s
    where
      n.name in ('opened cursors current') and
      s.statistic# = n.statistic#
    group by
      s.sid
  ),
  ( select
      value
    from
      v\$parameter
    where
      name = 'open_cursors'
  )
;
EOF
}

function qtd_estacoes_online () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT COUNT(DISTINCT(MACHINE)) FROM V\$SESSION WHERE USERNAME IS NOT NULL AND TERMINAL   <> 'unknown' AND TERMINAL NOT LIKE '%pts/%'; 
EOF
}

function usuarios_crmall_online () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT  COUNT(DISTINCT(SID))  FROM V\$SESSION WHERE USERNAME IS NOT NULL AND TERMINAL <> 'unknown';
EOF
}

function usuarios_wiseit_online () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT  COUNT(DISTINCT(SID))  FROM V\$SESSION WHERE OSUSER = 'wiseit';
EOF
}

case $1 in
							"lista_tablespace")
													 lista_tablespace 
													 ;;

							  "total_size_tbs_crmall")
													 total_size_tbs_crmall
													 ;;

							  "total_size_tbs_cliente")
													 total_size_tbs_cliente
													 ;;

							  "total_size_tbs_correio")
													 total_size_tbs_correio
													 ;;

							  "total_size_tbs_system")
													 total_size_tbs_system
													 ;;

						   "used_tablespace_crmall")
													 used_tablespace_crmall
													 ;;

						   "used_tablespace_cliente")
													 used_tablespace_cliente
													 ;;

						   "used_tablespace_correio")
													 used_tablespace_correio
													 ;;

						   "used_tablespace_system")
													 used_tablespace_system
													 ;;

							   "database_name")
													 database_name
													 ;;

						  "objetos_invalidos")
													 objetos_invalidos $2 
							  						 ;;

					 "usuarios_4c_conectados")
										  			 usuarios_4c_conectados | wc -l
							  						 ;;

					  "usuarios_3_conectados")
										 			 usuarios_3_conectados |  wc -l
							  						 ;;

		  "usuarios_antecipado_conectados")
										  			 usuarios_antecipado_conectados |  wc -l
													 ;;

		  "usuarios_baseunica_conectados")
										  			 usuarios_baseunica_conectados |  wc -l
													 ;;

					  "db_archivelog_status")
										  			db_archivelog_status |  wc -l
													 ;;

  						   "db_archived_last")
 										  			db_archived_last
													 ;;

				   "db_archivelog_last_seq")
										  			db_archivelog_last_seq | tail -1 |sed 's/  *//g'
													 ;;

					   			  "db_alive")
										  			db_alive | wc -l
													 ;;

					   			  "db_total_size")
										  			db_total_size |  sed 's/  *//g'
													 ;;

					   			  "db_used_size")
										  			db_used_size |  sed 's/  *//g'
													 ;;

					   			  "db_version")
										  			db_version | cut -d- -f1  | awk {'print $1,$2,$3}'
													 ;;

					   			  "db_release")
										  			db_release | cut -d- -f1 | awk {'print $5}'
													 ;;

					   		  "index_invalid")
										  			 index_invalid $2
													 ;;

			   		  "waits_controlfileio")
										  			 waits_controlfileio 
													 ;;

  		   		   "waits_directpath_read")
										  			 waits_directpath_read 
													 ;;

					   		  "waits_file_io")
										  			 waits_file_io 
													 ;;

					   		    "waits_latch")
										  			 waits_latch 
													 ;;

					   	    "waits_logwrite")
										  			 waits_logwrite
													 ;;

					   "waits_multiblock_read")
										  			 waits_multiblock_read
													 ;;

					   		    "waits_other")
										  			 waits_other
													 ;;

			        "waits_singleblock_read")
										  			 waits_singleblock_read
													 ;;

					   		   "waits_sqlnet")
										  			 waits_sqlnet
													 ;;
						   					
					     "pga_aggregat_target")
										  			 pga_aggregat_target
													 ;;
						   					
					                     "pga")
										  			 pga
													 ;;
						   					
							  "sga_buffer_cache")
										  			 sga_buffer_cache
													 ;;
						   					
										"sga_fixed")
										  			 sga_fixed
													 ;;
						   					
								  "sga_java_pool")
										  			 sga_java_pool
													 ;;
						   					
								 "sga_large_pool")
										  			 sga_large_pool
													 ;;
						   					
								 "sga_log_buffer")
										  			 sga_log_buffer
													 ;;
						   					
								"sga_shared_pool_total")
										  			 sga_shared_pool_total
													 ;;
						   					
								"sga_shared_pool_used")
										  			 sga_shared_pool_used
													 ;;
						   					
								"sga_shared_pool_free")
										  			 sga_shared_pool_free
													 ;;
						   					
								     "sga_target")
										  			 sga_target
													 ;;
						   					
									"sga_max_size")
										  			 sga_max_size
													 ;;
						   					
	  									 "sga_free")
										  			 sga_free
													 ;;
						   					
									    "sga_used")
										  			 sga_used
													 ;;
						   					
									"db_hit_rate")
										  			 db_hit_rate
													 ;;
						   					
				"session_cached_cursor_value")
										  			 session_cached_cursor_value
													 ;;
						   					
				"session_cached_cursor_used")
										  			 session_cached_cursor_used
													 ;;
						   					
				"session_cached_cursor_pct_used")
										  			 session_cached_cursor_pct_used
													 ;;
						   					
  				        "open_cursors_total")
										  			 open_cursors_total
													 ;;
						   					
  				        "open_cursors_used")
										  			 open_cursors_used
													 ;;
						   					
                 "open_cursors_pct_used")
										  			 open_cursors_pct_used
													 ;;
						   					
                 "qtd_estacoes_online")
										  			 qtd_estacoes_online
													 ;;
						   					
                 "usuarios_crmall_online")
										  			 usuarios_crmall_online
													 ;;
						   					
                 "usuarios_wiseit_online")
										  			 usuarios_wiseit_online
													 ;;
						   					
												    *)
											       echo "Argumento Invalido"
													 show_options
										          echo " Utilize apenas um desses: ${LIST1}"| more
												    ;;		

esac


exit 0
