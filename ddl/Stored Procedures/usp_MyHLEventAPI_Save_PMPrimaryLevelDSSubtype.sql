CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Save_PMPrimaryLevelDSSubtype]

		-- Mandatory Parameters
		@PK_PMPrimaryLevel	INT
		,@PK_DSSubType		INT

		-- Optional Parameters

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:     dbo.usp_MyHLEventAPI_Save_PMPrimaryLevelDSSubtype
USE:
				DECLARE @e int, @em varchar(4000)

				EXEC [dbo].[usp_MyHLEventAPI_Save_PMPrimaryLevelDSSubtype]
					-- Mandatory Parameters
					@PK_PMPrimaryLevel	= 	4		
					,@PK_DSSubType =		310016
					
					-- Optional Parameters

					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

		SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION: Inserts or Updates record into dbo.PMPrimaryLevelDSSubtype
				
NOTES:              


DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1.0.0		2020-02-10		NoeG			Initial

******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON      
	
------------------------------------------------------------------------------------------------------------------
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
	
	SELECT @Error = 0, @ErrorMessage = ''

	BEGIN TRY

		DECLARE @PMPrimaryLevelDSSubtypes table (
			[action]						VARCHAR(25)
			,[PK_PMPrimaryLevelDSSubtype]	INT
			,[PK_PMPrimaryLevel]			INT
			,[PK_DSSubType]					INT
			,[ModifiedDateUTC]				DATETIME
			,[ModifiedBy]					VARCHAR(50)
		);

		MERGE PMPrimaryLevelDSSubtype AS t
			USING (
				SELECT	@PK_PMPrimaryLevel AS [PK_PMPrimaryLevel]
						,@PK_DSSubType AS [PK_DSSubType]
						,@StartTime AS [ModifiedDateUTC]
						,replace(suser_sname(),'HERBALIFECORP\','') AS [ModifiedBy]
			) AS s ON (t.[PK_PMPrimaryLevel] = @PK_PMPrimaryLevel and t.[PK_DSSubType] = @PK_DSSubType)
			WHEN NOT MATCHED THEN
				INSERT (
						[PK_PMPrimaryLevel]
						,[PK_DSSubType]
				)
				VALUES (
						s.[PK_PMPrimaryLevel]
						,s.[PK_DSSubType]
				)
			OUTPUT	$action
					,inserted.[PK_PMPrimaryLevelDSSubtype]
					,inserted.[PK_PMPrimaryLevel]
					,inserted.[PK_DSSubType]
					,inserted.[ModifiedDateUTC]
					,inserted.[ModifiedBy]
				INTO @PMPrimaryLevelDSSubtypes
		;	-- MERGE PMPrimaryLevelDSSubtype

		/* Return the Information from the Record Inserted or Updated */

		SELECT [PK_PMPrimaryLevelDSSubtype], [PK_PMPrimaryLevel], [PK_DSSubType] FROM @PMPrimaryLevelDSSubtypes

		IF @IsDevQA = 1	
		Begin 
			SELECT [Action], [PK_PMPrimaryLevelDSSubtype], [PK_PMPrimaryLevel], [PK_DSSubType] FROM @PMPrimaryLevelDSSubtypes

			SELECT 'Table PMPrimaryLevelDSSubtypes', [PK_PMPrimaryLevelDSSubtype], [PK_PMPrimaryLevel], [PK_DSSubType], [ModifiedDateUTC], [ModifiedBy] FROM [PMPrimaryLevelDSSubtype]
		End
	END TRY
	BEGIN CATCH
       SET @Error = ERROR_NUMBER();
       SET @ErrorMessage = ERROR_MESSAGE();
       SET @StoredProcedure = ERROR_PROCEDURE();

	   IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

       -- UPDATE ERROR LOG
       EXEC dbo.usp_Utility_UpdateErrorLog 
                    @ProcedureName = @StoredProcedure
                    ,@ErrorNumber = 3
                    ,@ErrorMessage = @ErrorMessage
                    ,@SQLErrorCode = @Error
                    ,@SQLErrorMsg = @ErrorMessage; 
	END CATCH;

END;
GO
