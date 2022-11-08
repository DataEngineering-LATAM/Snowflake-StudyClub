CREATE OR REPLACE WAREHOUSE COMPUTE_WH 
WITH WAREHOUSE_SIZE = 'MEDIUM' WAREHOUSE_TYPE = 'STANDARD' 
AUTO_SUSPEND = 60 
AUTO_RESUME = TRUE MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 2 
SCALING_POLICY = 'STANDARD';

// Creacion de DB
CREATE OR REPLACE DATABASE Citibike COMMENT = 'Base de datos de prueba Citibike';

Use database Citibike;
use schema public;

// Creando la primera tabla llamada trips
create or replace table trips  
(tripduration integer,
  starttime timestamp,
  stoptime timestamp,
  start_station_id integer,
  start_station_name string,
  start_station_latitude float,
  start_station_longitude float,
  end_station_id integer,
  end_station_name string,
  end_station_latitude float,
  end_station_longitude float,
  bikeid integer,
  membership_type string,
  usertype string,
  birth_year integer,
  gender integer);


CREATE STAGE "CITIBIKE"."PUBLIC".citibike_trips2 
 URL = 's3://snowflake-workshop-lab/citibike-trips-csv' 
 COMMENT = 'Stage Externo para el cargado de datos de Citibike';
 

list @citibike_trips2;

CREATE FILE FORMAT "CITIBIKE"."PUBLIC".CSV 
TYPE = 'CSV' COMPRESSION = 'AUTO' 
FIELD_DELIMITER = ',' 
RECORD_DELIMITER = '\n' 
SKIP_HEADER = 0 
FIELD_OPTIONALLY_ENCLOSED_BY = '\042' 
TRIM_SPACE = FALSE 
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE 
ESCAPE = 'NONE' 
ESCAPE_UNENCLOSED_FIELD = '\134' 
DATE_FORMAT = 'AUTO' 
TIMESTAMP_FORMAT = 'AUTO' NULL_IF = ('') 
COMMENT = 'Formato de archivo para el cargado de los datos de Citibike';


Select $1, $2, $3, $4, $5
From @citibike_trips/trips_2013_0_0_0.csv.gz
(file_format => CSV)
limit 10;


copy into trips 
from @citibike_trips/trips
file_format=CSV;
