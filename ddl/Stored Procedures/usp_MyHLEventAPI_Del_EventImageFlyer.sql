
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Del_EventImageFlyer]
        --Mandatory Parameters
		 @PK_EventImage INT
		,@PK_EventURL INT
		,@PK_Event INT
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
	
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Del_EventImageFlyer
USE:
			DECLARE @e int, @em varchar(4000)

			EXEC usp_MyHLEventAPI_Del_EventImageFlyer
					@PK_EventImage = 7
					,@PK_EventURL = 45
					,@PK_Event = 646
					,@Error = @e OUTPUT  -- @e must be defined in the local call   
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	DELETES RECORD(s) FROM EventImage and/or EventURL (FLYER)

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventImage
dbo.EventURL

VERSIONS
--------------------------------------------------------------------
1	2011-12-07	PrabhuS	Initial
2	2019-08-14	NoeG	Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON	

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		IF @PK_EventImage  IS NOT NULL
		BEGIN
		/* IF A PARAMETER FOR PK_EVENTIMAGE IS PASSED THEN WE DELETE THE CORRESPOING RECORD FROM THE EVENT IMAGE TABLE */
		UPDATE
			EI
		SET
			 EI.EventImageLocation = NULL
			,EI.ModifiedDateUTC = GETUTCDATE()
		FROM
			dbo.EventImage EI
		WHERE
			PK_Event = @PK_Event
		AND
			PK_EventImage = @PK_EventImage 

		END

		IF @PK_EventURL  IS NOT NULL
		/* IF A PARAMETER FOR PK_EVENTURL IS PASSED THEN WE DELETE THE CORRESPOING RECORD FROM THE EVENT URL TABLE */
		BEGIN
		UPDATE
			EU
		SET
			EU.Flyer = NULL
		FROM
			dbo.EventURL EU
		WHERE
			PK_Event = @PK_Event
		AND
			PK_EventURL = @PK_EventURL
		END
	
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
		RETURN 
	END CATCH

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

