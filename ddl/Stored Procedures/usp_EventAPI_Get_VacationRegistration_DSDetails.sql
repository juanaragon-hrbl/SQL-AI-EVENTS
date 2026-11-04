
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_VacationRegistration_DSDetails]
     @DistributorID varchar(50)

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0	

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_VacationRegistration_DSDetails

DESCRIPTION:	Retrieves Distributor information

NOTES:			
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_EventAPI_Get_VacationRegistration_DSDetails 
				@DistributorID = '2222222222'
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
1	2011-07-19	Jahnavi/Chandan		Initial
1.1 2012-06-26  SandhyaP			Renamed SP from usp_EventAPI_Get_DistbutorDetails_SamCam to usp_EventAPI_Get_VacationRegistration_DSDetails
1.2 2019-09-05	NoeG				SRE template applied
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

		SELECT D.sDistributorID as DistributorID,
			   D.sFirstName as  FirstName,
			   D.sLastName as LastName,
			   D.sTeam as TeamStatus,
			   D.sEmail as Email,
			   DC.Phone as Phone,
			   DC.Phone as Mobilenumber
		FROM 
			dbo.v_Distributor D
		INNER JOIN
			dbo.v_DistributorContactDetails DC
			ON 
				D.sDistributorID = DC.sDistributorID     
		WHERE
			D.sDistributorID = @DistributorID

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