
CREATE PROCEDURE [dbo].[usp_QualStd_DSTypeNonSupervisor]
	
	-- Error Parameters
	@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************

OBJECT:  dbo.usp_QualStd_DSTypeNonSupervisor
  
USE:			
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_QualStd_DSTypeNonSupervisor 
			@Error = @e OUTPUT
            ,@ErrorMessage = @em OUTPUT
            ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]
  
DESCRIPTION:  get current distriburor who are not supervisors
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------    
1								Initial
2	2019-09-30		NoeG		SRE template applied
3	2020-11-26		SushmaA		Exclude PM tyoes from being picked up in PK_Qual 2
******************************************************************************/  

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@ProcParam varchar(100) = ''
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE 
			@QualID int

		SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'NonSP'

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
			@QualID
			,D.PK_Distributor 
			,CONVERT(DATETIME,CONVERT(VARCHAR, D.ApplicationDate),112) 
			,D.PK_COP 
			,CASE WHEN D.StatusCode = 'COMPLETE' THEN 0 ELSE 1 END
			,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END
			,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
		FROM
			pubEvents.dbo.dimDistributor D WITH (NOLOCK)
		LEFT JOIN
			(SELECT nDistributorID FROM dbo.v_IsType23Distributor WITH (NOLOCK)) T
			ON D.PK_Distributor = T.nDistributorID
		LEFT JOIN
			dbo.v_DistributorDoNotRecognize R WITH (NOLOCK)
			ON
				D.PK_Distributor = R.PK_Distributor
		WHERE
			D.TypeCode NOT IN ('SP','RS','RB', 'MB', 'NM', 'PM')

		CREATE INDEX IX_#distqual_PK_Distributor ON #distqual(PK_Distributor)

		/******************************************************************************
			remove distributors from qualfication in production table
		******************************************************************************/
		--DELETE FROM
		--	dbo.QualificationDistributor
		--WHERE
		--	PK_Qualification = @QualID

		; WITH NonSP(PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR) AS
		(SELECT PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR 
		 FROM dbo.QualificationDistributor WITH (NOLOCK) WHERE PK_Qualification = @QualID)
		 MERGE NonSP NSP
		 USING #distqual DQ
		 ON NSP.PK_Distributor = DQ.PK_Distributor
		 WHEN MATCHED AND (NSP.IsDeleted <> DQ.IsDeleted OR NSP.IsType23 <> DQ.IsType23 OR NSP.IsDNR <> DQ.IsDNR) THEN
		 UPDATE
			SET
				NSP.RoyaltyMonth = DQ.RoyaltyMonth
				,NSP.PK_Country = DQ.PK_Country
				,NSP.IsDeleted = DQ.IsDeleted
				,NSP.IsType23 = DQ.IsType23
				,NSP.IsDNR = DQ.IsDNR
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

		/******************************************************************************
			add new qualifiers
		******************************************************************************/
		--ALTER INDEX IX_QualificationDistributor_PK_Qualification ON dbo.QualificationDistributor DISABLE

		--INSERT
		--	dbo.QualificationDistributor
		--(
		--	PK_Qualification
		--	,PK_Distributor
		--	,RoyaltyMonth
		--	,PK_Country
		--	,IsDeleted
		--	,IsType23
		--	,IsDNR
		--)
		--SELECT
		--	PK_Qualification
		--	,PK_Distributor
		--	,RoyaltyMonth
		--	,PK_Country
		--	,IsDeleted
		--	,IsType23
		--	,IsDNR
		--FROM
		--	#distqual

		--ALTER INDEX IX_QualificationDistributor_PK_Qualification ON dbo.QualificationDistributor REBUILD

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StoredProcedureParameters = @ProcParam
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
	END CATCH

/******************************************************************************
	end procedure
******************************************************************************/

END