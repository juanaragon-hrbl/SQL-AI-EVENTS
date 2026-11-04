CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_UserEventSubTypes]
		-- Mandatory Parameters
		 @LocaleCode CHAR(5) = NULL
		,@EventTypeCode varchar(7) = 'ALL' --[DE, CE, CP, ALL, ALLCORP][optional][default distributor event]		
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
	            
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_UserEventSubTypes

USE:
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.usp_MyHLEventAPI_Get_UserEventSubTypes
						 @LocaleCode = 'en-US'
					 	,@EventTypeCode = NULL
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the EventSubTypes for locale and/or EventTypeCode passed

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.EventSubTypeGroupMaster, dbo.EventSubTypeGroupLocale, dbo.EventSubTypeGroup, 
dbo.EventSubTypes, dbo.EventSubTypeLocaleDesc, dbo.Locales

VERSIONS
----------------------------------------------------------------------------------
1	2014-11-12	Sushma B	Initial
2	2019-08-14	NoeG		Refactor code (SRE)
******************************************************************************/

DECLARE @PK_Locale int
DECLARE @PK_DefaultLocale int
DECLARE @tblEventType TABLE (PK_EventType int)
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = 'en-US'

/* ***************** SonarQube check 105 and 106 - Output parameters should be assigned 
	SRE changes added
*/
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY
	IF COALESCE(@EventTypeCode, 'ALL') = 'ALL'
	BEGIN
		INSERT @tblEventType (PK_EventType)
		SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK)	
	END 

	ELSE

	IF @EventTypeCode = 'ALLCORP'
	BEGIN
		INSERT @tblEventType (PK_EventType)
		SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode IN ('CP','CE')	
	
	END

	ELSE
	BEGIN
		INSERT @tblEventType (PK_EventType)
		SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode = @EventTypeCode
	
	END

		SELECT DISTINCT
			 EST.PK_EventSubType
			,ESL.EventSubTypeDesc 'EventSubType'
			,ETE.EventType
			,ETE.EventTypeCode	
			,ESL.PK_Locale
			,L.LocaleCode
		FROM 
			dbo.EventSubTypeGroupMaster EM WITH (nolock)
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (nolock)
		ON
			ESG.PK_EventSubTypeGroupMaster = EM.PK_EventSubTypeGroupMaster
		INNER JOIN
			@tblEventType ET
		ON
			ESG.PK_EventType = ET.PK_EventType
		INNER JOIN
			dbo.EventType ETE  WITH (NOLOCK)
		ON
			ETE.PK_EventType = ET.PK_EventType		
		INNER JOIN
			dbo.EventSubTypes EST WITH (nolock)
		ON
			EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
			AND
			EST.PK_EventType = ESG.PK_EventType
			AND
			EST.IsActive = 1 	
		INNER JOIN
			dbo.EventSubTypeLocaleDesc ESL  WITH (NOLOCK)
		ON
			EST.PK_EventSubType = ESL.PK_EventSubType
			AND 
			ESL.PK_Locale = COALESCE(@PK_Locale, ESL.PK_Locale)
		INNER JOIN
			dbo.Locales L WITH (NOLOCK)
		ON
			ESL.PK_Locale = L.PK_Locale
		WHERE
			EM.IsActive = 1
			AND
			ESL.EventSubTypeDesc IS NOT NULL	
		ORDER BY
			2
	

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
END CATCH;
END
