CREATE PROCEDURE [dbo].[usp_EventsAT_Get_CheckUserExists]	
	-- MANDATORY
	 @UserID nVARCHAR(30)        /* Logged User */
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA tinyint = 0
AS
BEGIN


/*
OBJECT:			dbo.usp_EventsAT_Get_CheckUserExists

USE:		DECLARE @e int, @em varchar(4000)
			EXEC usp_EventsAT_Get_CheckUserExists
					 @UserID  = 'ivanci'
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.EventATAccessUser

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventATAccessUser

VERSIONS
--------------------------------------------------------------------
	1.0.0	2012-08-07	OrlandoL	Initial
	2.0.0	2019-08-08	OrlandoL	Refactor code (SRE)
	2.1.0	2021-12-21	ivanci		US 882107 - Admin Tool - User Management - Able to remove access for user
	2.1.1	2022-06-13	puertac		US 1050464: Remove Error logging when ID has no access
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

SET @UserID = LTRIM(RTRIM(@UserID))

/**************************************************************************************
 Verify if the LoggedUser is a valid User
****************************************************************************************/

IF NOT EXISTS (SELECT PK_EventATAccessUser FROM dbo.EventATAccessUser ET WITH(NOLOCK) WHERE EventATAccessUserName = @UserID)
BEGIN
	SET @Error = 280
	SELECT @ErrorMessage = ErrorMsg FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = @Error
	RETURN 
END


/**************************************************************************************
 CHECK USERID EXISTS OR NOT
****************************************************************************************/

BEGIN TRY

	IF @IsDevQA= 2 THROW 60000, N'Unit test Error', 1;

	SELECT 
		EventATAccessUserName AS UserID 
		,EventATAccessUserFirstName AS FirstName
		,EventATAccessUserLastName AS LastName
		,EventATAccessUserCountry AS Country
		,EU.PK_EventATAccessUserType 
		,EUT.EventATAccessUserType 
		,EU.EventATAccessUserEmailAddress
	FROM	
		dbo.EventATAccessUser EU WITH(NOLOCK) 
	INNER JOIN
		dbo.EventATAccessUserTypes EUT WITH(NOLOCK) 
		ON
			EU.PK_EventATAccessUserType = EUT.PK_EventATAccessUserType 	
	WHERE
		EventATAccessUserName = @UserID AND ISNULL(IsDeleted,0) = 0			-- 2.1.0


	SELECT DISTINCT
		--eu.PK_EventATAccessUser
		eu.EventATAccessUserName
		--,eu.PK_EventATAccessUserType
		,eum.PK_EventATAccessModule
		,am.EventATAccessModuleName
		,eum.PK_EventATAccessModuleAction
		,ama.EventATAccessModuleActionName		
	FROM 
		dbo.EventATAccessUserTypeModuleActions eum WITH(NOLOCK) 
	INNER JOIN 
		dbo.EventATAccessUser eu WITH(NOLOCK) 
	ON
		eum.PK_EventATAccessUserType = eu.PK_EventATAccessUserType
		AND
		eu.EventATAccessUserName = @UserID		
	INNER JOIN
		dbo.EventATAccessModules am WITH(NOLOCK) 
	ON
		am.PK_EventATAccessModule = eum.PK_EventATAccessModule
	INNER JOIN
		dbo.EventATAccessModuleActions ama WITH(NOLOCK) 
	ON
		ama.PK_EventATAccessModuleAction = eum.PK_EventATAccessModuleAction
/*	WHERE
		eu.EventATAccessUserName = @UserID */


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
	 
END CATCH

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
END