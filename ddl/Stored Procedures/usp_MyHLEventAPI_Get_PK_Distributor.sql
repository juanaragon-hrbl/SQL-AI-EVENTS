CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_PK_Distributor]
	-- Required
	@DistributorID		VARCHAR(50)
	,@PK_Distributor	INT OUTPUT
	
	-- Error Parameters
	,@Error	INT OUTPUT
	,@ErrorMessage VARCHAR(4000) OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS

BEGIN
/******************************************************************************

	OBJECT:			[dbo].[usp_MyHLEventAPI_Get_PK_Distributor]
	
	USE:			
					
	DESCRIPTION:	Gets past events with pagination

	NOTES:
			@Start -> Sets the starting point of the result set
			@Rows -> Number of rows that will be returned
	
	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventLocaleDesc, dbo.EventDSTeamType, dbo.EventImage, dbo.EventImageLocaleDesc, dbo.EventImageType, dbo.Locales

	VERSIONS (U)
	--------------------------------------------------------------------
	1.0.0		2019-08-14		NoeG			Refactor code (SRE)
	
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
		
	BEGIN TRY
		
		SELECT @PK_Distributor = nDistributorID 
			FROM v_Distributor (NOLOCK)
			WHERE sDistributorID = @DistributorID

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