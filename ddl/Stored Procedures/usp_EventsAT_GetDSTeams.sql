
CREATE PROCEDURE [dbo].[usp_EventsAT_GetDSTeams]
		-- Optional
		@Locale varchar(5) = NULL
						
		-- Error Parameters
		,@Error	int OUTPUT
		,@ErrorMessage varchar(MAX) OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventsAT_GetDSTeams]
	
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC usp_EventsAT_GetDSTeams 
				@Error = @e OUTPUT
				,@ErrorMessage = @em OUTPUT

			SELECT @e AS [Error], @em AS [ErrorMessage]

	DESCRIPTION:	
		Return the distributor and preferred members types and teams by locale. If locale is not provided, default is returned.

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	[dimDSTeam], [dimDSSubType], [DSTeamTypeLocaleDesc]

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2018-08-25		RogelioR		Initial
	
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255);
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
		
		DECLARE @PK_Locale int = (SELECT [PK_Locale] FROM [Locales] (NOLOCK) WHERE [LocaleCode] = @Locale);

		SELECT
				t.[PK_DSTeam]
				,t.[TeamCode]
				,CASE WHEN [TeamCode] = '-2' THEN 'PM' ELSE t.[TeamDesc] END AS [TeamDesc]
				,st.[SubTypeCode]
				,ISNULL(st.SubTypeDesc, tl.[DSTeamTypeDesc]) AS [SubTypeDesc]
				,tl.[PK_Locale]
			FROM [dimDSTeam] AS t (NOLOCK)
				LEFT JOIN [dimDSSubType] AS st (NOLOCK) ON st.[PK_DSTeam] = t.[PK_DSTeam]
				LEFT JOIN [DSTeamTypeLocaleDesc] AS tl (NOLOCK) ON st.[SubTypeCode] = tl.[DSTeamTypeCode]
					AND tl.[PK_Locale] = @PK_Locale
			WHERE (SubTypeCode != '-2');
	
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
END;