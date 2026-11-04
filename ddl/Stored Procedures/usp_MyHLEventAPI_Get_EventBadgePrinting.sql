CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventBadgePrinting]	
	-- MANDATORY
	@PK_ER INT
	,@EventID INT
	,@UserID varchar(20)
	-- OPTIONAL
	,@Error	int = 0 OUTPUT 
	,@ErrorMessage varchar(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN


/*
OBJECT:		dbo.usp_MyHLEventAPI_Get_EventBadgePrinting

USE:		DECLARE @e int, @em varchar(200)	
			EXEC usp_MyHLEventAPI_Get_EventBadgePrinting
					@PK_ER = 830155 
					,@EventID = 801
					,@UserID = 's01-801'
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 0
			Print @em
DESCRIPTION: Get Badge Printing Information

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2013-01-15	OrlandoL	Initial
2	2019-08-14	NoeG		Refactor code (SRE)
2.1	2022-06-16	JonathanO	@PrivCodes VARCHAR(200) to MAX
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE
 @PrivCodes VARCHAR(MAX) = ''
,@SQL NVARCHAR(MAX) = ''
,@SE INT = 1
,@MAXSE INT
,@SENAME varchar(100) = ''
,@ActualUser INT

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

	
/******************************************************************************
Get SubEvents that the DS has qualified for 
******************************************************************************/
BEGIN TRY

	IF EXISTS (SELECT PK_Distributor FROM dbo.EventBadgePrinting WITH(NOLOCK) WHERE PK_EventsRegistration = @PK_ER AND PK_Event = @EventID)
	BEGIN
		/******************************************************************************
			Generate @PrivCodes based on EventBadgeSubEvents table
		******************************************************************************/
		SELECT 
			@PrivCodes = @PrivCodes +'E'+CONVERT(VARCHAR(10),BSE.PK_Event)+'.E'+  CONVERT(VARCHAR(2),BSE.SequenceNo)+',' 
		FROM
			dbo.EventBadgePrinting EBP WITH(NOLOCK)
		INNER JOIN	
			dbo.EventBadgeSubEvents BSE WITH(NOLOCK)
		ON 
			EBP.PK_Event = BSE.PK_Event
			AND
			EBP.PK_EventBadgePrinting = BSE.PK_EventBadgePrinting
		WHERE
			EBP.PK_EventsRegistration = @PK_ER
			AND
			EBP.PK_Event = @EventID
	
		SET @PrivCodes = SUBSTRING(@PrivCodes, 1, LEN(@PrivCodes)-1);
		SET @ActualUser = RIGHT(LEFT(@UserID,3),2)
	
		/******************************************************************************
			CREATE Temp Tables 
		******************************************************************************/
		IF OBJECT_ID ('tempDB..#Subevents', 'U')IS NOT NULL DROP TABLE #Subevents

		IF OBJECT_ID ('tempDB..#BadgePrintingInfo', 'U')IS NOT NULL DROP TABLE #BadgePrintingInfo
	
		CREATE TABLE #BadgePrintingInfo  
		(
		   Company VARCHAR(20)
		  ,FirstName VARCHAR(100)
		  ,LastName VARCHAR(100)
		  ,bCardChip INT
		  ,ProductionID INT
		  ,PrivCodes VARCHAR(MAX)
		  ,Plastic INT
		  ,Paper INT
		  ,EventID VARCHAR(10)
		  ,Country VARCHAR(50)
		  ,Title VARCHAR(50) 
		  ,Pod INT
		  ,EventCode VARCHAR(20)
		  ,ServiceKey VARCHAR(100)
		)
    
		CREATE TABLE #Subevents 
		(
			PK int IDENTITY(1,1) PRIMARY KEY
			,PK_Event INT
			,SubEventName varchar(250)
			,SubEventNumber varchar(20)
		)
	
	
		/******************************************************************************
			ADD PrintOnlyAux column with Sequence number 
		******************************************************************************/
		INSERT
			#Subevents
		(
			PK_Event,
			SubEventNumber,
			SubEventName		
		)
		SELECT
			BSE.PK_Event,
			'PrintOnlyAux' + CONVERT(VARCHAR(2),BSE.SequenceNo),
			BSE.SubEventDisplayName
		FROM
			dbo.EventBadgePrinting EBP WITH(NOLOCK)
		INNER JOIN	
			dbo.EventBadgeSubEvents BSE WITH(NOLOCK)
		ON
			EBP.PK_EventBadgePrinting = BSE.PK_EventBadgePrinting
			AND
			EBP.PK_Event = BSE.PK_Event
		WHERE
			EBP.PK_Event = @EventID
			AND
			EBP.PK_EventsRegistration = @PK_ER
		ORDER BY 
			BSE.SequenceNo
		
		SET @MAXSE = @@ROWCOUNT	
		
		SELECT
			@SQL = @SQL + 'ALTER TABLE #BadgePrintingInfo ADD [' + SubEventNumber + '] VARCHAR(100); ' 
		FROM
			#Subevents
		ORDER BY
			SubEventNumber
		
		EXEC sp_executesql @SQL
    
		PRINT @MAXSE
    
		/******************************************************************************
			Insert values into #BadgePrintingInfo
		******************************************************************************/  
		INSERT #BadgePrintingInfo
		(
		  Company 
		  ,FirstName
		  ,LastName
		  ,bCardChip 
		  ,ProductionID 
		  ,PrivCodes 
		  ,Plastic 
		  ,Paper 
		  ,EventID 
		  ,Country 
		  ,Title 
		  ,Pod 
		  ,EventCode 
		  ,ServiceKey 
		)
		SELECT
			EBP.DistributorID AS Company,
			EBP.FirstName,
			EBP.LastName,
			@PK_ER AS bCardChip,
			@EventID AS ProductionID,
			@PrivCodes AS PrivCodes, 
			1 AS Plastic,
			0 AS Paper,
			E.VendorEventID AS EventID,
			EBP.COP AS Country,
			EBP.TeamStatus AS Title,
			BP.PortNumber AS Pod,
			EX.EventCode,
			EX.ServiceKey
		FROM
			dbo.EventBadgePrinting EBP WITH(NOLOCK)
		INNER JOIN	
			dbo.EventBadgeSubEvents BSE WITH(NOLOCK)
		ON
			EBP.PK_EventBadgePrinting = BSE.PK_EventBadgePrinting
			AND
			EBP.PK_Event = BSE.PK_Event
		INNER JOIN
			dbo.Event E WITH(NOLOCK)
		ON
			EBP.PK_Event = E.PK_Event 
		INNER JOIN
			dbo.EventExtn EX WITH(NOLOCK)
		ON
			EBP.PK_Event = EX.PK_Event
		INNER JOIN
			dbo.EventBadgePortSetup BP WITH(NOLOCK)
		ON
			EBP.PK_Event = BP.PK_Event
			AND
			@ActualUser BETWEEN BP.BeginUserID AND BP.EndUserID 
		WHERE
			EBP.PK_Event = @EventID
			AND
			EBP.PK_EventsRegistration = @PK_ER


		/******************************************************************************
			Insert SubEvent Names 
		******************************************************************************/ 
		WHILE @SE <= @MaxSE
		BEGIN
			SELECT 
				@SENAME = SubEventNumber
			FROM
				#Subevents SE
			WHERE
				SE.PK = @SE
			ORDER BY
				SubEventNumber
		
			SET @sql = '
			UPDATE 
				R
			SET 
				[' + @SENAME + '] = SE.SubEventName
			FROM 
				#BadgePrintingInfo R
			INNER JOIN
				#Subevents SE
				ON
				R.ProductionID = SE.PK_Event
				AND
				SE.PK = ' + CONVERT(varchar,@SE)

			EXEC sp_executesql @sql
			SET @SE += 1
		END
	
		SELECT PK, PK_Event, SubEventName, SubEventNumber FROM #Subevents 
	
		SELECT DISTINCT  
		   Company 
		  ,FirstName
		  ,LastName
		  ,bCardChip 
		  ,ProductionID 
		  ,PrivCodes 
		  ,Plastic 
		  ,Paper 
		  ,EventID 
		  ,Country 
		  ,Title 
		  ,Pod 
		  ,EventCode 
		  ,ServiceKey 
		FROM #BadgePrintingInfo
	END

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
	END Procedure
******************************************************************************/
END