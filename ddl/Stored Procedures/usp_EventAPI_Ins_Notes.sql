CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_Notes]
    -- REQUIRED
	@EventID INT
	,@UploadNote [udt_UploadNoteList] READONLY
	,@FileName VARCHAR(100)
	,@UploadBy VARCHAR(100)
	,@PK_EventNoteType INT = 45
  
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0	

AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Ins_Notes

USE:		
				DECLARE @e int, @em varchar(4000)
			
				/* Declare a variable that references the type. */  
				DECLARE @Note AS [udt_UploadNoteList];  

				/* Add data to the table variable. */  
				INSERT INTO @Note (DistributorID, Note)  
					SELECT '1111111111', 'Test'
				
                EXEC usp_EventAPI_Ins_Notes 
					@EventID = 3735
					,@UploadNote = @Note
					,@FileName = 'FileName'
					,@UploadBy = 'NoeG'
					,@PK_EventNoteType = 46
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	This API will upload the notes to the Event ID passed in the parameters.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2009-01-22	OrlandoL	Initial
2	2019-09-05	NoeG		SRE template applied
3   2022-09-05	Jairli		Sync CEA Notes and Update processing Log was added
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
   VARIABLE DECLARATION
******************************************************************************/
DECLARE 
@Records INT,
@PK_NoteFiles INT

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/*********************************
		SELECT MB Information
		********************************/
		IF NOT EXISTS (SELECT [PK_Notefiles] FROM dbo.NoteFiles WITH (NOLOCK) WHERE [FileName] = @FileName AND EventID = @EventID)
		BEGIN
			INSERT INTO [dbo].[NoteFiles]
			([FileName]
			,[UploadDate]
			,[UploadBy]
			,[EventID])
			VALUES
				(@FileName
				,GETDATE()
				,@UploadBy
				,@EventID)

			SET @PK_NoteFiles = @@IDENTITY
		END
		ELSE
		BEGIN
			SET @ErrorMessage = 'File already exists'
			RETURN 
		END

		/********************************************************************/
		--DELETE FROM dbo.EventDistributorNotes 
		--WHERE PK_Event = @EventID AND PK_EventNoteType = @PK_EventNoteType

		INSERT INTO dbo.EventDistributorNotes
		(PK_Distributor, Notes, PK_Event, PK_EventNoteType, PK_NoteFiles)
		SELECT
			D.nDistributorID, DL.Note, @EventID, @PK_EventNoteType, @PK_NoteFiles
		FROM
			@UploadNote DL
		INNER JOIN
			v_Distributor D
		ON
			DL.DistributorID = D.sDistributorID

		SET @Records = @@ROWCOUNT

		/*******************************************************************/
		UPDATE 
			dbo.NoteFiles
		SET
			Records = @Records
		WHERE
			PK_NoteFiles = @PK_NoteFiles

	   /*********************************
		INSERT/UPDATE CEA Note
		********************************/	   
		EXEC [z_evp_cea_maintenance].[spcea_Event_Ins_MassiveNotes] @EventID, @PK_EventNoteType

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

/******************************************************************************
	END Procedure
******************************************************************************/
END