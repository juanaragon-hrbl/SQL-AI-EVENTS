CREATE PROCEDURE [dbo].[usp_EventsAT_Del_SubEvents]			
	 @PK_EventSubType INT
	,@PK_Locale INT
	,@LoggedUser NVARCHAR(MAX)

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Del_SubEvents

USE:	
					DECLARE @e int, @em varchar(4000)
		
					EXEC usp_EventsAT_Del_SubEvents
					 @PK_EventSubType = 1415
					,@PK_Locale  = 36
					,@LoggedUser = 'MuraliP'
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Delete Sub Events by Name AND Trasnlatoins

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubType
dbo.EventSubTypeLocalDesc

VERSIONS
--------------------------------------------------------------------
1	2012-11-08	OrlandoL	Initial
2	2019-08-08	OrlandoL	Refactor code (SRE)
*/

/******************************************************************************
	variable declaration
******************************************************************************/

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_EventSubTypeGroupMaster INT

	SELECT @Error = 0, @ErrorMessage = '';

	/**************************************************************************************
		Delete SubEvents and Translations only for non-atomic Master Events
	***************************************************************************************/	


	--IF EXISTS (SELECT 1 FROM DBO.EventSubTypeGroup ESTG (NOLOCK) INNER JOIN dbo.EventSubTypeGroupMaster ESTM (NOLOCK)
	--	ON ESTG.PK_EventSubTypeGroupMaster = ESTM.PK_EventSubTypeGroupMaster
	--	INNER JOIN dbo.EventSubTypes EST(NOLOCK) ON ESTG.PK_EventSubTypeGroup = EST.PK_EventSubTypeGroup
	--		WHERE EST.PK_EventSubType = @PK_EventSubType
	--			AND ESTM.IsAtomic = 1
	--)
	--BEGIN
	--	SELECT @Error =  PK_ErrorCode FROM dbo.ErrorCode(NOLOCK) WHERE ErrorMsg = 'The Sub Event that needs to be updated/deleted belongs to an Atomic Master Event'
	--	-- Update ErrorLog
	--	EXEC dbo.usp_Utility_UpdateErrorLog 
	--		 @ProcedureName = @StoredProcedure 
	--		,@ErrorNumber = @Error
	--		,@ErrorMessage = @ErrorMessage OUTPUT
	--	RETURN 
	--END

	IF EXISTS (SELECT TOP 1 1 FROM dbo.EventLocaleDesc ELD WITH (NOLOCK) JOIN dbo.EventEventSubType EES WITH (NOLOCK) on ELD.PK_Event = EES.PK_Event and ELD.PK_EventType = EES.PK_EventType	
					INNER JOIN dbo.EventSubTypes EST WITH (NOLOCK) on EES.PK_EventSubType = EST.PK_EventSubType and EST.PK_EventType = EES.PK_EventType	
					INNER JOIN dbo.EventSubTypeLocaleDesc SEL WITH (NOLOCK) ON EST.PK_EventSubType = SEL.PK_EventSubType
					WHERE EST.PK_EventSubType = @PK_EventSubType)
	BEGIN
	
		SELECT @Error =  PK_ErrorCode FROM dbo.ErrorCode WITH (NOLOCK) WHERE ErrorMsg = 'Sub Event Type cannot be deleted, remove its associated Event(s) to delete it'
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			 @ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT

		RETURN
	END

	IF EXISTS (SELECT TOP 1 1 FROM dbo.EventDSAccess EST WITH (NOLOCK)
					INNER JOIN dbo.EventSubTypeLocaleDesc SEL WITH (NOLOCK) ON EST.PK_EventSubTypeLocaleDesc = SEL.PK_EventSubTypeLocaleDesc
					WHERE SEL.PK_EventSubType = @PK_EventSubType)
	BEGIN
	
		SELECT @Error =  PK_ErrorCode FROM dbo.ErrorCode WITH (NOLOCK) WHERE ErrorMsg = 'Sub Event Type cannot be deleted, remove its associated Event(s) to delete it'
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			 @ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT

		RETURN
	END

	IF (((SELECT PK_EventATAccessUserType FROM DBO.EventATAccessUser WITH (NOLOCK) where EventATAccessUserName = @LoggedUser) = 2) AND 
	((SELECT PK_EventATAccessUserType FROM DBO.EventATAccessUser WITH (NOLOCK) where EventATAccessUserName = (SELECT EST.CreatedBy FROM dbo.EventSubTypes EST WITH (NOLOCK) WHERE EST.PK_EventSubType = @PK_EventSubType)) = 1))
	BEGIN
	
		SELECT @Error =  403
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			 @ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT

		RETURN
	END


	BEGIN TRY
	
		/******************************************************************************
		  Remove the SubTypes & SubTypesLocales for the checkedoff Code Types
		******************************************************************************/	

		DELETE ESTL
		FROM dbo.EventSubTypeLocaleDesc ESTL
		INNER JOIN
			dbo.EventSubTypes EST
			ON
				EST.PK_EventSubType = ESTL.PK_EventSubType
		WHERE
			ESTL.PK_EventSubType = @PK_EventSubType
			AND
			ESTL.PK_Locale = @PK_Locale
	
		IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.EventSubTypeLocaleDesc ESTL WITH (NOLOCK) WHERE ESTL.PK_EventSubType = @PK_EventSubType AND PK_Locale <> @PK_Locale)
		BEGIN
	
			DELETE EST
			FROM dbo.EventSubTypes EST
			WHERE 
				EST.PK_EventSubType = @PK_EventSubType	
		END

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

