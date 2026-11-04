CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromotion]
    -- REQUIRED
    @PK_Event            int = NULL
 
    -- OPTIONAL
    ,@PK_EventType        int = 15
    ,@EventName            nvarchar(400) = NULL
    ,@dStartUTC            datetime2 = NULL
    ,@dEndUTC            datetime2 = NULL
    
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
 
    OBJECT:            dbo.usp_EventsAT_Get_PMPromotion
 
    USE:            
			DECLARE @e int, @em varchar(4000)
 
            EXEC dbo.usp_EventsAT_Get_PMPromotion
                    @PK_Event = 777795
                    ,@Error = @e OUTPUT  /* @e must be defined in the local call */
                    ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
				    ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
                    
    DESCRIPTION:    Gets promotion data
 
    NOTES:
 
    DEPENDENCIES
    --------------------------------------------------------------------
    dbo.Event, dbo.EventLocaleDesc, dbo.EventExtn, dbo.EventDSTeamType, dbo.EventDistributorCountryLocales
 
    VERSIONS
    --------------------------------------------------------------------
    1.0.0        2017-04-05         RogelioR        Initial
    2.0.0		 2019-08-08			NoeG			Refactor code (SRE)
	2.0.1		 2019-10-17			alejandramed	SRE Compliance 
	2.0.2		 2022-06-20		    puertac			US 1050464: Remove Errorlog when PK_event has been deleted
******************************************************************************/
    
    SET ANSI_NULLS ON
    SET QUOTED_IDENTIFIER ON
    SET NOCOUNT ON
    
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_Locale            int
            ,@PK_DefaultLocale    int;
            
	SELECT @Error = 0, @ErrorMessage = '';
             
    BEGIN TRY
        -----------------------------------------------------------------------------------------------------------------------
        -- Promotion Audience
        SELECT DSTeamTypeCode AS Audience
            FROM EventDSTeamType WITH(NOLOCK)
            WHERE PK_Event = @PK_Event;
 
        -----------------------------------------------------------------------------------------------------------------------
        -- Promotion Locales
        SELECT  
                eld.PK_Locale
                ,l.LocaleCode
                ,l.LanguageCountryRegion
                ,cl.sRegionLabel AS Region
            FROM EventDistributorCountryLocales    AS eld  WITH(NOLOCK)
                INNER JOIN Locales AS l  WITH(NOLOCK) ON l.PK_Locale = eld.PK_Locale
                INNER JOIN v_CountryLocale AS cl  WITH(NOLOCK) ON cl.sLocaleCode = l.LocaleCode
            WHERE PK_Event = @PK_Event;
 
        -----------------------------------------------------------------------------------------------------------------------
        -- Default locale
        SELECT 
                e.PK_DefaultLocale
                ,l.LocaleCode
                ,l.LanguageCountryRegion
            FROM Event AS e  WITH(NOLOCK)
                INNER JOIN Locales AS l ON l.PK_Locale = e.PK_DefaultLocale
            WHERE e.PK_Event = @PK_Event;
        
        -----------------------------------------------------------------------------------------------------------------------
        -- Allowed DS List flag
        SELECT    
                COUNT(*) AS [AllowedDS]
                ,(SELECT
                        COUNT(*)
                    FROM [UploadedMemberDump] WITH(NOLOCK)
                    WHERE [PK_Event] = @PK_Event) AS [InvalidIds]
            FROM [UploadedMember] WITH(NOLOCK) WHERE [PK_EVENT] = @PK_Event;


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
		 
	END CATCH
END;