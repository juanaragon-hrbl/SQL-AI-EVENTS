CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromoDates]
	-- Required
	@PK_Event			int = NULL

	-- Optional
	,@PK_MediaType		int = NULL
	,@PK_EventMedia		int = NULL
	,@PK_Locale			int = NULL
	
		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Get_PMPromoDates

	USE:			
					DECLARE @e int, @em varchar(4000);

					EXEC dbo.usp_EventsAT_Get_PMPromoDates
							@PK_Event = 48020
							,@PK_MediaType = NULL
							,@PK_EventMedia = NULL
							,@PK_Locale = NULL
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1
					
					SELECT @e AS Error, @em AS ErrorMessage

	DESCRIPTION:	Gets promotion media data

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventMedia

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-06		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.0.1		2020-08-13		puertac			T 327639 : Adding DisplayDates	
	2.0.2		2022-06-20		puertac			US 1050464: Remove Errorlog when PK_event has been deleted
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
			
	BEGIN TRY
		
		-----------------------------------------------------------------------------------------------------------------------
		-- Promotion Audience
		SELECT
				[PK_Event]
				,[dStartUTC]
				,[dEndUTC]
				,[Location]
				,[EventTimeZone]
				,DisplayStartDate				-- T 327639 : Adding DisplayDates
				,DisplayEndDate					-- T 327639 : Adding DisplayDates
			FROM dbo.[Event] WITH (NOLOCK)
			WHERE PK_Event = @PK_Event 


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
		
	END CATCH
END;