
CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_EventProductRecommendation]   
 -- MANDATORY  
  @PK_Event INT
 -- OPTIONAL     
 ,@PK_SubEvent INT = NULL
 ,@IsProductRecommended BIT = 0
 ,@IsLinkedToMainEvent BIT = 0
 ,@IsThresholdEnabled BIT = 0
 ,@Goal MONEY = 0.00
 ,@Threshold MONEY = 0.00
 ,@IsThresholdMonthBased BIT = 0
		-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS  
BEGIN  
  
  
/*  
OBJECT:  dbo.usp_EventsAT_Upd_EventProductRecommendation  
  
USE:  
	DECLARE @e int, @em varchar(4000)

   EXEC [usp_EventsAT_Upd_EventProductRecommendation]  
      @PK_Event = 77  
	 ,@PK_SubEvent = 496
     ,@IsProductRecommended = 1
     ,@IsLinkedToMainEvent = 0
     ,@IsThresholdEnabled = 1
     ,@Goal = 100.00
     ,@Threshold = 50.00
     ,@IsThresholdMonthBased = 1
		,@Error = @e OUTPUT  -- @e must be defined in the local call   
		,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
		,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION: On the admin page, this API will fetch all the product recommendation information of a particular event
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------  
1	2018-07-10		SushmaA		Initial 
2	2019-08-08		NoeG		Refactor code (SRE)
*/    
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON  
  
/******************************************************************************  
 variable declaration  
******************************************************************************/  
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
    
	/******************************************************************************  
	Retrieve Master Events and SubEvents for Distributor Events (DE) only  
	******************************************************************************/  
	BEGIN TRY  

		MERGE
			dbo.[EventProductRecommendation] EPR
		USING (SELECT @IsProductRecommended AS IsProductRecommended, @IsLinkedToMainEvent AS IsLinkedToMainEvent, @PK_SubEvent AS PK_SubEvent, @IsThresholdEnabled AS IsThresholdEnabled
						,@Goal AS Goal, @Threshold AS Threshold, @IsThresholdMonthBased AS IsThresholdMonthBased, @PK_Event AS PK_Event)S
		ON (S.PK_Event = EPR.PK_Event)
		WHEN NOT MATCHED THEN INSERT([IsProductRecommended], [IsLinkedToMainEvent], [PK_SubEvent], [IsThresholdEnabled], [Goal], [Threshold], [IsThresholdMonthBased],PK_Event)
								VALUES (S.[IsProductRecommended], S.[IsLinkedToMainEvent], S.[PK_SubEvent], S.[IsThresholdEnabled], S.[Goal], S.[Threshold], S.[IsThresholdMonthBased], S.PK_Event)
		WHEN MATCHED THEN UPDATE
			SET [IsProductRecommended] = S.[IsProductRecommended], 
			[IsLinkedToMainEvent] = S.[IsLinkedToMainEvent], 
			[PK_SubEvent] = S.[PK_SubEvent], 
			[IsThresholdEnabled] = S.[IsThresholdEnabled], 
			[Goal] = S.[Goal], 
			[Threshold] = S.[Threshold], 
			[IsThresholdMonthBased] = S.[IsThresholdMonthBased]
		;
     
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
 END Procedure  
******************************************************************************/  
END
GO

