CREATE PROCEDURE [dbo].[usp_EventAPI_UploadAttendees]
		-- Mandatory Parameters
		@UploadCompanions xml

		-- Optional Paramenters
		,@User nvarchar(255) = NULL

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
	OBJECT:			usp_EventAPI_UploadAttendees

	USE:
	
					DECLARE @e int, @em varchar(4000)
							,@s varchar(max) = N'
								<reg>
									<eid>54138</eid>
									<did>1111111111</did>
									<cm>5</cm>
									<sp>1</sp>
									<usr>rogelior</usr>
									<rt>2017-12-25 12:05:12</rt>
									<tz>PACIFIC</tz>
								</reg>
								<reg>
									<eid>54138</eid>
									<did>2222222222</did>
									<sp>0</sp>
									<cm>0</cm>
									<usr>rogelior</usr>
									<rt>2017-12-25 12:05:12</rt>
									<tz>PACIFIC</tz>
								</reg>
								<reg>
									<eid>54138</eid>
									<did>staff</did>
									<cm>0</cm>
									<usr>rogelior</usr>
									<rt>2017-12-25 12:10:12</rt>
									<tz>CENTRAL</tz>
								</reg>
								'
							,@UploadCompanions xml;

					SELECT @UploadCompanions = CAST(@s AS xml);
					
					SELECT @UploadCompanions

					EXEC [dbo].[usp_EventAPI_UploadAttendees]
							-- Mandatory Parameters
							@UploadCompanions = @UploadCompanions

							-- Optional Paramenters
							,@User = NULL

							-- Error Parameters
							,@Error	= @e OUTPUT
							,@ErrorMessage = @em OUTPUT
							,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]

					select * from EventsRegistration where pk_event in (54138)
					
	DESCRIPTION:	Upload event attendees to EventCoordinatorDetail

	NOTES:

	DEPENDENCIES (U)
	--------------------------------------------------------------------
	dbo.v_Distributor, dbo.Event, dbo., dbo.EventsRegistration

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-12-18		RogelioR		Initial
	1.0.1		2019-09-05		NoeG			SRE template applied
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	SELECT @User = ISNULL(@User, REPLACE(SYSTEM_USER, 'HERBALIFECORP\', ''));

	BEGIN TRY
		IF OBJECT_ID('tempdb.dbo.#Attendees') IS NOT NULL
			DROP TABLE #Attendees;
		
		SELECT
				UploadCompanions.col.value('eid[1]', 'int') AS [PK_Event]
				,UploadCompanions.col.value('did[1]', 'varchar(20)') AS [DistributorID]
				,UploadCompanions.col.value('cm[1]', 'int') AS [Companions]
				,ISNULL(UploadCompanions.col.value('sp[1]', 'bit'), 0) AS [SpouseAttended]
				,ISNULL(UploadCompanions.col.value('usr[1]', 'varchar(255)'), @User) AS [ModifiedBy]
				,ISNULL(UploadCompanions.col.value('rt[1]', 'datetime2'), GETUTCDATE()) AS [ModifiedDateUTC]
				,ISNULL(NULLIF(UploadCompanions.col.value('tz[1]', 'varchar(255)'), ''), 'UTC') AS [TimeZone]
			INTO #Attendees
			FROM @UploadCompanions.nodes('/reg') AS UploadCompanions(col);
			
		-- Check that attendees are qualified for the event
		--
		IF EXISTS (
			SELECT 1 FROM (SELECT a.[DistributorID], a.[PK_Event], ISNULL(l.[PK_Event], 0) AS [Chk] 
								FROM #Attendees AS a
								LEFT JOIN [LocalSubEventQualifier] AS l WITH (NOLOCK) ON a.[DistributorID] = l.[DistributorID]
									AND a.[PK_Event] = l.[PK_Event]
					) AS c
				WHERE Chk = 0
			)
			RAISERROR('One or more attendees are not qualified for this event.', 16, 1);

		-- Check if attendees are already registered
		--
		IF EXISTS (SELECT 1
						FROM #Attendees AS a
							INNER JOIN [EventsRegistration] AS e WITH (NOLOCK) ON e.[PK_Event] = a.[PK_Event]
								AND e.[DistributorID] = a.[DistributorID])
			RAISERROR('One or more attendees are already registered.', 16, 1);

		IF OBJECT_ID('tempdb.dbo.#c_attendees') IS NOT NULL
			DROP TABLE #c_attendees;

		WITH c_attendess AS (
			SELECT
					[PK_Event]
					,[DistributorID]
					,[Companions]
					,[SpouseAttended]
					,[ModifiedBy]
					,[ModifiedDateUTC]
					,[TimeZone]
				FROM #Attendees
		)
		SELECT
				c.[PK_Event]
				,c.[DistributorID]
				,d.[nDistributorID] AS [PK_Distributor]
				,d.[sFirstName] AS [FirstName]
				,d.[sLastName] AS [LastName]
				,d.[sStreet] AS [AddressLine1]
				,d.[sCity] AS [City]
				,d.[sDistributorStateOrProvince] AS [State]
				,d.[sDistributorCountryProcessingCode] AS [Country]
				,d.[Phone] AS [Phones]
				,d.[sEmail] AS [EmailAddress]
				,1 AS [IsPrimaryGuest]
				,1 AS [HasCheckedIn]
				,c.[ModifiedDateUTC] AS [CreatedDateUTC]
				,1 AS [IsDistributor]
				,c.[ModifiedBy] AS [CreatedBy]
				,c.[ModifiedDateUTC]
				,c.[ModifiedBy]
				,c.[Companions]
				,c.[TimeZone]
				,c.[SpouseAttended]
				,d.[SpouseFirstName]
				,d.[SpouseLastName]
				,CAST(c.[Companions] AS nvarchar(255)) + ';' + c.[TimeZone] AS [CustomValue]
				,CASE WHEN d.[nDistributorID] IS NULL THEN 0 ELSE 1 END AS [ValidID]
				,CASE WHEN e.[PK_Event] IS NULL THEN 0 ELSE 1 END AS [ValidEvent]
			INTO #c_attendees
			FROM c_attendess AS c
				LEFT JOIN [v_Distributor] AS d ON d.[sDistributorID] = c.[DistributorID]
				LEFT JOIN [Event] AS e WITH (NOLOCK) ON e.[PK_Event] = c.[PK_Event]

		-- Add spouses in the registration source
		INSERT INTO #c_attendees
		SELECT
				[PK_Event]
				,[DistributorID]
				,[PK_Distributor]
				,[SpouseFirstName] AS [FirstName]
				,[SpouseLastName] AS [LastName]
				,[AddressLine1]
				,[City]
				,[State]
				,[Country]
				,[Phones]
				,[EmailAddress]
				,0 AS [IsPrimaryGuest]
				,1 AS [HasCheckedIn]
				,[CreatedDateUTC]
				,1 AS [IsDistributor]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[Companions]
				,[TimeZone]
				,[SpouseAttended]
				,NULL AS [SpouseFirstName]
				,NULL AS [SpouseLastName]
				,[CustomValue]
				,[ValidID]
				,[ValidEvent]
			FROM #c_attendees
			WHERE [SpouseAttended] = 1

		--IF @IsDevQA = 1 SELECT * FROM #c_attendees

		-- Event does not exists
		IF EXISTS (SELECT 1 FROM #c_attendees WHERE ValidEvent = 0)
			RAISERROR('One or more Event(s) do not exist.', 16, 1);
		
		-- Check for invalid distributor id
		IF EXISTS(SELECT 1 FROM #c_attendees WHERE ValidID = 0)
			RAISERROR('One or more distributor ID do not exist.', 16, 1);
			
		INSERT INTO [dbo].[EventsRegistration] (
				[DistributorID]
				,[PK_Distributor]
				,[FirstName]
				,[LastName]
				,[AddressLine1]
				,[City]
				,[State]
				,[Country]
				,[Phones]
				,[EmailAddress]
				,[IsPrimaryGuest]
				,[HasCheckedIn]
				,[CreatedDateUTC]
				,[IsDistributor]
				,[CreatedBy]
				,[PK_Event]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[CustomValue]
		)
		SELECT
				c.[DistributorID]
				,c.[PK_Distributor]
				,c.[FirstName]
				,c.[LastName]
				,c.[AddressLine1]
				,c.[City]
				,c.[State]
				,c.[Country]
				,c.[Phones]
				,c.[EmailAddress]
				,c.[IsPrimaryGuest]
				,c.[HasCheckedIn]
				,c.[CreatedDateUTC]
				,c.[IsDistributor]
				,c.[CreatedBy]
				,c.[PK_Event]
				,c.[ModifiedDateUTC]
				,c.[ModifiedBy]
				,c.[CustomValue]
			FROM #c_attendees AS c
				LEFT JOIN [dbo].[EventsRegistration] AS e WITH (NOLOCK) ON e.[PK_Event] = c.[PK_Event]
					AND e.[PK_Distributor] = c.[PK_Distributor]
			WHERE e.[PK_Distributor] IS NULL;
			
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

