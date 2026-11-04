
CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_EventDistrubutorNotes]
	-- REQUIRED
	@DistributorID varchar(10)
   ,@EventID int
   ,@NoteType int
   ,@Notes varchar(1000)
   ,@UserID varchar(20)
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Ins_EventDistrubutorNotes

USE:
			DECLARE @e int, @em varchar(4000)
            EXEC usp_EventAPI_Ins_EventDistrubutorNotes @DistributorID = '21389533' 
					                                    ,@EventID = 1
                                                        ,@NoteType = 3 
                                                        ,@Notes = 'Rock Ur Day!'
                                                        ,@UserID = 'SandhyaP'
					                                    ,@Error = @e OUTPUT  /* @e must be defined in the local call */
					                                    ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					                                    ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.SubEvent

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1	2009-01-21 Sandhya	Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
DECLARE @PK_Distributor int
	
SELECT @Error = 0, @ErrorMessage = '';
 
/******************************************************************************
  Check If Distributor Exists
******************************************************************************/

	BEGIN TRY

		IF EXISTS (SELECT sDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
				   UNION
				   SELECT DistributorID FROM dbo.TempDistributors WITH (NOLOCK) WHERE DistributorID = @DistributorID)
		   BEGIN 
				   SELECT @PK_Distributor = DistributorID
				   FROM (
				   SELECT nDistributorID AS DistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
				   UNION
				   SELECT PK_Temp AS DistributorID FROM dbo.TempDistributors WITH (NOLOCK) WHERE DistributorID = @DistributorID)A
		   END
		ELSE
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
		  Check If Event Exists
		******************************************************************************/
		IF NOT EXISTS(SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @EventID)
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
		  Check If NoteType Exists
		******************************************************************************/
		IF NOT EXISTS(SELECT PK_EventNoteType FROM dbo.EventNoteTypes WITH (NOLOCK) WHERE PK_EventNoteType = @NoteType)
		BEGIN
			SET @Error = 181
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		END

		/******************************************************************************
		  Insert the Notes
		******************************************************************************/

		BEGIN 

		INSERT INTO
			  dbo.EventDistributorNotes
				   ([PK_Distributor]
				   ,[Notes]
				   ,[CreatedBy]
				   ,[ModifiedBy]
				   ,[PK_Event]
				   ,[PK_EventNoteType])
		VALUES (
			   @PK_Distributor
			  ,@Notes
			  ,@UserID
			  ,@UserID
			  ,@EventID
			  ,@NoteType
			   )

		END

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

/******************************************************************************
	end procedure
******************************************************************************/
END
GO


