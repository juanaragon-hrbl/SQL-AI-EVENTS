CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_TempGuests]
-- REQUIRED
@DistributorID varchar(10)
,@PK_Event INT
,@GuestFirstName varchar(100)
,@GuestLastName varchar(100) 
,@ModifiedBy varchar(50) 
-- OPTIONAL
,@GuestID INT = NULL	

-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0
    
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Ins_TempGuests

USE:			
				DECLARE @e int, @em varchar(4000)

                EXEC usp_EventAPI_Ins_TempGuests @DistributorID = 'markhughes'
													,@PK_Event = 9901
                                                     ,@GuestFirstName  = 'Leslie'
                                                     ,@GuestLastName = 'Stan'
													 ,@GuestID = null
                                                     ,@ModifiedBy  = 'SandhyaP'
                                                     ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                             ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
													,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Insert Temp Distributors in the TempGuests table

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1	2017-06-27		SandhyaP	Initial
2	2019-09-05		NoeG		SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @e int
DECLARE @em varchar(200)
DECLARE @PK_Temp INT

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
 
	/******************************************************************************
	  Generate the temporary ID for a distributor
	******************************************************************************/

	BEGIN TRY

	  MERGE dbo.TempGuests AS t
				USING (SELECT
							@DistributorID As DistributorID
						   ,@PK_Event As PK_Event
						   ,@GuestFirstName As GuestFirstName
						   ,@GuestLastName As GuestLastName
						   ,@ModifiedBy As CreatedBy
						   ,@ModifiedBy As ModifiedBy
					) AS s
					ON (t.PK_TempGuest = @GuestID OR (t.DistributorID = @DistributorID AND t.PK_Event = @PK_Event))
				WHEN MATCHED THEN
					UPDATE SET
						   GuestFirstName = @GuestFirstName
						   ,GuestLastName = @GuestLastName
						   ,ModifiedBy = @ModifiedBy
				WHEN NOT MATCHED THEN
	  INSERT
			   (DistributorID
			   ,PK_Event
			   ,GuestFirstName
			   ,GuestLastName
			   ,CreatedBy
			   ,ModifiedBy
			   )
		 VALUES
			   (@DistributorID
			   ,@PK_Event
			   ,@GuestFirstName
			   ,@GuestLastName
			   ,@ModifiedBy
			   ,@ModifiedBy);
           
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

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;

