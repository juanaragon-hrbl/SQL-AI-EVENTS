
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_GuestSpeakers]	
		-- Error Parameters
		@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_GuestSpeakers

USE:	        Declare @e int, @em varchar(4000)
                 EXEC usp_MyHLEventAPI_Get_GuestSpeakers
					  @Error = @e OUTPUT  /* @e must be defined in the local call */
					 ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

DESCRIPTION:	Get the Guest Speakers Names from GuestSpeakers Table

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.GuestSpeakers

VERSIONS
--------------------------------------------------------------------
1.0		2010-12-29				Sandhya				Intitial
2.0		2019-08-14				NoeG				Refactor code (SRE)
3.0		2019-10-17				alejandramed		SRE Compliance 

********************************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

BEGIN TRY

		SELECT
			PK_GuestSpeaker
		   ,SpeakerName
		FROM 
		   dbo.GuestSpeakers WITH (NOLOCK)

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
END

GO

