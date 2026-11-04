
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_PastEvents]
		-- Optional
		@DistributorID nVarchar(10) = NULL
		,@StartDate datetime2 = NULL
		,@EndDate datetime2 = NULL

		-- Pagination
		,@Start				int = NULL
		,@Rows				int = NULL OUTPUT
		,@Total				int = NULL OUTPUT

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN	
/******************************************************************************

	OBJECT:			[dbo].[usp_MyHLEventAPI_Get_PastEvents]
	
	USE:			
					DECLARE @e int, @em varchar(4000), @r int, @s int = 1, @t int;

					EXEC [dbo].[usp_MyHLEventAPI_Get_PastEvents]
							@DistributorID = 'staff'
							,@Start = @s
							,@Rows = @r OUTPUT		
							,@Total	= @t OUTPUT
							,@Error = @e OUTPUT				-- @e must be defined in the local call   
							,@ErrorMessage = @em OUTPUT		-- @em must be defined in the local call   
							,@IsDevQA = 1  
					
					SELECT @e, @em, @r, @t
					
	DESCRIPTION:	Gets past events with pagination

	NOTES:
			@Start -> Sets the starting point of the result set
			@Rows -> Number of rows that will be returned
	
	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventLocaleDesc, dbo.EventDSTeamType, dbo.EventImage, dbo.EventImageLocaleDesc, dbo.EventImageType, dbo.Locales

	VERSIONS (U)
	--------------------------------------------------------------------
	1.0.0		2017-11-13		RogelioR		Initial
	1.1.0		2019-08-14		NoeG			Refactor code (SRE)
	
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

			SELECT	@EndDate = ISNULL(@EndDate, GETUTCDATE()); 

			IF OBJECT_ID('tempdb.dbo.#PastEvents') IS NOT NULL
				DROP TABLE #PastEvents;

			SELECT
					e.[PK_Event]
					,e.[EventName]
					,e.[EventZipCode]
					,RIGHT(l.[LocaleCode], 2) AS [EventCountry]
					,e.[dStartUTC] AS [EventStartDate]
					,e.[dEndUTC] AS [EventEndDate]
					,e.[EventAddress]
					,e.[EventCity]
					,e.[EventState]
					,e.[CreatedDateUTC]
					,e.[EventVenueName]
					,e.[Latitude]
					,e.[Longitude]
					,ROW_NUMBER() OVER (ORDER BY e.[CreatedDateUTC]) AS r1
				INTO #PastEvents
				FROM [dbo].[Event] AS e WITH (NOLOCK)
					LEFT JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = e.[PK_DefaultLocale]
				WHERE e.[CreatedDistributorID] = @DistributorID
					AND	e.[EventApprovalStatus] = 1
					AND e.[dEndUTC] < CONVERT(DATE,GETUTCDATE(), 110)
					AND	e.[PK_Event] NOT IN (SELECT [PK_Event] FROM [dbo].[EventDeleteQueue] WITH (NOLOCK) WHERE [PK_Event] IS NOT NULL AND [PK_Event] = e.[PK_Event])
					AND (@StartDate IS NULL OR e.[dEndUTC] BETWEEN @StartDate AND @EndDate)
					AND	ISNULL(e.[IsRecurring], 0) = 0

			SELECT
					[PK_Event]
					,[EventName]
					,[EventZipCode]
					,[EventCountry]
					,[EventStartDate]
					,[EventEndDate]
					,[EventAddress]
					,[EventCity]
					,[EventState]
					,[CreatedDateUTC]
					,[EventVenueName]
					,[Latitude]
					,[Longitude]
					,[r1]
				FROM #PastEvents
				WHERE ((ISNULL(@Start, 0) = 0 OR ISNULL(@Rows, 0) = 0) 
					OR [r1] BETWEEN @Start AND (@Start + @Rows - 1))
				ORDER BY [r1];

			-- Return pagination variables
			SELECT	@Rows = @@ROWCOUNT, @Total = (SELECT COUNT(1) FROM #PastEvents);

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
GO

