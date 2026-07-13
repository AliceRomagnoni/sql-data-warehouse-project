/*
===============================================================================
Stored Procedure: Load Clean Layer (Raw -> Clean)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'clean' schema tables from the 'raw' schema.
	Actions Performed:
		- Truncates Clean tables.
		- Inserts transformed and cleansed data from Raw into Clean tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Clean.load_clean;
===============================================================================
*/

CREATE OR ALTER PROCEDURE clean.load_clean AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
  BEGIN TRY
    SET @batch_start_time = GETDATE();
    PRINT '================================================';
    PRINT 'Loading Clean Layer';
    PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT 'Truncating Table: clean.crm_cust_info';
		TRUNCATE TABLE clean.crm_cust_info;
		PRINT '>> Inserting data into: clean.crm_cust_info';
		INSERT INTO clean.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date)
		SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) as cst_firstname,
		TRIM(cst_lastname) as cst_lastname,
		CASE WHEN UPPER(TRIM(cst_marital_status)) ='S' THEN 'Single'
			 WHEN UPPER(TRIM(cst_marital_status)) ='M' THEN 'Married' 	 
			 ELSE 'Unknown' -- normalize marital values
		END cst_marital_status,
		CASE WHEN UPPER(TRIM(cst_gndr)) ='F' THEN 'Female'
			 WHEN UPPER(TRIM(cst_gndr)) ='M' THEN 'Male' 	 
			 ELSE 'Unknown' -- normalize gender values
		END cst_gndr,
		cst_create_date
		FROM (
			SELECT
				*,
				ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM raw.crm_cust_info
			WHERE cst_id IS NOT NULL
		) t
		WHERE flag_last = 1; -- Select the most recent record per customer
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		
		SET @start_time = GETDATE();
		PRINT 'Truncating Table: clean.crm_prd_info';
		TRUNCATE TABLE clean.crm_prd_info;
		PRINT '>> Inserting data into: clean.crm_prd_info';
		INSERT INTO clean.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
		prd_id,
		REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id, --extract category id
		SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key,-- extract product key
		prd_nm,
		ISNULL(prd_cost,0) as prd_cost,
		CASE UPPER(TRIM(prd_line))
			 WHEN 'M' THEN 'Mountain'
			 WHEN 'R' THEN 'Road'
			 WHEN 'S' THEN 'Other Sales'
			 WHEN 'T' THEN 'Touring'
			 ELSE 'Unknown'
		END AS prd_line, -- map product line
		CAST (prd_start_dt AS DATE) as prd_start_dt,
		CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE
		) as prd_end_dt -- calculate end date as 1 day before next start date
		FROM raw.crm_prd_info ;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		
		SET @start_time = GETDATE();
		PRINT 'Truncating Table: clean.crm_sales_details';
		TRUNCATE TABLE clean.crm_sales_details;
		PRINT '>> Inserting data into: clean.crm_sales_details';
		INSERT INTO clean.crm_sales_details (
			sls_ord_num ,
			sls_prd_key ,
			sls_cust_id ,
			sls_order_dt ,
			sls_ship_dt ,
			sls_due_dt ,
			sls_sales ,
			sls_quantity ,
			sls_price )
		SELECT 
		sls_ord_num ,
		sls_prd_key ,
		sls_cust_id ,
		CASE WHEN sls_order_dt=0 OR LEN(sls_order_dt)!=8 THEN NULL
			 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END sls_order_dt,
		CASE WHEN sls_ship_dt=0 OR LEN(sls_ship_dt)!=8 THEN NULL
			 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END sls_ship_dt,
		CASE WHEN sls_due_dt=0 OR LEN(sls_due_dt)!=8 THEN NULL
			 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END sls_due_dt,
		CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
			 THEN sls_quantity * ABS(sls_price)
			 ELSE sls_sales
		END AS sls_sales, -- recalculate sales if original value is missing or incorrect
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <=0 
			 THEN sls_sales / NULLIF(sls_quantity,0)
			 ELSE sls_price
		END AS sls_price -- derive price if original value is invalid
		FROM raw.crm_sales_details ;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT 'Truncating Table: clean.erp_cust_az12';
		TRUNCATE TABLE clean.erp_cust_az12;
		PRINT '>> Inserting data into: clean.erp_cust_az12';
		INSERT INTO clean.erp_cust_az12 (
		cid,
		bdate,
		gen)
		SELECT 
		CASE WHEN cid LIKE 'NAS%'
			 THEN SUBSTRING(cid,4,LEN(cid))
			 ELSE cid
		END cid, -- remove NAS prefix if present
		CASE WHEN bdate > GETDATE() THEN NULL 
			 ELSE bdate
		END bdate, --set future birthdates to null
		CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
			 WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
			 ELSE 'Unknown'
		END AS gen --normalize gender
		FROM raw.erp_cust_az12 
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		
		SET @start_time = GETDATE();
		PRINT 'Truncating Table: clean.erp_loc_a101';
		TRUNCATE TABLE clean.erp_loc_a101;
		PRINT '>> Inserting data into: clean.erp_loc_a101';
		INSERT INTO clean.erp_loc_a101 (
		cid,
		cntry)
		SELECT 
		REPLACE(cid,'-','') cid,
		CASE WHEN TRIM(UPPER(cntry)) = 'DE' THEN 'Germany'
			 WHEN TRIM(UPPER(cntry)) in ('US','USA') THEN 'United States'
			 WHEN TRIM(UPPER(cntry)) =' '  OR cntry IS NULL THEN 'Unknown'
			 ELSE TRIM(cntry)
		END cntry --normalize countries
		FROM raw.erp_loc_a101 ;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		
		SET @start_time = GETDATE();
		PRINT 'Truncating Table: clean.erp_px_cat_g1v2';
		TRUNCATE TABLE clean.erp_px_cat_g1v2;
		PRINT '>> Inserting data into: clean.erp_px_cat_g1v2';
		INSERT INTO clean.erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintenance)
		SELECT
		id,
		cat,
		subcat,
		maintenance
		FROM raw.erp_px_cat_g1v2  ;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
    PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
    PRINT '=========================================='
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
	
	
