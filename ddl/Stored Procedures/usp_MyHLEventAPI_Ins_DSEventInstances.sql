
CREATE PROC [dbo].[usp_MyHLEventAPI_Ins_DSEventInstances]
		 @ModifiedBy varchar(30)
		,@PK_Event INT
		,@LocaleCode CHAR(5)
		,@DistributorID VARCHAR(10)
		,@StartDate DATETIME2
		,@EndDate DATETIME2
		,@EventEndDate DATETIME2
		,@Repeat varchar(1) --W - WEEKLY, M - MONTHLY, B - BIWEEKLY

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Ins_DSEventInstances

USE:	        
			DECLARE @e int, @em varchar(4000)

                 EXEC dbo.usp_MyHLEventAPI_Ins_DSEventInstances
						 @ModifiedBy = 'SandhyaP'
					 	,@PK_Event = 10231
						,@LocaleCode = 'en-US'
						,@DistributorID = '2222222222'
						,@StartDate = '2014-10-06'
						,@EndDate = '2014-10-07'
						,@EventEndDate = '2015-10-30'
						,@Repeat = 'M'
						,@Error = @e OUTPUT
						,@ErrorMessage = @em OUTPUT
						,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Inserts all the records for associated DS Event instances based on the PK_Event passed

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event

VERSIONS
----------------------------------------------------------------------------------
1	2014-10-09	Sushma	Intitial
2	2019-08-14	NoeG	Refactor code (SRE)
******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @tally TABLE(n int)
DECLARE @InstanceDates AS TABLE (PK INT IDENTITY(1,1),EventStartDate DATETIME2, EventEndDate DATETIME2)
DECLARE @InsertedRows TABLE (PK_Event INT)
DECLARE @CreatedDateUTC DATETIME2 

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE()

SELECT @Error = 0, @ErrorMessage = '';

SET @CreatedDateUTC = GETUTCDATE()

BEGIN TRY

	/*Generate the dates based of the repetition option selected*/

	IF @repeat = 'W'
	BEGIN

		DECLARE @everyNweeks int

		SET @everyNweeks = 0
		WHILE @everyNweeks < 52
		BEGIN
		 INSERT @tally
		 SELECT @everyNweeks
		 SET @everyNweeks = @everyNweeks + 1
		END

		SET @everyNweeks = 1

	/* ***************** SonarQube check 39 - Queries that use "TOP" should have an "ORDER BY" */
		INSERT INTO @InstanceDates(EventStartDate, EventEndDate)
		SELECT	TOP 12 DATEADD(wk,n*@everyNweeks,@StartDate), DATEADD(wk,n*@everyNweeks,@endDate)
		FROM	@Tally
		WHERE	CAST(DATEADD(wk,n*@everyNweeks,@endDate) AS DATE) <= @eventendDate /* Compare the Date only to create the last instance */
		ORDER BY DATEADD(wk,n*@everyNweeks,@StartDate)
	/* ***************** SonarQube check 39 */

	END

	IF @repeat = 'M'
	BEGIN

	DECLARE @Week int
	DECLARE @DaysOfWeek_Start int
	DECLARE @DaysDiff int
	DECLARE @EventDates AS TABLE (StartDate DATETIME2, EndDate DATETIME2, MonthSeq INT, YearSeq INT)
	DECLARE @Row_Of_Month INT
	DECLARE @StartEventTime TIME 
	DECLARE @EndEventTime TIME 

	SELECT @StartEventTime = CAST(@StartDate AS TIME)
	SELECT @EndEventTime = CAST(@EndDate AS TIME)


	SELECT @Week = datediff(week, dateadd(week, datediff(week, 0, dateadd(month, datediff(month, 0, CAST(@StartDate AS DATETIME)), 0)), 0), CAST(@startDate AS DATETIME) - 1) + 1
	SELECT @DaysOfWeek_Start = (DATEPART(WEEKDAY, @startDate)) - 2
	SELECT @DaysDiff = DATEDIFF(dd, @startDate, @endDate) 

	--select  @Week 'Week', @DaysDiff 'DaysDiff', @DaysOfWeek_Start 'Day of the week', @startdate, @endDate, @eventendDate

	declare @Months as table (ID INT, StartDate Datetime, EndDate Datetime, YearSeq INT, MonthSeq INT, WeekNumber  INT, RowNo INT)

	--select @DayOfWeek, @DaysDiff
	DECLARE @date datetime = CAST( CAST( datepart(m, @startdate) AS VARCHAR ) + '/01/' + CAST( datepart(year, @startdate) AS VARCHAR ) AS DATETIME )

	--select DATEADD(month,datepart(M, @startDate)-1,DATEADD(year,datepart(year, @startdate)-1900,0)) /*First*/
	--select @date + ( 7 - DATEPART ( weekday , @date ) + 1 ) % 7 --first sunday

	;with months (startdate, enddate, level) AS
	(
		  select DATEADD(month,datepart(M, @startDate)-1,DATEADD(year,datepart(year, @startdate)-1900,0)), (@date + ( 7 - DATEPART ( weekday , @date ) + 1 ) % 7), 0
		  union all
		  select DATEADD(DD, 1, EndDate) --startdate
		  , case when (datepart(M,(DATEADD(DD, 7, EndDate))) <> datepart(M, DATEADD(DD, 1, EndDate))) --end date in case of last few days of the month
				THEN DATEADD(day,-1,DATEADD(month,datepart(M, startDate),DATEADD(year,datepart(year, startDate)-1900,0))) --last day of the month 
			 ELSE 
			  case when DATEPART(weekday, DATEADD(DD, 7, enddate)) <> 1
					  THEN (CAST( CAST( datepart(m, DATEADD(DD, 1, EndDate)) AS VARCHAR ) + '/01/' + CAST( datepart(year, DATEADD(DD, 1, EndDate)) AS VARCHAR ) AS DATETIME )) -- first sunday f d month
					  + ( 7 - DATEPART ( weekday , CAST( CAST( datepart(m, DATEADD(DD, 1, EndDate)) AS VARCHAR ) + '/01/' + CAST( datepart(year, DATEADD(DD, 1, EndDate)) AS VARCHAR ) AS DATETIME ) ) + 1 ) % 7
				else DATEADD(DD, 7, enddate) end       
			 end
		  , Level + 1
		  from mONTHS WHERE ENDDATE <= DATEADD(day,-1,DATEADD(month,datepart(M, @eventendDate),DATEADD(year,datepart(year, @eventendDate)-1900,0)))
	)

	insert into @Months(StartDate, EndDate, YearSeq, MonthSeq, WeekNumber, RowNo, ID)
	select 
	M.startDate, M.enddate, DATEPART(YEAR, M.StartDate), DATEPART(M, startdate)
	, datediff(week, dateadd(week, datediff(week, 0, dateadd(month, datediff(month, 0, CAST(StartDate AS DATETIME)), 0)), 0), CAST(StartDate AS DATETIME) - 1) + 1
	, 0
	, 0--ROW_NUMBER () OVER (PARTITION BY DATEPART(M, M.startdate) ORDER BY M.startDate) 
	from months M
	WHERE ENDDATE <= DATEADD(day,-1,DATEADD(month,datepart(M, @eventendDate),DATEADD(year,datepart(year, @eventendDate)-1900,0)))
	OPTION (MAXRECURSION 4000);

	--SELECT MonthSeq FROM @Months where RowNo = 1 and datepart(WEEKDAY,StartDate) > DATEPART(Weekday, @startdate) AND WEEKNUMBER > 0
	--SELECT MonthSeq FROM @Months where RowNo = 1 and datepart(WEEKDAY,StartDate) < DATEPART(Weekday, @startdate) AND WEEKNUMBER > 0


	/*first instance*/
	insert into @EventDates (StartDate, EndDate, MonthSeq, YearSeq)
	select CAST(@startDate AS DATE), CAST(@endDate AS DATE), DATEPART(m, @startdate), DATEPART(YEAR, @startDate)

	IF (@DaysOfWeek_Start < 0)
	BEGIN 
		update M set RowNo = 
		 CASE WHEN (DATEPART(WEEKDAY, EndDate) = 1) then 1 ELSE 0 end
		FROM @Months M
		--WHERE MonthSeq IN (SELECT MonthSeq FROM @Months WHERE WeekNumber = 0)
	END
	ELSE

		update M set RowNo = 
		 CASE WHEN (datepart(weekday,StartDate) <= (@DaysOfWeek_Start + 2)) then 1 ELSE 0 end
		FROM @Months M
		WHERE WeekNumber > 0
		--select MonthSeq from @Months WHERE WeekNumber = 0)


	select M.StartDate, M.EndDate, MonthSeq,YearSeq, WeekNumber, RowNo
	,ROW_NUMBER () OVER (PARTITION BY DATEPART(Year, M.startdate),DATEPART(M, M.startdate) ORDER BY M.WeekNumber) Seq  into #temp1 
	from @Months M WHERE RowNo = 1

	select @Row_Of_Month = Seq from #temp1 WHERE @startDate between StartDate and EndDate

	--select @Row_Of_Month

	IF (@DaysOfWeek_Start < 0)
	BEGIN
		insert into @EventDates(StartDate, EndDate, MonthSeq, YearSeq)
		select DATEADD(WEEK, DATEDIFF(WEEK, @DaysOfWeek_Start, T.StartDate), @DaysOfWeek_Start)
		, DATEADD(WEEK, DATEDIFF(WEEK, @DaysOfWeek_Start + @DaysDiff, T.StartDate), @DaysOfWeek_Start + @DaysDiff), T.MonthSeq, T.YearSeq
		from #temp1 T
		left join @EventDates E on T.MonthSeq = E.MonthSeq and T.YearSeq =E.YearSeq
		where T.Seq = @Row_Of_Month
		AND E.MonthSeq IS NULL
		AND T.WeekNumber = 0
		AND DATEPART(m, DATEADD(WEEK, DATEDIFF(WEEK, @DaysOfWeek_Start, T.StartDate), @DaysOfWeek_Start)) = T.MonthSeq
	
		delete T from #temp1 T INNER JOIN @EventDates D on T.YearSeq = D.YearSeq and T.monthSeq = D.MonthSeq
	
		insert into @EventDates(StartDate, EndDate, MonthSeq, YearSeq)
		select T.EndDate, DATEADD(DD, @DaysDiff, T.EndDate), T.MonthSeq, T.YearSeq
		from #temp1 T
		left join @EventDates E on T.MonthSeq = E.MonthSeq and T.YearSeq =E.YearSeq
		where T.Seq = @Row_Of_Month
		AND E.MonthSeq IS NULL
		AND DATEPART(m, T.EndDate) = T.MonthSeq
	
	
	END
	ELSE
	BEGIN
		insert into @EventDates(StartDate, EndDate, MonthSeq, YearSeq)
		select DATEADD(WEEK, DATEDIFF(WEEK, @DaysOfWeek_Start, T.StartDate), @DaysOfWeek_Start)
		, DATEADD(WEEK, DATEDIFF(WEEK, (@DaysOfWeek_Start + @DaysDiff), T.StartDate), (@DaysOfWeek_Start + @DaysDiff))
		, T.MonthSeq, T.YearSeq
		from #temp1 T
		left join @EventDates E on T.MonthSeq = E.MonthSeq and T.YearSeq =E.YearSeq

	/* ***************** SonarQube check 40 - Nullable subqueries should not be used in "NOT IN" conditions */
		where T.Seq = @Row_Of_Month
		AND E.MonthSeq IS NULL
		--and T.monthseq not in (select MonthSeq From @Months WHERE ID = 1 AND WeekNumber > 0)
		and T.monthseq not in (select MonthSeq From @Months WHERE ID = 1 AND WeekNumber > 0 and MonthSeq is not null)
		AND DATEPART(m, DATEADD(WEEK, DATEDIFF(WEEK, @DaysOfWeek_Start, T.StartDate), @DaysOfWeek_Start)) = T.MonthSeq
	/* ***************** SonarQube check 40 */

		delete T from #temp1 T INNER JOIN @EventDates D on T.YearSeq = D.YearSeq and T.monthSeq = D.MonthSeq
	
		insert into @EventDates(StartDate, EndDate, MonthSeq, YearSeq)
		select DATEADD(WEEK, DATEDIFF(WEEK, @DaysOfWeek_Start, T.StartDate), @DaysOfWeek_Start)
		, DATEADD(WEEK, DATEDIFF(WEEK, (@DaysOfWeek_Start + @DaysDiff), T.StartDate), (@DaysOfWeek_Start + @DaysDiff))
		, T.MonthSeq, T.YearSeq
		from #temp1 T
		left join @EventDates E on T.MonthSeq = E.MonthSeq and T.YearSeq =E.YearSeq
		WHERE T.Seq = (@Row_Of_Month - 1)
		AND DATEPART(m, DATEADD(WEEK, DATEDIFF(WEEK, @DaysOfWeek_Start, T.StartDate), @DaysOfWeek_Start)) = T.MonthSeq

	END

	INSERT INTO @InstanceDates(EventStartDate, EventEndDate)
	SELECT TOP 12 CAST(StartDate AS DATETIME) + CAST(@StartEventTime AS DATETIME)
				, CAST(DATEADD(DD, @DaysDiff, StartDate) AS DATETIME) + CAST(CONVERT(DATETIME, @EndEventTime) AS DATETIME)
	FROM @EventDates 
	WHERE CAST(DATEADD(DD, @DaysDiff, StartDate) AS DATE) <= @EventEndDate  /* Compare the Date only to create the last instance */
	ORDER BY StartDate
	
	END

	IF @repeat = 'B'
	BEGIN

		SET @everyNweeks = 0
		WHILE @everyNweeks < 52
		BEGIN
		 INSERT @tally
		 SELECT @everyNweeks
		 SET @everyNweeks = @everyNweeks + 1
		END

		SET @everyNweeks = 1

	/* ***************** SonarQube check 41 - Queries that use "TOP" should have an "ORDER BY" */
		INSERT INTO @InstanceDates(EventStartDate, EventEndDate)
		SELECT	TOP 12 DATEADD(DD, (14 * N), @StartDate), DATEADD(DD, (14 * N), @endDate)
		FROM	@Tally
		WHERE	CAST(DATEADD(DD, (14 * N),@endDate) AS DATE) <= @eventendDate /* Compare the Date only to create the last instance */
		ORDER BY DATEADD(DD, (14 * N), @StartDate)
	/* ***************** SonarQube check 41 */

	END

	BEGIN TRY
 
	 --Table 1: Event Table
	  INSERT INTO dbo.Event
	  (
		 [PK_EventType]
		,[dStartUTC]
		,[dEndUTC]
		,[EventName]
		,[EventDesc]
		,[EventCity]
		,[EventState]
		,[EventZipCode]
		,[EventAddress]
		,[EventCostDetails]
		,[EventApprovalStatus]
		,[IsHotelEnabled]
		,[IsInventoryEnabled]
		,[IsPreRegistrationRequired]
		,[CanAssignTickets]
		,[CanPurchaseTicketOnline]
		,[CanRegisterOnline]
		,[MakePublic]
		,[IsActive]
		,[IsPublish]
		,[IsTicketPurchaseRequired]
		,[CanDisplayQualPeriod]
		,[CanShowCurrentQualOnline]
		,[PK_DefaultLocale]
		,[DisplayStartDate]
		,[DisplayEndDate]
		,[CreatedBy]
		,[ModifiedBy]
		,[EventVenueName]
		,[IsSocialNetworkEnabled]
		,[PK_OldEventApp]
		,[IsRecurring]
		,[CreatedDistributorID]
		,[Latitude]
		,[Longitude]
		)
		OUTPUT
			inserted.PK_Event
		INTO
			@InsertedRows
		SELECT 
		 E.PK_EventType
		,R.EventStartDate
		,R.EventEndDate
		,E.EventName
		,E.EventDesc
		,E.EventCity
		,E.EventState
		,E.EventZipCode
		,E.EventAddress
		,E.EventCostDetails
		,E.EventApprovalStatus
		,E.[IsHotelEnabled]
		,E.[IsInventoryEnabled]
		,E.[IsPreRegistrationRequired]
		,E.[CanAssignTickets]
		,E.[CanPurchaseTicketOnline]
		,E.[CanRegisterOnline]
		,E.[MakePublic]
		,E.[IsActive]
		,E.[IsPublish]
		,E.[IsTicketPurchaseRequired]
		,E.[CanDisplayQualPeriod]
		,E.[CanShowCurrentQualOnline]
		,E.PK_DefaultLocale
		,E.DisplayStartDate
		,R.EventEndDate -- let each instance have the event end date as the instance end date
		,E.ModifiedBy
		,E.ModifiedBy
		,E.EventVenueName
		,E.IsSocialNetworkEnabled
		,@PK_Event	
		,0
		,E.CreatedDistributorID
		,E.Latitude
		,E.Longitude
		FROM 
			@InstanceDates R
		CROSS JOIN 
			dbo.Event E WITH (NOLOCK)	
		WHERE
			E.PK_Event = @PK_Event  
		ORDER BY
			R.EventStartDate
	END TRY

	BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE() 
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 

	END CATCH  

	BEGIN TRY

	--Table 2: EventLocaleDesc

	INSERT 
		dbo.EventLocaleDesc
	(
		 [PK_Event]
		,[PK_EventType]
		,[PK_Locale]
		,[PK_DefaultLocale]
		,[EventName]
		,[EventDesc]
		,[EventAddress]
		,[EventCity]
		,[EventState]
		,[EventDisplayAddress]
		,[EventCostDetails]	
		,[EventTrainingLanguages]
		,[CreatedBy]
		,[ModifiedBy]
		,[EventApprovalNotes]
		,[EventComments]
		,[EventSummary]
	)
	SELECT
		 I.PK_Event
		,E.PK_EventType
		,E.PK_Locale
		,E.PK_DefaultLocale
		,E.EventName
		,E.EventDesc
		,E.EventAddress
		,E.EventCity
		,E.EventState
		,E.EventDisplayAddress
		,E.EventCostDetails
		,E.EventTrainingLanguages
		,E.CreatedBy
		,E.ModifiedBy
		,E.EventApprovalNotes
		,E.EventComments
		,E.EventSummary	 
	FROM
		@InsertedRows I
	CROSS JOIN	
		dbo.EventLocaleDesc E WITH (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event

	END TRY

	BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 

	END CATCH

	BEGIN TRY

	--TABLE 3: EventURL

	INSERT 
		dbo.EventURL
	(
		 [PK_Event]
		,[PK_Locale]
		,[EventURL]
		,[Flyer]
	)

	SELECT
		 I.PK_Event
		,E.PK_Locale
		,E.EventURL
		,E.Flyer
	FROM
		@InsertedRows I
	CROSS JOIN
		dbo.EventURL E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event

	END TRY

	BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 

	END CATCH

	BEGIN TRY

	--TABLE 4: EventCountry

	INSERT 
		dbo.EventCountry
	(
		 [PK_Event]
		,[PK_Country]
	)
	SELECT
		I.PK_Event
		,E.PK_Country
	FROM
		@InsertedRows I
	CROSS JOIN
		dbo.EventCountry E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event
	END TRY

	BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	
	END CATCH

	BEGIN TRY

	--TABLE 5: EventGuestSpeakers

	INSERT INTO dbo.EventGuestSpeakers
	  (	
		PK_GuestSpeaker, 
		EventSpeakerName, 
		CreatedDateUTC, 
		CreatedBy, 
		ModifiedDateUTC, 
		ModifiedBy, 
		PK_Event, 
		EventSpeakerTitle, 
		EventSpeakerPhone, 
		EventSpeakerEmail, 
		EventSpeakerTeamLevel
	   )
   
	SELECT
		E.PK_GuestSpeaker
		,E.EventSpeakerName
		,@CreatedDateUTC
		,@ModifiedBy
		,@CreatedDateUTC
		,@ModifiedBy
		,I.PK_Event
		,E.EventSpeakerTitle
		,E.EventSpeakerPhone
		,E.EventSpeakerEmail
		,E.EventSpeakerTeamLevel
	FROM
		@InsertedRows I
	CROSS JOIN
		dbo.EventGuestSpeakers E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event
	
   
	END TRY

	BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	
	END CATCH

	BEGIN TRY

	--TABLE 6: EventImage

	INSERT INTO [dbo].[EventImage]
			   ([EventImageLocation]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_Event]
			   ,[PK_EventImageType])           

	SELECT
		E.EventImageLocation
		,@CreatedDateUTC
		,@ModifiedBy
		,@CreatedDateUTC
		,@ModifiedBy
		,I.PK_Event
		,E.PK_EventImageType
	FROM	
		@InsertedRows I
	CROSS JOIN
		dbo.EventImage E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event
           
	END TRY

	BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	
	END CATCH

	BEGIN TRY

	--TABLE 7: EventDSteamType

	INSERT 
		dbo.EventDSteamType
	(
		 DSTeamTypeCode
		,PK_Event
		,CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
	)
	SELECT
		 E.DSTeamTypeCode
		,I.PK_Event
		,@CreatedDateUTC
		,@ModifiedBy
		,@CreatedDateUTC
		,@ModifiedBy
	FROM
		@InsertedRows I
	CROSS JOIN
		dbo.EventDSTeamType E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event

	END TRY

	BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	
	END CATCH

	BEGIN TRY

	--TABLE 8: EventEventSubType

	INSERT
		dbo.EventEventSubType
	(
		 PK_Event
		,PK_EventType
		,PK_EventSubType
		,CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
	)

	SELECT
		 I.PK_Event
		,E.PK_EventType
		,E.PK_EventSubType
		,@CreatedDateUTC
		,@ModifiedBy
		,@CreatedDateUTC
		,@ModifiedBy
	FROM 
		@InsertedRows I
	CROSS JOIN
		dbo.EventEventSubType E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event

	END TRY

	BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	
	END CATCH

	BEGIN TRY

	--TABLE 9: EventDistributorCountry

	INSERT INTO dbo.EventDistributorCountry
	  (CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Event, PK_Country)
	SELECT
		@CreatedDateUTC, @ModifiedBy, @CreatedDateUTC, @ModifiedBy, I.PK_Event, E.PK_Country
	FROM 
		@InsertedRows I
	CROSS JOIN
		dbo.EventDistributorCountry E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event

	END TRY

	BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	
	END CATCH

	BEGIN TRY

	--TABLE 10: EventDistributorCountryLocales

	INSERT INTO EventDistributorCountryLocales
	(
		 PK_Event
		,PK_Locale
		,IsDefault
	)

	SELECT
		I.PK_Event, E.PK_Locale, E.IsDefault
	FROM 
		@InsertedRows I
	CROSS JOIN
		dbo.EventDistributorCountryLocales E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH


	BEGIN TRY

	--TABLE 11: EventCoordinatorDetail

	INSERT INTO dbo.EventCoordinatorDetail
	(
		PK_Event,
		CreatedDistributorID,
		CoordinatorID,
		CoordinatorName,
		CoordinatorPhone,
		CoordinatorEmail,
		CreatedDateUTC,
		CreatedBy,
		ModifiedDateUTC,
		ModifiedBy,
		CoordinatorTitle,
		CoordinatorTeamLevel,
		CoordinatorWebsite	
	)

	SELECT
		 I.PK_Event
		,E.CreatedDistributorID
		,E.CoordinatorID
		,E.CoordinatorName
		,E.CoordinatorPhone
		,E.CoordinatorEmail
		,@CreatedDateUTC
		,@ModifiedBy
		,@CreatedDateUTC
		,@ModifiedBy
		,E.CoordinatorTitle
		,E.CoordinatorTeamLevel
		,E.CoordinatorWebsite
	FROM
		@InsertedRows I
	CROSS JOIN
		dbo.EventCoordinatorDetail E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH


	/* UPDATE ENDDATE FOR PARENT EVENT TO BE THE LAST CHILD INSTANCE END DATE */

	UPDATE E
	SET
		dEndUTC = A.LastEventEndDate
	FROM
		dbo.Event E
	INNER JOIN
	(
	SELECT E.PK_Event, MAX(ET.dEndUTC) LastEventEndDate
	FROM
		dbo.Event E (NOLOCK)
	INNER JOIN
		dbo.Event ET (NOLOCK)
	ON
		E.PK_Event = ET.PK_OldEventApp
		AND
		E.PK_Event = @PK_Event
	GROUP BY 
		E.PK_Event
	)A
	ON
		A.PK_Event = E.PK_Event

	-- UPDATE PROCESSING LOG
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
   
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
END