CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_HerbalifeHonors_Mar2025]
	-- Mandatory parameters
	@PK_Event INT = 200446,
	@DistributorID VARCHAR(10),
	@LocaleCode VARCHAR(10) = ''
	
	-- Optional Parameters
	,@CurrentDate DATE = NULL
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_MyHLEventAPI_CustomTrackingPage_HerbalifeHonors_Mar2025]
	
	USE:			
			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC	[dbo].[usp_MyHLEventAPI_CustomTrackingPage_HerbalifeHonors_Mar2025]
					@PK_Event = 200446,
					@DistributorID = N'111302303',
					@Error = @Error OUTPUT,
					@ErrorMessage = @ErrorMessage OUTPUT

			SELECT	@Error as N'@Error',
					@ErrorMessage as N'@ErrorMessage'

			GO

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2024-09-10		alejandramed		Initial
	1.0.1		2025-02-13		alejandramed		User Story 1403292: 25010 - Herbalife Honors Mar 12-15 2025 - BRD V4
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	DECLARE @Potentials_Commitment_Date DATE = NULL

	IF @CurrentDate IS NULL
		SET @CurrentDate = GETUTCDATE();


	DECLARE	@BeginDate	DATETIME  
			,@EndDate DATETIME	
	  
	SELECT @BeginDate = '2024-03-01'
	SELECT @EndDate = '2025-01-01'

BEGIN TRY

		IF (@IsDevQA = 2) THROW 60000, N'Unit test Error', 1;
  
		DECLARE @PK_Distributor INT = (SELECT nDistributorID FROM v_Distributor WHERE sDistributorID = @DistributorID)

		SELECT Q.PK_Distributor
			,D.sDistributorID
			,D.sType
			,D.sTeam
			,D.sSubTeam
			,Q.Q01			
			,Q.Q02			
			,Q.Q03			
			,Q.Q04			
			,Q.Q05			
			,Q.Q06			
			,Q.Q07			
			,Q.Q08			
			,Q.Q09			
			,Q.Q10			
			,Q.Q11			
			,Q.Q12			
			,Q.Q13			
			,Q.Q14			
			,Q.Q15			
			,Q.Q16			
			,Q.Q17			
			,Q.Q18			
			,Q.Q19			
			,Q.Q20			
			,Q.Q21			
			,Q.Q22			
			,Q.Q23			
			,Q.Q24			
			,Q.Q25			
			,Q.Q26			
			,Q.Q27			
			,Q.Q28	
			,Q.Q29			
			,Q.Q31			
			,Q.Q32			
			,Q.Q33					
			,Q.E01			
			,Q.E02			
			,Q.E03			
			,Q.E04			
			,Q.E05			
			,Q.E06			
			,Q.E07			
			,Q.E08			
			,Q.E09			
			,Q.E10	
			,Q.E11	
			,Q.E12	
			,Q.E13	
			,Q.E14	
			,Q.E15	
			,Q.E16	
			,Q.E17	
			,Q.E18	
			,Q.E19	
			,Q.E20	
			,Q.E21	
			,Q.E22	
			,Q.E23	
			,Q.E24
			,Q.E26
			,Q.E27
		FROM [Event].[DSQual] AS Q WITH (NOLOCK)
		INNER JOIN v_Distributor AS D
			ON Q.PK_Distributor = D.nDistributorID
		WHERE @LocaleCode IS NOT NULL AND D.sDistributorID = @DistributorID AND Q.PK_Event = @PK_Event


	 	DROP TABLE IF EXISTS #Periods 

		SELECT 
		@PK_Distributor AS [PK_Distributor],
		CAST(CONVERT(varchar(6), SD.MyDate, 112) AS int) AS [iMonth], 
		SD.MyDate  AS [dMonth]
		INTO #Periods
		FROM dbo.SourceDate AS SD WITH (NOLOCK) 
		WHERE SD.MyDate BETWEEN @BeginDate AND @EndDate

		DROP TABLE IF EXISTS #IndVolume

		SELECT 
			p.PK_Distributor AS PK_Distributor,
			p.dMonth AS RoyaltyMonth,
			ISNULL(Q.mRoyaltyOverrides,0) AS Points
		INTO #IndVolume
		FROM  #Periods AS p
		LEFT JOIN [Shared].[DistributorAssociation] AS a WITH (NOLOCK)
			ON p.PK_Distributor = a.PK_Distributor
		LEFT JOIN  
			dbo.v_aggFQS_ID Q
			ON 
				p.PK_Distributor = Q.nDistributorID
				AND Q.dRoyaltyMonth  = p.dMonth
		
		DROP TABLE IF EXISTS #MainVolume

		SELECT 
		p.PK_Distributor AS PK_Distributor,
		p.dMonth AS RoyaltyMonth,
		ISNULL(Q.mRoyaltyOverrides,0) AS Points
		INTO #MainVolume
		FROM  #Periods AS p
		LEFT JOIN [Shared].[DistributorAssociation] AS a WITH (NOLOCK)
			ON p.PK_Distributor = a.PK_Distributor
		LEFT JOIN  
			dbo.v_aggFQS_ID Q
			ON 
				a.nMainDistributorID = Q.nDistributorID
				AND Q.dRoyaltyMonth  = p.dMonth

	SELECT      
		 i.PK_Distributor
		 ,i.RoyaltyMonth                      
		 ,ISNULL(i.Points,0) + ISNULL(m.Points,0) AS RO             
	  FROM #IndVolume AS i
		LEFT JOIN #MainVolume AS m
			ON i.PK_Distributor = m.PK_Distributor AND i.RoyaltyMonth = m.RoyaltyMonth
	 ORDER BY RoyaltyMonth DESC    


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
END;