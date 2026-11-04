CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_ActiveSPPromo]
	  -- Mandatory parameters  
	  @PK_Event INT = 73829  
	 ,@LocaleCode CHAR(5)  
	 -- Optional Parameters  
	 ,@DistributorID VARCHAR(10) = '2222222222' 
	 ,@Year INT = 2020

    --Error Parameters
	,@Error	int = NULL OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

		--QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************  
OBJECT:   dbo.[usp_MyHLEventAPI_CustomTrackingPage_ActiveSPPromo]  
  
USE:           
			SELECT * FROM v_Distributor WHERE nDistributorID = 934456
			DECLARE @e int, @em varchar(4000)

            EXEC dbo.[usp_MyHLEventAPI_CustomTrackingPage_ActiveSPPromo]  
				@DistributorID = N'07103089'  
				,@PK_Event = 73829  
				,@LocaleCode = 'en-US'
				,@Year = 2020
				,@Error = @e OUTPUT  /* @e must be defined in the local call */
				,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
				,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
        
DESCRIPTION: This is a custom stored procedure that retreievs all the details for the   
                EMEA ASP Promo based on the sections defined for the Tracking Page.  
                The sections are specific to every event based on what the region decides  
                to display on the tracking page  
                  
                73829 == EMEA ASP Promo 2020 
  
NOTES:     
  
DEPENDENCIES  
----------------------------------------------------------------------------------  
  
VERSIONS  
----------------------------------------------------------------------------------  
1	2020-02-05		alejandramed			Intitial  
2	2020-03-21		alejandramed			Show the highest stone subevent the DS qualify for
******************************************************************************/  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT OFF  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

BEGIN TRY

	BEGIN TRANSACTION

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

	/* DECLARE THE REQUIRED VARIABLES */  
	DECLARE @PK_Distributor INT  
			,@PK_Locale INT  
			,@PK_DefaultLocale INT  
			,@COP CHAR (2) = NULL  
			,@TotalASPCount INT = 0
		
	/* SET THE VALUES FOR THE DECLARED VARIABLES */  
	SELECT @Error = 0, @ErrorMessage = '';

	SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID  
	SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode  
	SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @PK_Event  
  

	/* DECLARE A TEMP TABLE TO DISPLAY THE VOLUME DETAILS PER THE REQUIREMENT */
	IF OBJECT_ID('tempdb..#ASPQualDateDetails') IS NOT NULL DROP TABLE #ASPQualDateDetails
	IF OBJECT_ID('tempdb..#FianlResult') IS NOT NULL DROP TABLE #FianlResult
	IF OBJECT_ID('tempdb..#WRK_ActiveSPPromo') IS NOT NULL DROP TABLE #WRK_ActiveSPPromo

	/**********************************************
		SELECT DATA TO THIRD GRID
	**********************************************/
	SELECT
	  @PK_Distributor AS PK_Distributor
	 ,SE.PK_SubEvent
	 ,SE.SubEventName
	 ,SE.SubEventNumber
	 ,ISNULL(SQ.Qualified,0) [Qualified]
	 ,SQ.QualDate 
	 ,CASE WHEN ISNULL(SQ.Qualified,0) = 1 THEN 1 
		   WHEN (SE.SubEventNumber = 1 AND ISNULL(SQ.Qualified,0) = 0 AND GETUTCDATE() <= '2020-12-31') 
			   OR (LAG(SQ.Qualified) OVER (ORDER BY SE.SubEventNumber) = 1) THEN 0
		   ELSE 2 END [QualificationStatus]
	,0 AS [TotalASPCount]
	INTO #FianlResult
	FROM  
	 dbo.SubEvent SE WITH (NOLOCK)  
	LEFT JOIN  
	 dbo.SubEventQualifier SQ WITH (NOLOCK)  
	ON  
	 SQ.PK_Event = SE.PK_Event  
	 AND SQ.PK_SubEvent = SE.PK_SubEvent  
	 AND SQ.RemovedUTC = '12-31-2049' 
	 AND SQ.Qualified = 1  
	 AND SQ.PK_Distributor = @PK_Distributor  
	WHERE  
	 SE.PK_Event = @PK_Event  
	ORDER BY
	 SE.SubEventNumber 
	 
	UPDATE #FianlResult
	SET Qualified = 0, QualDate = NULL

	SELECT
	    PK_Distributor
	   ,[CurrentOverAllCount]
	   ,COP
	   ,AcviteSupervisor_QualDate
	   ,Stone1_QualDate
	   ,TotalStone1
	   ,Stone2_QualDate
	   ,TotalStone2
	   ,Stone3_QualDate
	   ,TotalStone3
	   ,Stone4_QualDate
	   ,TotalStone4
	   ,Stone5_QualDate
	   ,TotalStone5
	   ,Stone6_QualDate
	   ,TotalStone6
	   ,Stone7_QualDate
	   ,TotalStone7
	   ,Stone8_QualDate
	   ,TotalStone8
	   ,Stone9_QualDate
	   ,TotalStone9
	   ,Stone10_QualDate
	   ,TotalStone10
	   ,Stone11_QualDate
	   ,TotalStone11
	   ,Stone12_QualDate
	   ,TotalStone12
	   ,Stone13_QualDate
	   ,TotalStone13
	   ,Stone14_QualDate
	   ,TotalStone14
	   ,Stone15_QualDate
	   ,TotalStone15
	   ,Stone16_QualDate
	   ,TotalStone16
	   ,Stone17_QualDate
	   ,TotalStone17
	   ,Stone18_QualDate
	   ,TotalStone18
	   ,Stone19_QualDate
	   ,TotalStone19
	   ,Stone20_QualDate
	   ,TotalStone20
	   ,IsASP
	   ,IsStone1
	   ,IsStone2
	   ,IsStone3
	   ,IsStone4
	   ,IsStone5
	   ,IsStone6
	   ,IsStone7
	   ,IsStone8
	   ,IsStone9
	   ,IsStone10
	   ,IsStone11
	   ,IsStone12
	   ,IsStone13
	   ,IsStone14
	   ,IsStone15
	   ,IsStone16
	   ,IsStone17
	   ,IsStone18
	   ,IsStone19
	   ,IsStone20
	   ,nYear
	INTO #WRK_ActiveSPPromo 
	FROM  
	 dbo.WRK_ActiveSPPromo_EMEA WITH (NOLOCK)  
	WHERE
		PK_Distributor = @PK_Distributor
		AND
		nYear = @Year

	/************************************************************
		UPDATE Qualified Column from #ASPQualDateDetails per Level
	*************************************************************/
	UPDATE
		SP
	SET
		[TotalASPCount] = CASE WHEN ASP.TotalStone20 IS NOT NULL AND ASP.TotalStone20 > 0 THEN ASP.TotalStone20
								WHEN ASP.TotalStone19 IS NOT NULL AND ASP.TotalStone19 > 0 THEN ASP.TotalStone19
								WHEN ASP.TotalStone18 IS NOT NULL AND ASP.TotalStone18 > 0 THEN ASP.TotalStone18
								WHEN ASP.TotalStone17 IS NOT NULL AND ASP.TotalStone17 > 0 THEN ASP.TotalStone17
								WHEN ASP.TotalStone16 IS NOT NULL AND ASP.TotalStone16 > 0 THEN ASP.TotalStone16
								WHEN ASP.TotalStone15 IS NOT NULL AND ASP.TotalStone15 > 0 THEN ASP.TotalStone15
								WHEN ASP.TotalStone14 IS NOT NULL AND ASP.TotalStone14 > 0 THEN ASP.TotalStone14
								WHEN ASP.TotalStone13 IS NOT NULL AND ASP.TotalStone13 > 0 THEN ASP.TotalStone13
								WHEN ASP.TotalStone12 IS NOT NULL AND ASP.TotalStone12 > 0 THEN ASP.TotalStone12
								WHEN ASP.TotalStone11 IS NOT NULL AND ASP.TotalStone11 > 0 THEN ASP.TotalStone11
								WHEN ASP.TotalStone10 IS NOT NULL AND ASP.TotalStone10 > 0 THEN ASP.TotalStone10
								WHEN ASP.TotalStone9 IS NOT NULL AND ASP.TotalStone9 > 0 THEN ASP.TotalStone9
								WHEN ASP.TotalStone8 IS NOT NULL AND ASP.TotalStone8 > 0 THEN ASP.TotalStone8
								WHEN ASP.TotalStone7 IS NOT NULL AND ASP.TotalStone7 > 0 THEN ASP.TotalStone7
								WHEN ASP.TotalStone6 IS NOT NULL AND ASP.TotalStone6 > 0 THEN ASP.TotalStone6
								WHEN ASP.TotalStone5 IS NOT NULL AND ASP.TotalStone5 > 0 THEN ASP.TotalStone5
								WHEN ASP.TotalStone4 IS NOT NULL AND ASP.TotalStone4 > 0 THEN ASP.TotalStone4
								WHEN ASP.TotalStone3 IS NOT NULL AND ASP.TotalStone3 > 0 THEN ASP.TotalStone3
								WHEN ASP.TotalStone2 IS NOT NULL AND ASP.TotalStone2 > 0 THEN ASP.TotalStone2
								WHEN ASP.TotalStone1 IS NOT NULL AND ASP.TotalStone1 > 0 THEN ASP.TotalStone1
								ELSE 0 END
	   ,SP.Qualified = ASP.IsASP
	   ,SP.QualDate = ASP.AcviteSupervisor_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.AcviteSupervisor_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN
		#WRK_ActiveSPPromo ASP WITH(NOLOCK) 
	ON
		SP.PK_Distributor = ASP.PK_Distributor
	WHERE
		ASP.IsASP = 1	
		AND
		ASP.nYear = @Year
		AND
		SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 1 AND PK_Event = @PK_Event)
	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone1,0)
	   ,SP.QualDate = ASP.Stone1_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone1_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 2 AND PK_Event = @PK_Event)
	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone2,0)
	   ,SP.QualDate = ASP.Stone2_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone2_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 3 AND PK_Event = @PK_Event)
	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone3,0)
	   ,SP.QualDate = ASP.Stone3_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone3_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 4 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone4,0)
	   ,SP.QualDate = ASP.Stone4_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone4_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 5 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone5,0)
	   ,SP.QualDate = ASP.Stone5_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone5_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 6 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone6,0)
	   ,SP.QualDate = ASP.Stone6_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone6_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 7 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone7,0)
	   ,SP.QualDate = ASP.Stone7_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone7_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 8 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone8,0)
	   ,SP.QualDate = ASP.Stone8_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone8_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 9 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone9,0)
	   ,SP.QualDate = ASP.Stone9_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone9_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 10 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone10,0)
	   ,SP.QualDate = ASP.Stone10_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone10_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 11 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone11,0)
	   ,SP.QualDate = ASP.Stone11_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone11_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 12 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone12,0)
	   ,SP.QualDate = ASP.Stone12_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone12_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 13 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone13,0)
	   ,SP.QualDate = ASP.Stone13_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone13_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 14 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone14,0)
	   ,SP.QualDate = ASP.Stone14_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone14_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 15 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone15,0)
	   ,SP.QualDate = ASP.Stone15_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone15_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 16 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone16,0)
	   ,SP.QualDate = ASP.Stone16_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone16_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 17 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone17,0)
	   ,SP.QualDate = ASP.Stone17_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone17_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 18 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone18,0)
	   ,SP.QualDate = ASP.Stone18_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone18_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 19 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone19,0)
	   ,SP.QualDate = ASP.Stone19_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone19_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 20 AND PK_Event = @PK_Event)

	/*****************************************************************************************************/
	UPDATE
		SP
	SET
		SP.Qualified = ISNULL(ASP.IsStone20,0)
	   ,SP.QualDate = ASP.Stone20_QualDate
	   ,SP.QualificationStatus = CASE WHEN ASP.Stone20_QualDate IS NOT NULL THEN 1 ELSE 2 END
	FROM
		#FianlResult SP
	INNER JOIN #WRK_ActiveSPPromo ASP WITH(NOLOCK) ON SP.PK_Distributor = ASP.PK_Distributor
	WHERE ASP.IsASP = 1	AND ASP.nYear = @Year AND SP.PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 21 AND PK_Event = @PK_Event)


	/****************************************************************************************************/

	SELECT DISTINCT @TotalASPCount = [TotalASPCount] FROM #FianlResult WHERE PK_SubEvent = (SELECT PK_SubEvent FROM SubEvent WITH (NOLOCK) WHERE SubEventNumber = 1 AND PK_Event = @PK_Event)

	SELECT @TotalASPCount [TotalASPCount]

		SELECT PK_Distributor
			  ,PK_SubEvent
			  ,SubEventName
			  ,SubEventNumber
			  ,[Qualified]
			  ,CASE WHEN ((@TotalASPCount + 1) = SubEventNumber ) OR SubEventNumber = 1 THEN Qualified ELSE 0 END [IsDisplay]
			  ,QualDate
			  ,QualificationStatus
			  ,TotalASPCount FROM #FianlResult
		WHERE SubEventNumber BETWEEN 1 AND 21 

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;


	COMMIT TRANSACTION

END TRY
BEGIN CATCH  
	-- Error encountered  
	IF @@TRANCOUNT > 0
	BEGIN
		PRINT 'Error Occured. No Record set was retrieved.'
		ROLLBACK TRANSACTION
	END
	
		-- Raise an error with the details of the exception 
		DECLARE @ErrorSeverity AS INT 
		 
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()
		SET @ErrorSeverity = ERROR_SEVERITY()

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

