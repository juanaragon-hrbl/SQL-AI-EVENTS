CREATE PROCEDURE [dbo].[usp_SetEventSKU]

	@EventSKU_Items dbo.udt_Setup_EventSKU READONLY
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
	OBJECT:			[dbo].[usp_SetEventSKU]
	
	USE:			

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-04-30		alejandramed		Initial
	1.1.0		2019-08-14		NoeG				Refactor code (SRE)
	
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	MERGE  
		dbo.EventSKU AS [target]
	USING @EventSKU_Items AS [source]  
	ON ([target].PK_Event = [source].PK_Event AND [target].SKUCode = [source].SKUCode)
	WHEN MATCHED THEN     
		UPDATE SET 
			[target].CreatedDateUTC = [source].CreatedDateUTC,
			[target].CreatedBy = [source].CreatedBy,
			[target].ModifiedDateUTC = [source].ModifiedDateUTC,
			[target].ModifiedBy = [source].ModifiedBy,
			[target].PK_Event = [source].PK_Event,
			[target].PK_Country = [source].PK_Country,
			[target].SKUCode = [source].SKUCode,
			[target].SKUDesc = [source].SKUDesc,
			[target].SKUValidBeginUTC = [source].SKUValidBeginUTC,
			[target].SKUValidEndUTC = [source].SKUValidEndUTC,
			[target].NumberOfTicketsPerSKU = [source].NumberOfTicketsPerSKU,
			[target].PK_EventSKUType = [source].PK_EventSKUType,
			[target].IsEventTicketSKU = [source].IsEventTicketSKU,
			[target].IsGenerateNote = [source].IsGenerateNote,
			[target].IsTrackingVisible = [source].IsTrackingVisible,
			[target].IsSKUUsedInPreOrder = [source].IsSKUUsedInPreOrder
	WHEN NOT MATCHED THEN
		INSERT (CreatedDateUTC,CreatedBy,ModifiedDateUTC,ModifiedBy,PK_Event,PK_Country
				,SKUCode,SKUDesc,SKUValidBeginUTC,SKUValidEndUTC,NumberOfTicketsPerSKU,PK_EventSKUType
				,IsEventTicketSKU,IsGenerateNote,IsTrackingVisible,IsSKUUsedInPreOrder) 
		VALUES ([source].CreatedDateUTC,[source].CreatedBy,[source].ModifiedDateUTC,[source].ModifiedBy,[source].PK_Event,[source].PK_Country
				,[source].SKUCode,[source].SKUDesc,[source].SKUValidBeginUTC,[source].SKUValidEndUTC,[source].NumberOfTicketsPerSKU,[source].PK_EventSKUType
				,[source].IsEventTicketSKU,[source].IsGenerateNote,[source].IsTrackingVisible,[source].IsSKUUsedInPreOrder);

	--IsEventTicketSKU always 1 for DMMY 
	UPDATE E
	SET IsEventTicketSKU = 1
	FROM
		dbo.EventSKU E
		INNER JOIN @EventSKU_Items temp	
			ON E.PK_Event = temp.PK_Event
		WHERE E.SKUCode = 'DMMY'

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
	END CATCH;
END
