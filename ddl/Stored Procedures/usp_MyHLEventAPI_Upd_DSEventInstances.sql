
CREATE PROC [dbo].[usp_MyHLEventAPI_Upd_DSEventInstances]
		 @ModifiedBy varchar(30)
		,@PK_Event INT
		,@LocaleCode CHAR(5)
		,@DistributorID VARCHAR(10)
		,@StartDate DATETIME2
		,@EndDate DATETIME2
		,@EventEndDate DATETIME2
		,@ParentEvent INT
		,@Repeat varchar(1) --W - WEEKLY, M - MONTHLY, B - BIWEEKLY
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Upd_DSEventInstances

USE:
			DECLARE @e int, @em varchar(4000)
                 EXEC dbo.usp_MyHLEventAPI_Upd_DSEventInstances
						 @ModifiedBy = 'SandhyaP'
					 	,@PK_Event = 33239
						,@LocaleCode = 'en-US'
						,@DistributorID = '1111111111'
						,@StartDate = '2015-04-14'
						,@EndDate = '2015-04-16'
						,@EventEndDate = '2015-10-19'
						,@ParentEvent = 33229
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
DECLARE @InstanceDates AS TABLE (PK INT IDENTITY(1,1),EventStartDate DATETIME2, EventEndDate DATETIME2, MonthSeq INT)
DECLARE @InsertedRows TABLE (PK_Event INT)
DECLARE @CreatedDateUTC DATETIME2 
DECLARE @Event AS TABLE (PK INT IDENTITY(1,1), PK_Event INT,EventStartDate DATETIME2, EventEndDate DATETIME2, IsActive BIT)
DECLARE @PK_EventToBeDeleted VARCHAR(200)
DECLARE @PK_OldEventApp INT
declare @Week INT
declare @DaysOfWeek_Start INT
declare @DaysDiff INT
DECLARE @Counter INT
DECLARE @SQL nVARCHAR(MAX)

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE()

SELECT @Error = 0, @ErrorMessage = '';

SET @CreatedDateUTC = GETUTCDATE()
SET @PK_OldEventApp = @ParentEvent

BEGIN TRY

	SELECT @Counter = (CASE WHEN @PK_Event = @ParentEvent THEN 0 ELSE 1 END)--use this to drive the instances to be derived

	--COLLECT ALL THE EXISTING EVENT INSTANCES
	INSERT INTO @Event (PK_Event, EventStartDate, EventEndDate, IsActive)
	SELECT
		E.PK_Event, E.dStartUTC, E.dEndUTC, E.IsActive
	FROM
		dbo.Event E WITH (NOLOCK)
	WHERE
		E.PK_OldEventApp = @PK_OldEventApp
	AND
		E.PK_Event <> @PK_Event
	AND
		(E.dEndUTC >= @StartTime)
	ORDER BY 
		E.dStartUTC
	
	/*Generate the dates based of the repetition option selected*/

	IF @repeat = 'W'
	BEGIN

		DECLARE @everyNweeks int

		SET @everyNweeks = @Counter -- START FROM THE NEXT WEEK ONWARDS
		WHILE @everyNweeks < 52
		BEGIN
		 INSERT @tally
		 SELECT @everyNweeks
		 SET @everyNweeks = @everyNweeks + 1
		END

		SET @everyNweeks = 1

	/* ***************** SonarQube check 42 - Queries that use "TOP" should have an "ORDER BY" */
		INSERT INTO @InstanceDates(EventStartDate, EventEndDate)
		SELECT	TOP 12 DATEADD(wk,n*@everyNweeks,@StartDate), DATEADD(wk,n*@everyNweeks,@endDate)
		FROM	@Tally
		WHERE	CAST(DATEADD(wk,n*@everyNweeks,@endDate) AS DATE) <= @eventendDate /* Compare the Date only to create the last instance */
		ORDER BY DATEADD(wk,n*@everyNweeks,@StartDate)
	/* ***************** SonarQube check 42  */

	END

	IF @repeat = 'M'
	BEGIN

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
		--select * from #temp1 ORDER BY StartDate


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

	/* ***************** SonarQube check 43 - Nullable subqueries should not be used in "NOT IN" conditions */
			where T.Seq = @Row_Of_Month
			AND E.MonthSeq IS NULL
			--and T.monthseq not in (select MonthSeq From @Months WHERE ID = 1 AND WeekNumber > 0)
			and T.monthseq not in (select MonthSeq From @Months WHERE ID = 1 AND WeekNumber > 0 and MonthSeq is not null)
			AND DATEPART(m, DATEADD(WEEK, DATEDIFF(WEEK, @DaysOfWeek_Start, T.StartDate), @DaysOfWeek_Start)) = T.MonthSeq
	/* ***************** SonarQube check 43 */

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

		IF @Counter = 1 --if the child instance is being called, then exclude the child instance dates
		BEGIN
			INSERT INTO @InstanceDates(EventStartDate, EventEndDate)
			SELECT TOP 12 CAST(StartDate AS DATETIME) + CAST(@StartEventTime AS DATETIME)
				, CAST(DATEADD(DD, @DaysDiff, StartDate) AS DATETIME) + CAST(CONVERT(DATETIME, @EndEventTime) AS DATETIME)

			FROM @EventDates 
			WHERE CAST(DATEADD(DD, @DaysDiff, StartDate) AS DATE) <= @EventEndDate /* Compare the Date only to create the last instance */
			AND StartDate <> @StartDate
			ORDER BY StartDate
		END
		ELSE
		BEGIN
			INSERT INTO @InstanceDates(EventStartDate, EventEndDate)
			SELECT TOP 12 CAST(StartDate AS DATETIME) + CAST(@StartEventTime AS DATETIME)
				, CAST(DATEADD(DD, @DaysDiff, StartDate) AS DATETIME) + CAST(CONVERT(DATETIME, @EndEventTime) AS DATETIME)
			FROM @EventDates 
			WHERE CAST(DATEADD(DD, @DaysDiff, StartDate) AS DATE) <= @EventEndDate /* Compare the Date only to create the last instance */
			ORDER BY StartDate
		END

	END

	IF @repeat = 'B'
	BEGIN

		SET @everyNweeks = @Counter
		WHILE @everyNweeks < 52
		BEGIN
		 INSERT @tally
		 SELECT @everyNweeks
		 SET @everyNweeks = @everyNweeks + 1
		END

		SET @everyNweeks = 1

	/* ***************** SonarQube check 44 - Queries that use "TOP" should have an "ORDER BY" */
		INSERT INTO @InstanceDates(EventStartDate, EventEndDate)
		SELECT TOP 12 DATEADD(DD, (14 * N), @StartDate), DATEADD(DD, (14 * N), @endDate)
		FROM	@Tally
		WHERE	CAST(DATEADD(DD, (14 * N),@endDate) AS DATE) <= @eventendDate /* Compare the Date only to create the last instance */
		ORDER BY DATEADD(DD, (14 * N), @StartDate)
	/* ***************** SonarQube check 44 */

	END

	/* Events that are selected to be deleted */
	SELECT @PK_EventToBeDeleted = (coalesce(PIV.[1], '') + COALESCE((CASE WHEN PIV.[2] IS NOT NULL THEN ',' + PIV.[2] ELSE '' END) , '')
	+ COALESCE((CASE WHEN PIV.[3] IS NOT NULL THEN ',' + PIV.[3] ELSE '' END), '') + coalesce((CASE WHEN PIV.[4] IS NOT NULL THEN ',' + PIV.[4] ELSE '' END) , ''))
	FROM
	(
		SELECT cast (e.PK_Event as VARCHAR(10)) PK_Event, row_number () over (ORDER BY E.PK) PK, I.PK [I_PK]
		FROM 
			@Event E
		LEFT JOIN
			@InstanceDates I
		ON
			E.PK = I.PK
		WHERE
			I.PK IS NULL
	)S 
	PIVOT(min(PK_Event) FOR pk in ([1], [2], [3], [4])) AS PIV	

	select @PK_EventToBeDeleted = case when substring(@PK_EventToBeDeleted, 1, 1) = ',' then substring(@PK_EventToBeDeleted, 2, LEN(@PK_EventToBeDeleted)) else @PK_EventToBeDeleted end

	--SELECT @PK_EventToBeDeleted

	BEGIN TRY

	--DELETE THE INSTANCES THAT ARE NO MORE NEEDED
		IF COALESCE(@PK_EventToBeDeleted , '') <> ''
		BEGIN
			 --inactivate the event to be deleted
			SELECT @SQL = 'update dbo.Event set IsPublish = 0, IsActive = 0 where PK_Event IN (' + @PK_EventToBeDeleted +')'
			EXECUTE sp_executesql @SQL
			--move to delete
			EXEC dbo.usp_MyHLEventAPI_Del_Event @PK_Event = @PK_EventToBeDeleted, @UserID = @ModifiedBy, @Error = @Error, @ErrorMessage = @ErrorMessage
		END


	 --Table 1: Event Table
	 --HANDLE THE INSERT/UPDATE OF INSTANCES
		MERGE
			dbo.Event E
		USING
		(
			SELECT EI.PK_Event, EI.PK,I.PK AS [I_PK], I.EventStartDate, I.EventEndDate
			,[PK_EventType], [EventName], [EventDesc], [EventCity], [EventState], [EventZipCode]
			,[EventAddress], [EventCostDetails], [EventApprovalStatus], [IsHotelEnabled], [IsInventoryEnabled], [IsPreRegistrationRequired]
			,[CanAssignTickets], [CanPurchaseTicketOnline], [CanRegisterOnline], [MakePublic], COALESCE(EI.[IsActive], E.IsActive) [IsActive], [IsPublish], [IsTicketPurchaseRequired]
			,[CanDisplayQualPeriod], [CanShowCurrentQualOnline], [PK_DefaultLocale], [DisplayStartDate], I.EventEndDate AS [DisplayEndDate], @ModifiedBy AS [CreatedBy]
			,@ModifiedBy as [ModifiedBy], [EventVenueName], [IsSocialNetworkEnabled], @PK_OldEventApp AS [PK_OldEventApp], 0 AS [IsRecurring], [CreatedDistributorID], [Latitude], [Longitude]	
			FROM	
				@InstanceDates I			
			LEFT JOIN	
				@Event EI
			ON 
				EI.PK = I.PK
			CROSS JOIN
				dbo.Event E WITH (NOLOCK)
			WHERE
				E.PK_Event = @PK_Event	
		) EI 
			ON E.PK_Event = EI.PK_Event
			AND EI.IsActive = 1
		WHEN NOT MATCHED AND (@PK_Event = @PK_OldEventApp)
		THEN INSERT
		(	[PK_EventType], [EventName], [EventDesc], [EventCity], [EventState], [EventZipCode]
			,[EventAddress], [EventCostDetails], [EventApprovalStatus], [IsHotelEnabled], [IsInventoryEnabled], [IsPreRegistrationRequired]
			,[CanAssignTickets], [CanPurchaseTicketOnline], [CanRegisterOnline], [MakePublic], [IsActive], [IsPublish], [IsTicketPurchaseRequired]
			,[CanDisplayQualPeriod], [CanShowCurrentQualOnline], [PK_DefaultLocale], [DisplayStartDate], [DisplayEndDate], [CreatedBy]
			,[ModifiedBy], [EventVenueName], [IsSocialNetworkEnabled], [PK_OldEventApp], [IsRecurring], [CreatedDistributorID], [dStartUTC], [dEndUTC], [Latitude], [Longitude]
		)
		VALUES ([PK_EventType], [EventName], [EventDesc], [EventCity], [EventState], [EventZipCode]
			,[EventAddress], [EventCostDetails], [EventApprovalStatus], [IsHotelEnabled], [IsInventoryEnabled], [IsPreRegistrationRequired]
			,[CanAssignTickets], [CanPurchaseTicketOnline], [CanRegisterOnline], [MakePublic], [IsActive], [IsPublish], [IsTicketPurchaseRequired]
			,[CanDisplayQualPeriod], [CanShowCurrentQualOnline], [PK_DefaultLocale], [DisplayStartDate], [DisplayEndDate], [CreatedBy]
			,[ModifiedBy], [EventVenueName], [IsSocialNetworkEnabled], [PK_OldEventApp], [IsRecurring], [CreatedDistributorID], EventStartDate, EventEndDate, Latitude, Longitude)
		WHEN MATCHED 
		THEN UPDATE SET
			 PK_EventType = EI.PK_EventType
			,dStartUTC = EI.EventStartDate
			,dEndUTC = EI.EventEndDate
			,EventName = EI.EventName
			,EventDesc = EI.EventDesc
			,EventCity = EI.EventCity
			,EventState = EI.EventState
			,EventZipCode = EI.EventZipCode
			,[EventAddress] = EI.[EventAddress]
			,[EventCostDetails] = EI.[EventCostDetails]
			,[EventApprovalStatus] = EI.[EventApprovalStatus]
			,[IsHotelEnabled] = EI.[IsHotelEnabled]
			,[IsInventoryEnabled] = EI.[IsInventoryEnabled]
			,[IsPreRegistrationRequired] = EI.[IsPreRegistrationRequired]
			,[CanAssignTickets]= EI.[CanAssignTickets]
			,[CanPurchaseTicketOnline] = EI.[CanPurchaseTicketOnline]
			,[CanRegisterOnline] = EI.[CanRegisterOnline]
			,[MakePublic] = EI.[MakePublic]
			,[IsActive] = EI.[IsActive]
			,[IsPublish] = EI.[IsPublish]
			,[IsTicketPurchaseRequired] = EI.[IsTicketPurchaseRequired]
			,[CanDisplayQualPeriod] = EI.[CanDisplayQualPeriod]
			,[CanShowCurrentQualOnline] = EI.[CanShowCurrentQualOnline]
			,[PK_DefaultLocale] = EI.[PK_DefaultLocale]
			,[DisplayStartDate] = EI.[DisplayStartDate]
			,[DisplayEndDate] = EI.[DisplayEndDate]
			,[ModifiedBy] = EI.[ModifiedBy]
			,[EventVenueName] = EI.[EventVenueName]
			,[IsSocialNetworkEnabled] = EI.[IsSocialNetworkEnabled]
			,[IsRecurring] = EI.[IsRecurring]
			,[CreatedDistributorID] = EI.[CreatedDistributorID]
			,[PK_OldEventAPP] = EI.PK_OldEventAPP
			,[Latitude] = EI.Latitude
			,[Longitude] = EI.Longitude
		OUTPUT
			inserted.PK_Event
		INTO
			@InsertedRows
		;
	
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

	--GET ALL THE EVENTS IN THE TABLE VARIABLE FOR FUTURE USE
	DELETE FROM @Event

	INSERT INTO @Event(PK_Event)
	SELECT 
		I.PK_Event
	FROM 
		@InsertedRows I
	WHERE 
		I.PK_Event NOT IN (SELECT ED.PK_Event FROM dbo.EventDeleteQueue ED WITH (NOLOCK))

	BEGIN TRY

	--Table 2: EventLocaleDesc

	MERGE
		dbo.EventLocaleDesc ELD
	USING
	(
			SELECT EL.[PK_EventType], EL.[EventName], EL.[PK_Locale], EL.[PK_DefaultLocale], EL.[EventDesc], EL.[EventCity], EL.[EventState], EL.EventDisplayAddress
			,EL.[EventAddress], EL.[EventCostDetails], EL.[EventTrainingLanguages], @ModifiedBy AS [CreatedBy], EL.[EventApprovalNotes], EL.[EventComments]
			,@ModifiedBy as [ModifiedBy], EL.[EventSummary], @PK_Event AS [PK_OldEventApp], ELD.PK_EventLocaleDesc, E.PK_Event
			FROM	
				@Event E
			INNER JOIN
				(SELECT E.[PK_EventLocaleDesc]
						,E.[PK_Event]              
						,E.[PK_EventType]           
						,E.[PK_Locale]            
						,E.[PK_DefaultLocale]      
						,E.[PK_TeamSite]            
						,E.[EventName]              
					    ,E.[EventDesc]              
						,E.[EventSummary]           
						,E.[EventLocation]          
						,E.[EventVenueName]         
						,E.[EventAddress]           
						,E.[EventCity]              
						,E.[EventState]             
						,E.[Keywords]               
						,E.[EventCostDetails]       
						,E.[EventDisplayAddress]    
						,E.[EventTrainingLanguages] 
						,E.[EventApprovalNotes]     
						,E.[EventComments]          
						,E.[EventRules]             
						,E.[TeamSiteModifiedDate]   
						,E.[CreatedDateUTC]         
						,E.[CreatedBy]              
						,E.[ModifiedDateUTC]        
						,E.[ModifiedBy]             
						,E.[DistributorNotes]       
						,E.[ParticipatingCountries] 
						,E.[TicketRules]            
						,E.[EventAddress2]          
						,E.[IsCTAEnabledOnUpcoming] 
						,E.[CustomTrackingCode]  
				FROM dbo.EventLocaleDesc E WITH (NOLOCK) WHERE E.PK_Event = @PK_Event) EL
			ON
				EL.PK_Event = @PK_Event 
			LEFT JOIN
				dbo.EventLocaleDesc ELD
			ON 
				E.PK_Event = ELD.PK_Event	
			AND
				EL.PK_Locale = ELD.PK_Locale				
	) EL
	ON ELD.PK_Event = EL.PK_Event 
		AND ELD.PK_EventLocaleDesc = EL.PK_EventLocaleDesc
	WHEN NOT MATCHED
	THEN INSERT
	(    [PK_Event], [PK_EventType], [PK_Locale], [PK_DefaultLocale], [EventName], [EventDesc], [EventAddress]
		,[EventCity], [EventState], [EventDisplayAddress], [EventCostDetails], [EventTrainingLanguages], [CreatedBy]
		,[ModifiedBy], [EventApprovalNotes], [EventComments], [EventSummary])
	VALUES  ([PK_Event], [PK_EventType], [PK_Locale], [PK_DefaultLocale], [EventName], [EventDesc], [EventAddress]
		,[EventCity], [EventState], [EventDisplayAddress], [EventCostDetails], [EventTrainingLanguages], [CreatedBy]
		,[ModifiedBy], [EventApprovalNotes], [EventComments], [EventSummary])
	WHEN MATCHED THEN UPDATE
	SET
		  [PK_EventType] = EL.[PK_EventType]
		, [PK_Locale] = EL.[PK_Locale]
		, [PK_DefaultLocale] = EL.[PK_DefaultLocale]
		, [EventName] = EL.[EventName]
		, [EventDesc] = EL.[EventDesc]
		, [EventAddress] = EL.[EventAddress]
		, [EventCity] = EL.[EventCity]
		, [EventState] = EL.[EventState]
		, [EventDisplayAddress] = EL.[EventDisplayAddress]
		, [EventCostDetails] = EL.[EventCostDetails]
		, [EventTrainingLanguages] = EL.[EventTrainingLanguages]
		, [ModifiedBy] = EL.[ModifiedBy]
		, [EventApprovalNotes] = EL.[EventApprovalNotes]
		, [EventComments] = EL.[EventComments]
		, [EventSummary] = EL.[EventSummary]
	;

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
	DELETE EU FROM dbo.EventURL EU INNER JOIN @Event E ON EU.PK_Event = E.PK_Event

	INSERT INTO dbo.EventURL(PK_Event, PK_EventURLType, PK_Locale, EventURL, EventURLDesc, Flyer, CreatedBy, CreatedDateUTC, ModifiedBy, ModifiedDateUTC )
	SELECT
		E.PK_Event, EU.PK_EventURLType, EU.PK_Locale, EU.EventURL, EU.EventURLDesc, EU.Flyer, @ModifiedBy, @CreatedDateUTC, @ModifiedBy, @CreatedDateUTC
	FROM
		@Event E
	CROSS JOIN	
		dbo.EventURL EU WITH (NOLOCK)
	WHERE
		EU.PK_Event = @PK_Event

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

		MERGE
			dbo.EventCountry ECT
		USING
		(
			SELECT
				E.PK_Event, ECN.PK_EventCountry, EC.PK_Country
			FROM
					@Event E
			INNER JOIN
			(SELECT E.[PK_EventCountry] 
					,E.[CreatedDateUTC]    
					,E.[CreatedBy]         
					,E.[ModifiedDateUTC]   
					,E.[ModifiedBy]        
					,E.[PK_Event]          
					,E.[PK_Country]  
			FROM dbo.EventCountry E WITH (NOLOCK) WHERE E.PK_Event = @PK_Event) EC
			ON
				EC.PK_Event = @PK_Event
			LEFT JOIN
				dbo.EventCountry ECN WITH (NOLOCK)
			ON
				E.PK_Event = ECN.PK_Event			
		) ES ON ECT.PK_Event = ES.PK_Event 
		WHEN NOT MATCHED THEN 
		INSERT ([PK_Event], [PK_Country])
		VALUES (ES.[PK_Event], ES.[PK_Country])
		WHEN MATCHED THEN UPDATE SET
		PK_Country = ES.PK_Country 	
		;

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

	DELETE EGS FROM dbo.EventGuestSpeakers EGS INNER JOIN @Event E ON EGS.PK_Event = E.PK_Event

	INSERT INTO dbo.EventGuestSpeakers (PK_GuestSpeaker, EventSpeakerName, CreatedBy, CreatedDateUTC, ModifiedBy, ModifiedDateUTC, PK_Event, EventSpeakerTitle
									,EventSpeakerPhone, EventSpeakerEmail, EventSpeakerTeamLevel)
	SELECT
		ES.PK_GuestSpeaker, ES.EventSpeakerName, @ModifiedBy, @CreatedDateUTC, @ModifiedBy, @CreatedDateUTC, E.PK_Event, ES.EventSpeakerTitle
									,ES.EventSpeakerPhone, ES.EventSpeakerEmail, ES.EventSpeakerTeamLevel
	FROM
		@Event E
	CROSS JOIN
		EventGuestSpeakers ES WITH (NOLOCK)
	WHERE
		ES.PK_Event = @PK_Event

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

		MERGE 
			dbo.[EventImage] EI
		USING
		(
			SELECT
				E.PK_Event, ES.PK_EventImage, EG.EventImageLocation, @ModifiedBy [ModifiedBy], EG.PK_EventImageType
			FROM
				@Event E
			INNER JOIN
			(SELECT E.[PK_EventImage]    
					,E.[EventImageLocation] 
					,E.[CreatedDateUTC]     
					,E.[CreatedBy]          
					,E.[ModifiedDateUTC]    
					,E.[ModifiedBy]         
					,E.[PK_Event]           
					,E.[PK_EventImageType]
			FROM dbo.[EventImage] E WITH (NOLOCK) WHERE E.PK_Event = @PK_Event) EG
			ON
				EG.PK_Event = @PK_Event
			LEFT JOIN
				dbo.[EventImage] ES WITH (NOLOCK)
			ON
				E.PK_Event = ES.PK_Event
			AND
				EG.PK_EventImageType = ES.PK_EventImageType		
		) E ON EI.PK_Event = E.PK_Event
		AND E.PK_Event = EI.PK_Event
		WHEN NOT MATCHED THEN 
		INSERT (EventImageLocation, CreatedBy, ModifiedBy, PK_Event, PK_EventImageType)
		VALUES (E.EventImageLocation, E.ModifiedBy, E.ModifiedBy, E.PK_Event, E.PK_EventImageType)
		WHEN MATCHED THEN UPDATE
		SET
		 EventImageLocation = E.EventImageLocation
		,ModifiedBy = E.ModifiedBy
		,PK_EventImageType = E.PK_EventImageType
		;
          
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

	DELETE EDT FROM dbo.EventDSteamType EDT INNER JOIN @Event E ON EDT.PK_Event = E.PK_Event

	INSERT INTO EventDSTeamType (PK_Event, DSTeamTypeCode, CreatedBy, ModifiedBy, CreatedDateUTC, ModifiedDateUTC)
	SELECT
		E.PK_Event, ES.DSTeamTypeCode, @ModifiedBy, @ModifiedBy, @CreatedDateUTC, @CreatedDateUTC
	FROM 
		@Event E
	CROSS JOIN
		EventDSTeamType ES WITH (NOLOCK)
	WHERE
		ES.PK_Event  = @PK_Event
	
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

	DELETE EST FROM dbo.EventEventSubType EST INNER JOIN @Event E ON EST.PK_Event = E.PK_Event

	INSERT INTO dbo.EventEventSubType (PK_Event, PK_EventType, PK_EventSubType, CreatedBy, ModifiedBy, CreatedDateUTC, ModifiedDateUTC)
	SELECT
		E.PK_Event, ES.PK_EventType, ES.PK_EventSubType, @ModifiedBy, @ModifiedBy, @CreatedDateUTC, @CreatedDateUTC
	FROM	
		@Event E
	CROSS JOIN
		dbo.EventEventSubType ES WITH (NOLOCK)
	WHERE
		ES.PK_Event = @PK_Event

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

	DELETE EDS FROM dbo.EventDistributorCountry EDS INNER JOIN @Event E ON EDS.PK_Event = E.PK_Event

	INSERT INTO dbo.EventDistributorCountry (PK_Event, PK_Country, CreatedBy, ModifiedBy, CreatedDateUTC, ModifiedDateUTC)
	SELECT
		E.PK_Event, ED.PK_Country, @ModifiedBy, @ModifiedBy, @CreatedDateUTC, @CreatedDateUTC
	FROM 
		@Event E
	CROSS JOIN
		dbo.EventDistributorCountry ED WITH (NOLOCK)
	WHERE
		ED.PK_Event = @PK_Event

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

	DELETE EDS FROM dbo.EventDistributorCountryLocales EDS INNER JOIN @Event E ON EDS.PK_Event = E.PK_Event

	INSERT INTO dbo.EventDistributorCountryLocales (PK_Event, PK_Locale, IsDefault, CreatedBy, ModifiedBy, CreatedDateUTC, ModifiedDateUTC)
	SELECT
		E.PK_Event, ED.PK_Locale, ED.IsDefault, @ModifiedBy, @ModifiedBy, @CreatedDateUTC, @CreatedDateUTC
	FROM 
		@Event E
	CROSS JOIN
		dbo.EventDistributorCountryLocales ED WITH (NOLOCK)
	WHERE
		ED.PK_Event = @PK_Event

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
GO


