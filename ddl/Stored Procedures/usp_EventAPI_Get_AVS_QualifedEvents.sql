
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_AVS_QualifedEvents]
    -- REQUIRED
   @DistributorID varchar(10),
      -- OPTIONAL
 	   @IsDevQA		BIT = 0,   
	   @Error	int = 0 OUTPUT,
	   @ErrorMessage varchar(4000) = NULL OUTPUT

AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventAPI_Get_AVS_QualifedEvents]
	
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC [dbo].[usp_EventAPI_Get_AVS_QualifedEvents]
				
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1		
	2	2019-10-14	JonathanO	Refactor code (SRE)
	
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = 'usp_EventQual_NAMFSLLDW_Oct2019'
	,@StartTime datetime2 = GETUTCDATE();
	
BEGIN TRY

SELECT
      E.EventName
FROM
      dbo.EventQualifier EQ WITH (NOLOCK)
INNER JOIN
      dbo.Event E WITH (NOLOCK)
      ON
            EQ.PK_Event = E.PK_Event
            AND e.dEndUTC > GETUTCDATE()
WHERE
      DistributorID = @DistributorID

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

--exec [usp_EventAPI_Get_AVS_QualifedEvents] @DistributorID = '222222222'