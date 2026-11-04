CREATE PROCEDURE [dbo].[usp_EventsAT_Get_MasterEvents]				
	-- OPTIONAL
	 @PK_Locale INT = NULL
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT 

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/*********************************************************************************************
OBJECT:			dbo.usp_EventsAT_Get_MasterEvents

USE:	
		USE [PubEventManagement]
		GO

		DECLARE	@Error int,
				@ErrorMessage varchar(4000)

		EXEC	[dbo].[usp_EventsAT_Get_MasterEvents]
				@PK_Locale = NULL,
				@Error = @Error OUTPUT,
				@ErrorMessage = @ErrorMessage OUTPUT,
				@IsDevQA = 0

		SELECT	@Error as N'@Error',
				@ErrorMessage as N'@ErrorMessage'


DESCRIPTION: On Manage Master Events Page, this SP call is to provide the MasterEvents and its associated code types
			 for all code types (CE, CP & DE) in the system.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubTypeGroupMaster
dbo.EventSubTypeGroup
dbo.EventType

VERSIONS
--------------------------------------------------------------------
1		2012-10-22	JuanH/SandhyaP	Initial
1.1		2019-05-21	alejandramed	Homologating of standard error handling
1.2		2019-07-15	alejandramed	Setting error parameters as optionals
1.3		2019-10-15	alejandramed	SRE Compliance 
1.4		2020-07-01	puertac			T290609 Adding IsMajor flag to the result set.

*******************************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/**********************************************************************************
		GET MasterEvents and their Translations
***********************************************************************************/

IF @PK_Locale IS NULL

BEGIN TRY

SELECT DISTINCT
	SGM.PK_EventSubTypeGroupMaster
	, SGM.EventSubTypeGroupMasterName
	, SGM.IsActive
	, SGM.IsAtomic
	, SGM.IsMajor								-- T 290609 IsMajor addition	
	, CASE WHEN SGM.IsAtomic = 1 THEN 0 ELSE EST.HasSubEvents END AS HasSubEvents
	, EDA.HasTranslations
	, COALESCE(EV.[HasEvents], 0) AS [HasEvents]
FROM 
	dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
INNER JOIN	
	dbo.EventSubTypeGroup SG WITH (NOLOCK)
	ON	
		SG.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster
LEFT JOIN	
	dbo.EventSubTypeGroupLocale SGL WITH (NOLOCK)
	ON
		SGM.PK_EventSubTypeGroupMaster = SGL.PK_EventSubTypeGroupMaster
		AND	
		SGL.PK_Locale = COALESCE(@PK_Locale, SGL.PK_Locale)	
LEFT JOIN 
(
		SELECT 
		 A.PK_EventSubTypeGroupMaster, MAX(A.CanBeUpdated) AS [HasSubEvents]
		from
		(			
			SELECT	
			 SGM.PK_EventSubTypeGroupMaster, 
			 CASE WHEN EST.PK_EventSubTypeGroup IS NOT NULL THEN 1 ELSE 0 END [CanBeUpdated]--,
			-- CASE WHEN (SELECT TOP 1 1 FROM EventSubTypeGroupLocale ES WHERE ES.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster AND PK_Locale <> 77) = 1 THEN 1 ELSE 0 END AS [Translation]
			FROM
				dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
			LEFT JOIN
				dbo.EventSubTypeGroup SG WITH (NOLOCK)
				ON
					SG.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster			
			LEFT JOIN 
			(
				SELECT DISTINCT EST.PK_EventSubTypeGroup FROM dbo.EventSubTypes EST WITH (NOLOCK)
			)EST
			ON SG.PK_EventSubTypeGroup = EST.PK_EventSubTypeGroup			
		) A
		GROUP BY A.PK_EventSubTypeGroupMaster
)EST
ON SGM.PK_EventSubTypeGroupMaster = EST.PK_EventSubTypeGroupMaster
LEFT JOIN
(
	SELECT A.PK_EventSubTypeGroupMaster, MAX(A.IsDeleted) AS [HasTranslations]
	FROM (
		SELECT ESG.PK_EventSubTypeGroupMaster
		, CASE WHEN ((SELECT TOP 1 1 FROM EventSubTypeGroupLocale ES WITH (NOLOCK) WHERE ES.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster AND PK_Locale <> 77) = 1)THEN 1 ELSE 0 END AS [IsDeleted]
		FROM dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
		LEFT JOIN 
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
		ON
			SGM.PK_EventSubTypeGroupMaster = ESG.PK_EventSubTypeGroupMaster			
		LEFT JOIN
			dbo.EventSubTypeGroupLocale SGL WITH (NOLOCK)
		ON
			SGM.PK_EventSubTypeGroupMaster = SGL.PK_EventSubTypeGroupMaster
			AND
			SGL.PK_Locale = COALESCE(@PK_Locale, SGL.PK_Locale)	
		) A
	GROUP BY A.PK_EventSubTypeGroupMaster
) EDA
ON SGM.PK_EventSubTypeGroupMaster =  EDA.PK_EventSubTypeGroupMaster	
LEFT JOIN
(
	SELECT A.PK_EventSubTypeGroupMaster, 1 AS [HasEvents]
	FROM
	(
	/***** THIS IS TO VALIDATE BEFORE DELETING THE MASTER TYPE OR CHANGING THE MASTERTYPE FROM ATOMIC TO NON-ATOMIC *****/
	
		SELECT DISTINCT SGM.PK_EventSubTypeGroupmaster 
		FROM 
			dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK) -- CHECK IF SUBTYPES ARE ASSIGNED TO DISTRIBUTORS
		INNER JOIN 
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
			ON 
				SGM.PK_EventSubTypeGroupMaster = ESG.PK_EventSubTypeGroupMaster
		INNER JOIN 
			dbo.EventSubTypes EST WITH (NOLOCK)
			ON 
				ESG.PK_EventSubTypeGroup = EST.PK_EventSubTypeGroup
		INNER JOIN 
			dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK)
			ON 
				EST.PK_EventSubType = ESL.PK_EventSubType
		INNER JOIN dbo.EventDSAccess EDS WITH (NOLOCK)
			ON 
				ESL.PK_EventSubtypeLocaleDesc = EDS.PK_EventSubTypeLocaleDesc
		UNION 
		SELECT DISTINCT ESG.PK_EventSubTypeGroupMaster 
		FROM 
			dbo.EventEventSubType EES WITH (NOLOCK)-- CHECK IF SUBTYPES ARE ASSOCIATED TO EVENTS
		INNER JOIN 
			dbo.Event EV WITH (NOLOCK)
			ON
				 EES.PK_Event = EV.PK_Event
		INNER JOIN 
			dbo.EventSubTypes EST WITH (NOLOCK)
			ON 
				ees.PK_EventSubType = EST.PK_EventSubType
		INNER JOIN 
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
			ON 
				est.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
	)A
)EV
ON SGM.PK_EventSubTypeGroupMaster = EV.PK_EventSubTypeGroupMaster
		
ORDER BY 
	3 DESC	, 2 ASC
				
/**********************************************************************************
		GET MasterEvents and their Code Types
***********************************************************************************/

SELECT DISTINCT
	SGM.PK_EventSubTypeGroupMaster, SG.PK_EventSubTypeGroup, SGM.EventSubTypeGroupMasterName, ET.PK_EventType, ET.EventTypeCode
	, CASE WHEN ESG.PK_EventSubTypeGroup IS NULL  THEN 0 ELSE 1 END AS [CanBeModified]
FROM
	dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
INNER JOIN
	dbo.EventSubTypeGroup SG WITH (NOLOCK)
	ON
		SG.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster
INNER JOIN
	dbo.EventType ET WITH (NOLOCK)
	ON
		SG.PK_EventType = ET.PK_EventType	
LEFT JOIN
	dbo.EventSubTypeGroupLocale SGL WITH (NOLOCK)
	ON
		SGM.PK_EventSubTypeGroupMaster = SGL.PK_EventSubTypeGroupMaster
		AND
		SGL.PK_Locale = COALESCE(@PK_Locale, SGL.PK_Locale)		
LEFT JOIN
(
	 SELECT ESG.PK_EventSubTypeGroupMaster, ESG.PK_EventType, ESG.PK_EventSubTypeGroup
	 FROM DBO.EventSubTypeGroup ESG WITH (NOLOCK)
	 INNER JOIN DBO.EventSubTypes EST WITH (NOLOCK) ON ESG.PK_EventSubTypeGroup = EST.PK_EventSubTypeGroup
)ESG 
	ON 
	   SG.PK_EventSubTypeGroup = esg.PK_EventSubTypeGroup			
ORDER BY 3 ASC		

	
					
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH


ELSE


BEGIN TRY

SELECT DISTINCT
	SGM.PK_EventSubTypeGroupMaster, SGM.EventSubTypeGroupMasterName
FROM
	dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
INNER JOIN
	dbo.EventSubTypeGroup SG WITH (NOLOCK)
	ON
		SG.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster
		AND
		SGM.IsActive = 1
INNER JOIN
	dbo.EventSubTypeGroupLocale SGL WITH (NOLOCK)
	ON
		SGM.PK_EventSubTypeGroupMaster = SGL.PK_EventSubTypeGroupMaster
		AND
		SGL.PK_Locale = COALESCE(@PK_Locale, SGL.PK_Locale)		
WHERE SGM.IsAtomic = 0		
ORDER BY 
	2 ASC		
					
					
END TRY
BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

-- Update processing Log
EXEC [dbo].[usp_Utility_UpdateProcessingLog]
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime;


END