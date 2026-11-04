CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_PastEvent]
	@DistributorID nVarchar(10)
	,@PK_Event INT	= NULL

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_PastEvent

USE:	       
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_MyHLEventAPI_Get_PastEvent 
				@DistributorID = '2222222222'
				, @PK_Event = 9859
				-- Error Parameters
				,@Error = @e OUTPUT  
				,@ErrorMessage = @em OUTPUT 
				-- QA/DEV
                ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the events based on the input search criteria

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS (U)
----------------------------------------------------------------------------------
1	2013-08-21	Sushma	Intitial
2	2015-02-12	Sushma	Changes made to accomodate only event end dates in past and events 
						that were approved earlier and to include only normal DS events and those	
						events that are recurring but only instances not the dummy parent
3	2019-08-14	NoeG	Refactor code (SRE)

******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE @SQL nVARCHAR(MAX)
		,@And nVARCHAR(100)

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

		SELECT @And = CASE WHEN @PK_Event IS NULL THEN '' ELSE 'AND 
			E.PK_Event <> @PK_Event' END

		SELECT @SQL = '
		SELECT DISTINCT
			 E.PK_Event
			,E.EventName
			,E.dStartUTC [EventStartDate]
			,E.dEndUTC  [EventEndDate]
			,EMD.ActualDS
			,EMD.EstimatedDS
			,EMD.ActualNonDS
			,EMD.EstimatedNonDS
		FROM	
			dbo.Event E WITH(NOLOCK)
		LEFT JOIN
			dbo.EventManageDetails EMD WITH(NOLOCK)
		ON
			E.PK_Event = EMD.PK_Event
		WHERE
			E.CreatedDistributorID = @DistributorID
		AND
			E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110)
		AND
			E.PK_Event NOT IN (SELECT EDQ.PK_Event FROM dbo.EventDeleteQueue EDQ)
		AND
			ISNULL(E.IsRecurring, 0) = 0
		AND
			E.EventApprovalStatus = 1
		' + @And + '

		ORDER BY 3 DESC'

		--PRINT @SQL
		EXECUTE sp_executesql @SQL , N'@DistributorID nVARCHAR(10), @PK_Event INT', @DistributorID = @DistributorID, @PK_Event = @PK_Event

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

