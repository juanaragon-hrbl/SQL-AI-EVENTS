CREATE PROCEDURE [dbo].[usp_MYHLEventAPI_Upd_FeaturedEvents]
	-- Mandatory
	@Locales VARCHAR(MAX)
	,@FeaturedEvents [udt_FeaturedEvents] READONLY
	,@ModifiedBy VARCHAR(30) = 'UsrSQLProd'

	--Optional
	,@PK_EventImage INT = NULL
	,@BannerImageLocation VARCHAR(MAX) = NULL
	,@EventDesc VARCHAR(MAX) = NULL
	,@EventLink VARCHAR(MAX) = NULL
	,@EventAttachment VARCHAR(MAX) = NULL
	
	-- Error Parameters
	,@Error INT OUTPUT
	,@ErrorMessage VARCHAR(200) OUTPUT

	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
OBJECT:			dbo.[usp_MYHLEventAPI_Upd_FeaturedEvents]

USE:	        
				DECLARE @e int, @em varchar(200)
				DECLARE @FeaturedEvents [udt_FeaturedEvents]
				
				INSERT @FeaturedEvents (PK_Event, Locales, PK_DSTeam, IsActive)
					VALUES (230, 'es-US,en-US', 5, 1)
						,(231, 'es-MX,es-US,en-US', 3, 1)
						,(231, 'es-MX,es-US,en-US', 4, 0)
						,(231, 'es-MX,es-US,en-US', 5, 1);

				EXEC dbo.[usp_MYHLEventAPI_Upd_FeaturedEvents]
					-- Mandatory
					@Locales = 'en-US, es-US'
					,@FeaturedEvents = @FeaturedEvents
					,@PK_EventImage  = 37645
					,@BannerImageLocation  = 'D:\AppData\EventsAndPromotion\Image\EventImage\376d6a7c-5748-4c66-beb2-64cffa069858Logo_per_sito...jpg'
					,@EventDesc = 'Default Event Description - UK'
					,@EventLink = 'http:\\uk.myherbalife.com'
					,@EventAttachment = 'http://herbalifemail.com/Flyers/2011_ldw_usen.pdf'
					,@Error = @e
					,@ErrorMessage = @em
			   
			   SELECT @e, @em

			   SELECT <all> FROM FeaturedEvents where PK_Event in (230, 231);
			   select <all> from 

DESCRIPTION:	updated the events & promotions that are marked as featured events for a logged in locale

VERSIONS
----------------------------------------------------------------------------------
1	2016-06-15			SushmaA			Landing Page Featured Events Insert/Update
2	2018-02-26			RogelioR		Stored procedure can now process multiple locales for Event/Team in udt_FeaturedEvents
3	2020-10-12			puertac			BUG 342679 - Admin Tool - Featured Section - Default overview not saving changes (PK_EventImageType = 4 for Default Banner)
******************************************************************************/
				 
-- DECLARE THE LOCAL VARIABLES 

	DECLARE @PK_Locale INT
	DECLARE @PK_DefaultLocale INT
	DECLARE @PK_DefaultEventID INT = 1220
	DECLARE @CurrentDate DATE = CONVERT(DATE,GETUTCDATE(), 110)
	DECLARE @StoredProcedure VARCHAR(100)
	DECLARE @StartTime DATETIME
	DECLARE @PK_DefaultBannerType INT

	--- SET THE VARIABLES 
	SELECT @PK_DefaultLocale =  PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = 'en-US'
	SELECT @PK_DefaultBannerType = PK_EventImageType FROM dbo.EventImageType WITH (NOLOCK) WHERE EventImageType = 'Default Banner Location'

	/* SET THE VALUES FOR THE LOCAL VARIABLES */
	SET @ErrorMessage = 'No Error.'
	SET @StoredProcedure = 'usp_MYHLEventAPI_Upd_FeaturedEvents'
	SET @StartTime = GETUTCDATE()

	-- Decode locales
	DECLARE @InLocales table (
			[PK_Locale] int
		);

	INSERT INTO @InLocales
		SELECT l.[PK_Locale] 
			FROM [udf_SplitVarchar](@Locales, ',') AS s
				INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[LocaleCode] = s.[String];

	--IF @IsDevQA = 1 SELECT all FROM @InLocales;

	BEGIN TRY
		--1.  INACTIVATE ALL THE EVENTS FOR A PARTICULAR TEAM LEVEL		
		IF OBJECT_ID('tempdb..#FeaturedEvents') IS NOT NULL
			DROP TABLE #FeaturedEvents;

		SELECT 
				f.[PK_Event]
				,f.[PK_DSTeam]
				,f.[IsActive]
				,(SELECT [PK_Locale] FROM [Locales] WITH (NOLOCK) WHERE [LocaleCode] = l.[String]) AS [PK_Locale]
				,@ModifiedBy AS [ModifiedBy]	
				,@StartTime AS [StartTime]
			INTO #FeaturedEvents
			FROM @FeaturedEvents as f
				OUTER APPLY [udf_SplitVarchar](f.[Locales], ',') AS l;

		UPDATE t SET
				[IsActive] = 0
			FROM [FeaturedEvents] AS t
				INNER JOIN #FeaturedEvents AS f ON t.[PK_DSTeam] = f.[PK_DSTeam]
					AND t.[PK_Locale] = f.[PK_Locale]
					AND f.[IsActive] = 1;
					
		--2.  UPDATE THE FEATURED EVENTS FOR A PARTICULAR LOCALE TEAM-WISE
		DECLARE @fe table (
			[action] varchar(10)
			,[PK_Event] int
			,[PK_DSTeam] int
			,[IsActive] bit
			,[PK_Locale] int
		);

		MERGE [dbo].[FeaturedEvents] AS t
			USING (
				SELECT 
						f.[PK_Event]
						,f.[PK_DSTeam]
						,f.[IsActive]
						,(SELECT [PK_Locale] FROM [Locales] WITH (NOLOCK) WHERE [LocaleCode] = l.[String]) AS [PK_Locale]
						,@ModifiedBy AS [ModifiedBy]
						,@StartTime AS [StartTime]
					FROM @FeaturedEvents AS f
						OUTER APPLY [dbo].[udf_SplitVarchar](f.Locales, ',') AS l
				) AS s
				ON s.[PK_Event] = t.[PK_Event]
					AND s.[PK_DSTeam] = t.[PK_DSTeam]
					AND s.[PK_Locale] = t.[PK_Locale]
			WHEN NOT MATCHED THEN 
				INSERT (
					[PK_Event]
					,[PK_Locale]
					,[PK_DSTeam]
					,[IsActive]
					,[CreatedUTC]
					,[CreatedBy]
					,[ModifiedUTC]
					,[ModifiedBy]
				)
				VALUES(
					s.[PK_Event]
					,s.[PK_Locale]
					,s.[PK_DSTeam]
					,s.[IsActive]
					,s.[StartTime]
					,s.[ModifiedBy]
					,s.[StartTime]
					,s.[ModifiedBy]
				)
			WHEN MATCHED  THEN
				UPDATE SET
					[IsActive] = s.[IsActive]
					,[ModifiedUTC] = s.[StartTime]
					,[ModifiedBy] = s.[ModifiedBy]
			OUTPUT	$action
					,inserted.[PK_Event]
					,inserted.[PK_DSTeam]
					,inserted.[IsActive]
					,inserted.[PK_Locale]
				INTO @fe
			;	-- MERGE [FeaturedEvents]

			IF @IsDevQA = 1 SELECT PK_Event FROM @fe;

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()
	
		IF @IsDevQA = 1 SELECT 'Catch 1', @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH

	----- UPDATE DEFAULT BANNER/DESCRIPTION/URL
	BEGIN TRY
		DECLARE @MergeEventImage table (
			[action] varchar(10)
			,[PK_EventImage] int
		);

		MERGE [dbo].[EventImage] AS t
			USING (
				SELECT
						ISNULL(@PK_EventImage, (SELECT [PK_EventImage] FROM [dbo].[EventImage] WITH (NOLOCK) WHERE PK_Event = @PK_DefaultEventID AND PK_EventImageType = 4)) AS [PK_EventImage]		-- BUG 342679 PK_EventImageType = 4
						,@BannerImageLocation AS [EventImageLocation]
						,@StartTime AS [CreatedDateUTC]
						,@ModifiedBy AS [CreatedBy]
						,@StartTime AS [ModifiedDateUTC]
						,@ModifiedBy AS [ModifiedBy]
						,@PK_DefaultEventID AS [PK_Event]
						,4	AS [PK_EventImageType] -- Banner					-- BUG 342679 PK_EventImageType = 4
				) AS s ON s.[PK_EventImage] = t.[PK_EventImage]
			WHEN NOT MATCHED THEN
				INSERT (
					[EventImageLocation]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[PK_Event]
					,[PK_EventImageType]
				)
				VALUES (
					s.[EventImageLocation]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[PK_Event]
					,s.[PK_EventImageType]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[EventImageLocation] = s.[EventImageLocation]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
			OUTPUT $action, inserted.[PK_EventImage] INTO @MergeEventImage
		; -- MERGE [EventImage]

		SELECT @PK_EventImage = ISNULL(@PK_EventImage, (SELECT PK_EventImage FROM @MergeEventImage));

		MERGE [dbo].[EventImageLocaleDesc] AS t
			USING (
				SELECT
						e.[PK_EventImageLocaleDesc]
						,@BannerImageLocation AS [EventImageLocation]
						,@StartTime AS [CreatedDateUTC]
						,@ModifiedBy AS [CreatedBy]
						,@StartTime AS [ModifiedDateUTC]
						,@ModifiedBy AS [ModifiedBy]
						,@PK_EventImage AS [PK_EventImage]
						,@PK_DefaultEventID AS [PK_Event]
						,i.[PK_Locale]
					FROM @InLocales AS i
						LEFT JOIN [dbo].[EventImageLocaleDesc] AS e WITH (NOLOCK) ON e.[PK_Event] = @PK_DefaultEventID
							AND e.[PK_EventImage] = @PK_EventImage			
							AND e.[PK_Locale] = i.[PK_Locale]
				) AS s
				ON t.[PK_Event] = s.[PK_Event]
					AND t.[PK_EventImage] = s.[PK_EventImage]	
					AND t.PK_Locale = s.PK_Locale
			WHEN NOT MATCHED THEN
				INSERT (
					[PK_Event]
					,[PK_EventImage]
					,[PK_Locale]
					,[EventImageLocation]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
				VALUES (
					s.[PK_Event]
					,s.[PK_EventImage]
					,s.[PK_Locale]
					,s.[EventImageLocation]
					,s.[CreatedDateUTC]
					,s.[ModifiedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
				)
			WHEN MATCHED THEN
				UPDATE SET 
					[EventImageLocation] = s.[EventImageLocation]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
		;	-- MERGE [EventImageLocaleDesc]
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
	
		--UPDATE EVENT DESCRIPTION
	BEGIN TRY	
		MERGE [dbo].[EventLocaleDesc] t
			USING (
				SELECT 
						@PK_DefaultEventID AS [PK_Event]
						,@EventDesc AS [EventDesc]
						,12 AS [PK_EventType]
						,[PK_Locale]
						,@ModifiedBy AS [ModifiedBy]
						,@StartTime AS [StartTime] 
					FROM @InLocales
				) AS s	
				ON t.[PK_Event] = s.[PK_Event] AND t.[PK_Locale] = s.[PK_Locale]
			WHEN NOT MATCHED THEN 
				INSERT (
					[PK_Event]
					,[PK_Locale]
					,[PK_EventType]
					,[EventDesc]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
				VALUES(
					s.[PK_Event]
					,s.[PK_Locale]
					,s.[PK_EventType]
					,s.[EventDesc]
					,s.[StartTime]
					,s.[ModifiedBy]
					,s.[StartTime]
					,s.[ModifiedBy])
			WHEN MATCHED THEN
				UPDATE SET 
					[EventDesc] = s.[EventDesc]
					,[ModifiedDateUTC] = s.[StartTime]
					,[ModifiedBy] = s.[ModifiedBy]
		; -- [EventLocaleDesc]

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
	
		--UPDATE EVENT URL FOR LINK/ATTACHMENT
	BEGIN TRY		
		MERGE [dbo].[EventURL] AS t
			USING (
				SELECT
						u.[PK_EventURL]
						,@PK_DefaultEventID AS [PK_Event]
						,l.[PK_Locale]
						,@EventLink AS [EventURL]
						,@EventAttachment AS [Flyer]
						,@StartTime AS [CreatedDateUTC]
						,@ModifiedBy AS [CreatedBy]
						,@StartTime AS [ModifiedDateUTC]
						,@ModifiedBy AS [ModifiedBy]
						,8 AS [PK_EventURLType]	-- Landing page default attachment
					FROM @InLocales AS l
						LEFT JOIN [dbo].[EventURL] AS u WITH (NOLOCK) ON u.[PK_Event] = @PK_DefaultEventID
							AND u.[PK_Locale] = l.[PK_Locale]
							AND u.[PK_EventURLType] = 8
				) AS s ON s.[PK_EventURL] = t.[PK_EventURL]
			WHEN NOT MATCHED THEN
				INSERT (
					[PK_Event]
					,[PK_Locale]
					,[EventURL]
					,[Flyer]
					,[PK_EventURLType]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
				VALUES(
					[PK_Event]
					,[PK_Locale]
					,[EventURL]
					,[Flyer]
					,[PK_EventURLType]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
		WHEN MATCHED THEN
			UPDATE SET 
				[Flyer] = s.[Flyer]
				,[EventURL] = s.[EventURL]
				,[ModifiedDateUTC] = s.[ModifiedDateUTC]
				,[ModifiedBy] = s.[ModifiedBy]
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
	-- Deployment: 20180425
END