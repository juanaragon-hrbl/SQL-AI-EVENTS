CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromoEventURL]
	-- Required
	@PK_Event				int = NULL

	-- Optional
	,@PK_EventURL			int = NULL
	,@LocaleCode			varchar(5) = NULL
	,@PromoType				int = 11
	,@LinkType				int = 13
	
	-- Error
	,@Error				int OUTPUT 
	,@ErrorMessage		nvarchar(200) OUTPUT
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Get_PMPromoEventURL

	USE:			
					DECLARE @e int, @em varchar(max);

					EXEC dbo.usp_EventsAT_Get_PMPromoEventURL
							@PK_Event = 48022
							,@LocaleCode = 'en-US'
							--,@EventURLTypeException
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
					SELECT @e AS Error, @em AS ErrorMessage
					
	DESCRIPTION:	Gets promotion media data

	NOTES:select <all> from Locales

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventMedia

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-07		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.0.1		2022-06-20		puertac			US 1050464: Remove Errorlog when PK_event has been deleted
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
				eu.[PK_EventURL]
				,eu.[PK_Event]
				,eu.[PK_Locale]
				,l.[LocaleCode]
				,eu.[EventURL]
				,eu.[EventURLDesc]
				,eu.[Flyer]
				,eu.[PK_EventURLType]
				,eut.[EventURLType]
			FROM dbo.[EventURL] AS eu WITH (NOLOCK)
			INNER JOIN dbo.[EventURLType] AS eut WITH (NOLOCK) ON eut.PK_EventURLType = eu.PK_EventURLType
			INNER JOIN dbo.[Locales] AS l WITH (NOLOCK) ON l.PK_Locale = eu.PK_Locale
			WHERE (PK_EventURL = @PK_EventURL OR ISNULL(@PK_EventURL, 0) = 0)
			AND (eu.PK_EventURLType NOT IN (@PromoType, @LinkType))
			AND eu.PK_Event = @PK_Event 
			AND (l.LocaleCode = @LocaleCode OR ISNULL(@LocaleCode, '') = '');


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

