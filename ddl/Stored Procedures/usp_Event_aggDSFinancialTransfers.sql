CREATE PROCEDURE [dbo].[usp_Event_aggDSFinancialTransfers]  
		-- Error Parameters
		@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = NULL OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS  
BEGIN  
   
/******************************************************************************  
 OBJECT:   dbo.usp_Event_aggDSFinancialTransfers  

 USE:   	DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_Event_aggDSFinancialTransfers 
				
				 @Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
  
 DESCRIPTION: Aggregate metrics by Transfer ID in aggDSFinancial table  
 NOTES:     
  
 DEPENDENCIES  
 --------------------------------------------------------------------  
 SQL SERVER 2008  
   
 VERSIONS  
 --------------------------------------------------------------------  
 1.0	2011-10-13	IniU			Initial (Culled from BizWorks Financial Transfer)  
 1.1	2016-11-11	SandhyaP		Netizza reference changes
 1.2	2019-10-08	alejandramed	SRE Compliance 
******************************************************************************/  
  
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

		CREATE TABLE #wrk_Transfers  
		(  
		 PK    INT IDENTITY (1,1) PRIMARY KEY,  
		 PK_FromDS  INT,  
		 FromDS   VARCHAR(10),  
		 PK_ToDS   INT,  
		 ToDS   VARCHAR(10),  
		 PK_RollupDS  INT,  
		 RollupDS  VARCHAR(10),  
		 FromDSStatus VARCHAR(20),  
		 RollupDSStatus  VARCHAR(20),  
		 CreateDateSrc DATETIME,  
		 ModifiedDateSrc DATETIME  
		)  
  
		-- Fetch Transfers from HMS  
		INSERT INTO  
		#wrk_Transfers  
		 (  
		 FromDS,  
		 ToDS,  
		 CreateDateSrc,  
		 ModifiedDateSrc  
		 )   
		SELECT   
		 DFROM.DistributorID,  
		 DTO.DistributorID,  
		 DST.CreatedDate,  
		 DST.ModifiedDate   
		FROM   
		 pubEvents.dbo.dimDSTransfers DST WITH (NOLOCK)
		INNER JOIN  
		 pubEvents.dbo.dimDistributor DFROM WITH (NOLOCK)  
		ON  
		 DST.PK_FromDistributor = DFROM.PK_Distributor  
		INNER JOIN  
		 pubEvents.dbo.dimDistributor DTO WITH (NOLOCK)  
		ON  
		 DST.PK_ToDistributor = DTO.PK_Distributor  
     
		CREATE INDEX IX_1 ON #wrk_Transfers (FromDS)  
		CREATE INDEX IX_2 ON #wrk_Transfers (ToDS)  
  
		-- Remove DUPS (Keep Latest)  
		DELETE F  
		FROM   
			  #wrk_Transfers F  
		INNER JOIN   
			  (SELECT   
					 FromDS  
					,MAX(PK) PK  
			   FROM   
					#wrk_Transfers  
			   GROUP BY   
					FromDS  
			   HAVING   
					COUNT(1) > 1  
			  ) Dups  
			  ON F.FromDS = Dups.FromDS  
			  AND F.PK <> Dups.PK  
  
		-- Assign Roll-Up ID for Non-Chained transfers  
		/*  
		 b -> c where c is the current id  
		 From To  Roll-Up  
		 b  c  c  
		*/  
		UPDATE  
		 T1  
		SET  
		 T1.RollupDS= T1.ToDS  
		FROM  
		 #wrk_Transfers T1  
		LEFT JOIN   
		 #wrk_Transfers T2  
		 ON  
		  T1.ToDS = T2.FromDS  
		WHERE  
		 T2.FromDS IS NULL  
  
		-- Assign Roll-Up ID for Chained transfers  
		/*  
		 a -> b -> c where c is the current id  
		 From To  Roll-Up  
		 a  b  c  
		 b  c  c  
		*/  
		DECLARE @RowCount int = 1  
  
		WHILE @RowCount > 0  
		BEGIN  
  
		 UPDATE  
		  T1  
		 SET  
		  RollupDS = T2.RollUpDS  
		 FROM  
		  #wrk_Transfers T1  
		 INNER JOIN   
		  #wrk_Transfers T2  
		  ON  
		  T1.ToDS = T2.FromDS AND  
		  T2.RollUpDS IS NOT NULL  
		 WHERE  
		  T1.RollupDS IS NULL  
  
		 SET @RowCount = @@ROWCOUNT  
  
		END   
		-- Assign PK's and Status  
		UPDATE  
		 Wrk  
		SET  
		 Wrk.PK_FromDS = DS_FRM.PK_Distributor,  
		 Wrk.FromDSStatus = DS_ST_FRM.StatusCode,  
		 Wrk.PK_ToDS = DS_TO.PK_Distributor,  
		 Wrk.PK_RollupDS = DS_ROLL.PK_Distributor,   
		 Wrk.RollupDSStatus = DS_ST_ROLL.StatusCode  
		FROM  
		 #wrk_Transfers Wrk  
		INNER JOIN  
		 pubEvents.dbo.dimDistributor DS_FRM (NOLOCK)  
		 ON Wrk.FromDS = DS_FRM.DistributorID  
		INNER JOIN   
		 pubEvents.dbo.dimDSStatus DS_ST_FRM (NOLOCK)  
		 ON DS_FRM.PK_DSStatus = DS_ST_FRM.PK_DSStatus  
		INNER JOIN  
		 pubEvents.dbo.dimDistributor DS_TO (NOLOCK)  
		 ON Wrk.ToDS = DS_TO.DistributorID  
		INNER JOIN  
		 pubEvents.dbo.dimDistributor DS_ROLL (NOLOCK)  
		 ON Wrk.RollupDS = DS_ROLL.DistributorID   
		INNER JOIN   
		 pubEvents.dbo.dimDSStatus DS_ST_ROLL (NOLOCK)  
		 ON DS_ROLL.PK_DSStatus = DS_ST_ROLL.PK_DSStatus   
    
		CREATE INDEX IX_3 ON #wrk_Transfers (PK_FromDS)  
		CREATE INDEX IX_4 ON #wrk_Transfers (PK_ToDS)  
		CREATE INDEX IX_5 ON #wrk_Transfers (PK_RollupDS)  
  
		-- Remove any transfers with null From/To/Rollup PK  
		DELETE  
		 TF  
		FROM  
		 #wrk_Transfers TF  
		WHERE  
		 PK_FromDS IS NULL OR PK_ToDS IS NULL OR PK_RollupDS IS NULL  
   
		-- Remove Rejected Transfers  
		DELETE FROM #wrk_Transfers WHERE   
		(FromDSStatus = 'COMPLETE' AND RollupDSStatus = 'COMPLETE') OR  
		(FromDSStatus = 'DELETED' AND RollupDSStatus = 'DELETED') OR  
		(FromDSStatus = 'DELETED' AND RollupDSStatus = 'TERMINATED') OR  
		(FromDSStatus = 'TERMINATED' AND RollupDSStatus = 'DELETED') OR  
		(FromDSStatus = 'TERMINATED' AND RollupDSStatus = 'TERMINATED')   
  
		-- Reverse Transfers  
		UPDATE  
		 #wrk_Transfers  
		SET  
		 PK_FromDS = PK_RollupDS,  
		 FromDS = RollupDS,  
		 RollupDS = FromDS,  
		 PK_RollupDS = PK_FromDS   
		WHERE  
		(FromDSStatus = 'COMPLETE' AND RollupDSStatus = 'DELETED') OR  
		(FromDSStatus = 'COMPLETE' AND RollupDSStatus = 'TERMINATED')  
  
		-- Get Metrics from factDSFinancial for OLD ID  
		SELECT   
		 Wrk.PK_RollupDS,  
		 FACT.RoyaltyMonth,  
		 SUM(FACT.PPV) PPV,  
		 SUM(FACT.PV) PV,  
		 SUM(FACT.GV) GV,  
		 SUM(FACT.RO) RO,  
		 SUM(FACT.PB) PB,  
		 SUM(FACT.OV) OV,  
		 SUM(FACT.DLV) DLV,  
		 SUM(TV) TV   
		INTO   
		 #wrk_FromDSMetrics  
		FROM  
		 #wrk_Transfers WRK  
		INNER JOIN  
			dbo.aggDSFinancial FACT  WITH (NOLOCK)
		 ON WRK.PK_FromDS = FACT.PK_Distributor  
		GROUP BY  
		 Wrk.PK_RollupDS,  
		 FACT.RoyaltyMonth   
  
		-- Get Metrics from aggDSFinancial for Rollup ID  
		SELECT   
		 FACT.PK_Distributor AS PK_RollupDS,  
		 FACT.RoyaltyMonth,  
		 ISNULL(FACT.PPV,0) PPV,  
		 ISNULL(FACT.PV,0) PV,  
		 ISNULL(FACT.GV,0) GV,  
		 ISNULL(FACT.RO,0) RO,  
		 ISNULL(FACT.PB,0) PB,  
		 ISNULL(FACT.DLV,0) DLV,  
		 ISNULL(FACT.OV,0) OV,  
		 ISNULL(FACT.TV,0) TV  
		INTO   
		 #wrk_RollupDSMetrics  
		FROM  
		 dbo.aggDSFinancial FACT WITH (NOLOCK)  
		WHERE  
		 FACT.PK_Distributor IN (SELECT DISTINCT PK_RollupDS FROM #wrk_Transfers)    
  
		-- Find Distinct ID + RO Month combinations that will need to reside in factDSFinancial  
		-- for the Roll-Up ID  
		SELECT  
		 PK_RollupDS,  
		 RoyaltyMonth  
		INTO  
		 #wrk_DistinctCombo   
		FROM  
		(  
		SELECT  
		 PK_RollupDS,  
		 RoyaltyMonth  
		FROM  
		 #wrk_FromDSMetrics  
		UNION   
		SELECT  
		 PK_RollupDS,  
		 RoyaltyMonth  
		FROM  
		 #wrk_RollUpDSMetrics   
		) AS UNI  
  
		-- Build Financial Records for the Distinct Combinations of ID + Royalty Month  
		SELECT   
		 A.PK_RollupDS,  
		 A.RoyaltyMonth,  
		 ISNULL(Roll.PPV,0) + ISNULL(FRM.PPV,0) AS PPV,  
		 ISNULL(Roll.PV,0) + ISNULL(FRM.PV,0) AS PV,   
		 ISNULL(Roll.GV,0) + ISNULL(FRM.GV,0) AS GV,  
		 ISNULL(Roll.PB,0) + ISNULL(FRM.PB,0) AS PB,  
		 ISNULL(Roll.RO,0) + ISNULL(FRM.RO,0) AS RO,  
		 ISNULL(Roll.DLV,0) + ISNULL(FRM.DLV,0) AS DLV,  
		 ISNULL(Roll.OV,0) + ISNULL(FRM.OV,0) AS OV,  
		 ISNULL(Roll.TV,0) + ISNULL(FRM.TV,0) AS TV  
		INTO  
		 #wrk_DSFinancial   
		FROM  
		 #wrk_DistinctCombo A  
		LEFT JOIN  
		 #wrk_RollupDSMetrics Roll (NOLOCK)  
		 ON A.PK_RollupDS = Roll.PK_RollupDS AND  
			A.RoyaltyMonth = Roll.RoyaltyMonth   
		LEFT JOIN  
		 #wrk_FromDSMetrics FRM (NOLOCK)  
		 ON A.PK_RollupDS = FRM.PK_RollupDS AND  
			A.RoyaltyMonth = FRM.RoyaltyMonth  
      
		-- Delete All data for OLD DS   
		DELETE   
		 FACT  
		FROM  
		 dbo.aggDSFinancial FACT   
		INNER JOIN  
		 #wrk_Transfers TRF (NOLOCK)  
		 ON FACT.PK_Distributor = TRF.PK_FromDS    
  
		-- Delete All data for Rollup DS  
		DELETE   
		 FACT  
		FROM  
		 dbo.aggDSFinancial FACT   
		INNER JOIN  
		 #wrk_Transfers TRF (NOLOCK)  
		 ON FACT.PK_Distributor = TRF.PK_RollupDS  
  
		-- Insert new rolled up Data  
		INSERT INTO dbo.aggDSFinancial  
		(  
		 PK_Distributor,  
		 DistributorID,  
		 DeletedDate,  
		 Qual_SPDate,  
		 Team,  
		 COP,  
		 IsAssocType23,  
		 IsMainID,  
		 IsInAssocTable,  
		 RoyaltyMonth,  
		 PV,  
		 GV,  
		 TV,  
		 PPV,  
		 OV,  
		 RO,  
		 DLV,  
		 PB,  
		 PK_MainDistributor,  
		 MainDeletedDate,  
		 MainQual_SPDate,  
		 MainTeam,  
		 MainCOP,  
		 MainIsType23,  
		 LastModifiedDate  
		)  
		SELECT  
		 FACT.PK_RollupDS,  
		 DS.sDistributorID,  
		 DS.dDeleted,  
		 DS.dSupervisorQualification,  
		 DS.sTeam,  
		 DS.sDistributorCountryProcessingCode,  
		 0 AS IsAssocType23,  
		 1 AS IsMainID,  
		 0 AS IsInAssocTable,  
		 FACT.RoyaltyMonth,  
		 FACT.PV,  
		 FACT.GV,  
		 FACT.TV,  
		 FACT.PPV,  
		 FACT.OV,  
		 FACT.RO,  
		 FACT.DLV,  
		 FACT.PB,  
		 FACT.PK_RollupDS,  
		 DS.dDeleted,  
		 DS.dSupervisorQualification,  
		 DS.sTeam,  
		 DS.sDistributorCountryProcessingCode,  
		 0 AS MainIsType23,  
		 GETDATE() AS LastModifiedDate  
		FROM  
		 #wrk_DSFinancial FACT  
		INNER JOIN  
		 dbo.v_Distributor DS  WITH (NOLOCK)
		ON  
		 FACT.PK_RollupDS = DS.nDistributorID  
  
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
		RETURN 
	END CATCH;
END;
