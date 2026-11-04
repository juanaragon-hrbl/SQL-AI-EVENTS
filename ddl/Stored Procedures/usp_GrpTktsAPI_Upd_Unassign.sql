CREATE PROCEDURE [dbo].[usp_GrpTktsAPI_Upd_Unassign]
			      @ToDistributorID VARCHAR(10)
                 ,@FromDistributorID VARCHAR(10)
                 ,@PK_Event INT
				-- Error Parameters
				,@Error	int = 0 OUTPUT
				,@ErrorMessage varchar(4000) = '' OUTPUT

				-- QA/DEV
				,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_GrpTktsAPI_Upd_Unassign

USE:
				DECLARE @e int, @em varchar(4000)
                 EXEC usp_GrpTktsAPI_Upd_Unassign
				      @ToDistributorID = '2222222222'
				     ,@FromDistributorID = '1111111111'
				     ,@PK_Event = 240
					,@Error = @e OUTPUT  -- @e must be defined in the local call   
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves the header Records for group ticket assignment for the purchaser

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.EventTicketAssignment

VERSIONS
--------------------------------------------------------------------
1	2010-07-13		Prabhu		Intitial
2   2015-12-17		IniU		Add logic to only unassign if someone is not registered for the event.
2	2019-08-14		NoeG		Refactor code (SRE)
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY  

		/* Parameters to be passed from front end */
		DECLARE @PK_ToDistributor INT
		DECLARE @PK_FromDistributor INT
		DECLARE @PK_EventTicket INT
		DECLARE @Count INT
		DECLARE @TicketsQuantity INT
		DECLARE @PK_EventSKU INT
		DECLARE @PK_SKUPurchased INT
		DECLARE @ValidToDateUTC DATETIME = '2049-12-31'


		IF NOT EXISTS (SELECT [PK_EventsRegistration] FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_Event = @PK_Event AND DistributorID = @ToDistributorID AND HasCheckedIn = 1)
		BEGIN

		SELECT @PK_ToDistributor = nDistributorID FROM dbo.v_DistributorUnionTemp
		WHERE sDistributorID = @ToDistributorID

		SELECT @PK_FromDistributor = nDistributorID FROM dbo.v_DistributorUnionTemp
		WHERE sDistributorID = @FromDistributorID

		SELECT @TicketsQuantity = COUNT(DISTINCT PK_EventTicket) 
		FROM 
			dbo.EventTicketAssignment ETA WITH (NOLOCK)
		WHERE 
			ETA.PK_FromDistributor  = @PK_FromDistributor
		AND
			ETA.PK_ToDistributor = @PK_ToDistributor
		AND
			ETA.ValidToDateUTC = @ValidToDateUTC

		SET @Count = 1

		/* SETTING THE PK_EventTicket Value */
		WHILE
			@Count <= @TicketsQuantity
		BEGIN

		/* SELECT THE RESPECTIVE RECORDS */
		SELECT 
			 @PK_EventTicket = MIN(PK_EventTicket)
			,@PK_EventSKU = ETA.PK_EventSKU
			,@PK_SKUPurchased = ETA.PK_SKUPurchased
		FROM 
			dbo.EventTicketAssignment ETA WITH (NOLOCK)
		WHERE 
			ETA.PK_FromDistributor  = @PK_FromDistributor
		AND
			ETA.PK_ToDistributor = @PK_ToDistributor
		AND
			ETA.ValidToDateUTC = @ValidToDateUTC	
		GROUP BY
			  ETA.PK_EventSKU
			 ,ETA.PK_SKUPurchased
	 

		/* UN - ASSIGN THE RECORD FOR THE PURCHASER */
		UPDATE
			ETA
		SET
			 ETA.ValidToDateUTC = @ValidToDateUTC
			,ETA.ModifiedDateUTC = GetDate()
			,ETA.ModifiedBy = REPLACE (suser_sname(),'HERBALIFECORP\','')
		FROM
			dbo.EventTicketAssignment ETA
		WHERE
			PK_EventTicket = @PK_EventTicket
			AND
			PK_ToDistributor = @PK_FromDistributor
	
	
		/* DELETE THE ASSIGNMENT */

		DELETE FROM 
		 dbo.EventTicketAssignment 
		WHERE
		 PK_FromDistributor = @PK_FromDistributor
		 AND 
		 PK_ToDistributor = @PK_ToDistributor
		 AND
		 PK_EventTicket = @PK_EventTicket
		 AND
		 ValidToDateUTC = @ValidToDateUTC

		/* INSERT THE COUNTER */

		SET @Count = @Count + 1

		/* END WHILE LOOP */
		END

		END
		ELSE
		BEGIN
			SELECT 
				@Error = PK_ErrorCode
				,@ErrorMessage = ErrorMsg + ' : '+@ToDistributorID
			FROM
				dbo.ErrorCode WITH (NOLOCK)
			WHERE 
				PK_ErrorCode = 269
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
	END CATCH  

/* END PROCEDURE */
       
END
GO

