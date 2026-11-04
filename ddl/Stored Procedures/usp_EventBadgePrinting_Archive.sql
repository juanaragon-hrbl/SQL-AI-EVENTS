CREATE PROCEDURE [dbo].[usp_EventBadgePrinting_Archive]
	-- QA/DEV
	 @IsDevQA smallint = 0
	--Optional
	,@DisplayResult bit  = 0
	-- Error Parameters
	,@Error	int  OUTPUT
	,@ErrorMessage varchar(4000) OUTPUT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventBadgePrinting_Archive

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC	[dbo].[usp_EventBadgePrinting_Archive] 
					@IsDevQA = 0,
					@DisplayResult = 1,
					@Error = @Error OUTPUT, 
					@ErrorMessage = @ErrorMessage OUTPUT
					
			SELECT	@Error as N'@Error',
					@ErrorMessage as N'@ErrorMessage'

			GO

			* @IsDevQA = 0 - PROD
			* @IsDevQA = 2 - Forcing to fail for UT
			* @IsDevQA = 4 - Forcing to fail after insert/archive
			* @IsDevQA = 5 - Forcing to fail before to commit tran

	DESCRIPTION: This stored procedure archives EventBadgePrinting table. 
					
				This archiving process will run daily.
				This process will archive a limit of record by day using batches.

	NOTES:			

	SELECT COUNT(1) FROM [dbo].[EventBadgePrinting] WITH(NOLOCK)
	SELECT COUNT(1) FROM [dbo].[EventBadgePrinting_Archive] WITH(NOLOCK)

	DEPENDENCIES:
	usp_Utility_UpdateErrorLog
	usp_Utility_UpdateProcessingLog
	
	[Shared].[ArchivingSettings]
	[Shared].[ArchivingResults]

	WORK TABLES (WRK):
	
	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2022-07-06		alejandramed		Initial 
	1.0.1	2022-10-06		alejandramed		Creating archive results even if the execution failed
	***********************************************************************************************************************************/

	DECLARE @StoredProcedure varchar(255) = 'usp_EventBadgePrinting_Archive'
			,@StoredProcedureParameters varchar(100) = 'Complete'
			,@StartTime datetime2 = GETUTCDATE();
			
	SELECT @Error = 0, @ErrorMessage = '';
	
	SET XACT_ABORT ON;
	SET NOCOUNT ON;

BEGIN TRY
	
	-- EventBadgePrinting 
	-------------------------------------------------------------------------------------------------------------------
	
		--------------------------------------------------------------------------------------------------------------------
		-- 1) Variable declaration  
		--------------------------------------------------------------------------------------------------------------------

		DECLARE @EndTime				DATETIME,
				@InitSeconds			INT,
				@h						INT, 
				@m						INT, 
				@s						INT,
				@RunTime				VARCHAR(10),
				@DaysToKeepData			INT,
				@Limit					INT,
				@BatchSize				INT,
				@LogResult				BIT,
				@Min					BIGINT, 
				@Max					BIGINT, 
				@TotalRows				BIGINT, 
				@TotalRowsToArchive		BIGINT,
				@ArchiveDate			DATETIME, 
				@PKFrom					BIGINT, 
				@PKTo					BIGINT,
				@Inserted				BIGINT,
				@Deleted				BIGINT,
				@AccInserted			BIGINT = 0,
				@AccDeleted				BIGINT = 0,
				@refConflicts			BIGINT,
				@TranStatus				VARCHAR(250),
				@TableName				VARCHAR(250) = 'EventBadgePrinting',
				@KeepChanges			BIT, 
				@Batch					INT, 
				@BatchCount				INT 

		DROP TABLE IF EXISTS #Results CREATE TABLE #Results( ID INT IDENTITY(1,1), Batch VARCHAR(25),TotalRowsByBatch BIGINT ,FromPK BIGINT,ToPK BIGINT, INSERTED BIGINT, DELETED BIGINT, ARCHIVED BIGINT)
		
		--------------------------------------------------------------------------------------------------------------------
		-- 2) Getting settings value   
		--------------------------------------------------------------------------------------------------------------------

		IF NOT EXISTS (SELECT 1 FROM [Shared].[ArchivingSettings] WITH (NOLOCK) WHERE TableName = LTRIM(RTRIM(@TableName)))
		BEGIN
			PRINT 'Settings missing for ' + LTRIM(RTRIM(@TableName)) +' Archiving process';
			RETURN;
		END

		SELECT 
			@DaysToKeepData = [DaysToKeepData],
			@Limit = [LimitPerExecution],
			@BatchSize = [BatchSize],
			@LogResult = [LogResult],
			@KeepChanges = ISNULL([KeepChanges],1)
		FROM [Shared].[ArchivingSettings] WITH (NOLOCK) 
		WHERE TableName = LTRIM(RTRIM(@TableName))

		SET @ArchiveDate = DATEADD(DD,- @DaysToKeepData,(DATEADD(DD, DATEDIFF(DD, 0, GETDATE()), 0)))
		SET @TranStatus = 'Processing'

BEGIN TRAN

		IF (@IsDevQA = 2)
		BEGIN
			;THROW 60001, N'Forcing to fail for UT', 1
		END
		
		PRINT '------------------Start: '+ @TableName +' ------------------'

		--------------------------------------------------------------------------------------------------------------------
		-- 4) Getting archiving values   
		--------------------------------------------------------------------------------------------------------------------

		PRINT CONVERT(VARCHAR, @ArchiveDate, 23) + ' [ArchiveDate]'			
		PRINT CAST(@BatchSize AS VARCHAR(25)) + ' [BatchSize]' 
		PRINT CAST(@Limit AS VARCHAR(25)) + ' [Limit]' 
		
		--Total rows
		SELECT @TotalRows = COUNT(1) FROM dbo.EventBadgePrinting WITH (NOLOCK)
		WHERE CreatedDateUTC < @ArchiveDate 
		
		PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [TotalRows]'

		--Total rows to archieve according to the limit
		DROP TABLE IF EXISTS #RecordsToArchieve
				
		SELECT TOP (@Limit) PK_EventBadgePrinting AS [PK]
		INTO #RecordsToArchieve
		FROM dbo.EventBadgePrinting WITH (NOLOCK)
		WHERE CreatedDateUTC < @ArchiveDate 	
		ORDER BY PK_EventBadgePrinting ASC

		CREATE INDEX IX_#RecordsToArchieve_PK ON #RecordsToArchieve([PK]);

		SELECT @TotalRowsToArchive  = COUNT(1) FROM #RecordsToArchieve 
				 
		PRINT CAST(@TotalRowsToArchive AS VARCHAR(25)) + ' [TotalRowsArchived]'

		--PK Min and Max from rows to archieve according to the limit
		SELECT 
			@Min = ISNULL(MIN([PK]),0),
			@Max = ISNULL(MAX([PK]),0) FROM #RecordsToArchieve
				
		PRINT CAST(@Min AS VARCHAR(25)) + ' [PK_Min]'
		PRINT CAST(@Max AS VARCHAR(25)) + ' [PK_Max]'

		--Creating batches
		DROP TABLE IF EXISTS #Batches; CREATE TABLE #Batches (PK BIGINT, Batch INT);
		
		;WITH cte_records_sequence AS
		(
			SELECT 
				[PK]
				,[Sequence] = DENSE_RANK() OVER (ORDER BY [PK])
			FROM #RecordsToArchieve
		), cte_records_batches AS
		(
			SELECT 
				[PK]
				,Batch = ([Sequence] - 1) / @BatchSize + 1
			FROM cte_records_sequence
			WHERE [Sequence] <= @Limit
		)

		INSERT INTO #Batches(PK,Batch)
		SELECT [PK],Batch FROM cte_records_batches

		CREATE INDEX IX_#Batches_PK ON #Batches([PK]) INCLUDE([Batch]);

		DROP TABLE IF EXISTS #BatchesExecution

		SELECT DISTINCT Batch, CAST(0 AS BIT) AS [ctrl]		
		INTO #BatchesExecution
		FROM #Batches 
		
		SELECT @BatchCount = MAX(Batch) FROM #BatchesExecution

		PRINT CAST(@BatchCount AS VARCHAR(25)) + ' [Batches]' 
				
		-- 5) Running batches
		--------------------------------------------------------------------------------------------------------------------

		WHILE EXISTS (SELECT 1 FROM #BatchesExecution WHERE [ctrl] = 0)
		BEGIN

			SET @Deleted = 0
			SET @Inserted = 0

			SELECT @Batch = MIN(Batch) FROM #BatchesExecution WHERE [ctrl] = 0
			
			PRINT '------------------------------ Batch: ' + CAST(@Batch AS VARCHAR(25))
				
				IF @IsDevQA = 0
				BEGIN
				
					-- Total rows per batch
					DECLARE @TotalRowsByBatch BIGINT = ( SELECT  COUNT(1) FROM  #Batches WHERE Batch = @Batch )			
					PRINT CAST(@TotalRowsByBatch AS VARCHAR(25)) + ' [Total rows by batch]'

					-- From and To per batch
					SELECT 
						@PKFrom = ISNULL(MIN([PK]),0),
						@PKTo = ISNULL(MAX([PK]),0) 
					FROM #Batches WHERE Batch = @Batch 	

					PRINT CAST(@PKFrom AS VARCHAR(25)) + ' [PK From]'
					PRINT CAST(@PKTo AS VARCHAR(25)) + ' [PK To]'

					--Record archieved before current execution per batch
					DECLARE @Archieved BIGINT = ( SELECT  COUNT(1) FROM #Batches AS b 
													INNER JOIN [dbo].[EventBadgePrinting_Archive] AS t WITH (NOLOCK)
														ON b.PK = t.PK_EventBadgePrinting 
													WHERE Batch = @Batch )		

					PRINT CAST(@Archieved AS VARCHAR(25)) + ' [Records archieved before current execution]'
						  
					-- Insert in archive table
					PRINT 'Insert into EventBadgePrinting'

					DROP TABLE IF EXISTS #Source

					SELECT 
						[PK_EventBadgePrinting]
						,O.[PK_EventsRegistration]
						,O.[PK_Event]
						,O.[PK_Distributor]
						,O.[DistributorID]
						,O.[FirstName]
						,O.[LastName]
						,O.[COP]
						,O.[TeamStatus]
						,O.[Title]
						,O.[Salutation]
						,O.[BadgeStatus]
						,O.[TerminalID]
						,O.[PortNumber]
						,O.[CreatedDateUTC]
						,O.[CreatedBy]
						,O.[ModifiedDateUTC]
						,O.[ModifiedBy]
					INTO #Source
					FROM [dbo].[EventBadgePrinting] AS O WITH (NOLOCK)
					INNER JOIN #Batches AS b 
					ON O.[PK_EventBadgePrinting] = b.[PK] 
					WHERE b.Batch = @Batch 
					AND NOT EXISTS (SELECT 1 FROM [dbo].[EventBadgeSubEvents] AS A WITH (NOLOCK) WHERE A.[PK_EventBadgePrinting] = O.[PK_EventBadgePrinting])
					
					CREATE INDEX IX_#Source_PK ON #Source([PK_EventBadgePrinting]);

					MERGE [dbo].[EventBadgePrinting_Archive] AS t
					USING #Source AS s
					ON t.PK_EventBadgePrinting = s.PK_EventBadgePrinting
					WHEN NOT MATCHED BY Target THEN
						INSERT ([PK_EventBadgePrinting]
								  ,[PK_EventsRegistration]
								  ,[PK_Event]
								  ,[PK_Distributor]
								  ,[DistributorID]
								  ,[FirstName]
								  ,[LastName]
								  ,[COP]
								  ,[TeamStatus]
								  ,[Title]
								  ,[Salutation]
								  ,[BadgeStatus]
								  ,[TerminalID]
								  ,[PortNumber]
								  ,[CreatedDateUTC]
								  ,[CreatedBy]
								  ,[ModifiedDateUTC]
								  ,[ModifiedBy]) 
						VALUES (
							s.[PK_EventBadgePrinting]
							  ,s.[PK_EventsRegistration]
							  ,s.[PK_Event]
							  ,s.[PK_Distributor]
							  ,s.[DistributorID]
							  ,s.[FirstName]
							  ,s.[LastName]
							  ,s.[COP]
							  ,s.[TeamStatus]
							  ,s.[Title]
							  ,s.[Salutation]
							  ,s.[BadgeStatus]
							  ,s.[TerminalID]
							  ,s.[PortNumber]
							  ,s.[CreatedDateUTC]
							  ,s.[CreatedBy]
							  ,s.[ModifiedDateUTC]
							  ,s.[ModifiedBy]
						);
					
					SET @Inserted = @@ROWCOUNT
					PRINT CAST(@Inserted AS VARCHAR(25)) + ' [Insert RowCount]'
					SET @AccInserted = @AccInserted + ISNULL(@Inserted,0)

					IF (@IsDevQA = 4)
					BEGIN
						;THROW 60001, N'Forcing to fail after insert/archive', 1
					END

					--Delete records archieved
					IF @Inserted > 0
					BEGIN

						PRINT 'Delete from EventBadgePrinting'
						DELETE t FROM [dbo].[EventBadgePrinting] AS t 
								INNER JOIN #Source AS b 
								ON t.[PK_EventBadgePrinting] = b.[PK_EventBadgePrinting]  
			
						SET @Deleted = @@ROWCOUNT
						PRINT CAST(@Deleted AS VARCHAR(25)) + ' [Delete RowCount]'
						SET @AccDeleted= @AccDeleted + ISNULL(@Deleted,0)

					END
		
				IF @Deleted <> @Inserted
				BEGIN
					PRINT 'The counts of inserted and deleted rows are not matching';
				END

				END -- End @IsDevQA = 0
					
				--Creating results records for analysis
				INSERT INTO #Results(Batch,TotalRowsByBatch,FromPK,ToPK,INSERTED,DELETED,ARCHIVED)
				VALUES(@Batch,@TotalRowsByBatch, @PKFrom,@PKTo,@Inserted,@Deleted,@Archieved)
								  
			UPDATE #BatchesExecution
			SET [ctrl] = 1
			WHERE [Batch] = @Batch
		
		END; --End while batches execution

		-- Ending batches
		--------------------------------------------------------------------------------------------------------------------
		
		PRINT '------------------------------ Ending batches '
		
		IF @DisplayResult = 1 SELECT @TableName AS [TableName], Batch,TotalRowsByBatch,FromPK,ToPK,INSERTED,DELETED,ARCHIVED FROM #Results ORDER BY Batch ASC

		PRINT CAST(@AccInserted AS VARCHAR(25)) + ' [Accumulative Inserted Count]' 
		PRINT CAST(@AccDeleted AS VARCHAR(25)) + ' [Accumulative Deleted Count]' 
		
		--------------------------------------------------------------------------------------------------------------------
		-- 6) Getting references conflicts
		--------------------------------------------------------------------------------------------------------------------
		
		;WITH cte_conflicts AS (
				
				SELECT COUNT(1) AS [ref]
				FROM [dbo].[EventBadgePrinting] AS O WITH (NOLOCK)
					INNER JOIN #RecordsToArchieve AS r
					ON O.[PK_EventBadgePrinting] = r.[PK]
					WHERE  EXISTS (SELECT 1 FROM [dbo].[EventBadgeSubEvents] AS A WITH (NOLOCK) WHERE A.[PK_EventBadgePrinting] = O.[PK_EventBadgePrinting])
		)

		SELECT @refConflicts = SUM([ref])  FROM cte_conflicts

		PRINT CAST(@refConflicts AS VARCHAR(25)) + ' [Records skipped due references conflicts]'  


		PRINT '------------------End: ' + @TableName +' ------------------'

		IF (@IsDevQA = 5)
		BEGIN
			;THROW 60001, N'Forcing to fail before to commit tran', 1
		END

		IF @KeepChanges = 1
		BEGIN
			COMMIT TRAN
			SET @TranStatus = 'Succeeded';
		END
		ELSE
		BEGIN
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN 
			SET @TranStatus = 'Forced to rollback';
		END

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
					@StoredProcedureName = @StoredProcedure,
					@StoredProcedureParameters = @StoredProcedureParameters,
					@StartTime = @StartTime;

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA != 0 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		IF @@TRANCOUNT > 0 AND @IsDevQA = 0
		BEGIN
			ROLLBACK TRAN 	
			SET @TranStatus = 'Failed';
		END
		ELSE
			SET @TranStatus = 'Forced to fail';	

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH;

	BEGIN TRY
	IF @LogResult = 1 AND @IsDevQA = 0 AND @TotalRows > 0
	BEGIN

		SET @EndTime = GETUTCDATE()
		SET @InitSeconds = DATEDIFF(SECOND,@StartTime,@EndTime)
		SET @h = (@InitSeconds/3600)
		SET @m = (@InitSeconds-floor(@h*3600))/60
		SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

		SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
		RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
		RIGHT('0'+CONVERT(varchar,@s),2)		

		INSERT INTO [Shared].[ArchivingResults](
			[TableName],
			[LimitPerExecution],
			[BatchSize],
			[ArchiveDate],
			[PK_Min],
			[PK_Max],
			[TotalRows],			
			[TotalRowsArchived],
			[AccInserted],
			[AccDeleted],
			[RefConflicts],
			[RunTime],
			[Status]
			)
		SELECT LTRIM(RTRIM(@TableName)),
				@Limit,
				@BatchSize,
				@ArchiveDate,
				@Min,
				@Max,
				@TotalRows,					
				@TotalRowsToArchive,
				@AccInserted,
				@AccDeleted,
				@refConflicts,
				@RunTime,
				@TranStatus
	
		-- Update processing Log
		SET @StoredProcedureParameters = 'ArchivingResults'
		
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
			@StoredProcedureName = @StoredProcedure,
			@StoredProcedureParameters = @StoredProcedureParameters,
			@StartTime = @StartTime;

	END

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA != 0 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];	

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH;
END;

		