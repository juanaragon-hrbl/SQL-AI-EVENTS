
CREATE PROCEDURE [dbo].[usp_EventAPI_Del_SKUPurchased]
	-- REQUIRED
	@PK_SKUPurchased int

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Del_SKUPurchased

USE:			
				DECLARE @e int, @em varchar(4000)
			
				EXEC usp_EventAPI_Del_SKUPurchased
					@PK_SKUPurchased = 1
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Deletes record from dbo.SKUPurchased

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SKUPurchased

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	Aarti	Initial
2	2019-09-30	NoeG	SRE template applied

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

	/******************************************************************************
	be sure the value of FK exists in referenced table
	******************************************************************************/
	IF NOT EXISTS(SELECT PK_SKUPurchased FROM dbo.SKUPurchased WITH (NOLOCK) WHERE PK_SKUPurchased = @PK_SKUPurchased)
	BEGIN
		SET @Error = 157
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN
	END

	/******************************************************************************
	delete record
	******************************************************************************/
	BEGIN TRY

		DELETE FROM dbo.SKUPurchased WHERE PK_SKUPurchased = @PK_SKUPurchased

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

/******************************************************************************
	end procedure
******************************************************************************/
END
GO

