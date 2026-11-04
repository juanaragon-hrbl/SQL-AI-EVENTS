CREATE PROCEDURE [dbo].[usp_EventQual_MAP_EMEA]
		@PK_Event INT
		,@DatetoProcess DATE 
       ,@ListID INT = 0   

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN

/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_MAP_EMEA

	USE:	
			DECLARE @e int, @em varchar(4000)
				
			EXEC dbo.usp_EventQual_MAP_EMEA  
				@PK_Event = 53541 
				,@DatetoProcess = '20170301' 
				,@ListID = 13061
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION: This procedure is a custom qual for EMEA Member Activation Program ongoing Promotion

	NOTES:			

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2008
	WRK_MAP_Winner_EMEA
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1	2017-03-28   Juan		Initial
	2	2018-01-23   Juan		Italy removed from promo as of March 2018	  
	3	2019-09-30	 NoeG		SRE template applied
***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	DECLARE 
	@BeginMonth DATE  
	,@EndMonth DATE 
	,@CurrentDate DATE = @DatetoProcess

/*********************************************************************************/
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		IF GETUTCDATE() < @CurrentDate
			RETURN 1

		IF DAY(GETUTCDATE()) < 15
			SET @CurrentDate = DATEADD(m,-1,GETUTCDATE())

		SET @BeginMonth = DATEADD(m,-2,@CurrentDate)
		SET @BeginMonth = DATEADD(d,-DAY(@BeginMonth) + 1, @BeginMonth)
		SET @EndMonth = DATEADD(d,-DAY(@CurrentDate)+1,@CurrentDate)  


		SELECT nCountryID as PK_Country ,sCountryName
		INTO #Country
		FROM v_Countries 
		WHERE sCountryName IN 
		(
			'Austria','Belgium','Bosnia and Herzegovina','Botswana','Bulgaria','Croatia','Cyprus','Czech Republic',
			'Denmark','Finland','France','Germany','Ghana','Greece','Hungary','Iceland','Ireland','Israel','Italy',
			'Lebanon','Lesotho','Macedonia','Malta','Montenegro & Kosovo','Namibia','Netherlands','Norway','Portugal',
			'Poland','Republic of Moldova','Romania','Serbia','Slovak Republic','Slovenia','South Africa','Spain',
			'Swaziland','Sweden','Switzerland','Turkey','United Kingdom','Zambia'
		)

		IF @CurrentDate > '2018-03-01'
		DELETE FROM #Country WHERE sCountryName = 'Italy'

		CREATE TABLE #MAP
		(
			PK_Distributor INT,
			PK_Country INT
		)

		INSERT INTO #MAP 
		(
			PK_Distributor,
			PK_Country
		)
		SELECT  
			d.nDistributorID,
			c.PK_Country
		FROM
			v_DistributorCurrent d
		INNER JOIN
			#Country AS c
		ON
			d.nDistributorCountryProcessingID = c.PK_Country
		WHERE
			ISNULL(dSupervisorQualification,'2049-12-31') > @BeginMonth


		;WITH MAPEMEA (PK_Distributor,PK_Country, RoyaltyMonth)  AS (

			SELECT 
				PK_Distributor,
				PK_Country,
				@EndMonth		
			FROM #MAP M
			 CROSS APPLY ufn_GetConsecutive(M.PK_Distributor,@BeginMonth,@EndMonth,500,3,'PPV') 
			EXCEPT
			SELECT 
				PK_Distributor,
				PK_Country,
				@EndMonth		
			FROM
				 dbo.WRK_MAP_Winner_EMEA WITH (NOLOCK)
		)
		INSERT INTO dbo.WRK_MAP_Winner_EMEA 
		(
			PK_Distributor,
			PK_Country,
			RoyaltyMonth
		)
		SELECT PK_Distributor,PK_Country, RoyaltyMonth FROM MAPEMEA


		/******************************************************************
			Clean table from DELETED members
		******************************************************************/

		DELETE 
		FROM dbo.WRK_MAP_Winner_EMEA 
		WHERE NOT EXISTS (SELECT nDistributorID FROM v_DistributorCurrent WHERE PK_Distributor = nDistributorID)

		/******************************************************************
			Process Qualifiers
		******************************************************************/
		--IF OBJECT_ID('tempdb..##Q1', 'U') IS NOT NULL DROP TABLE ##Q1

		--DECLARE @PK_SubEvent INT
 
		-- /*1 Winner*/
		--SELECT @PK_SubEvent = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 1

		--	SELECT 
		--		T.PK_Distributor
		--	INTO ##Q1
		--	FROM
		--		WRK_MAP_Winner_EMEA T WITH (NOLOCK)
		--	EXCEPT
		--	SELECT 
		--		nDistributorID
		--	FROM
		--		v_DistributorSet
		--	WHERE
		--		nTypeLID	= @ListID

		--EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##Q1', 0

		--IF OBJECT_ID('tempdb..##Q1', 'U') IS NOT NULL DROP TABLE ##Q1

		EXEC usp_Utility_UpdateProcessingLog
			@StoredProcedureName = @StoredProcedure
			,@StoredProcedureParameters = ''
			,@StartTime = @StartTime

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

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
