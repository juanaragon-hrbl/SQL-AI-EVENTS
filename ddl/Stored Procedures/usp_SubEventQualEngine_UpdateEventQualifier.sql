CREATE PROCEDURE [dbo].[usp_SubEventQualEngine_UpdateEventQualifier]
    @PK_Event int

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_SubEventQualEngine_UpdateEventQualifier]
	
	USE:			
			DECLARE @e int, @em varchar(4000)
			
			EXEC [dbo].[usp_SubEventQualEngine_UpdateEventQualifier]
				@PK_Event = 0
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
	1.0.0										Initial
	2.0.0		2019-09-30		NoeG			SRE template applied
	2.0.1		2019-10-30		NoeG			SRE Hardcode changed
	
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@ProcParam varchar(100) = ''
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/******************************************************************************
			delete old qualifiers for the particular event qualifiers processed
		******************************************************************************/
		DELETE FROM
			dbo.EventQualifier
		WHERE
			PK_Event = @PK_Event 

		/******************************************************************************
			Perform Award SubEvent Cleanup for PK_Event 147
		******************************************************************************/	
		IF GETDATE() <= '2010-03-31'
		/* Cleanup for 30th Anniversary Summit*/ -- IniU 02/24/2010
		EXEC dbo.usp_EventQual_AwardQualifiersCheck 147

		/******************************************************************************
			process current events
		******************************************************************************/
		INSERT
			dbo.EventQualifier
		(
			PK_Event
			,PK_Distributor
			,DistributorID
		)
		SELECT DISTINCT
			E.PK_Event
			,E.PK_Distributor
			,E.DistributorID
		FROM
			dbo.SubEventQualifier E WITH (NOLOCK)
		WHERE 
			 E.PK_Event = @PK_Event
			 AND
			 E.Qualified = 1 AND E.RemovedUTC = @ValidDate

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StoredProcedureParameters = @ProcParam
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
	end procedure
******************************************************************************/
END
GO

