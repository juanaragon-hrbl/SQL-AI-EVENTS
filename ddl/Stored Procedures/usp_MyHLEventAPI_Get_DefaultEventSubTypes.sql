CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_DefaultEventSubTypes]
	 @LocaleCode varchar(5)
	,@PK_Event INT
	,@EventTypeCode varchar(7)= 'ALLCORP' --[DE, CE, CP, ALL, ALLCORP][optional][default corp event]
	

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Get_DefaultEventSubTypes
USE:
			DECLARE @e int, @em varchar(4000)
			declare @IsDevQA int

			EXEC usp_MyHLEventAPI_Get_DefaultEventSubTypes
					 @LocaleCode = 'es-CL'
					,@PK_Event = 2218					
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */					
					-- OPTIONAL
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retreives available eventsubtypes for events in translated/default locales

NOTES:			   @@EventTypeCode  default = DE
					DE = Distributor Event
					CE = Corporate Event
					CP = Corporate Promotion
					ALL = All Event Types
					ALLCORP = CE AND CP - Default
					
DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.Locales
dbo.EventType
dbo.EventSubTypes
dbo.EventSubTypeLocaleDesc

VERSIONS
--------------------------------------------------------------------
1	2011-01-04	SushmaA			Initial Version
2	2019-05-15	alejandramed	Setting error parameters as optionals
3	2019-08-14	NoeG			Refactor code (SRE)
4   2020-07-06	puertac			T290609 Adding IsMajor flag to the result set.																	   
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON		
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE @PK_Locale int
DECLARE @PK_DefaultLocale int
DECLARE @tblEventType TABLE (PK_EventType int)

	BEGIN TRY

		DECLARE @tblTypeList TABLE (
			PK_Master int
			,MasterName nvarchar(200)	
			,IsAtomic bit
			,IsMajor bit				-- T 290609 IsMajor addition
			,MasterTranslation NVARCHAR(400)
			,PK_Locale INT
			,PK_EventSubType INT
			,SubEventName nvarchar (200)
			,PK_EventType INT
			,SubEventNameTranslation nvarchar(400))
		
		SET @Error = 0
		SET @ErrorMessage = 'No Error.'

		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

		IF @EventTypeCode = 'ALL'
		BEGIN
			INSERT @tblEventType (PK_EventType)
			SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK)
		END 

		ELSE
		BEGIN
			IF @EventTypeCode = 'ALLCORP'
			BEGIN
				INSERT @tblEventType (PK_EventType)
				SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode IN ('CP','CE')	
			END
	
			ELSE 
			IF @EventTypeCode = 'DE'
			BEGIN
				INSERT @tblEventType (PK_EventType)
				SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode = @EventTypeCode
			END
	
			ELSE 
			IF @EventTypeCode = 'CE'
			BEGIN
				INSERT @tblEventType (PK_EventType)
				SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode = @EventTypeCode
			END
	
			ELSE 
			IF @EventTypeCode = 'CP'
			BEGIN
				INSERT @tblEventType (PK_EventType)
				SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode = @EventTypeCode
			END
		END
		IF @PK_Locale = @PK_DefaultLocale
		BEGIN
			INSERT @tblTypeList 
			SELECT DISTINCT  
				 EM.PK_EventSubTypeGroupMaster
				,EM.EventSubTypeGroupMasterName
				,EM.IsAtomic
				,EM.IsMajor										-- T 290609 IsMajor addition
				,COALESCE(EML.EventSubTypeGroupLocale,EventSubTypeGroupMasterName) EventSubTypeGroupLocale
				,EML.PK_Locale
				,EST.PK_EventSubType 
				,EST.EventSubType
				,EST.PK_EventType
				,ESL.EventSubTypeDesc EventSubTypeDesc
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
			INNER JOIN
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
			WHERE
				EM.IsActive = 1
				AND
				ESL.EventSubTypeDesc IS NOT NULL
		END
		ELSE
		BEGIN
			INSERT @tblTypeList 
			SELECT DISTINCT
				 EM.PK_EventSubTypeGroupMaster
				,EM.EventSubTypeGroupMasterName
				,EM.IsAtomic
				,EM.IsMajor							-- T 290609 IsMajor addition
				,COALESCE(EML.EventSubTypeGroupLocale,EventSubTypeGroupMasterName) EventSubTypeGroupLocale
				,EML.PK_Locale
				,EST.PK_EventSubType 
				,EST.EventSubType
				,EST.PK_EventType
				,COALESCE(ESL.EventSubTypeDesc, EST.EventSubType) EventSubTypeDesc
			FROM 
				dbo.EventSubTypeGroupMaster EM WITH (NOLOCK)
			LEFT JOIN
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
			INNER JOIN
				dbo.EventSubTypes EST WITH (NOLOCK)
			ON
				EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
				AND
				EST.PK_EventType = ESG.PK_EventType
				AND
				EST.IsActive = 1 
			INNER JOIN
				dbo.EventEventSubType EES WITH (NOLOCK)
			ON
				EST.PK_EventSubType = EES.PK_EventSubType
			AND
				EES.PK_Event = @PK_Event	
			LEFT JOIN
				dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK)
			ON
					EST.PK_EventSubType = ESL.PK_EventSubType
					AND 
					ESL.PK_Locale = @PK_Locale
			WHERE
				EM.IsActive = 1
				AND
				COALESCE(ESL.EventSubTypeDesc, EST.EventSubType) IS NOT NULL
		END	

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
		FROM 
			@tblTypeList T
		WHERE 
			SubEventNameTranslation IS NOT NULL
		ORDER BY 
			IsAtomic DESC, MasterName ASC, SubEventName


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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;