CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_MexicoFSL_May2024]
	-- Mandatory parameters
	 @PK_Event INT = 198554
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoFSL_May2024

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoFSL_May2024
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 198554
						,@LocaleCode = 'es-ES'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

VERSIONS
----------------------------------------------------------------------------------
1	2024-01-04	JonathanO	Intitial
1.1	2024-01-04	JonathanO	Adding downline detail

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
	WE.Q11,

	 WQ.SPQualDate
	,WQ.sTeamQualDate

	,WQ.TVPJan24	           
	,WQ.TVPFeb24	           
	,WQ.TVPMar24	           
	,WQ.TVPApr24	           

	,WQ.DLVJan24				
	,WQ.DLVFeb24				
	,WQ.DLVMar24				
	,WQ.DLVApr24				

	,WQ.PPVJan24				
	,WQ.PPVFeb24				
	,WQ.PPVMar24				
	,WQ.PPVApr24
	
	,WQ.HasTicketAssigned

	,WQ.NoDL
FROM
	Event.DSQual			WE	WITH (NOLOCK)
INNER JOIN
	WRK_MexicoFSL_May2024	WQ	WITH (NOLOCK)
ON
	WE.PK_Distributor = WQ.PK_Distributor
AND
	WE.PK_Distributor = @PK_Distributor
AND
	WE.PK_Event = @PK_Event

SELECT
	 PK_Distributor AS UplinePK_Distributor
	,DistributorID	AS UplineDistributorID
	,PK_DSDownline
	,DownlineID
	,FirstName
	,LastName
	,sTypeDL
	,SPQualDate
	,DSLevel
	,TotalDownlines
	,CASE WHEN TotalDownlines >= 2 THEN 1 ELSE 0 END AS [Counts For Qualification]
FROM
	WRK_MexicoFSL_May2024_Downlines WITH (NOLOCK)
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
	END CATCH

END