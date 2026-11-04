CREATE PROCEDURE [dbo].[usp_EventAPI_Del_Attendee]
-- REQUIRED
@PK_EventsRegistration int
	
-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT
	
-- QA/DEV
,@IsDevQA bit = 0 
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Del_Attendee

USE:			DECLARE @e int
                       ,@em varchar(200)
               EXEC usp_EventAPI_Del_Attendee @PK_EventsRegistration = 12623
                                                       ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                               ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						                               ,@IsDevQA = 0

					SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Add an Attendee to the EventRegistration, SubEventRegistration tables

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1		2009-02-06	Sandhya			Initial
1.1		2019-05-21	alejandramed	Homologating of standard error handling	
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';


/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @PK_Distributor int

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS (SELECT PK_EventsRegistration FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_EventsRegistration)
 BEGIN
	SET @Error = 87
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
 END

/******************************************************************************
be sure registrant has not attended any subevent already
******************************************************************************/
IF EXISTS (SELECT PK_SubEventAttendance FROM dbo.SubEventAttendance WITH (NOLOCK) WHERE PK_SubEventRegistration IN 
	(SELECT PK_SubEventRegistration FROM dbo.SubEventRegistration WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_EventsRegistration))
 BEGIN
	SET @Error = 250
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
 END
	

/******************************************************************************
update record
******************************************************************************/
BEGIN TRY

	DELETE SER
		FROM 
		dbo.SubEventRegistration SER
	WHERE 
		PK_EventsRegistration = @PK_EventsRegistration

	UPDATE T
	SET
		T.IsTicketUsed = 0
	FROM
		dbo.EventTickets T
	INNER JOIN
		dbo.EventsRegistration R (NOLOCK)
	ON
		T.PK_EventTicket = R.PK_EventTicket
	WHERE
		R.PK_EventsRegistration = @PK_EventsRegistration

	
	--Delete from EventBadgeSubEvents and EventBadgePrinting tables
	DELETE 
		BSE
	FROM
		dbo.EventBadgeSubEvents BSE
	INNER JOIN
		dbo.EventBadgePrinting EBP (NOLOCK)
	ON
		BSE.PK_EventBadgePrinting = EBP.PK_EventBadgePrinting 
	WHERE
		EBP.PK_EventsRegistration  = @PK_EventsRegistration
		
	DELETE 
		BP
	FROM
		dbo.EventBadgePrinting BP
	WHERE
		BP.PK_EventsRegistration = @PK_EventsRegistration
	
	-- Blacklist/Inactive any valid card
	DELETE ER
		FROM 
		dbo.EventsRegistration ER
	WHERE 
		PK_EventsRegistration = @PK_EventsRegistration

	UPDATE 
		ESB
	SET 
		ESB.PK_BadgeStatus = 3
		,ESB.IsActive = 0
		,ModifiedDateUTC = GETUTCDATE()
		,ModifiedBy = replace(suser_sname(),'HERBALIFECORP\','')
	FROM
		dbo.EventSecurityBadge ESB
	WHERE
		ESB.PK_EventsRegistration = @PK_EventsRegistration
		AND
		ESB.PK_BadgeStatus IN (1,2)
	
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

END
GO

