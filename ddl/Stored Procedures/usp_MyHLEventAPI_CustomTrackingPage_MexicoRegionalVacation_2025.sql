CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_MexicoRegionalVacation_2025]
	 --Mandatory parameters
	 @PK_Event INT = 198082
	,@LocaleCode CHAR(5)

	-- Optional Parameters
	,@DistributorID VARCHAR(10) 

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoRegionalVacation_2025

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoRegionalVacation_2025
					 	 @DistributorID = N'11139625'
					 	,@PK_Event = 198082
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2024-02-14	alejandramed	Intitial
2	2024-09-10	alejandramed	User Story 1356393: 25005 - Mexico Regional Vacation 2025- Umbraco Custom Data V2
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	/* DECLARE THE REQUIRED VARIABLES */
	
	DECLARE @PK_Distributor INT
	DECLARE @PK_Locale INT
	DECLARE @PK_DefaultLocale INT

BEGIN TRY

	BEGIN -- Body

		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END

	
		-- Variables for json values

		DECLARE @TeamFreezeDate DATE,
			@IsJulyDoubleBonusActive BIT, 
			@IsOctoberDoubleBonusActive BIT, 
			@IsNewDSBonusActive bit, 
			@Parameters NVARCHAR(MAX) = ''

		-- Getting parameters from qualifications execution setup

		SELECT @Parameters = [Parameters] FROM [Shared].[QualsExecParams] WITH (NOLOCK) WHERE PK_Event = @PK_Event

		-- Getting parameters values for json
		SELECT  
			@TeamFreezeDate = teamFreezeDate,
			@IsJulyDoubleBonusActive = isJulyDoubleBonusActive,
			@IsOctoberDoubleBonusActive = isOctoberDoubleBonusActive,
			@IsNewDSBonusActive = isNewDSBonusActive
		FROM OPENJSON(@Parameters)
		WITH (
				
				teamFreezeDate DATE '$.teamFreezeDate',
				isJulyDoubleBonusActive BIT '$.isJulyDoubleBonusActive',
				isOctoberDoubleBonusActive BIT '$.isOctoberDoubleBonusActive',
				isNewDSBonusActive BIT '$.isNewDSBonusActive'
			)
	 
		-- Default values
		SET @PK_Event = IIF(@PK_Event IS NULL,198082, @PK_Event)
		SET @TeamFreezeDate = IIF(@TeamFreezeDate IS NULL,'2024-01-16', @TeamFreezeDate)
		SET @IsJulyDoubleBonusActive = IIF(@IsJulyDoubleBonusActive IS NULL,1, @IsJulyDoubleBonusActive)
		SET @IsOctoberDoubleBonusActive = IIF(@IsOctoberDoubleBonusActive IS NULL,1, @IsOctoberDoubleBonusActive)
		SET @IsNewDSBonusActive = IIF(@IsNewDSBonusActive IS NULL,1, @IsNewDSBonusActive)

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

		----------------------------------------------------------------------------------------------------
		
		--Result set 1
		SELECT 		
			D.[PK_Distributor],
			@DistributorID AS [DistributorID],
			D.[DSCurrentTeam],
			D.[DSSubTeam], 
			B.[New DS Bonus] AS [New DS Bonus],
			B.[TotalNewDS] AS [TotalNewDS],
			B.[JULY DOUBLE VOLUME PROMOTION] AS [JULY DOUBLE VOLUME PROMOTION],
			B.[OCTOBER DOUBLE VOLUME PROMOTION] AS [OCTOBER DOUBLE VOLUME PROMOTION],
			Q.Q01,
			Q.Q02,
			Q.Q03,
			Q.Q04,
			Q.Q05,
			Q.Q06,
			Q.Q07,
			Q.Q08,
			Q.Q09,
			Q.Q10,
			Q.Q11,
			Q.Q12,
			Q.Q13,
			Q.Q14,
			Q.Q15,
			Q.Q16,
			Q.E01,
			Q.E02,
			@IsJulyDoubleBonusActive AS [IsJulyDoubleBonusActive],
			@IsOctoberDoubleBonusActive AS [IsOctoberDoubleBonusActive],
			@IsNewDSBonusActive AS [IsNewDSBonusActive]
		FROM [dbo].[WRK_25005_DSDetails] AS D WITH (NOLOCK) 
		INNER JOIN [Event].[DSQual] AS Q WITH (NOLOCK)
			ON D.PK_Distributor = Q.PK_Distributor AND Q.PK_Event = @PK_Event
		LEFT JOIN [dbo].[WRK_25005_BonusSummary] AS B WITH (NOLOCK)
			ON D.PK_Distributor = B.PK_Distributor
		WHERE  D.PK_Distributor = @PK_Distributor 
		

	END --Body 

	SET @Error = @Error + @@ERROR      
		

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
	END CATCH
END