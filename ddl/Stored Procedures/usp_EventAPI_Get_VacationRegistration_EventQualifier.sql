
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_VacationRegistration_EventQualifier]
	-- REQUIRED
	 @DistributorID Varchar(40)
	,@PK_Event int	

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0	

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_VacationRegistration_EventQualifier


DESCRIPTION:	Retrieves record from dbo.EventQualifier

NOTES:			
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_EventAPI_Get_VacationRegistration_EventQualifier
				@DistributorID = '2222222222'
				,@PK_Event = 691
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventQualifier

VERSIONS
--------------------------------------------------------------------
1	2011-07-26	Jahnavi/Chandan		Initial
1.1 2012-06-26  SandhyaP		    Renamed SP from usp_EventAPI_Get_EventQualifier_SamCam to usp_EventAPI_Get_VacationRegistration_EventQualifier
									@EventID parameter changed to @PK_Event
									@PK_Event value needs to be passed, hence uncommented @EventID = 319 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
	--SET @EventID = 319

	/******************************************************************************
	be sure the value of FK exists in referenced table
	******************************************************************************/

	IF NOT EXISTS 
		(SELECT DistributorID 
		 FROM dbo.EventQualifier WITH (NOLOCK) 
		 WHERE PK_Event = @PK_Event 
		 AND DistributorID = @DistributorID) 
	BEGIN
		SELECT
				 NULL as [PK_EventQualifier] 
				,[PK_Event] = @PK_Event
				,[Distributorid] = @DistributorID
				,0 as Qualified
		RETURN 
	END
	/******************************************************************************
	select record
	******************************************************************************/

	BEGIN TRY

		SELECT
			 [PK_EventQualifier] 
			,[PK_Event] 
			,[Distributorid] 
			,1 as Qualified
		FROM 
			dbo.EventQualifier WITH (NOLOCK) 
		WHERE 
			Distributorid = @Distributorid
			AND
			PK_Event = @PK_Event

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

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime 

/******************************************************************************
	end procedure
******************************************************************************/
END