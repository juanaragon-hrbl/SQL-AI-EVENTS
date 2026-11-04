CREATE PROCEDURE [dbo].[usp_BBReport]
 @List VARCHAR(35)
 ,@PK_Event INT
 ,@MailSubject VARCHAR(40)
,@Error int OUTPUT
,@ErrorMessage varchar(200) OUTPUT
-- QA/DEV
,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_BBReport

USE:		declare @e int
                   ,@em varchar(200)

        EXEC usp_BBReport
					@List = 'BBListMexicoExt@herbalife.com'
					,@PK_Event = 88
					,@Subject = 'BB Report - MX Extravaganza'
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

DESCRIPTION:	Called by SMA to generate and send blackberry reports.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------

VERSIONS
--------------------------------------------------------------------
1	2009-09-03 IniU 	Initial
2   2019-01-09 SandhyaP Add @Profile_Name, @execute_query_database for sp_send_dbmail
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @SQL VARCHAR(100)
DECLARE @Profile VARCHAR(50)
DECLARE @DBName VARCHAR(50)
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_BBReport'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'


SET @SQL = 'EXEC dbo.usp_Event_OnsiteReport @PK_Event = ' + CONVERT(varchar,@PK_Event)
SELECT @Profile = name FROM msdb.dbo.sysmail_profile WITH (NOLOCK) where name like 'zusw02p1ensql%'
SELECT @DBName = DB_NAME()
	
BEGIN TRY

EXEC msdb.dbo.sp_send_dbmail
	@profile_name = @Profile 
	,@execute_query_database = @DBName
	,@recipients = @List
	,@query = @SQL
	,@Subject = @MailSubject
	,@body_format = 'Text'

END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH
  
END