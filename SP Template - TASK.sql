-- This SP template is used to build Store Procedures that will be scheduled via a Snowflake TASK

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
			
			
			-- Verify whether or not the <Task_Name> task exists within the DB_KKF_MAIN.AUTOMATION.TASK_LIST table in Snowflake
				-- Update the <Task_Name> task record within the DB_KKF_MAIN.AUTOMATION.TASK_LIST table in Snowflake if it already exists
				-- Insert the <Task_Name> task record into the DB_KKF_MAIN.AUTOMATION.TASK_LIST table in Snowflake if it does NOT already exist
			MERGE INTO DB_KKF_MAIN.AUTOMATION.TASK_LIST T
				USING
				(
					-- Assign the necessary values for each column
					SELECT
						'<Task_Name>' AS TASK_NAME
						,'<Task_Description>' AS TASK_DESCRIPTION
						,'<Task_Frequency>' AS TASK_FREQUENCY
						,'<Task_Day_Of_Week>' AS TASK_DAY_OF_WEEK
						,'<Task_Time_Of_Day> EST' AS TASK_TIME_OF_DAY
						,NULL AS TASK_PREDECESSOR_NAME
						,CURRENT_DATE() AS TASK_LAST_RUN_START_DATE
						,TO_TIME(CONVERT_TIMEZONE('America/New_York', CURRENT_TIMESTAMP())) AS TASK_LAST_RUN_START_TIME_IN_EST
						,NULL AS TASK_LAST_RUN_END_DATE
						,NULL AS TASK_LAST_RUN_END_TIME_IN_EST
						,NULL AS TASK_LAST_RUN_DURATION_IN_SECONDS
				) S
				ON T.TASK_NAME = S.TASK_NAME
				
				-- Update the <Task_Name> task record within the DB_KKF_MAIN.AUTOMATION.TASK_LIST table in Snowflake
				-- Set the TASK_LAST_RUN_START_DATE & TASK_LAST_RUN_START_TIME_IN_EST with the current date and time in EST that the TASK started
				WHEN MATCHED
					THEN UPDATE SET
						T.TASK_LAST_RUN_START_DATE = S.TASK_LAST_RUN_START_DATE
						,T.TASK_LAST_RUN_START_TIME_IN_EST = S.TASK_LAST_RUN_START_TIME_IN_EST
				
				-- Insert the <Task_Name> task record into the DB_KKF_MAIN.AUTOMATION.TASK_LIST table in Snowflake
				WHEN NOT MATCHED
					THEN INSERT VALUES
					(
						S.TASK_NAME
						,S.TASK_DESCRIPTION
						,S.TASK_FREQUENCY
						,S.TASK_DAY_OF_WEEK
						,S.TASK_TIME_OF_DAY
						,S.TASK_PREDECESSOR_NAME
						,S.TASK_LAST_RUN_START_DATE
						,S.TASK_LAST_RUN_START_TIME_IN_EST
						,S.TASK_LAST_RUN_END_DATE
						,S.TASK_LAST_RUN_END_TIME_IN_EST
						,S.TASK_LAST_RUN_DURATION_IN_SECONDS
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
			
			
			-- Update the <Task_Name> task record within the DB_KKF_MAIN.AUTOMATION.TASK_LIST table in Snowflake
			-- Set the TASK_LAST_RUN_END_DATE & TASK_LAST_RUN_END_TIME_IN_EST with the current date and time in EST that the TASK started
			UPDATE DB_KKF_MAIN.AUTOMATION.TASK_LIST
				SET
					TASK_LAST_RUN_END_DATE = CURRENT_DATE()
					,TASK_LAST_RUN_END_TIME_IN_EST = TO_TIME(CONVERT_TIMEZONE('America/New_York', CURRENT_TIMESTAMP()))
				
				WHERE TASK_NAME = '<Task_Name>'
			;
			
			/*
			-- Update the <Task_Name> task record within the DB_KKF_MAIN.AUTOMATION.TASK_LIST table in Snowflake
			-- Set the TASK_LAST_RUN_DURATION_IN_SECONDS updated value from taking the difference between the task start date and time and task end date and time
			UPDATE DB_KKF_MAIN.AUTOMATION.TASK_LIST
				SET TASK_LAST_RUN_DURATION_IN_SECONDS = DATEDIFF
				(
					SECOND
					,TASK_LAST_RUN_START_TIME_IN_EST
					,TASK_LAST_RUN_END_TIME_IN_EST
				)
				
				WHERE TASK_NAME = '<Task_Name>'
			;
			*/
			
			-- Load the updated <Task_Name> task record into the DB_KKF_MAIN.AUTOMATION.TASK_RUN_HISTORY table in Snowflake that keeps history of all task runs
			INSERT INTO DB_KKF_MAIN.AUTOMATION.TASK_RUN_HISTORY
			
				SELECT *
				
				FROM DB_KKF_MAIN.AUTOMATION.TASK_LIST
				
				WHERE TASK_NAME = '<Task_Name>'
			;
		
		END;
		
	$$
	;
