
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_VacationRegistration_VacationDSService]
    -- Required
    @PK_Event INT

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0	

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_VacationRegistration_VacationDSService

DESCRIPTION:	Retrieves record from dbo.EventDSCommunication

NOTES:			
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_EventAPI_Get_VacationRegistration_VacationDSService
				@PK_Event = 691
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.VacationRegistration

VERSIONS
--------------------------------------------------------------------
1	2011-07-28		Jahnavi/Chandan		Initial
1.1 2012-06-26      SandhyaP            Renamed SP from usp_EventAPI_Get_VacationDSService_SamCam to usp_EventAPI_Get_VacationRegistration_VacationDSService
										Added @PK_Event required parameter
1.2	2019-09-05		NoeG				SRE template applied
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

	/******************************************************************************
	select record
	******************************************************************************/
	BEGIN TRY

		SELECT 
			A.sCountryName
			,B.Email
		FROM
			dbo.v_Countries A 
			INNER JOIN
			dbo.EventDSCommunication B WITH (NOLOCK)
			ON
				A.nCountryID = B.PK_Country
				AND
				B.EventType = 1
		WHERE 
			B.PK_Event = @PK_Event			
             
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