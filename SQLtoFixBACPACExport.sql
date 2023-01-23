DECLARE @sql VARCHAR(MAX) = ''

PRINT 'Dropping Procedures...'

SELECT @sql=@sql+'DROP PROCEDURE ['+s.[name]+'].['+o.[name] +'];'
FROM sys.objects o
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.[type] = 'P' AND  o.is_ms_shipped = 0

EXEC(@sql)

SET @sql = ''

PRINT 'Dropping Triggers...'

SELECT @sql=@sql+'DROP TRIGGER ['+s.[name]+'].['+o.[name] +'];'
FROM sys.objects o
INNER JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
WHERE [type] = 'TR'
EXEC(@sql)

SET @sql = ''

PRINT 'Dropping Constraints...'

SELECT  @sql=@sql+'ALTER TABLE ['+t.name+'] DROP CONSTRAINT ['+con.[name] +'];'
FROM sys.check_constraints con
INNER JOIN sys.objects t ON con.parent_object_id = t.object_id
INNER JOIN sys.all_columns col ON con.parent_column_id = col.column_id AND  con.parent_object_id = col.object_id

EXEC(@sql)

SET @sql = ''

PRINT 'Dropping Functions...'

SELECT @sql=@sql+'DROP FUNCTION ['+s.[name]+'].['+o.[name] +'];'
FROM sys.objects o
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
LEFT OUTER JOIN sys.computed_columns cc ON cc.definition LIKE '%' + o.name + '%'
WHERE o.[type] IN ('IF', 'FN', 'FS', 'FT', 'TF') 
AND o.is_ms_shipped = 0
AND cc.column_id IS NULL

EXEC(@sql)


SET @sql = ''

PRINT 'Updating Authorizations...'

SELECT  @sql=@sql+'ALTER AUTHORIZATION ON SCHEMA::['+s.[name]+'] TO dbo;'
FROM sys.schemas s
WHERE s.[name] NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'sa')

EXEC(@sql)

SET @sql = ''

PRINT 'Dropping Users...'

SELECT @sql=@sql+'DROP USER ['+p.[name] +'];'
FROM sys.database_principals p
WHERE p.[type] IN ('S', 'G', 'U')
and p.[name] NOT IN ('dbo', 'guest', 'sys', 'INFORMATION_SCHEMA', 'sa')

EXEC(@sql)

SET @sql = ''

PRINT 'Dropping Role Members...'

SELECT @sql=@sql+'EXEC sp_droprolemember ['+r.[name]+'], ['+m.[name]+'];'
FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE r.[name] != 'db_owner'

EXEC(@sql)

SET @sql = ''

PRINT 'Dropping Roles...'

SELECT @sql=@sql+'DROP ROLE ['+p.[name] +'];'
FROM sys.database_principals p
WHERE p.[type] IN ('R')
AND p.[name] NOT LIKE ('db_%') AND p.[name] != 'public'

EXEC(@sql)

SET @sql = ''

PRINT 'Dropping Aplication Roles...'

SELECT @sql=@sql+'DROP APPLICATION ROLE ['+p.[name] +'];'
FROM sys.database_principals p
WHERE p.[type] IN ('A')
AND p.[name] NOT LIKE ('db_%') AND p.[name] != 'public'

EXEC(@sql)

SET @sql = ''

PRINT 'Dropping Views...'

SELECT @sql=@sql+'DROP VIEW ['+s.[name]+'].['+v.[name] +'];'
FROM sys.views v
INNER JOIN sys.schemas s ON s.schema_id = v.schema_id

EXEC(@sql)

SET @sql = ''

DECLARE @name VARCHAR(500)

PRINT 'Dropping Assemblies...'

WHILE EXISTS (SELECT * FROM sys.assemblies a WHERE a.is_user_defined = 1)
BEGIN
	DECLARE assemblyCursor CURSOR FOR SELECT [name] FROM sys.assemblies a WHERE a.is_user_defined = 1
	
	OPEN assemblyCursor  
	FETCH NEXT FROM assemblyCursor INTO @name

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @sql = 'DROP ASSEMBLY  ['+ @name +'];'
		EXEC(@sql)

		FETCH NEXT FROM assemblyCursor INTO @name
	END

	CLOSE assemblyCursor
	DEALLOCATE assemblyCursor
END

SET @sql = ''

PRINT 'Dropping Synonyms...'

SELECT @sql=@sql+'DROP SYNONYM ['+s.[name]+'].['+o.[name] +'];'
FROM sys.objects o
INNER JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
WHERE [type] = 'SN'

EXEC(@sql)

SET @sql = ''

PRINT 'Rename User Data Types...'

SELECT @sql=@sql+'EXEC sp_rename ''['+ s.[name] +'].[' + t.[name] + ']'', ''['+ s.[name] +'].[' + t.[name] + 'Custom]'', ''USERDATATYPE'';'
FROM sys.types t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE
	s.[name] != 'sys'
	AND t.[name] IN (
		SELECT t.[name]
		FROM sys.types t
		INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
		WHERE
			s.[name] = 'sys'
	)

EXEC(@sql)
