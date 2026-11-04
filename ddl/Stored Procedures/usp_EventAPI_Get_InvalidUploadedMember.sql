
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_InvalidUploadedMember]
		@PK_Event int

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventAPI_Get_InvalidUploadedMember]
	
	USE:			
			DECLARE @e int, @em varchar(4000)
			
			EXEC [usp_EventAPI_Get_InvalidUploadedMember]
				@PK_Event = 777795
				,@Error = @e
				,@ErrorMessage = @em
				,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2018-10-02		RogelioR		Initial
	1.0.1		2019-09-05		NoeG			SRE template applied
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT
				[DistributorID]
				,[PK_SubEvent]
			FROM [UploadedMemberDump] WITH (NOLOCK)
			WHERE [PK_Event] = @PK_Event;

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
END;
GO

