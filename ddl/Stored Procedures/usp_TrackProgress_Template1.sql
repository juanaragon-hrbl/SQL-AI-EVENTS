
CREATE PROCEDURE [dbo].[usp_TrackProgress_Template1]
		@PK_Event int
		,@LocaleCode char(5)

		-- Optional Parameters
		,@DistributorID varchar(20)
		
		-- Error Parameters
		,@Error	int OUTPUT
		,@ErrorMessage varchar(MAX) OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_TrackProgress_Template1]
	
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC [dbo].[usp_TrackProgress_Template1]
				@PK_Event = 14089
				,@LocaleCode = 'en-US'
				,@DistributorID = N'2222222222'
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2018-09-27		RogelioR		Initial
	
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255);

	BEGIN TRY
		
		EXEC dbo.usp_TrackProgress_NAMMAP2018
					 	 @DistributorID = @DistributorID
					 	,@PK_Event = @PK_Event
						,@LocaleCode = @LocaleCode;

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