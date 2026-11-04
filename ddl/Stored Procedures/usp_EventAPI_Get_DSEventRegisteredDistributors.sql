CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DSEventRegisteredDistributors]
		-- Mandatory
		@PK_Event int

		-- Optional
		,@DistributorID varchar(30) = NULL

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventAPI_Get_DSEventRegisteredDistributors]
	
	USE:			
					DECLARE @e int, @em varchar(4000)

					EXEC [dbo].[usp_EventAPI_Get_DSEventRegisteredDistributors]
								@PK_Event = 79344
								,@DistributorID = NULL
					            ,@Error = @e OUTPUT  /* @e must be defined in the local call */
					            ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					            ,@IsDevQA = 0

					SELECT @e AS [Error], @em AS [Error Message]
				
	DESCRIPTION:	Get all registered distributors for a DS Events

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	[LocalSubEventQualifier], [v_Distributor], [EventsRegistration]

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2018-02-21		RogelioR		Initial
	1.0.1		2019-09-05		NoeG			SRE template applied
	1.0.2		2021-05-06		puertac			re-order #output columns
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

	SELECT @Error = 0, @ErrorMessage = '';
	
	BEGIN TRY
		-- Encabezado
		SELECT 
				e.[EventName]
				,e.[dStartUTC]
				,e.[dEndUTC]
				,e.[EventCity]
				,e.[EventState]
				,e.[Location] AS [TimeZone]
				,e.[CreatedDistributorID] AS [Host DS ID]
				,(SELECT sFirstName + ' ' + sLastName FROM [v_Distributor] WITH (NOLOCK) WHERE [sDistributorID] = e.[CreatedDistributorID]) AS [Host Name]
			FROM [Event] AS e WITH (NOLOCK)
			WHERE [PK_Event] = @PK_Event;

		-- 
		DECLARE @t table(
			PK_Event int
			,PK_SubEvent int
			,SubEventName varchar(max)
		);

		INSERT INTO @t
			SELECT DISTINCT l.[PK_Event], l.[PK_SubEvent], se.[SubEventName]
				FROM [LocalSubEventQualifier] AS l WITH (NOLOCK)
					INNER JOIN [SubEvent] AS se WITH (NOLOCK) ON se.[PK_SubEvent] = l.[PK_SubEvent]
				WHERE l.[PK_Event] = @PK_Event;

		DECLARE @s varchar(max);
		SELECT @s = ISNULL(@s + ',', '') + ('[' + [SubEventName] + '] bit') FROM @t;

		-- Create and format subevent columns
		IF OBJECT_ID('tempdb.dbo.#t') IS NOT NULL
			DROP TABLE #t;

		CREATE TABLE #t (	-- Base subevent table
			[DistributorID] varchar(30)
		);

		DECLARE @cmd nvarchar(max) = 'ALTER TABLE #t ADD ';
		SELECT @cmd = @cmd + @s;
	
		IF @IsDevQA = 1 SELECT @cmd; 

		-- Add subevent columns to base table
		DECLARE @i nvarchar(max);
		SELECT @i = ISNULL(@i + ',', '') + ('MAX(CASE WHEN l.[PK_SubEvent] = ' + CAST(PK_SubEvent AS varchar(max)) + ' THEN 1 ELSE 0 END) AS [' + SubEventName + ']') FROM @t;
		
		IF @IsDevQA = 1 SELECT @i;

		EXEC sp_executesql @cmd;

		-- Add data to subevent table
		SELECT @cmd = null;
		SELECT @cmd = N'INSERT INTO #t
							SELECT l.DistributorID, ' 
							+ @i 
							+ N'FROM LocalSubEventQualifier AS l 
									INNER JOIN SubEvent AS se ON se.PK_SubEvent = l.PK_SubEvent 
								WHERE l.PK_Event = ' + CAST(@PK_Event AS nvarchar(max)) 
							+ N' GROUP BY l.DistributorID';

		EXEC sp_executesql @cmd;
	
		--IF @IsDevQA = 1 SELECT * FROM #t;
		
		IF OBJECT_ID('tempdb..#Output') IS NOT NULL
			DROP TABLE #Output;

		SELECT 
				v.[sFirstName] AS [DS First Name]
				,v.[sLastName] AS [DS Last Name]
				,r.[CreatedDateUTC] AS [RegistrationDate]
				,r.[CreatedBy] AS [RegisteredByDSID]
				,(SELECT sFirstName + ', ' + sLastName FROM [v_Distributor] WITH (NOLOCK) WHERE [sDistributorID] = r.[CreatedBy]) AS [RegisteredByName]
				,CASE WHEN EXISTS (SELECT [IsPrimaryGuest] FROM [EventsRegistration] WITH (NOLOCK) WHERE [DistributorID] = r.[DistributorID] AND [IsPrimaryGuest] = 0) THEN 1 ELSE 0 END AS [IsSpouseCompanion]
				,CONVERT(int, ISNULL(SUBSTRING(r.CustomValue, 1, CHARINDEX(';', r.CustomValue) - 1), '0')) AS [Companions]
				,(SELECT  '<' + STUFF((SELECT '<' + n.Notes + '>' [text()]
							 FROM [dbo].[EventDistributorNotes] AS n WITH (NOLOCK)
								INNER JOIN [v_Distributor] AS v ON v.[nDistributorID] = n.[PK_Distributor]
							 WHERE [PK_Event] =  r.[PK_Event]
								AND [sDistributorID] = r.[DistributorID]
							 FOR XML PATH(''), TYPE)
							.value('.','NVARCHAR(MAX)'),1,1,' ')) as Notes
				,t.*
			INTO #Output
			FROM [EventsRegistration] AS r WITH (NOLOCK)
				INNER JOIN [v_Distributor] AS v ON v.[sDistributorID] = r.[DistributorID]
					AND r.[IsPrimaryGuest] = 1
				LEFT JOIN #t AS t ON t.[DistributorID] = r.[DistributorID]
			WHERE (@PK_Event IS NULL OR r.[PK_Event] = @PK_Event)
				AND (@DistributorID IS NULL OR r.[DistributorID] = @DistributorID);

		 SELECT @i = NULL;

		 SELECT @i = ISNULL(@i + ',', '') + ('ISNULL([' + name + '], 0) AS [' + name + ']')
		 FROM tempdb.sys.columns WITH (NOLOCK)
		 WHERE object_id = object_id('tempdb..#Output')
		 	--AND name != 'DistributorID'
		 ORDER BY column_id

		 SELECT @cmd = 'SELECT ' + @i + ' FROM #Output';

		IF @IsDevQA = 1 SELECT @cmd;

		EXEC sp_executesql @cmd;

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH;
END;
