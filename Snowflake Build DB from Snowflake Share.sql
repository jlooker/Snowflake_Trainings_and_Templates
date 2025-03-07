------------------------------------------------------------------------
-- GRANT IMPORTED PRIVILEGES TO ALL ROLES USING THE ACCOUNTADMIN ROLE --
------------------------------------------------------------------------

USE ROLE ACCOUNTADMIN;

GRANT IMPORTED PRIVILEGES ON DATABASE <database_name> TO ROLE SYSADMIN;

GRANT IMPORTED PRIVILEGES ON DATABASE <database_name> TO ROLE SECURITYADMIN;

GRANT IMPORTED PRIVILEGES ON DATABASE <database_name> TO ROLE USERADMIN;


-------------------------------------------------------
-- CREATE THE NEW WAREHOUSE USING THE SYSADMIN ROLE --
-------------------------------------------------------

USE ROLE SYSADMIN;

CREATE WAREHOUSE <warehouse_name>
    WAREHOUSE_SIZE = XSMALL
    MAX_CLUSTER_COUNT = 1
    MIN_CLUSTER_COUNT = 1
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;


---------------------------------------------------------------------
-- CREATE THE NEW <database_name> DATABASE USING THE SYSADMIN ROLE --
---------------------------------------------------------------------

USE ROLE SYSADMIN;

CREATE DATABASE <database_name>;


-----------------------------------------------------------------
-- CREATE THE NEW <schema_name> SCHEMA USING THE SYSADMIN ROLE --
-----------------------------------------------------------------

USE ROLE SYSADMIN;

CREATE SCHEMA <database_name>.<schema_name>;


---------------------------------------------------------
-- CREATE RESOURCE MONITOR USING THE ACCOUNTADMIN ROLE --
---------------------------------------------------------

-- Only the ACCOUNTADMIN role has this privilege by default
USE ROLE ACCOUNTADMIN;


-- Create the resource monitor
-- Proper naming convention for creating a resource monitor is to prepend "RM_" before the resource monitor name (i.e. RM_<resource_monitor_name>)
CREATE OR REPLACE RESOURCE MONITOR RM_<resource_monitor_name>
WITH
	CREDIT_QUOTA = <max_#_of_monthly_credits>
	FREQUENCY = MONTHLY
	START_TIMESTAMP = IMMEDIATELY
	NOTIFY_USERS =
	(
		<username_1>
		,<username_2>
		,<username_n>
	)
	-- Upto 5 notify triggers are able to be assigned to a resource monitor
	TRIGGERS
		ON 50 PERCENT DO NOTIFY
		ON 75 PERCENT DO NOTIFY
		ON 90 PERCENT DO NOTIFY
		ON 100 PERCENT DO SUSPEND
		ON 110 PERCENT DO SUSPEND_IMMEDIATE
;


-- Assign the resource monitor to the account by altering the account
ALTER ACCOUNT SET RESOURCE_MONITOR = RM_<resource_monitor_name>
;<database_name>.INFORMATION_SCHEMA