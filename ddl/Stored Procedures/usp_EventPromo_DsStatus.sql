CREATE PROCEDURE [dbo].[usp_EventPromo_DsStatus]
		@PK_Event int
		,@DistributorID varchar(30)
		,@CurrentDate datetime2 = NULL

		-- Error Parameters
		,@Error	int OUTPUT
		,@ErrorMessage varchar(MAX) OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventPromo_DSStatus]

	USE:
			DECLARE @e int, @em varchar(max)

			EXEC [dbo].[usp_EventPromo_DSStatus]
				@PK_Event = 9995
				,@DistributorID = '10Y2117718'
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
			SELECT * FROM [EventPromoTemplate]

	DESCRIPTION:

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------


	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2018-10-02		RogelioR		Initial
	1.1.0		2021-09-27		rogelior		Added handler for additional parameters in [CustomValue]

******************************************************************************/ 
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime = GETUTCDATE()
			,@Query nvarchar(4000)
			,@Param nvarchar(4000)
			,@QParam nvarchar(4000)
			,@sp nvarchar(4000)
			,@CustomValue nvarchar(4000)
			;

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
		SELECT @Param = N'@PK_Event int, @DistributorID varchar(30), @Error	int OUTPUT, @ErrorMessage varchar(MAX) OUTPUT, @IsDevQA bit'
				,@QParam = N'@PK_Event, @DistributorID, @Error, @ErrorMessage, @IsDevQA';
		
		SELECT 
				@sp = 'EXEC ' + [StatusSP] + ' '
				,@CustomValue = [CustomValue]
			FROM [EventPromoTemplate] WITH (NOLOCK)
			WHERE [PK_Event] = @PK_Event;

		DECLARE @CValues table(
			[CustomValue] nvarchar(4000)
		);

		INSERT @CValues SELECT [value] FROM string_split(@CustomValue, ',')
		
		SELECT @Query = @sp + @QParam;

		IF EXISTS (SELECT [CustomValue] FROM @CValues WHERE [CustomValue] = 'WITH CURRENTDATE')
		BEGIN
			SELECT @Query = @Query + ', @CurrentDate';
			SELECT @Param = @Param + ', @CurrentDate datetime2';

			EXEC sp_executesql @Query, @Param
							,@PK_Event = @PK_Event
							,@DistributorID = @DistributorID
							,@Error = @Error
							,@ErrorMessage = @ErrorMessage
							,@IsDevQA = @IsDevQA
							,@CurrentDate = @CurrentDate;
		END;
		ELSE
		BEGIN

			EXEC sp_executesql @Query, @Param
							,@PK_Event = @PK_Event
							,@DistributorID = @DistributorID
							,@Error = @Error
							,@ErrorMessage = @ErrorMessage
							,@IsDevQA = @IsDevQA;
		END;
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
	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime
	,@StoredProcedureParameters = @PK_Event
END;
