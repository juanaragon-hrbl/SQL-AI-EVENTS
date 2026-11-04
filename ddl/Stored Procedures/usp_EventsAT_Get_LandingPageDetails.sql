CREATE PROCEDURE [dbo].[usp_EventsAT_Get_LandingPageDetails]
		 @Title		VARCHAR(50) = NULL
        ,@TitleID	INT = NULL
		,@Locale	VARCHAR(5) = NULL
		
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/*
OBJECT:			dbo.usp_EventsAT_Get_LandingPageDetails

USE:	
		DECLARE @e int, @em varchar(4000)
	
		EXEC usp_EventsAT_Get_LandingPageDetails
					@Title = NULL
					,@TitleID = 29
					--,@Locale = 'es-US'
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
1	2015-10-14			SandhyaP			Initial
2	2018-09-18			RogelioR			Added [IsPersistentGroup] to result set
2	2019-08-08			OrlandoL			Refactor code (SRE)
3	2019-10-15			alejandramed		SRE Compliance 

*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @CurrDate datetime
DECLARE @PK_EventGroupType INT = 2
DECLARE @PK_Locale INT
DECLARE @PK_EventImageType INT

SELECT @Error = 0, @ErrorMessage = '';
SET @CurrDate = GETUTCDATE()


/* GET PK_Locale */
IF @Locale IS NULL
       SELECT @PK_Locale = PK_DefaultLocale FROM dbo.[EventGroups] WITH (NOLOCK) WHERE PK_EventGroup = @TitleID  OR EventGroupName = @Title
ELSE
	   SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @Locale

--SELECT @PK_Locale =
--Case WHEN MAX(CASE WHEN @PK_Locale = A.PK_Locale THEN  1 ELSE 0 END) = 1 THEN @PK_Locale ELSE NULL END
--FROM  
--(
--SELECT PK_DefaultLocale AS PK_Locale
--FROM dbo.EventGroups WITH (NOLOCK)
--WHERE PK_EventGroup = 4
--UNION 
--SELECT PK_Locale
--FROM DBO.EventGroupLocale WITH (NOLOCK)
--WHERE PK_EventGroup = 4
--)A
 
/* Validate Title is already in use */
IF @TitleID IS NULL AND NOT EXISTS (SELECT 1 FROM dbo.EventGroups WITH (NOLOCK) WHERE EventGroupName = @Title)
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

		-- Get the Landing Page Title/Summary

		SELECT EG.[PK_EventGroup]
			   ,COALESCE(EGL.[EventGroupName], EG.[EventGroupName]) AS [EventGroupName]
			   ,COALESCE(EGL.[EventGroupDesc], EG.[EventGroupDesc]) AS [EventGroupDesc]
			   ,EG.[PK_DefaultLocale]
			   ,LO.LocaleCode AS [DefaultLocale]
			   ,@PK_Locale AS [PK_Locale]
			   ,@Locale AS [Locale]
			   ,COALESCE(EGL.CreatedDateUTC, EG.CreatedDateUTC) CreatedDateUTC
			   ,COALESCE(EGL.CreatedBy, EG.CreatedBy) CreatedBy
			   ,COALESCE(EGL.ModifiedDateUTC, EG.ModifiedDateUTC) ModifiedDateUTC
			   ,COALESCE(EGL.ModifiedBy, EG.ModifiedBy) ModifiedBy
			   ,EG.[CreatedDateUTC] AS [LandingPageCreatedDateUTC]
			   ,EGL.[PageTitle]
			   ,EGL.[PageSummary]
			   ,EGL.[TicketLink]
			   ,EGL.[IsTicketLinkDisplayed]
			   ,EGL.[ProductLink]
			   ,EGL.[IsProductLinkDisplayed]
			   ,EG.[IsPublished]
			   ,EG.[IsPersistentGroup]
		FROM 
		dbo.[EventGroups]  EG WITH (NOLOCK)
		LEFT JOIN 
		dbo.[EventGroupLocale]  EGL WITH (NOLOCK)
		ON EG.[PK_EventGroup] = EGL.[PK_EventGroup]
		AND
		EGL.[PK_Locale] = @PK_Locale
		LEFT JOIN
		dbo.[Locales]  L WITH (NOLOCK)
		ON EGL.[PK_Locale] = L.[PK_Locale]
		LEFT JOIN
		dbo.[Locales]  LO WITH (NOLOCK)
		ON EG.[PK_DefaultLocale] = LO.[PK_Locale]
		WHERE
			(EG.[PK_EventGroup] = @TitleID OR EG.[EventGroupName] = @Title)

			

		-- Get the Events selected

		SELECT EG.[PK_EventGroup], 
			   EGM.[PK_Event],
			   EGM.[CreatedDateUTC],
			   EGM.[CreatedBy],
			   EGM.[ModifiedDateUTC],
			   EGM.[ModifiedBy],
			   E.[EventName],
			   '' AS [EventSummary],--COALESCE(ED.EventSummary, '') EventSummary,
			   '' AS [EventDesc],--COALESCE(ED.EventDesc, '') EventDesc,
			   '' AS [EventRules],--COALESCE(ED.EventRules,'') EventRules,
			   E.[dStartUTC] AS [StartDate],
			   E.[dEndUTC] AS [EndDate],
			   E.[EventVenueName],
			   E.[Location],
			   E.[EventAddress],
			   E.[EventCity],
			   E.[EventState],
			   E.[EventZipCode],
			   C.[sCountryName] AS [Country],
			   '' AS [EventDisplayAddress],--COALESCE(ED.EventDisplayAddress, '') EventDisplayAddress,
			   EI.[EventImageLocation] AS [EventLogo],
			  CASE WHEN (CASE WHEN E.[PK_EventType] = 3 AND (E.[IsActive] = 0 OR E.[DisplayEndDate] < CONVERT(DATE,GETUTCDATE(), 110) OR E.[dEndUTC] < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
			  WHEN E.[PK_EventType] = 3 AND E.[EventApprovalStatus] = 0 THEN 0
			  WHEN E.[PK_EventType] = 3 AND E.[EventApprovalStatus] = 1 THEN 1
			  WHEN E.[PK_EventType] = 3 AND E.[EventApprovalStatus] = 2 THEN 2
			  WHEN E.[PK_EventType] = 3 AND E.[EventApprovalStatus] = 3 THEN 3
			  WHEN E.[PK_EventType] IN (1,2) AND E.[IsPublish] = 1 AND E.[DisplayEndDate] >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4
			  WHEN E.[PK_EventType] IN (1,2) AND (E.[IsPublish] = 0 OR E.[DisplayEndDate] < CONVERT(DATE,GETUTCDATE(), 110) OR E.[dEndUTC] < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
			  END) IN (1,4) AND (CONVERT(DATE,GETUTCDATE(), 110) >= E.DisplayStartDate AND CONVERT(DATE,GETUTCDATE(), 110) <= E.[DisplayEndDate]) THEN 1 ELSE 0 END AS [CanDisplayEvent],
			  CASE WHEN E.[PK_Event] = EL.[PK_Event] THEN 1 ELSE 0 END AS [IsEventAudience],
			  E.[MakePublic],
			  E.[CanPurchaseTicketOnline],
			  E.[IsTicketforQualifiedDS] AS [TicketPurchaseforQualifiedDSOnly],
			  E.[IsQualifytoPurchaseTickets],
			  E.[TicketThirdPartyLink] AS [IsThirdPartyTicketPurchaseLink],
			  EUL.[EventURL] AS [TicketsThirdPartyLink],
			  CASE WHEN EXISTS (SELECT 1 FROM dbo.[EventGuestSpeakers] AS EGS WITH (NOLOCK) WHERE EGM.[PK_Event] = EGS.[PK_Event]) THEN 1 ELSE 0 END AS [HasGuestSpeakers]
		FROM 
		dbo.[EventGroups]   EG WITH (NOLOCK)
		INNER JOIN
		dbo.[EventGroupMembers] EGM WITH (NOLOCK)
		ON
			EG.[PK_EventGroup] = EGM.[PK_EventGroup]
		INNER JOIN 
		dbo.[Event] E WITH (NOLOCK)
		ON
			E.[PK_Event] = EGM.[PK_Event]
		--INNER JOIN
		--	dbo.EventLocaleDesc ED WITH (NOLOCK)
		--ON
		--	E.PK_Event = ED.PK_Event
		--	AND 
		--	ED.PK_Locale = @PK_Locale
		LEFT JOIN
		dbo.[EventCountry] EC WITH (NOLOCK)
		ON
			E.[PK_Event] = EC.[PK_Event]
		LEFT JOIN
		dbo.[v_Countries] AS C WITH (NOLOCK)
		ON
			EC.[PK_Country] = [nCountryID]
		LEFT JOIN
		dbo.[EventImage] EI WITH (NOLOCK)
		ON
			E.[PK_Event] = EI.[PK_Event]
			AND
			EI.[PK_EventImageType] = 1
		LEFT JOIN
		(SELECT DISTINCT EM.[PK_Event]
		 FROM dbo.[EventDistributorCountryLocales] EDL WITH (NOLOCK)
		 INNER JOIN 
			  dbo.[EventGroupMembers] EM WITH (NOLOCK) 
		 ON
			EM.[PK_Event] = EDL.[PK_Event]
			AND

			EDL.[PK_Locale] = @PK_Locale) EL
		ON
			EL.[PK_Event] = E.[PK_Event]
		LEFT JOIN
		dbo.[EventURL]  EUL WITH (NOLOCK)
		ON
			E.[PK_Event] = EUL.[PK_Event]
		AND 
			EUL.[PK_EventURLType] = 5 -- for tickets third party link
		AND
			EUL.[PK_Locale] = @PK_Locale
		WHERE
			(EG.[PK_EventGroup] = @TitleID OR EG.[EventGroupName] = @Title)
		ORDER BY 
			E.[dStartUTC], E.[Location]


		-- Get the Logo/Banner selected

		SELECT DISTINCT COALESCE(EGI.PK_EventGroupImageLocale, EGIL.PK_EventGroupImageLocale) PK_EventGroupImageLocale,
			   EG.PK_EventGroup, 
			   COALESCE(EGI.PK_Locale, EGIL.PK_Locale) PK_Locale,
			   COALESCE(L.Localecode, LO.LocaleCode) Locale,
			   COALESCE(EGI.PK_EventImageType, EGIL.PK_EventImageType) PK_EventImageType,
			   EI.EventImageType,
			   COALESCE(EGI.ImageTitle, EGIL.ImageTitle) ImageTitle,
			   COALESCE(EGI.ImageLocation,  EGIL.ImageLocation) ImageLocation,
			   COALESCE(EGI.CreatedDateUTC, EGIL.CreatedDateUTC) CreatedDateUTC,
			   COALESCE(EGI.CreatedBy, EGIL.CreatedBy) CreatedBy,
			   COALESCE(EGI.ModifiedDateUTC, EGIL.ModifiedDateUTC) ModifiedDateUTC,
			   COALESCE(EGI.ModifiedBy, EGIL.ModifiedBy) ModifiedBy
		FROM 
		dbo.EventGroups  EG WITH (NOLOCK)
		LEFT JOIN
		dbo.EventGroupImageLocale EGI WITH (NOLOCK)
		ON
			EG.PK_EventGroup = EGI.PK_EventGroup
			AND
			EGI.PK_Locale = @PK_Locale 
		LEFT JOIN
		dbo.EventGroupImageLocale EGIL WITH (NOLOCK)
		ON
			EG.PK_EventGroup = EGIL.PK_EventGroup
			AND
			EGIL.PK_Locale = EG.PK_DefaultLocale
		LEFT JOIN
		dbo.Locales L WITH (NOLOCK)
		ON 
			EGI.PK_Locale = L.PK_Locale
		LEFT JOIN
		dbo.Locales LO WITH (NOLOCK)
		ON 
			EGIL.PK_Locale = LO.PK_Locale
		INNER JOIN
		dbo.EventImageType  EI WITH (NOLOCK)
		ON
			COALESCE(EGI.PK_EventImageType, EGIL.PK_EventImageType)  = EI.PK_EventImageType
		WHERE
			(EG.PK_EventGroup = @TitleID OR EG.EventGroupName = @Title)

		-- Get the translated locales

		SELECT EG.PK_DefaultLocale As PK_Locale
			   ,L.LocaleCode
			   ,L.LanguageCountryRegion 
			   ,1 As IsDefault 
		FROM 
		dbo.EventGroups EG WITH (NOLOCK)
		INNER JOIN
		dbo.Locales  L WITH (NOLOCK)
		ON EG.PK_DefaultLocale = L.PK_Locale
		WHERE
			(EG.PK_EventGroup = @TitleID OR EG.EventGroupName = @Title)
		UNION
		SELECT EGL.PK_Locale 
			   ,L.LocaleCode
			   ,L.LanguageCountryRegion 
			   ,0 As IsDefault
		FROM 
		dbo.EventGroups EG WITH (NOLOCK)
		INNER JOIN 
		dbo.EventGroupLocale  EGL WITH (NOLOCK)
		ON	EG.PK_EventGroup = EGL.PK_EventGroup
		INNER JOIN
		dbo.Locales  L WITH (NOLOCK)
		ON EGL.PK_Locale = L.PK_Locale
		AND EG.PK_DefaultLocale <> L.PK_Locale
		WHERE
			(EG.PK_EventGroup = @TitleID OR EG.EventGroupName = @Title)
		ORDER BY 4 Desc

		
		----------------------------------------------------------------------------
		-- Get links from EventURL
		--
		SELECT
				egu.[PK_EventGroupURL]
				,egu.[PK_EventGroup]
				,egu.[PK_Locale]
				,egu.[EventGroupURL]
				,egu.[EventGroupURLDesc]
				,egu.[Flyer]
				,egu.[ModifiedDateUTC]
			FROM [dbo].[EventGroups] AS eg WITH (NOLOCK)
				INNER JOIN [dbo].[EventGroupURL] AS egu WITH (NOLOCK) ON eg.[PK_EventGroup] = egu.[PK_EventGroup]
				INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = egu.[PK_Locale]
					AND l.[PK_Locale] = @PK_Locale
			WHERE (eg.[PK_EventGroup] = @TitleID OR eg.[EventGroupName] = @Title)
				
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

