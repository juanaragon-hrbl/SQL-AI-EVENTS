CREATE PROCEDURE [dbo].[usp_Utility_QualByPointsMembersBulk]
		 @QualByPoints dbo.udt_QualByPoints READONLY 
		,@Error	INT = 0 OUTPUT
		,@ErrorMessage VARCHAR(4000) = NULL OUTPUT

		-- QA/DEV	
		,@IsDevQA BIT = 0        
AS     
BEGIN         
/* -----------------------------------------------------------------------------------------------------------------------------------------              
 OBJECT:   [dbo].[usp_Utility_QualByPointsMembersBulk]           
 USAGE:     

			--Requieres usp_Utility_GetPointsUnpivotByMembers execution first, WRK_MembersPoints table must exists

			DECLARE	@e INT,	@em VARCHAR(4000)

			DECLARE @QualByPoints dbo.udt_QualByPoints, @PK_Event INT = 71687

			INSERT INTO @QualByPoints(StartDate, EndDate, Frequency, Consecutive, Accumulated, MetricType, MinPoints, GoalPoints)
			VALUES
			('2019-07-01', '2020-02-01', 1, 0, 0, 'TV', 0, 2500),
			('2019-07-01', '2020-01-01', 4, 1, 0, 'TV', 0, 2500),
			('2019-07-01', '2020-02-01', 3, 1, 1, 'TV', 0, 4000),
			('2019-07-01', '2020-01-01', 1, 0, 0, 'RO', 0, 1000),
			('2019-07-01', '2020-02-01', 3, 1, 0, 'TV', 0, 2500),
			('2005-01-01', '2019-08-01', 3, 1, 0, 'TV', 0, 2500)

			EXEC	[dbo].[usp_Utility_QualByPointsMembersBulk]
			@QualByPoints = @QualByPoints,
			@Error = @e OUTPUT,
			@ErrorMessage = @em OUTPUT,
			@IsDevQA = NULL 
			
			-- Result dbo.WRK_QualifiersByPointsMetric table creation
              
 DESCRIPTION: Retrieves the distributors that accomplish with the qualifications by points         
              
 DEPENDENCIES              
 ---------------------------------------------------------------------------------------------------------------------------------------    
 User defined table type
	- udt_QualByPoints
	- MemberList       
	
Stored procedures
	- usp_Utility_GetPointsUnpivotByMembers   
               
 VERSIONS              
 ----------------------------------------------------------------------------------------------------------------------------------------              
 1.0.0   2019-10-02  alejandramed  Initital    
   
----------------------------------------------------------------------------------------------------------------------------------------- */               
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

SET XACT_ABORT ON 
BEGIN TRY
BEGIN TRAN

		IF OBJECT_ID('WRK_QualifiersByPointsMetrics', 'U') IS NOT NULL DROP TABLE WRK_QualifiersByPointsMetrics
		
		CREATE TABLE dbo.WRK_QualifiersByPointsMetrics
		(
			PK_Distributor INT,
			MetricType VARCHAR(4),
			MinPoints MONEY,
			GoalPoints MONEY,
			Consecutive_Any VARCHAR(11),
			Frequency INT,
			Accumulated_Achieve VARCHAR(11),
			StartDate SMALLDATETIME,
			EndDate SMALLDATETIME,
			QualDate SMALLDATETIME
		)

		;WITH 
		QualFilter
		(
			StartDate,
			EndDate,
			MetricType
		)
		AS
		(
			SELECT
				MIN(StartDate) StartDate,
				MAX(EndDate) EndDate,
				MetricType
			FROM @QualByPoints
			GROUP BY MetricType
		)
			,CTM_Points
			(
				RoyaltyMonth,
				PK_Distributor,
				DistributorID,
				dDeleted,
				dQual_SP,
				dQual_QS,
				dQual_QS_Actual,
				sTeam,
				sCOP,
				nIsAssocType23,
				nIsMainID,
				nIsInAssocTable,
				nMainDistributorID,
				sMainDistributorID,
				dMainDeleted,
				dMainQual_SP,
				sMainTeam,
				sMainCOP,
				nMainIsType23,
				MetricType,
				Points
			)
			AS
			(
			SELECT
				 A.RoyaltyMonth
				,A.PK_Distributor
				,A.DistributorID
				,A.DeletedDate
				,A.Qual_SPDate
				,A.Qual_QSDate
				,A.Qual_QSDate_Actual
				,A.Team
				,A.COP
				,A.IsAssocType23
				,A.IsMainID
				,A.IsInAssocTable
				,A.MainDistributorID
				,A.MainDistributorID
				,A.MainDeletedDate
				,A.MainQual_SPDate
				,A.MainTeam
				,A.MainCOP
				,A.MainIsType23
				,A.MetricType
				,A.Points
			FROM dbo.WRK_MembersPoints AS A WITH (NOLOCK)  
			WHERE EXISTS (SELECT 1 FROM QualFilter B WHERE A.RoyaltyMonth BETWEEN B.StartDate AND B.EndDate AND A.MetricType = B.MetricType)
			)
	
		INSERT INTO WRK_QualifiersByPointsMetrics(PK_Distributor,MetricType,MinPoints,GoalPoints,Consecutive_Any,Frequency,Accumulated_Achieve,StartDate,EndDate,QualDate)
		/* Accumulated/Consecutive */
		SELECT
			B.PK_Distributor,
			B.MetricType,
			x.MinPoints MinPoints,
			x.GoalPoints AS GoalPoints,
			CASE WHEN x.Consecutive = 1 THEN 'Consecutive' ELSE 'Any' END AS Consecutive_Any,
			x.Frequency AS Frequency,
			CASE WHEN x.Accumulated = 1 THEN 'Accumulated' ELSE 'Achieve' END AS Accumulated_Achieve,
			x.StartDate AS StartDate,
			x.EndDate AS EndDate,
			MIN(A.EndDate) AS QualDate
		FROM @QualByPoints x
			CROSS APPLY
			dbo.ufn_GetPeriods(x.StartDate, x.EndDate, x.Frequency, x.Consecutive, x.Accumulated) A
		CROSS APPLY (
			SELECT
				C.PK_Distributor,
				C.MetricType
			FROM
				CTM_Points C
			WHERE
				C.RoyaltyMonth BETWEEN A.StartDate AND A.EndDate
				AND
				C.MetricType = X.MetricType
				AND
				C.Points >= x.MinPoints
				AND
				x.Consecutive = 1
				AND
				x.Accumulated  = 1
			GROUP BY C.PK_Distributor, C.MetricType
			HAVING SUM(C.Points) >= x.GoalPoints
		) B
		WHERE
			x.Consecutive = 1
			AND
			x.Accumulated  = 1
		GROUP BY B.PK_Distributor, B.MetricType, x.MinPoints,x.GoalPoints,x.Consecutive,x.Frequency,x.Accumulated,x.StartDate,x.EndDate
				
		UNION ALL

		/* Accumulated/Not-Consecutive */
		SELECT
			PK_Distributor,
			MetricType,
			MinPoints,
			GoalPoints,
			Consecutive_Any,
			Frequency,
			Accumulated_Achieve,
			StartDate,
			EndDate,
			QualDate
		FROM (
				SELECT
					B.PK_Distributor,
					B.MetricType,
					x.MinPoints MinPoints,
					x.GoalPoints AS GoalPoints,
					CASE WHEN x.Consecutive = 1 THEN 'Consecutive' ELSE 'Any' END AS Consecutive_Any,
					x.Frequency AS Frequency,
					CASE WHEN x.Accumulated = 1 THEN 'Accumulated' ELSE 'Achieve' END AS Accumulated_Achieve,
					x.StartDate AS StartDate,
					x.EndDate AS EndDate,
					MAX(B.QualDate) AS QualDate,
					SUM(B.Points) AS TotalPoints,
					COUNT(1) AS TotalRows
					FROM @QualByPoints x
					CROSS APPLY 
				(
					SELECT 
						A.PK_Distributor,
						A.MetricType,
						A.RoyaltyMonth QualDate,
						A.Points,
						ROW_NUMBER() OVER(PARTITION BY A.PK_Distributor,A.MetricType ORDER BY A.Points DESC) AS ROWMonth 
					FROM
						CTM_Points A
					WHERE
						A.RoyaltyMonth BETWEEN x.StartDate AND x.EndDate
						AND
						A.MetricType = x.MetricType
						AND
						A.Points >= x.MinPoints
						AND
						x.Consecutive = 0
						AND
						x.Accumulated  = 1
				) B
				WHERE
					ROWMonth BETWEEN 1 AND x.Frequency
					AND
					x.Consecutive = 0
					AND
					x.Accumulated  = 1
				GROUP BY B.PK_Distributor, B.MetricType, x.MinPoints,x.GoalPoints,x.Consecutive,x.Frequency,x.Accumulated,x.StartDate,x.EndDate
		) AS Y
		WHERE
			Y.TotalPoints >= Y.GoalPoints
			AND
			(
				(Y.MinPoints > 0 AND Y.TotalRows >= Y.Frequency)
				OR
				Y.MinPoints <= 0
			)

		UNION ALL

		/* Achieve/Not-Consecutive */

		SELECT 
				B.PK_Distributor,
				B.MetricType,
				B.MinPoints,
				B.GoalPoints,
				B.Consecutive_Any,
				B.Frequency,
				B.Accumulated_Achieve,
				B.StartDate,
				B.EndDate,
				B.QualDate
		FROM @QualByPoints x
				CROSS APPLY
				(
			SELECT
				A.PK_Distributor,
				A.MetricType,
				X.MinPoints,
				X.GoalPoints,
				CASE WHEN X.Consecutive = 1 THEN 'Consecutive' ELSE 'Any' END AS Consecutive_Any,
				X.Frequency AS Frequency,
				CASE WHEN X.Accumulated = 1 THEN 'Accumulated' ELSE 'Achieve' END AS Accumulated_Achieve,
				X.StartDate AS StartDate,
				X.EndDate AS EndDate,
				MAX(A.RoyaltyMonth) AS QualDate
			FROM 
				CTM_Points A
			WHERE
				RoyaltyMonth BETWEEN X.StartDate AND X.EndDate
				AND
				MetricType = X.MetricType
				AND
				Points >= X.MinPoints
				AND
				Points >= X.GoalPoints
				AND
				X.Consecutive = 0
				AND
				X.Accumulated  = 0
			GROUP BY A.PK_Distributor, A.MetricType
			HAVING COUNT(*) >= X.Frequency
			) B
			WHERE
				X.Consecutive = 0
				AND
				X.Accumulated  = 0

		UNION ALL

		/* Achieve/Consecutive */
		SELECT 
			MB.PK_Distributor,
			MB.MetricType,
			X.MinPoints MinPoints,
			X.GoalPoints AS GoalPoints,
			CASE WHEN X.Consecutive = 1 THEN 'Consecutive' ELSE 'Any' END AS Consecutive_Any,
			X.Frequency AS Frequency,
			CASE WHEN X.Accumulated = 1 THEN 'Accumulated' ELSE 'Achieve' END AS Accumulated_Achieve,
			X.StartDate AS StartDate,
			X.EndDate AS EndDate,
			DATEADD(mm, -ROWMonth + 1, MB.RoyaltyMonth)  AS QualDate
		FROM @QualByPoints x
			CROSS APPLY 
		(
			SELECT 
				A.PK_Distributor,
				A.MetricType,
				A.RoyaltyMonth,
				A.Points,
				ROW_NUMBER() OVER(PARTITION BY A.PK_Distributor, A.MetricType ORDER BY A.RoyaltyMonth) AS ROWMonth 
			FROM
				CTM_Points A
			WHERE
				RoyaltyMonth BETWEEN X.StartDate AND X.EndDate
				AND
				MetricType = X.MetricType
				AND
				Points >= X.GoalPoints
				AND
				X.Consecutive = 1
				AND
				X.Accumulated  = 0

		) MB
		WHERE
			X.Consecutive = 1
			AND
			X.Accumulated  = 0
		GROUP BY MB.PK_Distributor,MB.MetricType,X.MinPoints,X.GoalPoints,X.Consecutive,X.Frequency,X.Accumulated,X.StartDate,X.EndDate,DATEADD(mm, -ROWMonth + 1, RoyaltyMonth)
		HAVING COUNT(1) >= X.Frequency
				
		CREATE CLUSTERED INDEX [IX_PK_Distributor_WRK_QualifiersPointsMetrics] ON [dbo].[WRK_QualifiersByPointsMetrics] ([PK_Distributor])

			-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;
	COMMIT
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		IF @@trancount > 0
			ROLLBACK

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