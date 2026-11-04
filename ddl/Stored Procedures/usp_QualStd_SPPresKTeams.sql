CREATE PROCEDURE [dbo].[usp_QualStd_SPPresKTeams]
       @IsDevQA		BIT = 0,   
	   @Error	int = 0 OUTPUT,
	   @ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_QualStd_SPPresKTeams
		
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_QualStd_SPPresKTeams 
				
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
	NOTES:		

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2010
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1	
	2	2019-10-16	 JonathanO		Refactor code (SRE)


***********************************************************************************************************************************/
/***********************************************************************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@QualID int
	,@ProcName varchar(100)
	,@ProcParam varchar(100)
	,@StartTime datetime2
	,@BeginCurrMonth datetime

SET @ProcName = 'usp_QualStd_SPPresKTeams'
SET @ProcParam = ''
SET @StartTime = GETUTCDATE()
SET @BeginCurrMonth = CONVERT(DATETIME,CONVERT(varchar(8),GETUTCDATE(),120) + '01',120)

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
	
BEGIN TRY
/***********************************************************************************
	Define all the Pres Earning levels and Get all Current Pres Earning Levels
***********************************************************************************/
IF OBJECT_ID('tempdb..#EarnTeam') IS NOT NULL DROP TABLE #EarnTeam
CREATE TABLE #EarnTeam (PK_Qual int,SubTeam varchar(5))

INSERT INTO #EarnTeam(SubTeam)
VALUES
	  ('GP')
	 ,('MP')
	 ,('PT')
	 ,('15K')
	 ,('20K')
	 ,('30K')
	 ,('40K')
	 ,('50K')
	 ,('60K')
	 ,('70K')
	 ,('80K')
	 ,('90K')
	 
UPDATE 
	ET 
SET
	PK_Qual = Q.PK_Qualification 
FROM
	#EarnTeam ET
INNER JOIN
	dbo.Qualification Q WITH (NOLOCK)
ON
	Q.PK_QualificationType = 5 
	AND
	Q.QualificationAbbreviation = ET.SubTeam 
	 
IF OBJECT_ID('tempdb..#distqual') IS NOT NULL DROP TABLE #distqual
	 
CREATE TABLE #distqual (
	PK_Qualification int
	,PK_Distributor int
	,RoyaltyMonth smalldatetime
	,PK_Country int
	,IsDeleted bit
	,IsType23 bit
	,IsDNR bit
)
	 
INSERT
	#distqual
		(	
		PK_Qualification
		,PK_Distributor
		,RoyaltyMonth
		,PK_Country
		,IsDeleted
		,IsType23
		,IsDNR
		)
SELECT
		ET.PK_Qual
		,D.PK_Distributor
		,@BeginCurrMonth
		,D.PK_COP
		,CASE WHEN D.StatusCode = 'COMPLETE' THEN 0 ELSE 1 END
		,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END
		,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
	FROM
		pubEvents.dbo.dimDistributor D WITH (NOLOCK)
	INNER JOIN
		#EarnTeam ET
	ON
		D.SubTypeCode = ET.SubTeam 
	LEFT JOIN
		(SELECT nDistributorID FROM dbo.v_IsType23Distributor WITH (NOLOCK)) T
	ON 
		D.PK_Distributor = T.nDistributorID
	LEFT JOIN
		dbo.v_DistributorDoNotRecognize R WITH (NOLOCK)
	ON
		D.PK_Distributor = R.PK_Distributor

 CREATE INDEX IX_#distqual_PK_Distributor ON #distqual(PK_Distributor)
/******************************************************************************
	Merge distributors from qualfication in production table
******************************************************************************/
; WITH Teams(PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR) AS
(SELECT QD.PK_Qualification,QD.PK_Distributor,QD.RoyaltyMonth,QD.PK_Country,QD.IsDeleted,QD.IsType23,QD.IsDNR 
 FROM dbo.QualificationDistributor QD WITH (NOLOCK) 
 INNER JOIN #EarnTeam ET ON QD.PK_Qualification = ET.PK_Qual)
 MERGE Teams PT
 USING #distqual DQ
 ON PT.PK_Distributor = DQ.PK_Distributor AND PT.PK_Qualification = DQ.PK_Qualification
 WHEN MATCHED AND (PT.IsDeleted <> DQ.IsDeleted OR PT.IsType23 <> DQ.IsType23 OR PT.IsDNR <> DQ.IsDNR) THEN
 UPDATE
	SET
		PT.RoyaltyMonth = DQ.RoyaltyMonth
		,PT.PK_Country = DQ.PK_Country
		,PT.IsDeleted = DQ.IsDeleted
		,PT.IsType23 = DQ.IsType23
		,PT.IsDNR = DQ.IsDNR
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
WHEN NOT MATCHED BY TARGET THEN
	INSERT	(PK_Qualification
			,PK_Distributor
			,RoyaltyMonth
			,PK_Country
			,IsDeleted
			,IsType23
			,IsDNR
		   )
	VALUES (DQ.PK_Qualification
			,DQ.PK_Distributor
			,DQ.RoyaltyMonth
			,DQ.PK_Country
			,DQ.IsDeleted
			,DQ.IsType23
			,DQ.IsDNR
		   );

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

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;