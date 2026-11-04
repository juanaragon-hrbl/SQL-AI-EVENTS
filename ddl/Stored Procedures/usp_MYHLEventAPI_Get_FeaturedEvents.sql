CREATE PROCEDURE [dbo].[usp_MYHLEventAPI_Get_FeaturedEvents]
		-- Mandatory
		@Locales varchar(max)

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		--
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.[usp_MYHLEventAPI_Get_FeaturedEvents]

USE:	        
				DECLARE @e int, @em varchar(4000)
				EXEC dbo.[usp_MYHLEventAPI_Get_FeaturedEvents]
						-- Mandatory
					 	@Locales = 'es-US,en-US'
						,@Error = @e OUTPUT
						,@ErrorMessage = @em OUTPUT
						,@IsDevQA = 1
					
				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Displays all the events & promotions that are marked as featured events on the Add Corporate Event page for a logged in locale

VERSIONS
----------------------------------------------------------------------------------
1	2016-06-08			SushmaA			Landing Page Featured Event Search
2	2017-03-08			RogelioR		Show default values for events
3	2018-04-09			RogelioR		Locales now accept a comma separated value with different locales and returns only events that include all
4	2019-08-14			NoeG			Refactor code (SRE)
5	2020-09-30			puertac			BUG 342679 Admin Tool - Featured Section - Default overview not saving changes 
										(actually not retrieving the changes, the data was saved correctly)
6	2021-06-04			puertac			BUG 652518 : Duplicated events are being displayed within featured section module 
7	2022-09-05			puertac			BUG 1112652 : Public Event with out select Team Level not display in feature section
******************************************************************************/
	
	-- DECLARE THE LOCAL VARIABLES 

	DECLARE @PK_Locale INT
			,@PK_DefaultLocale INT
			,@PK_DefaultEventID INT = 1220
			,@CurrentDate DATETIME = GETUTCDATE()
			,@n int	-- Number of locales
			,@DefaultRows int			-- BUG 342679

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	
	BEGIN TRY

		--- SET THE VARIABLES
		SELECT @PK_DefaultLocale = [PK_Locale] FROM [dbo].[Locales] WITH(NOLOCK) WHERE [LocaleCode] = 'en-US';

		IF OBJECT_ID('tempdb..#Locales') IS NOT NULL
			DROP TABLE #Locales;
	
		SELECT	l.[PK_Locale]
				,l.[LocaleCode]
			INTO #Locales
			FROM [Locales] AS l WITH(NOLOCK)
				INNER JOIN (SELECT [String] AS [LocaleCode] FROM [udf_SplitVarchar](@Locales, ',')) AS f ON l.[LocaleCode] = f.[LocaleCode];
	
		SELECT @n = @@ROWCOUNT;
	
		IF @IsDevQA = 1 SELECT @n AS '#Locales', PK_Locale
												,LocaleCode FROM #Locales;

		-- Get valid TeamLevels for featured section 
		DROP TABLE IF EXISTS #DSTeamType

		SELECT PK_DSTeamType, DSTeamTypeCode, TeamOrder, TeamDisplayOrder, TransitionLevelGroup
		INTO #DSTeamType
		FROM dbo.DSTeamType WITH (NOLOCK)
		WHERE PK_DSTeamType <= 38		-- Where regular DS teams IDs end (PK_DSTeamType from dbo.DSTeamType)
			
	
		-- 1. select all the featured events
		--
		IF OBJECT_ID('tempdb..#Events') IS NOT NULL
			DROP TABLE #Events;

		SELECT DISTINCT
				 e.[PK_Event]
				,e.[EventName]
				,t.[PK_DSTeam]
				,CASE WHEN t.[TeamDesc] = 'N.A.' THEN 'Distributor' 
					  WHEN t.[TeamDesc] = 'No Team' THEN 'Fully Qualified Supervisor' 	
					  ELSE t.[TeamDesc] END AS [Team]
				,ISNULL(FE.IsActive, 0) AS [IsFeatured]
				,edl.PK_Locale
			INTO #Events
			FROM [dbo].[Event]  AS e WITH(NOLOCK)
			INNER JOIN [dbo].[EventDistributorCountryLocales] AS edl  WITH(NOLOCK) 
				ON e.[PK_Event] = edl.[PK_Event]
			INNER JOIN #Locales L 												-- BUG 652518
				ON edl.[PK_Locale] = L.PK_Locale								-- BUG 652518
			INNER JOIN [dbo].[EventDSTeamType] AS edt  WITH(NOLOCK) 
				ON edt.[PK_Event] = e.[PK_Event]
			INNER JOIN #DSTeamType AS dt   
				ON edt.[DSTeamTypeCode] = dt.[DSTeamTypeCode]
			INNER JOIN [pubEvents].[dbo].[dimDSSubType] AS st WITH(NOLOCK) 
				ON st.[SubTypeCode] = dt.[DSTeamTypeCode]
			INNER JOIN [PubEvents].[dbo].[dimDSTeam] AS t WITH(NOLOCK) 
				ON st.[PK_DSTeam] = t.[PK_DSTeam]
			LEFT JOIN [dbo].[FeaturedEvents] AS fe WITH(NOLOCK) 
				ON edl.[PK_Event] = fe.[PK_Event]								-- BUG 652518
				AND edl.PK_Locale = fe.PK_Locale								-- BUG 652518
				AND t.[PK_DSTeam] = fe.[PK_DSTeam]			
			WHERE @CurrentDate BETWEEN e.[DisplayStartDate] AND (e.[DisplayEndDate] + 1)
			AND e.[PK_EventType] IN (1, 2) -- for Corp Event & Promotion
			AND e.[IsPublish] = 1
			ORDER BY [Team], e.[EventName]
	
	
		-- Include Events x all team levels when MakePublic = 1	(no team level records on EventDSTeamType) 			-- BUG 1112652
		INSERT INTO #Events
		SELECT DISTINCT
				e.[PK_Event]
			,e.[EventName]
			,t.[PK_DSTeam]
			,CASE WHEN t.[TeamDesc] = 'N.A.' THEN 'Distributor' 
					WHEN t.[TeamDesc] = 'No Team' THEN 'Fully Qualified Supervisor' 	
					ELSE t.[TeamDesc] END AS [Team]
			,ISNULL(FE.IsActive, 0) AS [IsFeatured]
			,edl.PK_Locale
		FROM [dbo].[Event]  AS e WITH(NOLOCK)
		INNER JOIN [dbo].[EventDistributorCountryLocales] AS edl  WITH(NOLOCK) 
			ON e.[PK_Event] = edl.[PK_Event]
		INNER JOIN #Locales L 												-- BUG 652518
			ON edl.[PK_Locale] = L.PK_Locale								-- BUG 652518
		CROSS APPLY #DSTeamType AS dt WITH(NOLOCK) 
		INNER JOIN [pubEvents].[dbo].[dimDSSubType] AS st WITH(NOLOCK) 
			ON st.[SubTypeCode] = dt.[DSTeamTypeCode]
		INNER JOIN [PubEvents].[dbo].[dimDSTeam] AS t WITH(NOLOCK) 
			ON st.[PK_DSTeam] = t.[PK_DSTeam]
		LEFT JOIN [dbo].[FeaturedEvents] AS fe WITH(NOLOCK) 
			ON edl.[PK_Event] = fe.[PK_Event]								-- BUG 652518
			AND edl.PK_Locale = fe.PK_Locale								-- BUG 652518
			AND t.[PK_DSTeam] = fe.[PK_DSTeam]			
		WHERE @CurrentDate BETWEEN e.[DisplayStartDate] AND (e.[DisplayEndDate] + 1)
		AND e.[PK_EventType] IN (1, 2) -- for Corp Event & Promotion
		AND e.[IsPublish] = 1
		AND e.MakePublic = 1
		AND NOT EXISTS (SELECT 1 FROM #Events E1 WHERE E1.PK_Event = e.PK_Event)
		ORDER BY [Team], e.[EventName]
	
	
		IF @IsDevQA = 1 SELECT PK_Event
							  ,EventName
							  ,PK_DSTeam
							  ,Team
							  ,IsFeatured
							  ,PK_Locale FROM #Events;

		SELECT DISTINCT
				[PK_Event]
				,[EventName]
				,[PK_DSTeam]
				,[Team]
				,IIF(COUNT(IIF([IsFeatured] = 1, 1, NULL)) = @n, 1, 0) AS IsFeatured 	  -- BUG 652518
		FROM #Events 
		GROUP BY [PK_Event], [EventName], [PK_DSTeam], [Team]							  -- BUG 652518
		HAVING COUNT(*) = @n
		ORDER BY [Team], [EventName];

		-- 2. select all the default values for events	
		DROP TABLE IF EXISTS #DefaultValues							-- BUG 342679
			
		SELECT DISTINCT 											-- BUG 342679 : Distinct when multiple Locales have the same info
				 ei.[PK_EventImage]
				,eil.[EventImageLocation] AS [DefaultBannerImageLocation]
				,ell.[EventDesc] AS [DefaultEventDescription]
				,eul.[EventURL] AS  [DefaultEventLink]
				,eul.[Flyer] AS [DefaultEventAttachment]
		INTO #DefaultValues
		FROM [dbo].[Event] AS e WITH(NOLOCK)
				LEFT JOIN [dbo].[EventImage] AS ei WITH(NOLOCK) ON e.[PK_Event] = ei.[PK_Event]
					AND ei.[PK_EventImageType] = 4 ---- default banner
				LEFT JOIN [dbo].[EventImageLocaleDesc] AS eil WITH(NOLOCK) ON e.[PK_Event] = eil.[PK_Event]
					AND ei.[PK_EventImage] = eil.[PK_EventImage]
					AND eil.[PK_Locale] IN (SELECT PK_Locale FROM #Locales)												-- BUG 342679
				INNER JOIN [dbo].[EventLocaleDesc] AS ell WITH(NOLOCK) ON e.[PK_Event] = ell.[PK_Event]
					AND ell.[PK_Locale]	IN (SELECT PK_Locale FROM #Locales)												-- BUG 342679
				LEFT JOIN [dbo].[EventURL] AS eul WITH(NOLOCK) ON E.PK_Event = EUL.PK_Event
					AND EUL.PK_Locale IN (SELECT PK_Locale FROM #Locales)												-- BUG 342679
					AND	EUL.PK_EventURLType = 8
			WHERE E.PK_Event = @PK_DefaultEventID ---DEFAULT EVENT																		
	
		SELECT @DefaultRows = @@ROWCOUNT		-- BUG 342679

		IF (@DefaultRows >1)					-- BUG 342679 : Delete all items to not show any results when more than 1 record
			DELETE FROM #DefaultValues
		
		
		SELECT PK_EventImage					-- BUG 342679	
				,DefaultBannerImageLocation
				,DefaultEventDescription
				,DefaultEventLink
				,DefaultEventAttachment
		FROM #DefaultValues
		
		
		SELECT L.LocaleCode, L.LanguageCountryRegion
			FROM dbo.Locales L WITH(NOLOCK)
			WHERE L.PK_Locale IN (SELECT PK_Locale FROM #Locales);
		
		
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
		 
	END CATCH;

END