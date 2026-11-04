CREATE PROCEDURE [dbo].[usp_EventsAT_Get_DSAccess]
-- MANDATORY
	@LoggedUser nVARCHAR(20)
	,@DSID nVARCHAR(30)				/* pass DistributorID for search */
	,@Locale nVARCHAR (10) 
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:		dbo.usp_EventsAT_Get_DSAccess

USE:		
			DECLARE @e int, @em varchar(4000)
			EXEC usp_EventsAT_Get_DSAccess
			         @LoggedUser = 'Juanah'
					,@DSID  = '1111111111'
					,@Locale = 'es-MX'
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieve record from v_Distributor, Locale, Event, EventLocaleDesc, SubEventLocaleDesc, EventDSAccessEvents

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2012-10-07	OrlandoL	Initial
2   2012-10-18  JuanH			Added validation by logged user
3   2012-11-08	OrlandoL		Modified validation "DS COP must belongs to the Logged User Markets"  
4   2013-06-05  JuanaH			Modified Email source
5	2019-07.15	alejandramed	Setting error parameters as optionals
6	2022-06-21	puertac			US 1050464: Remove Errorlog when @DSID does not exist
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_Locale INT
DECLARE @LoggedUserType INT

SELECT @Error = 0, @ErrorMessage = '';

SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @Locale
SELECT @LoggedUserType = PK_EventATAccessUserType FROM dbo.EventATAccessUser ET WITH (NOLOCK) WHERE EventATAccessUserName = @LoggedUser

/**************************************************************************************
 Verify if the DistributorID is a valid DistributorID
****************************************************************************************/

IF NOT EXISTS (SELECT nDistributorID FROM dbo.v_Distributor ET WHERE sDistributorID = @DSID)
BEGIN
		SELECT @Error = 267
		RETURN
END	
	
/**************************************************************************************
 Staff User cannot access DS Access. Verify LoggedUser is not a HL staff 
****************************************************************************************/

IF (SELECT PK_EventATAccessUserType FROM dbo.EventATAccessUser ET WITH (NOLOCK) WHERE EventATAccessUserName = @LoggedUser) = 3
BEGIN
		SET @Error = 279
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
	
	/* Retrieve DS info*/
	SELECT DISTINCT
		D.sDistributorID AS DistributorID
		,D.sFirstName AS FirstName
		,D.sLastName AS LastName
		,CASE WHEN D.sTeam = 'W' THEN 'World'
			  WHEN D.sTeam = 'G' THEN 'GET'
			  WHEN D.sTeam = 'M' THEN 'Millionaire'
			  WHEN D.sTeam = 'P' AND D.sSubTeam NOT IN ('CC','FC') THEN 'President'
			  WHEN D.sSubTeam = 'CC' THEN 'Chairmains Club'
			  WHEN D.sSubTeam = 'FC' THEN 'Founders Circle' ELSE 'No Team' END AS TeamStatus
		,L.LocaleCode 		
		,C.sCountryName AS Country
		,E.sString AS EmailAddress
		,sType
	FROM 
		dbo.v_Distributor D WITH (NOLOCK)	
	INNER JOIN
		dbo.v_Countries C WITH (NOLOCK)
	ON
		D.nDistributorCountryProcessingID = C.nCountryID		
	INNER JOIN
		dbo.Locales L WITH (NOLOCK)
	ON
		SUBSTRING(LocaleCode,4,2) = C.sCountryCodeISO		
	LEFT JOIN 
		dbo.v_DistributorEmail E
	ON
		E.nDistributorIDFK = D.nDistributorID
			
 	WHERE
		D.sDistributorID = @DSID	
		AND
		D.dDeleted = '2049-12-31'
	
	

	/* Retrieve Events and SubEvent for DS COP Markets*/	

	SELECT DISTINCT 
		@DSID AS DistributorID,
		ESL.PK_Locale,  
		SGM.PK_EventSubTypeGroupMaster,
		SGM.EventSubTypeGroupMasterName,
		SG.PK_EventSubTypeGroup,  
		EST.PK_EventSubType,  
		EST.EventSubType,
		EDA.PK_EventSubTypeLocaleDesc 		
	FROM		
		dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
	INNER JOIN 
		dbo.EventSubTypeGroup SG WITH (NOLOCK)
	ON
		SGM.PK_EventSubTypeGroupMaster = SG.PK_EventSubTypeGroupMaster
	INNER JOIN
		dbo.EventSubTypes EST WITH (NOLOCK)
	ON
		EST.PK_EventSubTypeGroup = SG.PK_EventSubTypeGroup
		AND
		EST.PK_EventType = SG.PK_EventType
	INNER JOIN
		dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK) 
	ON  
		EST.PK_EventSubType = ESL.PK_EventSubType  
	INNER JOIN  
		dbo.EventDSAccess EDA WITH (NOLOCK)
	ON
		EDA.PK_EventSubTypeLocaleDesc = ESL.PK_EventSubTypeLocaleDesc  
		AND
		EDA.DistributorID = @DSID    
 --INNER JOIN  
 -- dbo.EventATAccessUserModules EUM (NOLOCK)  
 --ON  
 -- EUM.PK_Locale = EDA.PK_Locale  
 --INNER JOIN  
 -- dbo.EventATAccessUser EU (NOLOCK)  
 --ON  
 -- EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser    
	WHERE
		ESL.PK_Locale = @PK_Locale  
  --AND  
  --EU.EventATAccessUserName = @LoggedUser   
		AND
		SG.PK_EventType = 3
		AND 
		SGM.IsActive = 1
		
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

/******************************************************************************
	END Procedure
******************************************************************************/
END

