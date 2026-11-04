CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMTabTeam_2024]
	-- Mandatory parameters
	 @PK_Event INT = 193219
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMTabTeam_2024

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMTabTeam_2024
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 193219
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.v_AGGFQS_ID, 


VERSIONS
----------------------------------------------------------------------------------
1	2022-11-08	JonathanO	Intitial
2	2023/09/12	JonathanO	BRDv3 including bonus

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

	;WITH HighestTeam(PK_Distributor, nEventTypeLID) AS
	(
	 SELECT        
		  H.nDistributorIDFK,        
		  MAX(nEventTypeLID) AS nEventTypeLID        
		 FROM dbo.v_DistributorHistory H   
		 INNER JOIN WRK_NAMTabTeam_2024 SM WITH (NOLOCK) 
		 ON H.nDistributorIDFK = SM.PK_Distributor  
		 WHERE   
		 H.dThrough = '2049-12-31'        
		  AND         
		  H.nEventTypeLID BETWEEN 225 AND 241     
		  GROUP BY nDistributorIDFK
	),
	HighestTeamDate(PK_Distributor, TeamDate) AS
	(
		 SELECT        
		  H.nDistributorIDFK,        
		  MAX(H.dFrom)  TeamDate     
		 FROM dbo.v_DistributorHistory H   
		 JOIN HighestTeam SM 
		 ON H.nDistributorIDFK = SM.PK_Distributor  
		 WHERE   
		  H.dThrough = '2049-12-31'        
		  AND         
		  H.nEventTypeLID = SM.nEventTypeLID   
		  GROUP BY nDistributorIDFK
	)

	SELECT
		 W.PK_Distributor
		,W.DistributorID
		,W.DSCurrentTeam
		,W.SCountryCode
		,W.IsQ01 AS IsTAB
	    ,W.IsQ03 AS IsQualifiedtoPTVacation
	    ,HD.TeamDate AS TeamQualificationDate
	    ,(W.TVPJanDec24+W.ROsJanDec24) AS TotalVacationPoints
	    ,W.TVPJanDec24 AS TotalVolumePoints
		,[SEPTEMBER DOUBLE VOLUME]
	FROM 
		WRK_NAMTabTeam_2024	W WITH (NOLOCK)
	LEFT JOIN
		HighestTeamDate HD
	ON 
		HD.PK_Distributor = W.PK_Distributor
	WHERE
		W.PK_Distributor = @PK_Distributor


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