#!/bin/sh

# ------------------------------#
# Oracle - Zabbix Info (CRMALL) #
#                               #
# Josue Pirolo 03/2015          #
# ------------------------------#
##
## Menu
## Execute the Following:
## 1 - zabbix_info.sh oracle_env
## 2 - zabbix_info.sh verify_user_zabbix
##
##
# Variables

# Tools
DATA=$(date +%Y-%m-%d)
DATA_HORA=$(date +%Y-%m-%d-%H_%M_%S)
CAT=$(which cat)
GREP=$(which grep)
SED=$(which sed)
CUT=$(which cut)
DATE=$(which date)
HEAD=$(which head)
WC=$(which wc)
SQLPLUS=$(which sqlplus)
RM=$(which rm)

# Config Files Path
CONFIG_FILE="/var/lib/zabbix/scripts/oracle-zabbix/config_user"
ORACLE_FILE="/var/lib/zabbix/scripts/oracle-zabbix/config_oracle"
##

##
# functions

function password () {

echo "Informe o usuario SYSADMIN"
read SYSTEM

echo "Informe a senha do Usuario SYSTEM"
read -s SYSTEM_PASS
}

function verify_user_zabbix () {
#
password
#
# Continuando com os passos seguintes
#
RETORNO=$($SQLPLUS -S ${SYSTEM}/${SYSTEM_PASS} as sysdba  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT COUNT(USERNAME) FROM DBA_USERS WHERE USERNAME ='ZABBIX';
EOF
)
#echo $RETORNO
##
##
if [ ${RETORNO} -eq 1 ]; then
  echo "Usuario existente"
  exit 0
else
  echo "Usuario nao existe...Inicializando processo de criacao"
  gen_pass_for_zabbix
fi
}

function gen_pass_for_zabbix () {

echo "Criando usuario zabbix"


GEN_PASS=$(${DATE} +%s | sha256sum | base64 | ${HEAD} -c 12 ; echo)

echo "USERNAME=\"zabbix"\" > ${CONFIG_FILE}
echo "PASSWORD=\"${GEN_PASS}"\" >> ${CONFIG_FILE}

PASSWORD_ZABBIX=$(${CAT} ${CONFIG_FILE}  | ${GREP} PASS | ${CUT} -d'"' -f2)

echo "CREATE PROFILE CRMALL_3 LIMIT
COMPOSITE_LIMIT                  UNLIMITED
SESSIONS_PER_USER                UNLIMITED
CPU_PER_SESSION                  UNLIMITED
CPU_PER_CALL                     UNLIMITED
LOGICAL_READS_PER_SESSION        UNLIMITED
LOGICAL_READS_PER_CALL           UNLIMITED
IDLE_TIME                        UNLIMITED
CONNECT_TIME                     UNLIMITED
PRIVATE_SGA                      UNLIMITED
FAILED_LOGIN_ATTEMPTS            10
PASSWORD_LIFE_TIME               UNLIMITED
PASSWORD_REUSE_TIME              UNLIMITED
PASSWORD_REUSE_MAX               UNLIMITED
PASSWORD_VERIFY_FUNCTION         NULL
PASSWORD_LOCK_TIME               1
PASSWORD_GRACE_TIME              7
/
CREATE USER ZABBIX
IDENTIFIED BY \"${PASSWORD_ZABBIX}\" 
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
PROFILE DEFAULT
ACCOUNT UNLOCK
/
GRANT ALTER SESSION TO ZABBIX
/
GRANT CREATE SESSION TO ZABBIX
/
GRANT CONNECT TO ZABBIX
/
ALTER USER ZABBIX DEFAULT ROLE ALL
/
GRANT ALTER USER TO ZABBIX
/
GRANT CREATE PROCEDURE TO ZABBIX
/
GRANT SELECT ON V_\$INSTANCE TO ZABBIX
/
GRANT SELECT ON DBA_USERS TO ZABBIX
/
GRANT SELECT ON V_\$LOG_HISTORY TO ZABBIX
/
GRANT SELECT ON V_\$PARAMETER TO ZABBIX
/
GRANT SELECT ON SYS.DBA_AUDIT_SESSION TO ZABBIX
/
GRANT SELECT ON V_\$LOCK TO ZABBIX
/
GRANT SELECT ON DBA_REGISTRY TO ZABBIX
/
GRANT SELECT ON V_\$LIBRARYCACHE TO ZABBIX
/
GRANT SELECT ON V_\$SYSSTAT TO ZABBIX
/
GRANT SELECT ON V_\$PARAMETER TO ZABBIX
/
GRANT SELECT ON V_\$LATCH TO ZABBIX
/
GRANT SELECT ON V_\$PGASTAT TO ZABBIX
/
GRANT SELECT ON V_\$SGASTAT TO ZABBIX
/
GRANT SELECT ON V_\$LIBRARYCACHE TO ZABBIX
/
GRANT SELECT ON V_\$PROCESS TO ZABBIX
/
GRANT SELECT ON DBA_DATA_FILES TO ZABBIX
/
GRANT SELECT ON DBA_TEMP_FILES TO ZABBIX
/
GRANT SELECT ON DBA_FREE_SPACE TO ZABBIX
/
GRANT SELECT ON V_\$SYSTEM_EVENT TO ZABBIX
/
GRANT EXECUTE ON DBMS_NETWORK_ACL_ADMIN TO ZABBIX
/
GRANT SELECT ON SYS.V_\$SESSION TO ZABBIX
/
GRANT SELECT ON SYS.V_\$SHARED_SERVER TO ZABBIX
/
GRANT SELECT ON SYS.V_\$SESSION TO ZABBIX
/
GRANT SELECT ON SYS.DBA_OBJECTS TO ZABBIX
/
GRANT SELECT ON SYS.DBA_DATA_FILES TO ZABBIX
/
GRANT SELECT ON SYS.DBA_SEGMENTS TO ZABBIX
/
GRANT SELECT ON SYS.DBA_TABLESPACES TO ZABBIX
/
GRANT SELECT ON SYS.V_\$DATABASE TO ZABBIX
/
GRANT SELECT ON SYS.V_\$ARCHIVED_LOG TO ZABBIX
/
GRANT SELECT ON SYS.V_\$PARAMETER TO ZABBIX
/
GRANT SELECT ON SYS.V_\$PGASTAT TO ZABBIX
/
GRANT SELECT ON SYS.V_\$SGASTAT TO ZABBIX
/
GRANT SELECT ON SYS.V_\$SYSTEM_EVENT TO ZABBIX
/
GRANT SELECT ON SYS.DBA_USERS TO ZABBIX
/
GRANT SELECT ON SYS.V_\$LOG_HISTORY TO ZABBIX
/
GRANT SELECT ON SYS.V_\$DATABASE TO ZABBIX
/
GRANT SELECT ON SYS.DBA_INDEXES TO ZABBIX
/
GRANT SELECT ON V_\$ROWCACHE TO ZABBIX
/
GRANT SELECT ON V_\$PARAMETER TO ZABBIX
/
GRANT SELECT ON V_\$STATNAME TO ZABBIX
/
GRANT SELECT ON V_\$SESSTAT TO ZABBIX
/
GRANT SELECT ON DBA_ROLE_PRIVS TO ZABBIX
/
GRANT SELECT ON DBA_ROLES TO ZABBIX
/
ALTER USER SYSTEM PROFILE CRMALL_3
/
-- ALTER USER CRMALL PROFILE CRMALL_3
-- /
-- ALTER USER CLIENTE PROFILE CRMALL_3
-- /
ALTER USER CORREIO PROFILE CRMALL_3
/
CREATE OR REPLACE FUNCTION ZABBIX.FUNC_USERNAME_LIST(PA_OPTION VARCHAR2) RETURN VARCHAR2 IS
V_CRMALL_USER DBA_USERS.USERNAME%TYPE;
V_CLIENTE_USER DBA_USERS.USERNAME%TYPE;
BEGIN

    SELECT USERNAME INTO V_CRMALL_USER FROM DBA_USERS WHERE USERNAME LIKE '%CRMALL%';
    --
    SELECT USERNAME INTO V_CLIENTE_USER FROM DBA_USERS WHERE USERNAME LIKE '%CLIENTE%';
    
    IF PA_OPTION = 'CRMALL' THEN 
    RETURN V_CRMALL_USER;
    ELSIF PA_OPTION = 'CLIENTE' THEN
    RETURN V_CLIENTE_USER;
    END IF;
END;
/
CREATE OR REPLACE PROCEDURE ZABBIX.PROC_USERNAME_PROFILE IS
BEGIN
    EXECUTE IMMEDIATE ('ALTER USER '||(FUNC_USERNAME_LIST('CRMALL'))||' PROFILE CRMALL_3');
    --
    EXECUTE IMMEDIATE ('ALTER USER '||(FUNC_USERNAME_LIST('CLIENTE'))||' PROFILE CRMALL_3');
END;
/
EXECUTE ZABBIX.PROC_USERNAME_PROFILE()
/
QUIT
/" > /var/lib/zabbix/scripts/oracle-zabbix/Criar_usuario_zabbix.sql
##
##
echo " "
$SQLPLUS -S ${SYSTEM}/${SYSTEM_PASS} as sysdba @Criar_usuario_zabbix.sql
$RM -f Criar_usuario_zabbix.sql
echo "Completed Sucessfully"
##
##
}
##
## Load Oracle Profile
function oracle_env () {
DIR1="/u01" # Oracle XE - Versao 11g
DIR2="/usr/lib/oracle" # Oracle XE - Versao 10g
##
if [ -d ${DIR1} ]; then
	#
	FIND1=$(find ${DIR1} -name oracle_env.sh)
	#
   ${CAT} ${FIND1} > config_oracle
	#
   . $ORACLE_FILE
elif [ -d ${DIR2} ]; then
	#
	FIND2=$(find ${DIR2} -name oracle_env.sh)
	#
	${CAT} ${FIND2} > config_oracle
	#
   . $ORACLE_FILE
else
	echo "Oracle Database not installed ou it is a Oracle SE1,SE or EE."
fi
}
##
## Load Zabbix User Variables #
if [ -f $CONFIG_FILE ]; then
      . $CONFIG_FILE            #
      echo "Usuario Zabbix Existente, pronto para utilizar"

else
      echo "Creating  Zabbix User Config File..."
      verify_user_zabbix

fi
##                    #
##
function total_tbs_crmall() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT SUM(DT.BYTES)
FROM DBA_DATA_FILES DT
INNER JOIN  DBA_USERS U
ON U.DEFAULT_TABLESPACE = DT.TABLESPACE_NAME
AND DT.TABLESPACE_NAME LIKE '%CRMALL%'
AND U.PROFILE NOT IN ('DEFAULT','MONITORING_PROFILE','CRMALL_4C_CLIENTES_USER','HOMOLOGACAO','CRMALL_4C_INTERNO_USER');
 
EOF
}

function total_tbs_cliente() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT SUM(DT.BYTES)
FROM DBA_DATA_FILES DT
INNER JOIN  DBA_USERS U
ON U.DEFAULT_TABLESPACE = DT.TABLESPACE_NAME
AND DT.TABLESPACE_NAME LIKE '%CLIENTE%' 
AND U.PROFILE NOT      IN ('DEFAULT','MONITORING_PROFILE','CRMALL_4C_CLIENTES_USER','HOMOLOGACAO','CRMALL_4C_INTERNO_USER');
EOF
}

function total_tbs_correio() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT SUM(DT.BYTES)
FROM DBA_DATA_FILES DT
INNER JOIN  DBA_USERS U
ON U.DEFAULT_TABLESPACE = DT.TABLESPACE_NAME
AND DT.TABLESPACE_NAME LIKE '%CORREIO%'
AND U.PROFILE NOT      IN ('DEFAULT','MONITORING_PROFILE','CRMALL_4C_CLIENTES_USER','HOMOLOGACAO','CRMALL_4C_INTERNO_USER');
EOF
}

function total_tbs_system() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT SUM(DT.BYTES)
FROM DBA_DATA_FILES DT
INNER JOIN  DBA_USERS U
ON U.DEFAULT_TABLESPACE = DT.TABLESPACE_NAME
AND DT.TABLESPACE_NAME LIKE '%SYSTEM%'
AND U.PROFILE NOT      IN ('DEFAULT','MONITORING_PROFILE','CRMALL_4C_CLIENTES_USER','HOMOLOGACAO','CRMALL_4C_INTERNO_USER');
EOF
}

function lista_tablespace() {
cd /var/lib/zabbix/scripts/

$SQLPLUS -S $USERNAME/$PASSWORD>tablespaces 2>&1 <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT DT.TABLESPACE_NAME FROM DBA_TABLESPACES DT INNER JOIN
DBA_USERS U ON DT.TABLESPACE_NAME = U.DEFAULT_TABLESPACE AND  U.PROFILE NOT IN ('MONITORING_PROFILE','DEFAULT','CRMALL_4C_CLIENTES_USER','HOMOLOGACAO')
AND DT.TABLESPACE_NAME <> 'USERS'
ORDER BY USERNAME
/
--SELECT DEFAULT_TABLESPACE FROM DBA_USERS WHERE PROFILE = 'CRMALL_4C_CLIENTES';
EOF


TOTAL=`cat tablespaces | wc -l`
i=0

# Cria lista JSON

echo "{" > lista_tablespaces
echo "  \"data\":[" >> lista_tablespaces

for X in `cat tablespaces`; do

i=$((i+1))


if [ $TOTAL -eq $i ]; then
echo "  { \"{#TABLESPACE}\":\"${X}\"}" >> lista_tablespaces
else
echo "  { \"{#TABLESPACE}\":\"${X}\"}," >> lista_tablespaces
fi
done

echo "   ]" >> lista_tablespaces
echo "}" >> lista_tablespaces

rm tablespaces

exit 0;

}


function lista_users() {
cd /var/lib/zabbix/scripts/

$SQLPLUS -S $USERNAME/$PASSWORD>users 2>&1 <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT U.USERNAME FROM DBA_USERS U WHERE  U.PROFILE NOT IN ('MONITORING_PROFILE','DEFAULT','HOMOLOGACAO','SYSTEM')
ORDER BY U.USERNAME
/
EOF


TOTALUSER=`cat users | wc -l`
ii=0

# Cria lista JSON

echo "{" > lista_users
echo "  \"data\":[" >> lista_users

for X in `cat users`; do

ii=$((ii+1))


if [ $TOTALUSER -eq $ii ]; then
echo "  { \"{#USER}\":\"${X}\"}" >> lista_users
else
echo "  { \"{#USER}\":\"${X}\"}," >> lista_users
fi
done

echo "   ]" >> lista_users
echo "}" >> lista_users

rm users

exit 0;

}

function used_tbs_crmall() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT
  SUM(BYTES)
FROM
  DBA_SEGMENTS
WHERE
  TABLESPACE_NAME = (SELECT DEFAULT_TABLESPACE FROM DBA_USERS WHERE USERNAME LIKE '%CRMALL%' AND PROFILE NOT IN ('DEFAULT','MONITORING_PROFILE'))
GROUP BY
  TABLESPACE_NAME;
EOF
}

function used_tbs_cliente() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT
  SUM(BYTES)
FROM
  DBA_SEGMENTS
WHERE
  TABLESPACE_NAME = (SELECT DEFAULT_TABLESPACE FROM DBA_USERS WHERE USERNAME LIKE '%CLIENTE%' AND PROFILE NOT IN ('DEFAULT','MONITORING_PROFILE'))
GROUP BY
  TABLESPACE_NAME;
EOF
}

function used_tbs_correio() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT
  SUM(BYTES)
FROM
  DBA_SEGMENTS
WHERE
  TABLESPACE_NAME = (SELECT DEFAULT_TABLESPACE FROM DBA_USERS WHERE USERNAME LIKE '%CORREIO%' AND PROFILE NOT IN ('DEFAULT','MONITORING_PROFILE'))
GROUP BY
  TABLESPACE_NAME;
EOF
}

function used_tbs_system() {

$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set numformat 99999999999999999999
SELECT
  SUM(BYTES)
FROM
  DBA_SEGMENTS
WHERE
  TABLESPACE_NAME = (SELECT DEFAULT_TABLESPACE FROM DBA_USERS WHERE USERNAME LIKE '%SYSTEM%' AND PROFILE NOT IN ('DEFAULT','MONITORING_PROFILE'))
GROUP BY
  TABLESPACE_NAME;
EOF
}

function account_status_crmall() {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT
  CASE
    WHEN ACCOUNT_STATUS = 'OPEN'
    THEN '0'
    WHEN ACCOUNT_STATUS = 'LOCKED'
    THEN '1'
    WHEN ACCOUNT_STATUS = 'EXPIRED'
    THEN '2'
    WHEN ACCOUNT_STATUS = 'EXPIRED(GRACE)'
    THEN '3'
    WHEN ACCOUNT_STATUS = 'LOCKED(TIME)'
    THEN '4'
    END AS ACCOUNT_STATUS
    FROM DBA_USERS
WHERE USERNAME = (SELECT USERNAME FROM DBA_USERS WHERE USERNAME LIKE '%CRMALL%' AND PROFILE NOT IN ('DEFAULT','MONITORING_PROFILE'))
/
EOF
}

function account_status_cliente() {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT
  CASE
    WHEN ACCOUNT_STATUS = 'OPEN'
    THEN '0'
    WHEN ACCOUNT_STATUS = 'LOCKED'
    THEN '1'
    WHEN ACCOUNT_STATUS = 'EXPIRED'
    THEN '2'
    WHEN ACCOUNT_STATUS = 'EXPIRED(GRACE)'
    THEN '3'
    WHEN ACCOUNT_STATUS = 'LOCKED(TIME)'
    THEN '4'
    END AS ACCOUNT_STATUS
    FROM DBA_USERS
WHERE USERNAME = (SELECT USERNAME FROM DBA_USERS WHERE USERNAME LIKE '%CLIENTE%' AND PROFILE NOT IN ('DEFAULT','MONITORING_PROFILE'))
/
EOF
}

function account_status_correio() {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT
  CASE
    WHEN ACCOUNT_STATUS = 'OPEN'
    THEN '0'
    WHEN ACCOUNT_STATUS = 'LOCKED'
    THEN '1'
    WHEN ACCOUNT_STATUS = 'EXPIRED'
    THEN '2'
    WHEN ACCOUNT_STATUS = 'EXPIRED(GRACE)'
    THEN '3'
    WHEN ACCOUNT_STATUS = 'LOCKED(TIME)'
    THEN '4'
    END AS ACCOUNT_STATUS
    FROM DBA_USERS
WHERE USERNAME = (SELECT USERNAME FROM DBA_USERS WHERE USERNAME LIKE '%CORREIO%' AND PROFILE NOT IN ('DEFAULT','MONITORING_PROFILE'))
/
EOF
}

function account_status_system() {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT
  CASE
    WHEN ACCOUNT_STATUS = 'OPEN'
    THEN '0'
    WHEN ACCOUNT_STATUS = 'LOCKED'
    THEN '1'
    WHEN ACCOUNT_STATUS = 'EXPIRED'
    THEN '2'
    WHEN ACCOUNT_STATUS = 'EXPIRED(GRACE)'
    THEN '3'
    WHEN ACCOUNT_STATUS = 'LOCKED(TIME)'
    THEN '4'
    END AS ACCOUNT_STATUS
    FROM DBA_USERS
WHERE USERNAME = (SELECT USERNAME FROM DBA_USERS WHERE USERNAME LIKE '%SYSTEM%' AND PROFILE NOT IN ('DEFAULT','MONITORING_PROFILE'))
/
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
SELECT OBJECT_NAME FROM DBA_OBJECTS WHERE STATUS = 'INVALID' AND OWNER = '$1';
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
SELECT TRIM(SUBSTR(BANNER,1,(INSTR(BANNER,' ',20)))) AS DB_VERSION FROM V\$VERSION WHERE BANNER LIKE '%Oracle Database%';
EOF
}

function db_release () {
$SQLPLUS -S $USERNAME/$PASSWORD  <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT TRIM(REGEXP_REPLACE(SUBSTR(BANNER,(INSTR(BANNER,'.',4))-2),'[^12357890.]+', '')) AS DB_RELEASE FROM V\$VERSION WHERE BANNER LIKE '%Oracle Database%';
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

case $1 in
                "oracle_env")
                           oracle_env
                           ;;
                        
                "gen_pass_for_zabbix")
                           gen_pass_for_zabbix
                           ;;
                        
                "verify_user_zabbix")
                           verify_user_zabbix 
                           ;;

                "lista_tablespace")
                          lista_tablespace
                           ;;

                "lista_users")
                           lista_users
                           ;;

                "total_tbs_crmall")
                           total_tbs_crmall
                           ;;

                "total_tbs_cliente")
                           total_tbs_cliente
                           ;;

                "total_tbs_correio")
                           total_tbs_correio
                           ;;

                "total_tbs_system")
                           total_tbs_system
                           ;;

                "used_tbs_crmall")
                           used_tbs_crmall
                           ;;

                "used_tbs_cliente")
                           used_tbs_cliente
                           ;;

                "used_tbs_correio")
                           used_tbs_correio
                           ;;

                "used_tbs_system")
                           used_tbs_system
                           ;;

                "database_name")
                           database_name
                           ;;

                "objetos_invalidos")
                           objetos_invalidos $2
                             ;;

                "usuarios_3_conectados")
                           usuarios_3_conectados |  wc -l
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
                           db_version
                           ;;

                "db_release")
                           db_release
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

                "account_status_crmall")
                           account_status_crmall
                           ;;

                "account_status_cliente")
                           account_status_cliente
                           ;;

                "account_status_correio")
                           account_status_correio
                           ;;

                "account_status_system")
                           account_status_system
                           ;;

                           *)
                echo "Informe um argumento"
                           ;;

esac
exit 0
