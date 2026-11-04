CREATE PROCEDURE [dbo].[usp_EventsAT_Save_LandingPage]
		-- Mandatory
		 @Title			varchar(100) = 'Test LDW'
		,@Locale		varchar(5) = 'en-US'
		,@Events		udt_LPEvents READONLY
		,@Image			udt_LPImage	 READONLY
		,@EventURL		udt_EventURL READONLY
		,@ModifiedBy	nvarchar(50)
		
		-- Optional
        ,@TitleID	int = NULL OUTPUT
		,@TitleDesc	varchar(1000) = NULL
		,@PageTile varchar(255) = NULL
		,@PageSummary varchar(max) = NULL
		,@TicketLink varchar(255) = NULL
		,@IsTicketLinkDisplayed bit = 0
		,@ProductLink varchar(255) = NULL
		,@IsProductLinkDisplayed bit = 0
		,@IsPublished bit = 0
		,@IsPersistentGroup bit = 0

		-- Defaults
		,@PK_EventGroupType int = 1

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/*
OBJECT:		dbo.usp_EventsAT_Save_LandingPage

USE:	
	begin tran 
			DECLARE @e int, @em varchar(4000)
			DECLARE @Events udt_LPEvents
			DECLARE @Image	udt_LPImage
			DECLARE @EventURL udt_EventURL
			--select top 10 * from Event order by pk_event desc

			INSERT INTO @Events
			VALUES  (null,21)
					,(null,22)
					,(null,23)
					
			INSERT @Image VALUES (null, null, 1, 77, 'Logo en', 'MyLogo.jpg', 1),
								 (null, null, 2, 77, 'Banner en US1', 'Banner_en1.jpg', 1),
								 (null, null, 2, 77, 'Banner en US2', 'Banner_en2.jpg', 1),
								 (null, null, 2, 77, 'Banner en US3', 'Banner_en3.jpg', 1)
	
			INSERT INTO @EventURL VALUES (NULL, 21, 'en-US', 'http://53844.com/primerlink_cambio', 'Descripción del primer link', NULL, 0)
										,(NULL, 21, 'en-US', 'http://53844.com/linken-us_cambio', 'Link en-US description', NULL, 0)
										,(NULL, 21, 'es-US', 'http://53844.com/linkes-es_cambio', 'Descripción del link es-US', NULL, 0)
										,(NULL, 23, 'en-US', 'http://53843.com/linkes-en_cambio', 'Descripción del link en-US 53843', NULL, 0)
										,(NULL, 23, 'en-US', 'http://53845.com/linkes-en_cambio', 'Descripción del link en-US 53845', NULL, 0)
									
			EXEC usp_EventsAT_Save_LandingPage
					@Title = 'Prueba LDW T6'
					,@TitleDesc = 'LDW test'
					,@TitleID = 35
					,@Locale = 'en-US'
					,@Events = @Events
					,@Image	= @Image
					,@EventURL =  @EventURL
					,@PageTile = 'Page title for group event'
					,@PageSummary = 'Page '
					,@TicketLink = NULL
					,@IsTicketLinkDisplayed = 0
					,@ProductLink = NULL
					,@IsProductLinkDisplayed = 0
					,@IsPublished = 0
					,@ModifiedBy = 'RogelioR'
					,@Error = @e OUTPUT  -- @e must be defined in the local call
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
			rollback tran

DESCRIPTION:	Save Events landing Page, Grouping events together for specific events (like LDW, FSL, Kickoff Events or other DS events)

NOTES:

DEPENDENCIES
--------------------------------------------------------------------
dbo.EventGroups, dbo.EventGroupImageLocale, dbo.EventGroupAudience

VERSIONS
--------------------------------------------------------------------
1	2015-10-14			SandhyaP			Initial
2	2017-05-18			RogelioR			Added new columns (PageTitle, PageSummary, TicketLink, IsTicketLinkDisplayed, ProductLink, IsProductLinkDisplayed) and save attachments 
											functionality (EventGroupURL)
3	2017-11-22			RogelioR			Added IsPublished functionality
4	2018-09-18			RogelioR			Added IsPersistentGroup functionality
5	2019-08-08			NoeG				Refactor code (SRE)

*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE @CurrDate datetime
DECLARE @PK_Locale INT
DECLARE @PK_EventImageType INT
DECLARE @PK_DefaultLocale INT
DECLARE @PK_EventGroup TABLE (PK_EventGroup INT)

SET @CurrDate = GETUTCDATE()

/* GET PK_Locale */
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @Locale;

SELECT @PK_DefaultLocale = PK_DefaultLocale FROM EventGroups WITH (NOLOCK) WHERE PK_EventGroup = @TitleID;

SELECT @ModifiedBy = ISNULL(@ModifiedBy, (REPLACE(SUSER_SNAME(),'HERBALIFECORP\','')));

/* Validate Title is already in use */
IF @TitleID IS NULL AND EXISTS (SELECT [PK_EventGroupLocale] FROM dbo.EventGroupLocale WITH (NOLOCK) WHERE EventGroupName = @Title AND PK_Locale = @PK_Locale)
BEGIN
	SET @Error = 414
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error 
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END


	BEGIN TRY

			-- Insert/Update Landing page Title
		
			;WITH Title (TitleID, Title, TitleDesc, PK_Locale)
			AS (SELECT @TitleID, @Title, @TitleDesc, @PK_Locale)
			Merge dbo.EventGroups As T
			Using Title As S
				On T.PK_EventGroup = S.TitleID 
			When Matched AND T.PK_DefaultLocale = @PK_Locale Then Update
				Set EventGroupName = S.Title
					,EventgroupDesc = S.TitleDesc
					,ModifiedDateUTC = GetUTCDate()
					,ModifiedBy = @ModifiedBy
					,IsPublished = @IsPublished
					,IsPersistentGroup = @IsPersistentGroup
			When Not Matched Then Insert
			(
				EventGroupName
				,EventGroupDesc
				,PK_DefaultLocale
				,PK_EventGroupType
				,CreatedDateUTC
				,CreatedBy
				,ModifiedDateUTC
				,ModifiedBy
				,IsPublished
				,IsPersistentGroup
			)
			Values
			(
				S.Title 
				,S.TitleDesc
				,S.PK_Locale
				,@PK_EventGroupType
				,@CurrDate
				,@ModifiedBy
				,@CurrDate
				,@ModifiedBy
				,@IsPublished
				,@IsPersistentGroup
			)
			OUTPUT inserted.PK_EventGroup INTO @PK_EventGroup
	;

	If @TitleID IS NULL
	BEGIN

	SET @TitleID = SCOPE_IDENTITY()

	END

	IF @IsDevQA = 1 SELECT @TitleID AS PK_EventGroup;

			WITH Title (TitleID, Title, TitleDesc, PK_Locale, PageTitle, PageSummary, TicketLink, IsTicketLinkDisplayed, ProductLink, IsProductLinkDisplayed)
			AS (SELECT @TitleID, @Title, @TitleDesc, @PK_Locale, @PageTile, @PageSummary, @TicketLink, @IsTicketLinkDisplayed,@ProductLink, @IsProductLinkDisplayed)
			Merge dbo.EventGroupLocale As T
			Using Title As S
				On T.PK_EventGroup = S.TitleID AND T.PK_Locale = @PK_Locale
			When Matched Then Update
				Set EventGroupName = S.Title,
					EventgroupDesc = S.TitleDesc,
					PageTitle = S.PageTitle,
					PageSummary = S.PageSummary,
					TicketLink = S.TicketLink,
					IsTicketLinkDisplayed = S.IsTicketLinkDisplayed,
					ProductLink = S.ProductLink,
					IsProductLinkDisplayed = S.IsProductLinkDisplayed,
					ModifiedDateUTC = GetUTCDate(),
					ModifiedBy = @ModifiedBy
			When Not Matched Then Insert
					(
						PK_EventGroup
						,PK_Locale
						,EventGroupName
						,EventGroupDesc	
						,PageTitle
						,PageSummary
						,TicketLink
						,IsTicketLinkDisplayed
						,ProductLink
						,IsProductLinkDisplayed
						,CreatedDateUTC
						,CreatedBy
						,ModifiedDateUTC
						,ModifiedBy
					)
					Values
					(
						@TitleID
						,@PK_Locale
						,S.Title
						,S.TitleDesc
						,S.PageTitle
						,S.PageSummary
						,S.TicketLink
						,S.IsTicketLinkDisplayed
						,S.ProductLink
						,S.IsProductLinkDisplayed
						,@CurrDate
						,@ModifiedBy
						,@CurrDate
						,@ModifiedBy
					)
	;
		
			--
			IF @PK_DefaultLocale = @PK_Locale
				UPDATE dbo.EventGroupLocale SET EventGroupName = @Title WHERE PK_EventGroup = @TitleID

		IF @IsDevQA = 1 SELECT 'EventGroupLocale';

		-- Insert/Update the Events
			;WITH EventMembersTarget (PK_EventGroup, PK_Event, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy)
			AS
			(SELECT PK_EventGroup, PK_Event, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy
			FROM dbo.EventGroupMembers WITH (NOLOCK) 
			WHERE PK_EventGroup IN (SELECT PK_EventGroup FROM @Events))
			Merge EventMembersTarget As T
			Using @Events As S
				On (T.PK_EventGroup = S.PK_EventGroup AND T.PK_Event = S.PK_Event)
			When Matched Then Update
				Set ModifiedDateUTC = GetUTCDate(),
					ModifiedBy = @ModifiedBy
			When Not Matched Then Insert
			(
				PK_Event
				,PK_EventGroup
				,CreatedDateUTC
				,CreatedBy
				,ModifiedDateUTC
				,ModifiedBy
			)
			Values
			(
				S.PK_Event 
				,@TitleID
				,@CurrDate
				,@ModifiedBy
				,@CurrDate
				,@ModifiedBy
			)
			When Not Matched By Source Then Delete
	;

	IF @IsDevQA = 1 SELECT 'EventGroupMembers';

		-- Insert/Update the Logo/Banner
		
			WITH LogoBanner (PK_EventGroupImageLocale, PK_EventGroup, PK_EventImageType, PK_Locale, ImageTitle, ImageLocation)
			 AS
			(SELECT PK_EventGroupImageLocale, PK_EventGroup, PK_EventImageType, PK_Locale, ImageTitle, ImageLocation
			 FROM @Image
			 WHERE IsActive = 1
			 )
			 ,EventBannerTarget (PK_EventGroupImageLocale, PK_EventGroup, PK_EventImageType, PK_Locale, ImageTitle, ImageLocation, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy)
			 AS
			(SELECT EL.PK_EventGroupImageLocale, EL.PK_EventGroup, EL.PK_EventImageType, EL.PK_Locale, EL.ImageTitle, EL.ImageLocation, EL.CreatedDateUTC, EL.CreatedBy, EL.ModifiedDateUTC, EL.ModifiedBy
			 FROM dbo.EventGroupImageLocale EL WITH (NOLOCK)
			 INNER JOIN @Image I
			 ON EL.PK_EventGroupImageLocale = I.PK_EventGroupImageLocale
			 )
			Merge EventBannerTarget As T
			Using LogoBanner As S
				On (T.PK_EventGroupImageLocale  = S.PK_EventGroupImageLocale)  
			When Matched Then Update
				Set ImageTitle = S.ImageTitle,
					ImageLocation = S.ImageLocation,
					ModifiedDateUTC = GetUTCDate(),
					ModifiedBy = @ModifiedBy
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
				@TitleID
				,S.PK_EventImageType
				,S.PK_Locale
				,S.ImageTitle
				,S.ImageLocation
				,@CurrDate
				,@ModifiedBy
				,@CurrDate
				,@ModifiedBy
			)
			When Not Matched By Source Then Delete;

		IF @IsDevQA = 1 SELECT 'EventBannerTarget'

		---------------------------------------------------------------------------------------
		-- Update links on EventGroupURL
		-- 
		MERGE [dbo].[EventGroupURL] AS t
			USING (SELECT
						e.PK_EventURL AS PK_EventGroupURL
						,@TitleID AS PK_EventGroup
						,e.LocaleCode AS LocaleCode
						,l.PK_Locale AS PK_Locale
						,e.EventURL AS EventGroupURL
						,e.EventURLDesc AS EventGroupURLDesc
						,e.Flyer AS Flyer
						,e.IsDelete AS IsDelete
						,1 AS PK_EventURLType
					FROM @EventURL AS e
						INNER JOIN Locales AS l WITH (NOLOCK) ON e.LocaleCode = l.LocaleCode) AS s	
				ON (s.PK_EventGroupURL = t.PK_EventGroupURL)
			WHEN NOT MATCHED THEN
				INSERT (
					[PK_EventGroup]
					,[PK_Locale]
					,[EventGroupURL]
					,[EventGroupURLDesc]
					,[Flyer]
					,[PK_EventURLType]				
				)
				VALUES (
					[PK_EventGroup]
					,s.[PK_Locale]
					,s.[EventGroupURL]
					,s.[EventGroupURLDesc]
					,s.[Flyer]
					,s.[PK_EventURLType]
				)
			WHEN MATCHED AND s.IsDelete = 1 THEN
				DELETE
			WHEN MATCHED THEN
				UPDATE SET
					[PK_Locale] = s.[PK_Locale]
					,[EventGroupURL] = s.[EventGroupURL]
					,[EventGroupURLDesc] = s.[EventGroupURLDesc]
					,[Flyer] = s.[Flyer]
					,[PK_EventURLType] = s.[PK_EventURLType]
			;	-- MERGE EventGroupURL
	
	IF @IsDevQA = 1 SELECT '[EventGroupURL]'

	SELECT @TitleID	TitleID

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

END
GO

