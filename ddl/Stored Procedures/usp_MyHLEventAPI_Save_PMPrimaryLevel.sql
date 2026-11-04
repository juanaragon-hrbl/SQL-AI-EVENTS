CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Save_PMPrimaryLevel]
		-- Mandatory Parameters
		@PrimaryLevelCode VARCHAR(5)
		,@PrimaryLevelDescription VARCHAR(50)
		,@Order INT

		-- Optional Parameters
		,@PK_PMPrimaryLevel	INT = NULL

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:     dbo.usp_MyHLEventAPI_Save_PMPrimaryLevel
USE:
				DECLARE @e int, @em varchar(4000)

				EXEC [dbo].[usp_MyHLEventAPI_Save_PMPrimaryLevel]
					-- Mandatory Parameters
					@PrimaryLevelCode = 			'TCM'
					,@PrimaryLevelDescription =		'Test X Level'
					,@Order	=						6
					
					-- Optional Parameters
					,@PK_PMPrimaryLevel =			NULL				/*	- Setting null value or a non Existing Number, insert is porcessed
																		- Setting an existing number, update is processed
																	*/
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

		SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION: Inserts or Updates record into dbo.PMPrimaryLevel
				
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

		DECLARE @PrimaryLevels table (
			[action]					varchar(25)
			,[PK_PMPrimaryLevel]		int
			,[PrimaryLevelCode]			VARCHAR(5)
			,[PrimaryLevelDescription]	VARCHAR(50)
			,[Order]					INT
			,[ModifiedDateUTC]			DATETIME
			,[ModifiedBy]				VARCHAR(50)
		);

		MERGE PMPrimaryLevel AS t
			USING (
				SELECT	ISNULL(@PK_PMPrimaryLevel,(Select ISNULL(max(PK_PMPrimaryLevel),0)+1 from PMPrimaryLevel WITH (NOLOCK))) AS [PK_PMPrimaryLevel]
						,@PrimaryLevelCode AS [PrimaryLevelCode]
						,@PrimaryLevelDescription AS [PrimaryLevelDescription]
						,@Order AS [Order]						
						,@StartTime AS [ModifiedDateUTC]
						,replace(suser_sname(),'HERBALIFECORP\','') AS [ModifiedBy]
			) AS s ON (t.[PK_PMPrimaryLevel] = @PK_PMPrimaryLevel)
			WHEN MATCHED THEN
				UPDATE SET
						t.[PrimaryLevelCode] = s.[PrimaryLevelCode]
						,t.[PrimaryLevelDescription] = s.[PrimaryLevelDescription]
						,t.[Order] = s.[Order]
						,t.[ModifiedDateUTC] = s.[ModifiedDateUTC]
						,t.[ModifiedBy] = s.[ModifiedBy]
			WHEN NOT MATCHED THEN
				INSERT (
						[PK_PMPrimaryLevel]
						,[PrimaryLevelCode]
						,[PrimaryLevelDescription]
						,[Order]
				)
				VALUES (
						s.[PK_PMPrimaryLevel]
						,s.[PrimaryLevelCode]
						,s.[PrimaryLevelDescription]
						,s.[Order]
				)
			OUTPUT	$action
					,inserted.[PK_PMPrimaryLevel]
					,inserted.[PrimaryLevelCode]
					,inserted.[PrimaryLevelDescription]
					,inserted.[Order]
					,inserted.[ModifiedDateUTC]
					,inserted.[ModifiedBy]
				INTO @PrimaryLevels
		;	-- MERGE PMPrimaryLevel

		/* Return the Information from the Record Inserted or Updated */

		SELECT PK_PMPrimaryLevel, PrimaryLevelCode, PrimaryLevelDescription, [Order] FROM @PrimaryLevels

		IF @IsDevQA = 1	
		Begin 
			SELECT [Action], PK_PMPrimaryLevel, PrimaryLevelCode, PrimaryLevelDescription, [Order] FROM @PrimaryLevels

			SELECT 'Table PMPrimaryLevel', PK_PMPrimaryLevel, PrimaryLevelCode, PrimaryLevelDescription, [Order], [ModifiedDateUTC], [ModifiedBy] FROM [PMPrimaryLevel]
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
