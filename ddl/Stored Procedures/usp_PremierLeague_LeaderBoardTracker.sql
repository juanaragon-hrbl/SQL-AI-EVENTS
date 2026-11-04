CREATE PROCEDURE [dbo].[usp_PremierLeague_LeaderBoardTracker]
	@PK_Event INT = 199427
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
OBJECT:			dbo.usp_PremierLeague_LeaderBoardTracker

USE:	        DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_PremierLeague_LeaderBoardTracker
					 	 @DistributorID = '14Y0094546'
					 	,@PK_Event = 199427
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
	1.0.0		2024-06-21		puertac		Intitial

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


		SELECT	 W.PK_Distributor
				,D.DistributorID
				,IIF(LOWER(D.DISTRIBUTOR_NAME_ON_AWARD) IS NULL OR LOWER(D.DISTRIBUTOR_NAME_ON_AWARD) = 'unknown', LOWER(D.FirstName)+' '+LOWER(D.LastName), LOWER(D.DISTRIBUTOR_NAME_ON_AWARD) ) AS Distributor_Name
				,TeamCode
				,SubTypeCode
				,W.WW_Ranking
				,W.Upline_COP
				,W.COP_Ranking
				,IIF(D.PK_Distributor = @PK_Distributor,1,0) AS IsLoggedDS
		FROM Promo.WRK_PremierLeague_QualifiersDetails AS W WITH (NOLOCK)
		INNER JOIN PubEvents.dbo.dimDistributor AS D WITH (NOLOCK)
			ON W.PK_Distributor = D.PK_Distributor
			AND W.WW_Ranking IS NOT NULL
		ORDER BY WW_Ranking


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

