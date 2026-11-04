
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DistrubutorNotes]
	-- REQUIRED
	@DistributorID VARCHAR(10)
    -- OPTIONAL
	,@EventID INT = NULL
    ,@NoteType INT = NULL
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_DistrubutorNotes

USE:
				DECLARE @e int, @em varchar(4000)
                EXEC usp_EventAPI_Get_DistrubutorNotes 
                                @DistributorID = '14265010'
                                ,@NoteType = 3
                                ,@EventID = 8
					            ,@Error = @e OUTPUT  /* @e must be defined in the local call */
					            ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
								,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.EventDistrubutorNotes

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1	2009-01-21	Sandhya	  Initial
2   2019-09-05	NoeG	  SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
 Check if Distributor exist
******************************************************************************/


BEGIN TRY

	IF EXISTS  (SELECT nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
				UNION
				SELECT PK_Temp FROM dbo.TempDistributors  WITH(NOLOCK) WHERE DistributorID = @DistributorID)
   
	BEGIN


	/******************************************************************************
	select record
	******************************************************************************/

	BEGIN 

		SELECT
			 @DistributorID AS DistributorID
			,E.[PK_Event] 
			,S.[Notes]
			,S.[PK_EventNoteType]
			,S.[CreatedDateUTC]
			,S.[CreatedBy]
			,S.[ModifiedDateUTC]
			,S.[ModifiedBy]
		FROM 
			dbo.EventDistributorNotes S WITH(NOLOCK) 
		 INNER JOIN
			dbo.Event E WITH(NOLOCK)
			 ON 
			   S.PK_Event = E.PK_Event 
			INNER JOIN  
			(SELECT DISTINCT nDistributorID,sDistributorID FROM dbo.v_DistributorUnionTemp  WITH(NOLOCK)) D
			 ON 
			   S.PK_Distributor = D.nDistributorID
		 WHERE 
			   D.sDistributorID = @DistributorID
		   AND E.PK_Event = ISNULL(@EventID, E.PK_Event)
		   AND S.PK_EventNoteType = ISNULL(@NoteType, S.PK_EventNoteType)
		 ORDER BY 
			S.CreatedDateUTC DESC
        
	END

	END

	ELSE

	BEGIN
		SET @Error = 8
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN
	END

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime  

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
	end procedure
******************************************************************************/
END