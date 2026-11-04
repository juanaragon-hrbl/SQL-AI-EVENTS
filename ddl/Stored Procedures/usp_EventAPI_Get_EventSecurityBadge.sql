CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventSecurityBadge]
	-- REQUIRED
	@PK_EventsRegistration int
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************

OBJECT:			dbo.usp_EventAPI_Get_EventSecurityBadge
USE:			
			DECLARE @e int, @em varchar(4000)
			EXEC usp_EventAPI_Get_EventSecurityBadge
					@PK_EventsRegistration = 12345
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
	                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.EventSecurityBadge

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.EventSecurityBadge

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	Aarti			Initial
2	2019-09-05	NoeG			SRE template applied
3   2019-10-08	alejandramed	SRE Compliance 
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
be sure the value of FK exists in referenced table
******************************************************************************/
--IF NOT EXISTS(SELECT PK_EventSecurityBadge FROM dbo.EventSecurityBadge WHERE PK_EventsRegistration = @PK_EventsRegistration)
--BEGIN
--	SET @Error = 184
--	-- Update ErrorLog
--	EXEC dbo.usp_Utility_UpdateErrorLog 
--		@ProcedureName = @StoredProcedure 
--		,@ErrorNumber = @Error
--		,@ErrorMessage = @ErrorMessage OUTPUT
--	RETURN 
--END

/******************************************************************************
select record
******************************************************************************/
BEGIN TRY
	SELECT
		 S.PK_BadgeStatus
		,S.BadgeStatus
		,B.BadgeUID
		,B.DistributorID
		,R.DistributorTeam AS Team
		,B.EventRegistrationName
		,B.EventQualificationString
		,B.PK_Event
		,B.ModifiedDateUTC
		,B.ModifiedBy
		,B.CreatedDateUTC
		,B.CreatedBy
		,B.PK_Distributor
		,B.IsACtive
		,B.PK_EventSecurityBadge
	FROM 
		dbo.EventSecurityBadge B WITH (NOLOCK) 
	INNER JOIN
		dbo.BadgeStatus S WITH (NOLOCK)
	ON
		S.PK_BadgeStatus = B.PK_BadgeStatus
	INNER JOIN
		dbo.EventsRegistration R WITH (NOLOCK)
	ON
		R.PK_EventsRegistration = B.PK_EventsRegistration
	WHERE 
		B.PK_EventsRegistration = @PK_EventsRegistration
    ORDER BY
		B.ModifiedDateUTC DESC
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