
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_Currencies]
	-- Optional
	@OnlyActive bit = 1

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			[dbo].[usp_EventAPI_Get_Currencies]

USE:
		DECLARE @e int, @em varchar(4000);

		EXEC [dbo].[usp_EventAPI_Get_Currencies]

				@Error = @e output
				,@ErrorMessage = @em output
				,@IsDevQA = 0

		SELECT @e, @em;

DESCRIPTION:	Retrives the list of currencies

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.Currency

VERSIONS
--------------------------------------------------------------------
1.0.0	2018-01-09		RogelioR		Initial
1.0.1	2019-09-05		NoeG			SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT
				[PK_Currency]
				,[AlphaCode]
				,[Currency]
				,[Active]
			FROM [dbo].[Currency] WITH (NOLOCK)
			WHERE ([Active] = @OnlyActive);

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

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime
END
GO

