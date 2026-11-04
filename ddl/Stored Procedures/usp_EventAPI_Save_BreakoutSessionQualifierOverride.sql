
CREATE PROCEDURE [dbo].[usp_EventAPI_Save_BreakoutSessionQualifierOverride]
		@EventID INT				
		,@SessionID INT
		,@DistributorID VARCHAR(30)
		,@IsQualified BIT
		,@Note VARCHAR(MAX)
		,@UserID VARCHAR(50)

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventAPI_Save_BreakoutSessionQualifierOverride]
	
	USE:			
			DECLARE @e int, @em varchar(4000), @ap int = 0

			EXEC [dbo].[usp_EventAPI_Save_BreakoutSessionQualifierOverride]
				@EventID = 63002
				,@SessionID = 24828--24810
				,@DistributorID = '010029194'--'01002480'--'38854317'
				,@IsQualified = 1
				,@Note = 'Reason for Override Qualification'
				,@UserID = 'OtherUserWhoModifies'
				,@Error = @e output
				,@ErrorMessage = @em output
				,@IsDevQA = 1

			Select	PK_BreakoutSessionQualifierOverride, PK_Event, PK_SubEvent, DistributorID
					, IsQualified, Note, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy 
			from	BreakoutSessionQualifierOverride


	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-01-29		NoeG			Initial
	1.0.1		2019-01-30		NoeG			UserID parameter added to manage the CreatedBy and ModifiedBy with custom UserID
	1.0.2		2019-09-05		NoeG			SRE template applied
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE @BreakoutSessionQualifierOverride table (
			[action] varchar(15)
			,[PK_BreakoutSessionQualifierOverride]	[bigint]
			,[PK_Event]								[int]
			,[PK_SubEvent]							[int]
			,[DistributorID]						[varchar](30)
			,[IsQualified]							[bit]
			,[Note]									[varchar](max)
			,[CreatedDateUTC]						[datetime]
			,[CreatedBy]							[varchar](50)
			,[ModifiedDateUTC]						[datetime]
			,[ModifiedBy]							[varchar](50)
		);
	
		MERGE [dbo].[BreakoutSessionQualifierOverride] AS t
			USING(
				SELECT
						(SELECT [PK_BreakoutSessionQualifierOverride]
							FROM [dbo].[BreakoutSessionQualifierOverride] AS t WITH (NOLOCK)
							WHERE t.[PK_Event] = @EventID
									AND t.[PK_SubEvent] = @SessionID
									AND t.[DistributorID] = @DistributorID
						) AS [PK_BreakoutSessionQualifierOverride]
						,@EventID as [PK_Event]			
						,@SessionID as [PK_SubEvent]		
						,@DistributorID as [DistributorID]	
						,@IsQualified as [IsQualified]		
						,@Note as [Note]				
						,GETUTCDATE() as [CreatedDateUTC]	
						,@UserID as [CreatedBy]		
						,GETUTCDATE() as [ModifiedDateUTC]	
						,@UserID as [ModifiedBy]		
				) AS s 
					ON	s.[PK_Event] = t.[PK_Event]
						AND s.[PK_SubEvent] = t.[PK_SubEvent]
						AND s.[DistributorID] = t.[DistributorID]
			WHEN MATCHED THEN
				UPDATE SET
					[IsQualified] = s.[IsQualified]		
					,[Note] = s.[Note]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]	
					,[ModifiedBy] = s.[ModifiedBy]		
			WHEN NOT MATCHED THEN
				INSERT(
					 [PK_Event]			
					,[PK_SubEvent]		
					,[DistributorID]	
					,[IsQualified]		
					,[Note]				
					,[CreatedDateUTC]	
					,[CreatedBy]		
					,[ModifiedDateUTC]	
					,[ModifiedBy]		
				)
				VALUES(
					s.[PK_Event]			
					,s.[PK_SubEvent]		
					,s.[DistributorID]	
					,s.[IsQualified]		
					,s.[Note]				
					,s.[CreatedDateUTC]	
					,s.[CreatedBy]		
					,s.[ModifiedDateUTC]	
					,s.[ModifiedBy]		
				)

			OUTPUT
					$action
					,inserted.[PK_BreakoutSessionQualifierOverride]
					,inserted.[PK_Event]
					,inserted.[PK_SubEvent]

					,inserted.[DistributorID]	
					,inserted.[IsQualified]	
					,inserted.[Note]			
					,inserted.[CreatedDateUTC]	
					,inserted.[CreatedBy]		
					,inserted.[ModifiedDateUTC]	
					,inserted.[ModifiedBy]		

				INTO @BreakoutSessionQualifierOverride
		;	-- MERGE [BreakoutSessionQualifierOverride]

		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1 
			BEGIN
				SELECT 'MERGE', action
							   ,PK_BreakoutSessionQualifierOverride
							   ,PK_Event
							   ,PK_SubEvent
							   ,DistributorID
							   ,IsQualified
							   ,Note
							   ,CreatedDateUTC
							   ,CreatedBy
							   ,ModifiedDateUTC
							   ,ModifiedBy FROM @BreakoutSessionQualifierOverride
				
				SELECT @Error AS [Error], @ErrorMessage AS [Error Message]
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
	END CATCH;
END;
GO

