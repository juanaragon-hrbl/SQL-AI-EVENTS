CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Del_EventAudio]  
        --Mandatory Parameters  
   @PK_EventAudio INT  
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS  
BEGIN  
  
/******************************************************************************  
OBJECT:  dbo.usp_MyHLEventAPI_Del_EventAudio  
USE:  
	DECLARE @e int, @em varchar(4000)

	EXEC usp_MyHLEventAPI_Del_EventAudio  
      @PK_EventAudio = 20  
	,@Error = @e OUTPUT  -- @e must be defined in the local call   
	,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
	,@IsDevQA = 1
       
	SELECT @e AS [Error], @em AS [Error Message]
  
DESCRIPTION: Deletes a record from dbo.EventAudio  
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
dbo.EventAudio  
  
VERSIONS  
--------------------------------------------------------------------  
1 2013-01-17 Sushma Initial  
2 2019-08-14 NoeG	Refactor code (SRE)
  
******************************************************************************/  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON   
  
/******************************************************************************  
 VARIABLE DECLARATION  
******************************************************************************/  
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
  
	/* Delete the record from EventAudio table */  
	BEGIN TRY  

		DELETE
		FROM
		 dbo.EventAudioLocaleDesc
		WHERE  
		 PK_EventAudio = @PK_EventAudio  
  
		DELETE  
		FROM   
		 DBO.EventAudio   
		 WHERE  
		 PK_EventAudio = @PK_EventAudio  
   
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
	END CATCH
  
/******************************************************************************  
 END PROCEDURE  
******************************************************************************/  
END
GO

