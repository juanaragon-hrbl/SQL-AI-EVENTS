CREATE PROCEDURE [dbo].[usp_EventPromo_Downline_202468]
         @PK_Event INT
		,@DistributorID VARCHAR(20)							 
        ,@DSLevel udt_DSLevel READONLY
        -- Optional Parameters
        ,@SelectedCut INT = NULL
        ,@SelectedTarget INT = NULL
        ,@PageNumber INT = NULL
        ,@PageSize INT = 30
        -- Error Parameters
        ,@Error INT = 0 OUTPUT
        ,@ErrorMessage VARCHAR(4000) = '' OUTPUT
        -- QA/DEV
        ,@IsDevQA TINYINT = 0
		-- Optional
		,@BaselineMonth DATETIME2 = NULL
		,@CurrentDate	DATETIME2 = NULL						 
AS
BEGIN
/******************************************************************************
    OBJECT:         [dbo].[usp_EventPromo_Downline_202468]
    USE:
            DECLARE @e int, @em varchar(max)
                    ,@DSLevel dbo.udt_DSLevel
            ----INSERT INTO @DSLevel VALUES (1), (2), (3)
			
            EXEC [dbo].[usp_EventPromo_Downline_202468]
				 @PK_Event = 202468
				,@DistributorID = '2222222222'--'40129530'
                ,@DSLevel = @DSLevel
                ,@SelectedCut = 1
                ,@SelectedTarget = 1
                ,@PageNumber = 1
                ,@PageSize = 100
                ,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 0
    
			SELECT @e AS [Error], @em AS [Error Message]
    
	DESCRIPTION:
    NOTES:
    DEPENDENCIES	
    --------------------------------------------------------------------
    VERSIONS
    --------------------------------------------------------------------
    1.0.0       2025-02-24      rosarioo       Initial
******************************************************************************/

    SET NOCOUNT ON
    
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
				,@Param varchar(100) = CONVERT(VARCHAR,@PK_Event)
	DECLARE @StartTime datetime = GETUTCDATE()
    
    BEGIN TRY
	
		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END

        -- Calculate pages for return set
		DECLARE  @ReturnAll 	BIT = CASE WHEN @PageNumber IS NULL THEN 1 ELSE 0 END
				,@Offset 		INT = (@PageNumber - 1) * @PageSize
				,@Levels 		INT = (SELECT ISNULL(COUNT(*), 0) FROM @DSLevel)					-- Check if there are DS level filters
				,@FirstHLDate 	INT = 19000101
				,@ShowQualifiedOnly BIT = 0
				,@PeriodStart  DATETIME2 = (SELECT QualPeriodStart FROM dbo.[Event] WITH (NOLOCK) WHERE PK_Event = @PK_Event )
			    ,@PeriodEnd    DATETIME2 = (SELECT QualPeriodEnd FROM dbo.[Event] WITH (NOLOCK) WHERE PK_Event = @PK_Event )
				,@SQL			NVARCHAR(MAX) = ''
				-- Custom Promo.Options
				--Custom dbo.EventPromoTemplate
				,@DisplayConsecutiveMonths TINYINT = ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'DisplayConsecutiveMonths' AND [Group] = 'downline' AND IsActive = 1),0)
				,@ConsecutiveMonths int = (SELECT DISTINCT TOP 1 t.ConsecutiveMonths FROM [Promo].[TargetMetrics] AS t WITH (NOLOCK) WHERE [PK_Event] = @PK_Event AND RIGHT(t.TargetName,1) = @SelectedTarget)

		SELECT @CurrentDate  = CONVERT(DATE,ISNULL(@CurrentDate ,GETUTCDATE()))							 	--US 720693
			  ,@ConsecutiveMonths = ISNULL(@ConsecutiveMonths,DATEDIFF(MONTH,@PeriodStart,@PeriodEnd))

		
		IF(@CurrentDate  > @PeriodEnd)
		BEGIN	SET @ShowQualifiedOnly = 1	END

		IF @DisplayConsecutiveMonths = 1
		BEGIN
			SELECT   @PeriodStart = CASE WHEN @CurrentDate>@PeriodEnd THEN DATEADD(MONTH,-(@ConsecutiveMonths-1),CONVERT(DATE,@PeriodEnd)) ELSE DATEADD(MONTH,-(@ConsecutiveMonths-1),CONVERT(DATE,@CurrentDate)) END
					,@PeriodEnd = CASE WHEN @CurrentDate>@PeriodEnd THEN @PeriodEnd ELSE @CurrentDate END
		END

         --First ResultSet  
        SELECT DISTINCT
                 MainMetric
                ,TeamLevelTarget
				,MetricValues
                ,COP
                ,BaseLine
                ,DateStart
				,TargetType----1.1.9
				,ConsecutiveMonths----1.1.9						
            FROM Promo.TargetMetrics WITH (NOLOCK)
			WHERE PK_Event = @PK_Event
            ORDER BY COP
	
        -- Base data set
		DROP TABLE IF EXISTS #Potential_Downlines;
		
        SELECT   D.ULDistributorID
				,D.PK_Distributor
                ,D.DLDistributorID
				,D.PK_DSDownline AS PK_DLDistributor
                ,D.DSLevelFromUL
		INTO #Potential_Downlines
		FROM PubEvents.dbo.dimDSLngDownline_wBlock D WITH (NOLOCK)
		INNER JOIN Promo.EventDistributor E WITH (NOLOCK)
			ON E.PK_Distributor = D.PK_DSDownline
			AND E.PK_Event = @PK_Event
			AND E.AsDownline = 1				
		WHERE D.ULDistributorID = @DistributorID
		AND (@Levels = 0 OR D.DSLevelFromUL IN (SELECT DSLevel + 1 FROM @DSLevel))
		AND D.DSLevelFromUL > 1
   
		CREATE INDEX IX_#Potential_Downlines_PK ON #Potential_Downlines(PK_Distributor, PK_DLDistributor)



		-- 1.1.1 Rebuilt #MainSet creation
		DROP TABLE IF EXISTS #MainSet	

		CREATE TABLE #MainSet (
				 PK_Distributor			BIGINT
                ,DistributorID			VARCHAR(39)
                ,PK_Sponsor				BIGINT
                ,SponsorID				VARCHAR(30)
                ,ApplicationDate		INT
                ,dApplicationDate		DATETIME2
                ,SPQualDate				INT
                ,QPQualDate				INT
                ,QSQualDate				INT
                ,TypeCode				VARCHAR(5)
                ,SubTypeCode			VARCHAR(5)
                ,FirstName				NVARCHAR(150)
                ,LastName				NVARCHAR(150)
                ,AppDate				INT
                ,ContractAcceptanceDate	INT
                ,Email					VARCHAR(250)
                ,Phone					VARCHAR(200)
                ,Team					VARCHAR(100)
                ,COP					VARCHAR(4)
                ,COPISO					VARCHAR(4)
                ,IsInactive				BIT
                ,VolumeNeeded			DECIMAL(12,2)
                ,TeamLevelTarget		VARCHAR(20)
				,DistributorName		NVARCHAR(301)
                ,SponsorName			NVARCHAR(300)
                ,FirstUplineTABId		VARCHAR(30)
                ,FirstUplineTABName		NVARCHAR(300)
				,FirstUplinePTId		VARCHAR(30)
				,FirstUplinePTName		NVARCHAR(300)
				,sUplineSPID			VARCHAR(30)
				,FirstUplineSPName		NVARCHAR(150)
				,CurrentCut				INT
                ,DSLevel				INT
				,[Level]				INT
				,DateQualified			DATETIME2
				,RecognitionMonth		DATETIME2
			    ,Qualified				BIT
				,LastOrder 				INT	
				,InitialAppDate			INT
				,dInitialAppDate		DATETIME2
				,TotalTickets			int
		)
		

		         INSERT INTO #MainSet
				 SELECT  D.PK_Distributor, D.DistributorID, D.PK_Sponsor, D.SponsorID, D.ApplicationDate, D.dApplicationDate, D.SPQualDate, D.QPQualDate
						,D.QSQualDate, D.TypeCode, D.SubTypeCode, D.FirstName, D.LastName, D.ApplicationDate AS AppDate, D.ContractAcceptanceDate, D.Email
						,D.Phone
						,(CASE WHEN D.PK_DSType IN (6,7) THEN (SELECT LOWER(LEFT([SubTypeDesc], charindex(' ', [SubTypeDesc]) - 1)) FROM [PubEvents].[dbo].[dimDSSubType] WITH (NOLOCK) WHERE [SubTypeCode] = d.[Team]) ELSE D.[Team] END) AS [Team]
						,D.COP, D.COPISO, 0 AS IsInactive
						--,(SELECT DISTINCT TOP 1 ISNULL(CAST(LEFT([MetricValues], ISNULL(CASE WHEN CHARINDEX(',', [MetricValues]) = 0 THEN LEN([MetricValues]) ELSE CHARINDEX(',', [MetricValues]) - 1 END, 0)) AS decimal(12,2)), 0)
						--	FROM [Promo].[TargetMetrics] AS t WITH (NOLOCK)
						--	WHERE t.[COP] LIKE '%' + d.[COP] + '%'
						--	AND [PK_Event] = @PK_Event
						--	AND RIGHT(t.TargetName,1) = @SelectedTarget			-- VolumeNeeded according to SelectedTarget	  
						--	AND ISNULL(T.IsMain,1) = 1
						--)  AS VolumeNeeded
						,NULL AS VolumeNeeded
						,CASE WHEN ISNULL(D.[SPQualDate], @FirstHLDate) != @FirstHLDate THEN 'FQS' ELSE 'NONFQS' END AS [TeamLevelTarget]
						,ISNULL(D.[FirstName] + ' ', '') + ISNULL(D.[LastName], '') AS [DistributorName]
						,D.[SponsorName]
						,D.[sUplineTABID] AS [FirstUplineTABId]
						,ISNULL(D.[sUplineTABFirstName] + ' ', '') + ISNULL(D.[sUplineTABLastName], '') AS [FirstUplineTABName]
						,D.[sUplinePresID] AS [FirstUplinePTId]
						,ISNULL(D.[sUplinePresFirstName] + ' ', '') + ISNULL(D.[sUplinePresLastName], '') AS [FirstUplinePTName]
						,D.[sUplineSPID]
						,ISNULL(D.[sUplineSPFirstName] + ' ', '') + ISNULL(D.[sUplineSPLastName], '') AS [FirstUplineSPName]
						,NULL--DC.Cut AS CurrentCut
						,(dc.[DSLevelFromUL] - 1) AS [DSLevel]
						,(dc.[DSLevelFromUL] - 1) AS [Level]
						,NULL--CAST(CAST(E.DateQualified * 100 + 1 AS VARCHAR(8)) AS DATETIME2) AS [DateQualified]
						,NULL--,DATEADD(MONTH, 1, CAST(CAST(E.DateQualified  * 100 + 1 AS VARCHAR(8)) AS DATETIME2)) AS [RecognitionMonth]
						,NULL--IIF(E.DateQualified IS NOT NULL, 1, 0) AS [Qualified]
						,CAST(NULL AS INT) AS LastOrder 	
						,ISNULL(d.InitialAppDate,(CASE WHEN (MBApplicationDate IS NOT NULL AND MBApplicationDate <> 19000101 AND MBApplicationDate <  APPLICATIONDATE) OR APPLICATIONDATE = 19000101
						THEN MBApplicationDate ELSE APPLICATIONDATE END)) AS InitialAppDate ----1.4.0
						,ISNULL(d.dInitialAppDate,(CASE WHEN (MBApplicationDate IS NOT NULL AND MBApplicationDate <> 19000101 AND MBApplicationDate <  APPLICATIONDATE) OR APPLICATIONDATE = 19000101
						THEN dMBApplicationDate ELSE dApplicationDate END)) AS dInitialAppDate----1.4.0
						,0 AS TotalTickets
				FROM #Potential_Downlines AS DC 
				INNER JOIN Promo.dimDistributor AS D WITH (NOLOCK) 
					ON D.PK_Distributor = DC.PK_DLDistributor
		      
		
		CREATE INDEX IX_#MainSet_PK ON #MainSet(PK_Distributor)


		DROP TABLE IF EXISTS #ResultSet

		SELECT  M.PK_Distributor, M.DistributorID, M.PK_Sponsor, M.SponsorID, M.ApplicationDate, M.dApplicationDate, M.SPQualDate, M.QPQualDate
				,M.QSQualDate, M.TypeCode, M.SubTypeCode, M.FirstName, M.LastName, M.AppDate, M.ContractAcceptanceDate, M.Email, M.Phone, M.Team
				,M.COP, M.COPISO, M.IsInactive, M.VolumeNeeded, M.CurrentCut, M.DSLevel, M.TeamLevelTarget, M.DateQualified, M.RecognitionMonth
				,M.[Level], M.DistributorName, M.SponsorName, M.FirstUplineTABId, M.FirstUplineTABName, M.FirstUplinePTId, M.FirstUplinePTName
				,M.Qualified, M.sUplineSPID, M.FirstUplineSPName,M.LastOrder,M.InitialAppDate,M.dInitialAppDate,M.TotalTickets
		INTO #ResultSet
		FROM #MainSet M
		WHERE ( (@ShowQualifiedOnly = 1 AND M.[Qualified] =1) OR @ShowQualifiedOnly = 0 )

		CREATE INDEX IX_#ResultSet_PK_Distributor ON #ResultSet(PK_Distributor)

	------------------------------------------------------------------------------------------------------------------------
	-- Add Total Tickets
	
	   ;WITH DSTickets AS (
	   SELECT 
			S.PK_Distributor,SUM(S.QtyTickets) AS Qty_Tickets
	   FROM Promo.WRK_NAM_Sweepstakes2025_DSSubEvent AS S (NOLOCK) 
	   INNER JOIN #ResultSet AS R
	   ON R.PK_Distributor = S.PK_Distributor
	   GROUP BY S.PK_Distributor
	   )
	   UPDATE R SET 
	   R.TotalTickets = T.Qty_Tickets
	   FROM DSTickets AS T
	   INNER JOIN #ResultSet AS R
	   ON T.PK_Distributor = R.PK_Distributor


	------------------------------------------------------------------------------------------------------------------------
	-- Add Volume Points	 -- 1.2.0

		-- Page data
		DECLARE @TotalRows int;

        SELECT  @TotalRows = COUNT(*)
        FROM #ResultSet
		
		--Second ResultSet
		SELECT   @PageNumber AS [PageNumber]
                ,@PageSize AS [PageSize]
                ,@TotalRows AS [TotalRows];


		-- Third ResultSet
      SET @SQL =  ' SELECT   PK_Distributor, DistributorID, PK_Sponsor, SponsorID, ApplicationDate, dApplicationDate, SPQualDate, QPQualDate, QSQualDate, TypeCode
				,SubTypeCode, FirstName, LastName, AppDate, ContractAcceptanceDate, Email, Phone, Team, COP, COPISO, IsInactive, LastOrder, VolumeNeeded
				,TotalTickets,CurrentCut, DSLevel, TeamLevelTarget,  DistributorName,SponsorName, FirstUplineTABId, FirstUplineTABName, FirstUplinePTId, FirstUplinePTName
				,Qualified, DateQualified, RecognitionMonth, [Level], sUplineSPID, FirstUplineSPName, InitialAppDate, dInitialAppDate
        FROM #ResultSet AS R
		ORDER BY [TotalTickets] DESC
		--ORDER BY [DistributorID]
		 OFFSET '+CONVERT(VARCHAR,ISNULL(@Offset, 0))+' ROWS
         FETCH FIRST (CASE WHEN '+CONVERT(VARCHAR,@ReturnAll)+' = 1 THEN (CASE WHEN '+CONVERT(VARCHAR,@TotalRows)+' = 0 THEN 1 ELSE '+CONVERT(VARCHAR,@TotalRows)+' END) ELSE '+CONVERT(VARCHAR,@PageSize)+' END) ROWS ONLY;
     '       
	 EXEC(@SQL)
            
	 -- Fourth ResultSet   
	 SELECT   [Key]
	 		,[Value]
	 FROM [Promo].[Options] WITH (NOLOCK)
	 WHERE [PK_Event] = @PK_Event AND [Group] = 'downline'	
			
 
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
	
	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StoredProcedureParameters = @Param
	,@StartTime = @StartTime	
	
END
GO


