
CREATE PROCEDURE [dbo].[usp_EventsAT_Del_EventGroups]
	-- Required
	@PK_EventGroup	int
	,@LocaleCode	varchar(5)
	
	-- Error
	,@Error int OUTPUT
	,@ErrorMessage varchar(200) OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			[dbo].[usp_EventsAT_Del_EventGroups]
USE:			
				DECLARE @e int, @em varchar(255);

				EXEC [dbo].[usp_EventsAT_Del_EventGroups]
					@PK_EventGroup = 1
					,@LocaleCode = 'en-SG'
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

				SELECT @e, @em

DESCRIPTION:	Deletes record from dbo.EventGroups and related tables

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.EventGroupImageLocale, dbo.EventGroupLocale, dbo.EventGroupMembers, dbo.EventGroupURL

VERSIONS
--------------------------------------------------------------------
1	2017-05-31		RogelioR		Initial

******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(100)
			,@StartTime datetime
			,@PK_DefaultLocale int
			,@PK_Locale int
			,@DeleteAll	bit;

	SELECT	@StoredProcedure = 'usp_EventAPI_Del_EventGroups'
			,@StartTime = GETUTCDATE()
			,@Error = 0
			,@ErrorMessage = 'No Error.';

	--------------------------------------------------------------------
	--	Check if event exists
	--
	SELECT @PK_EventGroup = [PK_EventGroup], @PK_DefaultLocale = [PK_DefaultLocale] FROM [dbo].[EventGroups] WITH (NOLOCK) WHERE [PK_EventGroup] = @PK_EventGroup;
	SELECT @PK_Locale = PK_Locale FROM Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode;

	IF @PK_EventGroup IS NULL OR @PK_DefaultLocale IS NULL OR @PK_Locale IS NULL
	BEGIN
		SET @Error = 126;

		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT;
		RETURN
	END

	--------------------------------------------------------------------
	--	Delete EventGroup from related tables
	--
	BEGIN TRY
		BEGIN TRANSACTION;
			SELECT @DeleteAll = CASE WHEN @PK_DefaultLocale = @PK_Locale THEN 1 ELSE 0 END;
			
			IF @IsDevQA = 1 SELECT @PK_DefaultLocale AS [Default Locale], @PK_Locale AS [Locale], @DeleteAll AS [Delete All];

			DELETE EventGroupImageLocale WHERE PK_EventGroup = @PK_EventGroup AND (@DeleteAll = 1 OR PK_Locale = @PK_Locale);
			
			DELETE EventGroupLocale WHERE PK_EventGroup = @PK_EventGroup AND (@DeleteAll = 1 OR PK_Locale = @PK_Locale);
			
			DELETE EventGroupMembers WHERE PK_EventGroup = @PK_EventGroup AND @DeleteAll = 1;
			
			DELETE EventGroupURL WHERE PK_EventGroup = @PK_EventGroup AND (@DeleteAll = 1 OR PK_Locale = @PK_Locale);
			
			DELETE EventGroups WHERE PK_EventGroup = @PK_EventGroup AND @DeleteAll = 1;

		COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		SELECT	@Error = ERROR_NUMBER()
				,@ErrorMessage = ERROR_MESSAGE()
				,@StoredProcedure = ERROR_PROCEDURE();

		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage;

		RETURN 
	END CATCH

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime

END