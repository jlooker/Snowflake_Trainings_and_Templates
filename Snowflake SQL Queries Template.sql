/****************************************************************************************************/
-- 
/****************************************************************************************************/


/****************************************************************************************************/
-- Create New User
/****************************************************************************************************/

	---------------------------------------------------------------------------------------------
	-- CREATE THE NEW USER WHO WILL HAVE ACCESS TO THE KKF MAIN DATA WAREHOUSE ------------------
	-- NEW USERS TO THE KKF MAIN DATA WAREHOUSE SHOULD ONLY BE GIVEN TO PEOPLE MANAGED BY JOSH --
	-- THIS WILL ENSURE DATA INTEGRITY AND SECURITY ---------------------------------------------
	---------------------------------------------------------------------------------------------

	USE ROLE USERADMIN;

	CREATE USER <User_Name>
		PASSWORD = 'Snowflake2024!'
		EMAIL = '<KKF_Email_Address>'
		DEFAULT_SECONDARY_ROLES = ('ALL')
		MUST_CHANGE_PASSWORD = TRUE
	;


	-----------------------------------------------------------------------------------------
	-- GRANT THE NEW USER ACCESS(ES) TO THE NECESSARY ROLE(S) USING THE SECURITYADMIN ROLE --
	-----------------------------------------------------------------------------------------

	USE ROLE SECURITYADMIN
	;

	GRANT ROLE <Role_Name>
	TO USER <User_Name>
	;


	-------------------------------------------------------------------------
	-- ALTER THE NEW USER TO SET DEFAULT SETTINGS USING THE USERADMIN ROLE --
	-------------------------------------------------------------------------

	USE ROLE USERADMIN
	;

	ALTER USER <User_Name>
		SET
			DEFAULT_ROLE = <Role_Name>
			DEFAULT_NAMESPACE = <Database_Name>.<Schema_Name>
			DEFAULT_WAREHOUSE = <Warehouse_Name>
	;


/****************************************************************************************************/
-- External Access Integration
/****************************************************************************************************/


	/*
		Resource: https://docs.snowflake.com/en/developer-guide/external-network-access/creating-using-external-network-access
	*/

	/*
		Step 1: Create a secret representing credentials
	*/


	USE ROLE SYSADMIN
	;

	CREATE OR REPLACE SECRET SECRET_YEXT_API_KEY
		TYPE = GENERIC_STRING
		SECRET_STRING = 'f6ad6b5cdaeaebf2f93f137a00fda365'
	;


	/*
		Step 2: Create a network rule representing the external network location
	*/


	USE ROLE SYSADMIN
	;

	CREATE OR REPLACE NETWORK RULE NETWORK_RULE_EXTERNAL_API
		-- Allows Snowflake to send requests to an external destination
		MODE = EGRESS
		-- indicates that the network rule will allow outgoing network traffic based on the domain of the request destination
		TYPE = HOST_PORT
		-- List all of the API and SFTP domains, separated by a commna (,), that Snowflake would need to access for ELT purposes
		VALUE_LIST =
		(
			'https://cdn.yextapis.com'
		)
	;


	/*
		Step 3: Create an external access integration using the secret and network rule
	*/


	USE ROLE ACCOUNTADMIN
	;

	CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ACCESS_INTEGRATION_YEXT_API
		ALLOWED_NETWORK_RULES = (NETWORK_RULE_EXTERNAL_API)
		ALLOWED_AUTHENTICATION_SECRETS = (SECRET_YEXT_API_KEY)
		ENABLED = true
	;


	/*
		Step 4: Create the DB_KKF_MAIN.PUBLIC.SP_YEXT_REVIEW_DATA_LOAD() procedure that store the Python data pipeline code
	*/


	-- Create the SP_YEXT_REVIEW_DATA_LOAD stored procedure that will extract tha raw data from the DB_KKF_MAIN.TRANSIENT.YEXT_OPERATOR_REVIEW table
	-- Transforms the data and loads into the DB_KKF_MAIN.YEXT.OPERATOR_REVIEW table
	CREATE OR REPLACE PROCEDURE DB_KKF_MAIN.PUBLIC.SP_YEXT_REVIEW_DATA_LOAD()
		/***** Required Parameters *****/
		-- Specify STRING as the data type to be returned, if data will be returned by the procedure once it is completed
		-- The RETURNS clause must be included and a return type defined, even if the procedure does not explicitly return anything.
		RETURNS STRING
		-- Specify Python as the coding language to be executed within the procedure
		LANGUAGE PYTHON
		-- Use the following query to see which Runtime Version you need
			-- SELECT * FROM DB_KKF_MAIN.INFORMATION_SCHEMA.PACKAGES WHERE LANGUAGE = 'python';
				-- See what Runtime Version is needed for all of the pagckages listed in the PACKAGES variable
		RUNTIME_VERSION = 3.9
		-- List all of the packages needed to run the Python code below
		-- This will ensure that all packages required to run the Python code are installed before the Python code is executed
		PACKAGES =
		(
			'<Package_1>'
			,'<Package_2>'
			,'<Package_...N>'
		)
		-- When the code is in-line, you can specify just the function name, as in the following example
		HANDLER = 'load_data'
		/***** Optional Parameters *****/
		-- Specify the the names of external access integration needed in order for this procedure’s handler code to access external networks.
		-- An external access integration specifies network rules and secrets that specify external locations and credentials (if any)
		-- allowed for use by handler code when making requests of an external network, such as an external REST API.
		EXTERNAL_ACCESS_INTEGRATIONS = (ACCESS_INTEGRATION_YEXT_API)
		-- Assign the names of secrets to variables so that you can use the variables to reference the secrets
		-- when retrieving information from secrets in handler code.
		-- Secrets you specify here must be allowed by the external access integration.
		-- This parameter’s value is a comma-separated list of assignment expressions with the following parts:
			-- secret_name as the name of the allowed secret.
				-- You will receive an error if you specify a SECRETS value whose secret isn’t also included in an integration
				-- specified by the EXTERNAL_ACCESS_INTEGRATIONS parameter.
			-- 'secret_variable_name' as the variable that will be used in handler code when retrieving information from the secret.
		SECRETS = ('<secret_variable_name>' = SECRET_YEXT_API_KEY)
		-- Specify that the procedure executes with the privileges as the caller, not the owner
		EXECUTE AS CALLER
		AS
		-- You must enclose the python code below in string literal delimiters (') or ($$)
		'
			def load_data():
			
				<ENTER DATA PIPELINE CODE HERE>
		'
	;


	/*
		Step 8: Execute the DB_KKF_MAIN.PUBLIC.SP_YEXT_REVIEW_DATA_LOAD() procedure
	*/


	CALL DB_KKF_MAIN.PUBLIC.SP_YEXT_REVIEW_DATA_LOAD()
	;


/****************************************************************************************************/
-- Initial Snowflake Environment Setup
/****************************************************************************************************/


	-- Assume the USERADMIN role to create new custom roles
	USE ROLE USERADMIN;


	-- Create the ELTADMIN user that will be utilized in ADF for ELT purposes
	CREATE USER ELTADMIN
		PASSWORD='*Easy_ELT_123!*'
		MUST_CHANGE_PASSWORD = FALSE;


	-- Assume the SECURITYADMIN role to grant object access to certain roles
	USE ROLE SECURITYADMIN;


	-- Grant the SYSADMIN role to the ELTADMIN user
	GRANT ROLE SYSADMIN
		TO USER ELTADMIN;


	-- Alter the ETLADMIN user to default certain specifications for convenience purposes
	ALTER USER ELTADMIN
		SET
			DEFAULT_ROLE = SYSADMIN
			DEFAULT_NAMESPACE = DB_KKF_MAIN.TRANSIENT
			DEFAULT_WAREHOUSE = PRD_WH_AD_HOC_ELT_ELT_ADMIN;


	-- Assume the SYSADMIN role to create new database objects
	USE SYSADMIN;


	-- Create the PRD_WH_DBO warehouse that will be utilized for building new database objects
	CREATE OR REPLACE WAREHOUSE PRD_WH_DBO
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;


	-- Create the PRD_WH_AD_HOC_ELT warehouse that will be utilized for executing Ad Hoc ELT projects/processes
	CREATE OR REPLACE WAREHOUSE PRD_WH_AD_HOC_ELT
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;


	-- Create the PRD_WH_ADF_ELT warehouse that will be utilized by ADF for executing ELT projects/processes
	CREATE OR REPLACE WAREHOUSE PRD_WH_ADF_ELT
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;


	-- Create the PRD_WH_REDFIN_ELT warehouse that will be utilized for executing Ad Hoc ELT projects/processes
	CREATE OR REPLACE WAREHOUSE PRD_WH_REDFIN_ELT
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;


	-- Create the PRD_WH_SYSCO_ELT warehouse that will be utilized for executing Ad Hoc ELT projects/processes
	CREATE OR REPLACE WAREHOUSE PRD_WH_SYSCO_ELT
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;


	-- Create the PRD_WH_ARROWSTREAM_ELT warehouse that will be utilized for executing Ad Hoc ELT projects/processes
	CREATE OR REPLACE WAREHOUSE PRD_WH_ARROWSTREAM_ELT
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;


	-- Create the PRD_WH_REDFIN_ELT warehouse that will be utilized for executing Ad Hoc ELT projects/processes
	CREATE OR REPLACE WAREHOUSE PRD_WH_SALESFORCE_ELT
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;


	-- Create the PRD_WH_REDFIN_ELT warehouse that will be utilized for executing Ad Hoc ELT projects/processes
	CREATE OR REPLACE WAREHOUSE PRD_WH_NETSUITE_ELT
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;


	-- Create the PRD_WH_REDFIN_ELT warehouse that will be utilized for executing Ad Hoc ELT projects/processes
	CREATE OR REPLACE WAREHOUSE PRD_WH_ZENDESK_ELT
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;

		
	-- Create the DB_KKF_MAIN database that will be utilized for storing all of the necessary data from all data sources
	-- for reporting puropses
	CREATE DATABASE DB_KKF_MAIN;


	-- Create the DB_KKF_MAIN.TRANSIENT schema that will be the 1st layer of the staging environment
	-- and will be utilized for storing raw data from all data sources
	CREATE SCHEMA DB_KKF_MAIN.TRANSIENT;


	-- Create the DB_KKF_MAIN.PERSISTED schema that will be the 2nd layer of the staging environment
	-- and will be utilized for storing transformed data from the DB_KKF_MAIN.TRANSIENT schema
	CREATE SCHEMA DB_KKF_MAIN.PERSISTED;


	-- Create the DB_KKF_MAIN.REPORTING schema that will be the presentation environment
	-- and will be utilized for storing modeled data from the DB_KKF_MAIN.PERSISTED schema
	CREATE SCHEMA DB_KKF_MAIN.REPORTING;


	-- Assume the DB_KKF_MAIN database in order to create database objects
	USE DATABASE DB_KKF_MAIN;


	-- that will be utilized to read and write Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	CREATE FILE FORMAT FF_CSV_COMMA
		TYPE = 'CSV'
		FIELD_DELIMITER = ','
		COMPRESSION = NONE;


	-- that will be utilized to read and write Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	CREATE FILE FORMAT FF_CSV_PIPE
		TYPE = 'CSV'
		FIELD_DELIMITER = '|'
		COMPRESSION = NONE;


	-- that will be utilized when loading or exporting CSV files between Snowflake and Azure Blob Storage
	CREATE OR REPLACE STAGE STG_AZURE_BLOB_CSV_COMMA
	  URL = 'azure://krispykrunchychicken.blob.core.windows.net/krispy-krunchy-foods'
	  CREDENTIALS = (AZURE_SAS_TOKEN = 'sp=r&st=2023-09-05T19:55:42Z&se=2023-09-06T03:55:42Z&spr=https&sv=2022-11-02&sr=c&sig=IYev%2FXA4zoJqU%2Bd%2FBH1q45KcNS3lVmYU8KVn6AHAKBc%3D')
	  FILE_FORMAT = FF_CSV_COMMA;


	-- that will be utilized when loading or exporting Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	CREATE OR REPLACE STAGE STG_AZURE_BLOB_CSV_PIPE
	  URL = 'azure://krispykrunchychicken.blob.core.windows.net/krispy-krunchy-foods'
	  CREDENTIALS = (AZURE_SAS_TOKEN = 'sp=r&st=2023-09-05T19:55:42Z&se=2023-09-06T03:55:42Z&spr=https&sv=2022-11-02&sr=c&sig=IYev%2FXA4zoJqU%2Bd%2FBH1q45KcNS3lVmYU8KVn6AHAKBc%3D')
	  FILE_FORMAT = FF_CSV_PIPE;


	-- Create the DB_KKF_MAIN.TRANSIENT.NIQ_TDLINX_INDEPENDENT_C_STORES table that will be utilized for storing
	-- the raw NIQ TDLinx C-Store data for staging puropses
	CREATE OR REPLACE TABLE DB_KKF_MAIN.TRANSIENT.NIQ_TDLINX_C_STORE
	(
		TDLINX_STORE_CODE VARCHAR(20)
		,DATA_PERIOD VARCHAR(15)
		,STORE_NAME VARCHAR(100)
		,STORE_NUM VARCHAR(10)
		,STREET_ADDRESS VARCHAR(100)
		,CITY VARCHAR(100)
		,STATE VARCHAR(10)
		,ZIP VARCHAR(10)
		,STATE_FIPS VARCHAR(10)
		,COUNTY_FIPS VARCHAR(11)
		,COUNTRY VARCHAR(10)
		,TRADE_CHANNEL VARCHAR(50)
		,SUB_CHANNEL VARCHAR(50)
		,NUM_STORES_IN_ULTIMATE_PARENT VARCHAR(30)
		,SAREACD VARCHAR(10)
		,SPHONENO VARCHAR(10)
		,ANNUAL_ACV_RANGE VARCHAR(50)
		,ANNUAL_ACV_THOUSANDS VARCHAR(20)
		,SELLING_SQFT VARCHAR(15)
	);


	-- Create the DB_KKF_MAIN.PERSISTED.NIQ_TDLINX_INDEPENDENT_C_STORES table that will be utilized for storing
	-- the transformed NIQ TDLinx C-Store data for reporting puropses
	CREATE OR REPLACE TABLE DB_KKF_MAIN.PERSISTED.NIQ_TDLINX_C_STORE
	(
		TDLINX_STORE_CODE VARCHAR(10)
		,DATA_PERIOD DATE
		,STORE_NAME VARCHAR(100)
		,STORE_NUMBER VARCHAR(10)
		,STREET_ADDRESS VARCHAR(100)
		,CITY VARCHAR(100)
		,STATE VARCHAR(5)
		,ZIP VARCHAR(10)
		,STATE_FIPS VARCHAR(5)
		,COUNTY_FIPS VARCHAR(5)
		,COUNTRY VARCHAR(5)
		,TRADE_CHANNEL VARCHAR(50)
		,SUB_CHANNEL VARCHAR(50)
		,NUM_STORES_IN_ULTIMATE_PARENT VARCHAR(15)
		,SAREACD VARCHAR(5)
		,SPHONENO VARCHAR(10)
		,ANNUAL_ACV_RANGE VARCHAR(50)
		,ANNUAL_ACV_THOUSANDS NUMBER(20,0)
		,SELLING_SQFT NUMBER(10,0)
	);


	-- Create the DB_KKF_MAIN.TRANSIENT.REDFIN_SALES_DETAIL table that will be utilized for storing
	-- the raw RedFin item for each check data for staging puropses
	CREATE OR REPLACE TABLE DB_KKF_MAIN.TRANSIENT.REDFIN_SALES_DETAIL
	(
		STORE_ID VARCHAR(15)
		,CHECK_DATE VARCHAR(25)
		,CHECK_TIME VARCHAR(5)
		,CHECK_NUMBER VARCHAR(15)
		,LINE_ITEM_NUMBER VARCHAR(10)
		,MENU_ITEM_NAME VARCHAR(100)
		,PLU VARCHAR(15)
		,DEPARTMENT_NAME VARCHAR(25)
		,CATEGORY_NAME VARCHAR(25)
		,QUANTITY VARCHAR(10)
		,ITEM_TOTAL VARCHAR(10)
	);


	-- Create the DB_KKF_MAIN.PERSISTED.REDFIN_SALES_DETAIL table that will be utilized for storing
	-- the transformed RedFin item for each check data for reporting puropses
	CREATE OR REPLACE TABLE DB_KKF_MAIN.PERSISTED.REDFIN_SALES_DETAIL
	(
		STORE_ID VARCHAR(15)
		,CHECK_NUMBER VARCHAR(5)
		,CHECK_DATE DATE
		,CHECK_TIME TIME
		,LINE_ITEM_NUMBER NUMBER(15,0)
		,PLU VARCHAR(15)
		,MENU_ITEM_NAME VARCHAR(100)
		,DEPARTMENT_NAME VARCHAR(25)
		,CATEGORY_NAME VARCHAR(25)
		,QUANTITY NUMBER(10,0)
		,ITEM_TOTAL NUMBER(15,2)
	);


	-- Create the DB_KKF_MAIN.TRANSIENT.REDFIN_SALES_HEADER table that will be utilized for storing
	-- the raw RedFin check header data for staging puropses
	CREATE OR REPLACE TABLE DB_KKF_MAIN.TRANSIENT.REDFIN_SALES_HEADER
	(
		STORE_ID  VARCHAR(15)
		,STORE_NAME VARCHAR(50)
		,STORE_LOCATION VARCHAR(50)
		,CHECK_DATE VARCHAR(25)
		,CHECK_NUMBER VARCHAR(11)
		,CHECK_TOTAL VARCHAR(10)
		,DISCOUNT_TOTAL VARCHAR(13)
		,TAX_TOTAL VARCHAR(8)
		--,NON_SALES_TOTAL VARCHAR(13)
		,VOID_TOTAL VARCHAR(10)
		,ORDER_TYPE VARCHAR(10)
	);


	-- Create the DB_KKF_MAIN.PERSISTED.REDFIN_SALES_HEADER table that will be utilized for storing
	-- the transformed RedFin check header data for reporting puropses
	CREATE OR REPLACE TABLE DB_KKF_MAIN.PERSISTED.REDFIN_SALES_HEADER
	(
		STORE_ID  VARCHAR(15)
		,STORE_NAME VARCHAR(50)
		,STORE_LOCATION VARCHAR(50)
		,CHECK_NUMBER VARCHAR(5)
		,CHECK_DATE DATE
		,CHECK_TIME TIME
		,CHECK_TOTAL NUMBER(15,2)
		,DISCOUNT_TOTAL NUMBER(15,2)
		,TAX_TOTAL NUMBER(15,2)
		,NON_SALES_TOTAL NUMBER(15,2)
		,VOID_TOTAL NUMBER(15,2)
		,ORDER_TYPE VARCHAR(15)
	);


/****************************************************************************************************/
-- Power Apps Integration
/****************************************************************************************************/


	-- Assume the ACCOUNT ADMIN role, as this is the role need to create a new SECURITY INTEGRATION in Snowflake
	USE ROLE ACCOUNTADMIN
	;


	-- Create the new, or update an existing SECURITY INTEGRATION named CONNECTOR
	CREATE OR REPLACE SECURITY INTEGRATION CONNECTOR
	   TYPE = EXTERNAL_OAUTH
	   ENABLED = TRUE
	   EXTERNAL_OAUTH_TYPE = AZURE
	   EXTERNAL_OAUTH_ISSUER = 'https://sts.windows.net/0a5127ea-bf38-4e1c-9667-724b1a37bad6/'    
	   EXTERNAL_OAUTH_JWS_KEYS_URL = 'https://login.microsoftonline.com/0a5127ea-bf38-4e1c-9667-724b1a37bad6/discovery/v2.0/keys'
	   EXTERNAL_OAUTH_AUDIENCE_LIST = ('api://2860ebcd-3963-4877-b95f-58a945ecbaf2')
	   EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'upn'
	   EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'login_name'
	   EXTERNAL_OAUTH_ANY_ROLE_MODE = 'ENABLE'
	;


	-- Grant a specific role access to use the CONNECTOR SECURITY INTEGRATION
	GRANT USE_ANY_ROLE ON INTEGRATION CONNECTOR
		TO ROLE SYSADMIN
	;


	-- 
	DESC SECURITY INTEGRATION CONNECTOR
	;


	/*
		-- Test the CONNECTOR SECURITY INTEGRATION
		curl -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
		  --data-urlencode "client_id=<OAUTH_CLIENT_ID>" \
		  --data-urlencode "client_secret=<OAUTH_CLIENT_SECRET>" \
		  --data-urlencode "username=<AZURE_AD_USER>" \
		  --data-urlencode "password=<AZURE_AD_USER_PASSWORD>" \
		  --data-urlencode "grant_type=password" \
		  --data-urlencode "scope=<AZURE_APP_URI+AZURE_APP_SCOPE>" \
		  'https://login.microsoftonline.com/0a5127ea-bf38-4e1c-9667-724b1a37bad6/oauth2/v2.0/token'
	*/


/****************************************************************************************************/
-- Snowflake Shares
/****************************************************************************************************/


	USE ROLE SYSADMIN;


	CREATE OR REPLACE SECURE VIEW <Database_Name>.<Schema_Name>.SVW_<Secure_View_Name>
	AS 

	SELECT * FROM <Database_Name>.<Schema_Name>.<Table_Name>
	;


	USE ROLE ACCOUNTADMIN;


	GRANT USAGE ON SCHEMA <Database_Name>.<Schema_Name>
		TO SHARE SHARE_CHAINACCOUNT
	;


	GRANT SELECT ON VIEW <Database_Name>.<Schema_Name>.<Secure_View_Name>
		TO SHARE SHARE_CHAINACCOUNT
	;


	REVOKE USAGE ON SCHEMA <Database_Name>.<Schema_Name>
		FROM SHARE SHARE_CHAINACCOUNT
	;


	REVOKE SELECT ON VIEW <Database_Name>.<Schema_Name>.<Secure_View_Name>
		TO SHARE SHARE_CHAINACCOUNT
	;


	SHOW GRANTS TO SHARE SHARE_CHAINACCOUNT
	;


/****************************************************************************************************/
-- Snowflake TASKS
/****************************************************************************************************/


	-- LOOK INTO RESCHEDULING EACH TASK TO BE RUN AT DIFFERENT TIMES


	DROP TASK TASK_SYSCO_INVOICE_ITEM_DETAIL_DATA_LOADS_DAILY_3_AM_EST
	;

	DROP TASK TASK_SYSCO_INVOICE_STORE_DETAIL_DATA_LOADS_DAILY_3_AM_EST
	;

	DROP TASK TASK_SYSCO_RECEIVING_PO_DATA_LOADS_DAILY_3_AM_EST
	;

	DROP TASK TASK_REDFIN_SALES_HEADER_DATA_LOADS_DAILY_4_AM_EST
	;


	-- Use the SYSADMIN role that has privileges to create and modify tasks
	USE ROLE SYSADMIN;

	-- Use the DB_KKF_MAIN database to specify where to save the task
	USE DATABASE DB_KKF_MAIN;

	-- Create the TASK_SYSCO_INVENTORY_DATA_LOADS_DAILY_3_AM_EST task
	CREATE OR REPLACE TASK TASK_SYSCO_INVENTORY_DATA_LOADS_DAILY_3_AM_EST
	  WAREHOUSE = PRD_WH_SYSCO_ELT
	  SCHEDULE = 'USING CRON 0 3 * * * America/New_York'
	  TIMESTAMP_INPUT_FORMAT = 'YYYY-MM-DD HH24'

	AS
	  CALL DB_KKF_MAIN.PUBLIC.SP_SYSCO_INVENTORY();


	ALTER TASK TASK_SYSCO_INVENTORY_DATA_LOADS_DAILY_3_AM_EST RESUME;



	/****************************************************************************************************/
	/****************************************************************************************************/
	/****************************************************************************************************/



	-- Create the TASK_SYSCO_INVOICE_ITEM_DETAIL_DATA_LOADS_DAILY_3_AM_EST task
	CREATE OR REPLACE TASK TASK_SYSCO_INVOICE_ITEM_DETAIL_DATA_LOADS_DAILY_315_AM_EST
	  WAREHOUSE = PRD_WH_SYSCO_ELT
	  SCHEDULE = 'USING CRON 15 3 * * * America/New_York'
	  TIMESTAMP_INPUT_FORMAT = 'YYYY-MM-DD HH24'

	AS
	  CALL DB_KKF_MAIN.PUBLIC.SP_SYSCO_NID_INVOICE_ITEM_DETAIL();


	ALTER TASK TASK_SYSCO_INVOICE_ITEM_DETAIL_DATA_LOADS_DAILY_315_AM_EST RESUME;



	/****************************************************************************************************/
	/****************************************************************************************************/
	/****************************************************************************************************/



	-- Create the TASK_SYSCO_INVOICE_STORE_DETAIL_DATA_LOADS_DAILY_3_AM_EST task
	CREATE OR REPLACE TASK TASK_SYSCO_INVOICE_STORE_DETAIL_DATA_LOADS_DAILY_330_AM_EST
	  WAREHOUSE = PRD_WH_SYSCO_ELT
	  SCHEDULE = 'USING CRON 30 3 * * * America/New_York'
	  TIMESTAMP_INPUT_FORMAT = 'YYYY-MM-DD HH24'

	AS
	  CALL DB_KKF_MAIN.PUBLIC.SP_SYSCO_INVOICE_STORE_DETAIL_DATA_LOADS_DAILY();


	ALTER TASK TASK_SYSCO_INVOICE_STORE_DETAIL_DATA_LOADS_DAILY_330_AM_EST RESUME;



	/****************************************************************************************************/
	/****************************************************************************************************/
	/****************************************************************************************************/



	-- Create the TASK_SYSCO_RECEIVING_PO_DATA_LOADS_DAILY_3_AM_EST task
	CREATE OR REPLACE TASK TASK_SYSCO_RECEIVING_PO_DATA_LOADS_DAILY_345_AM_EST
	  WAREHOUSE = PRD_WH_SYSCO_ELT
	  SCHEDULE = 'USING CRON 45 3 * * * America/New_York'
	  TIMESTAMP_INPUT_FORMAT = 'YYYY-MM-DD HH24'

	AS
	  CALL DB_KKF_MAIN.PUBLIC.SP_SYSCO_RECEIVING_PO();


	ALTER TASK TASK_SYSCO_RECEIVING_PO_DATA_LOADS_DAILY_345_AM_EST RESUME;


	/****************************************************************************************************/
	/****************************************************************************************************/
	/****************************************************************************************************/



	-- Create the TASK_REDFIN_SALES_DETAIL_DATA_LOADS_DAILY_4_AM_EST task
	CREATE OR REPLACE TASK TASK_REDFIN_SALES_DETAIL_DATA_LOADS_DAILY_4_AM_EST
	  WAREHOUSE = PRD_WH_REDFIN_ELT
	  SCHEDULE = 'USING CRON 0 4 * * * America/New_York'
	  TIMESTAMP_INPUT_FORMAT = 'YYYY-MM-DD HH24'

	AS
	  CALL DB_KKF_MAIN.PUBLIC.SP_REDFIN_SALES_DETAIL();


	ALTER TASK TASK_REDFIN_SALES_DETAIL_DATA_LOADS_DAILY_4_AM_EST RESUME;



	/****************************************************************************************************/
	/****************************************************************************************************/
	/****************************************************************************************************/



	-- Create the TASK_REDFIN_SALES_HEADER_DATA_LOADS_DAILY_4_AM_EST task
	CREATE OR REPLACE TASK TASK_REDFIN_SALES_HEADER_DATA_LOADS_DAILY_415_AM_EST
	  WAREHOUSE = PRD_WH_REDFIN_ELT
	  SCHEDULE = 'USING CRON 15 4 * * * America/New_York'
	  TIMESTAMP_INPUT_FORMAT = 'YYYY-MM-DD HH24'

	AS
	  CALL DB_KKF_MAIN.PUBLIC.SP_REDFIN_SALES_HEADER();


	ALTER TASK TASK_REDFIN_SALES_HEADER_DATA_LOADS_DAILY_415_AM_EST RESUME;




	SHOW TASKS
	;


/****************************************************************************************************/
-- Create New Role
/****************************************************************************************************/


	------------------------------------------------------------------
	-- CREATE THE NEW RL_PROJECTADMIN ROLE USING THE USERADMIN ROLE --
	------------------------------------------------------------------

	USE ROLE USERADMIN;

	CREATE OR REPLACE ROLE RL_PROJECTADMIN;


	---------------------------------------------------------
	-- GRANT THE RL_PROJECTADMIN ROLE TO THE SYSADMIN ROLE --
	---------------------------------------------------------

	USE ROLE ACCOUNTADMIN;

	GRANT ROLE RL_PROJECTADMIN
	   TO ROLE SYSADMIN;


	----------------------------------------------------------------------------------------------
	-- GRANT THE NEW RL_PROJECTADMIN ROLE ACCESS TO THE WAREHOUSES USING THE SECURITYADMIN ROLE --
	----------------------------------------------------------------------------------------------

	USE ROLE SECURITYADMIN;

	GRANT USAGE ON WAREHOUSE PRD_WH_REPORTING
	TO ROLE RL_PROJECTADMIN;

	GRANT USAGE ON WAREHOUSE TEST_WH_REPORTING
	TO ROLE RL_PROJECTADMIN;

	GRANT USAGE ON WAREHOUSE DEV_WH_REPORTING
	TO ROLE RL_PROJECTADMIN;


	----------------------------------------------------------------------
	-- GRANT A ROLE ACCESS TO THE DATABASE USING THE SECURITYADMIN ROLE --
	----------------------------------------------------------------------

	USE ROLE SECURITYADMIN;

	GRANT USAGE ON DATABASE DB_KKF_CHAIN_ACCOUNT
	TO ROLE RL_PROJECTADMIN;


	-----------------------------------------------------------------------
	-- GRANT A ROLE ACCESS TO THE SCHEMA(S) USING THE SECURITYADMIN ROLE --
	-----------------------------------------------------------------------

	USE ROLE SECURITYADMIN;

	GRANT USAGE ON SCHEMA DB_KKF_CHAIN_ACCOUNT.REPORTING
	TO ROLE RL_PROJECTADMIN;

	GRANT ALL ON FUTURE TABLES IN SCHEMA DB_KKF_CHAIN_ACCOUNT.REPORTING
	TO ROLE RL_PROJECTADMIN;

	GRANT ALL ON FUTURE VIEWS IN SCHEMA DB_KKF_CHAIN_ACCOUNT.REPORTING
	TO ROLE RL_PROJECTADMIN;

	GRANT USAGE ON FUTURE SCHEMAS IN DATABASE DB_KKF_CHAIN_ACCOUNT
	TO ROLE RL_PROJECTADMIN;


	-----------------------------------------------------------------------------------------------
	-- GRANT THE NEW RL_PROJECTADMIN ROLE THE NECESSARY PRIVILEGE(S) USING THE ACCOUNTADMIN ROLE --
	-----------------------------------------------------------------------------------------------

	USE ROLE ACCOUNTADMIN;

	GRANT IMPORTED PRIVILEGES ON DATABASE DB_KKF_CHAIN_ACCOUNT TO ROLE RL_PROJECTADMIN;

	-- GRANT PRIVILEGE TO CREATE NEW SCHEMAS WITHIN THE DB_KKF_CHAIN_ACCOUNT DATABASE
	GRANT CREATE SCHEMA ON DATABASE DB_KKF_CHAIN_ACCOUNT
	TO ROLE RL_PROJECTADMIN;

	-- GRANT PRIVILEGE TO CREATE NEW PROCEDURES WITHIN THE DB_KKF_CHAIN_ACCOUNT DATABASE
	GRANT MODIFY PROCEDURE ON SCHEMA DB_KKF_CHAIN_ACCOUNT.PUBLIC
	TO ROLE RL_PROJECTADMIN;

	-- GRANT PRIVILEGE TO MODIFY THE NEW REPORTING SCHEMA WITHIN THE DB_KKF_CHAIN_ACCOUNT DATABASE
	GRANT MODIFY ON SCHEMA DB_KKF_CHAIN_ACCOUNT.REPORTING
	TO ROLE RL_PROJECTADMIN;


/****************************************************************************************************/
-- Create New User
/****************************************************************************************************/


	--------------------------------------------------
	-- CREATE THE NEW USER USING THE USERADMIN ROLE --
	--------------------------------------------------

	USE ROLE USERADMIN;

	CREATE USER <User_Name>
		PASSWORD = 'Snowflake2024!'
		EMAIL = '<KKF_Email_Address>'
		DEFAULT_SECONDARY_ROLES = ('ALL')
		MUST_CHANGE_PASSWORD = TRUE
	;


	--------------------------------------------------------------------------------------
	-- CREATE THE NEW USER ACCESS TO THE NECESSARY ROLE(S) USING THE SECURITYADMIN ROLE --
	--------------------------------------------------------------------------------------

	USE ROLE SECURITYADMIN
	;

	GRANT ROLE <Role_Name>
	TO USER <User_Name>
	;


	-------------------------------------------------------------------------
	-- ALTER THE NEW USER TO SET DEFAULT SETTINGS USING THE USERADMIN ROLE --
	-------------------------------------------------------------------------

	USE ROLE USERADMIN
	;

	ALTER USER <User_Name>
		SET
			DEFAULT_ROLE = <Role_Name>
			DEFAULT_NAMESPACE = <Database_Name>.<Schema_Name>
			DEFAULT_WAREHOUSE = <Warehouse_Name>
	;


/****************************************************************************************************/
-- Snowflake Environment Initial Setup - DB Receiving Shares from DW
/****************************************************************************************************/


	------------------------------------------------------------------------
	-- GRANT IMPORTED PRIVILEGES TO ALL ROLES USING THE ACCOUNTADMIN ROLE --
	------------------------------------------------------------------------

	USE ROLE ACCOUNTADMIN;

	GRANT IMPORTED PRIVILEGES ON DATABASE DB_KKF_CHAIN_ACCOUNT TO ROLE SYSADMIN;

	GRANT IMPORTED PRIVILEGES ON DATABASE DB_KKF_CHAIN_ACCOUNT TO ROLE SECURITYADMIN;

	GRANT IMPORTED PRIVILEGES ON DATABASE DB_KKF_CHAIN_ACCOUNT TO ROLE USERADMIN;


	-------------------------------------------------------
	-- CREATE THE NEW WAREHOUSES USING THE SYSADMIN ROLE --
	-------------------------------------------------------

	USE ROLE SYSADMIN;

	CREATE WAREHOUSE PRD_WH_REPORTING
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;

	CREATE WAREHOUSE TEST_WH_REPORTING
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;

	CREATE WAREHOUSE DEV_WH_REPORTING
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE;


	--------------------------------------------------------------------------
	-- CREATE THE NEW DB_KKF_CHAIN_ACCOUNT DATABASE USING THE SYSADMIN ROLE --
	--------------------------------------------------------------------------

	USE ROLE SYSADMIN;

	CREATE DATABASE DB_KKF_CHAIN_ACCOUNT;


	-------------------------------------------------------------
	-- CREATE THE NEW REPORTING SCHEMA USING THE SYSADMIN ROLE --
	-------------------------------------------------------------

	USE ROLE SYSADMIN;

	CREATE SCHEMA DB_KKF_CHAIN_ACCOUNT.REPORTING;


	---------------------------------------------------------
	-- CREATE RESOURCE MONITOR USING THE ACCOUNTADMIN ROLE --
	---------------------------------------------------------

	-- Only the ACCOUNTADMIN role has this privilege by default
	USE ROLE ACCOUNTADMIN;


	-- Create the resource monitor
	-- Proper naming convention for creating a resource monitor is to prepend "RM_" before the resource monitor name (i.e. RM_CHAIN_ACCOUNT)
	CREATE OR REPLACE RESOURCE MONITOR RM_CHAIN_ACCOUNT
	WITH
		CREDIT_QUOTA = 5000
		FREQUENCY = MONTHLY
		START_TIMESTAMP = IMMEDIATELY
		NOTIFY_USERS =
		(
			JLOOKER
			,CRUIZ
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
	ALTER ACCOUNT SET RESOURCE_MONITOR = RM_CHAIN_ACCOUNT
	;


/****************************************************************************************************/
-- COPY INTO
/****************************************************************************************************/


	-- COPY INTO <locatin>
	COPY INTO @<Stage_Name>/<Folder_Name>/<File_Name>.<File_Extension>
		FROM <Database.Schema.Table/View> OR (<Query>)
		OVERWRITE = TRUE -- Overwrites any existing file with the same name in the same location
		MAX_FILE_SIZE = 5368709120 -- Increases the File size limit
		SINGLE = TRUE -- Creates a single instead of multiple smaller files
		HEADER = TRUE -- Includes column names as header row
	;
		

	-- COPY INTO <table>
	COPY INTO <database_name>.<schema_name>.<table_name>
		FROM @<Stage_Name>/<Folder_Name>/<File_Name>.<File_Extension>
	;


/****************************************************************************************************/
-- 
/****************************************************************************************************/


	-- Comma Delimited CSV/TXT files
	-- Proper naming convention is to prepend "FF_" followed by the file format name
	​
	-- Assume the DB_KRISPY_KRUNCHY database and create the FF_CSV_COMMA file format
	-- that will be utilized to read and write Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	USE DATABASE DB_KKF_MAIN;
	​
	CREATE OR REPLACE FILE FORMAT FF_CSV_COMMA
		TYPE = 'CSV'
		FIELD_DELIMITER = ','
		COMPRESSION = NONE
	;


	-- Comma Delimited CSV/TXT files w/ Double Qutoe (") wrapped field values
	-- Proper naming convention is to prepend "FF_" followed by the file format name
	​
	-- Assume the DB_KRISPY_KRUNCHY database and create the FF_CSV_COMMA file format
	-- that will be utilized to read and write Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	USE DATABASE DB_KKF_MAIN;
	​
	CREATE OR REPLACE FILE FORMAT FF_CSV_COMMA_DOUBLE_QUOTES
		TYPE = 'CSV'
		FIELD_DELIMITER = ','
		COMPRESSION = NONE
		FIELD_OPTIONALLY_ENCLOSED_BY = '"'
	;


	-- Pipe Delimited CSV/TXT files
	-- Proper naming convention is to prepend "FF_" followed by the file format name
	​
	-- Assume the DB_KRISPY_KRUNCHY database and create the FF_CSV_PIPE file format
	-- that will be utilized to read and write Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	USE DATABASE DB_KKF_MAIN;
	​
	CREATE OR REPLACE FILE FORMAT FF_CSV_PIPE
		TYPE = 'CSV'
		FIELD_DELIMITER = '|'
		COMPRESSION = NONE
	;


	-- JSON files
	-- Proper naming convention is to prepend "FF_" followed by the file format name
	​
	-- Assume the DB_KRISPY_KRUNCHY database and create the FF_CSV_PIPE file format
	-- that will be utilized to read and write Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	USE DATABASE DB_KKF_MAIN;
	​
	CREATE OR REPLACE FILE FORMAT FF_JSON
	  TYPE = JSON
	;


/****************************************************************************************************/
-- GRANT Privileges to a User
/****************************************************************************************************/


	-- Grants the specified account object privilege(s) to the specified role on the specified account object type and account object name
	GRANT <Account_Object_Privileges>
		ON <Account_Object> <Account_Object_Name>
		TO ROLE <Role_Name>
			/*
				Account Object & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- Grants the specified schema privilege(s) to the specified role on the specified database name and schema name
	GRANT <Schema_Privileges>
		ON SCHEMA <Database_Name>.<Schema_Name>
		TO ROLE <Role_Name>
			/*
				Schema Privileges:
				- 
			*/
	;
	​
	​
	​
	-- Grants the specified schema privilege(s) to the specified role on all existing schemas on the specified database name
	GRANT <Schema_Privileges>
		ON ALL SCHEMAS IN DATABASE <Database_Name>
		TO ROLE <Role_Name>
			/*
				Schema Privileges:
				- 
			*/
	;
	​
	​
	​
	-- Grants the specified schema privilege(s) to the specified role on all future schemas on the specified database name
	GRANT <Schema_Privileges>
		ON FUTURE SCHEMAS IN DATABASE <Database_Name>
		TO ROLE <Role_Name>
			/*
				Schema Privileges:
				- 
			*/
	;
	​
	​
	​
	-- Grants the specified schema object privilege(s) to the specified role on the specified schema object type and schema object name
	GRANT <Schema_Object_Privileges>
		ON <Object_Type> <Object_Name>
		TO ROLE <Role_Name>
			/*
				Schema Object & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- Grants the specified schema object privilege(s) to the specified role on all existing specified schema object types on the specified database name
	GRANT <Schema_Object_Privileges>
		ON ALL <Object_Type_Plural>
		IN DATABASE <Database_Name>
		TO ROLE <Role_Name>
			/*
				Object Type & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- Grants the specified schema object privilege(s) to the specified role on all existing specified schema object types on the specified database name and schema name
	GRANT <Schema_Object_Privileges>
		ON ALL <Object_Type_Plural>
		IN SCHEMA <Database_Name>.<Schema_Name>
		TO ROLE <Role_Name>
			/*
				Object Type & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- Grants the specified schema object privilege(s) to the specified role on all future specified schema object types on the specified database name
	GRANT <Schema_Object_Privileges>
		ON FUTURE <Object_Type_Plural>
		IN DATABASE <Database_Name>
		TO ROLE <Role_Name>
			/*
				Object Type & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- Grants the specified schema object privilege(s) to the specified role on all future specified schema object types on the specified database name and schema name
	GRANT <Schema_Object_Privileges>
		ON FUTURE <Object_Type_Plural>
		IN SCHEMA <Database_Name>.<Schema_Name>
		TO ROLE <Role_Name>
			/*
				Object Type & Privileges:
				- 
			*/
	;


/****************************************************************************************************/
-- Resource Monitor
/****************************************************************************************************/


	-- Create Resource Monitor
	-- Only the ACCOUNTADMIN role has this privilege by default
	USE ROLE ACCOUNTADMIN;
	​
	​
	-- Create the resource monitor
	-- Proper naming convention for creating a resource monitor is to prepend "RM_" before the resource monitor name (i.e. RM_CHAINACCOUNT)
	CREATE OR REPLACE RESOURCE MONITOR RM_<Resource_Monitor_Name>
	WITH
		CREDIT_QUOTA = <Credit_Limit_Number>
		FREQUENCY = MONTHLY
		START_TIMESTAMP = IMMEDIATELY
		NOTIFY_USERS =
		(
			<Snowflake_User_Name_1>
			,<Snowflake_User_Name_2>
			,<Snowflake_User_Name_N>
		)
		-- Upto 5 notify triggers are able to be assigned to a resource monitor
		TRIGGERS
			ON 50 PERCENT DO NOTIFY
			ON 75 PERCENT DO NOTIFY
			ON 90 PERCENT DO NOTIFY
			ON 100 PERCENT DO SUSPEND
			ON 110 PERCENT DO SUSPEND_IMMEDIATE
	;
	​
	​
	-- Assign the resource monitor to the account by altering the account
	ALTER ACCOUNT
		SET RESOURCE_MONITOR = <Resource_Monitor_Name>
	;


	-- ALTER Resource Monitor
	-- Only the ACCOUNTADMIN role has this privilege by default
	USE ROLE ACCOUNTADMIN;
	​
	​
	-- Alter the resource monitor to adjust the credit limit or add new users to notify
	ALTER RESOURCE MONITOR RM_<Resource_Monitor_Name>
		SET
			CREDIT_QUOTA = <New_Credit_Limit_Number>
			NOTIFY_USERS =
			(
				<New_Snowflake_User_Name_1>
				,<New_Snowflake_User_Name_2>
				,<New_Snowflake_User_Name_N>
			)
	;


/****************************************************************************************************/
-- Snowflake Role
/****************************************************************************************************/


	-- Create Role
	-- Only the USERADMIN role, or a higher role, has this privilege by default. The privilege can be granted to additional roles as needed
	USE ROLE USERADMIN;
	​
	-- Proper naming convention for creating a role is to prepend "RL_" before the role name (i.e. RL_PROJECT_ADMIN)
	CREATE OR REPLACE ROLE RL_<Role_Name>;


	-- Grant role access to warehouse
	USE ROLE SECURITYADMIN;
	​
	GRANT USAGE ON WAREHOUSE <Warehouse_Name>
	TO ROLE <Role_Name>;


	-- Grant rola access to database
	USE ROLE SECURITYADMIN;
	​
	GRANT USAGE ON DATABASE <Database_Name>
	TO ROLE <Role_Name>;


	-- Grant rola access to schema
	USE ROLE SECURITYADMIN;
	​
	GRANT USAGE ON SCHEMA <Database_Name>.<Schema_Name>
	TO ROLE <Role_Name>;


	-- Grant rola access to table/view
	USE ROLE SECURITYADMIN;
	​
	GRANT <privilege> ON TABLE/VIEW <Database_Name>.<Schema_Name>.<Table/View_Name>
	TO ROLE <Role_Name>;


	-- Grant user access to role
	USE ROLE SECURITYADMIN;
	​
	GRANT ROLE <Role_Name>
	TO USER <User_Name>;


	-- Grant privileges to role
	USE ROLE SECURITYADMIN;
	​
	-- 
	GRANT <Account_Object_Privileges>
		ON <Account_Object> <Account_Object_Name>
		TO ROLE <Role_Name>
			/*
				Account Object & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- 
	GRANT <Schema_Privileges>
		ON SCHEMA <Database_Name>.<Schema_Name>
		TO ROLE <Role_Name>
			/*
				Schema Privileges:
				- 
			*/
	;
	​
	​
	​
	-- 
	GRANT <Schema_Privileges>
		ON ALL SCHEMAS IN DATABASE <Database_Name>
		TO ROLE <Role_Name>
			/*
				Schema Privileges:
				- 
			*/
	;
	​
	​
	​
	-- 
	GRANT <Schema_Privileges>
		ON FUTURE SCHEMAS IN DATABASE <Database_Name>
		TO ROLE <Role_Name>
			/*
				Schema Privileges:
				- 
			*/
	;
	​
	​
	​
	-- 
	GRANT <Schema_Object_Privileges>
		ON <Object_Type> <Object_Name>
		TO ROLE <Role_Name>
			/*
				Schema Object & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- 
	GRANT <Schema_Object_Privileges>
		ON ALL <Object_Type_Plural>
		IN DATABASE <Database_Name>
		TO ROLE <Role_Name>
			/*
				Object Type & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- 
	GRANT <Schema_Object_Privileges>
		ON ALL <Object_Type_Plural>
		IN SCHEMA <Database_Name>.<Schema_Name>
		TO ROLE <Role_Name>
			/*
				Object Type & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- 
	GRANT <Schema_Object_Privileges>
		ON FUTURE <Object_Type_Plural>
		IN DATABASE <Database_Name>
		TO ROLE <Role_Name>
			/*
				Object Type & Privileges:
				- 
			*/
	;
	​
	​
	​
	-- 
	GRANT <Schema_Object_Privileges>
		ON FUTURE <Object_Type_Plural>
		IN SCHEMA <Database_Name>.<Schema_Name>
		TO ROLE <Role_Name>
			/*
				Object Type & Privileges:
				- 
			*/
	;


/****************************************************************************************************/
-- Snowlfake Stage
/****************************************************************************************************/


	-- Allows COMMA Delimited CSV files to be created in Azure Blob Storage and loaded from Azure Blob Storage. Specify the File Path and Name in the COPY INTO Command
	-- Assume the DB_KRISPY_KRUNCHY database and create the STG_AZURE_BLOB_CSV_COMMA stage
	-- that will be utilized when loading or exporting CSV files between Snowflake and Azure Blob Storage
	USE DATABASE DB_KKF_MAIN;
	​
	CREATE OR REPLACE STAGE STG_AZURE_BLOB_CSV_COMMA
	  URL = 'azure://krispykrunchychicken.blob.core.windows.net/krispykrunchychicken'
	  CREDENTIALS = (AZURE_SAS_TOKEN = 'sp=r&st=2023-09-05T19:55:42Z&se=2023-09-06T03:55:42Z&spr=https&sv=2022-11-02&sr=c&sig=IYev%2FXA4zoJqU%2Bd%2FBH1q45KcNS3lVmYU8KVn6AHAKBc%3D')
	  FILE_FORMAT = FF_CSV_COMMA;
	  

	-- Allows PIPE Delimited TXT files to be created in Azure Blob Storage and loaded from Azure Blob Storage. Specify the File Path and Name in the COPY INTO Command
	-- Assume the DB_KRISPY_KRUNCHY database and create the STG_AZURE_BLOB_CSV_PIPE stage
	-- that will be utilized when loading or exporting Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	USE DATABASE DB_KKF_MAIN;
	​
	CREATE OR REPLACE STAGE STG_AZURE_BLOB_CSV_PIPE
	  URL = 'azure://krispykrunchychicken.blob.core.windows.net/krispykrunchychicken'
	  CREDENTIALS = (AZURE_SAS_TOKEN = 'sp=r&st=2023-09-05T19:55:42Z&se=2023-09-06T03:55:42Z&spr=https&sv=2022-11-02&sr=c&sig=IYev%2FXA4zoJqU%2Bd%2FBH1q45KcNS3lVmYU8KVn6AHAKBc%3D')
	  FILE_FORMAT = FF_CSV_PIPE;


	-- Allows JSON files to be created in Azure Blob Storage and loaded from Azure Blob Storage within the toast-json-files container
	-- Assume the DB_KRISPY_KRUNCHY database and create the STG_AZURE_BLOB_CSV_PIPE stage
	-- that will be utilized when loading or exporting Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	USE DATABASE DB_KKF_MAIN;
	​
	CREATE OR REPLACE STAGE STG_AZURE_BLOB_TOAST_JSON
		URL = 'azure://krispykrunchychicken.blob.core.windows.net/toast-json-files'
		CREDENTIALS = (AZURE_SAS_TOKEN = '?sp=racwdli&st=2024-09-18T20:43:16Z&se=2035-12-31T19:59:59Z&spr=https&sv=2022-11-02&sr=c&sig=xge3XNZLx9v36%2FdLY5q4dgqH0pIF2HeoO8enp4Qp2ko%3D')
		FILE_FORMAT = FF_JSON
	;


	-- Allows COMMA Delimited CSV files to be created in Azure Blob Storage and loaded from Azure Blob Storage within the redfin-sysco-invoice-weekly container
	-- Assume the DB_KRISPY_KRUNCHY database and create the STG_AZURE_BLOB_CSV_PIPE stage
	-- that will be utilized when loading or exporting Vertical Bar "Pipe" files between Snowflake and Azure Blob Storage
	USE DATABASE DB_KKF_MAIN;
	​
	CREATE OR REPLACE STAGE STG_AZURE_BLOB_REDFIN_SYSCO_INVOICE_CSV_COMMA
		URL = 'azure://krispykrunchychicken.blob.core.windows.net/redfin-sysco-invoice-weekly'
		CREDENTIALS = (AZURE_SAS_TOKEN = '?sp=racwdli&st=2024-09-27T19:09:24Z&se=2036-01-01T06:59:59Z&spr=https&sv=2022-11-02&sr=c&sig=44ua2BvXQvAjHb1rMKQbwm02H6y55XXmVFkAKwooP2U%3D')
		FILE_FORMAT = FF_CSV_COMMA_DOUBLE_QUOTES
	;


/****************************************************************************************************/
-- Snowflake TASK
/****************************************************************************************************/


	-- Shows a detailed list of ALL TASKS
	SHOW TASKS;
	​
	​
	-- Show the history of TASK Executions
	SELECT *
	​
	FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
	​
	ORDER BY SCHEDULED_TIME;


	-- Use the SYSADMIN role that has privileges to create and modify tasks
	USE ROLE SYSADMIN;
	​
	-- CREATE OR REPLACE Parent TASK
	-- Proper naming convention is to prepend "TASK_" followed by the task name
	CREATE OR REPLACE TASK TASK_<Task_Name>
	  WAREHOUSE = <Warehouse_Name>
	  SCHEDULE = 'USING CRON * * * * * America/New_York' -- USING CRON <minute (0-59)> <hour (0-23)> <day of month (1-31, or L)> <month (1-12, JAN-DEC)> <weekday (0-6, SUN-SAT, or L)> <timezone>
	  TIMESTAMP_INPUT_FORMAT = 'YYYY-MM-DD HH24'
	​
	AS
	  CALL <Database_Name>.<Schema_Name>.<Stored_Procedure_Name>();
	​
	​
	-- CREATE OR REPLACE Child TAKS
	-- Proper naming convention is to prepend "TASK_" followed by the task name
	CREATE OR REPLACE TASK TASK_<Task_Name>
	  WAREHOUSE = <Warehouse_Name>
	  AFTER <Predecessor_Task_Name>
	​
	AS
	  CALL <Database_Name>.<Schema_Name>.<Stored_Procedure_Name>();
	​
	​
	/****************************************************************************************************/
	/****************************************************************************************************/
	​
	​
	-- To resume TASKS you must start with the first Task in the sequence and end with the last Task in the sequence
	​
	-- SUSPEND WEEKLY MONDAY DG FACT DATA LOAD
	ALTER TASK <Parent_Task_Name> SUSPEND;
	​
	​
	-- SUSPEND WEEKLY MONDAY DG NEW UPC DATA LOAD
	ALTER TASK <Child_Task_Name> SUSPEND;
	​
	​
	/****************************************************************************************************/
	/****************************************************************************************************/
	​
	​
	-- To resume TASKS you must start with the last Task in the sequence and work backwards ending with the first Task in the sequence
	​
	-- RESUME WEEKLY MONDAY DG MARKET MASTER DATA LOAD
	ALTER TASK <Child_Task_Name> RESUME;
	​
	​
	-- RESUME WEEKLY MONDAY DG PRODUCT MASTER DATA LOAD
	ALTER TASK <Parent_Task_Name> RESUME;


/****************************************************************************************************/
-- Snowflake USER
/****************************************************************************************************/


	USE ROLE USERADMIN;
	​
	CREATE USER <user1>
		PASSWORD = '<password>'
		EMAIL = '<Email_Address>'
		DEFAULT_ROLE = <Role_Name>
		DEFAULT_SECONDARY_ROLES = ('ALL')
		MUST_CHANGE_PASSWORD = TRUE;
		
		
	USE ROLE USERADMIN;
	​
	ALTER USER <User_Name>
		SET
			DEFAULT_ROLE = <Role_Name>
			DEFAULT_NAMESPACE = <Database_Name>.<Schema_Name>
			DEFAULT_WAREHOUSE = <Warehouse_Name>;


/****************************************************************************************************/
-- 
/****************************************************************************************************/


	USE ROLE SYSADMIN;
	​
	-- Proper naming convention for a view / secure view is to prepend with "VW_"
	CREATE OR REPLACE VIEW <database_name>.<schema_name>.VW_<view_name>;

	-- Proper naming convention for a view / secure view is to prepend with "SVW_"
	CREATE OR REPLACE SECURE VIEW <database_name>.<schema_name>.SVW_<view_name>;


/****************************************************************************************************/
-- Snowflake Warehouse
/****************************************************************************************************/


	/*
		When creating a new Snowflake Warehouse, be sure to setup the:
		WAREHOUSE_NAME - Prepend each warehouse name with the environment (DEV - Development, TEST - Test or PRD - Production) followed by WH
			Example:
				Warehouse used for development purposes: DEV_WH_<warehouse_name>
				Warehouse used for testing purposes: TEST_WH_<warehouse_name>
				Warehouse used for production purposes: PRD_WH_<warehouse_name>
		WAREHOUSE_SIZE - Bigger Warehouses are more powerful but also cost more
		AUTO_SUSPEND - Time is in seconds
		COMMENT - Fill in Warehouse name as the PROJECT
	*/
	​
	USE ROLE SYSADMIN
	;
	​
	​
	CREATE WAREHOUSE IF NOT EXISTS <Environent>_WH_<Warehouse Name>
		WAREHOUSE_SIZE = XSMALL | SMALL | MEDIUM | LARGE | XLARGE | XXLARGE | XXXLARGE | X4LARGE | X5LARGE | X6LARGE
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60 | 90 | 120 | 150 | 180 | 210 | 240 | 270 | 300 (Time is in Seconds)
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE
	;


	-- Example:
	USE ROLE SYSADMIN
	;
	​
	​
	CREATE WAREHOUSE IF NOT EXISTS PRD_WH_POWER_BI
		WAREHOUSE_SIZE = XSMALL
		MAX_CLUSTER_COUNT = 1
		MIN_CLUSTER_COUNT = 1
		AUTO_SUSPEND = 60
		AUTO_RESUME = TRUE
		INITIALLY_SUSPENDED = TRUE
	;