USE DATABASE DB_KKF_MAIN;



CREATE OR REPLACE STAGE STG_AZURE_BLOB_TOAST_JSON
    URL = 'azure://krispykrunchychicken.blob.core.windows.net/toast-json-files'
    CREDENTIALS = (AZURE_SAS_TOKEN = '?sp=racwdli&st=2024-09-18T20:43:16Z&se=2035-12-31T19:59:59Z&spr=https&sv=2022-11-02&sr=c&sig=xge3XNZLx9v36%2FdLY5q4dgqH0pIF2HeoO8enp4Qp2ko%3D')
    FILE_FORMAT = FF_JSON
;



CREATE OR REPLACE TABLE DB_KKF_MAIN.JSON.TOAST_ORDER
(
    ORDER_JSON VARIANT
)
;



-- Loads the JSON file into the Snowflake JSON Schema table
COPY INTO DB_KKF_MAIN.JSON.TOAST_ORDER
    FROM @STG_AZURE_BLOB_TOAST_JSON/Orders/Orders.json
    FILE_FORMAT = (TYPE = JSON);
;



-- Displays all JSON data within the Snowflake JSON Schema table
-- Copy and paste one value from the ORDER_JSON column into Notepad++ to identify the JSON record format
SELECT ORDER_JSON FROM DB_KKF_MAIN.JSON.TOAST_ORDER
;




-- List all outermost fields from the above query results for a single record into the SELECT statement in order to identify the 1st round of potential columns
-- The VALUE column identifies additional potential columns located within the checks square brackets []
    -- COPY and past one value from the CHECKS column into Notepad++ to identify the 2nd round of additional potential columns
SELECT
    ORDER_JSON:appliedPackagingInfo:: STRING AS APPLIED_PACKAGING_INFO
    ,ORDER_JSON:approvalStatus:: STRING AS APPROVAL_STATUS
    ,ORDER_JSON:businessDate:: STRING AS BUSINESS_DATE
    ,ORDER_JSON:channelGuid:: STRING AS CHANNEL_GUID
    ,VALUE AS CHECKS
    ,ORDER_JSON:closedDate:: STRING AS CLOSED_DATE
    ,ORDER_JSON:createdDate:: STRING AS CREATED_DATE
    ,ORDER_JSON:createdDevice.id:: STRING AS CREATED_DEVICE_ID
    ,ORDER_JSON:createdInTestMode:: STRING AS CREATED_IN_TEST_MODE
    ,ORDER_JSON:curbsidePickupInfo:: STRING AS CURBSIDE_PICKUP_INFO
    ,ORDER_JSON:deleted:: STRING AS DELETED
    ,ORDER_JSON:deletedDate:: STRING AS DELETED_DATE
    ,ORDER_JSON:deliveryInfo:: STRING AS DELIVERY_INFO
    ,ORDER_JSON:diningOption:: STRING AS DINING_OPTION
    ,ORDER_JSON:displayNumber:: STRING AS DISPLAY_NUMBER
    ,ORDER_JSON:duration:: STRING AS DURATION
    ,ORDER_JSON:entityType:: STRING AS ENTITY_TYPE
    ,ORDER_JSON:estimatedFulfillmentDate:: STRING AS ESTIMATED_FULFILLMENT_DATE
    ,ORDER_JSON:excessFood:: STRING AS EXCESS_FOOD
    ,ORDER_JSON:externalId:: STRING AS EXTERNAL_ID
    ,ORDER_JSON:guid:: STRING AS GUID
    ,ORDER_JSON:lastModifiedDevice.id:: STRING AS LAST_MODIFIED_DEVICE_ID
    ,ORDER_JSON:modifiedDate:: STRING AS MODIFIED_DATE
    ,ORDER_JSON:numberOfGuests:: STRING AS NUMBER_OF_GUESTS
    ,ORDER_JSON:openedDate:: STRING AS OPENED_DATE
    ,ORDER_JSON:paidDate:: STRING AS PAID_DATE
    ,ORDER_JSON:pricingFeatures.TAXESV2:: STRING AS PRICING_FEATURES_TAXES_V2
    ,ORDER_JSON:requiredPrepTime:: STRING AS REQUIRED_PREP_TIME
    ,ORDER_JSON:restaurantService.entityType:: STRING AS RESTAURANT_SERVICE_ENTITY_TYPE
    ,ORDER_JSON:restaurantService.externalId:: STRING AS RESTAURANT_SERVICE_EXTERNAL_ID
    ,ORDER_JSON:restaurantService.guid:: STRING AS RESTAURANTSERVICE_GUID
    ,ORDER_JSON:revenueCenter.entityType:: STRING AS REVENUE_CENTER_ENTITY_TYPE
    ,ORDER_JSON:revenueCenter.externalId:: STRING AS REVENUE_CENTER_EXTERNAL_ID
    ,ORDER_JSON:revenueCenter.guid:: STRING AS REVENUE_CENTER_GUID
    ,ORDER_JSON:server.entityType:: STRING AS SERVER_ENTITY_TYPE
    ,ORDER_JSON:server.externalId:: STRING AS SERVER_EXTERNAL_ID
    ,ORDER_JSON:server.guid:: STRING AS SERVER_GUID
    ,ORDER_JSON:serviceArea:: STRING AS SERVICE_AREA
    ,ORDER_JSON:source:: STRING AS SOURCE
    ,ORDER_JSON:table:: STRING AS TABLE_NAME
    ,ORDER_JSON:voidBusinessDate:: STRING AS VOID_BUSINESS_DATE
    ,ORDER_JSON:voidDate:: STRING AS VOID_DATE
    ,ORDER_JSON:voided:: STRING AS VOIDED

FROM
    DB_KKF_MAIN.JSON.TOAST_ORDER

    ,LATERAL FLATTEN(INPUT => ORDER_JSON:checks)
;



-- Add to the list of columns, the innermost fields from the above query results for a single record into the SELECT statement in order to identify the 2nd round of potential columns
    -- Be sure to replace the ORDER_JSON column name infront of all innermost field names with VALUE
SELECT
    ORDER_JSON:appliedPackagingInfo:: STRING AS APPLIED_PACKAGING_INFO
    ,ORDER_JSON:approvalStatus:: STRING AS APPROVAL_STATUS
    ,ORDER_JSON:businessDate:: STRING AS BUSINESS_DATE
    ,ORDER_JSON:channelGuid:: STRING AS CHANNEL_GUID
    ,VALUE:amount:: STRING AS AMOUNT
    ,VALUE:appliedDiscounts:: STRING AS APPLIED_DISCOUNTS
    ,VALUE:appliedLoyaltyInfo:: STRING AS APPLIED_LOYALTY_INFO
    ,VALUE:appliedServiceCharges:: STRING AS APPLIED_SERVICE_CHARGES
    ,VALUE:closedDate:: STRING AS CLOSED_DATE
    ,VALUE:createdDate:: STRING AS CREATED_DATE
    ,VALUE:createdDevice.id:: STRING AS CREATED_DEVICE_ID
    ,VALUE:customer:: STRING AS CUSTOMER
    ,VALUE:deleted:: STRING AS DELETED
    ,VALUE:deletedDate:: STRING AS DELETED_DATE
    ,VALUE:displayNumber:: STRING AS DISPLAY_NUMBER
    ,VALUE:duration:: STRING AS DURATION
    ,VALUE:entityType:: STRING AS ENTITY_TYPE
    ,VALUE:externalId:: STRING AS EXTERNAL_ID
    ,VALUE:guid:: STRING AS GUID
    ,VALUE:lastModifiedDevice.id:: STRING AS LAST_MODIFIED_DEVICE_ID
    ,VALUE:modifiedDate:: STRING AS MODIFIED_DATE
    ,VALUE:openedBy:: STRING AS OPENED_BY
    ,VALUE:openedDate:: STRING AS OPENED_DATE
    ,VALUE:paidDate:: STRING AS PAID_DATE
    ,VALUE:paymentStatus:: STRING AS PAYMENT_STATUS
    ,VALUE:payments:: STRING AS PAYMENTS
    ,VALUE:selections:: STRING AS SELECTIONS
    ,VALUE:tabName:: STRING AS TAB_NAME
    ,VALUE:taxAmount:: STRING AS TAX_AMOUNT
    ,VALUE:taxExempt:: STRING AS TAX_EXEMPT
    ,VALUE:taxExemptionAccount:: STRING AS TAX_EXEMPTION_ACCOUNT
    ,VALUE:totalAmount:: STRING AS TOTAL_AMOUNT
    ,VALUE:voidBusinessDate:: STRING AS VOID_BUSINESS_DATE
    ,VALUE:voidDate:: STRING AS VOID_DATE
    ,VALUE:voided:: STRING AS VOIDED
    ,ORDER_JSON:closedDate:: STRING AS CLOSED_DATE
    ,ORDER_JSON:createdDate:: STRING AS CREATED_DATE
    ,ORDER_JSON:createdDevice.id:: STRING AS CREATED_DEVICE_ID
    ,ORDER_JSON:createdInTestMode:: STRING AS CREATED_IN_TEST_MODE
    ,ORDER_JSON:curbsidePickupInfo:: STRING AS CURBSIDE_PICKUP_INFO
    ,ORDER_JSON:deleted:: STRING AS DELETED
    ,ORDER_JSON:deletedDate:: STRING AS DELETED_DATE
    ,ORDER_JSON:deliveryInfo:: STRING AS DELIVERY_INFO
    ,ORDER_JSON:diningOption:: STRING AS DINING_OPTION
    ,ORDER_JSON:displayNumber:: STRING AS DISPLAY_NUMBER
    ,ORDER_JSON:duration:: STRING AS DURATION
    ,ORDER_JSON:entityType:: STRING AS ENTITY_TYPE
    ,ORDER_JSON:estimatedFulfillmentDate:: STRING AS ESTIMATED_FULFILLMENT_DATE
    ,ORDER_JSON:excessFood:: STRING AS EXCESS_FOOD
    ,ORDER_JSON:externalId:: STRING AS EXTERNAL_ID
    ,ORDER_JSON:guid:: STRING AS GUID
    ,ORDER_JSON:lastModifiedDevice.id:: STRING AS LAST_MODIFIED_DEVICE_ID
    ,ORDER_JSON:modifiedDate:: STRING AS MODIFIED_DATE
    ,ORDER_JSON:numberOfGuests:: STRING AS NUMBER_OF_GUESTS
    ,ORDER_JSON:openedDate:: STRING AS OPENED_DATE
    ,ORDER_JSON:paidDate:: STRING AS PAID_DATE
    ,ORDER_JSON:pricingFeatures.TAXESV2:: STRING AS PRICING_FEATURES_TAXES_V2
    ,ORDER_JSON:requiredPrepTime:: STRING AS REQUIRED_PREP_TIME
    ,ORDER_JSON:restaurantService.entityType:: STRING AS RESTAURANT_SERVICE_ENTITY_TYPE
    ,ORDER_JSON:restaurantService.externalId:: STRING AS RESTAURANT_SERVICE_EXTERNAL_ID
    ,ORDER_JSON:restaurantService.guid:: STRING AS RESTAURANTSERVICE_GUID
    ,ORDER_JSON:revenueCenter.entityType:: STRING AS REVENUE_CENTER_ENTITY_TYPE
    ,ORDER_JSON:revenueCenter.externalId:: STRING AS REVENUE_CENTER_EXTERNAL_ID
    ,ORDER_JSON:revenueCenter.guid:: STRING AS REVENUE_CENTER_GUID
    ,ORDER_JSON:server.entityType:: STRING AS SERVER_ENTITY_TYPE
    ,ORDER_JSON:server.externalId:: STRING AS SERVER_EXTERNAL_ID
    ,ORDER_JSON:server.guid:: STRING AS SERVER_GUID
    ,ORDER_JSON:serviceArea:: STRING AS SERVICE_AREA
    ,ORDER_JSON:source:: STRING AS SOURCE
    ,ORDER_JSON:table:: STRING AS TABLE_NAME
    ,ORDER_JSON:voidBusinessDate:: STRING AS VOID_BUSINESS_DATE
    ,ORDER_JSON:voidDate:: STRING AS VOID_DATE
    ,ORDER_JSON:voided:: STRING AS VOIDED

FROM
    DB_KKF_MAIN.JSON.TOAST_ORDER

    ,LATERAL FLATTEN(INPUT => ORDER_JSON:checks)
;



CREATE OR REPLACE TABLE DB_KKF_MAIN.TRANSIENT.TOAST_ORDER
(
    APPLIED_PACKAGING_INFO AS VARCHAR
    ,APPROVAL_STATUS AS VARCHAR
    ,BUSINESS_DATE AS VARCHAR
    ,CHANNEL_GUID AS VARCHAR
    ,CHECK_AMOUNT AS VARCHAR
    ,CHECK_APPLIED_DISCOUNTS AS VARCHAR
    ,CHECK_APPLIED_LOYALTY_INFO AS VARCHAR
    ,CHECK_APPLIED_SERVICE_CHARGES AS VARCHAR
    ,CHECK_CLOSED_DATE AS VARCHAR
    ,CHECK_CREATED_DATE AS VARCHAR
    ,CHECK_CREATED_DEVICE_ID AS VARCHAR
    ,CHECK_CUSTOMER AS VARCHAR
    ,CHECK_DELETED AS VARCHAR
    ,CHECK_DELETED_DATE AS VARCHAR
    ,CHECK_DISPLAY_NUMBER AS VARCHAR
    ,CHECK_DURATION AS VARCHAR
    ,CHECK_ENTITY_TYPE AS VARCHAR
    ,CHECK_EXTERNAL_ID AS VARCHAR
    ,CHECK_GUID AS VARCHAR
    ,CHECK_LAST_MODIFIED_DEVICE_ID AS VARCHAR
    ,CHECK_MODIFIED_DATE AS VARCHAR
    ,CHECK_OPENED_BY AS VARCHAR
    ,CHECK_OPENED_DATE AS VARCHAR
    ,CHECK_PAID_DATE AS VARCHAR
    ,CHECK_PAYMENT_STATUS AS VARCHAR
    ,CHECK_PAYMENTS AS VARCHAR
    ,CHECK_SELECTIONS AS VARCHAR
    ,CHECK_TAB_NAME AS VARCHAR
    ,CHECK_TAX_AMOUNT AS VARCHAR
    ,CHECK_TAX_EXEMPT AS VARCHAR
    ,CHECK_TAX_EXEMPTION_ACCOUNT AS VARCHAR
    ,CHECK_TOTAL_AMOUNT AS VARCHAR
    ,CHECK_VOID_BUSINESS_DATE AS VARCHAR
    ,CHECK_VOID_DATE AS VARCHAR
    ,CHECK_VOIDED AS VARCHAR
    ,CLOSED_DATE AS VARCHAR
    ,CREATED_DATE AS VARCHAR
    ,CREATED_DEVICE_ID AS VARCHAR
    ,CREATED_IN_TEST_MODE AS VARCHAR
    ,CURBSIDE_PICKUP_INFO AS VARCHAR
    ,DELETED AS VARCHAR
    ,DELETED_DATE AS VARCHAR
    ,DELIVERY_INFO AS VARCHAR
    ,DINING_OPTION AS VARCHAR
    ,DISPLAY_NUMBER AS VARCHAR
    ,DURATION AS VARCHAR
    ,ENTITY_TYPE AS VARCHAR
    ,ESTIMATED_FULFILLMENT_DATE AS VARCHAR
    ,EXCESS_FOOD AS VARCHAR
    ,EXTERNAL_ID AS VARCHAR
    ,GUID AS VARCHAR
    ,LAST_MODIFIED_DEVICE_ID AS VARCHAR
    ,MODIFIED_DATE AS VARCHAR
    ,NUMBER_OF_GUESTS AS VARCHAR
    ,OPENED_DATE AS VARCHAR
    ,PAID_DATE AS VARCHAR
    ,PRICING_FEATURES_TAXES_V2 AS VARCHAR
    ,REQUIRED_PREP_TIME AS VARCHAR
    ,RESTAURANT_SERVICE_ENTITY_TYPE AS VARCHAR
    ,RESTAURANT_SERVICE_EXTERNAL_ID AS VARCHAR
    ,RESTAURANTSERVICE_GUID AS VARCHAR
    ,REVENUE_CENTER_ENTITY_TYPE AS VARCHAR
    ,REVENUE_CENTER_EXTERNAL_ID AS VARCHAR
    ,REVENUE_CENTER_GUID AS VARCHAR
    ,SERVER_ENTITY_TYPE AS VARCHAR
    ,SERVER_EXTERNAL_ID AS VARCHAR
    ,SERVER_GUID AS VARCHAR
    ,SERVICE_AREA AS VARCHAR
    ,SOURCE AS VARCHAR
    ,TABLE_NAME AS VARCHAR
    ,VOID_BUSINESS_DATE AS VARCHAR
    ,VOID_DATE AS VARCHAR
    ,VOIDED AS VARCHAR
)
;



-- Insert parsed out JSON records into the Snowflake Transient Schema table
INSERT INTO DB_KKF_MAIN.TRANSIENT.TOAST_ORDER

    SELECT
        ORDER_JSON:appliedPackagingInfo::	STRING	AS	APPLIED_PACKAGING_INFO
        ,ORDER_JSON:approvalStatus::	STRING	AS	APPROVAL_STATUS
        ,ORDER_JSON:businessDate::	STRING	AS	BUSINESS_DATE
        ,ORDER_JSON:channelGuid::	STRING	AS	CHANNEL_GUID
        ,VALUE:amount::	STRING	AS	CHECK_AMOUNT
        ,VALUE:appliedDiscounts::	STRING	AS	CHECK_APPLIED_DISCOUNTS
        ,VALUE:appliedLoyaltyInfo::	STRING	AS	CHECK_APPLIED_LOYALTY_INFO
        ,VALUE:appliedServiceCharges::	STRING	AS	CHECK_APPLIED_SERVICE_CHARGES
        ,VALUE:closedDate::	STRING	AS	CHECK_CLOSED_DATE
        ,VALUE:createdDate::	STRING	AS	CHECK_CREATED_DATE
        ,VALUE:createdDevice.id::	STRING	AS	CHECK_CREATED_DEVICE_ID
        ,VALUE:customer::	STRING	AS	CHECK_CUSTOMER
        ,VALUE:deleted::	STRING	AS	CHECK_DELETED
        ,VALUE:deletedDate::	STRING	AS	CHECK_DELETED_DATE
        ,VALUE:displayNumber::	STRING	AS	CHECK_DISPLAY_NUMBER
        ,VALUE:duration::	STRING	AS	CHECK_DURATION
        ,VALUE:entityType::	STRING	AS	CHECK_ENTITY_TYPE
        ,VALUE:externalId::	STRING	AS	CHECK_EXTERNAL_ID
        ,VALUE:guid::	STRING	AS	CHECK_GUID
        ,VALUE:lastModifiedDevice.id::	STRING	AS	CHECK_LAST_MODIFIED_DEVICE_ID
        ,VALUE:modifiedDate::	STRING	AS	CHECK_MODIFIED_DATE
        ,VALUE:openedBy::	STRING	AS	CHECK_OPENED_BY
        ,VALUE:openedDate::	STRING	AS	CHECK_OPENED_DATE
        ,VALUE:paidDate::	STRING	AS	CHECK_PAID_DATE
        ,VALUE:paymentStatus::	STRING	AS	CHECK_PAYMENT_STATUS
        ,VALUE:payments::	STRING	AS	CHECK_PAYMENTS
        ,VALUE:selections::	STRING	AS	CHECK_SELECTIONS
        ,VALUE:tabName::	STRING	AS	CHECK_TAB_NAME
        ,VALUE:taxAmount::	STRING	AS	CHECK_TAX_AMOUNT
        ,VALUE:taxExempt::	STRING	AS	CHECK_TAX_EXEMPT
        ,VALUE:taxExemptionAccount::	STRING	AS	CHECK_TAX_EXEMPTION_ACCOUNT
        ,VALUE:totalAmount::	STRING	AS	CHECK_TOTAL_AMOUNT
        ,VALUE:voidBusinessDate::	STRING	AS	CHECK_VOID_BUSINESS_DATE
        ,VALUE:voidDate::	STRING	AS	CHECK_VOID_DATE
        ,VALUE:voided::	STRING	AS	CHECK_VOIDED
        ,ORDER_JSON:closedDate::	STRING	AS	CLOSED_DATE
        ,ORDER_JSON:createdDate::	STRING	AS	CREATED_DATE
        ,ORDER_JSON:createdDevice.id::	STRING	AS	CREATED_DEVICE_ID
        ,ORDER_JSON:createdInTestMode::	STRING	AS	CREATED_IN_TEST_MODE
        ,ORDER_JSON:curbsidePickupInfo::	STRING	AS	CURBSIDE_PICKUP_INFO
        ,ORDER_JSON:deleted::	STRING	AS	DELETED
        ,ORDER_JSON:deletedDate::	STRING	AS	DELETED_DATE
        ,ORDER_JSON:deliveryInfo::	STRING	AS	DELIVERY_INFO
        ,ORDER_JSON:diningOption::	STRING	AS	DINING_OPTION
        ,ORDER_JSON:displayNumber::	STRING	AS	DISPLAY_NUMBER
        ,ORDER_JSON:duration::	STRING	AS	DURATION
        ,ORDER_JSON:entityType::	STRING	AS	ENTITY_TYPE
        ,ORDER_JSON:estimatedFulfillmentDate::	STRING	AS	ESTIMATED_FULFILLMENT_DATE
        ,ORDER_JSON:excessFood::	STRING	AS	EXCESS_FOOD
        ,ORDER_JSON:externalId::	STRING	AS	EXTERNAL_ID
        ,ORDER_JSON:guid::	STRING	AS	GUID
        ,ORDER_JSON:lastModifiedDevice.id::	STRING	AS	LAST_MODIFIED_DEVICE_ID
        ,ORDER_JSON:modifiedDate::	STRING	AS	MODIFIED_DATE
        ,ORDER_JSON:numberOfGuests::	STRING	AS	NUMBER_OF_GUESTS
        ,ORDER_JSON:openedDate::	STRING	AS	OPENED_DATE
        ,ORDER_JSON:paidDate::	STRING	AS	PAID_DATE
        ,ORDER_JSON:pricingFeatures.TAXESV2::	STRING	AS	PRICING_FEATURES_TAXES_V2
        ,ORDER_JSON:requiredPrepTime::	STRING	AS	REQUIRED_PREP_TIME
        ,ORDER_JSON:restaurantService.entityType::	STRING	AS	RESTAURANT_SERVICE_ENTITY_TYPE
        ,ORDER_JSON:restaurantService.externalId::	STRING	AS	RESTAURANT_SERVICE_EXTERNAL_ID
        ,ORDER_JSON:restaurantService.guid::	STRING	AS	RESTAURANTSERVICE_GUID
        ,ORDER_JSON:revenueCenter.entityType::	STRING	AS	REVENUE_CENTER_ENTITY_TYPE
        ,ORDER_JSON:revenueCenter.externalId::	STRING	AS	REVENUE_CENTER_EXTERNAL_ID
        ,ORDER_JSON:revenueCenter.guid::	STRING	AS	REVENUE_CENTER_GUID
        ,ORDER_JSON:server.entityType::	STRING	AS	SERVER_ENTITY_TYPE
        ,ORDER_JSON:server.externalId::	STRING	AS	SERVER_EXTERNAL_ID
        ,ORDER_JSON:server.guid::	STRING	AS	SERVER_GUID
        ,ORDER_JSON:serviceArea::	STRING	AS	SERVICE_AREA
        ,ORDER_JSON:source::	STRING	AS	SOURCE
        ,ORDER_JSON:table::	STRING	AS	TABLE_NAME
        ,ORDER_JSON:voidBusinessDate::	STRING	AS	VOID_BUSINESS_DATE
        ,ORDER_JSON:voidDate::	STRING	AS	VOID_DATE
        ,ORDER_JSON:voided::	STRING	AS	VOIDED
    
    FROM
        DB_KKF_MAIN.JSON.TOAST_ORDER
    
        ,LATERAL FLATTEN(INPUT => ORDER_JSON:checks)
    ;



CREATE OR REPLACE TABLE DB_KKF_MAIN.TRANSIENT.TOAST_ORDER
(
    APPLIED_PACKAGING_INFO AS VARCHAR()
    ,APPROVAL_STATUS AS VARCHAR()
    ,BUSINESS_DATE AS VARCHAR()
    ,CHANNEL_GUID AS VARCHAR()
    ,CHECK_AMOUNT AS VARCHAR()
    ,CHECK_APPLIED_DISCOUNTS AS VARCHAR()
    ,CHECK_APPLIED_LOYALTY_INFO AS VARCHAR()
    ,CHECK_APPLIED_SERVICE_CHARGES AS VARCHAR()
    ,CHECK_CLOSED_DATE AS VARCHAR()
    ,CHECK_CREATED_DATE AS VARCHAR()
    ,CHECK_CREATED_DEVICE_ID AS VARCHAR()
    ,CHECK_CUSTOMER AS VARCHAR()
    ,CHECK_DELETED AS VARCHAR()
    ,CHECK_DELETED_DATE AS VARCHAR()
    ,CHECK_DISPLAY_NUMBER AS VARCHAR()
    ,CHECK_DURATION AS VARCHAR()
    ,CHECK_ENTITY_TYPE AS VARCHAR()
    ,CHECK_EXTERNAL_ID AS VARCHAR()
    ,CHECK_GUID AS VARCHAR()
    ,CHECK_LAST_MODIFIED_DEVICE_ID AS VARCHAR()
    ,CHECK_MODIFIED_DATE AS VARCHAR()
    ,CHECK_OPENED_BY AS VARCHAR()
    ,CHECK_OPENED_DATE AS VARCHAR()
    ,CHECK_PAID_DATE AS VARCHAR()
    ,CHECK_PAYMENT_STATUS AS VARCHAR()
    ,CHECK_PAYMENTS AS VARCHAR()
    ,CHECK_SELECTIONS AS VARCHAR()
    ,CHECK_TAB_NAME AS VARCHAR()
    ,CHECK_TAX_AMOUNT AS VARCHAR()
    ,CHECK_TAX_EXEMPT AS VARCHAR()
    ,CHECK_TAX_EXEMPTION_ACCOUNT AS VARCHAR()
    ,CHECK_TOTAL_AMOUNT AS VARCHAR()
    ,CHECK_VOID_BUSINESS_DATE AS VARCHAR()
    ,CHECK_VOID_DATE AS VARCHAR()
    ,CHECK_VOIDED AS VARCHAR()
    ,CLOSED_DATE AS VARCHAR()
    ,CREATED_DATE AS VARCHAR()
    ,CREATED_DEVICE_ID AS VARCHAR()
    ,CREATED_IN_TEST_MODE AS VARCHAR()
    ,CURBSIDE_PICKUP_INFO AS VARCHAR()
    ,DELETED AS VARCHAR()
    ,DELETED_DATE AS VARCHAR()
    ,DELIVERY_INFO AS VARCHAR()
    ,DINING_OPTION AS VARCHAR()
    ,DISPLAY_NUMBER AS VARCHAR()
    ,DURATION AS VARCHAR()
    ,ENTITY_TYPE AS VARCHAR()
    ,ESTIMATED_FULFILLMENT_DATE AS VARCHAR()
    ,EXCESS_FOOD AS VARCHAR()
    ,EXTERNAL_ID AS VARCHAR()
    ,GUID AS VARCHAR()
    ,LAST_MODIFIED_DEVICE_ID AS VARCHAR()
    ,MODIFIED_DATE AS VARCHAR()
    ,NUMBER_OF_GUESTS AS VARCHAR()
    ,OPENED_DATE AS VARCHAR()
    ,PAID_DATE AS VARCHAR()
    ,PRICING_FEATURES_TAXES_V2 AS VARCHAR()
    ,REQUIRED_PREP_TIME AS VARCHAR()
    ,RESTAURANT_SERVICE_ENTITY_TYPE AS VARCHAR()
    ,RESTAURANT_SERVICE_EXTERNAL_ID AS VARCHAR()
    ,RESTAURANTSERVICE_GUID AS VARCHAR()
    ,REVENUE_CENTER_ENTITY_TYPE AS VARCHAR()
    ,REVENUE_CENTER_EXTERNAL_ID AS VARCHAR()
    ,REVENUE_CENTER_GUID AS VARCHAR()
    ,SERVER_ENTITY_TYPE AS VARCHAR()
    ,SERVER_EXTERNAL_ID AS VARCHAR()
    ,SERVER_GUID AS VARCHAR()
    ,SERVICE_AREA AS VARCHAR()
    ,SOURCE AS VARCHAR()
    ,TABLE_NAME AS VARCHAR()
    ,VOID_BUSINESS_DATE AS VARCHAR()
    ,VOID_DATE AS VARCHAR()
    ,VOIDED AS VARCHAR()
)
;