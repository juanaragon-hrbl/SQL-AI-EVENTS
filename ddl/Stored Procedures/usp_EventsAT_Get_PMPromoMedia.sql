CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromoMedia]
	-- Required
	@PK_Event			int = NULL

	-- Optional
	,@PK_MediaType		int = NULL
	,@PK_EventMedia		int = NULL
	,@LocaleCode		varchar(5) = NULL
	
	-- Error
	,@Error				int OUTPUT 
	,@ErrorMessage		nvarchar(200) OUTPUT
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Get_PMPromoMedia

	USE:			
					DECLARE @e int, @em varchar(max);

					EXEC dbo.usp_EventsAT_Get_PMPromoMedia
							@PK_MediaType = null
							,@PK_Event = 48019
							,@PK_EventMedia = null
							,@LocaleCode = 'en-PF'
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
					SELECT @e AS Error, @em AS ErrorMessage

	DESCRIPTION:	Gets promotion media data

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventMedia

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-06		RogelioR		Initial
	1.0.1		2022-06-07		puertac			US 1050464: Remove Errorlog when no records are found on EventMedia, Media information is optional + do not return all records when @PK_event = 0 OR NULL
	
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();		
			
	SELECT 
			@Error = 0
			,@ErrorMessage = 'No Error.';
			
	BEGIN TRY
												  		
		-----------------------------------------------------------------------------------------------------------------------
		-- Promotion Audience
		SELECT
				em.[PK_EventMedia]
				,em.[PK_Event]
				,em.[PK_MediaType]
				,emt.[MediaTypeDesc]
				,em.[PK_Locale]
				,em.[MediaName]
				,em.[MediaDesc]
				,em.[MediaHTML]
			FROM dbo.[EventMedia] AS em WITH (NOLOCK)
				INNER JOIN dbo.[MediaType] AS emt WITH (NOLOCK) ON emt.PK_MediaType = em.PK_MediaType
				INNER JOIN dbo.[Locales] AS l WITH (NOLOCK) ON l.PK_Locale = em.PK_Locale
			WHERE (PK_EventMedia = @PK_EventMedia OR ISNULL(@PK_EventMedia, 0) = 0)
				AND em.PK_Event = @PK_Event 
				AND (l.LocaleCode = @LocaleCode OR ISNULL(@LocaleCode, '') = '')
				AND (em.PK_MediaType = @PK_MediaType OR ISNULL(@PK_MediaType, 0) = 0);

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;


	END TRY
	
	BEGIN CATCH
		SELECT 
				@Error = ERROR_NUMBER()
				,@ErrorMessage = ERROR_MESSAGE()
				,@StoredProcedure = ERROR_PROCEDURE();

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage;

	END CATCH;
END;