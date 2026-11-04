CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromoSaveStatus]
	-- Required
	@PK_Event		int

	-- Optional
	,@LocaleCode	varchar(5) = null
	,@LogoType		int = 1

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Get_PMPromoSaveStatus

	USE:			
					DECLARE @e int, @em varchar(4000)

					EXEC dbo.usp_EventsAT_Get_PMPromoSaveStatus
							@PK_Event = 4806
							--,@LocaleCode = 'en-PF'

							-- Errors
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]
					
	DESCRIPTION:	Gets the status of required elements on a promotion to verify if it is completed
						1- StartDate, EndDate must not be NULL
						2- There must be a PromotionName and PromotionTranslation
						3- There must be at least one team sublevel
						4- There must be a Thumbnail for the Promotion
						5- At least one Target Audience
						6- If the promo has qualifications, the Qual dates must be provided
	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventImage, dbo.EventDSTeamType

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-05-02		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.0.1		2019-10-17		alejandramed	SRE Compliance 
	2.0.2		2020-10-01		puertac			BUG 384680 Promotion with qualification created some time a go after edit translations display INCOMPLETED, not allow publish promotion
												Validate QualificationDates instead of DisplayDates
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY;
		WITH cte_image AS (
			SELECT eild.PK_Event, eild.PK_Locale, eild.EventImageLocation
				FROM EventImage AS ei WITH(NOLOCK)
					LEFT JOIN EventImageLocaleDesc AS eild WITH(NOLOCK) ON eild.PK_EventImage = ei.PK_EventImage
				WHERE ei.PK_EventImageType = 1
					AND ei.PK_Event = @PK_Event
		)
		SELECT	e.PK_Event
				,eld.PK_Locale
				,l.LocaleCode
				,CASE WHEN eld.PK_Locale = e.PK_DefaultLocale THEN 1 ELSE 0 END AS DefaultLocale
				,CASE WHEN e.dStartUTC IS NOT NULL AND e.dEndUTC IS NOT NULL AND [Location] IS NOT NULL THEN 1 ELSE 0 END AS EventDates		-- (1)
				,CASE WHEN eld.EventName IS NOT NULL AND eld.EventDesc IS NOT NULL THEN 1 ELSE 0 END AS NameDesc							-- (2)
				,ISNULL((SELECT COUNT(1) FROM EventDSTeamType WITH(NOLOCK) WHERE PK_Event = e.PK_Event), 0) AS TeamSubLevels								-- (3)
				,CASE WHEN c.EventImageLocation IS NOT NULL THEN 1 ELSE 0 END AS Thumbnail													-- (4)
				,(SELECT COUNT(1) FROM EventDistributorCountryLocales WITH(NOLOCK) WHERE PK_Event = e.PK_Event) AS TargetAudience						-- (5)
				,CASE WHEN [CanDisplayQualPeriod] = 1 THEN
					CASE WHEN QualPeriodStart IS NOT NULL AND QualPeriodEnd IS NOT NULL THEN 1		-- BUG 384680
					ELSE 0 END
				ELSE 1 END AS QualDates																										-- (6)
			FROM Event AS e WITH(NOLOCK)
				LEFT JOIN EventLocaleDesc  AS eld WITH(NOLOCK) ON eld.PK_Event = e.PK_Event
				INNER JOIN Locales AS l WITH(NOLOCK) ON l.PK_Locale = eld.PK_Locale
				LEFT JOIN cte_image AS c WITH(NOLOCK) ON c.PK_Locale = eld.PK_Locale
			WHERE e.PK_Event = @PK_Event
				AND (l.LocaleCode = @LocaleCode OR ISNULL(@LocaleCode, '') = '')


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