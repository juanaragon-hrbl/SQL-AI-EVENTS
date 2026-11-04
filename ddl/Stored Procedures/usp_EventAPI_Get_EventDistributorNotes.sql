CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventDistributorNotes]
	@PK_EventDistributorNote INT 

	-- Error Parameters
	,@Error	INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA BIT = 0

AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_EventDistributorNotes
USE:		
			DECLARE @e int, @em varchar(4000)

			EXEC usp_EventAPI_Get_EventDistributorNotes
					@PK_EventDistributorNote = 1
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.EventDistributorNotes

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.EventDistributorNotes

VERSIONS
--------------------------------------------------------------------
1	2008-10-14	Aarti			Initial
2	2019-09-05	NoeG			SRE template applied
3	2019-10-08	alejandramed	SRE Compliance 
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


BEGIN TRY

	/******************************************************************************
	be sure the value of FK exists in referenced table
	******************************************************************************/
	IF NOT EXISTS(SELECT PK_EventDistributorNote FROM dbo.EventDistributorNotes(NOLOCK) WHERE PK_EventDistributorNote = @PK_EventDistributorNote)
	BEGIN
		SET @Error = 172

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

		SELECT
			[PK_EventDistributorNote]
			,[PK_Distributor] 
			,[Notes] 
			,[CreatedDateUTC]
			,[CreatedBy]
			,[ModifiedDateUTC]
			,[ModifiedBy]
			,[PK_Event] 
			,[PK_EventNoteType]
		FROM	
			dbo.EventDistributorNotes WITH (NOLOCK)
		WHERE	
			PK_EventDistributorNote = @PK_EventDistributorNote
		ORDER BY 
			CreatedDateUTC DESC

	/******************************************************************************
		end procedure
	******************************************************************************/

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
	END CATCH




END
