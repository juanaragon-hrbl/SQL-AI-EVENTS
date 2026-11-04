CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_EventBadgePrinting]
	-- MANDATORY
	@PK_ER INT 
	,@EventID INT
	,@SubEventTbl udt_SubEvents READONLY
	,@Title VARCHAR(30)
    ,@Salutation VARCHAR(30)
    ,@BadgeStatus VARCHAR(10)
    ,@TerminalID VARCHAR(10) 
    ,@PortNumber VARCHAR(10) 
	,@ModifiedBy VARCHAR(20)
	
	-- OPTIONAL
    ,@FirstName nVARCHAR(100) = ''
    ,@LastName nVARCHAR(100) = ''
    ,@COP VARCHAR(30) = ''
    ,@TeamStatus VARCHAR(50) = ''
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN


/*
OBJECT:		dbo.usp_MyHLEventAPI_Upd_EventBadgePrinting

USE:		
			DECLARE @e int, @em varchar(4000)
			DECLARE @SubEvents udt_SubEvents

			INSERT INTO @SubEvents values (801,4631,1,'Main Event','',null,null,null,null,null,null,null,null,null),(801,4632,2,'Award 3 = $300','',null,null,null,null,null,null,null,null,null)
			
			EXEC usp_MyHLEventAPI_Upd_EventBadgePrinting
					@PK_ER = 824912
					,@EventID = 801
					,@SubEventTbl = @SubEvents
					,@Title = 'T'
					,@Salutation = 'S'
					,@BadgeStatus = 'Burned'
					,@TerminalID = '1'
					,@PortNumber = '1'
					,@ModifiedBy = 'OrlandoL'
					 
					 -- OPTIONAL
					,@FirstName = NULL
					,@LastName = NULL
					,@COP = NULL
					,@TeamStatus = NULL
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
			
DESCRIPTION: UPDATE Badge Printing and Badge SubEvents tables

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2013-01-15	OrlandoL	Initial
2	2019-08-14	NoeG		Refactor code (SRE)
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE()
		,@PK_DistributorID INT
		,@DistributorID VARCHAR(20)

SELECT @Error = 0, @ErrorMessage = '';

/**************************************************************************************
 Validate if exists the PK_ER on EventsRegistration table
****************************************************************************************/
SELECT @PK_DistributorID = PK_Distributor, @DistributorID = DistributorID FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_ER
IF @@ROWCOUNT = 0
BEGIN
	SET @Error = 87
	-- Update ErrorLosg
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END
	
/******************************************************************************
INSERT/UPDATE EventBadgePrinting and EventBadegeSubEvents tables
******************************************************************************/
BEGIN TRY
	
IF NOT EXISTS (SELECT 1 FROM dbo.EventBadgePrinting WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_ER)
	BEGIN
	
		/***********************************************
		  INSERT NEW RECORDS INTO EventBadgePrinting 
		***********************************************/
		INSERT 
			dbo.EventBadgePrinting
		(
			[PK_EventsRegistration]
           ,[PK_Event]
           ,[PK_Distributor]
           ,[DistributorID]
           ,[FirstName]
           ,[LastName]
           ,[COP]
           ,[TeamStatus]
           ,[Title]
           ,[Salutation]
           ,[BadgeStatus]
           ,[TerminalID]
           ,[PortNumber]
		)
		SELECT DISTINCT
			ER.PK_EventsRegistration,
			SEQ.PK_Event,
			SEQ.PK_Distributor,
			SEQ.DistributorID,
			CASE WHEN @FirstName IS NULL THEN D.sFirstName ELSE @FirstName END,
			CASE WHEN @LastName IS NULL THEN D.sLastName ELSE @LastName END,
			CASE WHEN @COP IS NULL THEN D.sDistributorCountryProcessingCode ELSE @COP END,	
			CASE WHEN @TeamStatus IS NULL THEN D.sTeam ELSE @TeamStatus END,
			@Title,
			@Salutation,
			@BadgeStatus,
			@TerminalID,
			@PortNumber				
		FROM
			dbo.EventsRegistration ER WITH (NOLOCK)
		INNER JOIN
			dbo.SubEventQualifier SEQ WITH (NOLOCK)
		ON
			SEQ.PK_Distributor = ER.PK_Distributor
			AND
			SEQ.PK_Event = ER.PK_Event
		INNER JOIN
			dbo.v_Distributor D
		ON
			SEQ.PK_Distributor = D.nDistributorID
		WHERE
			SEQ.PK_Event = @EventID
			AND
			SEQ.RemovedUTC = '2049-12-31'
			AND
			ER.Registered = 1
			AND
			ER.PK_EventsRegistration = @PK_ER
			
		
		/***********************************************
		  INSERT NEW RECORDS INTO EventBadgeSubEvents
		***********************************************/
		INSERT 
			dbo.EventBadgeSubEvents
		(
			[PK_EventBadgePrinting]
           ,[PK_Event]
           ,[PK_SubEvent]
           ,[PK_Distributor]
           ,[DistributorID]
           ,[SubEventDisplayName]
           ,[SequenceNo]
		)
		SELECT DISTINCT
			@@IDENTITY,
			@EventID,
			SE.PK_Subevent,
			@PK_DistributorID,
			@DistributorID,
			SE.SubeventName,
			SE.SubeventNumber
		FROM
			@SubEventTbl SE
		WHERE
			SE.PK_Subevent IS NOT NULL
	END
ELSE
	BEGIN
	
		/***********************************************
		  UPDATE Table EventBadgePrinting
		***********************************************/
		UPDATE
			dbo.EventBadgePrinting 
		SET
           [FirstName] = ISNULL(@FirstName,FirstName)
           ,[LastName] = ISNULL(@LastName,LastName)
           ,[COP] = ISNULL(@COP,COP)
           ,[TeamStatus] = ISNULL(@TeamStatus,TeamStatus)
           ,[Title] = ISNULL(@Title,Title)
           ,[Salutation] = ISNULL(@Salutation,Salutation)
           ,[BadgeStatus] = ISNULL(@BadgeStatus,BadgeStatus)
           ,[TerminalID] = ISNULL(@TerminalID,TerminalID)
           ,[PortNumber] = ISNULL(@PortNumber,PortNumber)
           ,[ModifiedBy] = @ModifiedBy
         WHERE
			PK_Event = @EventID
			AND
			PK_EventsRegistration = @PK_ER
		
		
		/***********************************************
		  UPDATE Table EventBadgeSubEvents
		***********************************************/
		DECLARE @PK_EventBadgePrinting INT
		
		SELECT @PK_EventBadgePrinting = PK_EventBadgePrinting FROM dbo.EventBadgePrinting WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_ER 
		
		UPDATE
			BSE 
		SET
           
			[SubEventDisplayName] = ISNULL(SE.SubeventName,SubEventDisplayName)
           ,[ModifiedBy] = ISNULL(@ModifiedBy,ModifiedBy)
        FROM
			dbo.EventBadgeSubEvents BSE
		INNER JOIN
			@SubEventTbl SE
		ON
			BSE.PK_SubEvent = SE.PK_Subevent
        WHERE
			BSE.PK_EventBadgePrinting = @PK_EventBadgePrinting
			AND
			BSE.PK_Event = @EventID
			
		/***********************************************************
		  If there is a new SubEvent INTERT INTO EventBadgeSubEvent
		************************************************************/
		
		;WITH SubEventsNotExists (SubEventID) AS 
			(
				 SELECT DISTINCT 
					PK_Subevent
				 FROM 
					@SubEventTbl
				 WHERE
					PK_Subevent IS NOT NULL
				 EXCEPT
				 SELECT DISTINCT 
					PK_SubEvent
				 FROM 
					dbo.EventBadgeSubEvents WITH (NOLOCK)	
				 WHERE
					PK_EventBadgePrinting = @PK_EventBadgePrinting
					AND
					PK_Event = @EventID
			 )
			INSERT 
					dbo.EventBadgeSubEvents
				(
					[PK_EventBadgePrinting]
				   ,[PK_Event]
				   ,[PK_SubEvent]
				   ,[PK_Distributor]
				   ,[DistributorID]
				   ,[SubEventDisplayName]
				   ,[SequenceNo]
				)
			SELECT DISTINCT
				@PK_EventBadgePrinting,
				@EventID,
				SE.PK_Subevent, 
				@PK_DistributorID, 
				@DistributorID, 
				SE.SubeventName,
				SE.SubeventNumber
			FROM
				SubEventsNotExists SNE WITH (NOLOCK)
			INNER JOIN
				@SubEventTbl SE
			ON
				SNE.SubEventID = SE.PK_Subevent

				
				
		/***********************************************************
		 Remove SubEvents in case the DS is not longer qualified
		************************************************************/
		;WITH SubEventsToDelete (SubEventID) AS 
		(
			 SELECT DISTINCT 
				PK_SubEvent
			 FROM 
				dbo.EventBadgeSubEvents WITH (NOLOCK)
			 WHERE
					PK_EventBadgePrinting = @PK_EventBadgePrinting
					AND
					PK_Event = @EventID
			 EXCEPT
			 SELECT DISTINCT 
				PK_Subevent
			 FROM 
				@SubEventTbl
			 WHERE
				PK_Subevent IS NOT NULL
		 )
		 
		DELETE BSE FROM 
			dbo.EventBadgeSubEvents BSE
		INNER JOIN
			SubEventsToDelete
		ON
			PK_SubEvent = SubEventID
		WHERE
			BSE.PK_EventBadgePrinting = @PK_EventBadgePrinting
			AND
			BSE.PK_Event = @EventID

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
END CATCH

/******************************************************************************
	END Procedure
******************************************************************************/
END
GO

