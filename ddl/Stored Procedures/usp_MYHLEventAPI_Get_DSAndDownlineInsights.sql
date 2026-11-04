CREATE PROCEDURE [dbo].[usp_MYHLEventAPI_Get_DSAndDownlineInsights]
     @DistributorID VARCHAR(25)		
    ,@PK_Event VARCHAR(MAX)
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT
	,@IsDevQA TINYINT = 0 

AS
BEGIN
/******************************************************************************
	OBJECT:			dbo.usp_MYHLEventAPI_Get_DSAndDownlineInsights
	
	USE:			DECLARE @e int, @em varchar(4000)

					EXEC [dbo].usp_MYHLEventAPI_Get_DSAndDownlineInsights]
							@DistributorID = 'staff'
                            ,@PK_Event = '62871,62872,62873'
							,@Error = @e OUTPUT  
							,@ErrorMessage = @em OUTPUT
							,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]
	DESCRIPTION:
	NOTES:	
	DEPENDENCIES
	--------------------------------------------------------------------
	
	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2024-01-29		puertac		Initial	
******************************************************************************/
	
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
	
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
				,@StartTime datetime2 = GETUTCDATE();
	SELECT @Error = 0, @ErrorMessage = '';
		
	BEGIN TRY

		IF @IsDevQA= 2 THROW 60000, N'Unit test Error', 1;
		
		DECLARE @PK_Distributor INT = (SELECT nDistributorID FROM V_Distributor WHERE sDistributorID = @DistributorID)


		DROP TABLE IF EXISTS #DSAndDownlines

        CREATE TABLE #DSAndDownlines(
             PK_Distributor_Upline		INT
            ,PK_Distributor_Downline	INT
			,DSLevel					INT
			,InheritedFrom_PK			INT
        )

		INSERT INTO #DSAndDownlines
			SELECT  D.PK_Distributor, D.PK_DSDownline, D.DSLevelFromUL, NULL AS InheritedFrom_PK				-- Personal Downlines
			FROM PubEvents.dbo.dimDSLngDownline_wBlock D WITH (NOLOCK)
			WHERE PK_Distributor = @PK_Distributor
			AND DSLevelFromUL BETWEEN 1 AND 7			-- 6 DSLevels only (Including Upline on DSLevelFromUL = 1)
		UNION
			SELECT A.PK_Distributor, D.PK_DSDownline, D.DSLevelFromUL, A.PK_AssociatedID AS InheritedFrom_PK	-- Inherited Downlines
			FROM Shared.DistributorAssociation AS A WITH (NOLOCK)
			INNER JOIN PubEvents.dbo.dimDSLngDownline_wBlock D WITH (NOLOCK)
				ON A.PK_AssociatedID = D.PK_Distributor
			WHERE A.PK_Distributor = @PK_Distributor
			AND D.DSLevelFromUL BETWEEN 2 AND 7			-- 6 DSLevels only
		
		CREATE INDEX IX_#DSAndDownlines_PK_Distributor_Downline ON #DSAndDownlines(PK_Distributor_Downline) 
	  


		DROP TABLE IF EXISTS #PK_Events_List

		CREATE TABLE #PK_Events_List (
			 PK_Event		INT
		)

		INSERT INTO #PK_Events_List
		SELECT Value 
		FROM STRING_SPLIT (@PK_Event,',')

		CREATE INDEX IX_#PK_Events_List_PK_Event ON #PK_Events_List(PK_Event) 



		DROP TABLE IF EXISTS #PK_MainSubEvents

		SELECT S.PK_Event, PK_SubEvent
		INTO #PK_MainSubEvents
		FROM dbo.SubEvent AS S WITH (NOLOCK)
		INNER JOIN #PK_Events_List AS L
			ON S.PK_Event = L.PK_Event
		WHERE S.IsMainEventQual = 1

		CREATE INDEX IX_#PK_MainSubEvents_PKs ON #PK_MainSubEvents(PK_Event, PK_SubEvent) 



		DROP TABLE IF EXISTS #AllQualifiers				 

		CREATE TABLE #AllQualifiers (
			 PK_Event					INT
			,PK_Distributor_Upline		INT
			,PK_Distributor_Downline	INT
		)
	
		INSERT INTO #AllQualifiers
		SELECT DISTINCT 
			   Q.PK_Event
			  ,D.PK_Distributor_Upline
			  ,D.PK_Distributor_Downline
		FROM #DSAndDownlines AS D
		CROSS APPLY #PK_MainSubEvents AS S
		INNER JOIN SubEventQualifier AS Q WITH (NOLOCK)
			ON Q.PK_Distributor = D.PK_Distributor_Downline  
			AND Q.PK_SubEvent = S.PK_SubEvent
			AND Q.PK_Event = S.PK_Event
			AND Q.Qualified = 1 	

	-- Index not needed for this table, it makes the processing heavier



		DROP TABLE IF EXISTS #UplineQualifiers

		CREATE TABLE #UplineQualifiers (
			 PK_Event			INT
			,PK_Distributor		INT
		)
	
		INSERT INTO #UplineQualifiers
		SELECT DISTINCT PK_Event, PK_Distributor_Upline AS PK_Distributor
		FROM #AllQualifiers 
		WHERE PK_Distributor_Upline = PK_Distributor_Downline

		CREATE INDEX IX_#UplineQualifiers_PK_Event ON #UplineQualifiers(PK_Event) 


	
		DROP TABLE IF EXISTS #CountDownlineQualifiers

		CREATE TABLE #CountDownlineQualifiers (
			 PK_Event					INT
			,DownlinesQualifiedCount	INT
		)

		INSERT INTO #CountDownlineQualifiers
		SELECT PK_Event, COUNT(PK_Distributor_Downline)
		FROM #AllQualifiers 
		WHERE PK_Distributor_Upline != PK_Distributor_Downline
		GROUP BY PK_Event
	
		CREATE INDEX IX_#CountDownlineQualifiers_PK_Event ON #CountDownlineQualifiers(PK_Event) 


		---------------------------------------------------------------------------------------------------------------------
		-- ResultSet

		SELECT PK.PK_Event
			  ,IIF(UP.PK_Event IS NOT NULL, 1, 0) AS IsUplineQualified
			  ,IIF(CD.DownlinesQualifiedCount IS NOT NULL, CD.DownlinesQualifiedCount,0) AS DownlinesQualified
		FROM #PK_Events_List AS PK
		LEFT JOIN #UplineQualifiers AS UP
			ON PK.PK_Event = UP.PK_Event
		LEFT JOIN #CountDownlineQualifiers AS CD
			ON PK.PK_Event = CD.PK_Event



		-- Update processing Log
		EXEC dbo.usp_Utility_UpdateProcessingLog 													
		 @StoredProcedureName = @StoredProcedure
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
	END CATCH

END
