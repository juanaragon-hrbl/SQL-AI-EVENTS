CREATE PROCEDURE [dbo].[usp_Del_EventActivity]
        -- Mandatory Parameters
		@PK_Event					INT
		,@PK_EventActivity			nVARCHAR(200)
		,@Delete					BIT 
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_Del_EventActivity

USE:	        Declare @e int, @em varchar(200)
                EXEC dbo.usp_Del_EventActivity
					 	 @PK_Event = 1
                        ,@PK_EventActivity = 0
						,@Delete = 1
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
				Print @em

DESCRIPTION:	Delete Activity for an Event
TABLES:			dbo.Event, dbo.EventActivity
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2015-06-19			SandhyaP				Intitial
******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @StoredProcedure VARCHAR(100) = 'usp_Manage_EventActivityList'
DECLARE @CurrentUTC DATETIME = GETUTCDATE()
DECLARE @ModifiedBy	nVARCHAR(50)

SET @ModifiedBy = Replace(suser_sname(),'HERBALIFECORP\','')

/* DELETE SPECIFIC EVENT ACTIVITY */

IF EXISTS (SELECT 1 FROM dbo.EventActivity (NOLOCK) WHERE PK_EventActivity = @PK_EventActivity AND DeletedUTC IS NULL)
BEGIN

	UPDATE 
		dbo.EventActivity
	SET 
		DeletedUTC = CASE WHEN @Delete = 1 THEN @CurrentUTC ELSE NULL END
		,ModifiedUTC = @CurrentUTC
		,ModifiedBy = @ModifiedBy
	WHERE
		PK_Event = @PK_Event
		AND
		PK_EventActivity = @PK_EventActivity

END

END