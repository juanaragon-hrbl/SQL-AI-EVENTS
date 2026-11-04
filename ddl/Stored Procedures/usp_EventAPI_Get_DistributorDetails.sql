CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DistributorDetails]
    -- REQUIRED
   @DistributorID varchar(10)
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_DistributorDetails

USE:
			DECLARE @e int, @em varchar(4000)
                EXEC usp_EventAPI_Get_DistributorDetails @DistributorID = '30675379'
                                                        ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                                ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						                                ,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.v_DistributorContactDetails
NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
3   2019-09-05 NoeG		SRE template applied
2   2016-12-01 Sandhya	Added COP, COR 
1	2009-01-22 Sandhya	Initial
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY
	/******************************************************************************
	 Check if the Distributor Exists
	******************************************************************************/
	IF NOT EXISTS (SELECT sDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
				   UNION
				   SELECT DistributorID FROM dbo.TempDistributors WITH(NOLOCK) WHERE DistributorID = @DistributorID)
	  BEGIN
		SET @Error = 8
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	  END
 
/******************************************************************************
select record
******************************************************************************/

BEGIN 

	SELECT  
		sDistributorID
		,sFirstName
		,slastName
		,sSubTeam AS sTeam
		,sType
		,dSupervisorQualification 
		,sDistributorCountryProcessingCode
		,sAddress
		,sCity
		,sStateCode
		,sState 
		,sPostalCode 
		,Phone AS sPhone
		,sCountryName AS Country
			,'NULL' As NationalID
			,'NULL' As RegionLocalName
			,'NULL' As RegionEnglishName
		,COALESCE(SpouseName,'') As SpouseName
		,Email 
		,Language
		,PK_Language
		,DistributorCountryProcessingISO
		,CountryISO
	FROM 
	   dbo.v_DistributorContactDetails DC WITH(NOLOCK)
	WHERE
	   sDistributorID = @DistributorID
	UNION
	SELECT 
		   DistributorID
		  ,FirstName
		  ,LastName
		  ,'No Team'
		  ,'TEMP'
		  ,''
		  ,'' 
		  ,COALESCE(ADDRESS1,'') + COALESCE(ADDRESS2,'') + COALESCE(ADDRESS3,'') AS sAddress
		  ,City
		  ,''
		  ,State
		  ,ZipCode
		  ,DayPhone
		  ,Country  
			,'NULL' As NationalID
			,'NULL' As RegionLocalName
			,'NULL' As RegionEnglishName
		  ,'NULL'
		  ,'' AS Email
		  ,'' AS Language
		  ,'' AS PK_Language
		  ,''
		  ,''
	FROM 
	   dbo.TempDistributors D WITH (NOLOCK) 
	WHERE
	   DistributorID = @DistributorID
	   AND
	   NOT EXISTS (SELECT 1 FROM dbo.v_Distributor S WHERE D.DistributorID = S.sDistributorID)
  

	END
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
	end procedure
******************************************************************************/
END