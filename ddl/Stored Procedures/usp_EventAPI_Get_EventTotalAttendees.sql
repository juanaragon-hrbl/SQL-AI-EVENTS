
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventTotalAttendees]
    -- REQUIRED
    @PK_Event int     
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
--
AS
BEGIN

/******************************************************************************
OBJECT:                 dbo.usp_EventAPI_Get_EventTotalAttendees

USE:    
			DECLARE @e int, @em varchar(4000)
			EXEC usp_EventAPI_Get_EventTotalAttendees
                            @PK_Event = 22
                            ,@Error = @e OUTPUT  /* @e must be defined in the local call */
                            ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:      Retrieves record from dbo.EventRegistration

NOTES:                  

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.EventsRegistration

VERSIONS
--------------------------------------------------------------------
1   2009-05-22	SandhyaP	Initial
2	2019-09-05	NoeG		SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
      variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event)
BEGIN
      SET @Error = 169
      -- Update ErrorLog
      EXEC dbo.usp_Utility_UpdateErrorLog 
            @ProcedureName = @StoredProcedure 
            ,@ErrorNumber = @Error
            ,@ErrorMessage = @ErrorMessage OUTPUT
      RETURN 
END



/******************************************************************************
select record
******************************************************************************/
BEGIN TRY

      SELECT
        COUNT(DISTINCT PK_Distributor) As RegisteredDS
       ,COUNT(DISTINCT PK_EventsRegistration) As TotalAttendees
      FROM 
            dbo.EventsRegistration WITH(NOLOCK)
      WHERE 
            PK_Event = @PK_Event
            AND
            HasCheckedIn = 1

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
	END PROCEDURE
******************************************************************************/
END;