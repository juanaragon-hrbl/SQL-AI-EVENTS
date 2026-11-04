CREATE PROCEDURE [dbo].[usp_EventPromo_Details]
    -- Mandatory parameters
    @PK_Event   INT =61931

    -- Optional Parameters
    ,@DistributorID VARCHAR(10) = NULL
    ,@LocaleCode    CHAR(5) = 'EN-US'

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
OBJECT:         [dbo].[usp_EventPromo_Details]

USE:
                DECLARE @e int, @em varchar(max)

                 EXEC [dbo].[usp_EventPromo_Details]
                        --@DistributorID = N'2222222222'
                        @PK_Event = 23560
                        ,@LocaleCode = 'en-US'
                        ,@IsDevQA = 0
                        ,@Error = @e OUTPUT
                        ,@ErrorMessage = @em OUTPUT

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:    This is a custom stored procedure that retreievs all the details for the
                NAM DAP 2018
NOTES:

DEPENDENCIES
----------------------------------------------------------------------------------
[dbo].[Event], [dbo].[Subevent], [dbo].[EventLocaleADesc], [dbo].[SubeventLocaleDesc],
[LS_SQL_BI_DB02].[EventManagement].[dbo].[v_AGGFQS_ID]

VERSIONS
----------------------------------------------------------------------------------
1.0.0   2018-02-23  OrlandoL
1.1.0   2018-08-17  RogelioR		Added error handling and @PK_Event is now optional
1.1.1   2010-02-01  GustavoGra		Added Event Promo template columns
1.1.2   2019-02-07  GustavoGra		Added MakePublic column.
1.1.3	2019-10-10	alejandramed	SRE Compliance
1.1.4   2020-10-12  alejandramed    Setting default values on EventSummary and EventDesc for PM Promotions
1.1.5   2020-11-06  GustavoGra		Including TimeZone
1.1.6	2022-02-22	ivanci		    Adding HideDates flag from dbo.EventExtn
1.1.7	2022-04-12	puertac			US 1003446 : Adding HasAutomatedQuals flag  + TemplateType fix
1.1.8	2023-05-20	ivanci	        US 1260167 - Admin tool - Display DS team levels  - Capability to publish/unpublish DS levels on Events
1.1.9	2023-05-26	puertac			BUG 1239248 - Prod - Promotion Templates - Issue with Banner
1.1.10	2023-07-13	ivanci			US 1275783 - Events Admin - Testing Tracker Feature
1.2.0	2023-10-03	puertac			Add Qualification Dates
******************************************************************************/
    SET ANSI_NULLS ON
    SET QUOTED_IDENTIFIER ON
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    --Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

	SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

    /* DECLARE THE REQUIRED VARIABLES */
    DECLARE @StartDate SMALLDATETIME = GETUTCDATE()
    DECLARE @CurrDate DATETIME = DATEADD(mm, DATEDIFF(mm, 0, GETUTCDATE()), 0)
    DECLARE @PeriodDate DATETIME = DATEADD(m, -11, @CurrDate)
    DECLARE @PK_Distributor INT
    DECLARE @PK_Locale INT = (SELECT [PK_Locale] FROM [dbo].[Locales]  WITH (NOLOCK) WHERE [LocaleCode] = @LocaleCode)
    DECLARE @PK_DefaultLocale INT = (SELECT [PK_DefaultLocale] FROM [dbo].[Event]  WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
    DECLARE @CountryCode CHAR(2) = SUBSTRING(@LocaleCode, 4, 2)
    DECLARE @CreatedDSID VARCHAR(10)
    DECLARE @StartLevelID INT = NULL 					-- T295644  Start team level infromation 
	   ,@StartTeamLevelName nvarchar (100) = NULL   -- T295644  Start team level infromation	+   US 585152 Level Translation
	   ,@StartTeamNameCode	varchar (5) = NULL	    -- T295644  Start team level infromation 
	   ,@StartTeamTypeIsSP	BIT = NULL			    -- T295644  Start team level infromation 

        -- Get distributor details
        SELECT
                @PK_Distributor = VD.[nDistributorID]
            FROM [dbo].[v_Distributor] AS VD
                INNER JOIN [PubEvents]..[dimDSSubType] AS DST WITH (NOLOCK) ON DST.[SubTypeCode] = VD.[sSubTeam]
            WHERE [sDistributorID] = @DistributorID;
        ;

        -- Distributor that created the event
        SELECT
                @CreatedDSID = [CreatedDistributorID]
            FROM [dbo].[Event] WITH (NOLOCK)
            WHERE [PK_Event] = @PK_Event
                AND [CreatedDistributorID] = @DistributorID;
        ;

        -- Show main variables
        IF @IsDevQA = 1
            SELECT
                    @PK_Locale AS [PK_Locale]
                    ,@PK_DefaultLocale AS [PK_DefaultLocale]
                    ,@CountryCode AS [CountryCode]
                    ,@StartDate AS [StartDate]
                    ,@CurrDate AS [CurrDate]
                    ,@PeriodDate AS [PeriodDate];

        /* CUSTOM TRACKING CODE */
        DECLARE @CustomCode NVARCHAR(MAX) = ISNULL(
            (SELECT CustomTrackingCode FROM EventLocaleDesc  WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_locale),
            (SELECT CustomTrackingCode FROM EventLocaleDesc  WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale)
        );

        /**************************************************************************
        T295644  Start team level name, Code and Type 
        ***************************************************************************/	

		SELECT @StartLevelID = MAX(TT.TeamOrder) 
		FROM EventDSTeamType ETT  WITH (NOLOCK) 
		INNER JOIN dbo.DSTeamType TT WITH (NOLOCK)
			ON  ETT.DSTeamTypeCode = TT.DSTeamTypeCode
		INNER JOIN PubEvents.dbo.dimDSSubType ST WITH (NOLOCK) 
				ON TT.DSTeamTypeCode = ST.SubTypeCode
		WHERE ST.TYPECODE IN ('SP','DS')
		AND TT.PK_DSTeamType <= 38		-- Where regular DS teams IDs end (PK_DSTeamType from dbo.DSTeamType)
		AND ETT.PK_Event = @PK_Event
	
		SELECT   @StartTeamLevelName =  ISNULL(DTL.DSTeamTypeDesc,ST.SubTypeDesc)	--US 585152 Level Translation					
				,@StartTeamNameCode  =  DT.DSTeamTypeCode			
				,@StartTeamTypeIsSP	 =  CASE WHEN ST.TYPECODE = 'SP' THEN 1 ELSE 0 END 
		FROM  DSTeamType DT WITH (NOLOCK) 
		INNER JOIN PubEvents.dbo.dimDSSubType ST WITH (NOLOCK) 
			ON DT.DSTeamTypeCode = ST.SubTypeCode
			AND DT.PK_DSTeamType <= 38				-- Where regular DS teams IDs end (PK_DSTeamType from dbo.DSTeamType)
		LEFT JOIN DSTeamTypeLocaleDesc DTL WITH (NOLOCK)		--US 585152 Level Translation
			ON DT.DSTeamTypeCode = DTL.DSTeamTypeCode
			AND DTL.PK_Locale = @PK_Locale
		WHERE DT.TeamOrder = @StartLevelID;

        /* SELECT EVENT DETAILS FOR THE PASSED PK_EVENT */
		DROP TABLE IF EXISTS #Images							-- 1.1.9  BUG 1239248

        SELECT  ISNULL(LOC.[EventImageLocation], DEF.[EventImageLocation]) AS [EventImageLocation]																									 
			,ei.[PK_EventImageType]
			,IIF(LOC.[EventImageLocation] IS NOT NULL,LOC.[PK_Locale], DEF.[PK_Locale]) AS [PK_Locale]
			,LOC.[EventImageLocation] AS LOC
			,DEF.[EventImageLocation] AS DEF
		INTO #Images
		FROM [dbo].[EventImage] AS ei WITH (NOLOCK)
		LEFT JOIN [EventImageLocaleDesc] AS LOC WITH (NOLOCK) 
			ON ei.[PK_EventImage] = LOC.[PK_EventImage]
			AND LOC.PK_Locale = @PK_Locale
		LEFT JOIN [EventImageLocaleDesc] AS DEF WITH (NOLOCK) 
			ON ei.[PK_EventImage] = DEF.[PK_EventImage]
			AND DEF.PK_Locale = @PK_DefaultLocale
		WHERE ei.[PK_Event] = @PK_Event
		AND [PK_EventImageType] IN (1,2)
		
		
        SELECT   e.[PK_Event] AS [EventID]
                ,e.[PK_EventType]
                ,ISNULL(ED.[EventName], (SELECT DISTINCT [EventName] FROM [dbo].[EventLocaleDesc] WITH (NOLOCK) WHERE [PK_Locale] = @PK_DefaultLocale AND [PK_Event] = @PK_Event)) AS [EventName]
                ,e.[dStartUTC] AS [EventStartDate]
                ,e.[dEndUTC] AS [EventEndDate]
                ,e.[DisplayStartDate]
                ,e.[DisplayEndDate]
				,e.QualPeriodStart						-- 1.2.0
				,e.QualPeriodEnd						-- 1.2.0
                ,(SELECT [EventImageLocation] FROM #Images WHERE [PK_EventImageType] = 1 ) AS [Logo]				-- 1.1.9  BUG 1239248
                ,(SELECT [EventImageLocation] FROM #Images WHERE [PK_EventImageType] = 2 ) AS [Banner]				-- 1.1.9  BUG 1239248
                , CASE
					WHEN e.[PK_EventType] = 15 THEN ISNULL(ED.EventDesc,(SELECT DISTINCT EventDesc FROM [dbo].EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale))
					ELSE ISNULL(ED.EventSummary, (SELECT DISTINCT EventSummary FROM [dbo].EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale))
				END AS [EventSummary]
				, CASE
					WHEN e.[PK_EventType] = 15 THEN (SELECT eu.[EventURLDesc] FROM [dbo].[EventURL] AS eu WITH (NOLOCK) WHERE eu.[PK_Event] = @PK_Event AND eu.[PK_Locale] = ISNULL(@PK_Locale, @PK_DefaultLocale) AND eu.[PK_EventURLType] = 13)
					ELSE ISNULL(ED.EventDesc,(SELECT DISTINCT EventDesc FROM [dbo].EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale)) 
					END AS [EventDesc]
                ,ISNULL(ED.EventRules,(SELECT Distinct EventRules FROM [dbo].EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale)) As [EventRules]
                ,e.[IsActive]
                ,e.[IsPublish]
				,e.[MakePublic]
                ,IIF(ept.[PK_EventPromoTemplateType] IS NOT NULL, ept.[PK_EventPromoTemplateType] , S.EventPromoTemplateID ) AS PK_EventPromoTemplateType		-- 1.1.7
                ,IIF(ept.[PK_EventPromoTemplateType] IS NOT NULL, eptt.[EventPromoTemplateType]	  , ST.EventPromoTemplateType) AS EventPromoTemplateType		-- 1.1.7
                ,ED.ParticipatingCountries AS [AchievementListText]
                ,ED.TicketRules AS [TrackProgressText]
				 ,(
                    CASE WHEN e.[PK_EventType] IN (15, 3) 
                    THEN e.[Location] -- Both PM Promotion (15) and DS Events (3) use Location to store the TimeZone
                    ELSE ex.[TimeZoneDesc] END -- the rest of types of Events & Promotions use TimeZonDesc from Event Extn
                ) AS [TimeZone]
                ,ISNULL(EX.DisplayDates, 1) as DisplayDates
				,CAST(IIF(S.PK_Event IS NOT NULL , 1, 0) AS BIT) AS HasAutomatedQuals						-- US 1003446
                ,@StartTeamLevelName  AS StartTeamLevelName                      -- T295644  Start team level infromation 
	            ,@StartTeamNameCode   AS StartTeamNameCode 					  -- T295644  Start team level infromation 
	            ,@StartTeamTypeIsSP   AS StartTeamTypeIsSP						  -- T295644  Start team level infromation 
                ,ISNULL(EX.HideTeamLevelInfo, 0) as HideTeamLevelInfo
                ,ISNULL(EX.EnableTesting, 0) as EnableTesting
            FROM [dbo].[Event] AS e WITH (NOLOCK)
                INNER JOIN [dbo].[EventType] AS ET WITH (NOLOCK) ON e.[PK_EventType] = ET.[PK_EventType]
                LEFT JOIN [dbo].[EventExtn] AS EX WITH (NOLOCK) ON e.[PK_Event] = EX.[PK_Event]
				LEFT JOIN [dbo].[EventLocaleDesc] AS ED WITH (NOLOCK) ON e.[PK_Event] = ED.[PK_Event]
                    AND (ED.[PK_Locale] = ISNULL(@PK_Locale, @PK_DefaultLocale))
                LEFT JOIN [dbo].[EventPromoTemplate] AS ept WITH (NOLOCK) ON ept.[PK_Event] = E.[PK_Event]
                LEFT JOIN [dbo].[EventPromoTemplateType] AS eptt WITH (NOLOCK) ON eptt.[PK_EventPromoTemplateType] = ept.[PK_EventPromoTemplateType]
           LEFT JOIN [eventpromo].[Settings] S WITH (NOLOCK)											-- US 1003446
				ON e.PK_Event = S.PK_Event							
		   LEFT JOIN [dbo].[EventPromoTemplateType] AS ST  WITH (NOLOCK)								-- 1.1.7
				ON ST.PK_EventPromoTemplateType = S.EventPromoTemplateID
            WHERE e.[PK_Event] = @PK_Event
        ;

        /* AUDIENCES */
        SELECT
                l.[LocaleCode],l.LanguageCountryRegion
            FROM [dbo].[EventDistributorCountryLocales] AS e WITH (NOLOCK)
                INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = e.[PK_Locale]
                WHERE PK_Event = @PK_Event
        ;

        /* ATTACHMENTs */
        SELECT
                eu.[PK_EventURL]
                ,eu.[PK_Event]
                ,eu.[PK_Locale]
                ,l.[LocaleCode]
                ,eu.[EventURL]
                ,eu.[EventURLDesc]
                ,eu.[Flyer]
                ,eu.[PK_EventURLType]
                ,eut.[EventURLType]
            FROM [dbo].[EventURL] AS eu WITH (NOLOCK)
                INNER JOIN [dbo].[EventURLType] AS eut WITH (NOLOCK) ON eut.PK_EventURLType = eu.PK_EventURLType
                INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.PK_Locale = eu.PK_Locale
            WHERE eu.[PK_Event] = @PK_Event
                AND eu.[PK_Locale] = ISNULL(@PK_Locale, @PK_DefaultLocale)
                AND (eu.[PK_EventURLType] != 9 AND eu.[PK_EventURLType] != 13);

        ;

        /* VIDEOS */
        SELECT
                EA.PK_EventAudio
                ,EA.PK_Event
                ,EAL.AudioName
                ,EAL.AudioDesc
                ,EAL.AudioHTML
                ,MT.[MediaTypeDesc] MediaType
            FROM [dbo].[EventAudio] EA WITH (NOLOCK)
            INNER JOIN [dbo].[MediaType] MT WITH (NOLOCK) ON EA.PK_MediaType = MT.PK_MediaType
            LEFT JOIN [dbo].EventAudioLocaleDesc EAL WITH (NOLOCK) ON EA.PK_Event = EAL.PK_Event
                AND EA.PK_EventAudio = EAL.PK_EventAudio
                AND EAL.PK_Locale = @PK_Locale
            WHERE EA.PK_Event = @PK_Event
                AND ISNULL(EAL.AudioHTML, '') <> ''
        ;

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
END;