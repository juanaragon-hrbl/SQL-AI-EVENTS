CREATE PROCEDURE [dbo].[usp_EventsAT_Get_TeamLevelAccess]
	-- MANDATORY
	@LoggedUser nVARCHAR(20)
	,@SubTypeCode nVARCHAR(5)				/* pass DistributorID for search */
	,@Locale nVARCHAR (10) 
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA TINYINT = 0
AS
BEGIN
/****************************************************************************************************************
OBJECT:		dbo.usp_EventsAT_Get_TeamLevelAccess
USE:		
			DECLARE @e int, @em varchar(4000)
			EXEC usp_EventsAT_Get_TeamLevelAccess
			         @LoggedUser = 'jesussal'
					,@SubTypeCode  = 'PT'
					,@Locale = 'en-US'
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	
NOTES:			
DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1.0.0	  2021-05-18		jesussal / puertac		Initial

*************************************************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)

	
DECLARE @PK_Locale INT
DECLARE @LoggedUserType INT

SELECT @Error = 0, @ErrorMessage = '';

SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @Locale
SELECT @LoggedUserType = PK_EventATAccessUserType FROM dbo.EventATAccessUser ET WITH (NOLOCK) WHERE EventATAccessUserName = @LoggedUser

/**************************************************************************************
 Verify if the DistributorID is a valid DistributorID
****************************************************************************************/

IF NOT EXISTS (SELECT PK_DSSubType FROM [PubEvents].[dbo].[dimDSSubType] ET WITH (NOLOCK) WHERE SubTypeCode = @SubTypeCode)
BEGIN
		SET @Error = 267
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
END

/******************************************************************************
SELECT RECORD
******************************************************************************/

BEGIN TRY

	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END

	SELECT DISTINCT
	 PK_DSSubType	
	,SubTypeCode	
	,SubTypeDesc	
	,PK_DSType	
	,TYPECODE	
	,PK_DSTeam	
	,TEAMCODE	
	,SORTBY
	FROM [PubEvents].[dbo].[dimDSSubType] AS D WITH (NOLOCK)
	WHERE D.SubTypeCode = @SubTypeCode		

	/* Retrieve Events and SubEvent for DS COP Markets*/	
	SELECT DISTINCT 
		@SubTypeCode AS SubTypeCode,
		ESL.PK_Locale,  
		SGM.PK_EventSubTypeGroupMaster,
		SGM.EventSubTypeGroupMasterName,
		SG.PK_EventSubTypeGroup,  
		EST.PK_EventSubType,  
		EST.EventSubType,
		EDA.PK_EventSubTypeLocaleDesc,
		EDA.[Message]
	FROM dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
	INNER JOIN dbo.EventSubTypeGroup SG WITH (NOLOCK)
		ON	SGM.PK_EventSubTypeGroupMaster = SG.PK_EventSubTypeGroupMaster
	INNER JOIN	dbo.EventSubTypes EST WITH (NOLOCK)
		ON	EST.PK_EventSubTypeGroup = SG.PK_EventSubTypeGroup
		AND	EST.PK_EventType = SG.PK_EventType
	INNER JOIN dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK) 
		ON  EST.PK_EventSubType = ESL.PK_EventSubType  
	INNER JOIN  dbo.EventTeamLevelAccess EDA WITH (NOLOCK)
		ON EDA.PK_EventSubTypeLocaleDesc = ESL.PK_EventSubTypeLocaleDesc  
		AND	EDA.SubTypeCode = @SubTypeCode    
 --INNER JOIN  dbo.EventATAccessUserModules EUM (NOLOCK)  
 --		ON EUM.PK_Locale = EDA.PK_Locale  
 --INNER JOIN dbo.EventATAccessUser EU (NOLOCK)  
 --		ON EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser    
	WHERE ESL.PK_Locale = @PK_Locale  
  --AND EU.EventATAccessUserName = @LoggedUser   
	AND SG.PK_EventType = 3
	AND	SGM.IsActive = 1
		
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
END



