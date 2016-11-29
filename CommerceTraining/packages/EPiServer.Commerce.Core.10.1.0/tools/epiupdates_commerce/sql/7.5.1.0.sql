--beginvalidatingquery 
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'SchemaVersion') 
    BEGIN 
    declare @major int = 7, @minor int = 5, @patch int = 1    
    IF EXISTS (SELECT 1 FROM dbo.SchemaVersion WHERE Major = @major AND Minor = @minor AND Patch = @patch) 
        select 0,'Already correct database version' 
    ELSE 
        select 1, 'Upgrading database' 
    END 
ELSE 
    select -1, 'Not an EPiServer Commerce database' 
--endvalidatingquery 
GO 

DECLARE @metaClassId int, @metaFieldId int
SET @metaClassId = (SELECT TOP 1 MetaClassId from MetaClass WHERE Name = 'LineItemEx')
SET @metaFieldId = (SELECT TOP 1 MetaFieldId from MetaField WHERE Name = 'Epi_FreeQuantity')

EXEC mdpsp_sys_DeleteMetaFieldFromMetaClass @MetaClassId, @MetaFieldId
EXEC mc_mcmd_MetaFieldDelete @MetaFieldId
GO
 
--beginUpdatingDatabaseVersion 
 
INSERT INTO dbo.SchemaVersion(Major, Minor, Patch, InstallDate) VALUES(7, 5, 1, GETUTCDATE())
GO 

--endUpdatingDatabaseVersion 