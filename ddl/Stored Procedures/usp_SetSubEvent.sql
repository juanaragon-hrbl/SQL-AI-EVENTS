CREATE PROCEDURE [dbo].[usp_SetSubEvent]
    @SubEvent_Items dbo.udt_Setup_SubEvent READONLY
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN  
/******************************************************************************
	OBJECT:			[dbo].[usp_SetSubEvent]
	
	USE:			
			
	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-05-02		alejandramed		Initial
	1.1.0		2019-08-14		NoeG				Refactor code (SRE)
	1.2.0		2019-10-04		puertac				Setup & Update values for IsBBBreakDownReqd
	1.3.0		2020-01-15		alejandramed		Including IsDiamondRptReqd
	
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
		dbo.SubEvent AS [target]
	USING @SubEvent_Items AS [source]  
	ON ([target].PK_Event = [source].PK_Event AND [target].SubEventNumber = [source].SubEventNumber)
	WHEN MATCHED THEN     
		UPDATE SET 
			[target].CreatedDateUTC = [source].CreatedDateUTC,
			[target].CreatedBy = [source].CreatedBy,
			[target].ModifiedDateUTC = [source].ModifiedDateUTC,
			[target].ModifiedBy = [source].ModifiedBy,
			[target].PK_Event = [source].PK_Event,
			[target].SubEventNumber = [source].SubEventNumber,
			[target].PK_SubEventType = [source].PK_SubEventType,
			[target].MaxCapacity = [source].MaxCapacity,
			[target].ExpectedCapacity = [source].ExpectedCapacity,
			[target].SubEventName = [source].SubEventName,
			[target].KeepDNR = [source].KeepDNR,
			[target].KeepDELETED = [source].KeepDELETED,
			[target].[Location] = [source].[Location],
			[target].IsMainEventQual = [source].IsMainEventQual,
			[target].IsTrackingVisible = [source].IsTrackingVisible,
			[target].IncludeInBizworkReport = [source].IncludeInBizworkReport,
			[target].IsBBBreakDownReqd = [source].IsBBBreakDownReqd,
			[target].IsDiamondRptReqd = [source].IsDiamondRptReqd,
			[target].[PK_SubEventGroup] = [source].[PK_SubEventGroup]			
	WHEN NOT MATCHED THEN
		INSERT (CreatedDateUTC,CreatedBy,ModifiedDateUTC,ModifiedBy,PK_Event,SubEventNumber,
		PK_SubEventType,MaxCapacity,ExpectedCapacity,SubEventName,KeepDNR,KeepDELETED,[Location],
		IsMainEventQual,IsTrackingVisible,IncludeInBizworkReport,IsBBBreakDownReqd,IsDiamondRptReqd,[PK_SubEventGroup]) 
		VALUES ([source].CreatedDateUTC,[source].CreatedBy,[source].ModifiedDateUTC,[source].ModifiedBy,[source].PK_Event,[source].SubEventNumber
				,[source].PK_SubEventType,[source].MaxCapacity,[source].ExpectedCapacity,[source].SubEventName,[source].KeepDNR,[source].KeepDELETED
				,[source].[Location],[source].IsMainEventQual,[source].IsTrackingVisible,[source].IncludeInBizworkReport,[source].IsBBBreakDownReqd
				,[source].IsDiamondRptReqd,[source].[PK_SubEventGroup])
		;

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
END;