CREATE PROCEDURE [dbo].[usp_EventAPI_MW_EventDetails]
	-- Mandatory parameters
	 @DistributorID VARCHAR(10) = '2222222222'
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT
	,@IsDevQA BIT = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.[usp_EventAPI_MW_EventDetails]

USE:
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.[usp_EventAPI_MW_EventDetails]
					 	 @DistributorID = N'2222222222'
					 	,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
			            ,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the required details for the Distributor ID that was passed for the middleware team

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.Subevent, dbo.EventSKU, dbo.SKUPurchased

VERSIONS
----------------------------------------------------------------------------------
1	2016-05-05	SushmaA		Intitial
2	2019-09-05	NoeG		SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	/* ***************** SonarQube check 53 and 54 - Output parameters should be assigned 
	   SRE changes added
	*/

--DECLARE @DistributorID VARCHAR(20) = '2222222222'
DECLARE @PK_Distributor INT, @RegionCode VARCHAR(5)

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY
	SELECT @PK_Distributor = nDistributorID, @RegionCode = V.sRegionCode
	FROM dbo.v_Distributor D  WITH(NOLOCK) 
	JOIN dbo.v_Countries  V  WITH(NOLOCK)
		ON D.nDistributorCountryProcessingID = V.nCountryID
	WHERE sDistributorID = @DistributorID

	DECLARE @Countries AS TABLE (PK_Country INT)
	INSERT INTO @Countries (PK_Country)
	SELECT
		C.nCountryID
	FROM 
		dbo.v_Countries C
	WHERE
		C.sRegionCode = @RegionCode

	--TEMP TABLE FOR LIST OF EVENTS
	If object_id('tempdb..#Events') IS NOT NULL Drop Table #Events
	Create Table #Events
	(
		 PK INT IDENTITY(1,1)
		,PK_Event INT
		,EventName nVARCHAR(400)
		,PK_EventType INT
		,EventType VARCHAR(25)
		,EventStartDate DATETIME2
		,EventEndDate DATETIME2
		,Qualified BIT
	)

	INSERT INTO #Events
	(	 PK_Event
		,EventName
		,PK_EventType	
		,EventType
		,EventStartDate
		,EventEndDate
		,Qualified
	)
	SELECT DISTINCT
		 E.PK_Event
		,E.EventName
		,E.PK_EventType	
		,ET.EventType
		,E.dStartUTC
		,E.dEndUTC
		,EQ.Qualified
	FROM
		dbo.Event  E WITH(NOLOCK)
	INNER JOIN
		dbo.EventType ET WITH(NOLOCK) 
	ON
		E.PK_EventType = ET.PK_EventType
	INNER JOIN
		dbo.EventQualifier EQ WITH(NOLOCK) 
	ON
		E.PK_Event = EQ.PK_Event
	INNER JOIN
		dbo.EventDistributorCountry  ED WITH(NOLOCK)
	ON
		E.PK_Event = ED.PK_Event
	INNER JOIN
		@Countries C
	ON
		ED.PK_Country = C.PK_Country
	WHERE
		E.PK_EventType IN (1,2)
	AND
		EQ.PK_Distributor = @PK_Distributor
	AND
		EQ.Qualified = 1

	--TABLE 1: EVENTS LIST	
	SELECT 
		 E.PK_Event [EventID]
		,E.EventName
		--,E.PK_EventType	
		,E.EventType
		,E.EventStartDate
		,E.EventEndDate
		,E.Qualified 
	FROM 
		#Events E
	ORDER BY E.EventStartDate DESC	

	--TABLE 2: SUBEVENTS LIST
	SELECT
		 SE.PK_SubEvent
		,SE.PK_Event 
		,SE.SubEventName
		,SEQ.Qualified
		,SEQ.QualDate
	FROM
		dbo.SubEventQualifier SEQ WITH(NOLOCK) 
	INNER JOIN
		dbo.SubEvent SE WITH(NOLOCK)
	ON 
		SEQ.PK_Event = SE.PK_Event
	AND
		SEQ.PK_SubEvent = SE.PK_SubEvent	
	INNER JOIN
		#Events E
	ON
		SEQ.PK_Event = E.PK_Event
	WHERE
		SEQ.PK_Distributor = @PK_Distributor
	AND
		SE.isTrackingVisible = 1
	ORDER BY
		SE.PK_Event, SE.PK_SubEvent	
	
	--TABLE 3: SKU PURCHASED LIST
	SELECT 
		 E.PK_Event
		,ESK.SKUCode
		,ESK.SKUDesc
		,SUM(ISNULL(SKP.Quantity, 0)) [TicketsPurchased]
	FROM 
		#Events E
	INNER JOIN
		dbo.EventSKU  ESK WITH(NOLOCK)
	ON
		E.PK_Event = ESK.PK_Event
	LEFT JOIN
		dbo.SKUPurchased  SKP WITH(NOLOCK)
	ON
		ESK.PK_EventSKU = SKP.PK_EventSKU
	WHERE
		ESK.IsEventTicketSKU = 1 AND ESK.IsTrackingVisible = 1 AND SKP.PK_Distributor_Purchaser = @PK_Distributor
	GROUP BY
		E.PK_Event, ESK.SKUDesc, ESK.SKUCode	

	--TABLE 4: AWT QUAL AND REQUAL DETAILS
	If object_id('tempdb..#AWT') IS NOT NULL Drop Table #AWT          
	Create Table #AWT          
	(          
	 AWTYear Int,           
	 RoyaltyMonth datetime,
	 FirstTime BIT
	) 

         
	INSERT  #AWT  (AWTYear, RoyaltyMonth, FirstTime)     
	SELECT
			AWT.AWTYear
		   ,AWT.Qual_AWT [RoyaltyMonth]
		   ,CASE WHEN AWT.PastAWT = 'No' THEN 1 ELSE 0 END [FirstTime]
	FROM
		   dbo.AWT AWT WITH(NOLOCK)
	WHERE
		   AWT.PK_Distributor = @PK_Distributor 
	ORDER BY 
		   RoyaltyMonth DESC          


	SELECT AWTYear
		  ,RoyaltyMonth
		  ,FirstTime FROM #AWT	   

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
	
END