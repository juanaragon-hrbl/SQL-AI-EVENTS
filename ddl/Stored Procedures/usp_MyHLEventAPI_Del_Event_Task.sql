CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Del_Event_Task]
	-- Optional
	@Error int = 0 OUTPUT 
	,@ErrorMessage varchar(200) = '' OUTPUT 
	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Del_Event_Task

USE:		
			DECLARE @e int
					,@em varchar(200)
					,@IsDevQA int
EXEC usp_MyHLEventAPI_Del_Event_Task
				-- Error Parameters
				@Error = @e OUTPUT  
				,@ErrorMessage = @em OUTPUT 
				-- QA/DEV
				,@IsDevQA = 1				
			
SELECT @e , @em 


DESCRIPTION:	Deletes from Event Queue 

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.Event
ALL Child Tables

VERSIONS
--------------------------------------------------------------------
1	2013-02-08	Juan			Initial
2   2013-05-15	Juan			Delete one by one
3	2019-10-17	alejandramed	SRE Compliance 
*/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

BEGIN TRY
	/******************************************************************************
		variable declaration
	******************************************************************************/


	DECLARE @Queue AS TABLE 
	(
		PK_Event INT	
	)

	DECLARE @PK_Event INT

	/******************************************************************************
	Delete 
	******************************************************************************/

	INSERT INTO @Queue (PK_Event)
	SELECT PK_Event FROM dbo.EventDeleteQueue WITH (NOLOCK)

	
	DECLARE cur_Event CURSOR FORWARD_ONLY FOR 
	SELECT PK_Event FROM @Queue
	

		OPEN cur_Event
		FETCH NEXT FROM cur_Event INTO @pk_Event
		WHILE @@FETCH_STATUS = 0
		BEGIN

				BEGIN TRAN T1
				/*Delete each child table*/	

				DELETE FROM dbo.EventGuestSpeakerLocale where PK_Event = @PK_Event

				DELETE FROM EventURL WHERE PK_Event = @PK_Event
	
				DELETE FROM EventCoordinatorDetail WHERE PK_Event = @PK_Event 
	
				--DELETE FROM SubEventQualificationFormula WHERE PK_Event = @PK_Event
	
				DELETE FROM EventHotel WHERE PK_Event = @PK_Event 
	
				--DELETE FROM EventTicketAssignment WHERE PK_Event = @PK_Event 
				DELETE FROM EventGuestSpeakers WHERE PK_Event = @PK_Event
	
				--DELETE FROM EventInventory WHERE PK_Event = @PK_Event 
				DELETE EL FROM EventImageLocaleDesc EL INNER JOIN EventImage E ON EL.PK_EventImage = E.PK_EventImage WHERE E.PK_Event = @PK_Event

				DELETE FROM EventImage WHERE PK_Event = @PK_Event

				DELETE FROM dbo.EventAudioLocaleDesc WHERE PK_Event = @PK_Event
	
				DELETE FROM EventAudio WHERE PK_Event = @PK_Event
	
				DELETE FROM SubEventLocaleDesc WHERE PK_Event = @PK_Event 
	
				DELETE FROM EventDSTeamType WHERE PK_Event = @PK_Event

				DELETE FROM EventSecurityRoles WHERE PK_Event = @PK_Event 

				DELETE FROM EventCountry WHERE PK_Event = @PK_Event

				DELETE FROM EventDistributorCountry WHERE PK_Event = @PK_Event
		
				DELETE FROM EventDistributorCountryLocales WHERE PK_Event = @PK_Event

				DELETE FROM EventEventTrackingPageSection WHERE PK_Event = @PK_Event

				DELETE FROM EventSKU WHERE PK_Event = @PK_Event

				DELETE FROM EventLocaleDesc WHERE PK_Event = @PK_Event 
					
				DELETE FROM dbo.SubEventExtn WHERE PK_Event = @PK_Event

				DELETE FROM SubEvent WHERE PK_Event = @PK_Event

				DELETE FROM EventEventSubType WHERE PK_Event = @PK_Event

				DELETE FROM dbo.EventExtn WHERE PK_Event = @PK_Event

				DELETE dbo.FeaturedEvents WHERE PK_Event = @PK_Event

				/*Delete the Event*/
				DELETE E FROM dbo.Event E WHERE PK_Event = @PK_Event

				/*Clean Queue*/
				DELETE FROM dbo.EventDeleteQueue 	WHERE PK_Event = @PK_Event

				COMMIT TRAN T1
	
	
	
			FETCH NEXT FROM cur_Event INTO @PK_Event

		END
		CLOSE cur_Event
		DEALLOCATE cur_Event


		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0
				ROLLBACK TRAN T1			
		IF @IsDevQA = 1
			SELECT 'PK_Event ' + STR(@PK_Event) + ':' + ERROR_MESSAGE()
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'PK_Event ' + STR(@PK_Event) + ':' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH
END
GO

