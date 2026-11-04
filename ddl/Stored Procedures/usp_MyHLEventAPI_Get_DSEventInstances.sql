
CREATE PROC [dbo].[usp_MyHLEventAPI_Get_DSEventInstances]
		 @UserID varchar(30)
		,@PK_Event INT
		,@LocaleCode CHAR(5)
		,@DistributorID VARCHAR(10)
		-- Error Parameters
		,@Error INT OUTPUT
		,@ErrorMessage VARCHAR(200) OUTPUT
		,@IsDevQA BIT = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_DSEventInstances

USE:	        Declare @e int, @em varchar(200)
                 EXEC dbo.usp_MyHLEventAPI_Get_DSEventInstances
						@UserID = 'SandhyaP'
					 	,@PK_Event = 10269
						,@LocaleCode = 'en-US'
						,@DistributorID = '1111111111'
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
Print @em

DESCRIPTION:	Retrieves all the records for associated DS Event instances based on the PK_Event passed

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.EventInstances

VERSIONS
----------------------------------------------------------------------------------
1	2014-06-05	Sushma	Intitial

******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @PK_EventType INT
DECLARE @StoredProcedure VARCHAR(100)
DECLARE @StartTime DATETIME
DECLARE @HasAccess INT

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SET @Error = 0
SET @ErrorMessage = 'No Error.'
SET @StoredProcedure = 'usp_MyHLEventAPI_Get_DSEventInstances'
SET @StartTime = GETUTCDATE()

--Retrieve all the instances of the main event with the status

SELECT
	 @PK_Event [PK_MainIntance]
	,EI.PK_Event [PK_EventInstance]
	,CASE WHEN (EI.IsActive = 0 OR EI.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR EI.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
		  ELSE EI.EventApprovalStatus END
	 [EventStatus]
	,EI.dStartUTC [EventStartDate]
	,EI.dEndUTC [EventEndDate]	
	,EI.EventName
FROM	
	dbo.Event(NOLOCK) EI
WHERE
	EI.PK_OldEventApp = @PK_Event

END
