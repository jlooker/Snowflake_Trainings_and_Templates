------------------------------------------------------------------
-- CREATE THE NEW RL_<role_name> ROLE USING THE USERADMIN ROLE --
------------------------------------------------------------------

USE ROLE USERADMIN;

CREATE OR REPLACE ROLE RL_<role_name>;


---------------------------------------------------------
-- GRANT THE RL_<role_name> ROLE TO THE <role_name> ROLE --
---------------------------------------------------------

USE ROLE ACCOUNTADMIN;

GRANT ROLE RL_<role_name>
   TO ROLE <role_name>;


----------------------------------------------------------------------------------------------
-- GRANT THE NEW RL_<role_name> ROLE ACCESS TO THE WAREHOUSES USING THE SECURITYADMIN ROLE --
----------------------------------------------------------------------------------------------

USE ROLE SECURITYADMIN;

GRANT USAGE ON WAREHOUSE <warehouse_name>
TO ROLE RL_<role_name>;


----------------------------------------------------------------------
-- GRANT A ROLE ACCESS TO THE DATABASE USING THE SECURITYADMIN ROLE --
----------------------------------------------------------------------

USE ROLE SECURITYADMIN;

GRANT USAGE ON DATABASE <database_name>
TO ROLE RL_<role_name>;


-----------------------------------------------------------------------
-- GRANT A ROLE ACCESS TO THE SCHEMA(S) USING THE SECURITYADMIN ROLE --
-----------------------------------------------------------------------

USE ROLE SECURITYADMIN;

GRANT USAGE ON SCHEMA <database_name>.<schema_name>
TO ROLE RL_<role_name>;

GRANT USAGE ON FUTURE SCHEMAS IN DATABASE <database_name>
TO ROLE RL_<role_name>;

GRANT ALL ON FUTURE TABLES IN SCHEMA <database_name>.<schema_name>
TO ROLE RL_<role_name>;

GRANT ALL ON FUTURE VIEWS IN SCHEMA <database_name>.<schema_name>
TO ROLE RL_<role_name>;


-----------------------------------------------------------------------------------------------
-- GRANT THE NEW RL_<role_name> ROLE THE NECESSARY PRIVILEGE(S) USING THE ACCOUNTADMIN ROLE --
-----------------------------------------------------------------------------------------------

USE ROLE ACCOUNTADMIN;

GRANT IMPORTED PRIVILEGES ON DATABASE <database_name> TO ROLE RL_<role_name>;

-- GRANT PRIVILEGE TO CREATE NEW SCHEMAS WITHIN THE <database_name> DATABASE
GRANT CREATE SCHEMA ON DATABASE <database_name>
TO ROLE RL_<role_name>;

-- GRANT PRIVILEGE TO CREATE NEW PROCEDURES WITHIN THE <database_name> DATABASE
GRANT MODIFY PROCEDURE ON SCHEMA <database_name>.PUBLIC
TO ROLE RL_<role_name>;

-- GRANT PRIVILEGE TO MODIFY THE NEW <schema_name> SCHEMA WITHIN THE <database_name> DATABASE
GRANT MODIFY ON SCHEMA <database_name>.<schema_name>
TO ROLE RL_<role_name>;