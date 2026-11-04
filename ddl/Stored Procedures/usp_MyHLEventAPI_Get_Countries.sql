
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_Countries]
		-- Error Parameters
		@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Get_Countries

USE:		
			DECLARE @e int, @em varchar(4000)

			EXEC dbo.usp_MyHLEventAPI_Get_Countries
					@Error = @e OUTPUT  -- @e must be defined in the local call   
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Get the Region - Country Dropdown

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2014-12-09		SandhyaP 				Initial
2	2019-08-14		NoeG					Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************/
BEGIN

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT
			 C.sCountryCodeISO As Countrycode
			,C.sCountryName As CountryName
			,'R' + C.sRegionCode  As RegionCode
			,C.sRegionLabel As RegionName
		FROM
			dbo.v_countries C
		WHERE
			C.sCountryCodeISO IS NOT NULL
			AND 
			C.sCountryCodeISO IN ('US', 'CA')
		ORDER BY
			C.sCountryName

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
GO

