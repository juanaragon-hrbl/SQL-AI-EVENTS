CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_PMPromoDates]
	-- Required
	@UserName		nvarchar(250)
	,@PK_Event		int
	,@dStartUTC		datetime2
	,@dEndUTC		datetime2
	
	-- Optional
	,@EventTimeZone 		decimal(5,2) = NULL
	,@TimeZone				nvarchar(50) = NULL
	,@DisplayStartDate		datetime2 = NULL			-- T 327639 : Adding DisplayDates
	,@DisplayEndDate		datetime2 = NULL			-- T 327639 : Adding DisplayDates
		
		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Upd_PMPromoDates

	USE:			
					DECLARE @e int, @em varchar(4000);

					EXEC dbo.usp_EventsAT_Upd_PMPromoDates
							@UserName = 'RogelioR'
							,@PK_Event = 48159
							,@dStartUTC = '2017-05-30'
							,@dEndUTC = '2017-05-31'
							,@TimeZone = 'PST'
							,@EventTimeZone = 4

							-- Errors
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 0
					
					SELECT @e, @em
					
	DESCRIPTION:	Update the preferred member promotion dates
	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event
	
	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-04		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.0.1		2020-08-13		puertac			T 327639 : Adding DisplayDates
	2.0.2		2026-02-11		ivanci			1441456 : Compare end date with current end date to avoid unnecessary update and error when end date is before today.

******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@CurrentEndDate datetime2;

    SELECT @CurrentEndDate = dEndUTC FROM dbo.[Event] WHERE PK_Event = @PK_Event;
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
		IF (@dEndUTC <= GETUTCDATE() AND @dEndUTC != @CurrentEndDate)
		BEGIN
			RAISERROR('The Event end date cannot be before today.', 11, 1);
			SELECT 0 AS PK_Event;
		END

		IF (@dEndUTC <= @dStartUTC)
		BEGIN
			RAISERROR('The start date cannot be greater than the end date.', 11, 1);
			SELECT 0 AS PK_Event;
		END

		BEGIN TRANSACTION
			UPDATE dbo.[Event] SET
					dEndUTC = @dEndUTC
					,dStartUTC = @dStartUTC
					,[Location] = @TimeZone
					,[EventTimeZone] = ISNULL(@EventTimeZone, [EventTimeZone])
					,ModifiedBy = @UserName
					,ModifiedDateUTC = GETUTCDATE()
					,DisplayStartDate =	@DisplayStartDate		-- T 327639 : Adding DisplayDates
					,DisplayEndDate	 =	@DisplayEndDate			-- T 327639 : Adding DisplayDates
				WHERE PK_Event = @PK_Event;

		COMMIT TRANSACTION

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
END;