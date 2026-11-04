CREATE PROCEDURE [dbo].[usp_EventPromo_DsStatus_207025]
		 @PK_Event INT 
        ,@DistributorID VARCHAR(30)  
		
        -- Error Parameters
        ,@Error INT = 0 OUTPUT
        ,@ErrorMessage VARCHAR(4000) = '' OUTPUT
		
        -- QA/DEV
        ,@IsDevQA TINYINT = 0
		,@CurrentDate DATETIME2 = NULL								 
AS
BEGIN
/******************************************************************************
	OBJECT:    dbo.usp_EventPromo_DsStatus_207025
	
    USE:
            DECLARE @e int, @em varchar(max)
			
            EXEC dbo.usp_EventPromo_DsStatus_207025
                 @PK_Event = 207025
                ,@DistributorID = '10615204'
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
    1.0.0       2026-09-02      puertac        Initial (Based on usp_EventPromo_DsStatus_std)
******************************************************************************/
    SET NOCOUNT ON	

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime = GETUTCDATE()
			,@PromoEndDate DATETIME2 = NULL		--US 720693	
			,@LastOrder INT = NULL	
			
   BEGIN TRY
   
		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END
	
		DECLARE @PK_Distributor INT = (SELECT nDistributorID FROM v_Distributor WHERE sDistributorID = @DistributorID)																																					
				--,@IsMultiTarget BIT = (SELECT CASE WHEN (SELECT MAX(RIGHT(TargetName,1)) FROM Promo.TargetMetrics WITH(NOLOCK) WHERE PK_Event = @PK_Event)>1 THEN 1 ELSE 0 END)
																																	 		
		DECLARE @IsQualified BIT = (SELECT COUNT(1) FROM Promo.DSSubEvent AS SE WITH (NOLOCK) 
									WHERE SE.PK_Event = @PK_Event 
									AND SE.PK_Distributor = @PK_Distributor 
									AND SE.DateQualified IS NOT NULL)
			   ,@CustomEvalDate NVARCHAR (1000) = (SELECT CustomEvalDate FROM EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)
			   ,@SubTypeFreezeDate INT = 202611
	   DECLARE  @TeamCode VARCHAR(2) = (SELECT TeamCode FROM PubEventManagement.Shared.DSSNAPSHOT AS S WITH (NOLOCK) WHERE PK_Distributor = @PK_Distributor AND RoyaltyMonth = @SubTypeFreezeDate)
	   DECLARE  @IsTAB BIT = IIF(@TeamCode IN ('G','M','P'), 1, 0)

		SELECT @CurrentDate = CONVERT(DATE,ISNULL(@CurrentDate,GETUTCDATE()))			--US 720693
		SELECT @PromoEndDate = ISNULL( (SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'PromoEndDate' AND [Group] = 'dsstatus' AND IsActive = 1 )
								,(SELECT QualPeriodEnd FROM dbo.[Event] WITH (NOLOCK) WHERE PK_Event = @PK_Event ))  		--US 720693
		SELECT @LastOrder = MAX(CreatedDateSrc) FROM Promo.factFinantialDetail WITH (NOLOCK) WHERE PK_Distributor = @PK_Distributor
			
		DROP TABLE IF EXISTS #DSSubEvent;
		
		SELECT PK_Event,PK_Distributor,DateQualified
		INTO #DSSubEvent
		FROM Promo.DSSubEvent WITH (NOLOCK)
		WHERE PK_Event = @PK_Event

		CREATE INDEX IX_#DSSubEvent_PK ON #DSSubEvent(PK_Event,PK_Distributor)
			
		DROP TABLE IF EXISTS #DL;
		
		SELECT   D.ULDistributorID
				,D.PK_Distributor
				,D.DLDistributorID
				,D.PK_DSDownline AS PK_DLDistributor
				,D.DSLevelFromUL
				,SE.DateQualified					 
		INTO #DL
		FROM PubEvents.dbo.dimDSLngDownline_wBlock D WITH (NOLOCK)
		INNER JOIN Promo.EventDistributor E WITH (NOLOCK)				
			ON E.PK_Distributor = D.PK_DSDownline
			AND E.PK_Event = @PK_Event
			AND E.AsDownline = 1 
		LEFT JOIN #DSSubEvent SE WITH (NOLOCK)
			ON SE.PK_Event = E.PK_Event
			AND SE.PK_Distributor = E.PK_Distributor											 
		WHERE D.PK_Distributor = @PK_Distributor
		AND D.DSLevelFromUL > 1
		
		CREATE INDEX IX_#DL_PK ON #DL(PK_Distributor, PK_DLDistributor)


		-- First ResultSet
  		SELECT  @PK_Event AS PK_Event
				,D.DistributorID AS DistributorID
				,IIF(ISNULL(E.IsEligible,0) = 1, 1, 0)   AS IsEligible
				,@IsQualified AS IsQualified
				,CASE WHEN @CurrentDate <= @PromoEndDate										
							THEN IIF((SELECT COUNT(1) FROM #DL) > 0, 1, 0) 
							ELSE IIF((SELECT COUNT(1) FROM #DL WHERE DateQualified IS NOT NULL) > 0, 1, 0) 
				 END AS [HasDownline]
				,0 AS IsRewardClaimed
				,CASE @CustomEvalDate WHEN 'dInitialAppDate' THEN ISNULL(d.dInitialAppDate,(CASE WHEN (MBApplicationDate IS NOT NULL AND MBApplicationDate <> 19000101 AND MBApplicationDate <  APPLICATIONDATE) OR APPLICATIONDATE = 19000101
																				 THEN dMBApplicationDate ELSE dApplicationDate END))
				 ELSE (CASE WHEN D.PK_DSType IN (6,7) THEN D.dMBApplicationDate ELSE D.dApplicationDate END) END AS ActivationDate ----1.0.5
				,CAST(CAST(@LastOrder AS varchar(8)) AS DATETIME2)  AS LastOrderDate
				,d.dQSQualDate
				,d.dSPQualDate
		FROM Promo.dimDistributor D WITH (NOLOCK)
		LEFT JOIN Promo.EventDistributor E WITH (NOLOCK)
			ON D.PK_Distributor = E.PK_Distributor
			AND PK_Event = @PK_Event
		WHERE D.PK_Distributor = @PK_Distributor
		
		
		-- Second ResultSet 
		;WITH cte_COP AS (
			SELECT	D.sDistributorCountryProcessingCode AS COP
					,IIF(@IsTAB = 1, 'TAB', 'NONTAB') AS [TeamLevelTarget]		-- Custom
					,IIF(EXISTS (SELECT 1 FROM Promo.TargetMetrics WITH (NOLOCK) WHERE COP LIKE '%' +sDistributorCountryProcessingCode+ '%' AND PK_Event = @PK_Event), 1, 0) AS HasValidCOP				 					 
			FROM v_Distributor D
			WHERE sDistributorID = @DistributorID
		)
		SELECT DISTINCT T.TargetName 
				,T.MetricNames
				,T.MetricValues
				,T.MainMetric
				,T.HiddenMetrics
				,T.TeamLevelTarget 
				,T.COP
				,T.DateStart
				,T.BaseLine				   
		FROM Promo.TargetMetrics AS T WITH (NOLOCK)
		INNER JOIN cte_COP C 
			ON (T.COP LIKE '%' + IIF(HasValidCOP = 0, '-', C.COP) + '%')
			AND ((t.TeamLevelTarget IS NULL OR c.TeamLevelTarget = t.TeamLevelTarget))
		WHERE PK_Event = @PK_Event
   
   
    END TRY
    BEGIN CATCH
        SET @Error = ERROR_NUMBER()
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @StoredProcedure = ERROR_PROCEDURE()

        IF @IsDevQA = 1 SELECT @Error AS Error, @ErrorMessage AS [Error Message];

        -- UPDATE ERROR LOG
        EXEC dbo.usp_Utility_UpdateErrorLog
                @ProcedureName = @StoredProcedure
                ,@ErrorNumber = 3
                ,@ErrorMessage = @ErrorMessage
                ,@SQLErrorCode = @Error
                ,@SQLErrorMsg = @ErrorMessage
    END CATCH;

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime
	,@StoredProcedureParameters = @PK_Event

	SET NOCOUNT OFF
END