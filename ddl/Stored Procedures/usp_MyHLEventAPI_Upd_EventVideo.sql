CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_EventVideo]
        --Mandatory Parameters
		 @PK_Event INT
		,@EventVideo udt_EventVideo READONLY
		,@ModifiedBy VARCHAR(10)
		-- Error Parameters
		 ,@Error	INT = 0 OUTPUT
		,@ErrorMessage VARCHAR(4000) = '' OUTPUT
		-- QA/DEV
		,@IsDevQA BIT = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Upd_EventVideo
USE:
			declare @e int
			declare @em varchar(200)
			declare @IsDevQA int
			declare @EventVideo udt_EventVideo
			INSERT INTO @EventVideo VALUES(NULL, 'EventVideo', 'http:\\hyperlink', NULL)
			--, (NULL, 'EventVideo', 'http:\\hyperlink', NULL)
			
			EXEC usp_MyHLEventAPI_Upd_EventVideo
					 @PK_Event = 9574
					,@EventVideo = @EventVideo
					,@ModifiedBy = 'sushmaa'
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
			print @e
			PRINT @em

DESCRIPTION:	Inserts/updates a record in dbo.EventVideo

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventVideo

VERSIONS
--------------------------------------------------------------------
	1.0.0	2016-01-26		Sandhya			Initial
	1.1.0	2019-10-17      puertac			SRE Implementation 

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON	

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure VARCHAR(100)
DECLARE @StartTime DATETIME

SET @Error = 0
SET @ErrorMessage = 'No Error.'
SET @StoredProcedure = 'usp_MyHLEventAPI_Upd_EventVideo'

/* Insert/Update the record into EventVideo table */
BEGIN TRY

	MERGE dbo.[EventVideo] EA
	USING
	(
		SELECT @PK_Event AS [PK_Event], EA.PK_EventVideo,  EA.VideoName, EA.VideoHTML
		FROM @EventVideo EA
	) AS M
	ON EA.[PK_Event] = M.[PK_Event]
	AND EA.PK_EventVideo = M.PK_EventVideo
	WHEN NOT MATCHED THEN INSERT (PK_Event, VideoName, VideoDesc, VideoHTML)
	VALUES(M.PK_Event, M.VideoName, M.VideoName, M.VideoHTML)
	WHEN MATCHED THEN UPDATE SET
	 [VideoName]= M.[VideoName]
	,[VideoHTML] = M.[VideoHTML]
	,ModifiedBy = @ModifiedBy
	;
	
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
	END PROCEDURE
******************************************************************************/
END