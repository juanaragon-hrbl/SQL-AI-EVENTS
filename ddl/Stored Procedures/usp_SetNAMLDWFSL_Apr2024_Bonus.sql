CREATE PROCEDURE [dbo].[usp_SetNAMLDWFSL_Apr2024_Bonus]
	@IsDevQA		BIT = 0,  
	   @Error	int = 0 OUTPUT,
	   @ErrorMessage varchar(4000) = NULL OUTPUT,
	   @Cut	DATETIME = NULL
 
AS
BEGIN

/*********************************************************************************************************************
	OBJECT:		dbo.usp_SetNAMLDWFSL_Apr2024_Bonus
		
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_SetNAMLDWFSL_Apr2024_Bonus 
				
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1
				,@Cut = '2024-03-01'

			SELECT @e AS [Error], @em AS [Error Message]
	NOTES:		

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2012
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1		2024-02-15   JonathanO  	Initial to get the contributors for the NAMLDW DS NEW BONUS from Jan24 to Mar24 ONLY!
	2		2024-02-23   JonathanO  	Initial to get the contributors for Jan24 to Mar24 and Jan24 to Dec24 Only.
	3		2024-02-29   JonathanO  	Changing v_agg to PubEvents.dbo.factdsfinancial_ctry.

	WRK_NAMLDWFSL_Apr2024_Bonus				Used for the Jan24-Mar24 Period
	WRK_NAMLDWFSL_Apr2024_BonusJanToDec		Used for the Jan24-Dec24 Period

***********************************************************************************************************************************/
/***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

	SELECT @Error = 0, @ErrorMessage = '';

	DECLARE	@StartAppDate	DATETIME = '2024-01-01',
			@EndAppDate		DATETIME = DATEADD(DD,-1,DATEADD(MM,1,@Cut))

BEGIN TRY	
/************************************************************
Starting validations with the parameters and populating #NewDS
**************************************************************/
IF	(@StartAppDate IS NULL OR @EndAppDate IS NULL OR @Cut IS NULL)
BEGIN
PRINT 'ERROR: You must specify the StartDate, EndDate or CutDate.'  
RETURN  
END

IF	(@EndAppDate NOT IN ('2024-03-31','2024-12-31') OR @Cut NOT IN ('2024-03-01','2024-12-01'))
BEGIN
PRINT 'ERROR: This usp supports only Jan24 to Mar24 and Jan24 to Dec24'  
RETURN  
END

DROP TABLE IF EXISTS #NewDS
 
SELECT 
	nDistributorID,
	dApplication,
	StatusCode,
	CAST(CAST(YEAR(dApplication) AS VARCHAR(4)) + '/' + CAST(MONTH(dApplication) AS VARCHAR(2)) + '/01' AS DATETIME) 	 AS StartMonth, 
	IIF( DATEADD(MM,1,dApplication) > @EndAppDate, @Cut, 
	CAST(CAST(YEAR(DATEADD(MM,1,dApplication)) AS VARCHAR(4)) + '/' + CAST(MONTH(DATEADD(MM,1,dApplication)) AS VARCHAR(2)) + '/01' AS DATETIME))  AS EndMonth   
INTO #NewDS
FROM v_Distributor AS D
WHERE dApplication BETWEEN @StartAppDate AND @EndAppDate

CREATE INDEX IX_#NewDS_PK_Distributor ON #NewDS(nDistributorID)

/***********************************************
Working for the WRK_NAMLDWFSL_Apr2024_Bonus ONLY
************************************************/
IF	(@StartAppDate	= '2024-01-01' AND
	 @EndAppDate	= '2024-03-31' AND
	 @Cut			= '2024-03-01'
)
BEGIN

DROP INDEX IF EXISTS [IX_Event_WRK_NAMLDWFSL_Apr2024_Bonus_PK_Distributor] ON [dbo].[WRK_NAMLDWFSL_Apr2024_Bonus];

MERGE WRK_NAMLDWFSL_Apr2024_Bonus  AS t
USING (

SELECT	v.pk_distributor AS [nDistributorID],nd.dApplication,nd.StatusCode,
		(SUM(v.DV)+SUM(v.DLV_DV)) AS [PPV]
FROM	PubEvents.dbo.factdsfinancial_ctry v WITH (NOLOCK)
INNER JOIN
#NewDS AS nd
ON v.pk_distributor = nd.nDistributorID AND v.RoyaltyMonth BETWEEN FORMAT(nd.StartMonth,'yyyyMM') AND FORMAT(nd.EndMonth,'yyyyMM')
GROUP BY v.pk_distributor,nd.dApplication,nd.StatusCode


) AS s ON s.[nDistributorID] = t.[PK_Distributor]
	WHEN NOT MATCHED AND s.[PPV] >= 100 AND s.[StatusCode] = 'COMPLETE'
	  THEN
		INSERT (
		 [PK_Distributor]
		,[dApplication]
		,[StatusCode]
		,[PPV]
		,[IsContributor]
		,[IsActive]
		)
	VALUES (
			 s.[nDistributorID]
			,s.[dApplication]
			,s.[StatusCode]
			,s.[PPV]
			,1
			,1
	)
	WHEN MATCHED AND s.[StatusCode] = 'COMPLETE'
		THEN
	UPDATE SET
	 [IsContributor]	= CASE WHEN s.[PPV] >= 100 THEN 1 ELSE 0 END  
	;

CREATE INDEX [IX_Event_WRK_NAMLDWFSL_Apr2024_Bonus_PK_Distributor] ON [dbo].[WRK_NAMLDWFSL_Apr2024_Bonus] ([PK_Distributor])

MERGE WRK_NAMLDWFSL_Apr2024_Bonus  AS t
USING (

SELECT 
	nDistributorID,dApplication,StatusCode
FROM
	#NewDS

) AS s ON s.[nDistributorID] = t.[PK_Distributor]
	WHEN MATCHED AND s.[StatusCode] != 'COMPLETE'
		THEN
	UPDATE SET
	 [IsActive]		= 0,
	 [StatusCode]	= s.[StatusCode]
	;

END

/***********************************************
Working for the WRK_NAMLDWFSL_Apr2024_BonusJanToDec
************************************************/

IF	(@StartAppDate	= '2024-01-01' AND
	 @EndAppDate	= '2024-12-31' AND
	 @Cut			= '2024-12-01'
)
BEGIN

DROP INDEX IF EXISTS [IX_Event_WRK_NAMLDWFSL_Apr2024_BonusJanToDec_PK_Distributor] ON [dbo].[WRK_NAMLDWFSL_Apr2024_BonusJanToDec];

MERGE WRK_NAMLDWFSL_Apr2024_BonusJanToDec  AS t
USING (

SELECT	v.pk_distributor AS [nDistributorID],nd.dApplication,nd.StatusCode,
		(SUM(v.DV)+SUM(v.DLV_DV)) AS [PPV]
FROM	PubEvents.dbo.factdsfinancial_ctry v WITH (NOLOCK)
INNER JOIN
#NewDS AS nd
ON v.pk_distributor = nd.nDistributorID AND v.RoyaltyMonth BETWEEN FORMAT(nd.StartMonth,'yyyyMM') AND FORMAT(nd.EndMonth,'yyyyMM')
GROUP BY v.pk_distributor,nd.dApplication,nd.StatusCode

) AS s ON s.[nDistributorID] = t.[PK_Distributor]
	WHEN NOT MATCHED AND s.[PPV] >= 100 AND s.[StatusCode] = 'COMPLETE'
	  THEN
		INSERT (
		 [PK_Distributor]
		,[dApplication]
		,[StatusCode]
		,[PPV]
		,[IsContributor]
		,[IsActive]
		)
	VALUES (
			 s.[nDistributorID]
			,s.[dApplication]
			,s.[StatusCode]
			,s.[PPV]
			,1
			,1
	)
	WHEN MATCHED AND s.[StatusCode] = 'COMPLETE'
		THEN
	UPDATE SET
	 [IsContributor]	= CASE WHEN s.[PPV] >= 100 THEN 1 ELSE 0 END  
	;

CREATE INDEX [IX_Event_WRK_NAMLDWFSL_Apr2024_BonusJanToDec_PK_Distributor] ON [dbo].[WRK_NAMLDWFSL_Apr2024_BonusJanToDec] ([PK_Distributor])

MERGE WRK_NAMLDWFSL_Apr2024_BonusJanToDec  AS t
USING (

SELECT 
	nDistributorID,dApplication,StatusCode
FROM
	#NewDS

) AS s ON s.[nDistributorID] = t.[PK_Distributor]
	WHEN MATCHED AND s.[StatusCode] != 'COMPLETE'
		THEN
	UPDATE SET
	 [IsActive]		= 0,
	 [StatusCode]	= s.[StatusCode]
	;

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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;