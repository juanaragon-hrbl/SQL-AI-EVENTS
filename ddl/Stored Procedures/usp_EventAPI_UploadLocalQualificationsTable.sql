CREATE PROCEDURE [dbo].[usp_EventAPI_UploadLocalQualificationsTable]
-- Mandatory
@DistributorID varchar(20)

-- Defaults
,@ErrorOnQualifiedDistributors bit = 0

-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
	OBJECT:			dbo.usp_EventAPI_UploadLocalQualificationsTable
	
	USE:			
			DECLARE @e int, @em varchar(4000)

			EXEC usp_EventAPI_UploadLocalQualificationsTable
					@DistributorID = 'staff'
					,@Error = @e OUTPUT  
					,@ErrorMessage = @em OUTPUT 
	                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Insert/Updates a qualified distributors in [LocalSubEventQualifier]

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	[dbo].[LocalSubEventQualifier]

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-11-30		RogelioR		Initial
	1.0.1		2019-09-05		NoeG			SRE template applied
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	SET ANSI_NULLS ON
	SET ANSI_PADDING ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@Msg varchar(max) = 'Distributor/User ' + @DistributorID + ' is not authorized for this event.'
			,@Access int = 0;
			
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY;
		IF OBJECT_ID('tempdb..#Output') IS NOT NULL
			DROP TABLE #Output;
			
		IF EXISTS(SELECT name FROM sys.indexes WITH (NOLOCK) WHERE name='IX_InLocalSubEventQualifier_PK_Event_PK_SubEvent_DistributorID')
			DROP INDEX IX_InLocalSubEventQualifier_PK_Event_PK_SubEvent_DistributorID ON InLocalSubEventQualifier;

		CREATE INDEX IX_InLocalSubEventQualifier_PK_Event_PK_SubEvent_DistributorID on InLocalSubEventQualifier(PK_Event, PK_SubEvent, DistributorID);

		--IF @IsDevQA = 1
		--	SELECT 'Already Qualified', *
		--		FROM InLocalSubEventQualifier AS i WITH (NOLOCK)
		--			INNER JOIN [LocalSubEventQualifier] AS l WITH (NOLOCK) ON i.[PK_Event] = l.[PK_Event]
		--				AND i.[DistributorID] = l.[DistributorID]
		--				AND i.[IsQualified] = 1;

		-----------------------------------------------------------------------------------------------
		-- If a distributor is already qualified for the event, an error is raised
		--
		IF @ErrorOnQualifiedDistributors = 1
			IF EXISTS (SELECT 1 
					FROM InLocalSubEventQualifier AS i WITH (NOLOCK)
						INNER JOIN [LocalSubEventQualifier] AS l WITH (NOLOCK) ON i.[PK_Event] = l.[PK_Event]
							AND i.[DistributorID] = l.[DistributorID]
							AND i.[IsQualified] = 1)
				RAISERROR('One or more distributors in the file are already qualified', 16, 1);
		
		-- Check if user is valid in EventDSAccess
		IF EXISTS (SELECT DistributorID FROM dbo.EventDSAccess EU WITH (NOLOCK) WHERE DistributorID = @DistributorID)
			SELECT @Access = 1;
		
		IF @IsDevQA = 1 SELECT @Access AS [Access by EventDSAccess];


		-- Check is the user is valid in the locale
		IF @Access = 0
		BEGIN
			IF @IsDevQA = 1 
				WITH c AS (
					SELECT DISTINCT
							x.[PK_Event]
							,e.[PK_Locale]
						FROM InLocalSubEventQualifier AS x WITH (NOLOCK)
							LEFT JOIN [dbo].[EventDistributorCountryLocales] AS e WITH (NOLOCK) ON x.[PK_Event] = e.PK_Event
				) 
				,c_user AS (
					SELECT
							u.PK_EventATAccessUser
							,ul.PK_Locale
							,ut.EventATAccessUserType
						FROM EventATAccessUser u WITH (NOLOCK)
						INNER JOIN EventATAccessUserModules ul WITH (NOLOCK) ON ul.PK_EventATAccessUser = u.PK_EventATAccessUser
						INNER JOIN EventATAccessUserTypes AS ut WITH (NOLOCK) ON ut.PK_EventATAccessUserType = u.PK_EventATAccessUserType
					WHERE EventATAccessUserName = @DistributorID
				)
				SELECT
						'Event Locales'
						,c.[PK_Event]
						,c.[PK_Locale]
						,u.[PK_Locale] AS [UserLocale]
						,CASE WHEN u.[PK_Locale] IS NOT NULL THEN 1 ELSE 0 END AS Authorized
					FROM c
						LEFT JOIN c_user AS u ON u.PK_Locale = c.PK_Locale;
			
				--		
				WITH c AS (
					SELECT DISTINCT
							x.[PK_Event]
							,e.[PK_Locale]
						FROM InLocalSubEventQualifier AS x WITH (NOLOCK)
							LEFT JOIN [dbo].[EventDistributorCountryLocales] AS e WITH (NOLOCK) ON x.[PK_Event] = e.PK_Event
				) 
				,c_user AS (
					SELECT
							u.PK_EventATAccessUser
							,ul.PK_Locale
							,ut.EventATAccessUserType
						FROM EventATAccessUser u WITH (NOLOCK)
						INNER JOIN EventATAccessUserModules ul WITH (NOLOCK) ON ul.PK_EventATAccessUser = u.PK_EventATAccessUser
						INNER JOIN EventATAccessUserTypes AS ut WITH (NOLOCK) ON ut.PK_EventATAccessUserType = u.PK_EventATAccessUserType
					WHERE EventATAccessUserName = @DistributorID
				)
				,c_chk AS (
					SELECT
							'Event Locales' AS [Label]
							,c.[PK_Event]
							,c.[PK_Locale]
							,u.[PK_Locale] AS [UserLocale]
							,CASE WHEN u.[PK_Locale] IS NOT NULL THEN 1 ELSE 0 END AS Authorized
						FROM c
							LEFT JOIN c_user AS u ON u.PK_Locale = c.PK_Locale
				)
				SELECT @Access = CASE WHEN EXISTS(SELECT PK_Event, SUM(Authorized) AS Authorized FROM c_chk GROUP BY PK_Event HAVING SUM(Authorized) = 0) THEN 0 ELSE 1 END;
		END;	-- User is valid in the locale

		IF @IsDevQA = 1 SELECT @Access AS [Access User];

		-- Check if @DistributorID is authorized for that event
		IF @Access = 0
		BEGIN
			-- Check to screen
			IF NOT EXISTS (SELECT [sDistributorID] FROM v_Distributor WHERE [sDistributorID] = @DistributorID)
				RAISERROR(@Msg, 16, 1);

			IF @IsDevQA = 1
			BEGIN
				WITH c AS (
					SELECT
							@DistributorID AS [DistributorID]
							,[PK_Event]
						FROM InLocalSubEventQualifier  WITH (NOLOCK)
				)
				SELECT
						'Distributor authorized events' AS [Distributor authorized events]
						,c.[DistributorID]
						,c.[PK_Event]
						,d.[sDistributorID]
						,d.[sDistributorCountryProcessingCode]
						,cl.[sCountryCode]
						,l.[PK_Locale]
						,CASE WHEN e.[PK_Event] IS NULL THEN 0 ELSE 1 END AS Authorized
						,e.PK_EventDistributorCountryLocales
					FROM c
						INNER JOIN [v_Distributor] AS d ON c.DistributorID = sDistributorID
						LEFT JOIN v_CountryLocale AS cl ON cl.sCountryCode = d.[sDistributorCountryProcessingCode]
						LEFT JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON cl.[sLocaleCode] = l.[LocaleCode]
						LEFT JOIN [dbo].[EventDistributorCountryLocales] AS e WITH (NOLOCK) ON e.[PK_Locale] = l.[PK_Locale]
							AND e.[PK_Event] = c.[PK_Event]
					WHERE [sDistributorID] = @DistributorID
			END;
			
			
			-- Check if user has access to the locale
			WITH c AS (
					SELECT 
							@DistributorID AS [DistributorID]
							,[PK_Event]
						FROM InLocalSubEventQualifier WITH (NOLOCK)
				)
				,c_chk AS (
					SELECT
							c.[PK_Event]
							,SUM(CASE WHEN e.[PK_Event] IS NULL THEN 0 ELSE 1 END) AS Authorized
						FROM c
							INNER JOIN [v_Distributor] AS d ON c.[DistributorID] = [sDistributorID]
							LEFT JOIN v_CountryLocale AS cl ON cl.sCountryCode = d.[sDistributorCountryProcessingCode]
							LEFT JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON cl.[sLocaleCode] = l.[LocaleCode]
							LEFT JOIN [dbo].[EventDistributorCountryLocales] AS e WITH (NOLOCK) ON e.[PK_Locale] = l.[PK_Locale]
								AND e.[PK_Event] = c.[PK_Event]
						WHERE [sDistributorID] = @DistributorID
						GROUP BY c.[PK_Event]
				)
				SELECT @Access = CASE WHEN EXISTS(SELECT [PK_Event] FROM c_chk WHERE Authorized = 0) THEN 0 ELSE 1 END
				
			IF @IsDevQA = 1 SELECT @Access AS [Access Distributor]

			IF @Access = 0 RAISERROR(@Msg, 16, 1);
		END;
		
		-- Generate output for validations
		WITH c AS (
			SELECT
					x.[PK_Event]
					,x.[PK_SubEvent]
					,x.[DistributorID]
					,x.[TimeZone]
					,x.[QualificationTime]
					,x.[Notes]
                    ,x.[IsQualified]
					,v.[nDistributorID] AS [DSChk]
					,se.[PK_Event] + se.[PK_SubEvent] AS [EventSubEventChk]
					,ROW_NUMBER() OVER (PARTITION BY x.[PK_Event], x.[PK_SubEvent], x.[DistributorID] ORDER BY x.[PK_Event], x.[PK_SubEvent], x.[DistributorID]) AS n
				FROM InLocalSubEventQualifier AS x WITH (NOLOCK)
					LEFT JOIN [dbo].[SubEvent] AS se WITH (NOLOCK) ON se.[PK_Event] = x.[PK_Event]	-- Check if event/subevent exists
						AND se.[PK_SubEvent] = x.[PK_SubEvent]
					LEFT JOIN [LocalSubEventQualifier] AS l WITH (NOLOCK) ON l.[PK_Event] = x.[PK_Event]
						AND l.[PK_SubEvent] = x.[PK_SubEvent]
						AND l.[DistributorID] = x.[DistributorID]
					LEFT JOIN v_Distributor AS v ON x.[DistributorID] = v.[sDistributorID]	-- Check if distributor exists
				WHERE l.PK_SubEvent IS NULL
		) 
		--OUTPUT inserted.
		SELECT
				[PK_Event]
				,[PK_SubEvent]
				,[DistributorID]
				,[TimeZone]
				,[QualificationTime]
				,[Notes]
                ,[IsQualified]
				,[DSChk]
				,[EventSubEventChk]
				,n
			INTO #Output
			FROM c;

		SELECT PK_Event, PK_SubEvent, DistributorID, DSChk FROM #Output WHERE DSChk IS NULL AND DistributorID <> ''
		-- Throw error if data is inconsistent


		IF EXISTS (SELECT [EventSubEventChk] FROM #Output WHERE [EventSubEventChk] IS NULL)
			RAISERROR('Invalid event or subevent in data', 16, 1);

		--IF EXISTS (SELECT [DistributorID] FROM [LocalSubEventQualifier]

		INSERT INTO [LocalSubEventQualifier] (
						[PK_Event]
						,[PK_SubEvent]
						,[DistributorID]
						,[TimeZone]
						,[QualificationTime]
						,[Notes]
						,[CreatedUTC]
						,[CreatedBy]
						,[UpdatedUTC]
						,[UpdatedBy]
					)
			SELECT
					[PK_Event]
					,[PK_SubEvent]
					,[DistributorID]
					,[TimeZone]
					,[QualificationTime]
					,[Notes]
					,GETUTCDATE()
					,@DistributorID
					,GETUTCDATE()
					,@DistributorID
				FROM #Output
                WHERE IsQualified = 1
					AND n = 1
					AND DSChk IS NOT NULL;

		DELETE l
			--OUTPUT DELETED.
			FROM [LocalSubEventQualifier] AS l
				INNER JOIN InLocalSubEventQualifier AS x ON l.[PK_Event] = x.[PK_Event]
						AND l.[PK_SubEvent] = x.[PK_SubEvent]
						AND (x.[DistributorID] = ''
                            OR (l.[DistributorID] = x.[DistributorID] AND x.IsQualified = 0)
                            );

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
GO

