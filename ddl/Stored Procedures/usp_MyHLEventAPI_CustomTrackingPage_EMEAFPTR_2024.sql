CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_EMEAFPTR_2024]
	-- Mandatory parameters
	 @PK_Event INT = 198079
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) = '113507859'
	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA int = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEAFPTR_2024

USE:	        
		DECLARE @e int, @em varchar(4000)
		
        EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEAFPTR_2024
				@DistributorID = N'10Y2137058'
			,@PK_Event = 198079
			,@LocaleCode = 'es-ES'
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
1		2024-06-03		JuanGue		Intitial
1.1		2024-06-11		JuanGue		Variables unused removed
1.2		2024-06-12		JuanGue		Removing code smells
1.3		2024-06-14		JuanGue		Changing the IsDevQA as INT
1.4		2024-07-02		JuanGue		Adding mandatory params like @LocaleCode required by the tracker platform
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
			THROW 60000, N'Unit test Error', 1
		END
		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

		IF @IsDevQA = 0 AND EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_EMEAFPTR_2024' and type='U')
		BEGIN

			SELECT	
				WQ.PK_Distributor
				,WQ.DistributorID
				,WQ.DSCurrentTeam		     
				,WQ.DSSubTeam			       
				,WQ.DSSPTeam	
				,WQ.dSPQualDate
				,WQ.Team_QualDate 		        
				,WQ.CountryCode	
				,WQ.IsFromList				
				,WQ.IsTicketPurchaser	
				,WQ.[GT_QualDate]		
				,WQ.[GP_QualDate]		
				,WQ.IsFromCOP			
				,WQ.IsWWCCFC			
				,WQ.RONov23			
				,WQ.RODec23			
				,WQ.ROJan24			
				,WQ.ROFeb24			
				,WQ.ROMar24			
				,WQ.ROApr24			
				,WQ.ROMay24			
				,WQ.ROJun24			
				,WQ.ROJul24			
				,WQ.ROAug24			
				,WQ.ROSep24			
				,WQ.ROOct24	
				,WQ.Stones
				,WE.Q01,WE.Q02,	WE.Q03,	WE.Q04,	WE.Q05
				,WE.Q06,WE.Q07,	WE.Q08,	WE.Q09,	WE.Q10
				,WE.Q11,WE.Q12,	WE.Q13,	WE.Q14,	WE.Q15
				,WE.Q16,WE.Q17,	WE.Q18,	WE.Q19,	WE.Q20
				,WE.Q21,WE.Q22,	WE.Q23,	WE.Q24,	WE.Q25
				,WE.Q26,WE.Q27,	WE.Q28,	WE.Q29

				,WE.Q30 -- List ID: 60089 Qualifies the Upline to Q13    Q13 = Q30 & ~Q31
				,WE.Q31 -- List ID: 60090 Unqualifies the Upline to Q13
				,WE.Q32 -- List ID: 60092 Qualifies the Upline to Q14	 Q14 = Q32 & ~Q33
				,WE.Q33 -- List ID: 60093 Unqualifies the Upline to Q14
				,WE.Q40,WE.Q41,	WE.Q42,	WE.Q43,	WE.Q44
				,WE.E01,WE.E02, WE.E03, WE.E04, WE.E05
				,WE.E06,WE.E07,	WE.E08,	WE.E09, WE.E10 
				,WE.E11, WE.E12,WE.E13,	WE.E14, WE.E15 
				,WE.E16, WE.E17,WE.E18,	WE.E19, WE.E20 
			FROM
				[Event].DSQual WE (NOLOCK)
			INNER JOIN WRK_EMEAFPTR_2024 WQ (NOLOCK)
				ON	WE.PK_Distributor = WQ.PK_Distributor
			WHERE 
				@LocaleCode IS NOT NULL 
				AND WE.PK_Distributor = @PK_Distributor 
				AND WE.PK_Event = @PK_Event
			
		END

	END -- Body

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