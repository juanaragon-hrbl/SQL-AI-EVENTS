CREATE PROCEDURE [dbo].[usp_EventAPI_Upd_RegisterAttendee]
	-- Mandatory parameters
	 @PK_Event INT  
	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Upd_RegisterAttendee

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_EventAPI_Upd_RegisterAttendee

					 	@PK_Event = 193950
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	This is refreshing the SubEventRegistration data on those events using Mailout program; 
				
				In case the subevent qualifications have changed after checked-in, the SubEventRegistration records 
				must reflect the new qualications in order to display the correct data in the mobile report
				
				Running on mobile report process only for those events flagged as HasMailOut = 1

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2023-04-14	alejandramed	Intitial
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
 

BEGIN TRY

		  
	--) Updated SubEventQualifier data
	--------------------------------------------------------------------------------------------------------------------

	DROP TABLE IF EXISTS #SubEventQualifier

	SELECT PK_SubEventQualifier,PK_Event, PK_SubEvent,DistributorID,PK_Distributor 
	INTO #SubEventQualifier
	FROM dbo.[SubEventQualifier] WITH (NOLOCK) WHERE PK_Event = @PK_Event AND Qualified = 1 AND RemovedUTC = '2049-12-31'

	DROP TABLE IF EXISTS #EventsRegistration

	SELECT PK_EventsRegistration,PK_Distributor,DistributorID  
	INTO #EventsRegistration
	FROM dbo.EventsRegistration 
	WHERE PK_Event = @PK_Event  AND Registered = 1 
	 
	DROP TABLE IF EXISTS #SubEventRegistration

	SELECT PK_EventsRegistration,seq.PK_SubEventQualifier, seq.PK_SubEvent, seq.PK_Distributor, seq.DistributorID 
	INTO #SubEventRegistration
	FROM #SubEventQualifier AS seq
	INNER JOIN #EventsRegistration AS er
		ON seq.DistributorID = er.DistributorID
	
	--) Current SubEventRegistration data (at the momement of checked-in)
	--------------------------------------------------------------------------------------------------------------------

	DROP TABLE IF EXISTS #cSubEventRegistration

	SELECT 
		ser.PK_SubEventRegistration,
		ser.CreatedDateUTC,
		ser.CreatedBy, 
		ser.ModifiedDateUTC,
		ser.ModifiedBy,
		ser.PK_EventsRegistration,
		ser.PK_SubEventQualifier,
		ser.Registered, 
		er.DistributorID, 
		er.PK_Distributor 
	INTO #cSubEventRegistration
	FROM dbo.SubEventRegistration AS ser
		INNER JOIN dbo.EventsRegistration AS er
			ON ser.PK_EventsRegistration = er.PK_EventsRegistration
	WHERE er.PK_Event = @PK_Event 
	
	--) Getting the SubEventRegistration records for those subevents for which the DS eligible after checked-in
	--------------------------------------------------------------------------------------------------------------------

	DROP TABLE IF EXISTS #insert_SubEventRegistration

	SELECT
		ser.PK_EventsRegistration,
		ser.PK_SubEventQualifier
	INTO #insert_SubEventRegistration
	FROM #SubEventRegistration AS ser WHERE  
	NOT EXISTS (SELECT 1 FROM #cSubEventRegistration AS cser 
	WHERE cser.PK_EventsRegistration = ser.PK_EventsRegistration AND cser.PK_SubEventQualifier = ser.PK_SubEventQualifier)

	IF @IsDevQA = 0
	BEGIN

		INSERT INTO [dbo].[SubEventRegistration]
				   ([CreatedBy]
				   ,[ModifiedBy]
				   ,[PK_EventsRegistration]
				   ,[PK_SubEventQualifier]
				   ,[Registered])
		  SELECT 
			   CONCAT('S99-',@PK_Event)
			  ,CONCAT('S99-',@PK_Event)
			  ,i.PK_EventsRegistration
			  ,i.PK_SubEventQualifier
			  ,1
		  FROM #insert_SubEventRegistration AS i
		  WHERE NOT EXISTS (SELECT 1 FROM dbo.[SubEventRegistration] ser WITH (NOLOCK) WHERE ser.[PK_EventsRegistration] = i.[PK_EventsRegistration] 
			AND ser.[PK_SubEventQualifier] = i.[PK_SubEventQualifier])
	END

	--) Getting the SubEventRegistration records for those subevents for which the DS is no longer eligible
	--------------------------------------------------------------------------------------------------------------------

	DROP TABLE IF EXISTS #delete_SubEventRegistration

	SELECT 
		ser.PK_SubEventRegistration,
		ser.CreatedDateUTC,
		ser.CreatedBy, 
		ser.ModifiedDateUTC,
		ser.ModifiedBy,
		ser.PK_EventsRegistration,
		ser.PK_SubEventQualifier,
		ser.Registered
	INTO #delete_SubEventRegistration
	FROM #cSubEventRegistration AS ser WHERE 
	NOT EXISTS (SELECT 1 FROM #SubEventRegistration  AS cser 
	WHERE cser.PK_EventsRegistration = ser.PK_EventsRegistration AND cser.PK_SubEventQualifier = ser.PK_SubEventQualifier)

	IF @IsDevQA = 0
	BEGIN

		INSERT INTO dbo.SubEventRegistration_Archive(PK_SubEventRegistration,
			CreatedDateUTC,
			CreatedBy, 
			ModifiedDateUTC,
			ModifiedBy,
			PK_EventsRegistration,
			PK_SubEventQualifier,
			Registered)
		SELECT 
			PK_SubEventRegistration,
			CreatedDateUTC,
			CreatedBy, 
			ModifiedDateUTC,
			ModifiedBy,
			PK_EventsRegistration,
			PK_SubEventQualifier,
			Registered
		FROM #delete_SubEventRegistration AS d
		WHERE NOT EXISTS (SELECT 1 FROM dbo.[SubEventRegistration] AS ser WITH (NOLOCK) 
				WHERE ser.[PK_EventsRegistration] = d.[PK_EventsRegistration] AND ser.[PK_SubEventQualifier] = d.[PK_SubEventQualifier])

		DELETE ser 
		FROM dbo.[SubEventRegistration] AS ser
			INNER JOIN #delete_SubEventRegistration AS d
			ON ser.[PK_EventsRegistration] = d.[PK_EventsRegistration] AND ser.[PK_SubEventQualifier] = d.[PK_SubEventQualifier]

	END


	IF @IsDevQA = 1
	BEGIN
		SELECT * FROM #insert_SubEventRegistration
		SELECT * FROM #delete_SubEventRegistration
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
	END CATCH
END