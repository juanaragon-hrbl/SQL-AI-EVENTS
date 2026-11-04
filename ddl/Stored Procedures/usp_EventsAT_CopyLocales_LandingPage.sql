CREATE PROCEDURE [dbo].[usp_EventsAT_CopyLocales_LandingPage]
		-- Mandatory
        @TitleID	INT
		,@FromLocale VARCHAR(5)
		,@ToLocales	udt_EventAudience READONLY
		,@ModifiedBy NVARCHAR(50)

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

			-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
 
/******************************************************************************
OBJECT:		dbo.usp_EventsAT_CopyLocales_LandingPage

USE:	
			DECLARE @e int, @em varchar(4000)
			DECLARE @ToLocales udt_EventAudience

			INSERT @ToLocales VALUES (1), (78)
			
			EXEC usp_EventsAT_CopyLocales_LandingPage
					@TitleID = 29
					,@FromLocale = 'en-US'
					,@ToLocales	= @ToLocales
					,@ModifiedBy = 'SandhyaP'
					,@Error = @e OUTPUT  -- @e must be defined in the local call
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Save Events landing Page, Grouping events together for specific events (like LDW, FSL, Kickoff Events or other DS events)

NOTES:

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventGroups
dbo.EventGroupImageLocale
dbo.EventGroupAudience

VERSIONS
--------------------------------------------------------------------
	1.0.0		2015-10-14			SandhyaP			Initial
	1.1.0		2017-06-09			RogelioR			Add new fields in EventGroupLocale
	1.2.0		2019-10-16			puertac				SRE Implementation 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE()
		,@CurrDate datetime = GETUTCDATE()
		,@PK_EventGroupType INT = 2
		,@PK_Locale INT
		,@PK_EventImageType INT
		,@ValidLocales udt_EventAudience
		,@InvalidLocales udt_EventAudience
		,@s varchar(255);

SELECT @Error = 0, @ErrorMessage = ''
		,@PK_Locale = (SELECT PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @FromLocale)
		,@CurrDate = GETUTCDATE()
			
INSERT INTO @InvalidLocales
	SELECT PK_Locale 
		FROM EventGroupLocale WITH (NOLOCK)
		WHERE EventGroupName = (SELECT EventGroupName FROM EventGroupLocale WITH (NOLOCK) WHERE PK_EventGroup = @TitleID AND PK_Locale = @PK_Locale)
			AND PK_Locale <> @PK_Locale

INSERT INTO @ValidLocales
	SELECT PK_Locale
		FROM @ToLocales
		WHERE PK_Locale NOT IN (SELECT PK_Locale FROM @InvalidLocales WHERE PK_Locale IS NOT NULL)

/* Validate Title is already in use */
--IF @TitleID IS NULL AND EXISTS (SELECT PK_EventGroupLocale,PK_EventGroup,PK_Locale,EventGroupName,EventGroupDesc,CreatedBy,CreatedDateUTC,ModifiedBy,ModifiedDateUTC,PageTitle,PageSummary,TicketLink,IsTicketLinkDisplayed,ProductLink,IsProductLinkDisplayed FROM dbo.EventGroupLocale WITH (NOLOCK) WHERE EventGroupName = @Title AND PK_Locale = @PK_Locale)
--BEGIN
--	SET @Error = 414
--	-- Update ErrorLog
--	EXEC dbo.usp_Utility_UpdateErrorLog 
--		@ProcedureName = @StoredProcedure 
--		,@ErrorNumber = @Error
--		,@ErrorMessage = @ErrorMessage --OUTPUT
--	RETURN 
--END




BEGIN TRY;
		-- Copy Landing Page for selected locales
		WITH Title AS (
			SELECT 
					EG.PK_EventGroup AS [PK_EventGroup]
					,COALESCE(ELG.EventGroupName, EG.EventGroupName) AS [EventGroupName]
					,COALESCE(ELG.EventGroupDesc, EG.EventGroupDesc) AS [EventGroupDesc]
					,ELG.PageTitle AS [PageTitle]
					,ELG.PageSummary AS [PageSummary]
					,ELG.TicketLink AS [TicketLink]
					,ELG.IsTicketLinkDisplayed AS [IsTicketLinkDisplayed]
					,ELG.ProductLink AS [ProductLink]
					,ELG.IsProductLinkDisplayed AS [IsProductLinkDisplayed]
					,@PK_Locale AS [PK_FromLocale]
					,L.PK_Locale AS [PK_ToLocale]
				FROM dbo.EventGroups EG WITH (NOLOCK) 
					INNER JOIN [dbo].[EventGroupLocale] ELG WITH (NOLOCK) ON EG.PK_EventGroup = ELG.PK_EventGroup
					CROSS JOIN @ValidLocales L 
				WHERE EG.PK_EventGroup = @TitleID AND COALESCE(ELG.PK_Locale, EG.PK_DefaultLocale) = @PK_Locale
		)
		Merge dbo.EventGroupLocale As T
		Using Title As S
			On (T.PK_EventGroup = S.PK_EventGroup AND T.PK_Locale = S.PK_ToLocale)
		When Not Matched Then Insert
		(
			[PK_EventGroup]
			,[EventGroupName]
			,[EventGroupDesc]
			,[PageTitle]
			,[PageSummary]
			,[TicketLink]
			,[IsTicketLinkDisplayed]
			,[ProductLink]
			,[IsProductLinkDisplayed]
			,[PK_Locale]
			,[CreatedDateUTC]
			,[CreatedBy]
			,[ModifiedDateUTC]
			,[ModifiedBy]
		)
		Values
		(
			S.[PK_EventGroup]
			,S.[EventGroupName]
			,S.[EventGroupDesc]
			,S.[PageTitle]
			,S.[PageSummary]
			,S.[TicketLink]
			,S.[IsTicketLinkDisplayed]
			,S.[ProductLink]
			,S.[IsProductLinkDisplayed]
			,S.[PK_ToLocale]
			,@CurrDate
			,@ModifiedBy
			,@CurrDate
			,@ModifiedBy
		)
;

	-- Copy the Logo/Banner for selected locales
		
		;WITH LogoBanner (PK_EventGroupImageLocale, PK_EventGroup, PK_EventImageType, PK_Locale, ImageTitle, ImageLocation)
		 AS
		(SELECT PK_EventGroupImageLocale, EG.PK_EventGroup, PK_EventImageType, L.PK_Locale, ImageTitle, ImageLocation
		 FROM dbo.EventGroups EG WITH (NOLOCK) 
		 INNER JOIN
		 dbo.EventGroupImageLocale EI WITH (NOLOCK)
		 ON
		 EG.PK_EventGroup = EI.PK_EventGroup 
		 AND 
		 EI.PK_Locale = @PK_Locale
		 CROSS JOIN
		 @ValidLocales L
		 WHERE EG.PK_EventGroup = @TitleID
		 )
		 ,EventBannerTarget (PK_EventGroupImageLocale, PK_EventGroup, PK_EventImageType, PK_Locale, ImageTitle, ImageLocation, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy)
		 AS
		(SELECT PK_EventGroupImageLocale, PK_EventGroup, PK_EventImageType, EI.PK_Locale, ImageTitle, ImageLocation, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy
		 FROM dbo.EventGroupImageLocale EI WITH (NOLOCK)
		 INNER JOIN @ValidLocales L
		 ON EI.PK_Locale = L.PK_Locale
		 WHERE PK_EventGroup = @TitleID
		 )
		Merge EventBannerTarget As T
		Using LogoBanner As S
			On (T.PK_EventGroup  = S.PK_EventGroup AND T.PK_Locale = S.PK_Locale AND T.PK_EventImageType = S.PK_EventImageType)  
		When Not Matched Then Insert
		(
			PK_EventGroup
			,PK_EventImageType
			,PK_Locale
			,ImageTitle
			,ImageLocation
			,CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
		)
		Values
		(
			S.PK_EventGroup
			,S.PK_EventImageType
			,S.PK_Locale
			,S.ImageTitle
			,S.ImageLocation
			,@CurrDate
			,@ModifiedBy
			,@CurrDate
			,@ModifiedBy
		)
;	

	------------------------------------------------------------------------------------------
	-- Copy EventGroupURL of the event
	INSERT INTO EventGroupURL (
		[PK_EventGroup]
		,[PK_Locale]
		,[PK_EventURLType]
		,[EventGroupURL]
		,[EventGroupURLDesc]
		,[Flyer]
		,[CreatedDateUTC]
		,[CreatedBy]
		,[ModifiedDateUTC]
		,[ModifiedBy]
	)
	SELECT
			@TitleID AS [PK_EventGroup]
			,l.[PK_Locale] AS [PK_Locale]
			,u.[PK_EventURLType] AS [PK_EventURLType]
			,u.[EventGroupURL] AS [EventGroupURL]
			,u.[EventGroupURLDesc] AS [EventGroupURLDesc]
			,u.[Flyer] AS [Flyer]
			,@CurrDate AS [CreatedDateUTC]
			,@ModifiedBy AS [CreatedBy]
			,@CurrDate AS [ModifiedDateUTC]
			,@ModifiedBy AS [ModifiedBy]
		FROM [dbo].[EventGroupURL] AS u  WITH (NOLOCK)
			CROSS JOIN @ValidLocales AS l
		WHERE u.[PK_Locale] = @PK_Locale
			AND u.PK_EventGroup = @TitleID;

	------------------------------------------------------------------------------------------
	-- Return invalid locales
	SELECT PK_Locale AS InvalidLocales FROM @InvalidLocales;

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