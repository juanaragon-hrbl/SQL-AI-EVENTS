CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_IndiaVacation2025]
	-- Mandatory parameters
	 @PK_Event INT = 199969
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_IndiaVacation2025

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_IndiaVacation2025
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 199969
						,@LocaleCode = 'es-ES'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.WRK_IndiaVacation2025
Event.DSQual

VERSIONS
----------------------------------------------------------------------------------
1		2024-05-27	JonathanO	Intitial

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

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event


/******************************************************************************
******************************************************************************/
SELECT	
	WE.PK_Distributor,
	WE.Q01,	WE.Q02,	WE.Q03,	WE.Q04,	WE.Q05,
	WE.Q06,	WE.Q07,	WE.Q08,	WE.Q09,	WE.Q10,
	WE.Q11, WE.Q12, WE.Q13, WE.Q14, WE.Q15,

		 WQ.DistributorID  
		,WQ.DSCurrentTeam	
		,WQ.DSSubTeam
		,CASE WHEN WQ.DSSPTeam = 'SP'						THEN 1 ELSE 0 END IsFQS
		,WQ.SPQualDate	
		,WQ.sCountryCode
		,WQ.IsAWT
		,WQ.TotalVolumeAccumulated
		,WQ.AWTBonus
		,WE.Q07 AS FirstLineRetention
		,CASE WHEN WQ.IsAWT = 1								THEN 1 ELSE 0 END IsAWTQualifiedOne
		,CASE WHEN WQ.IsAWT = 1 AND WQ.AWTBonus >= 5000		THEN 1 ELSE 0 END IsAWTQualifiedTwo
		,CASE WHEN WQ.IsAWT = 1 AND WQ.AWTBonus >= 15000	THEN 1 ELSE 0 END IsAWTQualifiedThree
FROM
	Event.DSQual			WE	WITH (NOLOCK)
INNER JOIN
	WRK_IndiaVacation2025	WQ	WITH (NOLOCK)
ON
	WE.PK_Distributor = WQ.PK_Distributor
AND
	WE.PK_Distributor = @PK_Distributor
AND
	WE.PK_Event = @PK_Event

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