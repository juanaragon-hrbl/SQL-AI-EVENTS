
CREATE PROCEDURE [dbo].[usp_NonTABAWT_Star_BuildDownline] 
@PromoStartDate DATETIME, 
@AWTYear INT

-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0

AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_NonTABAWT_Star_BuildDownline

	USE:			
			DECLARE @e int, @em varchar(4000)
			EXEC usp_NonTABAWT_Star_BuildDownline 
				@PromoStartDate = '2015-01-01'
				,@AWTYear = 2015
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION: This procedure will build the lineage STAR NONTAB AWT - 3 levels deep w/ Blocking 

	NOTES:			

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2008
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1	2015-08-11  Juan		Initial
	2	2019-09-30	NoeG		SRE template applied

***********************************************************************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		CREATE TABLE #TempTable(
			[PK] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
			[PK_Distributor] [int] NULL,
			[PK_FirstDownLine] [int] NULL,
			[FirstLineIsNonTAB] [bit] DEFAULT(0),
			[FirstLineIsAWT] [bit] DEFAULT(0),
			[FirstLineIsNewAWT] [bit] DEFAULT(0),
			[FirstLineNewStar] [bit] DEFAULT(0),
			[FirstLineRepeatStar] [bit] DEFAULT(0),
			[PK_SecondDownLine] [int] NULL,
			[SecondLineIsNonTAB] [bit] DEFAULT(0),
			[SecondLineIsAWT] [bit] DEFAULT(0),
			[SecondLineIsNewAWT] [bit] DEFAULT(0),
			[SecondLineNewStar] [bit] DEFAULT(0),
			[SecondLineRepeatStar] [bit] DEFAULT(0),
			[PK_ThirdDownLine] [int] NULL,
			[ThirdLineIsNonTAB] [bit] DEFAULT(0),
			[ThirdLineIsAWT] [bit] DEFAULT(0),
			[ThirdLineIsNewAWT] [bit] DEFAULT(0),
			[ThirdLineNewStar] [bit] DEFAULT(0),
			[ThirdLineRepeatStar] [bit] DEFAULT(0)

		)


		/*BUILD LINEAGE*/

			;WITH TAB (PK_Distributor) AS  
			(  
				SELECT
						DS.PK_Distributor  
				FROM
						pubEvents.dbo.dimDistributor DS (NOLOCK) 
				INNER JOIN
						dbo.AWT A (NOLOCK)  
						ON  
						DS.PK_Distributor = A.PK_Distributor   
						AND  
						A.AWTYear = @AWTYear 
				WHERE
  					DS.PK_DSStatus = 3 --(COMPLETE)
					AND
					DS.PK_DSType = 5 --(SP)
			)
			,FirstLvl (PK_Distributor, PK_FirstLine) AS
			(
				SELECT
						DS.PK_Distributor
						,DL.PK_DSDownline
				FROM            
					TAB DS
				LEFT JOIN
						dbo.v_dimDSLngDownline DL 
						ON
							DS.PK_Distributor = DL.PK_Distributor
							AND DL.SPLevelFromUL = 2
			)
			, SecondLvl (PK_Distributor, PK_FirstLine, PK_SecondLine) AS
			(
				SELECT 
						FirstLvl.PK_Distributor
						,FirstLvl.PK_FirstLine
						,DL.PK_DSDownline
				FROM
						FirstLvl
				LEFT JOIN
						dbo.v_dimDSLngDownline DL 
						ON
							FirstLvl.PK_FirstLine = DL.PK_Distributor
							AND DL.SPLevelFromUL = 2
			)
			, ThirdLvl (PK_Distributor, PK_FirstLine, PK_SecondLine, PK_ThirdLevel) AS
			(
				SELECT 
						SecondLvl.PK_Distributor
						,SecondLvl.PK_FirstLine
						,SecondLvl.PK_SecondLine
						,DL.PK_DSDownline
				FROM
						SecondLvl
				LEFT JOIN
						dbo.v_dimDSLngDownline DL 
						ON
							SecondLvl.PK_SecondLine = DL.PK_Distributor
							AND DL.SPLevelFromUL = 2
			)

		/* INSERT ALL THE QUALIFIERS TO THE TEAM TABLE THAT WAS CREATED ABOVE */
		INSERT
			#TempTable
		(
			PK_Distributor
			,PK_FirstDownLine
			,PK_SecondDownLine
			,PK_ThirdDownLine
		)
		SELECT
			 PK_Distributor
			,PK_FirstLine
			,PK_SecondLine
			,PK_ThirdLevel
		FROM
			ThirdLvl


		CREATE INDEX IX_TempTable_PK_Distributor ON #TempTable(PK_Distributor)
		CREATE INDEX IX_TempTable_PK_FirstDownLine ON #TempTable(PK_FirstDownLine)
		CREATE INDEX IX_TempTable_PK_SecondDownLine ON #TempTable(PK_SecondDownLine)
		CREATE INDEX IX_TempTable_PK_ThirdDownLine ON #TempTable(PK_ThirdDownLine)

		/*BUILD DL with AWT NonTab flags*/	
		DECLARE @DLFlags TABLE
		(
			PK_Distributor INT
			,isAWT BIT
			,isNewAWT BIT
			,isNonTAB BIT
		)

		;WITH DL(PK_Distributor) AS 
		(
			SELECT PK_FirstDownline
			FROM #TempTable
			UNION
			SELECT PK_SecondDownLine
			FROM #TempTable
			UNION
			SELECT PK_ThirdDownLine
			FROM #TempTable
		),AWT (PK_Distributor,isAWT,isNewAWT) AS
		(
			SELECT
				DL.PK_Distributor
				,CASE WHEN A.PK_AWT IS NULL THEN 0 ELSE 1 END isAWT
				,CASE WHEN PastAWT = 'No' THEN 1 ELSE 0 END isNewAWT				
			FROM DL	
			LEFT JOIN 
				dbo.AWT A (nolock)
			ON 
				DL.Pk_Distributor = A.PK_Distributor
				AND A.AWTYear = @AWTYear
		
		),NonTAB (PK_Distributor,isAWT,isNewAWT,isNonTAB) AS
		(
			SELECT
				AWT.PK_Distributor		
				,isAWT
				,isNewAWT
				,CASE WHEN DH.nDistributorIDFK IS NULL THEN 1 ELSE 0 END
			FROM AWT
			LEFT JOIN
				dbo.v_DistributorHistory DH
			ON
				DH.nDistributorIDFK = AWT.PK_Distributor
				AND DH.nEventTypeLID >= 222 AND DH.nEventTypeLID NOT IN (229,230,232)
				AND @PromoStartDate BETWEEN DH.dFrom AND DH.dThrough		

		)  

		INSERT INTO @DLFlags
		SELECT PK_Distributor,isAWT,isNewAWT,isNonTAB FROM NonTAB


		/* UPDATE THE FLAGS FOR THE FIRST LINE IDS */
		UPDATE
			A
		SET
			FirstLineIsAWT = isAWT,
			FirstLineIsNewAWT = isNewAWT,
			FirstLineIsNonTAB = isNonTAB
		FROM
			#TempTable A
		INNER JOIN
			@DLFlags D
		ON
			A.PK_FirstDownLine = D.PK_Distributor


		/* UPDATE THE FLAGS FOR THE SECOND LINE IDS */
		UPDATE
			A
		SET
			SecondLineIsAWT = isAWT,
			SecondLineIsNewAWT = isNewAWT,
			SecondLineIsNonTAB = isNonTAB
		FROM
			#TempTable A
		INNER JOIN
			@DLFlags D
		ON
			A.PK_SecondDownLine = D.PK_Distributor


		/* UPDATE THE FLAGS FOR THE THIRD LINE IDS */
		UPDATE
			A
		SET
			ThirdLineIsAWT = isAWT,
			ThirdLineIsNewAWT = isNewAWT,
			ThirdLineIsNonTAB = isNonTAB
		FROM
			#TempTable A
		INNER JOIN
			@DLFlags D
		ON
			A.PK_ThirdDownLine= D.PK_Distributor


		/******************* BLOCKING RULES **************************/
		UPDATE
			T
		SET
			FirstLineNewStar= 1
		FROM
			#TempTable T
		WHERE
			FirstLineIsNewAWT = 1 
			AND 
			FirstLineIsNonTAB = 1
	
		UPDATE
			T
		SET
			FirstLineRepeatStar = 1
		FROM
			#TempTable T
		WHERE
			FirstLineIsAWT = 1 
			AND 
			FirstLineIsNonTAB = 1 
			AND 
			FirstLineNewStar = 0	
	

		UPDATE
			T
		SET
			T.SecondLineNewStar = 1
		FROM
			#TempTable T
		WHERE
			SecondLineIsNewAWT = 1 
			AND 
			SecondLineIsNonTAB = 1 
			AND 
			FirstLineIsNonTAB = 1 
			AND 
			FirstLineNewStar = 0
			AND
			FirstLineRepeatStar = 0
	
		UPDATE
			T
		SET
			T.SecondLineRepeatStar = 1
		FROM
			#TempTable T
		WHERE
			SecondLineIsAWT = 1 
			AND 
			SecondLineIsNonTAB = 1  
			AND 
			SecondLineNewStar = 0
			AND 
			FirstLineIsNonTAB = 1 
			AND 
			FirstLineNewStar = 0
			AND
			FirstLineRepeatStar = 0 

		UPDATE
			T
		SET
			T.ThirdLineNewStar = 1
		FROM
			#TempTable T
		WHERE
			ThirdLineIsNewAWT = 1 
			AND 
			ThirdLineIsNonTAB = 1 
			AND
			SecondLineIsNonTAB = 1  
			AND
			SecondLineNewStar = 0
			AND
			SecondLineRepeatStar = 0
			AND
			FirstLineIsNonTAB = 1 
			AND 
			FirstLineNewStar = 0
			AND
			FirstLineRepeatStar = 0


		UPDATE
			T
		SET
			T.ThirdLineRepeatStar = 1
		FROM
			#TempTable T
		WHERE
			ThirdLineIsAWT = 1 
			AND 
			ThirdLineIsNonTAB = 1 
			AND
			ThirdLineNewStar = 0
			AND
			SecondLineIsNonTAB = 1  
			AND
			SecondLineNewStar = 0
			AND
			SecondLineRepeatStar = 0
			AND
			FirstLineIsNonTAB = 1 
			AND 
			FirstLineNewStar = 0
			AND
			FirstLineRepeatStar = 0

		/***** NO DOBLE COUNTING *****/

		UPDATE
			LvL 
		SET
			LvL.ThirdLineNewStar = 0,
			LvL.ThirdLineRepeatStar = 0
		FROM
			#TempTable LvL
		INNER JOIN
		(SELECT PK_Distributor,PK_ThirdDownLine
		FROM
			#TempTable LvL3
		WHERE 
			(LvL3.ThirdLineNewStar  = 1 OR LvL3.ThirdLineRepeatStar =1)
		AND (EXISTS ( SELECT 1 FROM #TempTable LvL2 
						 WHERE LvL3.PK_ThirdDownLine = LvL2.PK_SecondDownLine AND (LvL2.SecondLineNewStar = 1 OR LvL2.SecondLineRepeatStar = 1))
		OR EXISTS (SELECT 1 FROM #TempTable LvL1 
					 WHERE LvL3.PK_ThirdDownLine = LvL1.PK_FirstDownLine AND (LvL1.FirstLineNewStar = 1 OR LvL1.FirstLineRepeatStar =1))
			)
		 ) LS
		ON
			LvL.PK_Distributor = LS.PK_Distributor 
			AND
			LvL.PK_ThirdDownLine = LS.PK_ThirdDownLine 

		UPDATE  
		 LvL   
		SET  
		 LvL.SecondLineNewStar = 0,
		 LvL.SecondLineRepeatStar = 0  
		FROM  
		 #TempTable LvL  
		INNER JOIN  
		(SELECT PK_Distributor,PK_SecondDownLine  
		FROM  
		 #TempTable LvL2  
		WHERE   
		 (LvL2.SecondLineNewStar=1 OR LvL2.SecondLineRepeatStar=1 ) 
		AND EXISTS (	SELECT	1 
						FROM	#TempTable LvL1   
						WHERE LvL2.PK_SecondDownLine = LvL1.PK_FirstDownLine AND (LvL1.FirstLineNewStar =1 OR LvL1.FirstLineRepeatStar =1)
					)  
		) LS  
		ON  
		 LvL.PK_Distributor = LS.PK_Distributor   
		 AND  
		 LvL.PK_SecondDownLine = LS.PK_SecondDownLine  



		/*WIPE DOWNLINE*/
		TRUNCATE TABLE dbo.wrk_NonTABAWT_Star_DownlineDetails

		/*Final Insert*/

		INSERT INTO dbo.wrk_NonTABAWT_Star_DownlineDetails
		(
			[PK_Distributor],
			[PK_FirstDownLine],
			[FirstLineIsNonTAB],
			[FirstLineIsAWT],
			[FirstLineIsNewAWT],
			[FirstLineNewStar], 
			[FirstLineRepeatStar], 
			[PK_SecondDownLine], 
			[SecondLineIsNonTAB], 
			[SecondLineIsAWT], 
			[SecondLineIsNewAWT], 
			[SecondLineNewStar], 
			[SecondLineRepeatStar], 
			[PK_ThirdDownLine], 
			[ThirdLineIsNonTAB], 
			[ThirdLineIsAWT], 
			[ThirdLineIsNewAWT], 
			[ThirdLineNewStar], 
			[ThirdLineRepeatStar] 
		)
		SELECT
			[PK_Distributor],
			[PK_FirstDownLine],
			[FirstLineIsNonTAB],
			[FirstLineIsAWT],
			[FirstLineIsNewAWT],
			[FirstLineNewStar], 
			[FirstLineRepeatStar], 
			[PK_SecondDownLine], 
			[SecondLineIsNonTAB], 
			[SecondLineIsAWT], 
			[SecondLineIsNewAWT], 
			[SecondLineNewStar], 
			[SecondLineRepeatStar], 
			[PK_ThirdDownLine], 
			[ThirdLineIsNonTAB], 
			[ThirdLineIsAWT], 
			[ThirdLineIsNewAWT], 
			[ThirdLineNewStar], 
			[ThirdLineRepeatStar] 
		FROM #TempTable

		/******************************************************************************
			END PROCEDURE
		******************************************************************************/
		EXEC usp_Utility_UpdateProcessingLog
			@StoredProcedureName = @StoredProcedure
			,@StoredProcedureParameters = @PromoStartDate
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
		RETURN 
	END CATCH

END
