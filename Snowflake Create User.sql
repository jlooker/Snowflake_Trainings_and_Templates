---------------------------------------------------------------------------------------------
-- CREATE THE NEW USER WHO WILL HAVE ACCESS TO THE KKF MAIN DATA WAREHOUSE ------------------
-- NEW USERS TO THE KKF MAIN DATA WAREHOUSE SHOULD ONLY BE GIVEN TO PEOPLE MANAGED BY JOSH --
-- THIS WILL ENSURE DATA INTEGRITY AND SECURITY ---------------------------------------------
---------------------------------------------------------------------------------------------

USE ROLE USERADMIN;

CREATE USER <User_Name>
    PASSWORD = '<password>'
    EMAIL = '<Email_Address>'
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