-- This SP template is used to build Store Procedures that will be ran manually

-- Create the SP_<SP_Name> stored procedure that will extract tha raw data from the DB_KKF_MAIN.TRANSIENT.<Transient_Table_Name> table
-- Transforms the data and loads into the DB_KKF_MAIN.<Presentation_Schema_Name>.<Fact_Or_Dim_Table_Name> table
CREATE OR REPLACE PROCEDURE DB_KKF_MAIN.PUBLIC.SP_<SP_Name>()
	RETURNS VARCHAR
	LANGUAGE SQL
	EXECUTE AS CALLER
	AS
	$$
	
		BEGIN
		
			-- Assume the SYSADMIN role
			USE ROLE SYSADMIN;
			
			-- Assume the <ELT_Warehouse_Name> ELT Production Warehouse
			USE WAREHOUSE <ELT_Warehouse_Name>;
			
			-- Assume the DB_KKF_MAIN database
			USE DATABASE DB_KKF_MAIN;
			
			
			-- Verify whether or not the SP_<SP_Name> stored procedure exists within the DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST table in Snowflake
				-- Update the SP_<SP_Name> record within the DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST table in Snowflake if it already exists
				-- Insert the SP_<SP_Name> record into the DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST table in Snowflake if it does NOT already exist
			MERGE INTO DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST T
				USING
				(
					-- Assign the necessary values for each column
					SELECT
						'SP_<SP_Name>' AS PROCEDURE_NAME
						,'<Procedure_Description>' AS PROCEDURE_DESCRIPTION
						,'<Procedure_Frequency>' AS PROCEDURE_FREQUENCY
						,'<Procedure_Day_Of_Week>' AS PROCEDURE_DAY_OF_WEEK
						,'<Procedure_Time_Of_Day> EST' AS PROCEDURE_TIME_OF_DAY
						,NULL AS PROCEDURE_PREDECESSOR_NAME
						,CURRENT_DATE() AS PROCEDURE_LAST_RUN_START_DATE
						,TO_TIME(CONVERT_TIMEZONE('America/New_York', CURRENT_TIMESTAMP())) AS PROCEDURE_LAST_RUN_START_TIME_IN_EST
						,NULL AS PROCEDURE_LAST_RUN_END_DATE
						,NULL AS PROCEDURE_LAST_RUN_END_TIME_IN_EST
						,NULL AS PROCEDURE_LAST_RUN_DURATION_IN_SECONDS
						,'<Task_Name>' AS TASK_NAME
				) S
				ON T.PROCEDURE_NAME = S.PROCEDURE_NAME
				
				-- Update the SP_<SP_Name> record within the DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST table in Snowflake
				-- Set the PROCEDURE_LAST_RUN_START_DATE & PROCEDURE_LAST_RUN_START_TIME_IN_EST with the current date and time in EST that the TASK started
				WHEN MATCHED
					THEN UPDATE SET
						T.PROCEDURE_LAST_RUN_START_DATE = S.PROCEDURE_LAST_RUN_START_DATE
						,T.PROCEDURE_LAST_RUN_START_TIME_IN_EST = S.PROCEDURE_LAST_RUN_START_TIME_IN_EST
				
				-- Insert the SP_<SP_Name> record into the DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST table in Snowflake
				WHEN NOT MATCHED
					THEN INSERT VALUES
					(
						S.PROCEDURE_NAME
						,S.PROCEDURE_DESCRIPTION
						,S.PROCEDURE_FREQUENCY
						,S.PROCEDURE_DAY_OF_WEEK
						,S.PROCEDURE_TIME_OF_DAY
						,S.PROCEDURE_PREDECESSOR_NAME
						,S.PROCEDURE_LAST_RUN_START_DATE
						,S.PROCEDURE_LAST_RUN_START_TIME_IN_EST
						,S.PROCEDURE_LAST_RUN_END_DATE
						,S.PROCEDURE_LAST_RUN_END_TIME_IN_EST
						,S.PROCEDURE_LAST_RUN_DURATION_IN_SECONDS
						,S.TASK_NAME
					)
			;
			
			
			-- Truncate tabe DB_KKF_MAIN.PERSISTED.DB_KKF_MAIN.PERSISTED.<Persisted_Table_Name> table so the data can be replace with updated data
			TRUNCATE TABLE DB_KKF_MAIN.PERSISTED.<Persisted_Table_Name>;
			
			
			-- Extract the raw data from the DB_KKF_MAIN.TRANSIENT.<Transient_Table_Name> table
			-- Transform the raw data to make it more useable for reporting purposes
			-- Load the transformed data into the DB_KKF_MAIN.PERSISTED.<Persisted_Table_Name> table
			INSERT INTO DB_KKF_MAIN.PERSISTED.<Persisted_Table_Name>
			
				SELECT
					<Column_1>
					,<Column_2>
					,<Column_N...>
				
				FROM DB_KKF_MAIN.TRANSIENT.<Transient_Table_Name>
			;
			
			
			-- Use either the Insert or Merge statement below based on load methods for the dataset
			
				-- Extract the raw data from the DB_KKF_MAIN.TRANSIENT.<Transient_Table_Name> table
				-- Transform the raw data to make it more useable for reporting purposes
				-- Load the transformed data into the DB_KKF_MAIN.PERSISTED.<Persisted_Table_Name> table
				INSERT INTO DB_KKF_MAIN.<Presentation_Schema_Name>.<Fact_Or_Dim_Table_Name>
				
					SELECT
						<Column_1>
						,<Column_2>
						,<Column_N...>
					
					FROM DB_KKF_MAIN.PERSISTED.<Persisted_Table_Name>
				;
				
				
				-- Extract the transformed data from the DB_KKF_MAIN.PERSISTED.<Persisted_Table_Name> table
				-- Load the transformed data into the DB_KKF_MAIN.<Presentation_Schema_Name>.<Fact_Or_Dim_Table_Name> table	
				MERGE INTO DB_KKF_MAIN.<Presentation_Schema_Name>.<Fact_Or_Dim_Table_Name> T
					USING
					(
						SELECT
							<Column_1>
							,<Column_2>
							,<Column_N...>
						
						FROM DB_KKF_MAIN.PERSISTED.<Persisted_Table_Name>
					) S
					ON T.<Column_1> = S.<Column_1>
					AND T.<Column_2> = S.<Column_2>
					AND T.<Column_N...> = S.<Column_N...>

					-- Insert new <Persisted_Table> records into the DB_KKF_MAIN.<Presentation_Schema_Name>.<Fact_Or_Dim_Table_Name> table in Snowflake
					WHEN NOT MATCHED
						THEN INSERT VALUES
						(
							S.<Column_1>
							,S.<Column_2>
							,S.<Column_N...>
						)
				;
			
			
			-- Truncate the DB_KKF_MAIN.TRANSIENT.<Transient_Table_Name> table to prepare it for the next day's data loads
			TRUNCATE TABLE DB_KKF_MAIN.TRANSIENT.<Transient_Table_Name>;
			
			
			-- Update the SP_<SP_Name> record within the DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST table in Snowflake
			-- Set the PROCEDURE_LAST_RUN_END_DATE & PROCEDURE_LAST_RUN_END_TIME_IN_EST with the current date and time in EST that the stored procedure started
			UPDATE DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST
				SET
					PROCEDURE_LAST_RUN_END_DATE = CURRENT_DATE()
					,PROCEDURE_LAST_RUN_END_TIME_IN_EST = TO_TIME(CONVERT_TIMEZONE('America/New_York', CURRENT_TIMESTAMP()))
				
				WHERE PROCEDURE_NAME = 'SP_<SP_Name>'	
			;
			
			/*
			-- Update the SP_<SP_Name> record within the DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST table in Snowflake
			-- Set the PROCEDURE_LAST_RUN_DURATION_IN_SECONDS updated value from taking the difference between the stored procedure start date and time and stored procedure end date and time
			UPDATE DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST
				SET PROCEDURE_LAST_RUN_DURATION_IN_SECONDS = DATEDIFF
				(
					SECOND
					,PROCEDURE_LAST_RUN_START_TIME_IN_EST
					,PROCEDURE_LAST_RUN_END_TIME_IN_EST
				)
				
				WHERE PROCEDURE_NAME = 'SP_<SP_Name>'
			;
			*/
			
			-- Load the updated SP_<SP_Name> record into the DB_KKF_MAIN.AUTOMATION.PROCEDURE_RUN_HISTORY table in Snowflake that keeps history of all stored procedure runs
			INSERT INTO DB_KKF_MAIN.AUTOMATION.PROCEDURE_RUN_HISTORY
			
				SELECT *
				
				FROM DB_KKF_MAIN.AUTOMATION.PROCEDURE_LIST
				
				WHERE PROCEDURE_NAME = 'SP_<SP_Name>'
			;
		
		END;
		
	$$
	;
