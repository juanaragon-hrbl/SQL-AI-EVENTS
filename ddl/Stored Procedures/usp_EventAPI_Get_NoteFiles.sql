
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_NoteFiles]  
	@EventID INT = NULL
   ,@PK_NoteFiles INT = NULL

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_NoteFiles

USE:			DECLARE @e int, @em varchar(4000)

                EXEC usp_EventAPI_Get_NoteFiles 
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
2	2019-09-05	NoeG		SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
   VARIABLE DECLARATION
******************************************************************************/
DECLARE 
@PK_Distributor INT,
@IsPartner BIT = 0

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/*********************************
		SELECT MB Information
		********************************/

		IF @PK_NoteFiles IS NULL 
		SELECT
			[PK_Notefiles],
			[FileName],
			[UploadDate],
			[UploadBy],
			[Records],
			[EventID]
		FROM
			dbo.NoteFiles WITH (NOLOCK)
		ELSE
			SELECT D.sDistributorID AS DistributorID,Notes		 
			FROM dbo.EventDistributorNotes EN WITH (NOLOCK)
			INNER JOIN dbo.v_Distributor D WITH (NOLOCK) ON EN.PK_Distributor = D.nDistributorID
			WHERE PK_NoteFiles = @PK_NoteFiles AND PK_Event = @EventID

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

