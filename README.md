# Zabbix Oracle Template

## Introdução

Template do Zabbix para monitoramento de Banco de dados Oracle CRMALL3.

Os scripts devem ser instalados no servidor do banco de dados Oracle.

**Atenção:** os seguintes itens serão monitorados através do Template:

- `Tablespaces`
- `Usuários`
- `Objetos Inválidos`
- `Indexes Inválidos`
- `User role violation`
- `Alive`
- `Name`
- `Tamanho`
- `Versão`
- `Archive Log`
- `Hit Rate`
- `Open Cursors`
- `PGA/SGA`
- `Session Cached Cursor`
- `Users Connected`
- `Waits`
- `Index Location`

## Requisitos

- Zabbix **3.0**
- Zabbix Agent **3.0**
- Oracle Database 
- CRMALL 3

## Instalação 

1. Crie o diretorio `/var/lib/zabbix/scripts` para armazenar o script e os arquivos criados por ele.

```sh 
mkdir -p /var/lib/zabbix/scripts/
chown -R oracle:dba /var/lib.zabbix/scripts/
```
1. Baixe os scripts

```sh
git clone git clone https://github.com/crmall/oracle-zabbix.git
``` 

1. Execute a primeira vez `sh zabbix.sh oracle_env` para criar o usuário zabbix com os GRANTS necessários e definir a váriavel ORACLE_HOME 

1. Copie `userparameter_oracle.conf` para dentro do diretório `zabbix_agentd.d` e reinicie o `zabbix-agent`

1. Importe o template `Template_BS2_Oracle.xml` para dentro de seu Zabbix Server e adicione ao host. 

## Creditos

Criado por Josué Pirolo em 04/2016
