/*
====================================================================
Create Database and Schemas
====================================================================

Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
    within the database: 'raw', 'clean', and 'report'.

WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution
    and ensure you have proper backups before running this script.
*/

USE master;
GO

--- create database. if it already exists, drop it and create it again

IF EXISTS (SELECT 1 FROM sys.databases WHERE name ='DataWarehouse')
BEGIN
  ALTER DATABASE DataWarehaouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE DataWarehouse;
END;
GO

  --- create database
CREATE DATABASE DataWarehouse;
GO
  
USE DataWarehouse;
GO
  
--- creation schemas
CREATE SCHEMA raw;
GO
CREATE SCHEMA clean;
GO
CREATE SCHEMA report;
GO
