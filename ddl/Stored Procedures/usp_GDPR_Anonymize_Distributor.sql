CREATE PROCEDURE [dbo].[usp_GDPR_Anonymize_Distributor]

	-- Mandatory Parameters
	  @DSRRequestId VARCHAR(20) = ''
	 ,@DistributorId  NVARCHAR(30) = ''
	 ,@Email NVARCHAR(250) = ''
	 ,@SnowRequest VARCHAR(20) = ''
	
		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN

-- =======================================================================================
-- Author		Jair Lira Garcia
-- Create date  Oct2021
-- Description	Distributor data anonymization
-- Parameters :  @Error  OUT Error number
--               @ErrorMessage OUT Error message
--              QA/DEV
--       	     @IsDevQA SMALLINT = 0 
--------------------------------------------------------------------
--    VERSIONS
--------------------------------------------------------------------
--    1.0.0       2022-02-28     Jair Lira        Initial. 
--    1.1.0       2022-04-27     Jair Lira        Distributor Event Rules
--    1.2.0       2022-05-03     Jair Lira        Avoid blocking tables, simultaneous execution(Parallelism)
--    1.3.0       2022-08-30     Jair Lira        Remove PubEvents data check
-- ========================================================================================
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StartTime DATETIME = GETUTCDATE()
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
DECLARE @PK_Distributor INT = NULL,@RetrievalProcess BIT = 1,  @RetrievalCount INT = 0
DECLARE @GDPRMasking INT = 0
DECLARE @DatabaseName NVARCHAR(100), @SchemaName NVARCHAR(100), @TableName NVARCHAR(100), @ConditionId NVARCHAR(400), @Id Int
DECLARE @DistributorEvent NVARCHAR(MAX) = NULL

BEGIN TRY

	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END
	

/******************************************************************************
	Check GDPR Masking
******************************************************************************/
	SELECT @GDPRMasking = COUNT(1)
	FROM [dbo].[GDPRDistributors] WITH (NOLOCK) 
	WHERE StatusCode = 1 and DistributorId = @DistributorId  

	IF @GDPRMasking >= 1 
	BEGIN
		SELECT  1 as StatusCode,
			'GDPR Data already masked for ' + @Email as Message,
			NULL as Data,
			(SELECT TOP 1 DistributorEvent FROM [dbo].[GDPRDistributors] WITH (NOLOCK) WHERE StatusCode = 1 and DistributorId = @DistributorId  ) as DistributorEvent
		RETURN
	END


/******************************************************************************
	SET @RetrievalCount
******************************************************************************/
	IF EXISTS (SELECT TOP 1 StatusCode FROM [dbo].[GDPRDistributors] WITH (NOLOCK) WHERE  StatusCode = 0 and DistributorId = @DistributorId)
	BEGIN
		SELECT  @RetrievalCount = ISNULL(MAX(RetrievalCount) + 1,0) 
		FROM [dbo].[GDPRDistributors] WITH (NOLOCK)
		WHERE DistributorId = @DistributorId
		and CreatedDateUTC > (SELECT  MAX(CreatedDateUTC) FROM [dbo].[GDPRDistributors] WITH (NOLOCK) WHERE StatusCode = 0  and DistributorId = @DistributorId)
	END
	ELSE
	BEGIN
		SELECT  @RetrievalCount = ISNULL(MAX(RetrievalCount) + 1,0) 
		FROM [dbo].[GDPRDistributors] WITH (NOLOCK)
		 WHERE DistributorId = @DistributorId;
	END


/******************************************************************************
	Get Pk_Distributor
******************************************************************************/
	SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WITH (NOLOCK) WHERE sDistributorID = @DistributorId

	IF @PK_Distributor IS NULL 
	BEGIN
		SET @RetrievalProcess = 0;
		SET @PK_Distributor = 0;
		THROW 60000, 'Warning: DistributorId was not found' , 1
	END   

/******************************************************************************
	Mask Distributor data on PubEventManagement PII Tables
******************************************************************************/

	BEGIN TRANSACTION

		DECLARE @SQL NVARCHAR(MAX);


		DECLARE Distributor_cursor CURSOR FAST_FORWARD FOR
		SELECT
			Id, DatabaseName, SchemaName, TableName, ConditionId
		FROM
			[dbo].[GDPRTables] WITH (NOLOCK)
		WHERE Removed = 0
		ORDER BY Id


		OPEN Distributor_cursor
		FETCH NEXT FROM Distributor_cursor INTO @Id, @DatabaseName,@SchemaName,@TableName, @ConditionId

		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @SQL =  'UPDATE ' +'[' +@DatabaseName+'].' + '[' +@SchemaName+'].' + '[' +@TableName+']' +' SET ' + STUFF((SELECT ', [' + GDC.ColumnName + '] = ' + '''' + GDE.Mask + '''' 
				FROM  [dbo].[GDPRColumns] GDC WITH (NOLOCK)
				INNER JOIN [dbo].[GDPRDataElements] GDE WITH (NOLOCK) ON GDC.GDPRColumnId = GDE.Id
				WHERE 
					GDPRTableId = @Id
				FOR XML PATH('')), 1,1, '')

				SET  @ConditionId = REPLACE(@ConditionId, '@Pk_Distributor', '''' +  CAST(@Pk_Distributor AS varchar)  + '''');
				SET  @ConditionId = REPLACE(@ConditionId, '@DistributorId', ''''+ @DistributorId + '''');

				SET @SQL = @SQL  + ' WHERE ' + @ConditionId;
				EXEC SP_EXECUTESQL @SQL;
		
				FETCH NEXT FROM Distributor_cursor INTO @Id, @DatabaseName,@SchemaName,@TableName, @ConditionId
			END
		CLOSE Distributor_cursor
		DEALLOCATE Distributor_cursor

/**************************************************************************************
	Call Independent Distributor Events - no active events from anonymized Distributors
***************************************************************************************/

		IF EXISTS (SELECT TOP 1 EventApprovalStatus FROM [dbo].[Event] WITH (NOLOCK) WHERE  CreatedDistributorID = @DistributorId AND PK_EventType = 3 AND dEndUTC >= GETUTCDATE())
		BEGIN
			UPDATE [dbo].[Event]
				SET EventApprovalStatus = 2,
					IsPublish = 0
			WHERE CreatedDistributorID = @DistributorId AND PK_EventType = 3 AND dEndUTC >= GETUTCDATE();

			UPDATE EL
				SET EventComments = 'Event rejected, Distributor request anonymization',
				ModifiedDateUTC = GETUTCDATE()
			FROM [dbo].EventLocaleDesc EL WITH (NOLOCK)
			INNER JOIN [dbo].[Event] E WITH (NOLOCK) ON EL.PK_Event = E.PK_Event 
					AND E.CreatedDistributorID = @DistributorId AND E.PK_EventType = 3 AND dEndUTC >= GETUTCDATE()
			WHERE EL.PK_EventType = 3;

		END

/**************************************************************************************
	Call Independent Distributor Events - no active events with anonymized coordinators
***************************************************************************************/


		IF EXISTS (SELECT TOP 1 CoordinatorId FROM [dbo].[EventCoordinatorDetail] ECD WITH (NOLOCK) WHERE  CoordinatorId = CAST(@PK_Distributor AS varchar) AND EXISTS(SELECT 1 FROM [dbo].[Event] E WITH (NOLOCK) WHERE ECD.PK_Event = E.PK_Event AND PK_EventType = 3 AND dEndUTC >= GETUTCDATE()))
		BEGIN

			IF OBJECT_ID('Tempdb..#EventCoordinator','U') IS NOT NULL DROP TABLE #EventCoordinator

			CREATE TABLE #EventCoordinator (
			CreatedDistributorId NVARCHAR(10), 
			CoordinatorId NVARCHAR(10),
			PK_Event INT,
			EventName NVARCHAR(200),
			CoorNum INT)

			;WITH 
			EventCoordinator(CreatedDistributorId, CoordinatorId, PK_Event )  AS
			(	
				SELECT E.CreatedDistributorId,
					   ECD.CoordinatorId,
					   E.PK_Event
				FROM [dbo].[EventCoordinatorDetail] ECD WITH (NOLOCK)
				INNER JOIN  [dbo].[Event] E WITH (NOLOCK) ON ECD.PK_Event = E.PK_Event AND E.PK_EventType = 3 AND E.dEndUTC >= GETUTCDATE()
				WHERE EXISTS(SELECT 1 FROM [dbo].[EventCoordinatorDetail] ECD2 WITH (NOLOCK) WHERE ECD2.CoordinatorId = CAST(@PK_Distributor AS varchar)  and ECD2.PK_Event = ECD.PK_Event)
				GROUP BY E.CreatedDistributorId,ECD.CoordinatorId,E.PK_Event)

			INSERT INTO #EventCoordinator(CreatedDistributorId, CoordinatorId, PK_Event, EventName, CoorNum)
			SELECT EC.CreatedDistributorId ,
				   (SELECT sdistributorId FROM V_Distributor V WITH (NOLOCK) WHERE ndistributorId = EC.CoordinatorId),
				   EC.PK_Event,
				   (SELECT EventName FROM [dbo].[Event] E WITH (NOLOCK) WHERE E.PK_Event = EC.PK_Event) EventName,
		           (SELECT COUNT(*) from EventCoordinator EC2 WITH (NOLOCK) WHERE EC2.PK_Event = EC.Pk_Event) CoorNum
			FROM EventCoordinator EC
			WHERE CoordinatorId = CAST(@PK_Distributor AS varchar)
 
			IF EXISTS (SELECT TOP 1 CreatedDistributorId FROM #EventCoordinator WITH (NOLOCK) WHERE CoorNum = 1 and CreatedDistributorId <> CoordinatorId)
			SET @DistributorEvent = (SELECT CreatedDistributorId as 'DistributorId',  PK_Event as 'PK_Event' ,EventName as 'EventName' 
									FROM #EventCoordinator WITH (NOLOCK) WHERE CoorNum = 1 and CreatedDistributorId <> CoordinatorId
									FOR JSON AUTO) 

		   ---Event with 2 or more coordinators
		   DELETE ECD
		   FROM [dbo].[EventCoordinatorDetail] ECD
		   INNER JOIN #EventCoordinator EC ON  ECD.PK_Event = EC.PK_Event
	       WHERE ECD.CoordinatorId = CAST(@PK_Distributor AS varchar)

	       ---Event with only 1 coordinator
		   UPDATE E
		   SET E.EventApprovalStatus = 3, ---Save as Draft
		   IsPublish = 0 
		   FROM [dbo].[Event] E
		   INNER JOIN #EventCoordinator EC ON EC.PK_Event = E.PK_Event AND E.PK_EventType = 3 AND E.dEndUTC >= GETUTCDATE()
		   WHERE EC.CoorNum = 1 and EC.CreatedDistributorId <> EC.CoordinatorId;		

		END

/******************************************************************************
	SELECT DATA
******************************************************************************/
		IF @@ERROR = 0 
		BEGIN

		  ---	INSERT DATA ON GDPRDistributors

		  INSERT INTO [dbo].[GDPRDistributors] ([DSRRequestId] ,[Pk_Distributor],[DistributorId],[SnowRequest] ,[Type],[StatusCode] , [RetrievalCount], [RetrievalProcess] , [SubscriptionName], [AnonymizedDistributor], [DistributorEvent])
	      VALUES(@DSRRequestId, @Pk_distributor, @DistributorId, @SnowRequest, 1, 1, @RetrievalCount, 1, 'sbs.eventsPromotions', 1, @DistributorEvent)

	
		  SELECT TOP 1
				0 as StatusCode,
				'Successfully data masked for ' + @Email as Message,
				NULL as Data,
				@DistributorEvent as DistributorEvent

	COMMIT TRANSACTION
	
END   

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
	
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	INSERT INTO [dbo].[GDPRDistributors] ([DSRRequestId] ,[Pk_Distributor],[DistributorId],[SnowRequest] ,[Type],[StatusCode] , [RetrievalCount], [RetrievalProcess] , [SubscriptionName], [ErrorMessage])
    VALUES(@DSRRequestId, @Pk_distributor, @DistributorId,  @SnowRequest, 1, 2, @RetrievalCount, @RetrievalProcess, 'sbs.eventsPromotions', @ErrorMessage)

	-- UPDATE ERROR LOG
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage  


	SELECT @DSRRequestId as DSRRequestId,
	       @DistributorId as DistributorId,
		   @Email as Email,
		   @SnowRequest  as SnowRequest,
           1 as Type,
		   @RetrievalCount as RetrievalCount,
		   @RetrievalProcess as RetrievalProcess,
		   'sbs.eventsPromotions' as SubscriptionName,
		   2 as StatusCode,
		   @ErrorMessage as ErrorMessage

	RAISERROR(@ErrorMessage,16,1) With NoWait


END CATCH
/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
