CREATE PROCEDURE [dbo].[usp_Maintain_Events_BizWorks]
	@ExecutionType TINYINT = 1 -- 1 Full sync, 2 Only tickets
	-- QA/DEV
	,@IsDevQA smallint = 0,
	-- Error Parameters
	@Error	int = 0 OUTPUT,
	@ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:			dbo.usp_Maintain_Events_BizWorks

	USE:	        
					USE [PubEventManagement]
					GO

					DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC	[dbo].[usp_Maintain_Events_BizWorks]
					@IsDevQA = 0, 
					@Error = @Error OUTPUT, 
					@ErrorMessage = @ErrorMessage OUTPUT
					
			SELECT	@Error as N'@Error',
					@ErrorMessage as N'@ErrorMessage'


	DESCRIPTION:	This stored procedure is used to refresh/maintain the following related tables for replication to BizWorks:
					Event_BizWorks
					SubEvent_BizWorks
					SubEventQualifier_BizWorks
					EventQualifier_BizWorks
					SKUPurchased_BizWorks
					EventTicketAssignment_BizWorks
					EventsRegistration_BizWorks
				
	Note that those tables cannot be truncated as it is going to be replicated to
					IAPRODETL.DistributorReporting

	NOTES:			

	DEPENDENCIES
	----------------------------------------------------------------------------------


	VERSIONS
	----------------------------------------------------------------------------------
	1	2013-07-09	IniU		Intitial
	2	2016-10-26	Rlun			Add IsPublish Column
	3   2016-04-04  Prashanth		Add IsBizworkReportEnabled Column 
	4   2019-03-21	SandhyaP		Add IsNull for Date columns in Merge statement for Events
	5	2019-10-16  JonathanO  		SRE 
	6	2020-07-30	alejandramed	Fixing issue with uncommitted transactions
	7	2024-11-06	alejandramed	Running syncronization on batches
	8	2025-04-29	alejandramed	Including execution type, sync tickets every 2 hours
	9	2025-06-26	alejandramed	Incluiding subevents on sync happening every 2 hours
	10	2026-06-15	alejandramed	EventQualifiers sync logic it no longer depends on the primary key, preventing the full load behavior.
***********************************************************************************************************************************/

	PRINT IIF(@ExecutionType = 1, 'ExecutionType: Full sync','ExecutionType: Only tickets and subevents') 

	DECLARE @StoredProcedure varchar(255) = 'usp_Maintain_Events_BizWorks'
			,@StoredProcedureParameters varchar(100) = 'Complete'
			,@StartTime datetime2 = GETUTCDATE();
			
	SELECT @Error = 0, @ErrorMessage = '';
	
	SET XACT_ABORT ON;
	SET NOCOUNT ON;
	SET ROWCOUNT 0;

		--------------------------------------------------------------------------------------------------------------------
		-- 1) Variable declaration  
		--------------------------------------------------------------------------------------------------------------------

		DECLARE @Settings NVARCHAR(MAX), 
				@DisplayResult bit  = 0,
				@MonthInterval	INT = 0,
				@EndTime				DATETIME,
				@InitSeconds			INT,
				@h						INT, 
				@m						INT, 
				@s						INT,
				@RunTime				VARCHAR(10),
				@BatchSize				INT,
				@LogResult				BIT,
				@KeepChanges			BIT, 
				@TotalRows				BIGINT, 				
				@Inserted				BIGINT = 0,
				@Updated				BIGINT = 0,
				@Deleted				BIGINT = 0,
				@TranStatus				VARCHAR(250),
				@TableName				VARCHAR(250),
				@Batch					INT, 
				@BatchCount				INT,
				@TimeStamp DATETIME = GETUTCDATE(),
				@StepsStartTime datetime2,
				@RowsDelete BIGINT,
				@BatchDelete INT, 
				@DeletedBatch	BIGINT = 0

		--Temp table to keep the executions result
		DROP TABLE IF EXISTS #Results CREATE TABLE #Results( ID INT IDENTITY(1,1),TableName VARCHAR(100), Batch INT,TotalRows BIGINT,INSERTED BIGINT, UPDATED BIGINT, DELETED BIGINT,[Status] VARCHAR(250), RunTime VARCHAR(10))
		
		--Creating batches tables 
		DROP TABLE IF EXISTS #Batches; CREATE TABLE #Batches (PK BIGINT, Batch INT);
		DROP TABLE IF EXISTS #BatchesExecution CREATE TABLE #BatchesExecution (Batch INT, [ctrl] BIT DEFAULT 0);

 BEGIN TRY
		--------------------------------------------------------------------------------------------------------------------
		-- 2) Getting settings value   
		--------------------------------------------------------------------------------------------------------------------

		SET @Settings = ISNULL((SELECT CONVERT(NVARCHAR(MAX),MAX([value])) FROM [Promo].[Options] WITH (NOLOCK) WHERE [Key] = 'Settings' AND [IsActive] = 1 AND [Group] = 'SyncBizworks'),@Settings)

		-- Getting parameters values for json
		SELECT  
			@BatchSize = [batchSize],
			@LogResult = [logResult],
			@KeepChanges = ISNULL([keepChanges],1),
			@DisplayResult = ISNULL([displayResult],0),
			@MonthInterval = [monthInterval]
		FROM OPENJSON(@Settings)
		WITH (
				[batchSize] INT '$.batchSize',
				[logResult] BIT '$.logResult',
				[keepChanges] BIT '$.keepChanges',
				[displayResult] BIT '$.displayResult',
				[monthInterval] INT '$.monthInterval'
			)
	 
		-- Default values 
		SET @BatchSize = IIF(@BatchSize IS NULL,100000, @BatchSize)
		SET @LogResult = IIF(@LogResult IS NULL,1, @LogResult)
		SET @KeepChanges = IIF(@KeepChanges IS NULL,1, @KeepChanges)
		SET @DisplayResult = IIF(@DisplayResult IS NULL,0, @DisplayResult)
		SET @MonthInterval = IIF(@MonthInterval IS NULL,0, @MonthInterval)
		 
		--Batch size
		PRINT CAST(@BatchSize AS VARCHAR(25)) + ' [BatchSize]' 
	
		IF (@IsDevQA = 2) THROW 60001, N'Forcing to fail for UT', 1;	 
		
		--------------------------------------------------------------------------------------------------------------------
		--/////////////////////////////////////// EVENT TABLE
		--------------------------------------------------------------------------------------------------------------------
		IF @ExecutionType IN (1,2)
		BEGIN

			SET @TableName = 'Event'
			SET @BatchCount = 0

			PRINT '------------------ Start: '+ @TableName  
			SET @TranStatus = 'Processing'

			--------------------------------------------------------------------------------------------------------------------
			--) Getting records 
			--------------------------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #EventBW

			CREATE TABLE #EventBW (
				PK INT IDENTITY(1,1) PRIMARY KEY,
				[PK_Event] [int] NOT NULL,
				[EventName] [nvarchar](200) NULL,
				[EventTypeCode] [varchar](3) NULL,
				[EventType] [varchar](25) NULL,
				[EventStartDate] [smalldatetime] NULL,
				[EventEndDate] [smalldatetime] NULL,
				[QualPeriodStart] [smalldatetime] NULL,
				[QualPeriodEnd] [smalldatetime] NULL,
				[EventLocation] [nvarchar](300) NULL,
				[CreatedDate] [smalldatetime] NULL,
				[CreatedBy] [varchar](50) NULL,
				[ModifiedDate] [smalldatetime] NULL,
				[ModifiedBy] [varchar](50) NULL,
				[IsPublish] [BIT] NULL,
				[IsBizworkReportEnabled] BIT NULL
			)

			INSERT INTO #EventBW(
				PK_Event,
				EventName,
				EventTypeCode,
				EventType,
				EventStartDate,
				EventEndDate,
				QualPeriodStart,
				QualPeriodEnd,
				EventLocation,
				CreatedDate,
				CreatedBy,
				ModifiedDate,
				ModifiedBy,
				IsPublish,
				IsBizworkReportEnabled
			)
			SELECT
				E.PK_Event 
				,E.EventName
				,ET.EventTypeCode 
				,ET.EventType
				,E.dStartUTC 
				,E.dEndUTC 
				,E.QualPeriodStart 
				,E.QualPeriodEnd 
				,E.Location 
				,E.CreatedDateUTC 
				,E.CreatedBy 
				,E.ModifiedDateUTC 
				,E.ModifiedBy 
				,E.IsPublish
				,E.IsBizworkReportEnabled
			FROM 
				dbo.Event E WITH (NOLOCK) 
			INNER JOIN 
				dbo.EventType ET WITH (NOLOCK) 
			ON 
				E.PK_EventType = ET.PK_EventType 
			INNER JOIN 
				dbo.EventSchedule ES WITH (NOLOCK) 
			ON 
				E.PK_Event = ES.PK_Event 
				AND 
				ES.PK_Schedule = 5
			WHERE 
				ET.EventTypeCode NOT IN ('DE','DP','DA','LA','MS')
				AND
				ES.EndUTC >= DATEADD(MM,@MonthInterval,GETDATE())

			SET @Error = @Error + @@ERROR

			CREATE INDEX IX_#EventBW_PK_Event ON #EventBW(PK_Event)

			--Total rows
			SELECT @TotalRows = COUNT(1) FROM #EventBW
			IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [TotalRows Event]'

			--Cleaning up batches table
			DROP INDEX IF EXISTS IX_#Batches_PK ON #Batches;
			TRUNCATE TABLE #Batches;

			;WITH cte_records_sequence AS
			(
				SELECT 
					[PK]
					,[Sequence] = DENSE_RANK() OVER (ORDER BY [PK])
				FROM #EventBW
			), cte_records_batches AS
			(
				SELECT 
					[PK]
					,Batch = ([Sequence] - 1) / @BatchSize + 1
				FROM cte_records_sequence 
			)

			INSERT INTO #Batches(PK,Batch)
			SELECT [PK],Batch FROM cte_records_batches

			CREATE INDEX IX_#Batches_PK ON #Batches([PK]) INCLUDE([Batch]);

			INSERT INTO #BatchesExecution([Batch])
			SELECT DISTINCT Batch 
			FROM #Batches 
		
			SELECT @BatchCount = MAX(Batch) FROM #BatchesExecution

			PRINT CAST(@BatchCount AS VARCHAR(25)) + ' [Batches insert/update]' 
 
			--) Running batches 
			--------------------------------------------------------------------------------------------------------------------
	 
			WHILE EXISTS (SELECT 1 FROM #BatchesExecution WHERE [ctrl] = 0)
			BEGIN

				SET @StepsStartTime = GETUTCDATE()
				SET @Updated = 0
				SET @Deleted = 0
				SET @Inserted = 0

				SELECT @Batch = MIN(Batch) FROM #BatchesExecution WHERE [ctrl] = 0
			
				IF @DisplayResult = 1 PRINT '-> Batch: ' + CAST(@Batch AS VARCHAR(25))
			
					IF @IsDevQA = 0
					BEGIN

						BEGIN TRAN
				
							-- Total rows per batch
							SET @TotalRows = ( SELECT  COUNT(1) FROM  #Batches WHERE Batch = @Batch )			
							IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [Batch Count]'

							DROP TABLE IF EXISTS #SourceEvent

							SELECT
								O.PK_Event,
								O.EventName,
								O.EventTypeCode,
								O.EventType,
								O.EventStartDate,
								O.EventEndDate,
								O.QualPeriodStart,
								O.QualPeriodEnd,
								O.EventLocation,
								O.CreatedDate,
								O.CreatedBy,
								O.ModifiedDate,
								O.ModifiedBy,
								O.IsPublish,
								O.IsBizworkReportEnabled
							INTO #SourceEvent
							FROM #EventBW AS O
							INNER JOIN #Batches AS b 
								ON O.[PK] = b.[PK] 
							WHERE b.Batch = @Batch 
					
							CREATE INDEX IX_#Source_PK ON #SourceEvent([PK_Event]);

							--UPDATE
							UPDATE M
							SET
								 M.EventName = T.EventName
								,M.EventTypeCode = T.EventTypeCode
								,M.EventType = T.EventType
								,M.EventStartDate = T.EventStartDate
								,M.EventEndDate = T.EventEndDate
								,M.QualPeriodStart = T.QualPeriodStart
								,M.QualPeriodEnd = T.QualPeriodEnd 
								,M.EventLocation = T.EventLocation
								,M.ModifiedDate = @TimeStamp
								,M.ModifiedBy = @StoredProcedure
								,M.IsPublish = T.IsPublish
								,M.IsBizworkReportEnabled = T.IsBizworkReportEnabled
							FROM dbo.Event_BizWorks AS M 
								INNER JOIN #SourceEvent AS T 
								ON M.PK_Event = T.PK_Event
							WHERE (M.EventName <> T.EventName OR M.EventTypeCode <> T.EventTypeCode OR M.EventType <> T.EventType OR
							 IsNull(M.EventStartDate, '') <> IsNull(T.EventStartDate,'') OR IsNull(M.EventEndDate,'') <> IsNull(T.EventEndDate,'') OR IsNull(M.QualPeriodStart, '') <> IsNull(T.QualPeriodStart, '') OR 
							 M.QualPeriodEnd <> T.QualPeriodEnd OR M.EventLocation <> T.EventLocation OR ISNULL(M.IsPublish,0) <> ISNULL(T.IsPublish,0) 
							 OR ISNULL(M.IsBizworkReportEnabled,0) <> ISNULL(T.IsBizworkReportEnabled,0))

							SET @Updated = (SELECT ROWCOUNT_BIG())
							IF @Updated > 0 PRINT CAST(@Updated AS VARCHAR(25)) + ' [Update RowCount]'
				
							--INSERT			
							 INSERT dbo.Event_BizWorks (PK_Event 
								,EventName  
								,EventTypeCode 
								,EventType 
								,EventStartDate 
								,EventEndDate 
								,QualPeriodStart 
								,QualPeriodEnd 
								,EventLocation 
								,CreatedDate 
								,CreatedBy 
								,ModifiedDate 
								,ModifiedBy
								,IsPublish 		
								,IsBizworkReportEnabled	
								)
							SELECT S.PK_Event 
									,S.EventName  
									,S.EventTypeCode 
									,S.EventType 
									,S.EventStartDate 
									,S.EventEndDate 
									,S.QualPeriodStart 
									,S.QualPeriodEnd 
									,S.EventLocation 
									,S.CreatedDate 
									,S.CreatedBy 
									,S.ModifiedDate 
									,S.ModifiedBy
									,S.IsPublish 
									,S.IsBizworkReportEnabled
							FROM #SourceEvent AS S  
							WHERE NOT EXISTS (SELECT 1 FROM dbo.Event_BizWorks AS T WITH (NOLOCK) WHERE S.PK_Event = T.PK_Event)
 
							SET @Inserted = (SELECT ROWCOUNT_BIG())
							IF @Inserted > 0 PRINT CAST(@Inserted AS VARCHAR(25)) + ' [Insert RowCount]'
					 
							--DELETE
						
							SELECT @RowsDelete = COUNT(*) FROM dbo.Event_BizWorks AS T WITH (NOLOCK) WHERE NOT EXISTS (SELECT 1 FROM #EventBW AS S WHERE T.PK_Event = S.PK_Event)

							IF (@RowsDelete > 0 )
							BEGIN

								SELECT @BatchDelete = (@RowsDelete / @BatchSize) + 1;

								PRINT CAST(@BatchDelete AS VARCHAR(25)) + ' [Batches delete]' 

								WHILE @BatchDelete > 0
								BEGIN
									SET @DeletedBatch = 0;

									DELETE TOP(@BatchSize) T FROM dbo.Event_BizWorks AS T WHERE NOT EXISTS (SELECT 1 FROM #EventBW AS S WHERE T.PK_Event = S.PK_Event)
							
									SET @DeletedBatch = (SELECT ROWCOUNT_BIG())
									SET @Deleted = @Deleted + @DeletedBatch
							
									IF @DeletedBatch > 0 PRINT CAST(@DeletedBatch AS VARCHAR(25)) + ' [Delete RowCount] - [Batch] - ' + CAST(@BatchDelete AS VARCHAR(25))
									SELECT @BatchDelete = @BatchDelete - 1;

								END; 						
				 
							END

					IF @KeepChanges = 1
					BEGIN
						COMMIT TRAN
						CHECKPOINT
						SET @TranStatus = 'Succeeded';
					END
					ELSE
					BEGIN
						IF @@TRANCOUNT > 0
							ROLLBACK TRAN 
						SET @TranStatus = 'Forced to rollback';
					END
				END -- @IsDevQA

					SET @EndTime = GETUTCDATE()
					SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
					SET @h = (@InitSeconds/3600)
					SET @m = (@InitSeconds-floor(@h*3600))/60
					SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

					SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
					RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
					RIGHT('0'+CONVERT(varchar,@s),2)		

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				--Creating results records for analysis		 
				INSERT INTO #Results(TableName,Batch,TotalRows,INSERTED,UPDATED,DELETED,[Status],[RunTime])
				VALUES(@TableName,@Batch,@TotalRows,@Inserted,@Updated,@Deleted,@TranStatus,@RunTime)

				UPDATE #BatchesExecution
				SET [ctrl] = 1
				WHERE [Batch] = @Batch
		
			END; --End while batches execution

			-- Ending batches
			--------------------------------------------------------------------------------------------------------------------
		
			IF @DisplayResult = 1 PRINT '<- Ending batches '
		
			IF @DisplayResult = 1 SELECT [TableName], Batch,TotalRows,INSERTED,UPDATED,DELETED FROM #Results ORDER BY Batch ASC


			PRINT '------------------ End: ' + @TableName  

		END
		--------------------------------------------------------------------------------------------------------------------
		--/////////////////////////////////////// SUBEVENT TABLE
		--------------------------------------------------------------------------------------------------------------------
		IF @ExecutionType IN (1,2)
		BEGIN

			SET @TableName = 'SubEvent'
			SET @BatchCount = 0

			PRINT '------------------ Start: '+ @TableName  
			SET @TranStatus = 'Processing'

			--------------------------------------------------------------------------------------------------------------------
			--) Getting records 
			--------------------------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #SubEventBW

			CREATE TABLE #SubEventBW (
				PK INT IDENTITY(1,1) PRIMARY KEY,
				[PK_SubEvent] [int] NOT NULL,
				[CreatedDate] [datetime] NULL,
				[CreatedBy] [varchar](50) NULL,
				[ModifiedDate] [datetime] NULL,
				[ModifiedBy] [varchar](50) NULL,
				[PK_Event] [int] NULL,
				[SubEventNumber] [int] NULL,
				[SubEventName] varchar(200) NULL,
				[Location] nvarchar(300) NULL,
				[LocalName] nvarchar(300) NULL,
				[BeginTime] [datetime] NULL,
				[EndTime] [datetime] NULL,
				[IsMainEventQual] [bit] NULL,
				[IncludeInBizworkReport] BIT NULL,
			)

			INSERT INTO #SubEventBW(
				PK_Event,
				PK_SubEvent,
				SubEventName,
				SubEventNumber,
				IsMainEventQual,
				Location,
				LocalName,
				BeginTime,
				EndTime,
				CreatedDate,
				CreatedBy,
				ModifiedDate,
				ModifiedBy,
				IncludeInBizworkReport
			)
			SELECT
				E.PK_Event 
				,SE.PK_SubEvent 
				,SE.SubEventName  
				,SE.SubEventNumber 
				,SE.IsMainEventQual
				,SE.Location 
				,SE.LocalName  
				,SE.BeginTime  
				,SE.EndTime 
				,SE.CreatedDateUTC 
				,SE.CreatedBy 
				,SE.ModifiedDateUTC 
				,SE.ModifiedBy
				,SE.IncludeInBizworkReport
			FROM 
				#EventBW E (NOLOCK) 
			INNER JOIN 
				dbo.SubEvent SE WITH (NOLOCK) 
			ON 
				E.PK_Event = SE.PK_Event

			SET @Error = @Error + @@ERROR

			CREATE INDEX IX_#SubEventBW_PK_Event ON #SubEventBW(PK_Event)
			CREATE INDEX IX_#SubEventBW_PK_SubEvent ON #SubEventBW(PK_SubEvent)

			--Total rows
			SELECT @TotalRows = COUNT(1) FROM #SubEventBW
			IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [TotalRows SubEvents]'

			--Cleaning up batches table
			DROP INDEX IF EXISTS IX_#Batches_PK ON #Batches;
			TRUNCATE TABLE #Batches;
		
			;WITH cte_records_sequence AS
			(
				SELECT 
					[PK]
					,[Sequence] = DENSE_RANK() OVER (ORDER BY [PK])
				FROM #SubEventBW
			), cte_records_batches AS
			(
				SELECT 
					[PK]
					,Batch = ([Sequence] - 1) / @BatchSize + 1
				FROM cte_records_sequence 
			)

			INSERT INTO #Batches(PK,Batch)
			SELECT [PK],Batch FROM cte_records_batches

			CREATE INDEX IX_#Batches_PK ON #Batches([PK]) INCLUDE([Batch]);

			INSERT INTO #BatchesExecution([Batch])
			SELECT DISTINCT Batch 
			FROM #Batches 
		
			SELECT @BatchCount = MAX(Batch) FROM #BatchesExecution

			PRINT CAST(@BatchCount AS VARCHAR(25)) + ' [Batches insert/update]' 
 
			--) Running batches 
			--------------------------------------------------------------------------------------------------------------------
	 
			WHILE EXISTS (SELECT 1 FROM #BatchesExecution WHERE [ctrl] = 0)
			BEGIN

				SET @StepsStartTime = GETUTCDATE()
				SET @Updated = 0
				SET @Deleted = 0
				SET @Inserted = 0

				SELECT @Batch = MIN(Batch) FROM #BatchesExecution WHERE [ctrl] = 0
			
				IF @DisplayResult = 1 PRINT '-> Batch: ' + CAST(@Batch AS VARCHAR(25))
				
					IF @IsDevQA = 0
					BEGIN
				
						BEGIN TRAN

						-- Total rows per batch
						SET @TotalRows = ( SELECT  COUNT(1) FROM  #Batches WHERE Batch = @Batch )			
						IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [Batch Count]'

						DROP TABLE IF EXISTS #SourceSubEvent

						SELECT
							O.PK_Event,
							O.PK_SubEvent,
							O.SubEventName,
							O.SubEventNumber,
							O.IsMainEventQual,
							O.[Location],
							O.LocalName,
							O.BeginTime,
							O.EndTime,
							O.CreatedDate,
							O.CreatedBy,
							O.ModifiedDate,
							O.ModifiedBy,
							O.IncludeInBizworkReport
						INTO #SourceSubEvent
						FROM #SubEventBW AS O
						INNER JOIN #Batches AS b 
							ON O.[PK] = b.[PK] 
						WHERE b.Batch = @Batch 
					
						CREATE INDEX IX_#SourceSubEvent_PK_Event ON #SourceSubEvent(PK_Event);
						CREATE INDEX IX_#SourceSubEvent_PK_SubEvent ON #SourceSubEvent(PK_SubEvent);

						--UPDATE
						UPDATE M
						SET
						 M.SubEventName = T.SubEventName
						,M.SubEventNumber = T.SubEventNumber
						,M.Location = T.Location
						,M.LocalName = T.LocalName
						,M.BeginTime = T.BeginTime
						,M.EndTime = T.EndTime
						,M.ModifiedDate = @TimeStamp
						,M.ModifiedBy = @StoredProcedure
						,M.IncludeInBizworkReport = T.IncludeInBizworkReport
						FROM dbo.SubEvent_BizWorks AS M 
							INNER JOIN #SourceSubEvent AS T 
							ON M.PK_Event = T.PK_Event AND M.PK_SubEvent = T.PK_SubEvent
						WHERE (M.SubEventName <> T.SubEventName OR M.SubEventNumber <> T.SubEventNumber OR M.Location <> T.Location OR
						M.LocalName <> T.LocalName OR ISNULL(M.IncludeInBizworkReport,0) <> ISNULL(T.IncludeInBizworkReport,0))

						SET @Updated = (SELECT ROWCOUNT_BIG())
						IF @Updated > 0  PRINT CAST(@Updated AS VARCHAR(25)) + ' [Update RowCount]'
	
						 --INSERT 
						 INSERT INTO dbo.SubEvent_BizWorks(PK_Event 
								,PK_SubEvent
								,SubEventName  
								,SubEventNumber
								,Location 
								,LocalName 
								,BeginTime 
								,EndTime 
								,CreatedDate 
								,CreatedBy 
								,ModifiedDate 
								,ModifiedBy
								,IncludeInBizworkReport
								)
							SELECT S.PK_Event 
									,S.PK_SubEvent
									,S.SubEventName  
									,S.SubEventNumber 
									,S.Location 
									,S.LocalName 
									,S.BeginTime 
									,S.EndTime 
									,S.CreatedDate 
									,S.CreatedBy 
									,S.ModifiedDate 
									,S.ModifiedBy 
									,S.IncludeInBizworkReport
							FROM #SourceSubEvent AS S 
							WHERE NOT EXISTS (SELECT 1 FROM dbo.SubEvent_BizWorks AS T WITH (NOLOCK) WHERE S.PK_Event = T.PK_Event AND S.PK_SubEvent = T.PK_SubEvent )
		
						SET @Inserted = (SELECT ROWCOUNT_BIG())
						IF @Inserted > 0 PRINT CAST(@Inserted AS VARCHAR(25)) + ' [Insert RowCount]' 

						 --DELETE 

						SELECT @RowsDelete = COUNT(*) FROM dbo.SubEvent_BizWorks AS T WITH (NOLOCK) WHERE NOT EXISTS (SELECT 1 FROM #SubEventBW AS S WHERE T.PK_Event = S.PK_Event)

						IF (@RowsDelete > 0 )
						BEGIN

							SELECT @BatchDelete = (@RowsDelete / @BatchSize) + 1;
					
							PRINT CAST(@BatchDelete AS VARCHAR(25)) + ' [Batches delete]' 

							WHILE @BatchDelete > 0
							BEGIN
								SET @DeletedBatch = 0;

									DELETE TOP(@BatchSize) T FROM dbo.SubEvent_BizWorks AS T WHERE NOT EXISTS (SELECT 1 FROM #SubEventBW AS S WHERE T.PK_Event = S.PK_Event)
							
									SET @DeletedBatch = (SELECT ROWCOUNT_BIG())
									SET @Deleted = @Deleted + @DeletedBatch
							
									IF @DeletedBatch > 0 PRINT CAST(@DeletedBatch AS VARCHAR(25)) + ' [Delete RowCount] - [Batch] - ' + CAST(@BatchDelete AS VARCHAR(25))
									SELECT @BatchDelete = @BatchDelete - 1;

							END;  
 						END

					IF @KeepChanges = 1
					BEGIN
						COMMIT TRAN
						CHECKPOINT
						SET @TranStatus = 'Succeeded';
					END
					ELSE
					BEGIN
						IF @@TRANCOUNT > 0
							ROLLBACK TRAN 
						SET @TranStatus = 'Forced to rollback';
					END
				END -- @IsDevQA

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				--Creating results records for analysis		 
				INSERT INTO #Results(TableName,Batch,TotalRows,INSERTED,UPDATED,DELETED,[Status],[RunTime])
				VALUES(@TableName,@Batch,@TotalRows,@Inserted,@Updated,@Deleted,@TranStatus,@RunTime)

				UPDATE #BatchesExecution
				SET [ctrl] = 1
				WHERE [Batch] = @Batch
		
			END; --End while batches execution

			-- Ending batches
			--------------------------------------------------------------------------------------------------------------------
	 
			PRINT '<- Ending batches '
		
			IF @DisplayResult = 1 SELECT [TableName], Batch,TotalRows,INSERTED,UPDATED,DELETED FROM #Results ORDER BY Batch ASC


			PRINT '------------------ End: ' + @TableName  
		END
		--------------------------------------------------------------------------------------------------------------------
		--/////////////////////////////////////// SUBEVENT QUALIFIERS TABLE
		--------------------------------------------------------------------------------------------------------------------
		IF @ExecutionType = 1
		BEGIN

			SET @TableName = 'SubEventQualifier'
			SET @BatchCount = 0

			PRINT '------------------ Start: '+ @TableName  
			SET @TranStatus = 'Processing'

			--------------------------------------------------------------------------------------------------------------------
			--) Getting records 
			--------------------------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #SubEventQualifierBW

			CREATE TABLE #SubEventQualifierBW (
				PK int IDENTITY(1,1) PRIMARY KEY,
				[PK_SubEventQualifier] [int] NULL,
				[CreatedDate] [datetime] NULL,
				[CreatedBy] [varchar](50) NULL,
				[ModifiedDate] [datetime] NULL,
				[ModifiedBy] [varchar](50) NULL,
				[PK_Event] [int] NULL,
				[PK_SubEvent] [int] NULL,
				[PK_Distributor_EDW] [int] NULL,
				[DistributorID] [varchar](20) NULL,
				[QualDate] [smalldatetime] NULL,
				[AddedDate] [smalldatetime] NULL,
				[RemovedDate] [smalldatetime] NULL,
				[IsManualOverride] [bit] NULL,
				[Qualified] [int] NULL
			)

			INSERT INTO #SubEventQualifierBW (
				PK_SubEventQualifier,
				CreatedDate,
				CreatedBy,
				ModifiedDate,
				ModifiedBy,
				PK_Event,
				PK_SubEvent,
				PK_Distributor_EDW,
				DistributorID,
				QualDate,
				AddedDate,
				RemovedDate,
				IsManualOverride,
				Qualified
			)
			SELECT
				SEQ.PK_SubEventQualifier 
				,SEQ.CreatedDateUTC 
				,SEQ.CreatedBy 
				,SEQ.ModifiedDateUTC 
				,SEQ.ModifiedBy 
				,SE.PK_Event 
				,SE.PK_SubEvent 
				,SEQ.PK_Distributor 
				,SEQ.DistributorID 
				,SEQ.QualDate 
				,SEQ.AddedUTC 
				,SEQ.RemovedUTC 
				,SEQ.IsManualOverride 
				,SEQ.Qualified 
			FROM
				#SubEventBW SE
			INNER JOIN
				dbo.SubEventQualifier SEQ WITH (NOLOCK) 
			ON
				SE.PK_Event = SEQ.PK_Event 
				AND
				SE.PK_SubEvent = SEQ.PK_SubEvent 
				AND
				SEQ.RemovedUTC = '2049-12-31'

			SET @Error = @Error + @@ERROR

			CREATE INDEX IX_#SubEventQualifierBW_PK_Event ON #SubEventQualifierBW(PK_Event)
			CREATE INDEX IX_#SubEventQualifierBW_PK_SubEvent ON #SubEventQualifierBW(PK_SubEvent)
			CREATE INDEX IX_#SubEventQualifierBW_PK_Distributor_EDW ON #SubEventQualifierBW(PK_Distributor_EDW)
			CREATE INDEX IX_#SubEventQualifierBW_PK_SubEventQualifier ON #SubEventQualifierBW(PK_SubEventQualifier)

			--Total rows
			SELECT @TotalRows = COUNT(1) FROM #SubEventQualifierBW
			IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [TotalRows SubEventQualifier]'

			--Cleaning up batches table
			DROP INDEX IF EXISTS IX_#Batches_PK ON #Batches;
			TRUNCATE TABLE #Batches;
		
			;WITH cte_records_sequence AS
			(
				SELECT 
					[PK]
					,[Sequence] = DENSE_RANK() OVER (ORDER BY [PK])
				FROM #SubEventQualifierBW 
			), cte_records_batches AS
			(
				SELECT 
					[PK]
					,Batch = ([Sequence] - 1) / @BatchSize + 1
				FROM cte_records_sequence 
			)

			INSERT INTO #Batches(PK,Batch)
			SELECT [PK],Batch FROM cte_records_batches

			CREATE INDEX IX_#Batches_PK ON #Batches([PK]) INCLUDE([Batch]);

			INSERT INTO #BatchesExecution([Batch])
			SELECT DISTINCT Batch 
			FROM #Batches 
		
			SELECT @BatchCount = MAX(Batch) FROM #BatchesExecution

			PRINT CAST(@BatchCount AS VARCHAR(25)) + ' [Batches insert/update]' 
 
			--) Running batches 
			--------------------------------------------------------------------------------------------------------------------
	 
			WHILE EXISTS (SELECT 1 FROM #BatchesExecution WHERE [ctrl] = 0)
			BEGIN

				SET @StepsStartTime = GETUTCDATE()
				SET @Updated = 0
				SET @Deleted = 0
				SET @Inserted = 0

				SELECT @Batch = MIN(Batch) FROM #BatchesExecution WHERE [ctrl] = 0
			
				IF @DisplayResult = 1 PRINT '-> Batch: ' + CAST(@Batch AS VARCHAR(25))
				
				IF @IsDevQA = 0
				BEGIN
				
					BEGIN TRAN

						-- Total rows per batch
						SET @TotalRows = ( SELECT  COUNT(1) FROM  #Batches WHERE Batch = @Batch )			
						IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [Batch Count]'

						DROP TABLE IF EXISTS #SourceSubEventQualifier

						SELECT
							O.PK_SubEventQualifier,
							O.CreatedDate,
							O.CreatedBy,
							O.ModifiedDate,
							O.ModifiedBy,
							O.PK_Event,
							O.PK_SubEvent,
							O.PK_Distributor_EDW,
							O.DistributorID,
							O.QualDate,
							O.AddedDate,
							O.RemovedDate,
							O.IsManualOverride,
							O.Qualified
						INTO #SourceSubEventQualifier
						FROM #SubEventQualifierBW AS O
						INNER JOIN #Batches AS b 
							ON O.[PK] = b.[PK] 
						WHERE b.Batch = @Batch 
					
						CREATE INDEX IX_#SourceSubEventQualifier_PK_Event ON #SourceSubEventQualifier(PK_Event)
						CREATE INDEX IX_#SourceSubEventQualifier_PK_SubEvent ON #SourceSubEventQualifier(PK_SubEvent)
						CREATE INDEX IX_#SourceSubEventQualifier_PK_Distributor_EDW ON #SourceSubEventQualifier(PK_Distributor_EDW)
						CREATE INDEX IX_#SourceSubEventQualifier_PK_SubEventQualifier ON #SourceSubEventQualifier(PK_SubEventQualifier)

						--UPDATE				 
						UPDATE M
						SET
							M.DistributorID = T.DistributorID
							,M.Qualified = T.Qualified
							,M.IsManualOverride = T.IsManualOverride
							,M.RemovedDate = T.RemovedDate
							,M.QualDate = T.QualDate
							,M.Addeddate = T.AddedDate
							,M.ModifiedDate = @TimeStamp
							,M.ModifiedBy = @StoredProcedure
						FROM dbo.SubEventQualifier_BizWorks AS M 
							INNER JOIN #SourceSubEventQualifier AS T 
								ON M.PK_SubEventQualifier = T.PK_SubEventQualifier 
						WHERE (M.PK_Event <> T.PK_Event OR M.PK_SubEvent <> T.PK_SubEvent OR M.PK_Distributor_EDW <> T.PK_Distributor_EDW
						OR M.IsManualOverride <> T.IsManualOverride OR M.Qualified <> T.Qualified)
				 
						SET @Updated = (SELECT ROWCOUNT_BIG())
						IF @Updated > 0 PRINT CAST(@Updated AS VARCHAR(25)) + ' [Update RowCount]'

						--INSERT
						INSERT [dbo].[SubEventQualifier_BizWorks] 
						(PK_SubEventQualifier
						,PK_Event 
						,PK_SubEvent
						,PK_Distributor_EDW
						,DistributorID
						,QualDate
						,AddedDate
						,RemovedDate
						,IsManualOverride
						,Qualified
						,CreatedDate 
						,CreatedBy 
						,ModifiedDate 
						,ModifiedBy)	
						SELECT 
							S.PK_SubEventQualifier
						,S.PK_Event 
						,S.PK_SubEvent
						,S.PK_Distributor_EDW
						,S.DistributorID
						,S.QualDate
						,S.AddedDate
						,S.RemovedDate
						,S.IsManualOverride
						,S.Qualified
						,S.CreatedDate 
						,S.CreatedBy 
						,S.ModifiedDate 
						,S.ModifiedBy 
						FROM #SourceSubEventQualifier AS S  
						WHERE NOT EXISTS (SELECT 1 FROM dbo.SubEventQualifier_BizWorks AS T WITH (NOLOCK) WHERE S.PK_SubEventQualifier = T.PK_SubEventQualifier)
						
						SET @Inserted = (SELECT ROWCOUNT_BIG())
						IF @Inserted > 0 PRINT CAST(@Inserted AS VARCHAR(25)) + ' [Insert RowCount]' 
				
						 --DELETE 

							SELECT @RowsDelete = COUNT(*) FROM dbo.SubEventQualifier_BizWorks AS T WITH (NOLOCK) WHERE NOT EXISTS (SELECT 1 FROM #SubEventQualifierBW AS S WHERE T.PK_SubEventQualifier = S.PK_SubEventQualifier)

							IF (@RowsDelete > 0 )
							BEGIN
						
								SELECT @BatchDelete = (@RowsDelete / @BatchSize) + 1;
						
								PRINT CAST(@BatchDelete AS VARCHAR(25)) + ' [Batches delete]' 

								WHILE @BatchDelete > 0
								BEGIN
									SET @DeletedBatch = 0;

									DELETE TOP(@BatchSize) T FROM dbo.SubEventQualifier_BizWorks AS T WHERE NOT EXISTS (SELECT 1 FROM #SubEventQualifierBW AS S WHERE T.PK_SubEventQualifier = S.PK_SubEventQualifier)
							
									SET @DeletedBatch = (SELECT ROWCOUNT_BIG())
									SET @Deleted = @Deleted + @DeletedBatch
							
									IF @DeletedBatch > 0 PRINT CAST(@DeletedBatch AS VARCHAR(25)) + ' [Delete RowCount] - [Batch] - ' + CAST(@BatchDelete AS VARCHAR(25))
									SELECT @BatchDelete = @BatchDelete - 1;

								END;  

							END

					IF @KeepChanges = 1
					BEGIN
						COMMIT TRAN
						CHECKPOINT
						SET @TranStatus = 'Succeeded';
					END
					ELSE
					BEGIN
						IF @@TRANCOUNT > 0
							ROLLBACK TRAN 
						SET @TranStatus = 'Forced to rollback';
					END

				END -- @IsDevQA

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				--Creating results records for analysis		 
				INSERT INTO #Results(TableName,Batch,TotalRows,INSERTED,UPDATED,DELETED,[Status],[RunTime])
				VALUES(@TableName,@Batch,@TotalRows,@Inserted,@Updated,@Deleted,@TranStatus,@RunTime)

				UPDATE #BatchesExecution
				SET [ctrl] = 1
				WHERE [Batch] = @Batch
		
			END; --End while batches execution

			-- Ending batches
			--------------------------------------------------------------------------------------------------------------------
		
			PRINT '<- Ending batches '
		
			IF @DisplayResult = 1 SELECT [TableName], Batch,TotalRows,INSERTED,UPDATED,DELETED FROM #Results ORDER BY Batch ASC


			PRINT '------------------ End: ' + @TableName  
		END
		--------------------------------------------------------------------------------------------------------------------
		--/////////////////////////////////////// EVENT QUALIFIERS TABLE
		--------------------------------------------------------------------------------------------------------------------
		IF @ExecutionType = 1
		BEGIN

			SET @TableName = 'EventQualifier'
			SET @BatchCount = 0

			PRINT '------------------ Start: '+ @TableName  
			SET @TranStatus = 'Processing'

			--------------------------------------------------------------------------------------------------------------------
			--) Getting records 
			--------------------------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #EventQualifierBW

			CREATE TABLE #EventQualifierBW (
			PK int IDENTITY(1,1) PRIMARY KEY,
			[PK_EventQualifier] [bigint] NULL,
			[CreatedDate] [datetime] NULL,
			[CreatedBy] [varchar](50) NULL,
			[ModifiedDate] [datetime] NULL,
			[ModifiedBy] [varchar](50) NULL,
			[PK_Event] [int] NULL,
			[PK_Distributor_EDW] [int] NULL,
			[DistributorID] [varchar](20) NULL,
			[Qualified] [int] NULL
		)

			INSERT INTO #EventQualifierBW (
			PK_EventQualifier,
			CreatedDate,
			CreatedBy,
			ModifiedDate,
			ModifiedBy,
			PK_Event,
			PK_Distributor_EDW,
			DistributorID,
			Qualified
			)
			SELECT
				DISTINCT
				EQ.PK_EventQualifier 
				,EQ.CreatedDateUTC 
				,EQ.CreatedBy 
				,EQ.ModifiedDateUTC 
				,EQ.ModifiedBy 
				,E.PK_Event 
				,EQ.PK_Distributor 
				,EQ.DistributorID 
				,EQ.Qualified 
			FROM
				#EventBW E
			INNER JOIN
				dbo.EventQualifier EQ WITH (NOLOCK) 
			ON
				E.PK_Event = EQ.PK_Event 
			INNER JOIN
				dbo.SubEvent SE  WITH (NOLOCK) 
			ON
				E.PK_Event = SE.PK_Event
				AND
				SE.IsMainEventQual = 1
			INNER JOIN
				dbo.SubEventQualifier SEQ WITH (NOLOCK)
			ON
				E.PK_Event = SEQ.PK_Event
				AND
				SE.PK_SubEvent = SEQ.PK_SubEvent 
				AND
				EQ.PK_Distributor = SEQ.PK_Distributor
				AND
				SEQ.RemovedUTC = '2049-12-31'


			SET @Error = @Error + @@ERROR

			CREATE INDEX IX_#EventQualifierBW_PK_Event ON #EventQualifierBW(PK_Event)
			CREATE INDEX IX_#EventQualifierBW_PK_Distributor_EDW ON #EventQualifierBW(PK_Distributor_EDW)

			--Total rows
			SELECT @TotalRows = COUNT(1) FROM #EventQualifierBW
			IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [TotalRows EventQualifier]'

			--Cleaning up batches table
			DROP INDEX IF EXISTS IX_#Batches_PK ON #Batches;
			TRUNCATE TABLE #Batches;
		
			;WITH cte_records_sequence AS
			(
				SELECT 
					[PK]
					,[Sequence] = DENSE_RANK() OVER (ORDER BY [PK])
				FROM #EventQualifierBW 
			), cte_records_batches AS
			(
				SELECT 
					[PK]
					,Batch = ([Sequence] - 1) / @BatchSize + 1
				FROM cte_records_sequence 
			)

			INSERT INTO #Batches(PK,Batch)
			SELECT [PK],Batch FROM cte_records_batches

			CREATE INDEX IX_#Batches_PK ON #Batches([PK]) INCLUDE([Batch]);

			INSERT INTO #BatchesExecution([Batch])
			SELECT DISTINCT Batch 
			FROM #Batches 
		
			SELECT @BatchCount = MAX(Batch) FROM #BatchesExecution

			PRINT CAST(@BatchCount AS VARCHAR(25)) + ' [Batches insert/update]' 
 
			--) Running batches 
			--------------------------------------------------------------------------------------------------------------------
	 
			WHILE EXISTS (SELECT 1 FROM #BatchesExecution WHERE [ctrl] = 0)
			BEGIN

				SET @StepsStartTime = GETUTCDATE()
				SET @Updated = 0
				SET @Deleted = 0
				SET @Inserted = 0

				SELECT @Batch = MIN(Batch) FROM #BatchesExecution WHERE [ctrl] = 0
			
				IF @DisplayResult = 1 PRINT '-> Batch: ' + CAST(@Batch AS VARCHAR(25))
				
				IF @IsDevQA = 0
				BEGIN
				
					BEGIN TRAN

						-- Total rows per batch
						SET @TotalRows = ( SELECT  COUNT(1) FROM  #Batches WHERE Batch = @Batch )			
						IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [Batch Count]'

						DROP TABLE IF EXISTS #SourceEventQualifier

						SELECT
							PK_EventQualifier,
							CreatedDate,
							CreatedBy,
							ModifiedDate,
							ModifiedBy,
							PK_Event,
							PK_Distributor_EDW,
							DistributorID,
							Qualified
						INTO #SourceEventQualifier
						FROM #EventQualifierBW AS O
						INNER JOIN #Batches AS b 
							ON O.[PK] = b.[PK] 
						WHERE b.Batch = @Batch 
					
						CREATE INDEX IX_#SourceEventQualifier_PK_Event ON #SourceEventQualifier(PK_Event)
						CREATE INDEX IX_#SourceEventQualifier_PK_Distributor_EDW ON #SourceEventQualifier(PK_Distributor_EDW)

						--UPDATE				 
						UPDATE M
						SET
							 M.DistributorID = T.DistributorID
							,M.Qualified = T.Qualified
							,M.ModifiedDate = @TimeStamp
							,M.ModifiedBy = @StoredProcedure
						FROM dbo.EventQualifier_BizWorks AS M
						INNER JOIN #SourceEventQualifier AS T
						ON M.PK_Event = T.PK_Event AND M.PK_Distributor_EDW = T.PK_Distributor_EDW
						WHERE (M.DistributorID <> T.DistributorID OR M.Qualified <> T.Qualified)	
				 
						SET @Updated = (SELECT ROWCOUNT_BIG())
						IF @Updated > 0 PRINT CAST(@Updated AS VARCHAR(25)) + ' [Update RowCount]'

						--INSERT
						INSERT [dbo].[EventQualifier_BizWorks] (PK_EventQualifier
						,PK_Event 
						,PK_Distributor_EDW
						,DistributorID
						,Qualified
						,CreatedDate 
						,CreatedBy 
						,ModifiedDate 
						,ModifiedBy 			
						)	
						SELECT 
						T.PK_EventQualifier
						,T.PK_Event 
						,T.PK_Distributor_EDW
						,T.DistributorID
						,T.Qualified
						,T.CreatedDate 
						,T.CreatedBy 
						,T.ModifiedDate 
						,T.ModifiedBy
						FROM #SourceEventQualifier AS T 
						WHERE NOT EXISTS (SELECT 1 FROM dbo.[EventQualifier_BizWorks] AS S WITH (NOLOCK) 
							WHERE S.PK_Event = T.PK_Event AND S.PK_Distributor_EDW = T.PK_Distributor_EDW)
						
						SET @Inserted = (SELECT ROWCOUNT_BIG())
						IF @Inserted > 0 PRINT CAST(@Inserted AS VARCHAR(25)) + ' [Insert RowCount]' 
				
						--DELETE 

						SELECT @RowsDelete = COUNT(*) FROM dbo.[EventQualifier_BizWorks] AS T WITH (NOLOCK) WHERE NOT EXISTS (SELECT 1 FROM #EventQualifierBW AS S WHERE S.PK_Event = T.PK_Event AND S.PK_Distributor_EDW = T.PK_Distributor_EDW)

						IF (@RowsDelete > 0 )
						BEGIN

							SELECT @BatchDelete = (@RowsDelete / @BatchSize) + 1;

							PRINT CAST(@BatchDelete AS VARCHAR(25)) + ' [Batches delete]' 

							WHILE @BatchDelete > 0
							BEGIN
								SET @DeletedBatch = 0;

									DELETE TOP(@BatchSize) T FROM dbo.[EventQualifier_BizWorks] AS T WHERE NOT EXISTS (SELECT 1 FROM #EventQualifierBW AS S WHERE S.PK_Event = T.PK_Event AND S.PK_Distributor_EDW = T.PK_Distributor_EDW)
							
									SET @DeletedBatch = (SELECT ROWCOUNT_BIG())
									SET @Deleted = @Deleted + @DeletedBatch
							
									IF @DeletedBatch > 0 PRINT CAST(@DeletedBatch AS VARCHAR(25)) + ' [Delete RowCount] - [Batch] - ' + CAST(@BatchDelete AS VARCHAR(25))
									SELECT @BatchDelete = @BatchDelete - 1;

							END;  

						END

					IF @KeepChanges = 1
					BEGIN
						COMMIT TRAN
						CHECKPOINT
						SET @TranStatus = 'Succeeded';
					END
					ELSE
					BEGIN
						IF @@TRANCOUNT > 0
							ROLLBACK TRAN 
						SET @TranStatus = 'Forced to rollback';
					END

				END -- @IsDevQA

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				--Creating results records for analysis		 
				INSERT INTO #Results(TableName,Batch,TotalRows,INSERTED,UPDATED,DELETED,[Status],[RunTime])
				VALUES(@TableName,@Batch,@TotalRows,@Inserted,@Updated,@Deleted,@TranStatus,@RunTime)
			
				UPDATE #BatchesExecution
				SET [ctrl] = 1
				WHERE [Batch] = @Batch
		
			END; --End while batches execution

			-- Ending batches
			--------------------------------------------------------------------------------------------------------------------
		
			PRINT '<- Ending batches '
		
			IF @DisplayResult = 1 SELECT [TableName], Batch,TotalRows,INSERTED,UPDATED,DELETED FROM #Results ORDER BY Batch ASC


			PRINT '------------------ End: ' + @TableName  
		END
		--------------------------------------------------------------------------------------------------------------------
		--/////////////////////////////////////// SKUPURCHASED TABLE
		--------------------------------------------------------------------------------------------------------------------
		IF @ExecutionType IN (1,2)
		BEGIN
			SET @TableName = 'SKUPurchased'
			SET @BatchCount = 0

			PRINT '------------------ Start: '+ @TableName  
			SET @TranStatus = 'Processing'

			--------------------------------------------------------------------------------------------------------------------
			--) Getting records 
			--------------------------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #SKUPurchasedBW

			CREATE TABLE #SKUPurchasedBW (
				PK INT IDENTITY(1,1) PRIMARY KEY,
				[PK_SKUPurchased] [int] NOT NULL,
				[CreatedDate] [datetime] NULL,
				[CreatedBy] [varchar](50) NULL,
				[ModifiedDate] [datetime] NULL,
				[ModifiedBy] [varchar](50) NULL,
				[PK_Event] [int] NOT NULL,
				[PK_EventSKU] [int] NOT NULL,
				[SKUCode] [varchar](10) NOT NULL,
				[PK_Distributor_EDW] [int] NULL,
				[DistributorID] [varchar](10) NULL,
				[OrderDate] [smalldatetime] NULL,
				[NTSDate] [datetime] NULL,
				[OrderNumber] [varchar](10) NULL,
				[OrderType] [varchar](2) NULL,
				[Quantity] [int] NULL,
				[IsManual] [bit] NULL
			)

			INSERT INTO #SKUPurchasedBW(
				PK_SKUPurchased,
				CreatedDate,
				CreatedBy,
				ModifiedDate,
				ModifiedBy,
				PK_Event,
				PK_EventSKU,
				SKUCode,
				PK_Distributor_EDW,
				DistributorID,
				OrderDate,
				NTSDate,
				OrderNumber,
				OrderType,
				Quantity,
				IsManual
			)
			SELECT
				P.PK_SKUPurchased,
				P.CreatedDateUTC,
				P.CreatedBy,
				P.ModifiedDateUTC,
				P.ModifiedBy,
				E.PK_Event,
				P.PK_EventSKU,
				ES.SKUCode,
				P.PK_Distributor_Purchaser,
				P.DistributorID,
				P.OrderDate,
				P.NTSDate,
				P.OrderNumber,
				P.OrderType,
				P.Quantity,
				P.IsManual
			FROM 
				#EventBW E
			INNER JOIN
				dbo.SKUPurchased P WITH (NOLOCK) 
			ON
				E.PK_Event = P.PK_Event 
			INNER JOIN
				dbo.EventSKU ES WITH (NOLOCK) 
			ON
				E.PK_Event = ES.PK_Event 
				AND
				P.PK_EventSKU = ES.PK_EventSKU 
	
			SET @Error = @Error + @@ERROR
	
			CREATE INDEX IX_#SKUPurchasedBW_PK_Event ON #SKUPurchasedBW(PK_Event)
			CREATE INDEX IX_#SKUPurchasedBW_PK_Distributor_EDW ON #SKUPurchasedBW(PK_Distributor_EDW)
			CREATE INDEX IX_#SKUPurchasedBW_PK_EventSKU ON #SKUPurchasedBW(PK_EventSKU)
			CREATE INDEX IX_#SKUPurchasedBW_SKUCode ON #SKUPurchasedBW(SKUCode)

			--Total rows
			SELECT @TotalRows = COUNT(1) FROM #SKUPurchasedBW
			IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [TotalRows SKUPurchased]'

			--Cleaning up batches table
			DROP INDEX IF EXISTS IX_#Batches_PK ON #Batches;
			TRUNCATE TABLE #Batches;
		
			;WITH cte_records_sequence AS
			(
				SELECT 
					[PK]
					,[Sequence] = DENSE_RANK() OVER (ORDER BY [PK])
				FROM #SKUPurchasedBW 
			), cte_records_batches AS
			(
				SELECT 
					[PK]
					,Batch = ([Sequence] - 1) / @BatchSize + 1
				FROM cte_records_sequence 
			)

			INSERT INTO #Batches(PK,Batch)
			SELECT [PK],Batch FROM cte_records_batches

			CREATE INDEX IX_#Batches_PK ON #Batches([PK]) INCLUDE([Batch]);

			INSERT INTO #BatchesExecution([Batch])
			SELECT DISTINCT Batch 
			FROM #Batches 
		
			SELECT @BatchCount = MAX(Batch) FROM #BatchesExecution

			PRINT CAST(@BatchCount AS VARCHAR(25)) + ' [Batches insert/update]' 
 
			--) Running batches 
			--------------------------------------------------------------------------------------------------------------------
	 
			WHILE EXISTS (SELECT 1 FROM #BatchesExecution WHERE [ctrl] = 0)
			BEGIN

				SET @StepsStartTime = GETUTCDATE()
				SET @Updated = 0
				SET @Deleted = 0
				SET @Inserted = 0

				SELECT @Batch = MIN(Batch) FROM #BatchesExecution WHERE [ctrl] = 0
			
				IF @DisplayResult = 1 PRINT '-> Batch: ' + CAST(@Batch AS VARCHAR(25))
				
				IF @IsDevQA = 0
				BEGIN
				
					BEGIN TRAN

						-- Total rows per batch
						SET @TotalRows = ( SELECT  COUNT(1) FROM  #Batches WHERE Batch = @Batch )			
						IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [Batch Count]'

						DROP TABLE IF EXISTS #SourceSKUPurchased

						SELECT
							PK_SKUPurchased,
							CreatedDate,
							CreatedBy,
							ModifiedDate,
							ModifiedBy,
							PK_Event,
							PK_EventSKU,
							SKUCode,
							PK_Distributor_EDW,
							DistributorID,
							OrderDate,
							NTSDate,
							OrderNumber,
							OrderType,
							Quantity,
							IsManual
						INTO #SourceSKUPurchased
						FROM #SKUPurchasedBW AS O
						INNER JOIN #Batches AS b 
							ON O.[PK] = b.[PK] 
						WHERE b.Batch = @Batch 
					
						CREATE INDEX IX_#SourceSKUPurchased_PK_Event ON #SourceSKUPurchased(PK_Event)
						CREATE INDEX IX_#SourceSKUPurchased_PK_Distributor_EDW ON #SourceSKUPurchased(PK_Distributor_EDW)
						CREATE INDEX IX_#SourceSKUPurchased_PK_EventSKU ON #SourceSKUPurchased(PK_EventSKU)
						CREATE INDEX IX_#SourceSKUPurchased_SKUCode ON #SourceSKUPurchased(SKUCode)

						--UPDATE				 
						UPDATE M
						SET
							 M.DistributorID = T.DistributorID
							,M.SKUCode = T.SKUCode
							,M.OrderDate = T.OrderDate
							,M.NTSDate = T.NTSDate
							,M.OrderNumber = T.OrderNumber
							,M.OrderType = T.OrderType
							,M.Quantity = T.Quantity
							,M.IsManual = T.IsManual
							,M.ModifiedDate = @TimeStamp
							,M.ModifiedBy = @StoredProcedure
						FROM dbo.SKUPurchased_BizWorks AS M
						INNER JOIN #SourceSKUPurchased AS T
						ON M.PK_Event = T.PK_Event AND M.PK_Distributor_EDW = T.PK_Distributor_EDW AND M.PK_EventSKU = T.PK_EventSKU AND M.DistributorID <> T.DistributorID 
						WHERE (M.OrderNumber <> T.OrderNumber OR M.OrderDate <> T.OrderDate OR M.Quantity <> T.Quantity OR 
						M.IsManual <> T.IsManual OR M.NTSDate <> T.NTSDate OR M.OrderType <> T.OrderType OR M.SKUCode <> T.SKUCode)
				 
						SET @Updated = (SELECT ROWCOUNT_BIG())
						IF @Updated > 0 PRINT CAST(@Updated AS VARCHAR(25)) + ' [Update RowCount]'

						--INSERT
						INSERT dbo.SKUPurchased_BizWorks(PK_SKUPurchased,
							CreatedDate,
							CreatedBy,
							ModifiedDate,
							ModifiedBy,
							PK_Event,
							PK_EventSKU,
							SKUCode,
							PK_Distributor_EDW,
							DistributorID,
							OrderDate,
							NTSDate,
							OrderNumber,
							OrderType,
							Quantity,
							IsManual		
							)
					SELECT  M.PK_SKUPurchased,
							M.CreatedDate,
							M.CreatedBy,
							M.ModifiedDate,
							M.ModifiedBy,
							M.PK_Event,
							M.PK_EventSKU,
							M.SKUCode,
							M.PK_Distributor_EDW,
							M.DistributorID,
							M.OrderDate,
							M.NTSDate,
							M.OrderNumber,
							M.OrderType,
							M.Quantity,
							M.IsManual
					 FROM #SourceSKUPurchased AS M
						WHERE NOT EXISTS (SELECT 1 FROM dbo.[SKUPurchased_BizWorks] AS T WITH (NOLOCK) 
							WHERE M.PK_SKUPurchased = T.PK_SKUPurchased)
						
						SET @Inserted = (SELECT ROWCOUNT_BIG())
						IF @Inserted > 0 PRINT CAST(@Inserted AS VARCHAR(25)) + ' [Insert RowCount]' 
				
						--DELETE 
							SELECT @RowsDelete = COUNT(*) FROM dbo.[SKUPurchased_BizWorks] AS T WITH (NOLOCK) WHERE NOT EXISTS (SELECT 1 FROM #SKUPurchasedBW AS M WHERE  M.PK_SKUPurchased = T.PK_SKUPurchased)
						
							IF (@RowsDelete > 0 )
							BEGIN

								SELECT @BatchDelete = (@RowsDelete / @BatchSize) + 1;

								PRINT CAST(@BatchDelete AS VARCHAR(25)) + ' [Batches delete]' 

								WHILE @BatchDelete > 0
								BEGIN
									SET @DeletedBatch = 0;

									DELETE TOP(@BatchSize) T FROM dbo.[SKUPurchased_BizWorks] AS T WHERE NOT EXISTS (SELECT 1 FROM #SKUPurchasedBW AS M WHERE  M.PK_SKUPurchased = T.PK_SKUPurchased)
							
									SET @DeletedBatch = (SELECT ROWCOUNT_BIG())
									SET @Deleted = @Deleted + @DeletedBatch
							
									IF @DeletedBatch > 0 PRINT CAST(@DeletedBatch AS VARCHAR(25)) + ' [Delete RowCount] - [Batch] - ' + CAST(@BatchDelete AS VARCHAR(25))
									SELECT @BatchDelete = @BatchDelete - 1;

								END;  
							END

					IF @KeepChanges = 1
					BEGIN
						COMMIT TRAN
						CHECKPOINT
						SET @TranStatus = 'Succeeded';
					END
					ELSE
					BEGIN
						IF @@TRANCOUNT > 0
							ROLLBACK TRAN 
						SET @TranStatus = 'Forced to rollback';
					END

				END -- @IsDevQA

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				--Creating results records for analysis		 
				INSERT INTO #Results(TableName,Batch,TotalRows,INSERTED,UPDATED,DELETED,[Status],[RunTime])
				VALUES(@TableName,@Batch,@TotalRows,@Inserted,@Updated,@Deleted,@TranStatus,@RunTime)

				UPDATE #BatchesExecution
				SET [ctrl] = 1
				WHERE [Batch] = @Batch
		
			END; --End while batches execution

			-- Ending batches
			--------------------------------------------------------------------------------------------------------------------
		
			PRINT '<- Ending batches '
		
			IF @DisplayResult = 1 SELECT [TableName], Batch,TotalRows,INSERTED,UPDATED,DELETED FROM #Results ORDER BY Batch ASC


			PRINT '------------------ End: ' + @TableName  
		END
		--------------------------------------------------------------------------------------------------------------------
		--/////////////////////////////////////// EVENTTICKETASSIGMENT TABLE
		--------------------------------------------------------------------------------------------------------------------
		IF @ExecutionType IN (1,2)
		BEGIN

			SET @TableName = 'EventTicketAssignment'
			SET @BatchCount = 0

			PRINT '------------------ Start: '+ @TableName  
			SET @TranStatus = 'Processing'

			--------------------------------------------------------------------------------------------------------------------
			--) Getting records 
			--------------------------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #EventTABW

			CREATE TABLE #EventTABW (
			PK int IDENTITY(1,1) PRIMARY KEY,
			[PK_EventTicketAssignment] [int] NOT NULL,
			[PK_FromDistributor_EDW] [int] NOT NULL,
			[PK_ToDistributor_EDW] [int] NOT NULL,
			[FromDistributorID] [varchar](20) NOT NULL,
			[ToDistributorID] [varchar](20) NOT NULL,
			[CreatedDate] [datetime] NULL,
			[CreatedBy] [varchar](50) NULL,
			[ModifiedDate] [datetime] NULL,
			[ModifiedBy] [varchar](50) NULL,
			[Ticketed] [int] NOT NULL,
			[ValidFromDate] [datetime] NULL,
			[ValidToDate] [datetime] NULL,
			[PK_Event] [int] NULL,
			[PK_EventSKU] [int] NULL,
			[SKUCode] [varchar](10) NULL,
			[PK_SKUPurchased] [int] NULL
		)

		INSERT INTO #EventTABW(
				PK_EventTicketAssignment ,
				PK_FromDistributor_EDW ,
				PK_ToDistributor_EDW ,
				FromDistributorID  ,
				ToDistributorID  ,
				CreatedDate  ,
				CreatedBy  ,
				ModifiedDate  ,
				ModifiedBy  ,
				Ticketed ,
				ValidFromDate  ,
				ValidToDate  ,
				PK_Event ,
				PK_EventSKU ,
				SKUCode  ,
				PK_SKUPurchased
			)
			SELECT
				ETA.PK_EventTicketAssignment ,
				ETA.PK_FromDistributor ,
				ETA.PK_ToDistributor ,
				FD.sDistributorID  ,
				TD.sDistributorID  ,
				ETA.CreatedDateUTC  ,
				ETA.CreatedBy  ,
				ETA.ModifiedDateUTC  ,
				ETA.ModifiedBy  ,
				ETA.Ticketed ,
				ETA.ValidFromDateUTC  ,
				ETA.ValidToDateUTC  ,
				E.PK_Event ,
				ETA.PK_EventSKU ,
				ES.SKUCode  ,
				ETA.PK_SKUPurchased
			FROM 
				#EventBW E 
			INNER JOIN
				dbo.EventTicketAssignment ETA WITH (NOLOCK) 
			ON
				E.PK_Event = ETA.PK_Event 
			INNER JOIN
				dbo.EventSKU ES WITH (NOLOCK) 
			ON
				ETA.PK_EventSKU = ES.PK_EventSKU 
			INNER JOIN
				dbo.v_Distributor FD 
			ON
				ETA.PK_FromDistributor = FD.nDistributorID 
			INNER JOIN
				dbo.v_Distributor TD 
			ON
				ETA.PK_ToDistributor = TD.nDistributorID 

			SET @Error = @Error + @@ERROR

			CREATE INDEX IX_#EventTABW_PK_FromDistributor_EDW ON #EventTABW(PK_FromDistributor_EDW)
			CREATE INDEX IX_#EventTABW_PK_ToDistributor_EDW ON #EventTABW(PK_ToDistributor_EDW)
			CREATE INDEX IX_#EventTABW_PK_Event ON #EventTABW(PK_Event)
			CREATE INDEX IX_#EventTABW_PK_EventSKU ON #EventTABW(PK_EventSKU)
			CREATE INDEX IX_#EventTABW_ValidToDate ON #EventTABW(ValidToDate)
			CREATE INDEX IX_#EventTABW_ValidFromDate ON #EventTABW(ValidFromDate)

			--Total rows
			SELECT @TotalRows = COUNT(1) FROM #EventTABW
			IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [TotalRows EventTicketAssignment]'

			--Cleaning up batches table
			DROP INDEX IF EXISTS IX_#Batches_PK ON #Batches;
			TRUNCATE TABLE #Batches;
		
			;WITH cte_records_sequence AS
			(
				SELECT 
					[PK]
					,[Sequence] = DENSE_RANK() OVER (ORDER BY [PK])
				FROM #EventTABW 
			), cte_records_batches AS
			(
				SELECT 
					[PK]
					,Batch = ([Sequence] - 1) / @BatchSize + 1
				FROM cte_records_sequence 
			)

			INSERT INTO #Batches(PK,Batch)
			SELECT [PK],Batch FROM cte_records_batches

			CREATE INDEX IX_#Batches_PK ON #Batches([PK]) INCLUDE([Batch]);

			INSERT INTO #BatchesExecution([Batch])
			SELECT DISTINCT Batch 
			FROM #Batches 
		
			SELECT @BatchCount = MAX(Batch) FROM #BatchesExecution

			PRINT CAST(@BatchCount AS VARCHAR(25)) + ' [Batches insert/update]' 
 
			--) Running batches 
			--------------------------------------------------------------------------------------------------------------------
	 
			WHILE EXISTS (SELECT 1 FROM #BatchesExecution WHERE [ctrl] = 0)
			BEGIN

				SET @StepsStartTime = GETUTCDATE()
				SET @Updated = 0
				SET @Deleted = 0
				SET @Inserted = 0

				SELECT @Batch = MIN(Batch) FROM #BatchesExecution WHERE [ctrl] = 0
			
				IF @DisplayResult = 1 PRINT '-> Batch: ' + CAST(@Batch AS VARCHAR(25))
				
				IF @IsDevQA = 0
				BEGIN
				
					BEGIN TRAN

						-- Total rows per batch
						SET @TotalRows = ( SELECT  COUNT(1) FROM  #Batches WHERE Batch = @Batch )			
						IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [Batch Count]'

						DROP TABLE IF EXISTS #SourceEventTABW

						SELECT
							PK_EventTicketAssignment,
							PK_FromDistributor_EDW,
							PK_ToDistributor_EDW,
							FromDistributorID ,
							ToDistributorID ,
							CreatedDate,
							CreatedBy,
							ModifiedDate,
							ModifiedBy,
							Ticketed,
							ValidFromDate,
							ValidToDate,
							PK_Event,
							PK_EventSKU,
							SKUCode,
							PK_SKUPurchased
						INTO #SourceEventTABW
						FROM #EventTABW AS O
						INNER JOIN #Batches AS b 
							ON O.[PK] = b.[PK] 
						WHERE b.Batch = @Batch 
					
						CREATE INDEX IX_#SourceEventTABW_PK_FromDistributor_EDW ON #SourceEventTABW(PK_FromDistributor_EDW)
						CREATE INDEX IX_#SourceEventTABW_PK_ToDistributor_EDW ON #SourceEventTABW(PK_ToDistributor_EDW)
						CREATE INDEX IX_#SourceEventTABW_PK_Event ON #SourceEventTABW(PK_Event)
						CREATE INDEX IX_#SourceEventTABW_PK_EventSKU ON #SourceEventTABW(PK_EventSKU)
						CREATE INDEX IX_#SourceEventTABW_ValidToDate ON #SourceEventTABW(ValidToDate)
						CREATE INDEX IX_#SourceEventTABW_ValidFromDate ON #SourceEventTABW(ValidFromDate)

						--UPDATE				 
						UPDATE M
						SET
							  M.PK_Event = T.PK_Event 
							  ,M.PK_EventSKU = T.PK_EventSKU
							  ,M.PK_SKUPurchased = T.PK_SKUPurchased
							  ,M.FromDistributorID = T.FromDistributorID
							  ,M.ToDistributorID = T.ToDistributorID
							  ,M.PK_FromDistributor_EDW = T.PK_FromDistributor_EDW
							  ,M.PK_ToDistributor_EDW = T.PK_ToDistributor_EDW
							  ,M.SKUCode = T.SKUCode
							  ,M.ValidFromDate = T.ValidFromDate
							  ,M.ValidToDate = T.ValidToDate
							  ,M.ModifiedDate = @TimeStamp
							  ,M.ModifiedBy = @StoredProcedure
						FROM dbo.EventTicketAssignment_BizWorks AS M
						INNER JOIN #SourceEventTABW AS T
						ON M.PK_EventTicketAssignment = T.PK_EventTicketAssignment
						WHERE (M.SKUCode <> T.SKUCode OR M.PK_Event <> T.PK_Event OR M.PK_EventSKU = T.PK_EventSKU OR M.PK_SKUPurchased <> T.PK_SKUPurchased 
						 OR M.PK_FromDistributor_EDW <> T.PK_FromDistributor_EDW  OR M.PK_ToDistributor_EDW <> T.PK_ToDistributor_EDW  
						 OR M.FromDistributorID <> T.FromDistributorID OR M.ToDistributorID <> T.ToDistributorID  
						 OR M.ValidFromDate <> T.ValidFromDate OR M.ValidToDate <> T.ValidToDate)
					 
						SET @Updated = (SELECT ROWCOUNT_BIG())
						IF @Updated > 0 PRINT CAST(@Updated AS VARCHAR(25)) + ' [Update RowCount]'

						--INSERT
						INSERT [dbo].[EventTicketAssignment_BizWorks] (PK_EventTicketAssignment,
							PK_FromDistributor_EDW,
							PK_ToDistributor_EDW,
							FromDistributorID ,
							ToDistributorID ,
							CreatedDate,
							CreatedBy,
							ModifiedDate,
							ModifiedBy,
							Ticketed,
							ValidFromDate,
							ValidToDate,
							PK_Event,
							PK_EventSKU,
							SKUCode,
							PK_SKUPurchased			
							)
						SELECT M.PK_EventTicketAssignment,
								M.PK_FromDistributor_EDW,
								M.PK_ToDistributor_EDW,
								M.FromDistributorID,
								M.ToDistributorID,
								M.CreatedDate,
								M.CreatedBy,
								M.ModifiedDate,
								M.ModifiedBy,
								M.Ticketed,
								M.ValidFromDate,
								M.ValidToDate,
								M.PK_Event,
								M.PK_EventSKU,
								M.SKUCode,
								M.PK_SKUPurchased
					 FROM #SourceEventTABW AS M
						WHERE NOT EXISTS (SELECT 1 FROM dbo.[EventTicketAssignment_BizWorks] AS T WITH (NOLOCK) 
							WHERE M.PK_EventTicketAssignment = T.PK_EventTicketAssignment)
						
						SET @Inserted = (SELECT ROWCOUNT_BIG())
						IF @Inserted > 0 PRINT CAST(@Inserted AS VARCHAR(25)) + ' [Insert RowCount]' 
				
						--DELETE 

						SELECT @RowsDelete = COUNT(*) FROM dbo.[EventTicketAssignment_BizWorks] AS T WITH (NOLOCK) WHERE NOT EXISTS (SELECT 1 FROM #EventTABW AS M  WHERE M.PK_EventTicketAssignment = T.PK_EventTicketAssignment)

						IF (@RowsDelete > 0 )
						BEGIN

							SELECT @BatchDelete = (@RowsDelete / @BatchSize) + 1;

							PRINT CAST(@BatchDelete AS VARCHAR(25)) + ' [Batches delete]' 

							WHILE @BatchDelete > 0
							BEGIN
								SET @DeletedBatch = 0;

								DELETE TOP(@BatchSize) T FROM dbo.[EventTicketAssignment_BizWorks] AS T WHERE NOT EXISTS (SELECT 1 FROM #EventTABW AS M  WHERE M.PK_EventTicketAssignment = T.PK_EventTicketAssignment)
							
								SET @DeletedBatch = (SELECT ROWCOUNT_BIG())
								SET @Deleted = @Deleted + @DeletedBatch
							
								IF @DeletedBatch > 0 PRINT CAST(@DeletedBatch AS VARCHAR(25)) + ' [Delete RowCount] - [Batch] - ' + CAST(@BatchDelete AS VARCHAR(25))
								SELECT @BatchDelete = @BatchDelete - 1;

							END; 
						 END

					IF @KeepChanges = 1
					BEGIN
						COMMIT TRAN
						CHECKPOINT
						SET @TranStatus = 'Succeeded';
					END
					ELSE
					BEGIN
						IF @@TRANCOUNT > 0
							ROLLBACK TRAN 
						SET @TranStatus = 'Forced to rollback';
					END

				END -- @IsDevQA

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				--Creating results records for analysis		 
				INSERT INTO #Results(TableName,Batch,TotalRows,INSERTED,UPDATED,DELETED,[Status],[RunTime])
				VALUES(@TableName,@Batch,@TotalRows,@Inserted,@Updated,@Deleted,@TranStatus,@RunTime)

				UPDATE #BatchesExecution
				SET [ctrl] = 1
				WHERE [Batch] = @Batch
		
			END; --End while batches execution

			-- Ending batches
			--------------------------------------------------------------------------------------------------------------------
		
			PRINT '<- Ending batches '
		
			IF @DisplayResult = 1 SELECT [TableName], Batch,TotalRows,INSERTED,UPDATED,DELETED FROM #Results ORDER BY Batch ASC


			PRINT '------------------ End: ' + @TableName  
		
		END
		--------------------------------------------------------------------------------------------------------------------
		--/////////////////////////////////////// EVENTSREGISTRATION TABLE
		--------------------------------------------------------------------------------------------------------------------
		IF @ExecutionType = 1
		BEGIN

			SET @TableName = 'EventsRegistration'
			SET @BatchCount = 0

			PRINT '------------------ Start: '+ @TableName  
			SET @TranStatus = 'Processing'

			--------------------------------------------------------------------------------------------------------------------
			--) Getting records 
			--------------------------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #EventsReg

			CREATE TABLE #EventsReg (
				PK int IDENTITY(1,1) PRIMARY KEY,
				PK_EventsRegistration int not null, 
				PK_Distributor_EDW int not null, 
				PK_Distributor int, 
				DistributorID varchar(20), 
				FirstName	nvarchar(40), 
				LastName	nvarchar(40), 
				Phones			varchar(100), 
				EmailAddress	varchar(100), 
				IsPrimaryGuest	bit, 
				HasCheckedIn	bit, 
				CreatedDateUTC	datetime, 
				IsDistributor	bit, 
				CreatedBy		varchar(50), 
				UnRegister		bit, 
				ModifiedDateUTC	datetime, 
				IsPreRegistered	bit, 
				ModifiedBy		varchar(50), 
				DistributorTeam	varchar(10), 
				PK_EventTicket	int, 
				PK_Event		int, 
				Registered		int, 
				DSPreferredname	nvarchar(1000)
			)

			INSERT INTO #EventsReg(
				PK_EventsRegistration, 
				PK_Distributor_EDW, 
				DistributorID, 
				FirstName, 
				LastName, 
				Phones, 
				EmailAddress, 
				IsPrimaryGuest, 
				HasCheckedIn, 
				CreatedDateUTC, 
				IsDistributor, 
				CreatedBy, 
				UnRegister, 
				ModifiedDateUTC, 
				IsPreRegistered, 
				ModifiedBy, 
				DistributorTeam, 
				PK_EventTicket, 
				PK_Event, 
				Registered, 
				DSPreferredname	
			)
			SELECT
				ER.PK_EventsRegistration, 
				ER.PK_Distributor, 
				ER.DistributorID, 
				ER.FirstName, 
				ER.LastName, 
				ER.Phones, 
				ER.EmailAddress, 
				ER.IsPrimaryGuest, 
				ER.HasCheckedIn, 
				ER.CreatedDateUTC, 
				ER.IsDistributor, 
				ER.CreatedBy, 
				ER.UnRegister, 
				ER.ModifiedDateUTC, 
				ER.IsPreRegistered, 
				ER.ModifiedBy, 
				ER.DistributorTeam, 
				ER.PK_EventTicket, 
				ER.PK_Event, 
				ER.Registered, 
				ER.DSPreferredname	
			FROM 
				#EventBW E 
			INNER JOIN
				dbo.EventsRegistration ER WITH (NOLOCK) 
			ON
				E.PK_Event = ER.PK_Event 


			SET @Error = @Error + @@ERROR

			CREATE INDEX IX_#EventsReg_PK_EventsRegistration ON #EventsReg(PK_EventsRegistration)
			CREATE INDEX IX_#EventsReg_PK_Distributor_EDW ON #EventsReg(PK_Distributor_EDW)
			CREATE INDEX IX_#EventsReg_PK_Event ON #EventsReg(PK_Event)
			CREATE INDEX IX_#EventsReg_PK_EventTicket ON #EventsReg(PK_EventTicket)
			CREATE INDEX IX_#EventsReg_DistribuorID ON #EventsReg(DistributorID)
			CREATE INDEX IX_#EventsReg_ModifiedDateUTC ON #EventsReg(ModifiedDateUTC)

			--Total rows
			SELECT @TotalRows = COUNT(1) FROM #EventsReg
			IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [TotalRows EventsRegistration]'

			--Cleaning up batches table
			DROP INDEX IF EXISTS IX_#Batches_PK ON #Batches;
			TRUNCATE TABLE #Batches;
		
			;WITH cte_records_sequence AS
			(
				SELECT 
					[PK]
					,[Sequence] = DENSE_RANK() OVER (ORDER BY [PK])
				FROM #EventsReg 
			), cte_records_batches AS
			(
				SELECT 
					[PK]
					,Batch = ([Sequence] - 1) / @BatchSize + 1
				FROM cte_records_sequence 
			)

			INSERT INTO #Batches(PK,Batch)
			SELECT [PK],Batch FROM cte_records_batches

			CREATE INDEX IX_#Batches_PK ON #Batches([PK]) INCLUDE([Batch]);

			INSERT INTO #BatchesExecution([Batch])
			SELECT DISTINCT Batch 
			FROM #Batches 
		
			SELECT @BatchCount = MAX(Batch) FROM #BatchesExecution

			PRINT CAST(@BatchCount AS VARCHAR(25)) + ' [Batches insert/update]' 
 
			--) Running batches 
			--------------------------------------------------------------------------------------------------------------------
	 
			WHILE EXISTS (SELECT 1 FROM #BatchesExecution WHERE [ctrl] = 0)
			BEGIN

				SET @StepsStartTime = GETUTCDATE()
				SET @Updated = 0
				SET @Deleted = 0
				SET @Inserted = 0

				SELECT @Batch = MIN(Batch) FROM #BatchesExecution WHERE [ctrl] = 0
			
				IF @DisplayResult = 1 PRINT '-> Batch: ' + CAST(@Batch AS VARCHAR(25))
				
				IF @IsDevQA = 0
				BEGIN
				
					BEGIN TRAN

						-- Total rows per batch
						SET @TotalRows = ( SELECT  COUNT(1) FROM  #Batches WHERE Batch = @Batch )			
						IF @DisplayResult = 1 PRINT CAST(@TotalRows AS VARCHAR(25)) + ' [Batch Count]'

						DROP TABLE IF EXISTS #SourceEventsRegistration

						SELECT
							PK_EventsRegistration, 
							PK_Distributor_EDW, 
							DistributorID, 
							FirstName, 
							LastName, 
							Phones, 
							EmailAddress, 
							IsPrimaryGuest, 
							HasCheckedIn, 
							CreatedDateUTC, 
							IsDistributor, 
							CreatedBy, 
							UnRegister, 
							ModifiedDateUTC, 
							IsPreRegistered, 
							ModifiedBy, 
							DistributorTeam, 
							PK_EventTicket, 
							PK_Event, 
							Registered, 
							DSPreferredname	
						INTO #SourceEventsRegistration
						FROM #EventsReg AS O
						INNER JOIN #Batches AS b 
							ON O.[PK] = b.[PK] 
						WHERE b.Batch = @Batch 
					
						CREATE INDEX IX_#SourceEventsRegistration_PK_EventsRegistration ON #SourceEventsRegistration(PK_EventsRegistration)
						CREATE INDEX IX_#SourceEventsRegistration_PK_Distributor_EDW ON #SourceEventsRegistration(PK_Distributor_EDW)
						CREATE INDEX IX_#SourceEventsRegistration_PK_Event ON #SourceEventsRegistration(PK_Event)
						CREATE INDEX IX_#SourceEventsRegistration_PK_EventTicket ON #SourceEventsRegistration(PK_EventTicket)
						CREATE INDEX IX_#SourceEventsRegistration_DistribuorID ON #SourceEventsRegistration(DistributorID)
						CREATE INDEX IX_#SourceEventsRegistration_ModifiedDateUTC ON #SourceEventsRegistration(ModifiedDateUTC)

						--UPDATE				 
						UPDATE M
						SET
							 M.PK_Distributor_EDW = T.PK_Distributor_EDW
							,M.PK_Distributor = CASE WHEN M.DistributorID = T.DistributorID THEN M.PK_Distributor_EDW ELSE 0 END
							,M.DistributorID = T.DistributorID
							,M.FirstName = T.FirstName
							,M.LastName = T.LastName
							,M.Phones = T.Phones
							,M.EmailAddress = T.EmailAddress
							,M.IsPrimaryGuest = T.IsPrimaryGuest
							,M.HasCheckedIn = T.HasCheckedIn
							,M.IsDistributor = T.IsDistributor
							,M.UnRegister = T.UnRegister
							,M.IsPreRegistered = T.IsPreRegistered
							,M.Registered = T.Registered
							,M.DistributorTeam = T.DistributorTeam
							,M.PK_Event = T.PK_Event
							,M.PK_EventTicket = T.PK_EventTicket
							,M.DSPreferredname = T.DSPreferredname
							,M.ModifiedBy = T.ModifiedBy		
						FROM [dbo].[EventsRegistration_BizWorks] AS M
						INNER JOIN #SourceEventsRegistration AS T
						ON M.PK_EventsRegistration = T.PK_EventsRegistration
						WHERE (M.ModifiedDateUTC <> T.ModifiedDateUTC)
					 
						SET @Updated = (SELECT ROWCOUNT_BIG())
						IF @Updated > 0 PRINT CAST(@Updated AS VARCHAR(25)) + ' [Update RowCount]'

						--INSERT
						INSERT [dbo].[EventsRegistration_BizWorks] (PK_EventsRegistration, 
							PK_Distributor_EDW, 
							DistributorID, 
							FirstName, 
							LastName, 
							Phones, 
							EmailAddress, 
							IsPrimaryGuest, 
							HasCheckedIn, 
							CreatedDateUTC, 
							IsDistributor, 
							CreatedBy, 
							UnRegister, 
							ModifiedDateUTC, 
							IsPreRegistered, 
							ModifiedBy, 
							DistributorTeam, 
							PK_EventTicket, 
							PK_Event, 
							Registered, 
							DSPreferredname				
							)
						SELECT PK_EventsRegistration, 
							PK_Distributor_EDW, 
							DistributorID, 
							FirstName, 
							LastName, 
							Phones, 
							EmailAddress, 
							IsPrimaryGuest, 
							HasCheckedIn, 
							CreatedDateUTC, 
							IsDistributor, 
							CreatedBy, 
							UnRegister, 
							ModifiedDateUTC, 
							IsPreRegistered, 
							ModifiedBy, 
							DistributorTeam, 
							PK_EventTicket, 
							PK_Event, 
							Registered, 
							DSPreferredname	
					 FROM #SourceEventsRegistration AS M
						WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EventsRegistration_BizWorks] AS T WITH (NOLOCK) 
							WHERE M.PK_EventsRegistration = T.PK_EventsRegistration)
						
						SET @Inserted = (SELECT ROWCOUNT_BIG())
						IF @Inserted > 0 PRINT CAST(@Inserted AS VARCHAR(25)) + ' [Insert RowCount]' 
				
					
						 --DELETE 

						SELECT @RowsDelete = COUNT(*) FROM dbo.[EventsRegistration_BizWorks] AS T WITH (NOLOCK) WHERE NOT EXISTS (SELECT 1 FROM #EventsReg AS M WHERE  M.PK_EventsRegistration = T.PK_EventsRegistration)

						IF (@RowsDelete > 0 )
						BEGIN

							SELECT @BatchDelete = (@RowsDelete / @BatchSize) + 1;

							PRINT CAST(@BatchDelete AS VARCHAR(25)) + ' [Batches delete]' 

							WHILE @BatchDelete > 0
							BEGIN
								SET @DeletedBatch = 0;

									DELETE TOP(@BatchSize) T FROM dbo.[EventsRegistration_BizWorks] AS T WHERE NOT EXISTS (SELECT 1 FROM #EventsReg AS M WHERE  M.PK_EventsRegistration = T.PK_EventsRegistration)
							
									SET @DeletedBatch = (SELECT ROWCOUNT_BIG())
									SET @Deleted = @Deleted + @DeletedBatch
							
									IF @DeletedBatch > 0 PRINT CAST(@DeletedBatch AS VARCHAR(25)) + ' [Delete RowCount] - [Batch] - ' + CAST(@BatchDelete AS VARCHAR(25))
									SELECT @BatchDelete = @BatchDelete - 1;

							END;  
						END

					IF @KeepChanges = 1
					BEGIN
						COMMIT TRAN
						CHECKPOINT
						SET @TranStatus = 'Succeeded';
					END
					ELSE
					BEGIN
						IF @@TRANCOUNT > 0
							ROLLBACK TRAN 
						SET @TranStatus = 'Forced to rollback';
					END

				END -- @IsDevQA

				SET @EndTime = GETUTCDATE()
				SET @InitSeconds = DATEDIFF(SECOND,@StepsStartTime,@EndTime)
				SET @h = (@InitSeconds/3600)
				SET @m = (@InitSeconds-floor(@h*3600))/60
				SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

				SELECT @RunTime = RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
				RIGHT('0'+CONVERT(varchar,@s),2)		

				--Creating results records for analysis		 
				INSERT INTO #Results(TableName,Batch,TotalRows,INSERTED,UPDATED,DELETED,[Status],[RunTime])
				VALUES(@TableName,@Batch,@TotalRows,@Inserted,@Updated,@Deleted,@TranStatus,@RunTime)
			
				UPDATE #BatchesExecution
				SET [ctrl] = 1
				WHERE [Batch] = @Batch
		
			END; --End while batches execution

			-- Ending batches
			--------------------------------------------------------------------------------------------------------------------
		
			PRINT '<- Ending batches '
		
			IF @DisplayResult = 1 SELECT [TableName], Batch,TotalRows,INSERTED,UPDATED,DELETED FROM #Results ORDER BY Batch ASC


			PRINT '------------------ End: ' + @TableName
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

		IF @@TRANCOUNT > 0 AND @IsDevQA = 0
		BEGIN
			ROLLBACK TRAN 	
			SET @TranStatus = 'Failed';

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage

		END 
		
	END CATCH;

	BEGIN TRY
	IF @LogResult = 1 AND @IsDevQA = 0  
	BEGIN

		IF OBJECT_ID (N'[Shared].[BizworksSyncResults]', N'U') IS  NULL 
		BEGIN
			CREATE TABLE [Shared].[BizworksSyncResults](
				[CreatedDateUTC] [datetime]	NULL DEFAULT (getutcdate()), TableName VARCHAR(100),[BatchSize] INT, Batch INT,TotalRows BIGINT,INSERTED BIGINT, UPDATED BIGINT, DELETED BIGINT, [RunTime] VARCHAR(10),[Status] VARCHAR(250)
			)
		END

		INSERT INTO [Shared].[BizworksSyncResults](
			[TableName], 
			[BatchSize], 
			[Batch],
			[TotalRows],		 
			[Inserted],
			[Updated],
			[Deleted],
			[RunTime],
			[Status]
			)
			SELECT TableName,@BatchSize,Batch,TotalRows,INSERTED,UPDATED,DELETED,[RunTime],[Status] FROM #Results
			WHERE INSERTED > 0 OR UPDATED > 0 OR DELETED > 0

		-- Update processing Log
		SET @StoredProcedureParameters = 'SyncResults'
		
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
		IF @IsDevQA = 0   
		 BEGIN
		 EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		END

	END CATCH;
END;