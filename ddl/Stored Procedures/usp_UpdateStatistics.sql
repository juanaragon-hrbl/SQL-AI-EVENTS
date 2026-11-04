
CREATE PROCEDURE [dbo].[usp_UpdateStatistics]
	 @StatType char(1) = 'A' -- 'A' indicates update all stats while 'I' indicates only specific table(s) stats need to be updated.
	 ,@IsDevQA bit = 0	-- optional

	   ,@Error	int = 0 OUTPUT
	   ,@ErrorMessage varchar(4000) = NULL OUTPUT
--WITH EXECUTE AS 'dbo'
AS
BEGIN

/*********************************************************************************************************************
	OBJECT:		dbo.usp_UpdateStatistics
		
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_UpdateStatistics 
				
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
	NOTES:		

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2010
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1
	2	2019-10-16	 JonathanO		Refactor code (SRE)


***********************************************************************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	 @ProcName varchar(100)
	,@ProcParam varchar(100)	
	,@PKEvent  INT
	
SET @ProcName = 'usp_UpdateStatistics'
SET @ProcParam = ''

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

			BEGIN TRY
-- Rebuild Statistics in PubEventManagement For dbo.SubEventQualifier
IF @StatType = 'A'
BEGIN
	EXEC dbo.sp_updatestats
END

IF @StatType = 'I' 
BEGIN
	UPDATE STATISTICS dbo.SubEventQualifier
	UPDATE STATISTICS dbo.EventQualifier
END

/* END THE PROCEDURE */


		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;
	
	

END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;