
CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_MasterEventsTrans]			
		-- MANDATORY
		@MasterEventTrans udt_MasterEventTrans READONLY
		,@ModifiedBy nvarchar(50)
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Upd_MasterEventsTrans

USE:	
			DECLARE @e int, @em varchar(4000)
			DECLARE @MasterEventTrans udt_MasterEventTrans
			
			INSERT INTO @MasterEventTrans 
			VALUES  (9,77,'Summit')
					,(11,77,'Test')
					,(8,74,'LDW1')

		
	EXEC usp_EventsAT_Upd_MasterEventsTrans
					@MasterEventTrans = @MasterEventTrans
					,@ModifiedBy = 'SandhyaP'
		,@Error = @e OUTPUT  -- @e must be defined in the local call   
		,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
		,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Update Master Events Translations 

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubTypeGroup
dbo.EventSubTypeGroupLocale
dbo.EventType

VERSIONS
--------------------------------------------------------------------
1	2012-10-30		JuanH		Initial
2	2019-08-08		NoeG		Refactor code (SRE)
*/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	/* Verify if Exists */
	--IF EXISTS (SELECT TOP 1 * FROM EventSubTypeGroupLocale WHERE EventSubTypeGroupLocale =@TranslationName  )
	--BEGIN
	--	SET @ErrorMessage = 'Translation '+ @TranslationName + ' already exists. No Duplicate allowed'
	--	RETURN
	--END

	BEGIN TRY

	/* UPDATE THE EXISTING MASTER EVENTS TRANSALTIONS */

		UPDATE ESGL
		
		SET
			EventSubTypeGroupLocale = MT.EventSubTypeGroupLocale
			,ModifiedBy = @ModifiedBy
		FROM
			dbo.EventSubTypeGroupLocale ESGL
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESGM
			ON
				ESGL.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster	
				AND
				ESGM.IsActive = 1		
		INNER JOIN
			@MasterEventTrans MT
			ON
				MT.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster
				AND
				MT.PK_Locale = ESGL.PK_Locale
			
	/* INSERT THE NEW MASTER EVENTS TRANSALTIONS */
			
		INSERT [dbo].[EventSubTypeGroupLocale]
				   ([PK_EventSubTypeGroupMaster]
				   ,[PK_Locale]
				   ,[EventSubTypeGroupLocale]
				   ,[ModifiedBy])
		SELECT	
			ESGM.PK_EventSubTypeGroupMaster
			,MT.PK_Locale
			,MT.EventSubTypeGroupLocale
			,@ModifiedBy
		FROM	
			dbo.EventSubTypeGroupMaster ESGM WITH (NOLOCK)		
		INNER JOIN
			@MasterEventTrans MT
			ON
				MT.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster
		WHERE
			NOT EXISTS (SELECT [PK_EventSubTypeGroupLocale] FROM dbo.EventSubTypeGroupLocale WITH (NOLOCK) WHERE ESGM.PK_EventSubTypeGroupMaster = PK_EventSubTypeGroupMaster AND MT.PK_Locale = PK_Locale)
			AND
			ESGM.IsActive = 1
		
	/*Insert the default translations to the EventSubTypeLocaleDesc table for Atomic Master Events*/

		INSERT INTO dbo.EventSubTypeLocaleDesc
		(
			 PK_EventSubType
			,PK_Locale
			,EventSubTypeDesc
			,CreatedBy
			,CreatedDateUTC
			,ModifiedBy
			,ModifiedDateUTC	
		)
	
		SELECT
			EST.PK_EventSubType
		   ,MT.PK_Locale	
		   ,MT.EventSubTypeGroupLocale
		   ,@ModifiedBy
		   ,GETUTCDATE()
		   ,@ModifiedBy
		   ,GETUTCDATE()
		FROM
			dbo.EventSubTypes EST WITH (NOLOCK)
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
		ON 
			EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESGM WITH (NOLOCK)
		ON
			ESG.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster
		JOIN
			@MasterEventTrans MT
		ON
				MT.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster
		WHERE
			ESGM.IsAtomic = 1
			AND 
			ESGM.IsActive = 1
			AND
			NOT EXISTS(SELECT [PK_EventSubTypeLocaleDesc] FROM dbo.EventSubTypeLocaleDesc EL WITH (NOLOCK) WHERE EST.PK_EventSubType = EL.PK_EventSubType AND MT.PK_Locale = EL.PK_Locale)
			
	/*Update the Translation*/	
		UPDATE
				ESL
		SET
			 EventSubTypeDesc = MT.EventSubTypeGroupLocale
			,ModifiedBy = @ModifiedBy
		FROM
			dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK)
		INNER JOIN
			dbo.EventSubTypes EST WITH (NOLOCK)
		ON
			ESL.PK_EventSubType = EST.PK_EventSubType
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
		ON 
			EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESGM WITH (NOLOCK)
		ON
			ESG.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster
		JOIN
			@MasterEventTrans MT
		ON
				MT.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster
				AND
				ESL.PK_Locale = MT.PK_Locale
		WHERE
			ESGM.IsAtomic = 1
			AND 
			ESGM.IsActive = 1	
			
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
GO

