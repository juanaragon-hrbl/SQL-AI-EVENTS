CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Save_CountryPM]
		-- Mandatory Parameters
		@PK_Country					int
		,@HasDSAccess				bit
		,@AllowCorporateEvent		bit
		,@AllowDistributorEvents	bit
		,@AllowDistributorPromos	bit
		,@AllowGTA					bit
		,@AllowPmPromos				bit
		,@AllowTrackProgress		bit
		,@AllowRegistration			bit
		
		-- Optional Parameters

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:     dbo.usp_MyHLEventAPI_Save_CountryPM
USE:
				DECLARE @e int, @em varchar(4000)

				EXEC [dbo].[usp_MyHLEventAPI_Save_CountryPM]
					@PK_Country					= 260003
					,@HasDSAccess				= 1
					,@AllowCorporateEvent		= 1
					,@AllowDistributorEvents	= 1
					,@AllowDistributorPromos	= 1
					,@AllowGTA					= 1
					,@AllowPmPromos				= 1
					,@AllowTrackProgress		= 1
					,@AllowRegistration			= 1

					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION: Inserts or Updates record into dbo.CountryPM
				
NOTES:              


DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1.0.0		2020-02-10		NoeG			Initial
1.0.1		2020-04-24		NoeG			Changes added for features management

******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON      
	
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
	
	SELECT @Error = 0, @ErrorMessage = ''
	
	BEGIN TRY
		MERGE CountryPM AS t
			USING (
				SELECT	@PK_Country AS PK_Country
						,@HasDSAccess AS HasDSAccess
						,@AllowCorporateEvent AS AllowCorporateEvent
						,@AllowDistributorEvents AS AllowDistributorEvents
						,@AllowDistributorPromos AS AllowDistributorPromos
						,@AllowGTA AS AllowGTA
						,@AllowPmPromos AS AllowPmPromos
						,@AllowTrackProgress AS AllowTrackProgress
						,@AllowRegistration AS AllowRegistration
				) AS s ON (t.PK_Country = @PK_Country)
			WHEN MATCHED THEN
				UPDATE SET
						t.[HasDSAccess] = @HasDSAccess
						,t.[AllowCorporateEvent] = @AllowCorporateEvent	
						,t.[AllowDistributorEvents] = @AllowDistributorEvents
						,t.[AllowDistributorPromos] = @AllowDistributorPromos
						,t.[AllowGTA] = @AllowGTA				
						,t.[AllowPmPromos] = @AllowPmPromos			
						,t.[AllowTrackProgress] = @AllowTrackProgress	
						,t.[AllowRegistration] = @AllowRegistration
			WHEN NOT MATCHED THEN
				INSERT (
						[PK_Country]
						,[HasDSAccess]
						,[AllowCorporateEvent]						
						,[AllowDistributorEvents]
						,[AllowDistributorPromos]
						,[AllowGTA]
						,[AllowPmPromos]
						,[AllowTrackProgress]
						,[AllowRegistration]
				)
				VALUES (
						@PK_Country
						,@HasDSAccess
						,@AllowCorporateEvent	
						,@AllowDistributorEvents
						,@AllowDistributorPromos
						,@AllowGTA				
						,@AllowPmPromos			
						,@AllowTrackProgress
						,@AllowRegistration	
				)
		;	-- MERGE CountryPM

	END TRY
	BEGIN CATCH
       SET @Error = ERROR_NUMBER();
       SET @ErrorMessage = ERROR_MESSAGE();
       SET @StoredProcedure = ERROR_PROCEDURE();

	   IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

       -- UPDATE ERROR LOG
       EXEC dbo.usp_Utility_UpdateErrorLog 
                    @ProcedureName = @StoredProcedure
                    ,@ErrorNumber = 3
                    ,@ErrorMessage = @ErrorMessage
                    ,@SQLErrorCode = @Error
                    ,@SQLErrorMsg = @ErrorMessage; 
	END CATCH;

END;
GO
