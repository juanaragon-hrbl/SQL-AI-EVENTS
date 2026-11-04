CREATE PROCEDURE [dbo].[usp_GetDSConversionDates]
(
	@PK_Event int
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 
)
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_GetDSConversionDates

	USE:		EXEC dbo.usp_GetDSConversionDates @PK_Event = 199467 

	DESCRIPTION: 
 
	NOTES:			
 
	DEPENDENCIES:

	--Stored Procedures

		usp_Utility_UpdateErrorLog
		usp_Utility_UpdateProcessingLog
	
	--Funtions
	 
	--Tables 	
		--// input
			[tmp].[DSForConversionEvaluation]
			##tmp_DSForConversionEvaluation

		--// output
			[tmp].[MemberLastestConversion]
			##tmp_MemberLastestConversion

	RESULT:		

	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1	2024-04-03		alejandramed		Initial  
	
	***********************************************************************************************************************************/

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
	
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY

	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END

	IF @IsDevQA = 0
	BEGIN
		DROP TABLE IF EXISTS [tmp].[MemberLastestConversion]

		CREATE TABLE [tmp].[MemberLastestConversion]
		(
			[PK_Event] INT, 
			[CreatedUTCDate] DATETIME DEFAULT GETUTCDATE(),
			[PK_Distributor] INT,
			LastDSConversionMonth INT,
			LastPMConversionMonth INT,
			LatestConversionMonth INT,
			LatestConversionType VARCHAR(10)
		)						 
	END
	ELSE IF @IsDevQA = 3
	BEGIN
	 	DROP TABLE IF EXISTS ##tmp_MemberLastestConversion

		CREATE TABLE ##tmp_MemberLastestConversion
		(
			[PK_Event] INT, 
			[CreatedUTCDate] DATETIME DEFAULT GETUTCDATE(),
			[PK_Distributor] INT,
			LastDSConversionMonth INT,
			LastPMConversionMonth INT,
			LatestConversionMonth INT,
			LatestConversionType VARCHAR(10)
		)
	END

	
	
	IF @IsDevQA = 0
	BEGIN

		;WITH cte_latest_dimMemberConversion AS
		( 
			SELECT  DISTINCT 
				M.PK_Distributor
				,M.ROYALTYMONTH  
				,CONVERSIONDATEGMT
				,CONVERSIONDATELOCAL  
				,M.ROYALTYMONTH  AS ConversionMonth  
				,ISLATEST
				,CONVERSIONTYPE
				,ROW_NUMBER() OVER (PARTITION BY M.PK_DISTRIBUTOR ORDER BY M.ROYALTYMONTH DESC,M.CONVERSIONDATELOCAL DESC) AS [Sort]
				,CREATEDDATESRC
			FROM PubEvents.dbo.dimMemberConversion AS M WITH (NOLOCK) 
			INNER JOIN [tmp].[DSForConversionEvaluation] AS L WITH (NOLOCK)
				ON L.PK_Distributor = M.PK_DISTRIBUTOR
			WHERE  ISLATEST = 1
			AND CONVERSIONTYPE  IN ('DStoMB','MBToDS')
		)
		,cte_dimMemberConversion_DStoMB AS
		( 
			SELECT  DISTINCT 
				M.PK_Distributor
				,M.ROYALTYMONTH  
				,CONVERSIONDATEGMT
				,CONVERSIONDATELOCAL  
				,M.ROYALTYMONTH  AS ConversionMonth  
				,ISLATEST
				,CONVERSIONTYPE
				,ROW_NUMBER() OVER (PARTITION BY M.PK_DISTRIBUTOR ORDER BY M.ROYALTYMONTH DESC,M.CONVERSIONDATELOCAL DESC) AS [Sort]
				,CREATEDDATESRC
			FROM [PubEvents].[dbo].[dimMemberConversion] AS M WITH (NOLOCK) 
			INNER JOIN [tmp].[DSForConversionEvaluation] AS L WITH (NOLOCK)
				ON L.PK_Distributor = M.PK_DISTRIBUTOR
			WHERE  ISLATEST = 1
			AND CONVERSIONTYPE = 'DStoMB' 
		),cte_dimMemberConversion_MBToDS AS
		( 
			SELECT  DISTINCT 
				M.PK_Distributor
				,M.ROYALTYMONTH  
				,CONVERSIONDATEGMT
				,CONVERSIONDATELOCAL  
				,M.ROYALTYMONTH  AS ConversionMonth  
				,ISLATEST
				,CONVERSIONTYPE
				,ROW_NUMBER() OVER (PARTITION BY M.PK_DISTRIBUTOR ORDER BY M.ROYALTYMONTH DESC,M.CONVERSIONDATELOCAL DESC) AS [Sort]
				,CREATEDDATESRC
			FROM [PubEvents].[dbo].[dimMemberConversion] AS M WITH (NOLOCK) 
			INNER JOIN [tmp].[DSForConversionEvaluation] AS L WITH (NOLOCK)
				ON L.PK_Distributor = M.PK_DISTRIBUTOR
			WHERE  ISLATEST = 1
			AND CONVERSIONTYPE = 'MBToDS'
		)

		INSERT INTO [tmp].[MemberLastestConversion]([PK_Event],[PK_Distributor],[LastDSConversionMonth],[LastPMConversionMonth],[LatestConversionMonth],[LatestConversionType])
		SELECT 
			@PK_Event AS [PK_Event], 
			b.PK_Distributor,
			d.ConversionMonth AS LastDSConversionMonth,
			p.ConversionMonth AS LastPMConversionMonth,
			M.ConversionMonth AS LatestConversionMonth,
			M.CONVERSIONTYPE AS LatestConversionType 
		FROM [tmp].[DSForConversionEvaluation] AS b WITH (NOLOCK)
			LEFT JOIN cte_dimMemberConversion_MBToDS AS d
				ON b.PK_Distributor = d.PK_Distributor AND d.Sort = 1 
			LEFT JOIN cte_dimMemberConversion_DStoMB AS p 
				ON b.PK_Distributor = p.PK_Distributor AND p.Sort = 1
			LEFT JOIN cte_latest_dimMemberConversion AS M
				ON b.PK_Distributor = M.PK_Distributor AND M.Sort = 1
	END
	ELSE IF @IsDevQA = 3
	BEGIN

		;WITH cte_latest_dimMemberConversion AS
		( 
			SELECT  DISTINCT 
				M.PK_Distributor
				,M.ROYALTYMONTH  
				,CONVERSIONDATEGMT
				,CONVERSIONDATELOCAL  
				,M.ROYALTYMONTH  AS ConversionMonth  
				,ISLATEST
				,CONVERSIONTYPE
				,ROW_NUMBER() OVER (PARTITION BY M.PK_DISTRIBUTOR ORDER BY M.ROYALTYMONTH DESC,M.CONVERSIONDATELOCAL DESC) AS [Sort]
				,CREATEDDATESRC
			FROM PubEvents.dbo.dimMemberConversion AS M WITH (NOLOCK) 
			INNER JOIN ##tmp_DSForConversionEvaluation AS L WITH (NOLOCK)
				ON L.PK_Distributor = M.PK_DISTRIBUTOR
			WHERE  ISLATEST = 1
			AND CONVERSIONTYPE  IN ('DStoMB','MBToDS')
		)
		,cte_dimMemberConversion_DStoMB AS
		( 
			SELECT  DISTINCT 
				M.PK_Distributor
				,M.ROYALTYMONTH  
				,CONVERSIONDATEGMT
				,CONVERSIONDATELOCAL  
				,M.ROYALTYMONTH  AS ConversionMonth  
				,ISLATEST
				,CONVERSIONTYPE
				,ROW_NUMBER() OVER (PARTITION BY M.PK_DISTRIBUTOR ORDER BY M.ROYALTYMONTH DESC,M.CONVERSIONDATELOCAL DESC) AS [Sort]
				,CREATEDDATESRC
			FROM [PubEvents].[dbo].[dimMemberConversion] AS M WITH (NOLOCK) 
			INNER JOIN ##tmp_DSForConversionEvaluation AS L WITH (NOLOCK)
				ON L.PK_Distributor = M.PK_DISTRIBUTOR
			WHERE  ISLATEST = 1
			AND CONVERSIONTYPE = 'DStoMB' 
		),cte_dimMemberConversion_MBToDS AS
		( 
			SELECT  DISTINCT 
				M.PK_Distributor
				,M.ROYALTYMONTH  
				,CONVERSIONDATEGMT
				,CONVERSIONDATELOCAL  
				,M.ROYALTYMONTH  AS ConversionMonth  
				,ISLATEST
				,CONVERSIONTYPE
				,ROW_NUMBER() OVER (PARTITION BY M.PK_DISTRIBUTOR ORDER BY M.ROYALTYMONTH DESC,M.CONVERSIONDATELOCAL DESC) AS [Sort]
				,CREATEDDATESRC
			FROM [PubEvents].[dbo].[dimMemberConversion] AS M WITH (NOLOCK) 
			INNER JOIN ##tmp_DSForConversionEvaluation AS L WITH (NOLOCK)
				ON L.PK_Distributor = M.PK_DISTRIBUTOR
			WHERE  ISLATEST = 1
			AND CONVERSIONTYPE = 'MBToDS'
		)

		INSERT INTO ##tmp_MemberLastestConversion([PK_Event],[PK_Distributor],[LastDSConversionMonth],[LastPMConversionMonth],[LatestConversionMonth],[LatestConversionType])
		SELECT 
			@PK_Event AS [PK_Event], 
			b.PK_Distributor,
			d.ConversionMonth AS LastDSConversionMonth,
			p.ConversionMonth AS LastPMConversionMonth,
			M.ConversionMonth AS LatestConversionMonth,
			M.CONVERSIONTYPE AS LatestConversionType 
		FROM ##tmp_DSForConversionEvaluation AS b
			LEFT JOIN cte_dimMemberConversion_MBToDS AS d
				ON b.PK_Distributor = d.PK_Distributor AND d.Sort = 1 
			LEFT JOIN cte_dimMemberConversion_DStoMB AS p 
				ON b.PK_Distributor = p.PK_Distributor AND p.Sort = 1
			LEFT JOIN cte_latest_dimMemberConversion AS M
				ON b.PK_Distributor = M.PK_Distributor AND M.Sort = 1
	END

	/******************************************************************************
					END PROCEDURE
	******************************************************************************/
		IF @IsDevQA = 0
		BEGIN
			-- Update processing Log
			EXEC [dbo].[usp_Utility_UpdateProcessingLog]
					@StoredProcedureName = @StoredProcedure
					,@StoredProcedureParameters = 'Completed'
					,@StartTime = @StartTime;
		END
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		IF @IsDevQA = 0
		BEGIN
			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
		END

	END CATCH;
END;
				