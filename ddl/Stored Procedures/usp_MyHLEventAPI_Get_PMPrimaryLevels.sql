CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_PMPrimaryLevels]
	-- Mandatory Parameters
	
	-- Optional Parameters

	-- Error Parameters
	@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN    
/******************************************************************************    
OBJECT:   dbo.usp_MyHLEventAPI_Get_PMPrimaryLevels    
  
USE:   
		DECLARE @e int, @em varchar(4000)
		
		EXEC dbo.usp_MyHLEventAPI_Get_PMPrimaryLevels    
			@Error = @e OUTPUT  /* @e must be defined in the local call */    
			,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */    
            ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]
		    
DESCRIPTION: Retrieves all the records for Primary Levels for Preferred Members
    
NOTES:       
    
DEPENDENCIES    
----------------------------------------------------------------------------------    
    
VERSIONS    
----------------------------------------------------------------------------------    
1.0.0		2020-01-28		NoeG			Initial

******************************************************************************/    
    
/* DECLARE THE REQUIRED VARIABLES */
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
    
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	BEGIN TRY
	
		SELECT @Error = 0, @ErrorMessage = '';
     
		SELECT  PK_PMPrimaryLevel AS PMPrimaryLevel
				, PrimaryLevelCode AS PMPrimaryLevelCode
				, PrimaryLevelDescription AS PMPrimaryLevelDesc
				, [Order]
		FROM    dbo.PMPrimaryLevel PL WITH (NOLOCK)    
	
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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;

