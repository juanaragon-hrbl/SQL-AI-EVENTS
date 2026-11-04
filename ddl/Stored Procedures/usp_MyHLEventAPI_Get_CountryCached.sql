CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_CountryCached]
		-- Error Parameters
		@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS 
BEGIN

/******************************************************************************
OBJECT:			dbo.[usp_MyHLEventAPI_Get_CountryCached]

USE:	
		Declare @e int, @em varchar(4000)
        EXEC [usp_MyHLEventAPI_Get_CountryCached]
			@Error = @e OUTPUT  /* @e must be defined in the local call */
			,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
			,@IsDevQA = 1  

		Print @em  

DESCRIPTION:	Get the Region/Country for display in drop down 

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.v_Countries

VERSIONS
--------------------------------------------------------------------
1.0		2014-11-03				SushmaA				Cache implementation for Search CR
2.0		2019-08-14				NoeG				Refactor code (SRE)

********************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	/* ***************** SonarQube check 87 and 88 - Output parameters should be assigned 
		SRE changes added
	*/

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE @tbl TABLE (code nVARCHAR(3), name nVARCHAR(100), RegionCode VARCHAR(10), RegionName VARCHAR(100))

		/******************************************************************************
			DROPDOWN FOR COUNTRIES
		******************************************************************************/

		INSERT @tbl (Code, Name, RegionCode, RegionName)
			  SELECT DISTINCT sCountryCodeISO, sCountryName, 'R' + sRegionCode AS [RegionCode], sRegionLabel AS [RegionName]  FROM v_Countries WHERE sCountryCodeISO IS NOT NULL  ORDER BY sCountryName

		SELECT Code, Name, RegionCode, RegionName FROM @tbl WHERE code IS NOT NULL

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
