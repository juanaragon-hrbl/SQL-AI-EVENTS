CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_Mexico_GetawayVacation_2026]
	-- Mandatory parameters
	 @PK_Event INT = 202724
	,@LocaleCode CHAR(5)

	-- Optional Parameters
	,@DistributorID VARCHAR(10)

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_Mexico_GetawayVacation_2026

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_Mexico_GetawayVacation_2026
					 	 @DistributorID = N'11380475'
					 	,@PK_Event = 202724
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2025-02-04		juangue		Intitial
2	2025-05-19		juangue		E1 and E2 added to the result
3	2025-06-18		juangue		Getting the right contributors targeting Q9 (downlines valid points) 
4	2026-07-13		rosarioo	Bug 1476123: PROD PK_202724 - 26002 - Mexico Getaway Vacation 2026 - ID 115055965 incorrectly qualified to level 1
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	/* DECLARE THE REQUIRED VARIABLES */
	
	DECLARE @PK_Distributor INT
	DECLARE @PK_Locale INT
	DECLARE @PK_DefaultLocale INT

BEGIN TRY

		--New FQS
		DECLARE @MonthsAsFQS INT = 11
		
		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

----------------------------------------------------------------------------------------------------

	DECLARE 
				@iStartDate int,
				@dStartDate datetime,
				@iEndDate int,
				@dEndDate datetime
	 
			
			DROP TABLE IF EXISTS #DSDetails

			CREATE TABLE #DSDetails      
			(      
					 PK_Distributor		INT
					,DistributorID		VARCHAR(10)
					,DSCurrentTeam		varchar(10)        
					,DSSubTeam			varchar(10)       
					,DSSPTeam			varchar(10) 
					,sCountryCode		CHAR(5)
					,dSPQualDate		DATETIME
					,Q01				BIT DEFAULT 0
					,Q02				BIT DEFAULT 0
					,Q03				BIT DEFAULT 0
					,Q04				BIT DEFAULT 0
					,Q05				BIT DEFAULT 0
					,Q06				BIT DEFAULT 0
					,Q07				BIT DEFAULT 0
					,Q08				BIT DEFAULT 0
					,Q09				BIT DEFAULT 0	
					,E01				BIT DEFAULT 0
					,E02				BIT DEFAULT 0					
			)  
			
			DROP TABLE IF EXISTS #DS

			CREATE TABLE #DS
			(
				PK_Distributor		int,   
				DSCurrentTeam		varchar(10),        
				DSSubTeam			varchar(10),        
				DSSPTeam			varchar(10),               
				dSPQualDate			datetime2,        
				CountryCode			varchar(5),
				IsFromList			bit default(0),
				IsTicketPurchaser	bit default(0)
			)

			--DS 
			INSERT INTO #DS
			(
				PK_Distributor,	
				DSCurrentTeam,	
				DSSubTeam,		
				DSSPTeam,			
				dSPQualDate,		
				CountryCode
			)
			SELECT DISTINCT        
			D.nDistributorID AS PK_Distributor,   
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
			D.sSubteam AS DSSubTeam,        
			D.sType AS DSSPTeam,            
			D.dSupervisorqualification AS dSPQualDate,        
			D.sDistributorCountryProcessingCode AS CountryCode
			FROM        
			dbo.v_Distributor AS D  
			WHERE        
				D.sDistributorID = @DistributorID

			IF @IsDevQA > 0  SELECT PK_Distributor,	DSCurrentTeam, DSSubTeam, DSSPTeam, dSPQualDate, CountryCode FROM #DS

			--DS Period
			SELECT 
				@iStartDate = CAST(CONVERT(varchar(6),dSPQualDate, 112) AS int), 
				@dStartDate = dSPQualDate,
				@iEndDate = CAST(CONVERT(varchar(6),DATEADD(MM,@MonthsAsFQS,dSPQualDate), 112) AS int),
				@dEndDate = DATEADD(MM,@MonthsAsFQS,dSPQualDate)
			FROM #DS
	 
			IF @IsDevQA > 0  SELECT @iStartDate AS [@iStartDate],@dStartDate AS [@dStartDate],@iEndDate AS [@iEndDate],@dEndDate AS [@dEndDate]
				
			DROP TABLE IF EXISTS #DSMonths

			SELECT 
				@PK_Distributor AS [PK_Distributor],
				@PK_Event AS [PK_Event],
				CAST(CONVERT(varchar(6), SD.MyDate, 112) AS int) AS [iMonth],
				SD.MyDate AS [dMonth]
			INTO #DSMonths
			FROM dbo.SourceDate AS SD WITH (NOLOCK) 
			WHERE SD.MyDate BETWEEN @dStartDate AND @dEndDate

			-- DS Volume
			DROP TABLE IF EXISTS #DSVolume

			CREATE TABLE #DSVolume
			(
				PK_Distributor INT,
				RoyaltyMonth DATETIME,
				TVP MONEY
			)
			
			;WITH cte_TV AS
			(				
				SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
				FROM [Event].[DSPoints] AS P WITH(NOLOCK) 
				WHERE P.MetricType = 'TV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
				GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
			)
			 
			INSERT INTO #DSVolume([PK_Distributor],[RoyaltyMonth],[TVP])
				SELECT 
					D.[PK_Distributor],
					D.dMonth AS [RoyaltyMonth],
					ISNULL(IIF(TV.Points < 0,0, ROUND(TV.Points,2)),0) AS [TVP]					 
				FROM #DSMonths AS D
				LEFT JOIN cte_TV AS TV
					ON D.PK_Distributor = TV.PK_Distributor AND TV.RoyaltyMonth = D.iMonth	

			--DS Quals
			;WITH 
				cte_Quals AS (
						SELECT Q.PK_Distributor,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,E01,E02
							FROM   [Event].[DSQual] AS Q WITH (NOLOCK)
							WHERE Q.PK_Event = @PK_Event AND Q.PK_Distributor = @PK_Distributor 
					)
				
				INSERT INTO #DSDetails([PK_Distributor],[DistributorID],[DSCurrentTeam],[DSSubTeam],[DSSPTeam],[sCountryCode],[dSPQualDate],Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,E01,E02)
				SELECT  
				D.PK_Distributor AS [PK_Distributor],
				@DistributorID AS [DistributorID],							
				D.[DSCurrentTeam],
				D.[DSSubTeam],
				D.[DSSPTeam],
				D.CountryCode AS [sCountryCode],
				D.dSPQualDate,
				IIF(Q.Q01 = 1,1,0) AS [Q1],
				IIF(Q.Q02 = 1,1,0) AS [Q2],
				IIF(Q.Q03 = 1,1,0) AS [Q3],
				IIF(Q.Q04 = 1,1,0) AS [Q4],
				IIF(Q.Q05 = 1,1,0) AS [Q5],
				IIF(Q.Q06 = 1,1,0) AS [Q6],
				IIF(Q.Q07 = 1,1,0) AS [Q7], -- 4 -- PROD Bug 1476123
				IIF(Q.Q08 = 1,1,0) AS [Q8],
				IIF(Q.E01 = 1,1,0) AS [E1],
				IIF(Q.E02 = 1,1,0) AS [E2]
				FROM  #DS AS D
					INNER JOIN cte_Quals AS Q
						ON D.PK_Distributor = Q.PK_Distributor	

			--Downlines
			DROP TABLE IF EXISTS #1LDownlines;

			SELECT 
				M.PK_Distributor,
				DL.PK_DSDownline [PK_FirstLine],
				D.dApplication AS [AppDate]
			INTO #1LDownlines
			FROM
				#DS M
			INNER JOIN
				dbo.v_dimDSLngDownline DL WITH (NOLOCK)
			ON
				M.PK_Distributor = DL.PK_Distributor
				AND 
				DL.DSLevelFromUL = 2
			INNER JOIN v_Distributor AS D
				ON DL.PK_DSDownline = D.nDistributorID 
			WHERE d.dApplication BETWEEN M.dSPQualDate AND DATEADD(MM,@MonthsAsFQS,M.dSPQualDate)

			CREATE CLUSTERED INDEX [IX_#1LDownlines_PK_FirstLine] ON #1LDownlines ([PK_FirstLine])
					   			 
			-- Downline Volume 
			DROP TABLE IF EXISTS #Event_DSPoints_Validations

			CREATE TABLE #Event_DSPoints_Validations
			(
				[PK_Distributor] [int] NULL,
				[PK_Event] [int] NULL,
				[PK_Country] [int] NULL,
				[RoyaltyMonth] [int] NULL,
				[MetricType] [varchar](20) NULL,
				[PersonalPoints] [money] NULL DEFAULT(0),
				[TransferPoints] [money] NULL DEFAULT(0),
				[MainPoints] [money] NULL DEFAULT(0),
				[Points] [money] NULL DEFAULT(0),
				[Bonus] [money] NULL DEFAULT(0)
			)

			DROP TABLE IF EXISTS #DLMonths 

			SELECT r.dDate,r.iDate,r.iMonth,r.dMonthStart,r.iMonthStart
			INTO #DLMonths
			FROM #1LDownlines AS d
			CROSS APPLY udf_MonthsRangeByInt(d.[AppDate], DATEDIFF(MM,d.[AppDate],DATEADD(MM,12,d.[AppDate])), 1) AS r
			WHERE d.AppDate = r.dDate

			;WITH cte_PPV AS 
			(
				SELECT 
					d.PK_FirstLine AS PK_Distributor,
					p.[PK_Event],
					p.PK_Country,
					p.[RoyaltyMonth],
					p.MetricType,
					p.[PersonalPoints] AS [PersonalPoints],
					p.[TransferPoints] AS [TransferPoints],
					p.[MainPoints] AS [MainPoints], 
					ROUND(p.[Points],2) AS [Points],
					p.Bonus
				FROM [Event].[DSPoints] AS p WITH (NOLOCK)
					INNER JOIN #1LDownlines AS d
						ON p.PK_Distributor = d.PK_FirstLine
				WHERE PK_Event = @PK_Event AND MetricType = 'PPV'
				),
				cte_DLV_PM AS
				(
				SELECT 
					d.PK_FirstLine AS PK_Distributor,
					p.[PK_Event],
					p.PK_Country,
					p.[RoyaltyMonth],
					p.MetricType,
					p.[PersonalPoints] AS [PersonalPoints],
					p.[TransferPoints] AS [TransferPoints],
					p.[MainPoints] AS [MainPoints], 
					ROUND(p.[Points],2) AS [Points],
					p.Bonus
				FROM [Event].[DSPoints] AS p WITH (NOLOCK)
					INNER JOIN #1LDownlines AS d
						ON p.PK_Distributor = d.PK_FirstLine
				WHERE PK_Event = @PK_Event AND MetricType = 'DLV_PM'
				), cte_DS AS 
				(
					SELECT PK_FirstLine AS PK_Distributor,@PK_Event AS [PK_Event],m.iMonth AS [RoyaltyMonth], 12 [PK_Country] FROM #1LDownlines
					CROSS APPLY #DLMonths AS m
				)
		 
			INSERT INTO #Event_DSPoints_Validations(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])		
			SELECT 
				d.PK_Distributor,
				d.[PK_Event],
				d.PK_Country AS PK_Country,
				d.RoyaltyMonth,
				'PPV,DLV_PM' AS MetricType,
				ISNULL(p.[PersonalPoints],0) + ISNULL(s.[PersonalPoints],0) AS [PersonalPoints],
				ISNULL(p.[TransferPoints],0) + ISNULL(s.[TransferPoints],0) AS [TransferPoints],
				ISNULL(p.[MainPoints],0) + ISNULL(s.[MainPoints],0) AS [MainPoints],
				ISNULL(p.[Points],0) + ISNULL(s.[Points],0) AS [Points],
				ISNULL(p.[Bonus],0) + ISNULL(s.[Bonus],0) AS [Bonus]
			FROM cte_DS AS d
			LEFT JOIN cte_PPV AS p
				ON p.PK_Distributor = d.PK_Distributor AND
				p.[PK_Event] = d.[PK_Event] AND
				p.[RoyaltyMonth] = d.[RoyaltyMonth] AND 
				p.PK_Country = d.PK_Country  
			LEFT JOIN cte_DLV_PM AS s
				ON s.PK_Distributor = d.PK_Distributor AND
				s.[PK_Event] = d.[PK_Event] AND	
				s.[RoyaltyMonth] = d.[RoyaltyMonth] AND 
				s.PK_Country = d.PK_Country  
						
			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_Validations_PK_Distributor] ON #Event_DSPoints_Validations ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_Validations_MetricType] ON #Event_DSPoints_Validations ([MetricType])
		 
			DROP TABLE IF EXISTS #DLVolume

			CREATE TABLE #DLVolume
			(
				PK_Distributor INT,
				RoyaltyMonth DATETIME,
				[PPV+DLV_PM] MONEY
			)
					
			INSERT INTO #DLVolume(PK_Distributor,RoyaltyMonth,[PPV+DLV_PM])		
			SELECT p.PK_Distributor,m.dDate AS [RoyaltyMonth],p.Points AS [PPV+DLV_PM] 
			FROM #Event_DSPoints_Validations AS p
				INNER JOIN #DLMonths AS m
					ON p.RoyaltyMonth = m.iMonth

			--Contributors
			DROP TABLE IF EXISTS #1LDownlines_Contributors

			SELECT Q.PK_Distributor
				INTO #1LDownlines_Contributors
			FROM #1LDownlines AS [L1]
				INNER JOIN [Event].[DSQualPoints] AS Q WITH(NOLOCK)
					ON [L1].PK_FirstLine = Q.PK_Distributor AND Q.PK_Event = @PK_Event
			WHERE (Q.QualificationNumber = 9 AND Q.Part = 1 ) AND EOMONTH(L1.AppDate) =EOMONTH (Q.QualDate)
							 
			--First result set: DS details
			SELECT  
				PK_Distributor	
				,DistributorID  
				,[DSCurrentTeam]
				,[DSSubTeam]
				,[DSSPTeam]
				,sCountryCode
				,dSPQualDate
				,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,E01,E02
			FROM #DSDetails

			--Second result set: DS volume
			SELECT 
				PK_Distributor
				,RoyaltyMonth
				,TVP				 
			FROM #DSVolume	 

			--Third result set: Potentials
			SELECT 
				PK_Distributor,
				PK_FirstLine,
				AppDate 
			FROM #1LDownlines
	
			--Forth reuslt set: DL Volume
			SELECT 
				PK_Distributor,
				RoyaltyMonth,
				[PPV+DLV_PM] 
			FROM #DLVolume	

			--Fifth result set: DL Contributors
			SELECT 
				PK_Distributor 
			FROM #1LDownlines_Contributors

	SET @Error = @Error + @@ERROR      
		
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
	END CATCH
END

