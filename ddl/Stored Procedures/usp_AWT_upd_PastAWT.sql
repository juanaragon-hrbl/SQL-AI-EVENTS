CREATE PROCEDURE [dbo].[usp_AWT_upd_PastAWT]
	@AWTYear int
	,@IsDevQA bit = 0
	,@Today datetime = NULL
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_upd_PastAWT

USE:			dbo.usp_AWT_upd_PastAWT
					@AWTYear = 2021
					,@IsDevQA = 1

DESCRIPTION:	updates the PastAWT column

DEPENDENCIES
--------------------------------------------------------------------
everything

VERSIONS
--------------------------------------------------------------------
1	2010-01-05	Scott			Initial
2   2020-07-07	Emi				Populate PastAWT only for newly qualified
3	2021-08-18	alejandramed	Including validation over PastAWT field to avoid year duplicaton in case of run the AWT process more than once in the same month
4	2021-09-23	alejandramed	Re-coding the logic for tranfer and divorce cases  
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()

DECLARE @Year int = 2006
DECLARE @YearSearch varchar(5)

SELECT @Today = ISNULL(@Today,CONVERT(DATE,GETDATE()))

WHILE @Year <= @AWTYear
BEGIN

	SELECT @YearSearch = RIGHT(@Year,2)

		;WITH cte_year_validation AS
		(
			SELECT Q.PK_Distributor,Q.DistributorID,Q.PastAWT
			FROM dbo.AWT Q WITH (NOLOCK) 
			WHERE Q.AWTYear = @AWTYear 
			AND CHARINDEX(@YearSearch, Q.PastAWT) > 0
		)

		UPDATE
			A
		SET
			PastAWT =  IIF(v.PK_Distributor IS NOT NULL, A.PastAWT,  
				CASE WHEN A.PastAWT = 'No' THEN --A
					 CASE WHEN @Year = @AWTYear THEN --B
							 CASE WHEN DT.nMainDistributorID IS NOT NULL THEN -- C -- TC OR DC
							 	--CASE WHEN (MONTH(A.DateAdded) = MONTH(@Today)) AND (YEAR(A.DateAdded) = YEAR(@Today)) THEN A.PastAWT --D
								--ELSE 
									CASE WHEN DT.[Transfer] = 1 
										THEN IIF(TC.PastAWT = 'No' AND DT.nDistributorID != A.PK_Distributor , RIGHT(CONVERT(varchar,@Year),2), TC.PastAWT )  -- E
									ELSE 
										CASE WHEN DT.[Transfer] = 0 THEN IIF(DC.PastAWT = 'No' AND DT.nMainDistributorID != A.PK_Distributor  , RIGHT(CONVERT(varchar,@Year),2), DC.PastAWT )  END -- F
									END	--E						
								--END --D
							END -- C
					ELSE RIGHT(CONVERT(varchar,@Year),2) END  --B
				ELSE --A
					CASE WHEN (MONTH(A.DateAdded) = MONTH(@Today)) AND (YEAR(A.DateAdded) = YEAR(@Today))  -- F
						THEN A.PastAWT 
						ELSE A.PastAWT + '-' + RIGHT(CONVERT(varchar,@Year),2) 
					END 
				END ) --A
		FROM
			dbo.AWT AS A 
			LEFT JOIN cte_year_validation AS V
				ON A.PK_Distributor = V.PK_Distributor
			LEFT JOIN dbo.v_DistributorAssociate2 DT
				ON A.PK_Distributor IN (DT.nMainDistributorID, DT.nDistributorID) 
			LEFT JOIN dbo.AWT AS DC -- Divorce cases
				ON DC.AWTYear = A.AWTYear AND DC.PK_Distributor = DT.nMainDistributorID AND DC.DateAdded < @Today AND DT.[Transfer] = 0
			LEFT JOIN dbo.AWT AS TC -- Tranfer cases
				ON TC.AWTYear = A.AWTYear AND TC.PK_Distributor = DT.nDistributorID AND TC.DateAdded < @Today AND DT.[Transfer] = 1
		WHERE EXISTS (SELECT PK_Distributor FROM dbo.AWT_Qualifiers Q (NOLOCK)
			WHERE Q.AWTYear = @Year
				AND Q.PK_Distributor IN (A.PK_Distributor,DT.nDistributorID, DT.nMainDistributorID))	
			AND
			A.AWTYear = @AWTYear
			AND
			A.DateAdded >= @Today 

	SET @Year += 1
END

/******************************************************************************
				END PROCEDURE
******************************************************************************/


	-- Update Processing Log
	EXEC [dbo].[usp_Utility_UpdateProcessingLog]
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime;
END