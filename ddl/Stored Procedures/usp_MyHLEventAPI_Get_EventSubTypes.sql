CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventSubTypes]
	@UserID VARCHAR(30) = NULL
	,@LocaleCode varchar(5) = NULL --[Default Location]
	,@EventTypeCode varchar(7)= NULL --[DE, CE, CP, ALL, ALLCORP][optional][default distributor event]	
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Get_EventSubTypes
USE:
			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC	[dbo].[usp_MyHLEventAPI_Get_EventSubTypes]
					@UserID = '11110190',
					@LocaleCode = N'es-MX',
					@EventTypeCode = N'DE',
					@Error = @Error OUTPUT, /* @e must be defined in the local call */
					@ErrorMessage = @ErrorMessage OUTPUT /* @e must be defined in the local call */
					-- OPTIONAL
					,@IsDevQA = 0

			SELECT	@Error as N'@Error',
					@ErrorMessage as N'@ErrorMessage'			

DESCRIPTION:	RETREIVES AVAILABLE EVENTSUBTYPES FOR DSEVENTS

NOTES:			@@EventTypeCode  default = DE
					DE = Distributor Event
					CE = Corporate Event
					CP = Corporate Promotion
					ALL = All Event Types
					ALLCORP = CE AND CP
					
				WILL RETURN EN_US VERSION IF LOCALIZED EVENT TYPE DOES NOT EXIST
				WILL NOT RETURN EVENT TYPE IN LIST IF NO LOCALIZATION EXISTS

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.Locales
dbo.EventType
dbo.EventSubTypes
dbo.EventSubTypeLocaleDesc

REPLACES usp_MyHLEventAPI_Get_DSEventSubTypes

VERSIONS (S)
--------------------------------------------------------------------
1	2011-01-04	Initial			ScottB
2	2013-01-18  JuanH			Display MasterEvents/SubEvents structure
3	2017-10-24	RogelioR		Add [EventSubTypeLocaleDesc].[Image] column to result set
4	2018-05-16	RogelioR		Add EventSubTypeDesc to result set
5	2019-05-21	alejandramed	Including standard error handling
6	2019-07-15	alejandramed	Setting error parameters as optionals
7	2019-08-14	NoeG			Refactor code (SRE)
8   2020-07-06	puertac			T290609 Adding IsMajor flag to the result set.
9	2021-05-18	ivanci			US 93530 - Manage My Events - No access to Manage or Create Distributor Events  
10	2023-05-02	ivanci			Check for userId equal to null
11  2024-03-20  ivanci			Bug 1329330 - Granting Bulk access by team level is wrong
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

	/******************************************************************************
		VARIABLE DECLARATION
	******************************************************************************/
	DECLARE @PK_Locale int
	DECLARE @PK_DefaultLocale int
	DECLARE @tblEventType TABLE (PK_EventType int)
    DECLARE @DSCop VARCHAR(5)
    DECLARE @DSTeam VARCHAR(10)

	DECLARE @tblTypeList TABLE (
		PK_Master int
		,MasterName nvarchar(200)	
		,IsAtomic bit
		,IsMajor bit				-- T 290609 IsMajor addition	
		,MasterTranslation NVARCHAR(400)
		,PK_Locale INT
		,PK_EventSubType INT
		,SubEventName nvarchar (200)
		,LocaleDescription nvarchar(400)
		,PK_EventType INT
		,SubEventNameTranslation nvarchar(400)
		,[Image] nvarchar(255))

	SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
	SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = 'en-US'
    SELECT @DSCop = sDistributorCountryProcessingCode FROM dbo.v_Distributor WITH (NOLOCK) where sDistributorid = @UserID
    SELECT @DSTeam = sSubTeam FROM dbo.v_Distributor WITH (NOLOCK) where sDistributorid = @UserID

	IF @EventTypeCode = 'ALL'
	BEGIN
		INSERT @tblEventType (PK_EventType)
		SELECT PK_EventType FROM dbo.EventType	WITH (NOLOCK)
	END 

	ELSE
	BEGIN
		IF @EventTypeCode = 'ALLCORP'
		BEGIN
			INSERT @tblEventType (PK_EventType)
			SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode IN ('CP','CE')	
		END
	
		ELSE 
		IF (@EventTypeCode IN ('DE','CE', 'CP'))
		BEGIN
			INSERT @tblEventType (PK_EventType)
			SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode = @EventTypeCode
		END
	
	END

	/******************************************************************************
		GET DROPDOWNS FOR EVENTTYPES ON ADMIN TOOL PAGE FOR STAFF USERS
	******************************************************************************/

	IF (EXISTS (SELECT EventATAccessUserName FROM dbo.EventATAccessUser EU WITH (NOLOCK) WHERE EventATAccessUserName = @UserID) 
                AND (@EventTypeCode = 'ALLCORP' OR @EventTypeCode = 'CE' OR @EventTypeCode = 'CP' OR @EventTypeCode = 'DE') OR @UserID IS NULL)
	BEGIN

	INSERT @tblTypeList 
	SELECT DISTINCT
		 EM.PK_EventSubTypeGroupMaster
		,EM.EventSubTypeGroupMasterName
		,EM.IsAtomic
		,EM.IsMajor							-- T 290609 IsMajor addition
		,EML.EventSubTypeGroupLocale
		,EML.PK_Locale
		,EST.PK_EventSubType 
		,EST.EventSubType
		,ESL.LocaleDescription
		,EST.PK_EventType
		,ESL.EventSubTypeDesc
		,ESL.[Image]
	FROM 
		dbo.EventSubTypeGroupMaster EM WITH (NOLOCK)
	INNER JOIN
		dbo.EventSubTypeGroupLocale EML WITH (NOLOCK)
	ON
			EM.PK_EventSubTypeGroupMaster = EML.PK_EventSubTypeGroupMaster
			AND 
			EML.PK_Locale = @PK_Locale
	INNER JOIN
		dbo.EventSubTypeGroup ESG WITH (NOLOCK)
	ON
		ESG.PK_EventSubTypeGroupMaster = EM.PK_EventSubTypeGroupMaster
	INNER JOIN
		@tblEventType ET
	ON
		ESG.PK_EventType = ET.PK_EventType
	LEFT JOIN
		dbo.EventSubTypes EST WITH (NOLOCK)
	ON
		EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
		AND
		EST.PK_EventType = ESG.PK_EventType
		AND
		EST.IsActive = 1 	
	LEFT JOIN
		dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK)
	ON
			EST.PK_EventSubType = ESL.PK_EventSubType
			AND 
			ESL.PK_Locale = @PK_Locale	
	INNER JOIN
		dbo.EventATAccessUserModules EUM
	ON
		EUM.PK_Locale = EML.PK_Locale
	INNER JOIN
		dbo.EventATAccessUser EU WITH (NOLOCK)
	ON
		EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser					
	WHERE
		EM.IsActive = 1
		AND
		(EU.EventATAccessUserName = @UserID OR @UserID IS NULL)
		AND
		ESL.EventSubTypeDesc IS NOT NULL		

	
	END

	ELSE
	/******************************************************************************
		GET DROPDOWNS FOR EVENTTYPES ON MYHL PAGE FOR DISTRIBUTORS
	******************************************************************************/

	IF EXISTS (SELECT DistributorID FROM dbo.EventDSAccess EU WITH (NOLOCK) WHERE DistributorID = @UserID) AND @EventTypeCode = 'DE'

	BEGIN

	INSERT @tblTypeList 
	SELECT DISTINCT
		 EM.PK_EventSubTypeGroupMaster
		,EM.EventSubTypeGroupMasterName
		,EM.IsAtomic
		,EM.IsMajor							-- T 290609 IsMajor addition
		,EML.EventSubTypeGroupLocale
		,EML.PK_Locale
		,EST.PK_EventSubType
		,EST.EventSubType
		,ESL.LocaleDescription
		,EST.PK_EventType
		,ESL.EventSubTypeDesc
		,ESL.[Image]
	FROM 
		dbo.EventSubTypeGroupMaster EM WITH (NOLOCK)
	INNER JOIN
		dbo.EventSubTypeGroupLocale EML WITH (NOLOCK)
	ON
			EM.PK_EventSubTypeGroupMaster = EML.PK_EventSubTypeGroupMaster
			AND 
			EML.PK_Locale = @PK_Locale
	INNER JOIN
		dbo.EventSubTypeGroup ESG WITH (NOLOCK)
	ON
		ESG.PK_EventSubTypeGroupMaster = EM.PK_EventSubTypeGroupMaster
	INNER JOIN
		@tblEventType ET
	ON
		ESG.PK_EventType = ET.PK_EventType
	INNER JOIN
		dbo.EventType ETE WITH (NOLOCK)
	ON
		ETE.PK_EventType = ET.PK_EventType		
	LEFT JOIN
		dbo.EventSubTypes EST WITH (NOLOCK)
	ON
		EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
		AND
		EST.PK_EventType = ESG.PK_EventType
		AND
		EST.IsActive = 1 	
	LEFT JOIN
		dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK)
	ON
			EST.PK_EventSubType = ESL.PK_EventSubType
			AND 
			ESL.PK_Locale = @PK_Locale
	INNER JOIN
		dbo.EventDSAccess EDA  WITH (NOLOCK)
	ON
	EDA.PK_EventSubTypeLocaleDesc=ESL.PK_EventSubTypeLocaleDesc
    LEFT JOIN dbo.EventTeamLevelAccess ETA  WITH (NOLOCK) 
                            ON	ESL.PK_EventSubTypeLocaleDesc=ETA.PK_EventSubTypeLocaleDesc AND RIGHT((SELECT LocaleCode FROM Locales WITH (NOLOCK) WHERE PK_Locale = @PK_Locale), 2) = @DsCop
	WHERE
		EM.IsActive = 1
		AND
        (EDA.DistributorID = @UserID OR ETA.SubTypeCode = @DSTeam)
		AND
		ESL.EventSubTypeDesc IS NOT NULL	

	
	END
    ELSE -- START US 93530
    BEGIN

        
        DECLARE @HasManageEventAccess BIT

        SELECT @DSTeam = sSubTeam FROM dbo.v_Distributor WITH (NOLOCK) where sDistributorid = @UserID
        
        SELECT @HasManageEventAccess = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END 			
			FROM dbo.[EventTeamLevelAccess] etla WITH (NOLOCK)
			INNER JOIN EventSubTypeLocaleDesc stl WITH (NOLOCK)
			ON stl.pk_EventSubtypeLocaleDesc = etla.pk_EventSubtypeLocaleDesc 
            INNER JOIN Locales L WITH (NOLOCK)
            ON L.PK_Locale = @PK_Locale
			WHERE SubTypeCode = @DSTeam AND stl.pk_Locale = @PK_Locale



        IF @HasManageEventAccess = 1
        INSERT @tblTypeList 
        SELECT DISTINCT
            EM.PK_EventSubTypeGroupMaster
            ,EM.EventSubTypeGroupMasterName
            ,EM.IsAtomic
            ,EM.IsMajor							-- T 290609 IsMajor addition
            ,EML.EventSubTypeGroupLocale
            ,EML.PK_Locale
            ,EST.PK_EventSubType
            ,EST.EventSubType
            ,ESL.LocaleDescription
            ,EST.PK_EventType
            ,ESL.EventSubTypeDesc
            ,ESL.[Image]
        FROM 
            dbo.EventSubTypeGroupMaster EM WITH (NOLOCK)
        INNER JOIN
            dbo.EventSubTypeGroupLocale EML WITH (NOLOCK)
        ON
                EM.PK_EventSubTypeGroupMaster = EML.PK_EventSubTypeGroupMaster
                AND 
                EML.PK_Locale = @PK_Locale
        INNER JOIN
            dbo.EventSubTypeGroup ESG WITH (NOLOCK)
        ON
            ESG.PK_EventSubTypeGroupMaster = EM.PK_EventSubTypeGroupMaster
        INNER JOIN
            @tblEventType ET
        ON
            ESG.PK_EventType = ET.PK_EventType
        INNER JOIN
            dbo.EventType ETE WITH (NOLOCK)
        ON
            ETE.PK_EventType = ET.PK_EventType		
        LEFT JOIN
            dbo.EventSubTypes EST WITH (NOLOCK)
        ON
            EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
            AND
            EST.PK_EventType = ESG.PK_EventType
            AND
            EST.IsActive = 1 	
        LEFT JOIN
            dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK)
        ON
                EST.PK_EventSubType = ESL.PK_EventSubType
                AND 
                ESL.PK_Locale = @PK_Locale
        INNER JOIN
            dbo.EventTeamLevelAccess EDA  WITH (NOLOCK)
        ON
        EDA.PK_EventSubTypeLocaleDesc=ESL.PK_EventSubTypeLocaleDesc
        WHERE
            EM.IsActive = 1
            AND
            EDA.SubTypeCode = @DSTeam
            AND
            ESL.EventSubTypeDesc IS NOT NULL	




    END -- END US 93530

	/******************************************************************************
		GET DROPDOWNS FOR EVENTSUBTYPES
	******************************************************************************/


	/*Master Event*/
	SELECT DISTINCT 
		PK_Master
		,MasterName
		,IsAtomic
		,IsMajor            	-- T 290609 IsMajor addition
		,MasterTranslation
		,PK_Locale
	FROM 
		@tblTypeList
	WHERE 
		(IsAtomic = 1) OR (IsAtomic = 0 AND SubEventNameTranslation IS NOT NULL)
	ORDER BY
		IsAtomic DESC, MasterName ASC


	/*Sub Events*/	
	SELECT 
		PK_Master
		,PK_EventSubType
		,SubEventName
		,PK_EventType
		,SubEventNameTranslation
		,[Image]
		,LocaleDescription
	FROM 
		@tblTypeList
	WHERE 
		SubEventNameTranslation IS NOT NULL
	ORDER BY 
		IsAtomic DESC, MasterName ASC--, SubEventName
	

	/******************************************************************************
		END PROCEDURE
	******************************************************************************/

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

	-- UPDATE PROCESSING LOG
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
END
