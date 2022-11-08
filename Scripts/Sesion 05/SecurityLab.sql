/*

Vamos a utilizar la base de datos de prueba en Snowflake, denominada
snowflake_sample_data. Si no está esta base de datos dada de alta, se puede
crear de la siguiente forma:

create or replace database snowflake_sample_data from share SFC_SAMPLES.SAMPLE_DATA;

grant imported privileges on database SNOWFLAKE_SAMPLE_DATA to role sysadmin; 

create or replace database security_test;

*/

-- 1 Preparar el ecosistema para trabajar

use role accountadmin;

create or replace database security_test;

create or replace warehouse sec_test_wh 
COMMENT = 'waehouse prueba para seguridad' 
WAREHOUSE_SIZE = 'large' 
AUTO_RESUME = true 
AUTO_SUSPEND = 60 
MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1 SCALING_POLICY = 'STANDARD';

create or replace table lineitem_fact
as
select *
from snowflake_sample_data.tpch_sf10.lineitem;

create or replace table orders
as
select *
from snowflake_sample_data.tpch_sf10.orders;

create or replace table customers
as
select *
from snowflake_sample_data.tpch_sf10.customer;

show tables;

alter warehouse sec_test_wh set warehouse_size ='xsmall';

-- Crear un rol especial para trabajar con los datos
create or replace role dba_junior;

-- asignar el rol de junior_dba al usuario admin;
grant role dba_junior to user admin;

use role dba_junior;

-- asignamos privilegios al nuevo rol que acabamos de crear
use role accountadmin;

-- Datos
grant usage on database security_test to role dba_junior;
grant usage on schema public to role dba_junior;
grant select on all tables in schema security_test.public to role dba_junior;

-- Privilegios futuros
grant select on future tables in schema security_test.public to role dba_junior;

-- Objeto asegurable
grant usage on warehouse sec_test_wh to role dba_junior;

use role dba_junior;

-- Probamos con un par de queries

select *
from customers
limit 10;

select c_nationkey
    , c_name
    , count(o_orderkey) NumOrders
from customers c
    join orders o
        on c.c_custkey = o.o_custkey
group by c_nationkey, c_name
order by 3 desc
limit 100;

-- Creamos una política de enmascaramiento
use role accountadmin;

-- create a masking policy
create or replace masking policy ofusca_texto as (val string) returns string ->
  case
    when current_role() in ('DBA_JUNIOR') then '*******'
    else val
  end;

create or replace masking policy hash_numero as (val number) returns number ->
  case
    when current_role() in ('DBA_JUNIOR') then hash(val)
    else val
  end;

  
-- Aplicamos política de enmascaramiento de texto
alter table customers modify column c_name set masking policy ofusca_texto;

--alter table customers modify column c_name unset masking policy;

--  Aplicamos política de enmascaramiento de número
alter table customers modify column c_acctbal set masking policy hash_numero;

--alter table customers modify column c_acctbal unset masking policy;

select *
from customers
limit 10;

use role dba_junior;

select *
from customers
limit 10;

use role accountadmin;

-- Traemos una tabla nueva para traer las naciones
create or replace table nations
as
select *
from snowflake_sample_data.tpch_sf10.nation;

create or replace row access policy us_data
    as (nation_name varchar) returns boolean ->
case when 
    (
     (current_role() = 'DBA_JUNIOR' or current_role() = 'SLS_AMERICAS')
       and nation_name in ('UNITED STATES','CANADA')
    )
    then true
    else false
end
;

alter table nations add row access policy us_data on (n_name);
--alter table nations drop row access policy us_data;

select *
from nations;

use role dba_junior;

select *
from nations;

-- Pero esto no es escalable

use role accountadmin;

-- usemos una tabla de referencia
create or replace table sales_regions_config
(  sales_mgr_role varchar()
 , COUNTRY varchar()
);

insert into sales_regions_config (SALES_MGR_ROLE, COUNTRY)
values
 ('DBA_JUNIOR', 'UNITED STATES')
,('DBA_JUNIOR', 'CANADA')
,('SLS_AMERICAS', 'UNITED STATES')
,('SLS_AMERICAS', 'CANADA')
;

select *
from salesregions;

-- Let's re-create our row access policy
use role accountadmin;

alter table nations drop row access policy us_data;

create or replace row access policy us_data
    as (nation_name varchar) returns boolean ->
case when 
    (exists
        (select 1 
         from sales_regions_config
         where sales_mgr_role = current_role()
           and country = nation_name 
        )
     )
    then true
    else false
end
;

-- Aplicamos el rol en la tabla de nations
alter table nations add row access policy us_data on (n_name);

select *
from nations;

-- ¿Por qué no trajo nada de datos? ¿está bien?

use role dba_junior;

select *
from nations;

use role accountadmin;

-- ¿Y qué pasa si clonamos una base de datos?

create database security_test_dev clone security_test;

grant all privileges on database security_test_dev to role dba_junior;

use role dba_junior;

use database security_test_dev;

select * 
from nations;

select *
from customers
limit 10;

use role dba_junior; 

select n.n_nationkey
    , max(n_name) Pais
    , max(c_name) Max_Customer
    , min(c_name) Min_Customer
    , sum(l_quantity) Productos
    , (sum(l_extendedprice)-sum(l_discount)) Ventas
from lineitem_fact lf
    join orders o
        on lf.l_orderkey = o.o_orderkey
    join customers c
        on o.o_custkey = c.c_custkey
    join nations n
        on n.n_nationkey = c.c_nationkey
group by n.n_nationkey
;

-- Creemos el rol de ventas
create or replace role sls_americas;

grant role dba_junior to role sls_americas;
grant role sls_americas to user admin;

-- Probamos que sirva el rol
use role sls_americas;

-- Vamos a crear un usuario
use role accountadmin;

create or replace USER IDENTIFIER('"J_VENTAS"') COMMENT = '' PASSWORD = 'SecurityLab@2022' MUST_CHANGE_PASSWORD = false LOGIN_NAME = 'J_VENTAS' FIRST_NAME = 'J' LAST_NAME = 'J' DISPLAY_NAME = 'J_VENTAS' EMAIL = '' DEFAULT_WAREHOUSE = '' DEFAULT_NAMESPACE = '' DEFAULT_ROLE = 'SLS_AMERICAS';

GRANT ROLE sls_americas to user j_ventas;

-- Reset everything
use role accountadmin;

drop database security_test_dev;
drop database security_test;
drop user j_ventas;
drop role dba_junior;
drop role sls_america;
