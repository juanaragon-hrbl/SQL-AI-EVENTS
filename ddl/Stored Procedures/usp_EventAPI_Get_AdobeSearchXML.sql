CREATE PROCEDURE [dbo].[usp_EventAPI_Get_AdobeSearchXML]
		-- Optional
		@TypesOmmited xml = NULL
		,@NotNulls bit = 0
		,@StartDate datetime2 = NULL
		,@EndDate datetime2 = NULL
		,@EventURLDefault nvarchar(max) = NULL

		-- Defaults
		,@IsActive bit = 1
		,@IsPublish bit = 1
		,@Prefix nvarchar(255) = 'MyHL3Feed'
		,@OriginType nvarchar(255) = 'Event'
		,@Separator nvarchar(10) = '_'
		,@FileExtension nvarchar(10) = 'xml'

		-- Error
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			[dbo].[usp_EventAPI_Get_AdobeSearchXML]
	
	USE:			
					DECLARE @e int, @em varchar(max);

					DECLARE @s nvarchar(max)
							,@types xml

					EXEC [dbo].[usp_EventAPI_Get_AdobeSearchXML]
							@TypesOmmited = NULL
							,@NotNulls = 0
							,@StartDate = '2017-08-01'
							,@EndDate = '2017-11-01'

							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
					SELECT @e, @em
					
	DESCRIPTION:	Gets an XML column with the Event data properly formatted for Adobe Search

	NOTES:
			* The @types XML parameter includes the EventTypes that will NOT appear on the results. NULL gets all types.
			* @NotNulls = 0 will filter the locales that do not include data in the XML column
	
	DEPENDENCIES
	--------------------------------------------------------------------
	[dbo].[Locales], [dbo].[udf_EventAPI_Get_AdobeSearchSeed]

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-10-20		RogelioR		Initial
	1.0.1		2020-06-03		NoeG			Change to URL path, receive as parameter, if null then path is /eventsng/mediator/	
	1.0.2		2020-03-22		puertac			BUG 592848 : New default paths for all the events LocaleCode/eventsng/mediator/
												+ Remove invalid characters									   
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()

	SELECT @Error = 0, @ErrorMessage = ''


	IF @IsDevQA = 1
		SELECT 
				@IsActive IsActive
				,@IsPublish IsPublish
				,@Prefix Prefix
				,@OriginType OriginType
				,@Separator Separator
				,@FileExtension FileExtension

	BEGIN TRY
	
		;WITH cte AS (
			SELECT
					[id]
					,[OriginType]
					,[OriginID]
					,[PK_EventLocaleDesc]
					,[PK_Locale]
					,[Locale]
					,[Title]
					,[Description]
					,[Url]
					,[Logo] AS [ImageUrl]
					,[Scheme]
					,[Keywords]
					,[PK_EventType]
				FROM [dbo].[udf_EventAPI_Get_AdobeSearchSeed](
							null -- PK_Event
							,null -- LocaleCode
							,@StartDate
							,@EndDate
							,@TypesOmmited -- EventTypes
							,@IsActive
							,@IsPublish
							,'ContentPage' -- OriginTypeDefault
							,default -- EventURLDefault					--BUG 592848
							,default -- root
					)
		)
		,cte_format AS (
			SELECT
					l.[PK_Locale]
					,l.[LocaleCode]
					,(SELECT
							[OriginType]
							,[OriginID]
							,[Locale]
							,[Title]
							,[Description]
							,[Url]
							,(SELECT 'icon-microphone-ln-2' FOR XML RAW('icon'), TYPE, ELEMENTS)
							,CASE WHEN [PK_EventType] = 15 THEN (
								SELECT '<Schemes>'
										+ REPLACE(REPLACE((SELECT [Scheme] FROM (SELECT 'DS' AS [Scheme] UNION ALL SELECT 'MB' AS [Scheme]) AS Schemes FOR XML PATH('x')), '<x>', ''), '</x>', '')
										+ '</Schemes>'
								)	
							ELSE (SELECT 'DS' AS [Scheme] FOR XML RAW('Schemes'), TYPE, ELEMENTS) 
							END
							,[Keywords]
						FROM cte AS record
						WHERE [PK_Locale] = l.[PK_Locale]
						FOR XML RAW('record'), ELEMENTS, ROOT('records')
					) AS [XMLString]
				FROM [dbo].[Locales] AS l WITH (NOLOCK)
		)
		SELECT
				[PK_Locale]
				,[LocaleCode]
				,(@Prefix + @Separator + [LocaleCode] + @Separator + @OriginType + '.' + @FileExtension
				) AS [FileName]
				,CAST([XMLString] AS xml) AS [XMLString]
			FROM cte_format
			WHERE (@NotNulls = 1 OR [XMLString] IS NOT NULL)			
			
	END TRY
	BEGIN CATCH
		SELECT 	@Error = ERROR_NUMBER()
				,@ErrorMessage = ERROR_MESSAGE()
				,@StoredProcedure = ERROR_PROCEDURE();

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage;

	END CATCH;
END;