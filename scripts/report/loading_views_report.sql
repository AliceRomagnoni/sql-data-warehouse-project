/*
===============================================================================
DDL Script: Create Report Views
===============================================================================

Script Purpose:
    This script creates views for the Report layer in the data warehouse.
    The Report layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Clean layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.

===============================================================================
*/

-- =============================================================================
-- Create Dimension: report.dim_customers
-- =============================================================================

IF OBJECT_ID('report.dim_customers', 'V') IS NOT NULL
    DROP VIEW report.dim_customers;
GO


CREATE VIEW report.dim_customers AS
	SELECT 
		ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
		ci.cst_id AS customer_id,
		ci.cst_key as customer_number,
		ci.cst_firstname as first_name,
		ci.cst_lastname as last_name,
		la.cntry as country,
		ci.cst_marital_status as marital_status,
		CASE WHEN ci.cst_gndr!='Unknown' THEN ci.cst_gndr --CRM is the master for the gender info
			ELSE COALESCE(ca.gen,'Unknown')
		END AS gender,
		ca.bdate as birthdate,
		ci.cst_create_date as create_date
	FROM clean.crm_cust_info ci
	LEFT JOIN clean.erp_cust_az12 ca on ci.cst_key= ca.cid
	LEFT JOIN clean.erp_loc_a101 la on ci.cst_key=la.cid
GO	
-- =============================================================================
-- Create Dimension: report.dim_customers
-- =============================================================================

IF OBJECT_ID('report.dim_products', 'V') IS NOT NULL
    DROP VIEW report.dim_products;
GO

CREATE VIEW report.dim_products AS
	SELECT 
		ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt ,pn.prd_key) AS product_key,
		pn.prd_id as product_id,
		pn.prd_key as product_number,
		pn.prd_nm as product_name,
		pn.cat_id as category_id,
		pc.cat as category,
		pc.subcat as subcategory,
		pc.maintenance,
		pn.prd_cost as product_cost,
		pn.prd_line as product_line,
		pn.prd_start_dt as start_date
	FROM clean.crm_prd_info pn
	LEFT JOIN clean.erp_px_cat_g1v2 pc ON pn.cat_id=pc.id 
	WHERE pn.prd_end_dt IS NULL-- FILTER OUT HISTORICAL DATA
GO
-- =============================================================================
-- Create Dimension: report.dim_customers
-- =============================================================================

IF OBJECT_ID('report.fact_sales', 'V') IS NOT NULL
    DROP VIEW report.fact_sales;
GO
	
CREATE VIEW report.fact_sales AS
	SELECT 
		sd.sls_ord_num as order_number,
		pr.product_key  ,
		cu.customer_key  ,
		sd.sls_order_dt as order_date,
		sd.sls_ship_dt as shipping_date ,
		sd.sls_due_dt as due_date,
		sd.sls_sales as sales_amount,
		sd.sls_quantity as quantity,
		sd.sls_price as price
	FROM clean.crm_sales_details sd 
	LEFT JOIN report.dim_customers cu ON cu.customer_id =sd.sls_cust_id 
	LEFT JOIN report.dim_products pr ON pr.product_number =sd.sls_prd_key 
