CREATE PROCEDURE [dbo].[usp_EventsAT_Get_DSTeams]
		-- Optional
		@Locale varchar(5) = NULL
						
		-- Defaults
		,@DSTypes varchar(255) = '5,4,7,6'		--US 751461 : Adding DSType 6
		,@Delimiter varchar(10) = ','

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventsAT_Get_DSTeams]
	
	USE:			
				DECLARE @e int, @em varchar(4000)
			
				EXEC usp_EventsAT_Get_DSTeams 
					@Locale = 'en-US'
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT
					,@IsDevQA = 1

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
	2.0.0		2019-08-08		OrlandoL		Refactor code (SRE)
	2.0.1		2019-10-15		alejandramed	SRE Compliance 
	2.0.2		2020-01-28		NoeG			Manage Preferred Members Configured Information for Primary Levels
	2.0.3		2020-06-18		puertac			T259371:Team Level - Clean up according Marketing Plan
	2.0.4		2021-08-17		ivanci			US 751461 - IN:PCX - Introduce new CPC India Team Level
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
		
		DECLARE @PK_Locale INT = (SELECT [PK_Locale] FROM [Locales] WITH (NOLOCK) WHERE [LocaleCode] = @Locale);


		/*****************************************************************************************
			T259371 Insert the teams on a temp table to update the SubTypeDesc as requested
		******************************************************************************************/	
		IF OBJECT_ID('tempdb..#Teams') IS NOT NULL
			DROP TABLE #Teams;

		CREATE TABLE #Teams
		(
			 PK_DSTeam					INT 
			,TeamCode					NVARCHAR (3)  
			,TeamDesc					NVARCHAR (25)
			,SubTypeCode				VARCHAR (6)
			,SubTypeDesc				VARCHAR (50)
			,PK_Locale					INT
			,PK_DSType					INT
			,TeamOrder					INT
			,PrimaryLevelDescription	VARCHAR (25)
			,PK_DSTeamType				INT
		)
		
		INSERT INTO #Teams
		SELECT	 t.[PK_DSTeam]
				,t.[TeamCode]
				,t.[TeamDesc]
				,st.[SubTypeCode]
				,ISNULL(st.[SubTypeDesc], tl.[DSTeamTypeDesc]) AS [SubTypeDesc]
				,tl.[PK_Locale]
				,st.[PK_DSType]
				,CASE WHEN ISNULL(st.[PMLevelOrder],0) = 0 then tt.[TeamOrder] else st.[PMLevelOrder] end as [TeamOrder]
				,st.[PrimaryLevelDescription]
				,TT.PK_DSTeamType
		FROM	[PubEvents]..[dimDSTeam] AS t WITH (NOLOCK)
		LEFT JOIN	
				(	    /************************** T259371  **************************************/
						SELECT	ST.PK_DSSubType, ST.SubTypeCode, ST.SubTypeDesc, ST.PK_DSType, ST.TYPECODE, ST.PK_DSTeam, ST.TEAMCODE, ST.SORTBY
								, NULL as PrimaryLevelCode, NULL as PrimaryLevelDescription, NULL as PMLevelOrder
						FROM  dbo.DSTeamType TT WITH (NOLOCK)
						INNER JOIN  PubEvents.dbo.dimDSSubType ST WITH (NOLOCK)
							ON TT.DSTeamTypeCode = ST.SubTypeCode
						WHERE ST.TYPECODE IN ('SP','DS')
						AND PK_DSTeamType <= 38		-- Where regular DS teams IDs end (PK_DSTeamType from dbo.DSTeamType)
							
					UNION

						SELECT	st.PK_DSSubType, st.SubTypeCode, st.SubTypeDesc, st.PK_DSType
								, st.TYPECODE, st.PK_DSTeam, st.TEAMCODE, st.SORTBY
								, pl.PrimaryLevelCode, pl.PrimaryLevelDescription, pl.[Order] as PMLevelOrder
						FROM	[PubEvents]..[dimDSSubType] st WITH (NOLOCK) 
						LEFT JOIN [PMPrimaryLevel] pl WITH (NOLOCK)
							ON st.SubTypeCode = pl.PrimaryLevelCode
						WHERE	st.SubTypeCode in 
												(	SELECT	pl.[PrimaryLevelCode]
													FROM	[PMPrimaryLevel] pl WITH (NOLOCK)
												)
		 ) AS st 
			 ON st.[PK_DSTeam] = t.[PK_DSTeam]
			 AND st.[PK_DSType] IN	(	SELECT	CAST([String] AS int) 
			 						 	FROM	udf_SplitVarchar(@DSTypes, @Delimiter)
			 						)
		LEFT JOIN [DSTeamType] AS tt WITH (NOLOCK) 
			ON tt.[DSTeamTypeCode] = st.[SubTypeCode]
		LEFT JOIN [DSTeamTypeLocaleDesc] AS tl WITH (NOLOCK) 
			ON st.[SubTypeCode] = tl.[DSTeamTypeCode]
			AND tl.[PK_Locale] = @PK_Locale
		WHERE	[SubTypeCode] != '-2'


		UPDATE #Teams									-- Update the President's SubTypeDesc as requested
		SET SubTypeDesc = TeamDesc+' '+SubTypeCode 		
		WHERE SubTypeDesc LIKE 'President%'
		AND SubTypeCode <> 'PT'

        UPDATE #Teams									-- US 751461 : Update the pk_dstype to 7
		SET PK_DSType = 7		
		WHERE PK_DSType = 6
		
																		 
		SELECT  PK_DSTeam				
			   ,TeamCode				
			   ,TeamDesc				
			   ,SubTypeCode			
			   ,SubTypeDesc			
			   ,PK_Locale				
			   ,PK_DSType				
			   ,TeamOrder				
			   ,PrimaryLevelDescription
			   ,PK_DSTeamType
		FROM #Teams	   
		ORDER BY PK_DSTeamType


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
	END CATCH
END;