
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventRegistrationSummary]
	-- Required
	@PK_Event			int = NULL

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventAPI_Get_EventRegistrationSummary

	USE:			
					DECLARE @e int, @em varchar(4000);

					EXEC dbo.usp_EventAPI_Get_EventRegistrationSummary
							@PK_Event = 77878
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Get Event registration summary

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.[EventsRegistration]

	VERSIONS (PROD)
	--------------------------------------------------------------------
	1.0.0		2017-12-27		RogelioR		Initial
	1.0.1		2019-09-05		NoeG			SRE template applied
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @t table ([action] nvarchar(15), PK_Key int);

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
		SELECT
				@PK_Event AS [PK_Event]
				,(SELECT COUNT(DISTINCT [PK_Distributor])
					FROM [dbo].[EventsRegistration] WITH (NOLOCK)
					WHERE [PK_Event] = @PK_Event
				) AS [RegisteredDS]
				,ISNULL((SELECT 
						SUM(CAST(SUBSTRING([CustomValue], 1, CHARINDEX(';', [CustomValue])-1) AS INT))
					FROM [dbo].[EventsRegistration] WITH (NOLOCK)
					WHERE [PK_Event] = @PK_Event
						AND IsPrimaryGuest = 1
				), 0) AS [Companions]
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
END;