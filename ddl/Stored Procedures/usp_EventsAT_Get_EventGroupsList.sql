CREATE PROCEDURE [dbo].[usp_EventsAT_Get_EventGroupsList]
	-- Optional
	@LocaleCode		varchar(5) = NULL
	,@FilterUnpublished	bit = 1

	-- Defaults
	,@BannerType int = 2

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
EventImageLocaleDesc
	OBJECT:			[dbo].[usp_EventsAT_Get_EventGroupsList]
	
	USE:			
					DECLARE @e int, @em varchar(4000)

					EXEC [dbo].[usp_EventsAT_Get_EventGroupsList]
							@LocaleCode = 'en-US'
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Gets event group list

	NOTES:
	
	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Locales, dbo.EventGroups, dbo.EventGroupLocale, dbo.EventGroupImageLocale, dbo.EventGroupURL

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-06-05		RogelioR		Initial
	1.1.0		2018-09-18		RogelioR		Return [IsPersistentGroup] in datatset
	1.2.0		2019-07-15		alejandramed	Setting error parameters as optionals
	2.0.0		2019-09-30		NoeG			SRE template applied
	2.1.0		2019-10-07		NoeG			Add Flag to hide events on Events Landing Page
	
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
	
	BEGIN TRY;
		-----------------------------------------------------------------------------------------------------------------------
		-- Return groups
		--
		WITH cte_default AS (
			SELECT
					eg.[PK_EventGroup]
					,eg.[PK_DefaultLocale]
					,l.[LocaleCode]
					,d.[EventGroupName]
					,d.[EventGroupDesc]
					,d.[PageTitle]
					,d.[PageSummary]
					,d.[TicketLink]
					,d.[IsTicketLinkDisplayed]
					,d.[ProductLink]
					,d.[IsProductLinkDisplayed]
					,i.[PK_EventGroupImageLocale]
					,i.[ImageTitle]
					,i.[ImageLocation]
					,STUFF((SELECT  ',' + CAST(PK_Event AS varchar(255))
						FROM EventGroupMembers WITH (NOLOCK)
						WHERE PK_EventGroup = eg.PK_EventGroup
						FOR XML PATH('')), 1, 1, '')
					AS EventList
					,eg.[IsPersistentGroup]
				FROM [dbo].[EventGroups] AS eg WITH (NOLOCK)
					LEFT JOIN [dbo].[EventGroupLocale] AS d WITH (NOLOCK) ON d.[PK_EventGroup] = eg.[PK_EventGroup]
						AND d.[PK_Locale] = eg.[PK_DefaultLocale]
					LEFT JOIN [dbo].[EventGroupImageLocale] AS i WITH (NOLOCK) ON i.[PK_EventGroup] = eg.[PK_EventGroup]
						AND i.[PK_Locale] = eg.[PK_DefaultLocale]
						AND i.[PK_EventImageType] = @BannerType
					INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = eg.[PK_DefaultLocale]
				WHERE (@FilterUnpublished = 0 OR eg.IsPublished = 1)
		)
		,cte_GroupLocale AS (
			SELECT
					egl.[PK_EventGroupLocale]
					,egl.[PK_EventGroup]
					,egl.[PK_Locale]
					,l.[LocaleCode]
					,egl.[EventGroupName]
					,egl.[EventGroupDesc]
					,egl.[PageTitle]
					,egl.[PageSummary]
					,egl.[TicketLink]
					,egl.[IsTicketLinkDisplayed]
					,egl.[ProductLink]
					,egl.[IsProductLinkDisplayed]
					,i.[PK_EventGroupImageLocale]
					,i.[ImageTitle]
					,i.[ImageLocation]
				FROM [dbo].[EventGroupLocale] AS egl WITH (NOLOCK)
					INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = egl.[PK_Locale]
					LEFT JOIN [dbo].[EventGroupImageLocale] AS i WITH (NOLOCK) ON i.[PK_EventGroup] = egl.[PK_EventGroup]
						AND i.[PK_Locale] = egl.[PK_Locale]
						AND i.[PK_EventImageType] = @BannerType
				WHERE (ISNULL(@LocaleCode, '') = '' OR l.[LocaleCode] = @LocaleCode)
		)
		SELECT
				d.PK_EventGroup
				,gl.[PK_EventGroupLocale]
				,gl.[PK_EventGroup]
				,ISNULL(gl.[PK_Locale], d.[PK_DefaultLocale]) AS PK_Locale
				,ISNULL(gl.[LocaleCode], d.[LocaleCode]) AS LocaleCode
				,ISNULL(gl.[EventGroupName], d.[EventGroupName]) AS [EventGroupName]
				,ISNULL(gl.[EventGroupDesc], d.[EventGroupDesc]) AS [EventGroupDesc]
				,ISNULL(gl.[PageTitle], d.[PageTitle]) AS [PageTitle]
				,ISNULL(gl.[PageSummary], d.[PageSummary]) AS [PageSummary]
				,ISNULL(gl.[TicketLink], d.[TicketLink]) AS [TicketLink]
				,ISNULL(gl.[IsTicketLinkDisplayed], d.[IsTicketLinkDisplayed]) AS [IsTicketLinkDisplayed]
				,ISNULL(gl.[ProductLink], d.[ProductLink]) AS [ProductLink]
				,ISNULL(gl.[IsProductLinkDisplayed], d.[IsProductLinkDisplayed]) AS [IsProductLinkDisplayed]
				,ISNULL(gl.[PK_EventGroupImageLocale], d.[PK_EventGroupImageLocale]) AS [PK_EventGroupImageLocale]
				,ISNULL(gl.[ImageTitle], d.[ImageTitle]) AS [ImageTitle]
				,ISNULL(gl.[ImageLocation], d.[ImageLocation]) AS [ImageLocation]
				,d.[EventList]
				,ISNULL(d.[IsPersistentGroup], 0) AS [IsPersistentGroup]
			FROM [cte_default] AS d
				LEFT JOIN cte_GroupLocale AS gl ON gl.[PK_EventGroup] = d.[PK_EventGroup]
			WHERE gl.[LocaleCode] = @LocaleCode;

		-----------------------------------------------------------------------------------------------------------------------
		-- Return attachments
		--
		SELECT
				u.[PK_EventGroupURL]
				,u.[PK_EventGroup]
				,u.[PK_Locale]
				,l.[LocaleCode]
				,u.[PK_EventURLType]
				,u.[EventGroupURL]
				,u.[EventGroupURLDesc]
				,u.[Flyer]
			FROM [dbo].[EventGroupURL] AS u WITH (NOLOCK)
				INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = u.[PK_Locale]
			WHERE (ISNULL(@LocaleCode, '') = '' OR l.[LocaleCode] = @LocaleCode);

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
