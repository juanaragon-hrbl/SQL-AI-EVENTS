
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_NoteTypes]
    -- OPTIONAL
   @NoteType int = NULL

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_NoteTypes

USE:	DECLARE @e int, @em varchar(4000)   

		EXEC [usp_EventAPI_Get_NoteTypes]
			@NoteType = 1
			,@Error = @e OUTPUT				-- @e must be defined in the local call   
			,@ErrorMessage = @em OUTPUT		-- @em must be defined in the local call   
			,@IsDevQA = 1  

		Print @em  
		
DESCRIPTION:	Retrieves record from dbo.SubEvent

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1	2009-01-21	Sandhya	Initial
2	2019-09-05	NoeG	SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
 
		/******************************************************************************
		select record
		******************************************************************************/


		BEGIN 

			SELECT  
			   PK_EventNoteType
			  ,Description
			FROM 
			   dbo.EventNoteTypes WITH (NOLOCK)
			WHERE
			   PK_EventNoteType = ISNULL(@NoteType, PK_EventNoteType)
  

		END

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
	end procedure
******************************************************************************/
END
GO

