

/* 
****************************************************************************************************

            C R E A T I N G    S N O W F L A K E   R E S O U R C E   M O N I T O R S

**************************************************************************************************** 
*/
/* 
****************************************************************************************************

                                    Virtual Warehouses Section
                                    
**************************************************************************************************** 
*/

-- Use the SYSADMIN role to create the new virtual warehouses as best practice

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
SHOW WAREHOUSES;

-- Create Snowflake virtual warehouses

CREATE OR REPLACE WAREHOUSE VW2_WH WITH WAREHOUSE_SIZE = MEDIUM
    AUTO_SUSPEND = 300 AUTO_RESUME = true, INITIALLY_SUSPENDED=true;
    
CREATE OR REPLACE WAREHOUSE VW3_WH WITH WAREHOUSE_SIZE = SMALL
    AUTO_SUSPEND = 300 AUTO_RESUME = true, INITIALLY_SUSPENDED=true;
    
CREATE OR REPLACE WAREHOUSE VW4_WH WITH WAREHOUSE_SIZE = MEDIUM
    AUTO_SUSPEND = 300 AUTO_RESUME = true, INITIALLY_SUSPENDED=true;
    
CREATE OR REPLACE WAREHOUSE VW5_WH WITH WAREHOUSE_SIZE = SMALL
    AUTO_SUSPEND = 300 AUTO_RESUME = true, INITIALLY_SUSPENDED=true;
    
CREATE OR REPLACE WAREHOUSE VW6_WH WITH WAREHOUSE_SIZE = MEDIUM
    AUTO_SUSPEND = 300 AUTO_RESUME = true, INITIALLY_SUSPENDED=true;
    
    
/* 
****************************************************************************************************

                                    Resouce Monitors Section

  CREATE RESOURCE MONITOR - Assigns virtual warehouse(s) to a resource monitor
  ALTER RESOURCE MONITOR - Modifies an existing resource monitor
  SHOW RESOURCE MONITOR - Views an existing resource monitor
  DROP RESOURCE MONITOR - Deletes an existing resource monitor

**************************************************************************************************** 
*/    

USE ROLE ACCOUNTADMIN;
SHOW RESOURCE MONITORS;

-- ACCOUNT LEVEL -------------------------------------------------------------------------------------------------------
-- Snowflake resource monitors can only be created viewed, and maintained by the ACCOUNTADMIN role by default
-- Unless you are setting the monitor at the account level, you need to assign at least one virtual warehouse to the resource monitor.
-- Let’s first create an account-level resource monitor.

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE RESOURCE MONITOR MONITOR1_RM WITH CREDIT_QUOTA = 5000
    TRIGGERS on 50 percent do notify
             on 75 percent do notify
             on 100 percent do notify
             on 110 percent do notify
             on 125 percent do notify;



-- After we created the resource monitor, we’ll need to assign it to our Snowflake account

USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT SET RESOURCE_MONITOR = MONITOR1_RM;


-- WHSE LEVEL -----------------------------------------------------------------------------------------------------------
-- Next, we’ll create a virtual warehouse–level monitor.
-- We want to create the resource monitor for one of our priority virtual warehouses,
-- We’ll use the same notify actions for the priority virtual warehouse as we did for the account-level resource monitor. 

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE RESOURCE MONITOR MONITOR5_RM WITH CREDIT_QUOTA = 1500
    TRIGGERS on 50 percent do notify
             on 75 percent do notify
             on 100 percent do notify
             on 110 percent do notify
             on 125 percent do notify;             
ALTER WAREHOUSE VW2_WH SET RESOURCE_MONITOR = MONITOR5_RM;

-- Create a second resource monitor

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE RESOURCE MONITOR MONITOR2_RM WITH CREDIT_QUOTA = 500
    TRIGGERS on 50 percent do notify
             on 75 percent do notify
             on 100 percent do notify
             on 100 percent do suspend
             on 110 percent do notify
             on 110 percent do suspend_immediate;             
ALTER WAREHOUSE VW3_WH SET RESOURCE_MONITOR = MONITOR2_RM;


//-- Everything is good thus far. Now let’s purposely make a mistake to see what happens.
//-- We’ll create a resource monitor and assign it to a virtual warehouse, and then we’ll create another resource monitor and assign it to the same virtual warehouse.
//-- We know that a virtual warehouse can only be assigned to one resource monitor,
//
//USE ROLE ACCOUNTADMIN;
//CREATE OR REPLACE RESOURCE MONITOR MONITOR6_RM WITH CREDIT_QUOTA = 500
//    TRIGGERS on 50 percent do notify
//             on 75 percent do notify
//             on 100 percent do notify
//             on 100 percent do suspend
//             on 110 percent do notify
//             on 110 percent do suspend_immediate;             
//ALTER WAREHOUSE VW6_WH SET RESOURCE_MONITOR = MONITOR6_RM;
//
//
//-- You’ll notice from our planning diagram that we don’t have a sixth resource monitor planned, so it was a mistake to create the sixth resource monitor.
//USE ROLE ACCOUNTADMIN;
//CREATE OR REPLACE RESOURCE MONITOR MONITOR4_RM WITH CREDIT_QUOTA = 500
//    TRIGGERS on 50 percent do notify
//             on 75 percent do notify
//             on 100 percent do notify
//             on 100 percent do suspend
//             on 110 percent do notify
//             on 110 percent do suspend_immediate;             
//ALTER WAREHOUSE VW6_WH SET RESOURCE_MONITOR = MONITOR4_RM;
//
//
//
//-- The statement was executed successfully. So, let’s run a SHOW RESOURCE MONITORS command and see the results,
//-- We can see that the sixth resource monitor appears to have nullified when we assigned the fourth resource monitor to the virtual warehouse.
//USE ROLE ACCOUNTADMIN;
//SHOW RESOURCE MONITORS;
//SHOW WAREHOUSES;
//
//-- We can now get rid of the resource monitor we created in error:
//DROP RESOURCE MONITOR MONITOR6_RM;


-- Create a resource monitor for WM#6

CREATE OR REPLACE RESOURCE MONITOR MONITOR4_RM WITH CREDIT_QUOTA = 500
    TRIGGERS on 50 percent do notify
             on 75 percent do notify
             on 100 percent do notify
             on 100 percent do suspend
             on 110 percent do notify
             on 110 percent do suspend_immediate;             
ALTER WAREHOUSE VW6_WH SET RESOURCE_MONITOR = MONITOR4_RM;


-- Let’s create the last resource monitor from our planning diagram. We’ll assign the resource monitor to two virtual warehouses:
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE RESOURCE MONITOR MONITOR3_RM WITH CREDIT_QUOTA = 1500
    TRIGGERS on 50 percent do notify
             on 75 percent do notify
             on 100 percent do notify
             on 100 percent do suspend
             on 110 percent do notify
             on 110 percent do suspend_immediate;             
ALTER WAREHOUSE VW4_WH SET RESOURCE_MONITOR = MONITOR3_RM;
ALTER WAREHOUSE VW5_WH SET RESOURCE_MONITOR = MONITOR3_RM;


--
USE ROLE ACCOUNTADMIN;
SHOW WAREHOUSES;
SHOW RESOURCE MONITORS;



//SELECT "name", "size"
//FROM TABLE (RESULT_SCAN(LAST_QUERY_ID()))
//WHERE "resource_monitor" = 'null';




/* 
****************************************************************************************************

                       Q U E R Y I N G   T H E  "ACCOUNT_USAGE" V I E W

**************************************************************************************************** 
*/


 -- To get more granular detail about virtual warehouse costs, we can leverage queries on the Snowflake ACCOUNT_USAGE view.
 -- Access to the ACCOUNT_USAGE view is given only to the ACCOUNTADMIN role by default.  
 -- This query provides the individual details of cost, based on virtual warehouse start times and assuming $3.00 as the credit price:

    
USE ROLE ACCOUNTADMIN;

SET CREDIT_PRICE = 3.00;
USE DATABASE SNOWFLAKE;
USE SCHEMA ACCOUNT_USAGE;
SELECT  WAREHOUSE_NAME, START_TIME, END_TIME, CREDITS_USED,
    ($CREDIT_PRICE*CREDITS_USED) AS DOLLARS_USED                         
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
ORDER BY START_TIME DESC;


-- This query summarizes the costs of each virtual warehouse for the past 30 days, assuming $3.00 as the credit price as set in the previous query

SELECT WAREHOUSE_NAME,SUM(CREDITS_USED_COMPUTE)
    AS CREDITS_USED_COMPUTE_30DAYS,
    ($CREDIT_PRICE*CREDITS_USED_COMPUTE_30DAYS) AS DOLLARS_USED_30DAYS
FROM ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY 2 DESC;





- ****************************************************************************************************
-- Delete all resources and warehouses

DROP RESOURCE MONITOR MONITOR1_RM;
DROP RESOURCE MONITOR MONITOR2_RM;
DROP RESOURCE MONITOR MONITOR3_RM;
DROP RESOURCE MONITOR MONITOR4_RM;
DROP RESOURCE MONITOR MONITOR5_RM;
SHOW RESOURCE MONITORS;

DROP WAREHOUSE VW2_WH;
DROP WAREHOUSE VW3_WH;
DROP WAREHOUSE VW4_WH;
DROP WAREHOUSE VW5_WH;
DROP WAREHOUSE VW6_WH;
SHOW WAREHOUSES;




