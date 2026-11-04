
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMLDWApr19]
	-- Mandatory parameters
	 @PK_Event INT = 67640
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) = '113507859'

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.[usp_MyHLEventAPI_CustomTrackingPage_NAMLDWApr19]

USE:		
		DECLARE @e int, @em varchar(4000)   
        
        EXEC dbo.[usp_MyHLEventAPI_CustomTrackingPage_NAMLDWApr19]
				@DistributorID = N'2222222222'
			,@PK_Event = 67640
			,@LocaleCode = 'en-US'
			,@Error = @e OUTPUT				-- @e must be defined in the local call   
			,@ErrorMessage = @em OUTPUT		-- @em must be defined in the local call   
			,@IsDevQA = 1  

		Print @em  

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.v_AGGFQS_ID, 


VERSIONS
----------------------------------------------------------------------------------
1	2019-02-12	SushmaA	Intitial
1.1	2019-08-14		NoeG		Refactor code (SRE)
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/* DECLARE THE REQUIRED VARIABLES */
		DECLARE @PK_Distributor INT
		DECLARE @PK_Locale INT
		DECLARE @PK_DefaultLocale INT

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event


		/******************************************************************************
			  update Qualification
		******************************************************************************/
		SELECT 
			TotalNewFQS, 
			TotalNewFQS*2500 AS TotalFQSBonus,
			TotalNewDAP AS TotalDAP,
			TotalNewDAP*2500 AS TotalDAPBonus
		FROM 
			dbo.WRK_NAM_FSL_LDW_Apr2019 WITH (NOLOCK)
		WHERE
			PK_Distributor = @PK_Distributor

	-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

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

