CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_EventDistributorNotes]
	@DistributorID varchar(20) 
	,@PK_Event int 
	,@PK_EventNoteType int
	,@Notes nvarchar(1000) 
	,@CreatedBy varchar(50) 

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************

	OBJECT:			dbo.usp_EventAPI_Ins_EventDistributorNotes
	USE:			
				DECLARE @e int, @em varchar(max)

				EXEC usp_EventAPI_Ins_EventDistributorNotes
						@DistributorID = '1111111111'
						,@PK_Event = 1
						,@PK_EventNoteType = 1
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@CreatedBy = ''
						-- OPTIONAL					
						,@Notes = ''
						,@IsDevQA = 0

						SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Inserts record into dbo.EventDistributorNotes

	NOTES:			

	DEPENDENCIES
	--------------------------------------------------------------------
	SQL SERVER 2005
	dbo.EventDistributorNotes

	VERSIONS
	--------------------------------------------------------------------
	1		2008-10-14		Aarti			Initial
	1.1		2019-05-10		alejandramed	Homologating of standard error handling	
	1.2		2019-07-15		alejandramed	Setting error parameters as optionals
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/******************************************************************************
			variable declaration
		******************************************************************************/
		DECLARE @PK_Distributor int
		SET @PK_EventNoteType = ISNULL(@PK_EventNoteType,1)

		/******************************************************************************
			get pk_distributor for passed distributorid
		******************************************************************************/

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID

		/******************************************************************************
			be sure record is unique
		******************************************************************************/
		/*
		IF EXISTS(SELECT PK_EventDistributorNote FROM dbo.EventDistributorNotes WHERE PK_Event = @PK_Event 
			AND PK_Distributor = @PK_Distributor AND PK_EventNoteType = @PK_EventNoteType)
		BEGIN
			SET @Error = 227
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		END
		*/

		/******************************************************************************
		be sure the value of FK exists in referenced table
		******************************************************************************/
		IF NOT EXISTS(SELECT PK_Event FROM dbo.Event(NOLOCK) WHERE PK_Event = @PK_Event)
		BEGIN
			SET @Error = 5
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		END

		/******************************************************************************
		be sure the value of FK exists in referenced table
		******************************************************************************/
		IF NOT EXISTS(SELECT PK_EventNoteType FROM dbo.EventNoteTypes(NOLOCK) WHERE PK_EventNoteType = @PK_EventNoteType)
		BEGIN
			SET @Error = 7
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		END

		/******************************************************************************
		be sure distributor exists
		******************************************************************************/
		IF NOT EXISTS(SELECT nDistributorID FROM dbo.v_DistributorUnionTemp (NOLOCK) WHERE nDistributorID = @PK_Distributor)
		BEGIN
			SET @Error = 8
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		END
		/******************************************************************************
		insert record
		******************************************************************************/
		BEGIN TRY
		INSERT
			dbo.EventDistributorNotes
		(
			[PK_Distributor]
			,[Notes]
			,[PK_Event]
			,[PK_EventNoteType]
			,[CreatedBy]
		)
		SELECT
			@PK_Distributor
			,@Notes
			,@PK_Event
			,@PK_EventNoteType
			,@CreatedBy

		END TRY

		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
			RETURN 
		END CATCH

		-- Update processing Log
		EXEC dbo.usp_Utility_UpdateProcessingLog 
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime

		/******************************************************************************
			end procedure
		******************************************************************************/
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