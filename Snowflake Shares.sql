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