CREATE PROCEDURE [dbo].[usp_HPL2025_LeaderBoardTracker]
	 @PK_Event INT = 202477
	,@LocaleCode CHAR(5)
	,@DistributorID VARCHAR(10) 
	-- Error Parameters
	,@Error INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA TINYINT = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_HPL2025_LeaderBoardTracker

USE:	        DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_HPL2025_LeaderBoardTracker
					 	 @DistributorID = '14Y0094546'
					 	,@PK_Event = 202477
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT   
						,@ErrorMessage = @em OUTPUT   

				SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:
	NOTES:			
	DEPENDENCIES
	----------------------------------------------------------------------------------
	VERSIONS
	----------------------------------------------------------------------------------
	1.0.0		2025-02-19		puertac		Initial
	1.1.0		2025-03-20		puertac		US 1407662: recognize 25 qualifers that also qualified in 24

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@Param varchar(100) = @DistributorID 
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';


	BEGIN TRY

		IF @IsDevQA= 2 THROW 60000, N'Unit test Error', 1;

  
		DECLARE @PK_Distributor	INT = (SELECT nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID)


	-- Getting Divorce and Transfer IDs									--	1.1.0
		DROP TABLE IF EXISTS #AllDivorceAndTransfer

			SELECT  W.PK_Distributor AS CurrentPK
				   ,D.PK_AssociatedID AS OldPK							-- DIVORCE
		INTO #AllDivorceAndTransfer
			FROM  Promo.WRK_HPL2025_QualifiersDetails AS W WITH (NOLOCK)
			LEFT JOIN Shared.DistributorAssociation AS D WITH (NOLOCK)
				ON W.PK_Distributor = D.PK_Distributor
			WHERE W.WW_Ranking IS NOT NULL
		UNION
			SELECT  W.PK_Distributor AS CurrentPK
				   ,D.PK_FromDS AS OldPK								-- TRANSFER which transferred again after qulifying to 2025, so no longer active ID
			FROM  Promo.WRK_HPL2025_QualifiersDetails AS W WITH (NOLOCK)
			LEFT JOIN Shared.DistributorTransfers AS D WITH (NOLOCK)
				ON W.PK_Distributor = D.PK_ToDS
			WHERE W.WW_Ranking IS NOT NULL
		UNION
			SELECT  W.PK_Distributor AS CurrentPK
				   ,D.PK_FromDS AS OldPK								-- TRANSFER which is the current active ID
			FROM  Promo.WRK_HPL2025_QualifiersDetails AS W WITH (NOLOCK)
			LEFT JOIN Shared.DistributorTransfers AS D WITH (NOLOCK)
				ON W.PK_Distributor = D.PK_RollupDS
			WHERE W.WW_Ranking IS NOT NULL
		
		CREATE INDEX IX_#AllDivorceAndTransfer_OldPK ON #AllDivorceAndTransfer(OldPK)

	
		DROP TABLE IF EXISTS #QualifiedFlagOldID								-- 1.1.0

		SELECT  DT.CurrentPK AS PK_Distributor
				,1 AS Qualified
		INTO #QualifiedFlagOldID
		FROM  Promo.WRK_PremierLeague_QualifiersDetails AS O WITH(NOLOCK)
		INNER JOIN #AllDivorceAndTransfer AS DT
			ON DT.OldPK = O.PK_Distributor
			AND O.ContributingYear = 2024
			AND O.IsUplineQualified = 1 
			AND DT.OldPK IS NOT NULL
		GROUP BY DT.CurrentPK
		
		CREATE INDEX IX_#QualifiedFlagOldID_PK_Distributor ON #QualifiedFlagOldID(PK_Distributor)
		

	-- Ranking Resultset													 
		SELECT	 W.PK_Distributor
				,D.DistributorID
				,IIF(LOWER(D.DISTRIBUTOR_NAME_ON_AWARD) IS NULL OR LOWER(D.DISTRIBUTOR_NAME_ON_AWARD) = 'unknown', LOWER(D.FirstName)+' '+LOWER(D.LastName), LOWER(D.DISTRIBUTOR_NAME_ON_AWARD) ) AS Distributor_Name
				,TeamCode
				,SubTypeCode
				,W.WW_Ranking
				,W.COP AS Upline_COP
				,W.COP_Ranking
				,IIF(D.PK_Distributor = @PK_Distributor,1,0) AS IsLoggedDS
				,IIF(A.PK_Distributor IS NULL AND B.PK_Distributor IS NULL, 0, 1) AS QualifiedLastYear		-- 1.1.0
		FROM Promo.WRK_HPL2025_QualifiersDetails AS W WITH (NOLOCK)
		INNER JOIN PubEvents.dbo.dimDistributor AS D WITH (NOLOCK)
			ON W.PK_Distributor = D.PK_Distributor
			AND W.WW_Ranking IS NOT NULL
		LEFT JOIN Promo.WRK_PremierLeague_QualifiersDetails AS A WITH(NOLOCK)
			ON A.PK_Distributor = W.PK_Distributor
			AND A.ContributingYear = 2024
			AND A.IsUplineQualified = 1
		LEFT JOIN #QualifiedFlagOldID AS B																	-- 1.1.0
			ON B.PK_Distributor = W.PK_Distributor																	   
		ORDER BY WW_Ranking


	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StoredProcedureParameters = @Param
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
