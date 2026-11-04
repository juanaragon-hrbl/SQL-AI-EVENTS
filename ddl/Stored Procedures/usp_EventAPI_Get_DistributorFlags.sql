CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DistributorFlags]
    -- REQUIRED
   @DistributorID varchar(10)
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.[usp_EventAPI_Get_DistributorFlags]

USE:
			DECLARE @e int, @em varchar(4000)
                EXEC usp_EventAPI_Get_DistributorFlags @DistributorID = '11Y0023200'
                                                        ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                                ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						                                ,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from PubEvents.dbo.DimDSFlagsHMS
NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1	2024-10-04 ivanci	Initial
2	2025-07-01 jairli	Improve performance #1419759
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	SELECT
        DF.FLAGVALUES as Value,
        DF.FLAGCODES as Code
    FROM 
        PubEvents.dbo.DimDSFlagsHMS DF WITH (NOLOCK)
    INNER JOIN 
        PubEvents.dbo.dimDistributor D WITH (NOLOCK)
    ON
        D.PK_Distributor = DF.PK_DISTRIBUTOR
    WHERE
        D.DistributorID = @DistributorID

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
	end procedure
******************************************************************************/
END
GO
