
CREATE PROCEDURE [dbo].[usp_Update_PinReport] 
	@PK_Event INT = 678

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_Update_PinReport]
	
	USE:			
			DECLARE @e int, @em varchar(4000)
			
			EXEC [dbo].[usp_Update_PinReport]
				@PK_Event = 678
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0										Initial
	2.0.0		2019-09-30		NoeG			SRE template applied
	2.0.1		2019-10-30		NoeG			SRE Hardcode changed
	
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@ProcParam VARCHAR(100) = CONVERT(VARCHAR,@PK_Event)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'	

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE @PrevMonth DATETIME
		DECLARE @SilverPinSubEvent INT
		DECLARE @GoldPinSubEvent INT

		SET @PrevMonth = DATEADD(M,-1,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120)+'01',120))

		SELECT @SilverPinSubEvent = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 1
		SELECT @GoldPinSubEvent = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 2

		-- Insert New Qualifiers for Silver Pin
		INSERT INTO dbo.PinReport
		(
			PK_Distributor
			,DistributorID
			,Team
			,PinType
			,RoyaltyMonth
			,PK_Event
			,PK_SubEvent
		)
		SELECT
			SEQ.PK_Distributor
			,SEQ.DistributorID
			,DS.sTeam
			,'Silver'
			,@PrevMonth 
			,@PK_Event 
			,@SilverPinSubEvent 
		FROM
			dbo.SubEventQualifier SEQ WITH (NOLOCK)
		INNER JOIN
			dbo.v_Distributor DS WITH (NOLOCK)
		ON
			SEQ.PK_Distributor = DS.nDistributorID 
		LEFT JOIN
			dbo.PinReport PR WITH (NOLOCK)
		ON
			PR.PK_Distributor = DS.nDistributorID 
			AND
			PR.PinType = 'Silver'
		WHERE
			SEQ.PK_Event = @PK_Event 
			AND
			SEQ.PK_SubEvent = @SilverPinSubEvent 
			AND
			SEQ.RemovedUTC = @ValidDate
			AND
			PR.PK_Distributor IS NULL
	

		-- Insert New Qualifiers for Gold Pin
		INSERT INTO dbo.PinReport
		(
			PK_Distributor
			,DistributorID
			,Team
			,PinType
			,RoyaltyMonth
			,PK_Event
			,PK_SubEvent
		)
		SELECT
			SEQ.PK_Distributor
			,SEQ.DistributorID
			,DS.sTeam
			,'Gold'
			,@PrevMonth 
			,@PK_Event 
			,@GoldPinSubEvent 
		FROM
			dbo.SubEventQualifier SEQ WITH (NOLOCK)
		INNER JOIN
			dbo.v_Distributor DS WITH (NOLOCK)
		ON
			SEQ.PK_Distributor = DS.nDistributorID 
		LEFT JOIN
			dbo.PinReport PR WITH (NOLOCK)
		ON
			PR.PK_Distributor = DS.nDistributorID 
			AND
			PR.PinType = 'Gold'
		WHERE
			SEQ.PK_Event = @PK_Event 
			AND
			SEQ.PK_SubEvent = @GoldPinSubEvent 
			AND
			SEQ.RemovedUTC = @ValidDate
			AND
			PR.PK_Distributor IS NULL
	
		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StoredProcedureParameters = @ProcParam
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

