CREATE PROCEDURE [dbo].[usp_EventsAT_Del_EventOwner]
	-- REQUIRED
	@PK_Event int,
	@UserName VARCHAR(100)

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
	BEGIN
		/******************************************************************************
		OBJECT:			dbo.usp_EventsAT_Del_EventOwner

		USE:
						DECLARE @e int, @em varchar(4000)

						EXEC dbo.usp_EventsAT_Del_EventOwner
								@PK_Event = 77875
								,@UserName = 'gustavogr'
								,@Error = @e OUTPUT  /* @e must be defined in the local call */
								,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
								,@IsDevQA = 1

						SELECT @e AS [Error], @em AS [Error Message]

		DESCRIPTION:	Deletes and owner from event

		NOTES:


		VERSIONS
		--------------------------------------------------------------------
		1.0.0		2023-12-01		ivanci		Initial
		******************************************************************************/

		SET ANSI_NULLS ON
		SET QUOTED_IDENTIFIER ON
		SET NOCOUNT ON

		DECLARE 
			@StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_User int = (SELECT TOP 1 PK_EventATAccessUser FROM [dbo].[EventATAccessUser] WITH (NOLOCK) WHERE EventATAccessUserName = @UserName);


		BEGIN TRY

			BEGIN TRANSACTION
				
				DELETE FROM [dbo].[EventOwners] WHERE [PK_Event] = @PK_Event AND [PK_EventATAccessUser] = @PK_User;

			COMMIT TRANSACTION

			-- Update processing Log
			EXEC [dbo].[usp_Utility_UpdateProcessingLog]
					@StoredProcedureName = @StoredProcedure
					,@StartTime = @StartTime;

		END TRY
	
		BEGIN CATCH
			IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

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
		END CATCH;
	END;
