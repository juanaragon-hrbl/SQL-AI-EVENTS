CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Validate_DSAccess]	
    -- MANDATORY
    @DistributorID nVARCHAR(20)                /* pass DistributorID for search */    
    -- OPTIONAL
    ,@PK_Event int = NULL
	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:        [dbo].[usp_MyHLEventAPI_Validate_DSAccess]

USE:        
			DECLARE @e int, @em varchar(4000)
            
            EXEC [usp_MyHLEventAPI_Validate_DSAccess]
                    @DistributorID = '11541926'
                    ,@Error = @e OUTPUT  -- @e must be defined in the local call 
                    ,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

			--select @em

DESCRIPTION:    Validations: given DSID is valid or not, whether the DSID belongs to the region of loggedinuser and the distributor belongs to the market

NOTES:            

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1    2012-10-07    OrlandoL    Initial
2    2018-05-08    RogelioR    Include [AccessType] to check if access is due to [EventDSAccess] or [EventCoordinatorDetail]
3	 2019-08-14	   NoeG		   Refactor code (SRE)
4	 2022-06-03	   puertac	   US 1050464: Remove Error logging when ID has no access
*/

    SET ANSI_NULLS ON
    SET QUOTED_IDENTIFIER ON
    SET NOCOUNT ON

    /******************************************************************************
        variable declaration
    ******************************************************************************/
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
    DECLARE @PK_Locale int

    DECLARE @Access varchar(30)
            ,@Coordinator varchar(30);

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT TOP 1 @Access = [DistributorID] FROM [dbo].[EventDSAccess] WITH (NOLOCK) WHERE [DistributorID] = @DistributorID;
		SELECT TOP 1 @Coordinator = [CoordinatorID] FROM [dbo].[EventCoordinatorDetail] WITH (NOLOCK) WHERE [CreatedDistributorID] = @DistributorID AND CoordinatorID IS NOT NULL;
    
		IF(@Access IS NULL)
			BEGIN
				SET @Error = 8
			END

		SELECT    @DistributorID AS [DistributorID]
				,CASE WHEN @Coordinator IS NOT NULL THEN 'C' ELSE 'F' END AS [AccessType];
	
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
				
	END CATCH;
/******************************************************************************
    END Procedure
******************************************************************************/
END