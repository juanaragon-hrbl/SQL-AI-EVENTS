CREATE PROCEDURE [dbo].[usp_EventAPI_Get_VacationRegistration_Nationality]
	-- Error Parameters
	@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0	

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_VacationRegistration_Nationality

DESCRIPTION:	Retrieves record from dbo.v_Nationality

NOTES:	
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_EventAPI_Get_VacationRegistration_Nationality
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]
		

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.VacationRegistration

VERSIONS
--------------------------------------------------------------------
1	2011-07-26		Jahnavi/Chandan		Initial
1.1 2012-06-26      SandhyaP            Renamed SP from usp_EventAPI_Get_Nationality_SamCam to usp_EventAPI_Get_VacationRegistration_Nationality
1.2	2019-09-05		NoeG				SRE template applied
1.4 2019-10-09		alejandramed		SRE Compliance 
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

BEGIN TRY

	/******************************************************************************
	select record
	******************************************************************************/

		SELECT
		  nCountryID
		 ,sCountryName 
		FROM
			dbo.v_Nationality

	/******************************************************************************
	end procedure
	******************************************************************************/

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
		
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
END