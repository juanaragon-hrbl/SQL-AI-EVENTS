CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_DSEventSubmittedList]
		--Mandatory Parameters
		 @DistributorID VARCHAR(10) = 'staff'
		,@LocaleCode CHAR(5) = 'es-MX'

		-- Optional
		,@IsActive bit = NULL

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_DSEventSubmittedList

USE:	        
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.usp_MyHLEventAPI_Get_DSEventSubmittedList
					    @DistributorID = 'staff'
						,@LocaleCode = 'es-MX'
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the Events and the statuses for events submitted by the associated DS

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.EventLocaleADesc, dbo.EventCoordinatorDetail, dbo.Event

VERSIONS
----------------------------------------------------------------------------------
1	2010-12-02	IniU			Intitial
1.1 2013-03-01  SandhyaP		Added HasAccess flag
2   2013-06-12  SushmaA		    Added Locales column
3	2015-02-12	SandhyaP		Recurring events changes
4	2017-11-15	RogelioR		Added @IsActive parameter to filter inactive events
5	2018-03-09	RogelioR		Add events on which DistributorId is coordinator, [HasRegistration] column
6	2018-05-24	RogelioR		Include Events where @DistributorID is owner or coordinator
7	2019-08-14	NoeG			Refactor code (SRE)
8	2021-06-02	ivanci			BUG 688529 - End date in Manage My Events display incorrect			
9	2023-05-30	puertac			BUG 1235097 - Display Event that is  not Distributor Event in Manage My Event
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

	BEGIN TRY
	

		SELECT @Error = 0, @ErrorMessage = '';

		/* DECLARE THE REQUIRED VARIABLES */

		DECLARE @PK_Locale int
				,@HasAccess int

		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode


		/* SELECT EVENT DETAILS FOR THE PASSED DS AND LOCALE */
		SELECT DISTINCT
				 E.[PK_Event] AS [EventID]
				,COALESCE(ED.[EventName], E.[EventName]) AS [EventName]
				,CASE WHEN E.[dStartUTC] = E.[dEndUTC] THEN CONVERT(VARCHAR, E.[dStartUTC], 107)   
					  ELSE CONVERT(VARCHAR, E.[dStartUTC], 107) + ' - ' + CONVERT(VARCHAR, E.[dEndUTC], 107) 
				END AS [EventDate]
				,E.[dStartUTC] AS [StartDate]
				,E.[dEndUTC] AS [EndDate]
				,COALESCE(ED.[EventCity], E.[EventCity], '') 
					+ CASE WHEN (COALESCE(ED.[EventCity], E.[EventCity]) IS NULL OR COALESCE(ED.[EventCity], E.[EventCity]) = '') THEN '' 
						ELSE ', ' 
					END  
					+ COALESCE(ED.[EventState], E.[EventState], '') 
					+ CASE WHEN (COALESCE(ED.[EventState], E.[EventState]) IS NULL OR COALESCE(ED.[EventState], E.[EventState])= '') THEN '' 
						ELSE ', ' 
					END 
					+ CC.[sCountryCodeISO] AS [Location]
                ,E.[Location] AS [TimeZone]				-- BUG 688529
				,E.[EventApprovalStatus] AS [Status]-- 0 = Under review; 1 = Approved; 2 = Rejected
				,E.[IsActive]
				,E.[IsPreRegistrationRequired]
				,CASE WHEN EDA.DistributorID = E.CreatedDistributorID THEN 1 ELSE 0 END HasAccess	
				,L.[Locales]
				,E.[PK_OldEventApp]
				,E.[IsRecurring]
				,E.[RecurrenceEndDate]
				,RT.[RecurrenceCode] AS [Repeat]
				,CASE WHEN E.[IsRecurring] = 0 AND E.[PK_OldEventApp] IS NULL THEN E.[dStartUTC]
					  WHEN E.[IsRecurring] = 1 AND E.[PK_OldEventApp] IS NULL THEN E.[dStartUTC]
					  WHEN E.[IsRecurring] = 0 AND E.[PK_OldEventApp] IS NOT NULL THEN EE.[dStartUTC] END AS [SortDate]
				,E.[IsPublish]
				,E.[ModifiedDateUTC]
				,ISNULL(
					NULLIF(RTRIM(LTRIM((SELECT TOP 1 [EventImageLocation] FROM [EventImage] WITH (NOLOCK) WHERE [PK_EventImageType] = 1 AND [PK_Event] = E.[PK_Event]))), '')
					,ESLD.[Image]
				) AS [Logo]
				,CASE WHEN EXISTS (SELECT 1 FROM [dbo].[SubEvent] WITH (NOLOCK) WHERE [PK_Event] = E.[PK_Event] AND GETUTCDATE() <= E.[dEndUTC]) THEN 1 ELSE 0 END AS [HasRegistration]
			FROM [dbo].[Event] E WITH (NOLOCK)
				INNER JOIN [dbo].[EventCountry] C WITH (NOLOCK) ON E.[PK_Event] = C.[PK_Event]
				INNER JOIN [dbo].[v_Countries] CC WITH (NOLOCK) ON C.[PK_Country] = CC.[nCountryID]
				LEFT JOIN (
						SELECT PIV.[LocaleCodeSub], PIV.[1] + (CASE WHEN PIV.[2] IS NOT NULL THEN ',' + PIV.[2] ELSE '' END) 
								+ (CASE WHEN PIV.[3] IS NOT NULL THEN ',' + PIV.[3] ELSE '' END)
								+ (CASE WHEN PIV.[4] IS NOT NULL THEN ',' + PIV.[4] ELSE '' END) 
								AS [Locales]
							FROM (
								SELECT 
										SUBSTRING(L.[LocaleCode], 4, 2) AS [LocaleCodeSub]	--, L.*
										,L.[LocaleCode]
										,ROW_NUMBER() OVER (PARTITION BY SUBSTRING(L.[LocaleCode], 4, 2) ORDER BY SUBSTRING(L.LocaleCode, 4, 2) )AS [row]
									FROM [dbo].[Locales] L WITH (NOLOCK)
							)S
							PIVOT(min(LocaleCode) FOR ROW in ([1], [2], [3], [4])) AS PIV
					)L ON CC.[sCountryCodeISO] = L.[LocaleCodeSub]
				LEFT JOIN [dbo].[EventLocaleDesc] ED WITH (NOLOCK) ON E.[PK_Event] = ED.[PK_Event]
					AND ED.[PK_Locale] = @PK_Locale
				LEFT JOIN [dbo].[EventLocaleDesc] ED1 WITH (NOLOCK) ON E.[PK_Event] = ED1.[PK_Event]
					AND ED.[PK_Locale] = E.[PK_DefaultLocale]
				INNER JOIN [dbo].[EventEventSubType] EES WITH (NOLOCK) ON E.[PK_Event] = EES.[PK_Event]	
				LEFT JOIN [dbo].[EventSubTypeLocaleDesc] ESLD WITH (NOLOCK) ON EES.[PK_EventSubType] = ESLD.[PK_EventSubType]
					AND ESLD.[PK_Locale] = E.[PK_DefaultLocale]
				LEFT JOIN [dbo].[EventDSAccess] EDA WITH (NOLOCK) ON EDA.[DistributorID] = E.[CreatedDistributorID]
					AND	EDA.[PK_EventSubTypeLocaleDesc] = ESLD.[PK_EventSubTypeLocaleDesc]
				LEFT JOIN [dbo].[EventCoordinatorDetail] AS ecd WITH (NOLOCK) ON ecd.[PK_Event] = E.[PK_Event]
					AND ecd.[CreatedDistributorID] = @DistributorID
				LEFT JOIN [dbo].[RecurrenceType] RT WITH (NOLOCK) ON RT.[PK_RecurrenceType] = E.[PK_RecurrenceType]
				LEFT JOIN [dbo].[Event] EE WITH (NOLOCK) ON E.[PK_OldEventApp] = EE.[PK_Event]
			WHERE E.[CreatedDistributorID] = @DistributorID
				AND	(E.[dStartUTC] >= GETUTCDATE()-731 OR E.[dStartUTC] IS NULL)
				AND	(@IsActive IS NULL OR E.[IsActive] = @IsActive)
				AND ((EDA.PK_Distributor IS NOT NULL) OR (ecd.[CreatedDistributorID] IS NOT NULL) OR (E.[CreatedDistributorID] = @DistributorID))
				AND E.PK_EventType = 3				-- BUG 1235097 - DS Events only
			ORDER BY
				[SortDate] DESC
				,[EventName] 
				,E.[PK_Event] ASC



		SELECT DISTINCT
				 E.[PK_Event] AS [EventID]
				,COALESCE(ED.[EventName], E.[EventName]) AS [EventName]
				,CASE WHEN E.[dStartUTC] = E.[dEndUTC] THEN CONVERT(VARCHAR, E.[dStartUTC], 107)   
					  ELSE CONVERT(VARCHAR, E.[dStartUTC], 107) + ' - ' + CONVERT(VARCHAR, E.[dEndUTC], 107) 
				END AS [EventDate]
				,E.[dStartUTC] AS [StartDate]
				,E.[dEndUTC] AS [EndDate]
				,COALESCE(ED.[EventCity], E.[EventCity],'') 
					+ CASE WHEN (COALESCE(ED.[EventCity], E.[EventCity]) IS NULL OR COALESCE(ED.[EventCity], E.[EventCity]) = '') THEN '' 
						ELSE ', ' 
					END  
					+ COALESCE(ED.[EventState], E.[EventState],'') 
					+ CASE WHEN (COALESCE(ED.[EventState], E.[EventState]) IS NULL OR COALESCE(ED.[EventState], E.[EventState])= '') THEN '' 
						ELSE ', ' 
					END 
					+ CC.[sCountryCodeISO] AS [Location]
                ,E.[Location] AS [TimeZone]				-- BUG 688529
				,E.[EventApprovalStatus] AS [Status]-- 0 = Under review; 1 = Approved; 2 = Rejected
				,E.[IsActive]
				,E.[IsPreRegistrationRequired]
				,CASE WHEN EDA.DistributorID = E.CreatedDistributorID THEN 1 ELSE 0 END HasAccess	
				,L.[Locales]
				,E.[PK_OldEventApp]
				,E.[IsRecurring]
				,E.[RecurrenceEndDate]
				,RT.[RecurrenceCode] AS [Repeat]
				,CASE WHEN E.[IsRecurring] = 0 AND E.[PK_OldEventApp] IS NULL THEN E.[dStartUTC]
					  WHEN E.[IsRecurring] = 1 AND E.[PK_OldEventApp] IS NULL THEN E.[dStartUTC]
					  WHEN E.[IsRecurring] = 0 AND E.[PK_OldEventApp] IS NOT NULL THEN EE.[dStartUTC] END AS [SortDate]
				,E.[IsPublish]
				,E.[ModifiedDateUTC]
				,ISNULL(
					NULLIF(RTRIM(LTRIM((SELECT TOP 1 [EventImageLocation] FROM [EventImage] WITH (NOLOCK) WHERE [PK_EventImageType] = 1 AND [PK_Event] = E.[PK_Event]))), '')
					,ESLD.[Image]
				) AS [Logo]
				,CASE WHEN EXISTS (SELECT 1 FROM [dbo].[SubEvent] WITH (NOLOCK) WHERE [PK_Event] = E.[PK_Event] AND GETUTCDATE() <= E.[dEndUTC]) THEN 1 ELSE 0 END AS [HasRegistration]
			FROM [dbo].[Event] E WITH (NOLOCK)
				INNER JOIN [dbo].[EventCountry] C WITH (NOLOCK) ON E.[PK_Event] = C.[PK_Event]
				INNER JOIN [dbo].[v_Countries] CC WITH (NOLOCK) ON C.[PK_Country] = CC.[nCountryID]
				LEFT JOIN (
						SELECT PIV.[LocaleCodeSub], PIV.[1] + (CASE WHEN PIV.[2] IS NOT NULL THEN ',' + PIV.[2] ELSE '' END) 
								+ (CASE WHEN PIV.[3] IS NOT NULL THEN ',' + PIV.[3] ELSE '' END)
								+ (CASE WHEN PIV.[4] IS NOT NULL THEN ',' + PIV.[4] ELSE '' END) 
								AS [Locales]
							FROM (
								SELECT 
										SUBSTRING(L.[LocaleCode], 4, 2) AS [LocaleCodeSub]	--, L.*
										,L.[LocaleCode]
										,ROW_NUMBER() OVER (PARTITION BY SUBSTRING(L.[LocaleCode], 4, 2) ORDER BY SUBSTRING(L.LocaleCode, 4, 2) )AS [row]
									FROM [dbo].[Locales] L WITH (NOLOCK)
							)S
							PIVOT(min(LocaleCode) FOR ROW in ([1], [2], [3], [4])) AS PIV
					)L ON CC.[sCountryCodeISO] = L.[LocaleCodeSub]
				LEFT JOIN [dbo].[EventLocaleDesc] ED WITH (NOLOCK) ON E.[PK_Event] = ED.[PK_Event]
					AND ED.[PK_Locale] = @PK_Locale
				LEFT JOIN [dbo].[EventLocaleDesc] ED1 WITH (NOLOCK) ON E.[PK_Event] = ED1.[PK_Event]
					AND ED.[PK_Locale] = E.[PK_DefaultLocale]
				INNER JOIN [dbo].[EventEventSubType] EES WITH (NOLOCK) ON E.[PK_Event] = EES.[PK_Event]	
				INNER JOIN [dbo].[EventSubTypeLocaleDesc] ESLD WITH (NOLOCK) ON EES.[PK_EventSubType] = ESLD.[PK_EventSubType]	
					AND ESLD.[PK_Locale] = E.[PK_DefaultLocale]
				LEFT JOIN [dbo].[EventDSAccess] EDA WITH (NOLOCK) ON EDA.[DistributorID] = E.[CreatedDistributorID]	
					AND	EDA.[PK_EventSubTypeLocaleDesc] = ESLD.[PK_EventSubTypeLocaleDesc]	
				LEFT JOIN [dbo].[RecurrenceType] RT WITH (NOLOCK) ON RT.[PK_RecurrenceType] = E.[PK_RecurrenceType]
				LEFT JOIN [dbo].[Event]  EE WITH (NOLOCK) ON E.[PK_OldEventApp] = EE.[PK_Event]
			WHERE E.[CreatedDistributorID] != @DistributorID
				AND E.[PK_Event] IN (SELECT [PK_Event] FROM [dbo].[EventCoordinatorDetail] WITH (NOLOCK) WHERE [CreatedDistributorID] = @DistributorID)
				AND	(@IsActive IS NULL OR E.[IsActive] = @IsActive)
				AND (E.[EventApprovalStatus] = 1)
				AND E.[dEndUTC] >= GETUTCDATE()
				AND E.[IsPublish] = 1
				AND E.PK_EventType = 3				-- BUG 1235097 - DS Events only
			ORDER BY
				[SortDate] DESC
				,[EventName] 
				,E.[PK_Event] ASC


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

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;