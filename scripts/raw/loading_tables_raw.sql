/*
===============================================================================
Stored Procedure: Load Raw Layer (Source -> Raw)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'raw' schema from external CSV files.
    It performs the following actions:
    - Truncates the raw tables before loading data.
    - Uses the `BULK INSERT` command to load data from CSV files to raw tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC raw.load_raw;
===============================================================================
*/

CREATE OR ALTER PROCEDURE raw.load_raw AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	BEGIN TRY
		PRINT '========================================';
		PRINT 'Loading Row Layer';
		PRINT '========================================';
		
		SET @batch_start_time = GETDATE()
		PRINT '-----------------------';
		PRINT 'Loading CRM Tables';
		PRINT '-----------------------';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: crm_cust_info';
		TRUNCATE TABLE raw.crm_cust_info;
		
		PRINT '>> Loading Table: crm_cust_info';
		BULK INSERT raw.crm_cust_info
		FROM 'C:\Users\alice.romagnoni\Desktop\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH(
			FIRSTROW =2, --skip header
			FIELDTERMINATOR =',', --delimitator
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------'
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: crm_prd_info';
		TRUNCATE TABLE raw.crm_prd_info;
		
		PRINT '>> Loading Table: crm_prd_info';
		BULK INSERT raw.crm_prd_info
		FROM 'C:\Users\alice.romagnoni\Desktop\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW =2, --skip header
			FIELDTERMINATOR =',', --delimitator
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------'
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: crm_sales_details';
		TRUNCATE TABLE raw.crm_sales_details;
		
		PRINT '>> Loading Table: crm_sales_details';
		BULK INSERT raw.crm_sales_details
		FROM 'C:\Users\alice.romagnoni\Desktop\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW =2, --skip header
			FIELDTERMINATOR =',', --delimitator
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------'
		
		PRINT '-----------------------';
		PRINT 'Loading ERP Tables';
		PRINT '-----------------------';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: erp_loc_a101';
		TRUNCATE TABLE raw.erp_loc_a101;
		
		PRINT '>> Loading Table: erp_loc_a101';
		BULK INSERT raw.erp_loc_a101
		FROM 'C:\Users\alice.romagnoni\Desktop\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH(
			FIRSTROW =2, --skip header
			FIELDTERMINATOR =',', --delimitator
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------'
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: erp_cust_az12';
		TRUNCATE TABLE raw.erp_cust_az12;
		
		PRINT '>> Loading Table: erp_cust_az12';
		BULK INSERT raw.erp_cust_az12
		FROM 'C:\Users\alice.romagnoni\Desktop\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH(
			FIRSTROW =2, --skip header
			FIELDTERMINATOR =',', --delimitator
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------'
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: erp_px_cat_g1v2';
		TRUNCATE TABLE raw.erp_px_cat_g1v2;
		
		PRINT '>> Loading Table: erp_px_cat_g1v2';
		BULK INSERT raw.erp_px_cat_g1v2
		FROM 'C:\Users\alice.romagnoni\Desktop\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW =2, --skip header
			FIELDTERMINATOR =',', --delimitator
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------'
		
		SET @batch_end_time = GETDATE();
		PRINT '============================';
		PRINT 'Loading Raw Layer Completed';
		PRINT 'Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '============================';
		
		
	END TRY
	BEGIN CATCH
		PRINT '============================';
		PRINT 'ERROR OCCURED DURING LOADING RAW LAYER';
		PRINT 'Error Message '+ ERROR_MESSAGE();
		PRINT 'Error Message '+ CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT '============================';
	
	END CATCH
END
