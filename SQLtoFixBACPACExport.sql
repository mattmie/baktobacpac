DECLARE @sql VARCHAR(MAX) = ''

SELECT @sql=@sql+'DROP PROCEDURE ['+s.[name]+'].['+o.[name] +'];'
FROM sys.objects o
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.[type] = 'P' AND  o.is_ms_shipped = 0

EXEC(@sql)

SET @sql = ''

SELECT @sql=@sql+'DROP FUNCTION ['+s.[name]+'].['+o.[name] +'];'
FROM sys.objects o
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.[type] IN ('IF', 'FN', 'FS', 'FT', 'TF') AND o.is_ms_shipped = 0

EXEC(@sql)

SET @sql = ''

SELECT  @sql=@sql+'ALTER AUTHORIZATION ON SCHEMA::'+s.[name]+' TO dbo;'
FROM sys.schemas s
WHERE s.[name] NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')

EXEC(@sql)

SET @sql = ''

SELECT @sql=@sql+'DROP USER ['+p.[name] +'];'
FROM sys.database_principals p
WHERE p.[type] = 'S'
and p.[name] NOT IN ('dbo', 'guest', 'sys', 'INFORMATION_SCHEMA')

EXEC(@sql)

SET @sql = ''

SELECT @sql=@sql+'sp_droprolemember ['+r.[name]+'], ['+m.[name]+'];'
FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE r.[name] != 'db_owner'

EXEC(@sql)

SET @sql = ''

SELECT @sql=@sql+'DROP ROLE ['+p.[name] +'];'
FROM sys.database_principals p
WHERE p.[type] IN ('R')
AND p.[name] NOT LIKE ('db_%') AND p.[name] != 'public'

EXEC(@sql)

SET @sql = ''

SELECT @sql=@sql+'DROP APPLICATION ROLE ['+p.[name] +'];'
FROM sys.database_principals p
WHERE p.[type] IN ('A')
AND p.[name] NOT LIKE ('db_%') AND p.[name] != 'public'

EXEC(@sql)

SET @sql = ''

SELECT @sql=@sql+'DROP VIEW ['+s.[name]+'].['+v.[name] +'];'
FROM sys.views v
INNER JOIN sys.schemas s ON s.schema_id = v.schema_id

EXEC(@sql)

SET @sql = ''

WHILE EXISTS (SELECT * FROM sys.assemblies a WHERE a.is_user_defined = 1)
BEGIN
	SELECT @sql=@sql+'DROP ASSEMBLY  ['+a.[name] +'];'
	FROM sys.assemblies a
	WHERE a.is_user_defined = 1
END

EXEC(@sql)