CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Ins_EventBadgePortSetup]	
	-- MANDATORY
	@EventID INT
	,@Action INT
	,@BeginUserID INT = NULL
	,@EndUserID INT = NULL
	,@PortNumber INT = NULL
	,@PK_EventBadgePortSetup INT = NULL
	
	-- OPTIONAL
	,@Error int OUTPUT 
	,@ErrorMessage varchar(4000) OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN


/*
OBJECT:		dbo.usp_MyHLEventAPI_Ins_EventBadgePortSetup

USE:		DECLARE @e int, @em varchar(200)
			
			EXEC usp_MyHLEventAPI_Ins_EventBadgePortSetup
					@EventID = 800
					,@Action = 0 SELECT, 1 Add, 2 Delete
					,@BeginUserID = 1
					,@EndUserID = 20
					,@PortNumber = 8080
					,@PK_EventBadgePortSetup = NULL
					,@ModifiedBy = 'OrlandoL'
					 
					 -- OPTIONAL
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 0
			Print @em
			
DESCRIPTION: UPDATE Badge Printing and Badge SubEvents tables

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2013-01-15	OrlandoL		Initial
2	2019-10-16	 JonathanO		Refactor code (SRE)
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	
/******************************************************************************
INSERT/UPDATE EventBadgePrinting and EventBadegeSubEvents tables
******************************************************************************/
BEGIN TRY
	
	IF @Action = 0
		SELECT PK_EventBadgePortSetup, PK_Event, BeginUserID, EndUserID, PortNumber FROM dbo.EventBadgePortSetup WITH (NOLOCK) WHERE PK_Event = @EventID
	ELSE IF @Action = 1
	BEGIN
		INSERT INTO
			dbo.EventBadgePortSetup
		(
			[PK_Event],
			[BeginUserID],
			[EndUserID],
			[PortNumber]	
		)
		VALUES
		(
			@EventID,
			@BeginUserID,
			@EndUserID,
			@PortNumber
		)
	END
	ELSE IF @Action = 2 AND @PK_EventBadgePortSetup IS NOT NULL
	BEGIN
		DELETE FROM dbo.EventBadgePortSetup WHERE PK_EventBadgePortSetup = @PK_EventBadgePortSetup AND PK_Event = @EventID
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
END CATCH;



/******************************************************************************
	END Procedure
******************************************************************************/
END
