CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_CountryPM]
	-- Mandatory Parameters
	
	-- Optional Parameters

	-- Error Parameters
	@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN    
/******************************************************************************    
OBJECT:   dbo.usp_MyHLEventAPI_Get_CountryPM    
  
USE:   
		DECLARE @e int, @em varchar(4000)
		
		EXEC dbo.usp_MyHLEventAPI_Get_CountryPM    
			@Error = @e OUTPUT  /* @e must be defined in the local call */    
			,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */    
            ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]
		    
DESCRIPTION: Retrieves all the records from Country Preferred Members 
    
NOTES:       
    
DEPENDENCIES    
----------------------------------------------------------------------------------    
    
VERSIONS    
----------------------------------------------------------------------------------    
1.0.0		2020-01-28		NoeG			Initial
1.0.1		2020-04-24		NoeG			Changes added for features management

******************************************************************************/    
    
/* DECLARE THE REQUIRED VARIABLES */
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
    
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	BEGIN TRY
	
		SELECT @Error = 0, @ErrorMessage = '';
     
		SELECT	ctPM.PK_Country, ct.CountryCode, ct.CountryName, ct.CountryCodeISO
				, isnull(ctPM.HasDSAccess,0) HasDSAccess
				, isnull(ctPM.AllowCorporateEvent,0) AllowCorporateEvent
				, isnull(ctPM.AllowDistributorEvents,0) AllowDistributorEvents
				, isnull(ctPM.AllowDistributorPromos,0) AllowDistributorPromos
				, isnull(ctPM.AllowGTA,0) AllowGTA 
				, isnull(ctPM.AllowPmPromos,0) AllowPmPromos 
				, isnull(ctPM.AllowTrackProgress,0) AllowTrackProgress
				, isnull(ctPM.AllowRegistration,0) AllowRegistration
				
		FROM	CountryPM ctPM WITH (NOLOCK)
				INNER JOIN PubEvents.dbo.dimCountry ct WITH (NOLOCK)
					ON ctPM.PK_Country = ct.PK_Country
	
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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;

