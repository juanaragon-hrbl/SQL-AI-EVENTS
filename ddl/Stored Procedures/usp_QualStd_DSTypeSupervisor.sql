CREATE PROCEDURE [dbo].[usp_QualStd_DSTypeSupervisor]
       @IsDevQA		BIT = 0,   
	   @Error	int = 0 OUTPUT,
	   @ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_QualStd_DSTypeSupervisor
		
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_QualStd_DSTypeSupervisor 
				
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

SET @ProcName = 'usp_QualStd_DSTypeSupervisor'
SET @ProcParam = ''
SET @StartTime = GETUTCDATE()


DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)

SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'SP'

BEGIN TRY
/******************************************************************************
	get current supervisors
******************************************************************************/
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
	,D.nDistributorID
	,D.dSupervisorQualification
	,C.nCountryID
	,CASE WHEN D.dDeleted = '2049-12-31' THEN 0 ELSE 1 END
	,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END
	,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
FROM
	dbo.v_Distributor D WITH (NOLOCK)
INNER JOIN
	dbo.v_Countries C WITH (NOLOCK)
	ON
		D.sDistributorCountryProcessingCode = C.sCountryCode
LEFT JOIN
	(SELECT nDistributorID FROM dbo.v_IsType23Distributor WITH (NOLOCK)) T
	ON D.nDistributorID = T.nDistributorID
LEFT JOIN
	dbo.v_DistributorDoNotRecognize R WITH (NOLOCK)
	ON
		D.nDistributorID = R.PK_Distributor
WHERE
	D.sType IN ('SP','RS','RB')

/******************************************************************************
	remove distributors from qualfication in production table
******************************************************************************/
DELETE FROM
	dbo.QualificationDistributor
WHERE
	PK_Qualification = @QualID

/******************************************************************************
	add new qualifiers
******************************************************************************/
INSERT
	dbo.QualificationDistributor
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
	PK_Qualification
	,PK_Distributor
	,RoyaltyMonth
	,PK_Country
	,IsDeleted
	,IsType23
	,IsDNR
FROM
	#distqual

/******************************************************************************
	end procedure
******************************************************************************/

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