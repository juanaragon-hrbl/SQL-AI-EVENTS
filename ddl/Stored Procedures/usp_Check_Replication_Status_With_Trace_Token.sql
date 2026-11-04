CREATE PROCEDURE [dbo].[usp_Check_Replication_Status_With_Trace_Token] @publication SYSNAME
	-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = NULL OUTPUT
	-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN    
/*************************************************************************************************
OBJECT:		dbo.usp_Check_Replication_Status_With_Trace_Token
USE:		EXEC usp_Check_Replication_Status_With_Trace_Token   @publication = 'IAPRODIA_PubEventManagement_BIPRODRPT_EventManagement'   

DESCRIPTION:	Checks to see the replication is done
NOTES:			
DEPENDENCIES    
--------------------------------------------------------------------
VERSIONS
--------------------------------------------------------------------
	1.0.0        2011-05-13      Sandhya Pendyala          Initial
	1.1.0		 2019-10-11      puertac				   SRE Implementation
*************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/********************************** HOMGuests *****************************************/	
DECLARE @tokenID AS int;
DECLARE @suscriber_latency INT
--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
 

 	BEGIN TRY
			-- Insert a new tracer token in the publication database.
			EXEC sys.sp_posttracertoken 
			  @publication = @publication,
			  @tracer_token_id = @tokenID OUTPUT;
			SELECT 'The ID of the new tracer token is ''' + 
				  CONVERT(VARCHAR,@tokenID) + '''.'
 
 
			CREATE TABLE #subscriber_token (distributor_latency int, subscriber sysname,subscriber_db sysname ,subscriber_latency int , overall_latency int)

			INSERT INTO #subscriber_token
				EXEC sys.sp_helptracertokenhistory 
					 @publication = @publication, 
					 @tracer_id = @tokenID
			SELECT distributor_latency
				  ,subscriber
				  ,subscriber_db
				  ,subscriber_latency
				  ,overall_latency FROM #subscriber_token 
         
			WHILE  exists (SELECT distributor_latency
								 ,subscriber
								 ,subscriber_db
								 ,subscriber_latency
								 ,overall_latency  FROM #subscriber_token WHERE subscriber_latency IS NULL)
			BEGIN
			SELECT '1'
				--select getdate() from #subscriber_token
				WAITFOR DELAY '00:02:00'
    
				TRUNCATE TABLE #subscriber_token
    
				INSERT INTO #subscriber_token
				EXEC sys.sp_helptracertokenhistory 
					 @publication = @publication, 
					 @tracer_id = @tokenID;
			END
 
			DROP TABLE #subscriber_token
			EXEC sp_deletetracertokenhistory @publication, @tokenID 

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
