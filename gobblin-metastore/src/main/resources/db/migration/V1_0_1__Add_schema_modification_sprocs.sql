-- Copyright (C) 2014-2015 LinkedIn Corp. All rights reserved.
--
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not use
-- this file except in compliance with the License. You may obtain a copy of the
-- License at  http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software distributed
-- under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied.

--
-- Version: 1.0.1
--
-- Helper stored procedures that enable idempotent schema modifications in MySql.
-- The following stored procedures are being added:
--   1. add_index_if_not_exists: check if the specified index exists on the
--                                  given table and create it if it does not.
--   2. drop_index_if_exists: check if the specified index exists on the
--                            given table and delete it if it does.
--   3. add_column_if_not_exists: check if the specified columns exists on the
--                                give table and create it if it does not.
--   4. modify_column_if_exists: check if the specified column exists on the
--                               given table and modifies it if it does.
--

DELIMITER //
DROP PROCEDURE IF EXISTS add_index_if_not_exists //
CREATE PROCEDURE add_index_if_not_exists (
	 IN schemaName VARCHAR(128)
	,IN tableName VARCHAR(128)
	,IN indexName VARCHAR(128)
	,IN indexType ENUM('unique')
	,IN indexDefinition VARCHAR(1024))
BEGIN
	DECLARE sqlStatement VARCHAR(4095) DEFAULT '';
	SET schemaName = COALESCE(schemaName, SCHEMA());
	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.STATISTICS
			WHERE table_schema = schemaName AND table_name = tableName
			AND index_name = indexName) THEN
		SET indexType = COALESCE(indexType, '');
		SET sqlStatement = CONCAT('ALTER TABLE `', schemaName, '`.`', tableName, '` ADD ', UPPER(indexType), ' INDEX `', indexName, '` ', indexDefinition);
		SET @sql = sqlStatement;
		PREPARE preparedSqlStatement FROM @sql;
		EXECUTE preparedSqlStatement;
		DEALLOCATE PREPARE preparedSqlStatement;
	END IF;
END //
DELIMITER ;

DELIMITER //
DROP PROCEDURE IF EXISTS drop_index_if_exists //
CREATE PROCEDURE drop_index_if_exists (
	 IN schemaName VARCHAR(128)
	,IN tableName VARCHAR(128)
	,IN indexName VARCHAR(128))
BEGIN
	DECLARE sqlStatement VARCHAR(4095) DEFAULT '';
	SET schemaName = COALESCE(schemaName, SCHEMA());
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.STATISTICS
			WHERE table_schema = schemaName AND table_name = tableName
			AND index_name = indexName) THEN
		SET sqlStatement = CONCAT('ALTER TABLE `', schemaName, '`.`', tableName, '` DROP INDEX `', indexName, '`');
		SET @sql = sqlStatement;
		PREPARE preparedSqlStatement FROM @sql;
		EXECUTE preparedSqlStatement;
		DEALLOCATE PREPARE preparedSqlStatement;
	END IF;
END //
DELIMITER ;

DELIMITER //
DROP PROCEDURE IF EXISTS add_column_if_not_exists //
CREATE PROCEDURE add_column_if_not_exists (
	 IN schemaName VARCHAR(128)
	,IN tableName VARCHAR(128)
	,IN columnName VARCHAR(128)
	,IN columnDefinition VARCHAR(1024))
BEGIN
	DECLARE sqlStatement VARCHAR(4095) DEFAULT '';
	SET schemaName = COALESCE(schemaName, SCHEMA());
	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
			WHERE table_schema = schemaName AND table_name = tableName
			AND column_name = columnName) THEN
		SET sqlStatement = CONCAT('ALTER TABLE `', schemaName, '`.`', tableName, '` ADD `', columnName, '` ', columnDefinition);
		SET @sql = sqlStatement;
		PREPARE preparedSqlStatement FROM @sql;
		EXECUTE preparedSqlStatement;
		DEALLOCATE PREPARE preparedSqlStatement;
	END IF;
END //
DELIMITER ;

DELIMITER //
DROP PROCEDURE IF EXISTS modify_column_if_exists //
CREATE PROCEDURE modify_column_if_exists (
	 IN schemaName VARCHAR(128)
	,IN tableName VARCHAR(128)
	,IN columnName VARCHAR(128)
	,IN columnDefinition VARCHAR(1024))
BEGIN
	DECLARE sqlStatement VARCHAR(4095) DEFAULT '';
	SET schemaName = COALESCE(schemaName, SCHEMA());
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
			WHERE table_schema = schemaName AND table_name = tableName
			AND column_name = columnName) THEN
		SET sqlStatement = CONCAT('ALTER TABLE `', schemaName, '`.`', tableName, '` MODIFY `', columnName, '` ', columnDefinition);
		SET @sql = sqlStatement;
		PREPARE preparedSqlStatement FROM @sql;
		EXECUTE preparedSqlStatement;
		DEALLOCATE PREPARE preparedSqlStatement;
	END IF;
END //
DELIMITER ;