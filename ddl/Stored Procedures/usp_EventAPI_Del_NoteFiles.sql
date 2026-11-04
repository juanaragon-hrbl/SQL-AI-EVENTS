CREATE PROCEDURE [dbo].[usp_EventAPI_Del_NoteFiles]  
	 @EventID INT
	,@PK_Notefiles INT
	-- OPTIONAL
  ,@Error INT OUTPUT
  ,@ErrorMessage VARCHAR(200) OUTPUT	
  
	-- QA/DEV
  ,@IsDevQA BIT = 0   
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Del_NoteFiles

USE:			DECLARE @e int, @em varchar(200)

                EXEC usp_EventAPI_Del_NoteFiles 
                    @Error = @e OUTPUT  /* @e must be defined in the local call */
                   ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
                   ,@IsDevQA = 0


DESCRIPTION:	Get Note types

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2009-01-22	OrlandoL	Initial
2   2022-09-05	Jairli		Sync CEA Notes and Update processing Log was added
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
   VARIABLE DECLARATION
******************************************************************************/
DECLARE 
@StoredProcedure VARCHAR(100),
@StartTime DATETIME,
@PK_Distributor INT,
@IsPartner BIT = 0

SET @StoredProcedure = 'usp_EventAPI_Del_NoteFiles'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'


/*********************************
SELECT MB Information
********************************/
DELETE FROM dbo.EventDistributorNotes 
WHERE PK_Event = @EventID AND PK_Notefiles = @PK_Notefiles

DELETE FROM dbo.NoteFiles 
WHERE [EventID] = @EventID AND PK_Notefiles = @PK_Notefiles


/*********************************
 DELETEE CEA Notes
********************************/	   
EXEC [z_evp_cea_maintenance].[spcea_Event_Del_MassiveNotes] @EventID    

-- Update processing Log
EXEC [dbo].[usp_Utility_UpdateProcessingLog]
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime;
	

/******************************************************************************
	END Procedure
******************************************************************************/
END
