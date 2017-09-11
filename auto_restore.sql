-- Declare variables to be set
DECLARE
  @FromDatabaseName nvarchar(128),
  @ToDatabaseName nvarchar(128);

SET @FromDatabaseName = 'Example.Production.DB';
SET @ToDatabaseName = 'Example.Test.DB';

-- Get latest database backup for the FromDatabase
DECLARE @BackupFile nvarchar(260);

SELECT @BackupFile=[physical_device_name] FROM [msdb].[dbo].[backupmediafamily] 
  WHERE [media_set_id] =(SELECT TOP 1 [media_set_id] FROM msdb.dbo.backupset
  WHERE database_name=@FromDatabaseName AND type='D' ORDER BY backup_start_date DESC);

-- Get ToDatabase filenames
DECLARE
  @ToDatabaseFile nvarchar(260),
  @ToDatabaseLog nvarchar(260);

SELECT @ToDatabaseFile = f.physical_name FROM sys.master_files f RIGHT JOIN sys.databases d ON f.database_id = d.database_id 
  WHERE d.name = @ToDatabaseName AND f.type_desc = 'ROWS';

SELECT @ToDatabaseLog = f.physical_name FROM sys.master_files f RIGHT JOIN sys.databases d ON f.database_id = d.database_id 
  WHERE d.name = @ToDatabaseName AND f.type_desc = 'LOG';

-- Restore the database
EXEC('ALTER DATABASE [' + @ToDatabaseName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE');
EXEC('RESTORE DATABASE [' + @ToDatabaseName + '] FROM DISK = ''' + @BackupFile + ''' WITH FILE = 1, 
  MOVE ''DatabaseLogicName'' TO ''' + @ToDatabaseFile + ''', 
  MOVE ''DatabaseLogicName_log'' TO ''' + @ToDatabaseLog + ''', NOUNLOAD, REPLACE, STATS = 5');

EXEC('ALTER DATABASE [' + @ToDatabaseName + '] SET MULTI_USER');
