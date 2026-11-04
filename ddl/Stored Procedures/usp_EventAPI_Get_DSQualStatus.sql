CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DSQualStatus]
		--Mandatory
		@PK_Event int
		,@DistributorID VARCHAR(20)

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_DSQualStatus

USE:			
				DECLARE @e int, @em varchar(4000);
				
				EXEC usp_EventAPI_Get_DSQualStatus
					@PK_Event = 77878
					,@DistributorID = '21'
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1
					
DESCRIPTION:	Retrives record from dbo.Event

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.Event

VERSIONS
--------------------------------------------------------------------
1.0.0	2018-01-08		RogeioR			Initial
1.0.1	2019-09-05		NoeG			SRE template applied
******************************************************************************/
	SET ANSI_NULLS ON;
	SET QUOTED_IDENTIFIER ON;
	SET NOCOUNT ON;

	DECLARE @StoredProcedure varchar(255) = 'usp_EventAPI_Get_DSQualStatus'
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
		
		DECLARE @in table (
			DistributorID	varchar(20)
			,PK_Distributor int
			,PK_Event		int
			,IsQualified	bit
			,IsRegistered	bit
			,Companions		int
			,SpouseAttended bit
			,TimeZone		varchar(100)
		);
		
		INSERT INTO @in
			SELECT	@DistributorID AS [DistributorID]
					,(SELECT nDistributorID FROM v_Distributor WHERE sDistributorID = @DistributorID) AS [PK_Distributor]
					,@PK_Event AS [PK_Event]
					,CASE WHEN EXISTS(SELECT 1 FROM [LocalSubEventQualifier] WITH (NOLOCK) WHERE [DistributorID] = @DistributorID AND [PK_Event] = @PK_Event) THEN 1 ELSE 0 END AS [IsQualified]
					,CASE WHEN EXISTS(SELECT 1 FROM [EventsRegistration] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event 
							AND [PK_Distributor] = (SELECT [nDistributorID] FROM v_Distributor WHERE sDistributorID = @DistributorID)) THEN 1 ELSE 0 END AS [Registered]
					,(SELECT TOP 1 SUBSTRING([CustomValue], 1, CHARINDEX(';', [CustomValue])-1)
						FROM [EventsRegistration] WITH (NOLOCK)
						WHERE [PK_Event] = @PK_Event 
							AND [PK_Distributor] = (SELECT [nDistributorID] FROM v_Distributor WHERE sDistributorID = @DistributorID)
							AND [IsPrimaryGuest] = 1
					) AS [Companions]
					,CASE WHEN EXISTS(
						SELECT 1 FROM [EventsRegistration] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event 
							AND [PK_Distributor] = (SELECT [nDistributorID] FROM v_Distributor WHERE sDistributorID = @DistributorID)
							AND [IsPrimaryGuest] = 0
					) THEN 1 ELSE 0 END AS [SpouseAttended]
					,(SELECT [Location] FROM [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event) AS [TimeZone]
					
		IF @IsDevQA = 1 SELECT DistributorID
							  ,PK_Distributor
							  ,PK_Event
							  ,IsQualified
							  ,IsRegistered
							  ,Companions
							  ,SpouseAttended
							  ,TimeZone FROM @in;
		
		-- First dataset (Event qualification/registration
		SELECT [IsQualified], [IsRegistered], ISNULL([Companions], 0) AS [Companions], [SpouseAttended], [TimeZone] FROM @in;


		-- Seconda dataset (Subevent Qualifications)
		SELECT
				se.[PK_SubEvent]
				,se.[SubEventName]
				,(SELECT TOP 1 [SubEventQualDesc] FROM [SubEventLocaleDesc] WITH (NOLOCK) WHERE [PK_Event] = i.[PK_Event] AND [PK_SubEvent] = se.[PK_SubEvent]) AS SubEventDesc
				,CASE WHEN l.[DistributorID] IS NULL THEN 0 ELSE 1 END AS [IsQualified]
			FROM [SubEvent] AS se WITH (NOLOCK)
				LEFT JOIN @in AS i ON se.[PK_Event] = i.[PK_Event]
				LEFT JOIN [LocalSubEventQualifier] AS l WITH (NOLOCK) ON l.[DistributorID] = i.[DistributorID]
					AND l.[PK_SubEvent] = se.[PK_SubEvent]
			WHERE se.[PK_Event] = @PK_Event;

		-- Third dataset (Notes)
		SELECT
				n.[PK_Event]
				,i.[DistributorID]
				,n.[CreatedDateUTC] AS [CreationTime]
				,n.[Notes] AS [Note]
				,COALESCE(u.[EventATAccessUserFirstName] + ' ' + u.[EventATAccessUserLastName],
						  d.sFirstName + ' ' + d.sLastName,
						  u.[CreatedBy]) AS CreatedBy
			FROM [EventDistributorNotes] AS n WITH (NOLOCK)
				INNER JOIN @in AS i ON i.[PK_Event] = n.[PK_Event]
					AND i.[PK_Distributor] = n.[PK_Distributor]
				LEFT JOIN [EventATAccessUser] AS U WITH (NOLOCK) ON U.[EventATAccessUserName] = n.[CreatedBy]
				LEFT JOIN [v_Distributor] AS D ON D.[sDistributorID] = n.[CreatedBy]
			ORDER BY n.[CreatedDateUTC] DESC;

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