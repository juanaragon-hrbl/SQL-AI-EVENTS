CREATE PROCEDURE [dbo].[usp_QualStd_DSTypeQualifyingSupervisor]  

	-- Error Parameters
	@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS  
BEGIN  
/******************************************************************************  
OBJECT:  dbo.usp_QualStd_DSTypeQualifyingSupervisor
  
USE:			
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_QualStd_DSTypeQualifyingSupervisor 
			@Error = @e OUTPUT
            ,@ErrorMessage = @em OUTPUT
            ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:  Get QS records
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------    
2   2016-11-11		SandhyaP	Netizza reference changes  
3	2019-09-30		NoeG		SRE template applied

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
  
		SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'QS'  
  
		/******************************************************************************  
		 get current distriburor who are not supervisors  
		******************************************************************************/  
		IF OBJECT_ID ('tempdb..#distqual') IS NOT NULL DROP TABLE #distqual  
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
		 ,CASE WHEN D.QSQualDate = 19000101 THEN NULL WHEN D.QSQualDate IS NULL THEN NULL ELSE DATEADD(M,DATEDIFF(M,0,CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112)),0) END AS dQSQualification  
		 ,C.nCountryID  
		 ,CASE WHEN D.StatusCode = 'COMPLETE' THEN 0 ELSE 1 END  
		 ,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END  
		 ,CASE WHEN ISNULL(F.FlagValues,'N') = 'N' THEN 0 ELSE 1 END AS IsDNR  
		FROM  
		 pubEvents.dbo.dimDistributor D WITH (NOLOCK)
		INNER JOIN  
		 dbo.v_Countries C  
		 ON  
		  D.PK_COP = C.nCountryID  
		INNER JOIN
		 pubEvents.dbo.dimDSSubType DST WITH (NOLOCK)
		ON
		D.PK_DSSubType = DST.PK_DSSubType	
		AND
		 DST.SubTypeCode IN ('2QS', '5QS', 'PQS', 'QS', 'QV', 'SQS') --(7,11,24,27,28,33)  
		LEFT JOIN  
		 (SELECT nDistributorID FROM dbo.v_IsType23Distributor) T  
		 ON D.PK_Distributor= T.nDistributorID  
		LEFT JOIN
		 pubEvents.dbo.dimDSFlagsHMS F (NOLOCK)
		 ON D.PK_Distributor = F.PK_Distributor
		WHERE   
 			D.DistributorID NOT IN (SELECT D2.DistributorID FROM DBLists.dbo.DSList D1 WITH (NOLOCK) INNER JOIN DBLists.dbo.DSListDetail D2 WITH (NOLOCK)
									ON D1.PK_DSList = D2.PK_DSList WHERE D1.DSListName IN ('Test IDs','MSTR Reporting Exclude'))
			AND
			(D.PK_DSType <>  (SELECT PK_DSType FROM pubEvents.dbo.dimDSType WITH (NOLOCK) WHERE TypeCode = 'CS') OR D.PK_Distributor IN (1,2))	
  
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