CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMGetAwayVacation2024]         
	  @PK_Event INT = 193112      
	 ,@LocaleCode CHAR(5)          
	 ,@DistributorID VARCHAR(10)       
	 -- Error Parameters      
	 ,@Error INT = 0   OUTPUT
	 ,@ErrorMessage varchar(4000) = NULL OUTPUT     
AS      
BEGIN       
/******************************************************************************      
OBJECT:   dbo.[usp_MyHLEventAPI_CustomTrackingPage_NAMGetAwayVacation2024]      
      
USE:     EXEC dbo.[usp_MyHLEventAPI_CustomTrackingPage_NAMGetAwayVacation2024]      
			 @DistributorID = N'2222222222'      
			,@PK_Event = 193112      
			,@LocaleCode = 'en-US'       
      
DESCRIPTION: custom stored procedure for NAM GetAway Vacation 2024      
NOTES:         
      
DEPENDENCIES      
----------------------------------------------------------------------------------             
      
VERSIONS      
----------------------------------------------------------------------------------      
	1.0.0		2023-01-18			puertac (Based on  usp_MyHLEventAPI_CustomTrackingPage_NAMGetAwayVacation2023)   
      
******************************************************************************/      
SET ANSI_NULLS ON      
SET QUOTED_IDENTIFIER ON      
SET NOCOUNT OFF      
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
   
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID) 
		,@StartTime datetime2 = GETUTCDATE();       
SELECT @Error = 0, @ErrorMessage = ''     
 
 
BEGIN TRY     

    DECLARE  @TABVAcation_PK_Event INT = 193219			--  24004 - TAB Team Vacation 2024
			,@ValidDate DATETIME2 = '2049-12-31'
			,@Month1  DATETIME = '2023-01-01'				
			,@Month2 DATETIME = '2023-12-01'
			,@Month3 DATETIME = '2024-01-01'

	DECLARE @PK_Distributor INT = (SELECT nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID)
	DECLARE @PK_Locale INT  = (SELECT PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode )    
	DECLARE @PK_DefaultLocale INT  = (SELECT PK_DefaultLocale FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @PK_Event )    

 
	IF OBJECT_ID('tempdb..#MBDetails') IS NOT NULL DROP TABLE #MBDetails
	IF OBJECT_ID('tempdb..#MBVolumes') IS NOT NULL DROP TABLE #MBVolumes
      
	CREATE TABLE #MBDetails     
	(      
		 PK_Distributor	INT
		,DistributorID  VARCHAR(10)
		,DSCurrentTeam	CHAR(5)
		,SPQualDate		DATETIME
		,SCountryCode	CHAR(5)
		,IsTAB BIT DEFAULT 0
		,IsNewTAB BIT DEFAULT 0
		,IsNewNonTAB BIT DEFAULT 0
		,IsQualifiedtoTABVacation BIT DEFAULT 0
		,TeamQualificationDate DATETIME
		,TABQualificationDate DATETIME
	)  

	CREATE TABLE #MBVolumes
	(
		PK_Distributor INT,
		RoyaltyMonth DATETIME,
		TVP MONEY,
		RO MONEY
	)

	IF @PK_Distributor IS NOT NULL      
	BEGIN          
		INSERT #MBDetails      
		(      
			 PK_Distributor	
			,DistributorID  
			,DSCurrentTeam	
			,SPQualDate		
			,SCountryCode	 
			--,IsNewTAB
		)    
		SELECT
			 D.nDistributorID AS PK_Distributor
			,D.sDistributorID
			,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam	
			,D.dSupervisorqualification AS SPQualDate			
			,D.sDistributorCountryProcessingCode AS CountryCode	
			--,TAB2021
		FROM dbo.v_Distributor (NOLOCK) D
		WHERE D.nDistributorID = @PK_Distributor
		AND	D.StatusCode = 'COMPLETE'

		;WITH HighestTeam(PK_Distributor, nEventTypeLID) AS
		(
			SELECT H.nDistributorIDFK,        
				  MAX(nEventTypeLID) AS nEventTypeLID        
			FROM dbo.v_DistributorHistory H   
			INNER JOIN #MBDetails SM 
				ON H.nDistributorIDFK = SM.PK_Distributor  
			WHERE  H.dThrough = @ValidDate        
			AND  H.nEventTypeLID BETWEEN 223 AND 241     
			GROUP BY nDistributorIDFK
		),
		HighestTeamDate(PK_Distributor, TeamDate) AS
		(
			 SELECT  H.nDistributorIDFK,        
					MAX(H.dFrom)  TeamDate     
			 FROM dbo.v_DistributorHistory H   
			 INNER JOIN HighestTeam SM 
				ON H.nDistributorIDFK = SM.PK_Distributor  
			 WHERE  H.dThrough = @ValidDate        
			 AND  H.nEventTypeLID = SM.nEventTypeLID   
			 GROUP BY nDistributorIDFK
		)
		UPDATE w SET w.TeamQualificationDate = HD.TeamDate
		FROM #MBDetails w 
		INNER JOIN HighestTeamDate HD
			ON HD.PK_Distributor = w.PK_Distributor

		UPDATE W
		SET IsQualifiedtoTABVacation = 1
		FROM #MBDetails W
		INNER JOIN dbo.SubEventQualifier SEQ WITH (NOLOCK) 
			ON W.PK_Distributor = SEQ.PK_Distributor
			AND SEQ.PK_Event = @TABVAcation_PK_Event 
			AND RemovedUTC = @ValidDate
			AND SEQ.Qualified = 1

		;WITH cte_TABs (PK_Distributor, QualDate)
		AS (
				SELECT DISTINCT M.PK_Distributor,MIN(H.dFrom)  
				FROM #MBDetails M  
				INNER JOIN dbo.v_DistributorHistory H 
					ON M.PK_Distributor = H.nDistributorIDFK 
				INNER JOIN dbo.v_dimDSLifeCycle LC
					ON LC.LifeCycleCode = 225						
					AND H.SortOrder = LC.SortOrder					
					AND H.dThrough = @ValidDate 
					AND H.dFrom BETWEEN @Month1 AND @Month2
				GROUP BY M.PK_Distributor
		)	
	
		UPDATE A
		SET  A.IsNewTAB = 1,A.TABQualificationDate = CT.QualDate
			,A.IsNewNonTAB = 0
		FROM #MBDetails A
		INNER JOIN cte_TABs  CT
			ON A.PK_Distributor = CT.PK_Distributor	

		;WITH cte_NonTABs (PK_Distributor)
		AS (
			SELECT DISTINCT M.PK_Distributor
			FROM #MBDetails M  
			INNER JOIN dbo.v_DistributorHistory H 
				ON M.PK_Distributor = H.nDistributorIDFK 
				AND M.DSCurrentTeam IN ('G','M','P','A','B','C')
				AND TABQualificationDate >= @Month3															   
			INNER JOIN dbo.v_dimDSLifeCycle LC
				ON LC.LifeCycleCode BETWEEN 223 AND 224
			WHERE @Month2 BETWEEN H.dFrom  AND H.dThrough
		)
		
		 UPDATE A
		 SET A.IsNewNonTAB = 1
		 FROM #MBDetails A
		 INNER JOIN cte_NonTABs CNT
			ON A.PK_Distributor = CNT.PK_Distributor
		 WHERE A.IsNewNonTAB = 0 AND A.IsNewTAB = 0

		 UPDATE M SET M.IsTAB = 1
		 FROM #MBDetails M 
		 WHERE M.DSCurrentTeam IN ('G','M','P','A','B','C')

		INSERT INTO #MBVolumes(PK_Distributor, RoyaltyMonth, TVP, RO)
		SELECT   @PK_Distributor
				,dRoyaltyMonth
				,CASE WHEN ISNULL(mVolumePoints, 0) >= 0 THEN ISNULL(mVolumePoints, 0) ELSE 0 END
				,CASE WHEN (ISNULL(mRoyaltyOverrides, 0) + ISNULL(mMainRoyaltyOverrides, 0)) >= 0 THEN ISNULL(mRoyaltyOverrides, 0) + ISNULL(mMainRoyaltyOverrides, 0) ELSE 0 END 
		FROM dbo.v_aggFQS_ID
		WHERE nDistributorID = @PK_Distributor
		and dRoyaltyMonth BETWEEN @Month1 AND @Month2	
	END   

	IF EXISTS (SELECT 1 FROM #MBDetails MB WHERE PK_Distributor = @PK_Distributor)
	BEGIN
		SELECT PK_Distributor	
			,DistributorID  
			,DSCurrentTeam			
			,SCountryCode
			,IsTAB
			,IsNewTAB
			,IsNewNonTAB
			,IsQualifiedtoTABVacation
			,TeamQualificationDate
		FROM #MBDetails MB 

		SELECT  PK_Distributor	
				,RoyaltyMonth  
				,TVP
				,RO
		FROM #MBVolumes MB 
	END
	ELSE
	BEGIN
			SELECT  @PK_Distributor PK_Distributor	
					,'' DistributorID  
					,'' DSCurrentTeam	
					,'' SPQualDate		
					,'' QSQualDate		
					,'' SCountryCode	
					,0 IsTAB
					,0 IsNewTAB
					,0 IsNewNonTAB
					,0 IsQualifiedtoTABVacation
					,'' TeamQualificationDate

		SELECT @PK_Distributor PK_Distributor	
			,'' RoyaltyMonth  
			,0.00 TVP	
			,0.00 RO	
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
  
  SELECT @Error AS [Error], @ErrorMessage AS [Error Message];  
  
  -- UPDATE ERROR LOG  
  EXEC dbo.usp_Utility_UpdateErrorLog   
    @ProcedureName = @StoredProcedure  
    ,@ErrorNumber = 3  
    ,@ErrorMessage = @ErrorMessage  
    ,@SQLErrorCode = @Error  
    ,@SQLErrorMsg = @ErrorMessage  
     
 END CATCH;         
END


