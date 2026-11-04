CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMLDWOct20_JMTT]
	-- Mandatory parameters
	 @PK_Event INT = 76847
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMLDWOct20_JMTT

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMLDWOct20_JMTT
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 76841
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.v_AGGFQS_ID, 


VERSIONS
----------------------------------------------------------------------------------
1	2020-02-28	JonathanO	Intitial
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
			  update Qualification
		******************************************************************************/
		SELECT
			(TVPBonusJul20-TVPJul20)	AS TVPBonusJul20,
			QSQualDate,
			SPQualDate
		FROM 
			dbo.WRK_NAMLDWVirtual_JMTT_Oct2020Points WITH (NOLOCK)
		WHERE
			PK_Distributor = @PK_Distributor


		/******************************************************************************
			UPDATE MBIDsPoints for the tracker
		******************************************************************************/
		IF OBJECT_ID('tempdb..#MBIDsPoints')	IS NOT NULL DROP TABLE #MBIDsPoints
		
		CREATE TABLE #MBIDsPoints(
			 PK_Distributor		INT,
			 DistributorID		VARCHAR(20),          
			 dRoyaltyMonth		VARCHAR(12),           
			 PPV				MONEY,
			 TV					MONEY,
			 DLV				MONEY,
		)
		INSERT  INTO #MBIDsPoints
		SELECT
			PK_Distributor,
			DistributorID,
			'01-Jul-2020'    dRoyaltyMonth,
			PPVJul20		 PPV,			
			TVPJul20		 TV,			
			DLVJul20		 DLV			
		FROM	WRK_NAMLDWVirtual_JMTT_Oct2020Points	WITH (NOLOCK)
		
		INSERT  INTO #MBIDsPoints
		SELECT
			PK_Distributor,
			DistributorID,
			'01-Aug-2020'    dRoyaltyMonth,
			PPVAug20		 PPV,			
			TVPAug20		 TV,			
			DLVAug20		 DLV			
		FROM	WRK_NAMLDWVirtual_JMTT_Oct2020Points	WITH (NOLOCK)
		
		INSERT  INTO #MBIDsPoints
		SELECT
			PK_Distributor,
			DistributorID,
			'01-Sep-2020'    dRoyaltyMonth,
			PPVSep20		 PPV,			
			TVPSep20		 TV,			
			DLVSep20		 DLV			
		FROM	WRK_NAMLDWVirtual_JMTT_Oct2020Points	WITH (NOLOCK)
	
	
		SELECT	
			  PK_Distributor
			 ,DistributorID	 
			 ,dRoyaltyMonth	  
			 ,PPV			
			 ,TV				
			 ,DLV
		FROM	#MBIDsPoints
		WHERE	PK_Distributor = @PK_Distributor



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