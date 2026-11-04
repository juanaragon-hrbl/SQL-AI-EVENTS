
CREATE PROCEDURE [dbo].[usp_GrpTktsAPI_Get_Events]
	-- REQUIRED
       /* NO INPUT PARAMETERS REQUIRED */

		-- Error Parameters
		@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************

	OBJECT:			dbo.usp_GrpTktsAPI_Get_Events

	USE:			DECLARE @e int, @em varchar(4000);

					EXEC usp_GrpTktsAPI_Get_Events
						@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]


DESCRIPTION:	Retrives a list of records from dbo.Event Which has Group Tickets functionality
				ENABLED and the event start date is greater than the current date time

	NOTES:			

	DEPNDENCIES
	--------------------------------------------------------------------
	dbo.Event

	SQL SERVER 2008
	VERSIONS
	--------------------------------------------------------------------
	1	2010-07-13	    PrabhuS	    Initial
	2	2019-08-14		NoeG		Refactor code (SRE)
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON


/******************************************************************************
                          VARIABLE DECLARATION
******************************************************************************/

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY


		/******************************************************************************
							  BE SURE THE QUERY RETURNS A VALUE
		******************************************************************************/
		IF NOT EXISTS( 
				SELECT		
									  E.PK_Event
									 ,E.EventName
				FROM		
							[dbo].[Event] E	WITH (NOLOCK)
				WHERE		
							E.CanAssignTickets = 1
							AND
							@StartTime <= E.dEndUTC
			)
	
			BEGIN
				SET @Error				= 273

				-- UPDATE Error Log
				EXEC dbo.usp_Utility_UpdateErrorLog 
					 @ProcedureName		= @StoredProcedure 
					,@ErrorNumber		= @Error
					,@ErrorMessage		= @ErrorMessage OUTPUT
				RETURN 
			END

		ELSE 

			BEGIN
	
				SELECT		
							  E.PK_Event
							 ,E.EventName
				FROM		
							[dbo].[Event] E	WITH (NOLOCK)
				WHERE		
							E.CanAssignTickets = 1
							AND
							@StartTime <= E.dEndUTC

			END

		-- UPDATE Processing Log
		EXEC dbo.usp_Utility_UpdateProcessingLog 
			 @StoredProcedureName	= @StoredProcedure
			,@StartTime				= @StartTime

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
	END PROCEDURE
******************************************************************************/
END
GO

