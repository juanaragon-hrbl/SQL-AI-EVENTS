CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_Events_ActiveStatus]
        -- Mandatory Parameter(s)
		@PK_Event VARCHAR(250)

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
	
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Upd_Events_ActiveStatus
USE:
			declare @e int
			declare @em varchar(4000)
			declare @IsDevQA int

			EXEC usp_MyHLEventAPI_Upd_Events_ActiveStatus
					@PK_Event = '298,300,301,'
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Updates the respective Event records Isactive flag to 0

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.Event

VERSIONS
--------------------------------------------------------------------
1	2011-01-31	           PrabhuS	              Initial
2	2019-08-14				NoeG				Refactor code (SRE)
2	2023-01-16				ivanci				remove setting isActive

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON	

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/

DECLARE @tbl TABLE (PK_Event INT)
DECLARE @Len INT

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	SET @Len = LEN(@PK_Event)

	/* INSERT THE PARSED STRING INTO THE TABLE PARAMETER */
	WHILE @Len > 0
	BEGIN
		INSERT @tbl (PK_Event) SELECT LEFT(@PK_Event, CHARINDEX(',',@PK_Event)-1)
		SET @PK_Event = REPLACE(@PK_Event,LEFT(@PK_Event, CHARINDEX(',',@PK_Event)),'')
		SET @Len = LEN(@PK_Event)
	END

	BEGIN TRY
		/* UPDATE THE ISACTIVE FLAG TO 0 FOR ALL TH EVENTIDs PASSED IN THE COMMA SEPARATED STRING */

		UPDATE
			E
		SET
			E.IsPublish = 0
		FROM
			dbo.Event E
		INNER JOIN
			@tbl T
		ON
			E.PK_Event = T.PK_Event

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

	-- UPDATE PROCESSING LOG
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
