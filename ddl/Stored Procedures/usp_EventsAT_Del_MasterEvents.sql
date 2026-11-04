CREATE PROCEDURE [dbo].[usp_EventsAT_Del_MasterEvents]			
	@PK_MasterEvent INT 

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Del_MasterEvents

USE:	
	DECLARE @e int, @em varchar(4000)
		
	EXEC usp_EventsAT_Del_MasterEvents
					@PK_MasterEvent = 71
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Delete Master Events by PK

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubTypeGroup


VERSIONS
--------------------------------------------------------------------
1	2012-10-23	JuanH			Initial
2	2012-11-14	JuanH			Delete by PK
3	2019-08-15	NoeG			Refactor code (SRE)
4	2019-10-15	alejandramed	SRE Compliance 
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

BEGIN TRY

	/******************************************************************************
		variable declaration
	******************************************************************************/
	DECLARE @IsDelete INT = 0


	/*Verify if EventEventSubtype  using this masterevent*/

	IF EXISTS (
		SELECT TOP 1 PK_EventSubType
		FROM  dbo.EventSubTypes EST WITH (NOLOCK)
		INNER JOIN
			dbo.EventSubTypeGroup ESTG WITH (NOLOCK)
			ON
				ESTG.PK_EventSubTypeGroup = EST.PK_EventSubTypeGroup
		INNER JOIN 
			dbo.EventSubTypeGroupMaster ESM WITH (NOLOCK)
			ON 
				ESTG.PK_EventSubTypeGroupMaster = ESM.PK_EventSubTypeGroupMaster	
		WHERE 
			ESTG.PK_EventSubTypeGroupMaster = @PK_MasterEvent
		AND
			ESM.IsAtomic <> 1
	)
	BEGIN
		SET @Error = 298
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END 

	/* Verify if SubEvents are assigned to DS */
	IF EXISTS (SELECT TOP 1 1 
				FROM dbo.EventDSAccess EDA WITH (NOLOCK)
				INNER JOIN
				dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK)
				ON
					EDA.PK_EventSubTypeLocaleDesc = ESL.PK_EventSubTypeLocaleDesc
				INNER JOIN
				dbo.EventSubTypes EST WITH (NOLOCK)
				ON
					ESL.PK_EventSubType = EST.PK_EventSubType
				INNER JOIN 
				dbo.EventSubTypeGroup ESG WITH (NOLOCK)
				ON
					EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
				WHERE ESG.PK_EventSubTypeGroupMaster = @PK_MasterEvent) 
	BEGIN
		SET @Error = 298
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END

	/* Verify if Translations existes other than english  */

	IF EXISTS (SELECT TOP 1 PK_Locale 
				FROM dbo.EventSubTypeGroupLocale WITH (NOLOCK)
				WHERE PK_EventSubTypeGroupMaster = @PK_MasterEvent AND PK_Locale <> 77)				
	BEGIN
		SET @Error = 298
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END

		BEGIN TRAN
		/*	
			DELETE ESTL FROM dbo.EventSubTypeLocaleDesc ESTL
			INNER JOIN
			dbo.EventSubTypes EST
			ON
				ESTL.PK_EventSubType = EST.PK_EventSubType
			INNER JOIN
			dbo.EventSubTypeGroup ESG
			ON
				EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup		
			WHERE 
				ESG.PK_EventSubTypeGroupMaster = @PK_MasterEvent
		
	
			DELETE EST FROM dbo.EventSubTypes EST
			INNER JOIN
			dbo.EventSubTypeGroup ESG
			ON
				EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup		
			WHERE 
				ESG.PK_EventSubTypeGroupMaster = @PK_MasterEvent
		
	
			SELECT @IsDelete = @@ROWCOUNT
		*/	
				DELETE EST FROM dbo.EventSubTypes EST
				INNER JOIN dbo.EventSubTypeGroup ESG
				ON EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup	
				INNER JOIN dbo.EventSubTypeGroupMaster ESM
				ON ESG.PK_EventSubTypeGroupMaster = ESM.PK_EventSubTypeGroupMaster	
				WHERE ESG.PK_EventSubTypeGroupMaster = @PK_MasterEvent 
				AND ESM.IsAtomic = 1
		
				DELETE ESG FROM dbo.EventSubTypeGroup ESG
				WHERE ESG.PK_EventSubTypeGroupMaster = @PK_MasterEvent
	
				DELETE ESGL FROM dbo.EventSubTypeGroupLocale ESGL
				WHERE ESGL.PK_EventSubTypeGroupMaster = @PK_MasterEvent
				
				DELETE ESGM FROM dbo.EventSubTypeGroupMaster ESGM
				WHERE ESGM.PK_EventSubTypeGroupMaster = @PK_MasterEvent
		
		COMMIT

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
			
		ROLLBACK TRAN
	
	END CATCH

END
GO

