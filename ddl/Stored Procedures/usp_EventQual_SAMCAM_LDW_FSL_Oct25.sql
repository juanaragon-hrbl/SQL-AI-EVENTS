CREATE PROCEDURE [dbo].[usp_EventQual_SAMCAM_LDW_FSL_Oct25]
	@Parameters NVARCHAR(MAX) = NULL
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_SAMCAM_LDW_FSL_Oct25

	USE:	
	
			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			
			SET @param = N'{
				"currentDatetime": null,
				"pK_Event_PM":203527,
				"pK_Event_PE":203530,
				"pK_Event_AR_UY":203531,
				"pK_Event_CI":203532,
				"pK_Event_CO":203533,
				"pK_Event_BL":203534,
				"pK_Event_EC":203535,
				"pK_Event_GT_SV_HN_NI_CR":203536,
				"pK_Event_VE":203538,
				"pK_Event_DR":203539,
				"step":11,
				"qualPeriodJun25":"2025-06-01",
				"qualPeriodSep25":"2025-09-01",
				"qualPeriodJul25":"2025-07-01",
				"qualPeriodOct25":"2025-10-01",
				"newfQSqualDateStart":"2025-07-01",
				"newfQSqualDateEnd":"2025-10-31",
				"qSActualQualDateStart":"2025-10-01",
				"qSActualQualDateEnd":"2025-10-31",
				"newWTQualDateStart":"2025-07-01",
				"newWTQualDateEnd":"2025-10-31",
				"aWTNonTABQualDateStart":"2025-06-01",
				"aWTNonTABQualDateEnd":"2025-09-30",
				"bonusApplicableFrom":12,
				"bonusApplicableTo":20,
				"countries":"PM,PE,AR,UY,CI,CO,BL,EC,GT,SV,HN,NI,CR,VE,DR",
				"isDoubleBonusActive":1,
				"doubleBonusDateStart":"2025-06-01",
				"doubleBonusDateEnd":"2025-06-01",
				"isNewFQSBonusActive ":1,
				"newFQSBonusDateStart":"2025-07-01",
				"newFQSBonusDateEnd":"2025-10-01",
				"newQPDateStart":"2025-07-01",
				"newQPDateEnd":"2025-10-31",
				"vipPremiumBonusDateStart":202506,
				"vipPremiumBonusDateEnd":202509
			}'

			EXEC dbo.usp_EventQual_SAMCAM_LDW_FSL_Oct25 @Parameters= @param, @IsDevQA = 0, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
			SELECT @e AS [Error], @em AS [ErrorMessage]

			GO

	DESCRIPTION: 

	NOTES:	

	DEBUG TABLES:	
		
	DEPENDENCIES:
	
	WORK TABLES (WRK):

	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2025-06-24			juangue			Initial
	1.0.2	2025-07-16			JuanGue			#1420934 Incorrect qualifiers Outside COP: DS id qualified to E6 & E1
	1.0.3	2025-07-21			JuanGue			#1421454 DsQual Duplicates
	1.0.4	2025-07-22			JuanGue			#1420787 DS ID not qualified to E5 by Q2
	1.0.5	2025-07-30			JuanGue			#1422366 E2 Incorrect qualifiers by Q4 + E1
	1.0.6	2025-08-04			JuanGue			#1420934 Incorrect qualifiers Outside COP: DS id qualified to E6 & E1
	1.0.7	2025-08-04			JuanGue			#1420786 DS ID not qualified to E2 by Q4
	2.0.0	2025-08-06			JuanGue			BRD v2.0
	2.0.1	2025-08-11			JuanGue			#1423035 DS ID not qualified to E5 by Q3
	2.0.2	2025-08-11			JuanGue			#1423039 DS ID not qualified to E6 by Q24 List 66067 List 66062
	2.0.3	2025-08-11			JuanGue			#1423009 E2 Ds id not qualified by Q10
	2.0.4	2025-08-11			JuanGue			#1422926 E3 Incorrect qualifiers by Q4 + E1
	3.0.0	2025-08-12			JuanGue			BRD v3.0
	3.0.1	2025-08-13			JuanGue			#1423642 E3 DS id not qualified by Q4 + E1
	3.0.2	2025-08-19			JuanGue			#1423952 #1423960 #1423967 #1423966 #1423965
	3.0.3	2025-08-20			JuanGue			#1424182 #1424183
	4.0.0	2025-09-01			JuanGue			BRD v4.0
***********************************************************************************************************************************/

	IF (@IsDevQA = 3)
	BEGIN
		
		DROP TABLE IF EXISTS ##DSQualPoints_jgue

		CREATE TABLE ##DSQualPoints_jgue(
			[PK_Distributor] [int] NULL,
			[PK_Event] [int] NULL,
			[QualificationNumber] [int] NULL,
			[Part] [int] NULL,
			[QualDate] [datetime2](7) NULL
		)
		
		DROP TABLE IF EXISTS ##tmp_DS_jgue

		CREATE TABLE ##tmp_DS_jgue
		(
			[PK_Event] INT NULL,
			[PK_Distributor]  INT NULL, 
			[StartDate]  INT NULL,
			[EndDate]  INT NULL
		)
		
		DROP TABLE IF EXISTS ##Event_SetupEventQualification_jgue

		CREATE TABLE ##Event_SetupEventQualification_jgue(
			[PK_Event] [int] NULL,
			[QualificationNumber] [int] NULL,
			[Part] [int] NULL,
			[MetricType] [varchar](50) NULL,
			[dStartDate] [datetime2](7) NULL,
			[dEndDate] [datetime2](7) NULL,
			[Frequency] [int] NULL,
			[Consecutive] [bit] NULL,
			[Accumulated] [bit] NULL,
			[MinPoints] [money] NULL,
			[GoalPoints] [money] NULL,
			[Countries] [varchar](max) NULL,
			[Bonus] [bit] NULL,
			[QSVolume] [bit] NULL,
			[QSVolumePercentage] [int] NULL
		)
		
		DROP TABLE IF EXISTS ##tmp_DSQualDef_jgue

		CREATE TABLE ##tmp_DSQualDef_jgue
		(
			PK_Event			int,
			PK_Distributor		int,
			dStartDate			datetime2,
			dEndDate			datetime2,
			iStartDate			int,
			iEndDate			int,
			[dSPQualDate]		datetime2,
			[iSPQualDate]		int,
			Frequency			int,
			Consecutive			bit,
			Accumulated			bit,
			[MetricType]		[varchar](50) NULL,
			GoalPoints			money,
			MinPoints			money,
			QualificationNumber int,
			Part				int,
			PK_AssociatedID		int,
			Countries			varchar(max),
			Bonus				bit,
			[QSVolume]			bit,
			[QSVolumePercentage]		int
	
		)

		DROP TABLE IF EXISTS ##Event_DSPoints_jgue

		CREATE TABLE ##Event_DSPoints_jgue(
			[PK_Distributor] [int] NULL,
			[PK_Event] [int] NULL,
			[PK_Country] [int] NULL,
			[RoyaltyMonth] [int] NULL,
			[MetricType] [varchar](20) NULL,
			[PersonalPoints] [money] NULL DEFAULT(0),
			[TransferPoints] [money] NULL DEFAULT(0),
			[MainPoints] [money] NULL DEFAULT(0),
			[Points] [money] NULL,
			[Bonus] [money] NULL DEFAULT(0),
		)

		DROP TABLE IF EXISTS ##DSPointsSummary_jgue

		CREATE TABLE ##DSPointsSummary_jgue
		(
			PK_Event			int,
			PK_Distributor		int,
			RoyaltyMonth		int,
			[MetricType] [varchar](20) NULL,
			PK_Country			int,
			[Points]			money,
			[Bonus]				money,
			[QSVolume]			bit,
			[QSVolumePercentage]		int,
			[iSPQualDate]		int,
			QualificationNumber int,
			Part				int,
			HasBonus			bit,
			[TotalPoints]		money,
			iStartDate			int,
			iEndDate			int,
			Countries			varchar(max)
	
		)

	END

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetDSVolume_jgue] is missing, create it manually' AS [ErrorMessage]
	END

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetQualifier_Points_jgue] is missing, create it manually' AS [ErrorMessage]
	END

	SET NOCOUNT ON;

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY
		
	-- Variables for json values

	DECLARE 
		@PK_Event_PM INT,
		@PK_Event_PE INT,
		@PK_Event_AR_UY INT,
		@PK_Event_CI INT,
		@PK_Event_CO INT,
		@PK_Event_BL INT,
		@PK_Event_EC INT,
		@PK_Event_GT_SV_HN_NI_CR INT,
		@PK_Event_VE INT,
		@PK_Event_DR INT,
		@QualPeriodJun25 DATETIME,
		@QualPeriodSep25 DATETIME,
		@QualPeriodJul25 DATETIME,
		@QualPeriodOct25 DATETIME,
		@NewFQSQualDateStart DATETIME,
		@NewFQSQualDateEnd DATETIME,
		@QSActualQualDateStart DATE,
		@QSActualQualDateEnd DATE,
		@NewWTQualDateStart DATE,
		@NewWTQualDateEnd DATE,
		@AWTNonTABQualDateStart DATETIME,
		@AWTNonTABQualDateEnd DATETIME,
		@Step INT,
		@BonusApplicableFrom INT,
		@BonusApplicableTo INT,
		@Countries VARCHAR(MAX),
		@IsNewFQSBonusActive BIT,
		@NewFQSBonusDateStart DATETIME,
		@NewFQSBonusDateEnd DATETIME,
		@IsDoubleBonusActive BIT,
		@DoubleBonusDateStart DATETIME,
		@DoubleBonusDateEnd DATETIME,
		@NewQPDateStart DATETIME,
		@NewQPDateEnd DATETIME,
		@VipPremiumBonusDateStart INT,
		@VipPremiumBonusDateEnd	INT,
		@CurrentDatetime DATETIME

	-- Getting parameters values for json

	SELECT   
		@PK_Event_PM 				= g.pK_Event_PM,
		@PK_Event_PE 				= g.pK_Event_PE,
		@PK_Event_AR_UY 			= g.pK_Event_AR_UY,
		@PK_Event_CI 				= g.pK_Event_CI,
		@PK_Event_CO				= g.pK_Event_CO,
		@PK_Event_BL				= g.pK_Event_BL,
		@PK_Event_EC 				= g.pK_Event_EC,
		@PK_Event_GT_SV_HN_NI_CR	= g.pK_Event_GT_SV_HN_NI_CR,
		@PK_Event_VE				= g.pK_Event_VE,
		@PK_Event_DR				= g.pK_Event_DR,
		@QualPeriodJun25			= g.qualPeriodJun25,		
		@QualPeriodSep25			= g.qualPeriodSep25,		
		@QualPeriodJul25 			= g.qualPeriodJul25, 		
		@QualPeriodOct25 			= g.qualPeriodOct25,		
		@NewFQSQualDateStart 		= g.newFQSQualDateStart, 	
		@NewFQSQualDateEnd 			= g.newFQSQualDateEnd, 		
		@QSActualQualDateStart 		= g.qSActualQualDateStart, 	
		@QSActualQualDateEnd 		= g.qSActualQualDateEnd, 	
		@NewWTQualDateStart 		= g.newWTQualDateStart, 	
		@NewWTQualDateEnd 			= g.newWTQualDateEnd, 		
		@AWTNonTABQualDateStart		= g.aWTNonTABQualDateStart, 
		@AWTNonTABQualDateEnd 		= g.aWTNonTABQualDateEnd, 	
		@Step 						= g.step, 					
		@BonusApplicableFrom 		= g.bonusApplicableFrom, 	
		@BonusApplicableTo 			= g.bonusApplicableTo, 		
		@Countries 					= g.countries, 				
		@IsNewFQSBonusActive 		= g.isNewFQSBonusActive, 	
		@NewFQSBonusDateStart 		= g.newFQSBonusDateStart, 	
		@NewFQSBonusDateEnd 		= g.newFQSBonusDateEnd, 	
		@IsDoubleBonusActive 		= g.isDoubleBonusActive, 	
		@DoubleBonusDateStart 		= g.doubleBonusDateStart, 	
		@DoubleBonusDateEnd 		= g.doubleBonusDateEnd, 	
		@NewQPDateStart 			= g.newQPDateStart, 	
		@NewQPDateEnd 				= g.newQPDateEnd,
		@VipPremiumBonusDateStart	= g.vipPremiumBonusDateStart,
		@VipPremiumBonusDateEnd		= g.vipPremiumBonusDateEnd,
		@CurrentDatetime			= g.currentDatetime

	FROM OPENJSON(@Parameters)
	WITH ( 
			pK_Event_PM INT '$.pK_Event_PM',
			pK_Event_PE INT '$.pK_Event_PE',
			pK_Event_AR_UY INT '$.pK_Event_AR_UY',
			pK_Event_CI INT '$.pK_Event_CI',
			pK_Event_CO INT '$.pK_Event_CO',
			pK_Event_BL INT '$.pK_Event_BL',
			pK_Event_EC INT '$.pK_Event_EC',
			pK_Event_GT_SV_HN_NI_CR INT '$.pK_Event_GT_SV_HN_NI_CR',
			pK_Event_VE INT '$.pK_Event_VE',
			pK_Event_DR INT '$.pK_Event_DR',
			qualPeriodJun25 DATETIME '$.qualPeriodJun25',
			qualPeriodSep25 DATETIME '$.qualPeriodSep25',
			qualPeriodJul25 DATETIME '$.qualPeriodJul25',
			qualPeriodOct25 DATETIME '$.qualPeriodOct25',
			newFQSQualDateStart DATETIME '$.newFQSQualDateStart',
			newFQSQualDateEnd DATETIME '$.newFQSQualDateEnd',
			qSActualQualDateStart DATE '$.qSActualQualDateStart',
			qSActualQualDateEnd DATE '$.qSActualQualDateEnd',
			newWTQualDateStart DATE '$.newWTQualDateStart',
			newWTQualDateEnd DATE '$.newWTQualDateEnd',
			aWTNonTABQualDateStart DATETIME '$.aWTNonTABQualDateStart',
			aWTNonTABQualDateEnd DATETIME '$.aWTNonTABQualDateEnd',
			qSActualQualDateStart DATE '$.qSActualQualDateStart',
			qSActualQualDateEnd DATE '$.qSActualQualDateEnd',
			step INT '$.step',
			bonusApplicableFrom INT '$.bonusApplicableFrom',
			bonusApplicableTo INT '$.bonusApplicableTo',
			countries VARCHAR(MAX) '$.countries',
			isNewFQSBonusActive BIT '$.isNewFQSBonusActive',
			newFQSBonusDateStart DATETIME '$.newFQSBonusDateStart',
			newFQSBonusDateEnd DATETIME '$.newFQSBonusDateEnd',
			isDoubleBonusActive BIT '$.isDoubleBonusActive',
			doubleBonusDateStart DATETIME '$.doubleBonusDateStart',
			doubleBonusDateEnd DATETIME '$.doubleBonusDateEnd',
			newQPDateStart DATETIME '$.newQPDateStart',
			newQPDateEnd DATETIME '$.newQPDateEnd',
			vipPremiumBonusDateStart INT '$.vipPremiumBonusDateStart',
			vipPremiumBonusDateEnd	INT '$.vipPremiumBonusDateEnd',
			currentDatetime DATETIME '$.currentDatetime'

		) AS g
	 
	-- Default values

	SET	@PK_Event_PM = IIF(@PK_Event_PM IS NULL,203527, @PK_Event_PM)
	SET	@PK_Event_PE = IIF(@PK_Event_PE IS NULL,203530, @PK_Event_PE)
	SET	@PK_Event_AR_UY  = IIF(@PK_Event_AR_UY IS NULL,203531, @PK_Event_AR_UY)
	SET	@PK_Event_CI = IIF(@PK_Event_CI IS NULL,203532, @PK_Event_CI)
	SET	@PK_Event_CO = IIF(@PK_Event_CO IS NULL,203533, @PK_Event_CO)
	SET	@PK_Event_BL = IIF(@PK_Event_BL IS NULL,203534, @PK_Event_BL)
	SET	@PK_Event_EC = IIF(@PK_Event_EC IS NULL,203535, @PK_Event_EC)
	SET	@PK_Event_GT_SV_HN_NI_CR = IIF(@PK_Event_GT_SV_HN_NI_CR IS NULL,203536, @PK_Event_GT_SV_HN_NI_CR)
	SET	@PK_Event_VE = IIF(@PK_Event_VE IS NULL,203538, @PK_Event_VE)
	SET	@PK_Event_DR = IIF(@PK_Event_DR IS NULL,203539, @PK_Event_DR)	
	SET @Step = IIF(@Step IS NULL,11, @Step)
	SET @QualPeriodJun25 = IIF(@QualPeriodJun25 IS NULL,'2025-06-01', @QualPeriodJun25)
	SET @QualPeriodSep25 = IIF(@QualPeriodSep25 IS NULL,'2025-09-01', @QualPeriodSep25)
	SET @QualPeriodJul25 = IIF(@QualPeriodJul25 IS NULL,'2025-07-01', @QualPeriodJul25)
	SET @QualPeriodOct25 = IIF(@QualPeriodOct25 IS NULL,'2025-10-01', @QualPeriodOct25)
	SET @NewFQSQualDateStart = IIF(@NewFQSQualDateStart IS NULL,'2025-07-01', @NewFQSQualDateStart)
	SET @NewFQSQualDateEnd = IIF(@NewFQSQualDateEnd IS NULL,'2025-10-31', @NewFQSQualDateEnd)
	SET @QSActualQualDateStart = IIF(@QSActualQualDateStart IS NULL,'2025-10-01', @QSActualQualDateStart)
	SET @QSActualQualDateEnd = IIF(@QSActualQualDateEnd IS NULL,'2025-10-31', @QSActualQualDateEnd)
	SET @NewWTQualDateStart = IIF(@NewWTQualDateStart IS NULL,'2025-07-01', @NewWTQualDateStart)
	SET @NewWTQualDateEnd = IIF(@NewWTQualDateEnd IS NULL,'2025-10-31', @NewWTQualDateEnd)
	SET @AWTNonTABQualDateStart = IIF(@AWTNonTABQualDateStart IS NULL,'2025-06-01', @AWTNonTABQualDateStart)
	SET @AWTNonTABQualDateEnd = IIF(@AWTNonTABQualDateEnd IS NULL,'2025-09-30', @AWTNonTABQualDateEnd)
	SET @BonusApplicableFrom = IIF(@BonusApplicableFrom IS NULL,12, @BonusApplicableFrom)
	SET @BonusApplicableTo = IIF(@BonusApplicableTo IS NULL,20, @BonusApplicableTo)
	SET @Countries = IIF(@Countries IS NULL,'PM,PE,AR,UY,CI,CO,BL,EC,GT,SV,HN,NI,CR,VE,DR', @Countries)
	SET @IsDoubleBonusActive = IIF(@IsDoubleBonusActive IS NULL,1, @IsDoubleBonusActive)
	SET @DoubleBonusDateStart = IIF(@DoubleBonusDateStart IS NULL,'2025-06-01', @DoubleBonusDateStart)
	SET @DoubleBonusDateEnd = IIF(@DoubleBonusDateEnd IS NULL,'2025-06-01', @DoubleBonusDateEnd)
	SET @IsNewFQSBonusActive = IIF(@IsNewFQSBonusActive IS NULL,1, @IsNewFQSBonusActive)
	SET @NewFQSBonusDateStart = IIF(@NewFQSBonusDateStart IS NULL,'2025-07-01', @NewFQSBonusDateStart)
	SET @NewFQSBonusDateEnd = IIF(@NewFQSBonusDateEnd IS NULL,'2025-10-01', @NewFQSBonusDateEnd)
	SET @NewQPDateStart = IIF(@NewQPDateStart IS NULL,'2025-07-01', @NewQPDateStart)
	SET @NewQPDateEnd = IIF(@NewQPDateEnd IS NULL,'2025-10-31', @NewQPDateEnd)
	SET @VipPremiumBonusDateStart = IIF(@VipPremiumBonusDateStart IS NULL,202506, @VipPremiumBonusDateStart)
	SET @VipPremiumBonusDateEnd = IIF(@VipPremiumBonusDateEnd IS NULL,202509, @VipPremiumBonusDateEnd)
	SET @CurrentDatetime = IIF(@CurrentDatetime IS NULL,GETDATE(), @CurrentDatetime)

	SELECT
		@CurrentDatetime			AS	[CurrentDatetime],
		@PK_Event_PM				AS	[PK_Event_PM],
		@PK_Event_PE				AS	[PK_Event_PE],
		@PK_Event_AR_UY 			AS	[PK_Event_AR_UY],
		@PK_Event_CI				AS	[PK_Event_CI],
		@PK_Event_CO				AS	[PK_Event_CO],
		@PK_Event_BL				AS	[PK_Event_BL],
		@PK_Event_EC				AS	[PK_Event_EC],
		@PK_Event_GT_SV_HN_NI_CR 	AS	[PK_Event_GT_SV_HN_NI_CR],
		@PK_Event_VE				AS	[PK_Event_VE],
		@PK_Event_DR				AS	[PK_Event_DR],
		@Step						AS	[Step],					
		@QualPeriodJun25			AS	[QualPeriodJun25],		
		@QualPeriodSep25			AS	[QualPeriodSep25],			
		@QualPeriodJul25			AS	[QualPeriodJul25],		
		@QualPeriodOct25			AS	[QualPeriodOct25],			
		@NewFQSqualDateStart		AS	[NewFQSqualDateStart],	
		@NewFQSqualDateEnd			AS	[NewFQSqualDateEnd],		
		@QSActualQualDateStart		AS	[QSActualQualDateStart],	
		@QSActualQualDateEnd		AS	[QSActualQualDateEnd],	
		@NewWTQualDateStart			AS	[NewWTQualDateStart],		
		@NewWTQualDateEnd			AS	[NewWTQualDateEnd],		
		@AWTNonTABQualDateStart		AS	[AWTNonTABQualDateStart], 
		@AWTNonTABQualDateEnd		AS	[AWTNonTABQualDateEnd],	
		@BonusApplicableFrom		AS	[BonusApplicableFrom],	
		@BonusApplicableTo			AS	[BonusApplicableTo],		
		@Countries					AS	[Countries],				
		@IsDoubleBonusActive		AS	[IsDoubleBonusActive],	
		@DoubleBonusDateStart		AS	[DoubleBonusDateStart],	
		@DoubleBonusDateEnd			AS	[DoubleBonusDateEnd],		
		@IsNewFQSBonusActive		AS	[IsNewFQSBonusActive],	
		@NewFQSBonusDateStart		AS	[NewFQSBonusDateStart],	
		@NewFQSBonusDateEnd			AS	[NewFQSBonusDateEnd],		
		@NewQPDateStart				AS	[NewQPDateStart],	
		@NewQPDateEnd				AS	[NewQPDateEnd],	
		@VipPremiumBonusDateStart	AS	[VipPremiumBonusDateStart],
		@VipPremiumBonusDateEnd		AS	[VipPremiumBonusDateEnd]

	------------------------------------------------------------------------------------------------
	-- Tables and variables
	------------------------------------------------------------------------------------------------
	BEGIN

		-- *  Custom

		DECLARE @ColumnToPivot NVARCHAR(MAX),
				@SqlStatement NVARCHAR(MAX)

		DECLARE @PK_Event_General	INT

		DROP TABLE IF EXISTS #Locations

		CREATE TABLE #Locations
		(			
			[PK_Event] [int],
			[Location] [varchar](200),
			[CountryCode]	varchar(20), 
			[PK_Country] [int],
			[ctrl] [bit] DEFAULT(0)
		)

		INSERT INTO #Locations([PK_Event],[Location], [CountryCode],[PK_Country])
		SELECT 
			@PK_Event_PM AS [PK_Event],
			'Panama' AS [Location],
			'PM' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'PM' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_PE AS [PK_Event],
			'Peru' AS [Location],
			'PE' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'PE' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_AR_UY AS [PK_Event],
			'Argentina,Uruguay' AS [Location],
			'AR,UY' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'AR' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_AR_UY AS [PK_Event],
			'Argentina,Uruguay' AS [Location],
			'AR,UY' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'UY' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_CI AS [PK_Event],
			'Chile' AS [Location],
			'CI' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'CI' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_CO AS [PK_Event],
			'Colombia' AS [Location],
			'CO' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'CO' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_BL AS [PK_Event],
			'Bolivia' AS [Location],
			'BL' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'BL' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_EC AS [PK_Event],
			'Ecuador' AS [Location],
			'EC' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'EC' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_GT_SV_HN_NI_CR AS [PK_Event],
			'Guatemala,El Salvador,Honduras,Nicaragua,Costa Rica' AS [Location],
			'GT,SV,HN,NI,CR' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'GT' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_GT_SV_HN_NI_CR AS [PK_Event],
			'Guatemala,El Salvador,Honduras,Nicaragua,Costa Rica' AS [Location],
			'GT,SV,HN,NI,CR' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'SV' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_GT_SV_HN_NI_CR AS [PK_Event],
			'Guatemala,El Salvador,Honduras,Nicaragua,Costa Rica' AS [Location],
			'GT,SV,HN,NI,CR' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'HN' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_GT_SV_HN_NI_CR AS [PK_Event],
			'Guatemala,El Salvador,Honduras,Nicaragua,Costa Rica' AS [Location],
			'GT,SV,HN,NI,CR' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'NI' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_GT_SV_HN_NI_CR AS [PK_Event],
			'Guatemala,El Salvador,Honduras,Nicaragua,Costa Rica' AS [Location],
			'GT,SV,HN,NI,CR' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'CR' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_VE AS [PK_Event],
			'Venezuela' AS [Location],
			'VE' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'VE' ) AS PK_Country
		UNION
		SELECT  
			@PK_Event_DR AS [PK_Event],
			'Dominican Republic' AS [Location],
			'DR' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'DR' ) AS PK_Country


		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			ListID INT,
			QId INT
		)

		INSERT INTO #ListsQsMapping(PK_Event,ListID,QId)
			VALUES 
				(@PK_Event_PM, 65968,8),
				(@PK_Event_PM, 65969,22),
				(@PK_Event_PM, 65970,23),
				(@PK_Event_PM, 65971,24),
				(@PK_Event_PM, 65972,25),
				(@PK_Event_PM, 65973,26),
				(@PK_Event_PM, 65974,27),
				(@PK_Event_PM, 65975,28),
				(@PK_Event_PM, 65976,29), 
				(@PK_Event_PM, 65977,30),
				(@PK_Event_PM, 65978,31),
				(@PK_Event_PM, 66415,32),
				(@PK_Event_PM, 66416,33),

				(@PK_Event_PE, 65980,8),
				(@PK_Event_PE, 65981,21),
				(@PK_Event_PE, 65982,22),
				(@PK_Event_PE, 65983,23),
				(@PK_Event_PE, 65984,24),
				(@PK_Event_PE, 65985,25),
				(@PK_Event_PE, 65986,26),
				(@PK_Event_PE, 65987,27),
				(@PK_Event_PE, 65988,28),
				(@PK_Event_PE, 66210,30),
				(@PK_Event_PE, 66417,31),
				(@PK_Event_PE, 66418,32),

				(@PK_Event_AR_UY, 65990,8),
				(@PK_Event_AR_UY, 65991,18),
				(@PK_Event_AR_UY, 65992,19),
				(@PK_Event_AR_UY, 65993,20),
				(@PK_Event_AR_UY, 65994,21),
				(@PK_Event_AR_UY, 65995,22),
				(@PK_Event_AR_UY, 65996,23),
				(@PK_Event_AR_UY, 65997,24),
				(@PK_Event_AR_UY, 65998,25),
				(@PK_Event_AR_UY, 66211,27),
				(@PK_Event_AR_UY, 66477,28),
				(@PK_Event_AR_UY, 66419,29),				
				(@PK_Event_AR_UY, 66420,30),		
				
				(@PK_Event_CI, 66071,8),
				(@PK_Event_CI, 66000,23),
				(@PK_Event_CI, 66001,24),
				(@PK_Event_CI, 66002,25),
				(@PK_Event_CI, 66003,26),
				(@PK_Event_CI, 66004,27),
				(@PK_Event_CI, 66005,28), 
				(@PK_Event_CI, 66006,29),
				(@PK_Event_CI, 66007,30),
				(@PK_Event_CI, 66008,31),
				(@PK_Event_CI, 66212,33),
				(@PK_Event_CI, 66421,34),
				(@PK_Event_CI, 66422,35),

				(@PK_Event_CO, 66010,8),
				(@PK_Event_CO, 66011,21),
				(@PK_Event_CO, 66012,22),
				(@PK_Event_CO, 66013,23),
				(@PK_Event_CO, 66014,24),
				(@PK_Event_CO, 66015,25),
				(@PK_Event_CO, 66016,26),
				(@PK_Event_CO, 66017,27),
				(@PK_Event_CO, 66018,28),
				(@PK_Event_CO, 66213,30),
				(@PK_Event_CO, 66447,31),
				(@PK_Event_CO, 66423,32),
				(@PK_Event_CO, 66424,33),


				(@PK_Event_BL, 66020,8),
				(@PK_Event_BL, 66021,21),
				(@PK_Event_BL, 66022,22),
				(@PK_Event_BL, 66023,23),
				(@PK_Event_BL, 66024,24),
				(@PK_Event_BL, 66025,25),
				(@PK_Event_BL, 66026,26),
				(@PK_Event_BL, 66027,27),
				(@PK_Event_BL, 66028,28),
				(@PK_Event_BL, 66029,29),
				(@PK_Event_BL, 66214,31),
				(@PK_Event_BL, 66478,32),
				(@PK_Event_BL, 66479,33),
				(@PK_Event_BL, 66425,34),
				(@PK_Event_BL, 66426,35),

				(@PK_Event_EC, 66031,8),
				(@PK_Event_EC, 66032,21),
				(@PK_Event_EC, 66033,22),
				(@PK_Event_EC, 66034,23),
				(@PK_Event_EC, 66035,24),
				(@PK_Event_EC, 66036,25),
				(@PK_Event_EC, 66037,26),
				(@PK_Event_EC, 66038,27),
				(@PK_Event_EC, 66039,28), 
				(@PK_Event_EC, 66215,30), 
				(@PK_Event_EC, 66464,31),
				(@PK_Event_EC, 66427,32), 
				(@PK_Event_EC, 66428,33), 

				(@PK_Event_GT_SV_HN_NI_CR, 66041,8),
				(@PK_Event_GT_SV_HN_NI_CR, 66042,21),
				(@PK_Event_GT_SV_HN_NI_CR, 66043,22),
				(@PK_Event_GT_SV_HN_NI_CR, 66044,23),
				(@PK_Event_GT_SV_HN_NI_CR, 66045,24),
				(@PK_Event_GT_SV_HN_NI_CR, 66046,25),
				(@PK_Event_GT_SV_HN_NI_CR, 66047,26),
				(@PK_Event_GT_SV_HN_NI_CR, 66048,27),
				(@PK_Event_GT_SV_HN_NI_CR, 66049,28),
				(@PK_Event_GT_SV_HN_NI_CR, 66216,30),
				(@PK_Event_GT_SV_HN_NI_CR, 66429,31),
				(@PK_Event_GT_SV_HN_NI_CR, 66430,32),

				(@PK_Event_DR, 66061,8),
				(@PK_Event_DR, 66062,19),
				(@PK_Event_DR, 66063,20),
				(@PK_Event_DR, 66064,21),
				(@PK_Event_DR, 66065,22), 
				(@PK_Event_DR, 66066,23),
				(@PK_Event_DR, 66067,24),
				(@PK_Event_DR, 66068,25),
				(@PK_Event_DR, 66069,26),
				(@PK_Event_DR, 66218,28),
				(@PK_Event_DR, 66433,29),
				(@PK_Event_DR, 66434,30),

				(@PK_Event_VE, 66051,8),
				(@PK_Event_VE, 66052,18),
				(@PK_Event_VE, 66053,19),  
				(@PK_Event_VE, 66054,20),
				(@PK_Event_VE, 66055,21),
				(@PK_Event_VE, 66056,22),
				(@PK_Event_VE, 66057,23),
				(@PK_Event_VE, 66058,24),
				(@PK_Event_VE, 66059,25),
				(@PK_Event_VE, 66217,27),			
				(@PK_Event_VE, 66431,28),
				(@PK_Event_VE, 66432,29)

		DROP TABLE IF EXISTS #SKUsQsMapping

		CREATE TABLE #SKUsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			SKUCode VARCHAR(10),
			QId INT
		)

		DROP TABLE IF EXISTS #TimeLog;  

		CREATE TABLE #TimeLog(
			[Milestone]		varchar(255)
			,[StepGroup]	tinyint
			,[StepSubGroup] tinyint
			,[StepStart]	datetime2
			,[Duration]		int
		);
		
		DROP TABLE IF EXISTS #EventQual;

		CREATE TABLE #EventQual
		(
			PK_Event		INT,
			PK_Distributor	INT,
			CreatedDate		DATETIME DEFAULT  GETUTCDATE(),
			UpdatedDate		DATETIME DEFAULT  GETUTCDATE(),
			Q01  BIT DEFAULT 0,	Q02  BIT DEFAULT 0,	Q03  BIT DEFAULT 0,	Q04  BIT DEFAULT 0,	Q05  BIT DEFAULT 0,
			Q06  BIT DEFAULT 0,	Q07  BIT DEFAULT 0,	Q08  BIT DEFAULT 0,	Q09  BIT DEFAULT 0,	Q10  BIT DEFAULT 0,
			Q11  BIT DEFAULT 0,	Q12  BIT DEFAULT 0,	Q13  BIT DEFAULT 0,	Q14  BIT DEFAULT 0,	Q15  BIT DEFAULT 0,
			Q16  BIT DEFAULT 0,	Q17  BIT DEFAULT 0,	Q18  BIT DEFAULT 0,	Q19  BIT DEFAULT 0,	Q20  BIT DEFAULT 0,
			Q21  BIT DEFAULT 0,	Q22  BIT DEFAULT 0,	Q23  BIT DEFAULT 0,	Q24  BIT DEFAULT 0,	Q25  BIT DEFAULT 0,
			Q26  BIT DEFAULT 0,	Q27  BIT DEFAULT 0,	Q28  BIT DEFAULT 0,	Q29  BIT DEFAULT 0,	Q30  BIT DEFAULT 0,
			Q31  BIT DEFAULT 0,	Q32  BIT DEFAULT 0,	Q33  BIT DEFAULT 0,	Q34  BIT DEFAULT 0,	Q35  BIT DEFAULT 0,
			Q36  BIT DEFAULT 0,	Q37  BIT DEFAULT 0,	Q38  BIT DEFAULT 0,	Q39  BIT DEFAULT 0,	Q40  BIT DEFAULT 0,
			Q41  BIT DEFAULT 0,	Q42  BIT DEFAULT 0,	Q43  BIT DEFAULT 0,	Q44  BIT DEFAULT 0,	Q45  BIT DEFAULT 0,
			Q46  BIT DEFAULT 0,	Q47  BIT DEFAULT 0,	Q48  BIT DEFAULT 0,	Q49  BIT DEFAULT 0,	Q50  BIT DEFAULT 0,
	
			E01  BIT DEFAULT 0,	E02  BIT DEFAULT 0,	E03  BIT DEFAULT 0,	E04  BIT DEFAULT 0,	E05  BIT DEFAULT 0,
			E06  BIT DEFAULT 0,	E07  BIT DEFAULT 0,	E08  BIT DEFAULT 0,	E09  BIT DEFAULT 0,	E10  BIT DEFAULT 0,
			E11  BIT DEFAULT 0,	E12  BIT DEFAULT 0,	E13  BIT DEFAULT 0,	E14  BIT DEFAULT 0,	E15  BIT DEFAULT 0,
			E16  BIT DEFAULT 0,	E17  BIT DEFAULT 0,	E18  BIT DEFAULT 0,	E19  BIT DEFAULT 0,	E20  BIT DEFAULT 0,
			E21  BIT DEFAULT 0,	E22  BIT DEFAULT 0,	E23  BIT DEFAULT 0,	E24  BIT DEFAULT 0,	E25  BIT DEFAULT 0,
			E26  BIT DEFAULT 0,	E27  BIT DEFAULT 0,	E28  BIT DEFAULT 0,	E29  BIT DEFAULT 0,	E30  BIT DEFAULT 0,
			E31  BIT DEFAULT 0,	E32  BIT DEFAULT 0,	E33  BIT DEFAULT 0,	E34  BIT DEFAULT 0,	E35  BIT DEFAULT 0,
			E36  BIT DEFAULT 0,	E37  BIT DEFAULT 0,	E38  BIT DEFAULT 0,	E39  BIT DEFAULT 0,	E40  BIT DEFAULT 0,
			E41  BIT DEFAULT 0,	E42  BIT DEFAULT 0,	E43  BIT DEFAULT 0,	E44  BIT DEFAULT 0,	E45  BIT DEFAULT 0,
			E46  BIT DEFAULT 0,	E47  BIT DEFAULT 0,	E48  BIT DEFAULT 0,	E49  BIT DEFAULT 0,	E50  BIT DEFAULT 0
		)
	END
	
	------------------------------------------------------------------------------------------------
	-- Volume qualifications setup
	------------------------------------------------------------------------------------------------
	BEGIN

		DROP TABLE IF EXISTS #Event_SetupEventQualification

		CREATE TABLE #Event_SetupEventQualification
		(
			ID int IDENTITY(1,1),
			[PK_Event]				int,
			[QualificationNumber]	int,
			[Part]					int,
			[MetricType]			varchar(50),
			[dStartDate]			datetime2,
			[dEndDate]				datetime2,
			[Frequency]				int,
			[Consecutive]			bit, 
			[Accumulated]			bit, 
			[MinPoints]				money,
			[GoalPoints]			money,
			[Countries]				varchar(max),
			[Bonus]					bit,
			[QSVolume]				bit,
			[QSVolumePercentage]	int,
			[HasQualReference]		bit DEFAULT 0,
		)


		;WITH cte_Quals AS
		(
			--Q9	Achieve 2,500 TVP in any one (1) month (Jun 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			9 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
			UNION
			--Q10 Achieve 5,000 TVP in any one (1) month (Jun 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			10 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
			UNION
			--Q11 Achieve 2,500 TVP each month in any three (3) months (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			11 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
			UNION
			--Q12 Achieve 2,500 TVP each month in any three (3) months (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			12 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
			UNION
			--Q13 Accumulate 5,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			13 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate], 
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
			UNION
			--Q14 Accumulate 5,000 TVP (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			14 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
			UNION
			--Q15 Accumulate 10,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			15 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR,@PK_Event_DR)
			UNION
			--Q16 Accumulate 10,000 TVP (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			16 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR,@PK_Event_DR)
			UNION
			--Q17 Accumulate 15,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			17 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR,@PK_Event_DR)
			UNION
			--Q18 Accumulate 15,000 TVP (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			18 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR,@PK_Event_DR)
			UNION
			--Q19 Accumulate 20,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			19 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
			UNION
			--Q20 Accumulate 20,000 TVP (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			20 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
			UNION
			--Q9 Achieve 5,000 TVP in any one (1) month (Jun 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			9 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY)
			UNION
			--Q10 Achieve 2,500 TVP each month in any three (3) months (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			10 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY)
			UNION
			--Q11 Achieve 2,500 TVP each month in any three (3) months (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			11 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY)
			UNION
			--Q12 Accumulate 10,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			12 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY)
			UNION
			--Q13 Accumulate 10,000 TVP (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			13 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY)
			UNION
			--Q14 Accumulate 15,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			14 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY,@PK_Event_VE)
			UNION
			--Q15 Accumulate 15,000 TVP (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			15 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY,@PK_Event_VE)
			UNION
			--Q16 Accumulate 20,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			16 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY,@PK_Event_VE)
			UNION
			--Q17 Accumulate 20,000 TVP (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			17 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY,@PK_Event_VE)
			UNION
			--Q13 Accumulate 2,500 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			13 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate], 
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_DR)
			UNION
			--Q14 Accumulate 2,500 TVP (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			14 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_DR)
			UNION
			--Q12 Accumulate 3,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			12 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			3000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_VE)
			UNION
			--Q13 Accumulate 3,000 TVP (Jul 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			13 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJul25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			3000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_VE)
			UNION
			--Q11 Accumulate 1,000 PPV in any one (1) month (Jun 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			11 AS QualificationNumber,
			1 AS Part, 
			'PPV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			1000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_DR
			UNION
			--Q12 Achieve 1,500 TVP in any one (1) month (Jun 2025 - Oct 2025)
			SELECT 
			l.PK_Event,
			12 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodOct25 AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			1500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_DR)
			UNION
			--Q22 Achieve 1,000 RO in any one (1) month (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			22 AS QualificationNumber,
			1 AS Part, 
			'RO' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			1000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_CI)
			UNION
			--Q21 Accumulate 30,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			21 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			30000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM)
			UNION
			--Q29 Accumulate 30,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			29 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			30000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PE,@PK_Event_CO,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
			UNION
			--Q26 Accumulate 30,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			26 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			30000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_AR_UY,@PK_Event_VE)
			UNION
			--Q32 Accumulate 30,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			32 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			30000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_CI)
			UNION
			--Q30 Accumulate 30,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			30 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			30000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_BL)	
			UNION
			--Q27 Accumulate 30,000 TVP (Jun 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			27 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodJun25 AS [dStartDate], 
			@QualPeriodSep25 AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			30000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_DR)	
			UNION
			--Q36 Accumulate 10,000 TVP (May 2025 - Sep 2025)
			SELECT 
			l.PK_Event,
			36 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2025-05-01' AS [dStartDate], 
			'2025-09-01' AS [dEndDate],  
			5 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_CO)

		) 

	INSERT INTO #Event_SetupEventQualification(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries)
	SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries 
	FROM cte_Quals

		IF @IsDevQA = 0
		BEGIN	

			DELETE s 
			FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK)  
				INNER JOIN #Locations AS l
					ON s.PK_Event = l.PK_Event
	 
			INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries 
			FROM #Event_SetupEventQualification
		 
		END
		ELSE IF @IsDevQA = 3
		BEGIN	

			DELETE s 
			FROM ##Event_SetupEventQualification_jgue AS s  
				INNER JOIN #Locations AS l
					ON s.PK_Event = l.PK_Event
	 
			INSERT INTO ##Event_SetupEventQualification_jgue(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries 
			FROM #Event_SetupEventQualification

		END
	
	END

	------------------------------------------------------------------------------------------------
	-- Qualifications block
	------------------------------------------------------------------------------------------------
	BEGIN 

		IF (@IsDevQA = 2) THROW 60000, N'Unit test Error', 1; --Forcing to fail for unit testing purpose
	 		
		--Step 1: DS
		IF @Step >= 1
		BEGIN

			PRINT 'Executing step 1'

			INSERT INTO #TimeLog VALUES ('#DS', 1, 1, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #Countries

				CREATE TABLE #Countries
				(
					PK_Event INT,
					nCountryID		int,   
					sCountryCode	varchar(10), 
					sCountryCodeISO varchar(10), 
					sCountryName	varchar(150)
				)

				INSERT INTO #Countries(nCountryID,sCountryCode,sCountryCodeISO,sCountryName) 
					SELECT DISTINCT nCountryID,sCountryCode,sCountryCodeISO,sCountryName
					FROM dbo.v_Countries
					WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@Countries, ','))

				DROP TABLE IF EXISTS #DS

				CREATE TABLE #DS
				(
					PK_Event			int,  
					PK_Distributor		int,  
					DistributorID		varchar(40), 
					DSCurrentTeam		varchar(10),        
					DSSubTeam			varchar(10),        
					DSSPTeam			varchar(10), 
					NewSPQualDate		datetime2,
					NewWTQualDate		datetime2 default '1900-01-01',
					WTQualDate			datetime2,
					dSPQualDate			datetime2,
					SPQualDate			datetime2,
					dSPReQualDate		datetime2,
					RequalSPQualDate	datetime2,
					CountryCode			varchar(5),
					PK_Country			int,
					QSQualDate			smalldatetime,		
					QSActualQualDate	smalldatetime,	
					dSPDemotionDate		smalldatetime,
					IsFromCOP			bit default(0),
					IsFromList			bit default(0),
					IsTicketPurchaser	bit default(0),
					dQPQualification	datetime2,
					dQPDemotion			datetime2,
					IsAWT2025			bit default(0),
					NewSPBonus			bit default(0)
				)

				--FQS AND DS

				INSERT INTO #DS
				(
					PK_Event,
					PK_Distributor,	
					DistributorID,
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,
					[SPQualDate],
					dSPReQualDate,
					RequalSPQualDate,
					IsFromCOP,
					CountryCode,
					PK_Country,
					QSQualDate,		
					QSActualQualDate,
					dSPDemotionDate,
					dQPQualification,
					dQPDemotion

				)
				SELECT DISTINCT  
				C.PK_Event,
				D.nDistributorID AS PK_Distributor,
				D.sDistributorID,
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				ISNULL(D.dSupervisorqualification,'1900-01-01') AS dSPQualDate, 
				ISNULL(D.dSupervisorQualification,'1900-01-01')  AS [SPQualDate],
				ISNULL(D.dSupervisorReQualification,'1900-01-01')  AS dSPReQualDate, 
				ISNULL(D.dSupervisorReQualification,'1900-01-01')  AS [RequalSPQualDate],
				1 AS IsFromCOP,
				D.sDistributorCountryProcessingCode AS CountryCode,
				C.PK_Country,
				ISNULL(D.dQSQualification,'1900-01-01') AS dQSQualification,				
				ISNULL(D.dQSQualification_Actual,'1900-01-01') AS dQSQualification_Actual,
				ISNULL(D.dSPDemotion,'1900-01-01') AS dSPDemotion,
				ISNULL(D.dQPQualification,'1900-01-01') AS dQPQualification,
				ISNULL(D.dQPDemotion,'1900-01-01') AS dQPDemotion
				FROM dbo.v_Distributor AS D  
				INNER JOIN #Locations AS C
					ON D.nDistributorCountryProcessingID = C.PK_Country
				WHERE        
					D.StatusCode = 'COMPLETE'        
					AND D.sType IN ('DS','SP')		

				CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);
							   	
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 1 AND [StepSubGroup] = 1;
		END

		--Step 2: List and SKUs
		IF @Step >= 2
		BEGIN

			PRINT 'Executing step 2'

			INSERT INTO #TimeLog VALUES ('Lists', 2, 1, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #DSList

				CREATE TABLE #DSList
				(
					[PK_Event] INT
					,PK_Distributor INT
					,ListID INT
					,UniqueID NVARCHAR(MAX)
				)	
				
				DROP TABLE IF EXISTS #ListsIDs

				CREATE TABLE #ListsIDs
				(
					ID INT IDENTITY(1,1),
					PK_Event INT,
					ListID INT,
					QId INT
				)

				INSERT INTO #ListsIDs(PK_Event,ListID,QId)
				SELECT DISTINCT 
					l.PK_Event AS PK_Event,
					l.ListID AS [ListID],
					l.QId
				FROM #ListsQsMapping  AS l

				INSERT INTO #DSList([PK_Event],PK_Distributor,ListID,UniqueID)			  
				SELECT		
					l.PK_Event,
					S.nDistributorID AS PK_Distributor,				  
					S.nTypeLID AS ListID,
					CAST(l.PK_Event AS NVARCHAR(20)) + '-' + CAST(S.nDistributorID AS NVARCHAR(20))+ '-'+ CAST(s.nTypeLID AS NVARCHAR(20))  AS UniqueID
				FROM dbo.v_DistributorSet S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				INNER JOIN #ListsIDs l
					ON S.nTypeLID = l.ListID

				CREATE INDEX IX_#DSList_PK_Distributor ON #DSList(PK_Distributor);

				INSERT INTO #DS
				(
					PK_Event,
					PK_Distributor,
					DistributorID,		
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,	
					[SPQualDate],
					dSPReQualDate,
					RequalSPQualDate,
					CountryCode,	
					PK_Country,
					IsFromList,
					dQPQualification,
					dQPDemotion,
					dSPDemotionDate,
					QSQualDate,		
					QSActualQualDate
				)
				SELECT DISTINCT  
				L.PK_Event,
				D.nDistributorID AS PK_Distributor,   
				D.sDistributorID,
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				ISNULL(D.dSupervisorqualification,'1900-01-01')  AS dSPQualDate,   
				ISNULL(D.dSupervisorQualification,'1900-01-01')  AS [SPQualDate],
				ISNULL(D.dSupervisorReQualification,'1900-01-01')  AS dRequalSPQualDate, 
				ISNULL(D.dSupervisorReQualification,'1900-01-01')  AS [RequalSPQualDate],
				D.sDistributorCountryProcessingCode AS CountryCode,
				D.nDistributorCountryProcessingID,
				1 AS IsFromList,
				ISNULL(D.dQPQualification,'1900-01-01') AS dQPQualification,
				ISNULL(D.dQPDemotion,'1900-01-01') AS dQPDemotion,
				ISNULL(D.dSPDemotion,'1900-01-01') AS dSPDemotion,
				ISNULL(D.dQSQualification,'1900-01-01') AS dQSQualification,				
				ISNULL(D.dQSQualification_Actual,'1900-01-01') AS dQSQualification_Actual
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSList AS L
						ON D.nDistributorID = L.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = L.PK_Distributor AND T.PK_Event = L.PK_Event)

				UPDATE D
				SET IsFromList = 1
				FROM #DS AS D  
					INNER JOIN #DSList AS L
						ON D.PK_Distributor = L.PK_Distributor

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 1;

			INSERT INTO #TimeLog VALUES ('SKUs', 2, 2, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #DSSKUs

				CREATE TABLE #DSSKUs
				(
					PK_Distributor INT
					,PK_EventSKU INT
					,PK_Event INT
					,SKUCode VARCHAR(10)
					,UniqueID NVARCHAR(MAX)
				)	
				
				DROP TABLE IF EXISTS #SKUs

				CREATE TABLE #SKUs
				(
					ID INT IDENTITY(1,1),
					SKUCode VARCHAR(10),
					PK_Event INT,
				)

				INSERT INTO #SKUs(PK_Event,SKUCode)
				SELECT DISTINCT 
					l.PK_Event, 
					LTRIM(RTRIM(s.SKUCode))
				FROM [dbo].[EventSKU] AS s WITH (NOLOCK) 
				INNER JOIN #Locations AS l
				ON s.PK_Event = l.PK_Event
					 	
				INSERT INTO #DSSKUs(PK_Distributor,PK_EventSKU,PK_Event,SKUCode,UniqueID)
					SELECT DISTINCT et.PK_Distributor_Purchaser,esku.PK_EventSKU, s.PK_Event, esku.SKUCode ,CAST(l.PK_Event AS NVARCHAR(20)) + '-' + CAST(et.PK_Distributor_Purchaser AS NVARCHAR(20))+ '-'+ CAST(esku.SKUCode  AS NVARCHAR(20))  AS UniqueID 
				FROM #SKUs AS s 
					INNER JOIN dbo.EventSKU AS esku WITH (NOLOCK)
						ON s.SKUCode = esku.SKUCode
					INNER JOIN [dbo].[SKUPurchased] et WITH (NOLOCK)
						ON et.PK_EventSKU = esku.PK_EventSKU
					INNER JOIN #Locations AS l
						ON et.PK_Event = l.PK_Event

				CREATE INDEX IX_DSSKUs_PK_Distributor ON #DSSKUs(PK_Distributor)

				INSERT INTO #DS
				(
					PK_Event,
					PK_Distributor,
					DistributorID,					
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,
					[SPQualDate],
					dSPReQualDate,
					RequalSPQualDate,
					CountryCode,
					PK_Country,
					QSQualDate,		
					QSActualQualDate,
					dSPDemotionDate,
					IsTicketPurchaser,
					dQPQualification,
					dQPDemotion
				)
				SELECT DISTINCT       
				S.PK_Event,
				D.nDistributorID AS PK_Distributor,
				D.sDistributorID,				
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				ISNULL(D.dSupervisorqualification,'1900-01-01') AS dSPQualDate,      
				ISNULL(D.dSupervisorQualification,'1900-01-01') AS [SPQualDate],
				ISNULL(D.dSupervisorReQualification,'1900-01-01') AS dSPReQualDate, 
				ISNULL(D.dSupervisorReQualification,'1900-01-01') AS [RequalSPQualDate],
				D.sDistributorCountryProcessingCode AS CountryCode,
				D.nDistributorCountryProcessingID,
				ISNULL(D.dQSQualification,'1900-01-01') AS dQSQualification,				
				ISNULL(D.dQSQualification_Actual,'1900-01-01') AS dQSQualification_Actual,
				ISNULL(D.dSPDemotion,'1900-01-01') AS dSPDemotion,
				1 AS IsTicketPurchaser,
				ISNULL(D.dQPQualification,'1900-01-01') AS dQPQualification,
				ISNULL(D.dQPDemotion,'1900-01-01') AS dQPDemotion
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSSKUs AS S
						ON D.nDistributorID = S.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = S.PK_Distributor AND T.PK_Event = S.PK_Event)

				UPDATE D
				SET IsTicketPurchaser = 1
				FROM #DS AS D  
					INNER JOIN #DSSKUs AS S
						ON D.PK_Distributor = S.PK_Distributor


			--NewFQS
			UPDATE D
			SET NewSPQualDate = IIF(D.dSPDemotionDate = '1900-01-01', 
									D.dSPQualDate, -- First time ever / never demoted
									IIF(D.dSPQualDate > D.dSPReQualDate,D.dSPQualDate,D.dSPReQualDate) -- If demoted then get the latest date between SPQualDate and SPReQualDate
								)
			FROM #DS AS D  
			WHERE DSSPTeam = 'SP'


			--New World Team (WT) or requalified to WT
			DROP TABLE IF EXISTS #DSLatestStatus

			SELECT 
				PK_Distributor,
				CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
				DSSubTeam SUBTYPECODE
			INTO #DSLatestStatus
			FROM 
				#DS
			GROUP BY PK_Distributor,DSSubTeam

			DROP TABLE IF EXISTS #DSSNAPSHOT_disorganized

			SELECT 
				PK_Distributor,
				ROYALTYMONTH,
				SUBTYPECODE	
			INTO #DSSNAPSHOT_disorganized
			FROM #DSLatestStatus
			UNION
			SELECT
				DSN.PK_Distributor,
				DSN.ROYALTYMONTH,
				DSN.SUBTYPECODE
			FROM 
				[PubEventManagement].[Shared].[DSSNAPSHOT] DSN (NOLOCK)
			INNER JOIN #DSLatestStatus D
				ON DSN.PK_DISTRIBUTOR = D.PK_Distributor
			ORDER BY PK_Distributor,ROYALTYMONTH DESC

			DROP TABLE IF EXISTS #DSSNAPSHOT

			SELECT
				ROW_NUMBER() OVER (PARTITION BY PK_Distributor ORDER BY ROYALTYMONTH) AS [row_number],
				PK_Distributor,
				ROYALTYMONTH,
				SUBTYPECODE	
			INTO #DSSNAPSHOT
			FROM #DSSNAPSHOT_disorganized	

			DROP TABLE IF EXISTS #DSSNAPSHOT_PREVIOUS

			SELECT [row_number],PK_Distributor,ROYALTYMONTH,SUBTYPECODE, 
				LAG([row_number]) OVER (PARTITION BY PK_Distributor ORDER BY ROYALTYMONTH) PREVIOUSROWNUMBER, 
				LAG(ROYALTYMONTH) OVER (PARTITION BY PK_Distributor ORDER BY ROYALTYMONTH) PREVIOUSROYALTYMONTH,
				LAG(SUBTYPECODE) OVER (PARTITION BY PK_Distributor ORDER BY ROYALTYMONTH) PREVIOUSSUBTYPECODE   
			INTO #DSSNAPSHOT_PREVIOUS
			FROM #DSSNAPSHOT DSNAP

			DROP TABLE IF EXISTS #SNAPSHOTWithinRangeDate

			SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH
			INTO #SNAPSHOTWithinRangeDate
			FROM #DSSNAPSHOT
			WHERE
				ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewWTQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewWTQualDateEnd, 112) AS int)
				AND SUBTYPECODE = 'WT'
			GROUP BY PK_DISTRIBUTOR
			
			DROP TABLE IF EXISTS #NewWTQualDate

			CREATE TABLE #NewWTQualDate
			(
				PK_Distributor INT,
				ROYALTYMONTH INT
			)

			INSERT INTO #NewWTQualDate(PK_Distributor,ROYALTYMONTH)
			SELECT DSNAP.PK_Distributor, DSNAP.ROYALTYMONTH 
			FROM #DSSNAPSHOT_PREVIOUS DSNAP
			INNER JOIN #SNAPSHOTWithinRangeDate CSNAP
				ON	DSNAP.PK_DISTRIBUTOR = CSNAP.PK_DISTRIBUTOR AND DSNAP.ROYALTYMONTH = CSNAP.ROYALTYMONTH
			WHERE 
				DSNAP.PREVIOUSSUBTYPECODE != 'WT'

			INSERT INTO #NewWTQualDate(PK_Distributor,ROYALTYMONTH)
			SELECT DSNAP.PK_Distributor, MAX(DSNAP.PREVIOUSROYALTYMONTH) ROYALTYMONTH 
			FROM #DSSNAPSHOT_PREVIOUS DSNAP
			INNER JOIN #SNAPSHOTWithinRangeDate CSNAP
				ON	DSNAP.PK_DISTRIBUTOR = CSNAP.PK_DISTRIBUTOR
			WHERE 
				DSNAP.SUBTYPECODE != 'WT' AND DSNAP.PREVIOUSSUBTYPECODE = 'WT'
				AND DSNAP.ROYALTYMONTH < CSNAP.ROYALTYMONTH 
				AND NOT EXISTS (SELECT 1 FROM #NewWTQualDate WHERE PK_Distributor = CSNAP.PK_Distributor)
			GROUP BY DSNAP.PK_Distributor

			UPDATE D
				SET D.NewWTQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112), ISNULL((SELECT CONVERT(DATETIME,CONVERT(VARCHAR,MIN(ROYALTYMONTH)) + '01',112) FROM #DSSNAPSHOT WHERE PK_Distributor = D.PK_Distributor AND SUBTYPECODE = 'WT' GROUP BY PK_Distributor),'1900-01-01'))
			FROM #DS AS D 
			LEFT JOIN #NewWTQualDate DQ
				ON D.PK_Distributor = DQ.PK_Distributor


			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 2;
		END

		--Step 3: Volume
		IF @Step >= 3
		BEGIN

			PRINT 'Executing step 3'

			DROP TABLE IF EXISTS #vExec

			SELECT DISTINCT PK_Event,
			0 AS [ctrl]
			INTO #vExec
			FROM #Locations

			DROP TABLE IF EXISTS #Event_DSPoints

			CREATE TABLE #Event_DSPoints
			(
				[PK_Distributor] [int] NULL,
				[PK_Event] [int] NULL,
				[PK_Country] [int] NULL,
				[RoyaltyMonth] [int] NULL,
				[MetricType] [varchar](20) NULL,
				[PersonalPoints] [money] NULL DEFAULT(0),
				[TransferPoints] [money] NULL DEFAULT(0),
				[MainPoints] [money] NULL DEFAULT(0),
				[Points] [money] NULL DEFAULT(0),
				[Bonus] [money] NULL DEFAULT(0)
			)

			WHILE EXISTS (SELECT 1 FROM #vExec WHERE ctrl = 0)
			BEGIN

			SELECT @PK_Event_General = MIN(PK_Event) FROM #vExec WHERE ctrl = 0

			PRINT 'Getting volume for ' + CAST(@PK_Event_General AS VARCHAR(10))
			------------------------------------------------------------------------------------------------
			-- 3.1 Getting values from #Event_SetupEventQualification
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification', 3, 1, GETUTCDATE(), NULL);

				DECLARE 
					@iStartDate int,
					@dStartDate datetime,
					@iEndDate int,
					@dEndDate datetime
		
				SELECT 
					@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
					@dStartDate = MIN(dStartDate),
					@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
					@dEndDate = MAX(dEndDate)
					FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event_General
	
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

				-- Result set 
				IF @IsDevQA > 0 SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate]--,@DSCountries AS [DSCountries]--,@MetricType AS [MetricType]

				------------------------------------------------------------------------------------------------
				-- 3.2 Getting #tmp_DS
				------------------------------------------------------------------------------------------------
			
				INSERT INTO #TimeLog VALUES ('#tmp_DS', 3, 2, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #tmp_DS

					CREATE TABLE #tmp_DS(
						[PK_Event] [int] NOT NULL,
						[PK_Distributor] [int] NULL,
						[DistributorID] VARCHAR(30),
						[iStartDate] [int] NULL,
						[iEndDate] [int] NULL,
						[dStartDate] [datetime] NULL,
						[dEndDate] [datetime] NULL,
						[dSPQualDate] [datetime] NULL
					)

					INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
					SELECT 
						@PK_Event_General AS [PK_Event], --AR,BL,CI,CO,CR,DR,EC,GT,HN,NI,PM,PE,PY,SV,UY,VE
						D.PK_Distributor,
						D.DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						D.dSPQualDate 
					FROM #DS AS D
					WHERE D.PK_Event = @PK_Event_General

					CREATE INDEX IX_#tmp_DS_PK_Distributor ON #tmp_DS(PK_Distributor);	

					IF (@IsDevQA = 0)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_DS_PK_Distributor]
							ON [tmp].[DS];

						DELETE d FROM [tmp].[DS] AS d WHERE d.PK_Event = @PK_Event_General

						INSERT INTO [tmp].[DS]([PK_Event],[PK_Distributor],[StartDate],[EndDate])
						SELECT 
							D.[PK_Event], 
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate]
						FROM #tmp_DS AS D 						

						CREATE INDEX IX_DS_PK_Distributor ON [tmp].[DS](PK_Distributor) INCLUDE(PK_Event);

					END
					ELSE 
					IF (@IsDevQA = 3)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_##tmp_DS_jgue_PK_Distributor]
							ON ##tmp_DS_jgue;

						DELETE d FROM ##tmp_DS_jgue AS d WHERE d.PK_Event = @PK_Event_General

						INSERT INTO ##tmp_DS_jgue([PK_Event],[PK_Distributor],[StartDate],[EndDate])
						SELECT 
							D.[PK_Event], 
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate]
						FROM #tmp_DS AS D 	 
											 
						CREATE INDEX IX_##tmp_DS_jgue_PK_Distributor ON ##tmp_DS_jgue(PK_Distributor) INCLUDE(PK_Event);

					END

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;

				------------------------------------------------------------------------------------------------
				-- 3.3 Getting [Event].[DSPoints]
				------------------------------------------------------------------------------------------------
				IF (@IsDevQA = 0)
				BEGIN
					INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 3, 2, GETUTCDATE(), NULL);
							
					--Input
					--[tmp].[DS]
					--[Event].[SetupEventQualification]

					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event_General, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
					--Output [Event].[DSPoints]

					IF ISNULL(@Error,0) != 0
					BEGIN
						SELECT 'usp_GetDSVolume' AS [usp], @Error AS [Error], @ErrorMessage AS [ErrorMessage]
						RETURN;
					END

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
				END
				ELSE
				IF (@IsDevQA = 3)
				BEGIN
					INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 3, 2, GETUTCDATE(), NULL);

					--Input
					--##tmp_DS_jgue
					--##Event_SetupEventQualification_jgue

					EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event_General, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
					--Output
					--##Event_DSPoints_jgue
			
					IF ISNULL(@Error,0) != 0
					BEGIN
						SELECT '##usp_GetDSVolume_jgue' AS [usp], @Error AS [Error], @ErrorMessage AS [ErrorMessage]
						RETURN;
					END
					 
					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
				END
			
			------------------------------------------------------------------------------------------------
			-- 3.5 Getting #Event_DSPoints AND #Event_DSPoints_Validations
			------------------------------------------------------------------------------------------------
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints', 3, 5, GETUTCDATE(), NULL);

				IF @IsDevQA = 0
				BEGIN
					INSERT INTO #Event_DSPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])
					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						[PersonalPoints] AS [PersonalPoints],
						[TransferPoints] AS [TransferPoints],
						[MainPoints] AS [MainPoints], 
						ROUND([Points],2) AS [Points],
						Bonus
					FROM [Event].[DSPoints] WITH (NOLOCK)
					WHERE PK_Event = @PK_Event_General

				END
				ELSE IF @IsDevQA = 3
				BEGIN

					INSERT INTO #Event_DSPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])
					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,						
						[RoyaltyMonth],
						MetricType,
						[PersonalPoints] AS [PersonalPoints],
						[TransferPoints] AS [TransferPoints],
						[MainPoints] AS [MainPoints],  
						ROUND([Points],2) AS [Points],
						Bonus
					FROM ##Event_DSPoints_jgue 
					WHERE PK_Event = @PK_Event_General

				END		
			
			UPDATE #vExec
			SET [Ctrl] = 1
			WHERE PK_Event = @PK_Event_General

			END

			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])

		END

		--Step 4: Qualification definition
		IF @Step >= 4
		BEGIN
			PRINT 'Executing step 4'

			------------------------------------------------------------------------------------------------
			-- 4.1 Getting all qualification definition for each DS
			------------------------------------------------------------------------------------------------

			INSERT INTO #TimeLog VALUES ('#tmp_DSQualDef', 4, 1, GETUTCDATE(), NULL);
			
				DROP TABLE IF EXISTS #tmp_DSQualDef

				CREATE TABLE #tmp_DSQualDef
				(
					[PK_Event] [int] NOT NULL,
					[PK_Distributor] [int] NULL,
					[dStartDate] [datetime2](7) NULL,
					[dEndDate] [datetime2](7) NULL,
					[iStartDate] [int] NULL,
					[iEndDate] [int] NULL,
					[dSPQualDate] [datetime2](7) NULL,
					[iSPQualDate] [int] NULL,
					[Frequency] [int] NULL,
					[Consecutive] [bit] NULL,
					[Accumulated] [bit] NULL,
					[MetricType] [varchar](50) NULL,
					[GoalPoints] [money] NULL,
					[MinPoints] [money] NULL,
					[QualificationNumber] [int] NULL,
					[Part] [int] NULL,
					[PK_AssociatedID] [int] NULL,
					[Countries] [varchar](max) NULL,
					[Bonus] [bit] NULL,
					[QSVolume] [bit] NULL 
					)

				INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
					SELECT 
						D.PK_Event,
						D.PK_Distributor AS PK_Distributor,
						A.StartDate AS dStartDate,
						A.EndDate AS dEndDate,
						CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
						CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
						D.dSPQualDate AS [dSPQualDate],
						CAST(CONVERT(varchar(6), D.dSPQualDate, 112) AS int) AS [iSPQualDate],
						C.Frequency AS Frequency,
						C.Consecutive AS Consecutive,
						C.Accumulated AS Accumulated,
						C.MetricType AS MetricType,
						C.GoalPoints AS GoalPoints,
						C.MinPoints AS MinPoints,
						C.QualificationNumber,
						C.Part,
						M.PK_AssociatedID AS PK_AssociatedID,
						C.Countries,
						C.Bonus,
						C.[QSVolume]
					FROM #DS AS D					
						LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
							ON D.PK_Distributor = M.PK_Distributor
						OUTER APPLY (SELECT C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated,C.MetricType,C.GoalPoints,C.MinPoints,C.QualificationNumber,C.Part,C.Countries,C.Bonus,C.[QSVolume] FROM  #Event_SetupEventQualification AS C WHERE C.PK_Event = D.PK_Event) AS C
						CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
					
				CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef]', 4, 2, GETUTCDATE(), NULL);
								 
				DELETE [tmp].[DSQualDef] WHERE PK_Event = @PK_Event_General

				INSERT INTO [tmp].[DSQualDef]([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
					SELECT 
						[PK_Event],
						PK_Distributor,
						dStartDate,
						dEndDate,
						iStartDate,
						iEndDate,
						[dSPQualDate],
						[iSPQualDate],
						Frequency,
						Consecutive,
						Accumulated,
						MetricType,
						GoalPoints,
						MinPoints,
						QualificationNumber,
						Part,
						PK_AssociatedID,
						Countries,
						[Bonus],
						[QSVolume]
					FROM #tmp_DSQualDef

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 2;

					
		END  
			ELSE IF @IsDevQA = 3
			BEGIN
				
				INSERT INTO ##tmp_DSQualDef_jgue([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
					SELECT 
						[PK_Event],
						PK_Distributor,
						dStartDate,
						dEndDate,
						iStartDate,
						iEndDate,
						[dSPQualDate],
						[iSPQualDate],
						Frequency,
						Consecutive,
						Accumulated,
						MetricType,
						GoalPoints,
						MinPoints,
						QualificationNumber,
						Part,
						PK_AssociatedID,
						Countries,
						[Bonus],
						[QSVolume]
					FROM #tmp_DSQualDef
				
			END

		END

		--Step 5: Bonuses
		IF @Step >= 5
		BEGIN
			
			PRINT 'Executing step 5'

			------------------------------------------------------------------------------------------------
			-- 5.1 Getting bonuses
			------------------------------------------------------------------------------------------------
			------------------------------------------------------------------------------------------------
			-- * NEW SP BONUS 
			------------------------------------------------------------------------------------------------

				DROP TABLE IF EXISTS #bNewFQS
								 
				SELECT PK_Event,PK_Distributor,NewSPQualDate  AS SPQualDate 
				INTO #bNewFQS
				FROM #DS 
				WHERE 
					NewSPQualDate BETWEEN @NewFQSqualDateStart AND @NewFQSqualDateEnd --Applies for new SPs (SP for the first time) AND re-qualified SPs (had a demotion and then converted again to SP)		 
		
			------------------------------------------------------------------------------------------------
			-- * SPECIAL DOUBLE VOLUME
			------------------------------------------------------------------------------------------------

				DROP TABLE IF EXISTS #SpecialBonusFQS

				SELECT PK_Event, PK_Distributor, PK_Country, SPQualDate
				INTO #SpecialBonusFQS
				FROM #DS AS d WHERE DSSPTeam = 'SP' 
				AND NOT EXISTS (SELECT 1 FROM #bNewFQS AS n WHERE n.PK_Distributor = d.PK_Distributor) --This Promotion is not applicable for New Supervisors. 
			
				DROP TABLE IF EXISTS #SpecialBonusFQSMonth

				SELECT 
					d.PK_Event,
					d.PK_Distributor,
					IIF(d.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY, @PK_Event_CI, @PK_Event_CO, @PK_Event_BL, @PK_Event_EC, @PK_Event_GT_SV_HN_NI_CR,@PK_Event_VE,@PK_Event_DR), 202506,NULL)	AS RoyaltyMonth
				INTO #SpecialBonusFQSMonth
				FROM #SpecialBonusFQS AS d


			--// Bonus assignation
			
			DROP TABLE IF EXISTS #Event_DSPoints_Summary

			CREATE TABLE #Event_DSPoints_Summary
			(
				PK_Event [int],
				PK_Distributor [int],
				RoyaltyMonth [int],
				MetricType [varchar](10),
				PK_Country [int],
				[Points] [money], 
				[QSVolume] [bit],
				iSPQualDate [int],
				QualificationNumber [int],
				Part [int],
				iStartDate [int],
				iEndDate [int],
				[Countries] [varchar](max),
				row_num int
			)
					
			INSERT INTO #Event_DSPoints_Summary(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries,row_num)
			SELECT  
				U.PK_Event,
				U.PK_Distributor,
				U.RoyaltyMonth,
				U.MetricType,
				(SELECT nCountryID FROM v_Countries WHERE sCountryCode = '-W') AS PK_Country,
				SUM(U.Points) AS [Points],
				F.[QSVolume],
				F.iSPQualDate,
				F.QualificationNumber,
				F.Part,
				F.iStartDate,
				F.iEndDate,
				F.Countries, 
				ROW_NUMBER() OVER (PARTITION BY U.PK_Event,U.PK_Distributor,F.QualificationNumber ORDER BY U.RoyaltyMonth ) row_num
			FROM #Event_DSPoints AS U WITH (NOLOCK) 
				INNER JOIN #tmp_DSQualDef AS F
					ON u.PK_Distributor = F.PK_Distributor
			WHERE U.PK_Event = F.PK_Event AND F.MetricType = U.MetricType AND 
					U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
			GROUP BY U.PK_Event,U.PK_Distributor,U.RoyaltyMonth,U.MetricType,F.[QSVolume],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
								 	
			--Bonuses

			DROP TABLE IF EXISTS dbo.[WRK_25079_BonusPoints]

			SELECT 
					d.PK_Event,
					d.PK_Distributor,
					U.RoyaltyMonth,
					U.MetricType,
					(SELECT nCountryID FROM v_Countries WHERE sCountryCode = '-W') AS PK_Country,
					ISNULL(U.Points,0) AS [Points],
					U.[QSVolume],
					U.iSPQualDate,
					U.QualificationNumber,
					U.Part,
					U.iStartDate,
					U.iEndDate,
					U.Countries,
					IIF(b.PK_Distributor IS NOT NULL AND U.MetricType = 'TV' AND U.RoyaltyMonth >= CAST(CONVERT(varchar(6), d.SPQualDate, 112) AS int) AND @IsNewFQSBonusActive = 1,

						IIF(d.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_CI, @PK_Event_CO, @PK_Event_BL, @PK_Event_EC, @PK_Event_GT_SV_HN_NI_CR)
							AND U.QualificationNumber IN(15,16,17,18,19,20), U.Points,
						IIF(d.PK_Event IN (@PK_Event_AR_UY,@PK_Event_VE)
							AND U.QualificationNumber IN(12,13,14,15,16,17), U.Points,
						IIF(d.PK_Event = @PK_Event_DR 
							AND U.QualificationNumber IN(15,16,17,18), U.Points,
							
						IIF(d.PK_Event IN (@PK_Event_PM)
							AND U.QualificationNumber IN(21) AND U.RoyaltyMonth BETWEEN @VipPremiumBonusDateStart AND @VipPremiumBonusDateEnd, U.Points,
						IIF(d.PK_Event IN (@PK_Event_PE,@PK_Event_CO,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
							AND U.QualificationNumber IN(29) AND U.RoyaltyMonth BETWEEN @VipPremiumBonusDateStart AND @VipPremiumBonusDateEnd, U.Points,
						IIF(d.PK_Event IN (@PK_Event_AR_UY,@PK_Event_VE)
							AND U.QualificationNumber IN(26) AND U.RoyaltyMonth BETWEEN @VipPremiumBonusDateStart AND @VipPremiumBonusDateEnd, U.Points,							
						IIF(d.PK_Event IN (@PK_Event_CI)
							AND U.QualificationNumber IN(32) AND U.RoyaltyMonth BETWEEN @VipPremiumBonusDateStart AND @VipPremiumBonusDateEnd, U.Points,	
						IIF(d.PK_Event IN (@PK_Event_BL)
							AND U.QualificationNumber IN(30) AND U.RoyaltyMonth BETWEEN @VipPremiumBonusDateStart AND @VipPremiumBonusDateEnd, U.Points,	
							0))))))))
							
							,0) AS [NEW SP BONUS],

					IIF(c.PK_Distributor IS NOT NULL AND U.MetricType = 'TV' AND U.RoyaltyMonth = c.RoyaltyMonth AND @IsDoubleBonusActive = 1,

						IIF(d.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_CI, @PK_Event_CO, @PK_Event_BL, @PK_Event_EC, @PK_Event_GT_SV_HN_NI_CR)
							AND U.QualificationNumber IN(13,14,15,16,17,18,19,20), IIF(U.Points > 5000, 5000, U.Points),
						IIF(d.PK_Event IN (@PK_Event_AR_UY,@PK_Event_VE)
							AND U.QualificationNumber IN(12,13,14,15,16,17,26), IIF(U.Points > 5000, 5000, U.Points),
						IIF(d.PK_Event = @PK_Event_DR 
							AND U.QualificationNumber IN(15,16,17,18), IIF(U.Points > 5000, 5000, U.Points),

						IIF(d.PK_Event IN (@PK_Event_PM)
							AND U.QualificationNumber IN(21), IIF(U.Points > 5000, 5000, U.Points),
						IIF(d.PK_Event IN (@PK_Event_PE,@PK_Event_CO,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
							AND U.QualificationNumber IN(29), IIF(U.Points > 5000, 5000, U.Points),						
						IIF(d.PK_Event IN (@PK_Event_CI)
							AND U.QualificationNumber IN(32), IIF(U.Points > 5000, 5000, U.Points),	
						IIF(d.PK_Event IN (@PK_Event_BL)
							AND U.QualificationNumber IN(30), IIF(U.Points > 5000, 5000, U.Points),	

							0)))))))
							
							,0) AS [SPECIAL DOUBLE BONUS],

						U.row_num AS [Pos]
				INTO dbo.[WRK_25079_BonusPoints]
				FROM #DS AS d
					INNER JOIN #Event_DSPoints_Summary AS U WITH (NOLOCK)
						ON d.PK_Event = U.PK_Event AND d.PK_Distributor = U.PK_Distributor   
					LEFT JOIN #bNewFQS AS b
						ON d.PK_Event = b.PK_Event AND d.PK_Distributor = b.PK_Distributor
					LEFT JOIN #SpecialBonusFQSMonth AS c
						ON d.PK_Event = c.PK_Event AND d.PK_Distributor = c.PK_Distributor

			CREATE INDEX IX_WRK_25079_BonusPoints_PK_Distributor ON dbo.[WRK_25079_BonusPoints](PK_Distributor)

			INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 5, 5, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #tmp_DSPointsSummary

				CREATE TABLE #tmp_DSPointsSummary(
					[PK_Event] [int] NULL,
					[PK_Distributor] [int] NULL,
					[RoyaltyMonth] [int] NULL,
					[MetricType] [varchar](20) NULL,
					[PK_Country] [int] NULL,
					[Points] [money] NULL,
					[Bonus] [money] NULL,
					[QSVolume] [bit] NULL,
					[QSVolumePercentage] [int] NULL,
					[iSPQualDate] [int] NULL,
					[QualificationNumber] [int] NULL,
					[Part] [int] NULL,
					[HasBonus] [bit] NULL,
					[TotalPoints] [money] NULL,
					[iStartDate] [int] NULL,
					[iEndDate] [int] NULL,
					[Countries] [varchar](max) NULL
				)

				INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate)
				SELECT 
						P.PK_Event,
						P.PK_Distributor,
						P.RoyaltyMonth,			
						P.MetricType,
						P.PK_Country,
						P.[Points],
						P.QualificationNumber,
						P.Part,
						ISNULL([NEW SP BONUS],0) + ISNULL([SPECIAL DOUBLE BONUS] ,0) AS [Bonus], 
						P.[Points] + ISNULL([NEW SP BONUS],0) + ISNULL([SPECIAL DOUBLE BONUS] ,0) AS [TotalPoints],  
						P.iStartDate,
						P.iEndDate
					FROM dbo.[WRK_25079_BonusPoints] AS P WITH (NOLOCK)

				IF @IsDevQA = 0
				BEGIN
					
					INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 51, GETUTCDATE(), NULL);
					
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t
						INNER JOIN #Locations AS l
							ON t.PK_Event = l.PK_Event

					INSERT INTO [tmp].[DSPointsSummary](PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate)
					SELECT 
							PK_Event,
							PK_Distributor,
							RoyaltyMonth,
							MetricType,
							PK_Country,
							[Points],
							QualificationNumber,
							Part,
							[Bonus],
							[TotalPoints],
							iStartDate,
							iEndDate,
							iSPQualDate
						FROM #tmp_DSPointsSummary

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 5 AND [StepSubGroup] = 51;

				END
				ELSE IF @IsDevQA = 3
				BEGIN

					INSERT INTO ##DSPointsSummary_jgue(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate)
					SELECT 
							PK_Event,
							PK_Distributor,
							RoyaltyMonth,
							MetricType,
							PK_Country,
							[Points],
							QualificationNumber,
							Part,
							[Bonus],
							[TotalPoints],
							iStartDate,
							iEndDate,
							iSPQualDate
						FROM #tmp_DSPointsSummary

				END
				 
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 5;

		END

		--Step 6: Qualifiers by volume
		IF @Step >= 6
		BEGIN
			
			PRINT 'Executing step 6'

			------------------------------------------------------------------------------------------------
			-- 6.1 Getting qualifiers by volume according to qualification definitions
			------------------------------------------------------------------------------------------------
	
			INSERT INTO #TimeLog VALUES ('Qualifiers by volume', 6, 1, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #Executions

			CREATE TABLE #Executions(
				PK_Execution INT IDENTITY(1,1),
				PK_Event INT,
				OverwritePointsSummary BIT,
				QualType SMALLINT,
				Done BIT DEFAULT(0)
			)

			DROP TABLE IF EXISTS #Event_DSQualPoints

			CREATE TABLE #Event_DSQualPoints
			(
				[PK_Event] [int] NULL,
				[PK_Distributor] [int] NULL,
				[QualificationNumber] [int] NULL,
				[Part] [int] NULL,
				[QualDate] [datetime2](7) NULL
			)

			DECLARE @QualType SMALLINT  --1 = Accumulated/Non-Consecutive, 2 = Accumulated/Consecutive, 3 = Achieve/Consecutive, 4 = Achieve/Non-Consecutive
					,@PK_Execution INT
					,@PK_Event_Execution INT
					,@OverwritePointsSummary BIT

				DELETE FROM #Executions

				INSERT INTO #Executions(PK_Event,OverwritePointsSummary,QualType)
				SELECT DISTINCT
					PK_Event, 
					0 AS OverwritePointsSummary,
					 IIF(Accumulated = 0 AND Consecutive = 0, 4, --Achieve Non-Consecutive
						IIF( Accumulated = 0 AND Consecutive = 1, 3, --Achieve Consecutive
							IIF(Accumulated = 1 AND Consecutive = 1, 2, --Accumulated Consecutive
								IIF(Accumulated = 1 AND Consecutive = 0, 1,NULL)))) --Accumulated Non-Consecutive
						AS QualType 
				FROM #Event_SetupEventQualification					 
					 
				WHILE EXISTS (SELECT 1 FROM #Executions WHERE Done = 0)
				BEGIN

					SELECT TOP 1 
						@PK_Execution = PK_Execution,
						@QualType = QualType,
						@PK_Event_Execution = PK_Event,
						@OverwritePointsSummary = OverwritePointsSummary
					FROM #Executions 
					WHERE Done = 0

					
				IF @IsDevQA = 0
				BEGIN
					 
					 --Input [tmp].[DSPointsSummary]
					EXEC dbo.usp_GetQualifier_Points @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					--Output [Event].[DSQualPoints]
				END
				ELSE IF @IsDevQA = 3
				BEGIN
					 
					 --Input 
					 --##DSPointsSummary_jgue
					 --##Event_DSPoints_jgue
					 --##tmp_DSQualDef_jgue
					 --##Event_SetupEventQualification_jgue
					EXEC ##usp_GetQualifier_Points_jgue @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					--Output 
					--##DSQualPoints_jgue
				END

				IF @IsDevQA = 3
				BEGIN
					INSERT INTO #Event_DSQualPoints([PK_Event],PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						@PK_Event_Execution AS [PK_Event]
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM ##DSQualPoints_jgue AS Q
					WHERE PK_Event = @PK_Event_Execution
					AND NOT EXISTS (SELECT 1 FROM #Event_DSQualPoints WHERE PK_Distributor = Q.PK_Distributor AND PK_Event = Q.PK_Event AND QualificationNumber = Q.QualificationNumber AND Part = Q.Part AND QualDate = Q.QualDate )
				END
				ELSE
				BEGIN
					INSERT INTO #Event_DSQualPoints([PK_Event],PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						[PK_Event]
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK)
					WHERE Q.PK_Event = @PK_Event_Execution
					AND NOT EXISTS (SELECT 1 FROM #Event_DSQualPoints WHERE PK_Distributor = Q.PK_Distributor AND PK_Event = Q.PK_Event AND QualificationNumber = Q.QualificationNumber AND Part = Q.Part AND QualDate = Q.QualDate )
				END

				UPDATE #Executions
				SET Done = 1
				WHERE PK_Execution = @PK_Execution

				END
				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;

		END
			
		--Step 7: Qualifications
		IF @Step >= 7
		BEGIN
			
			PRINT 'Executing step 7'

			INSERT INTO #TimeLog VALUES ('#EventQual', 4, 1, GETUTCDATE(), NULL);

			------------------------------------------------------------------------------------------------
			-- General qualifications
			------------------------------------------------------------------------------------------------
			BEGIN

				INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q04,Q05,Q06,Q09,Q10,Q21,Q31,Q34,Q35,Q45,Q47,Q48,Q50)
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP',1,0)																									AS Q01, --	FQS 
					IIF(d.NewSPQualDate BETWEEN @NewFQSQualDateStart AND @NewFQSQualDateEnd, 1, 0)												AS Q02, --	New FQS (SP Qual date Jul 2025 - Oct 2025) 
					IIF(d.QSActualQualDate BETWEEN @QSActualQualDateStart AND @QSActualQualDateEnd,1,0)											AS Q03, --	QS, QV, PQS, SQS, 2QS, 5QS (Qual date: Oct 2025)
					IIF(d.NewWTQualDate > d.NewSPQualDate AND d.NewWTQualDate BETWEEN '2025-07-01' AND '2025-10-31',1,0)						AS Q04,	--	New WT (WT Qual date Jul 2025 - Oct 2025)
					IIF(d.DSCurrentTeam IN ('G','M','P','A','B','C'), 1,0)																		AS Q05, --	TAB team
					IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0)																				AS Q06, --	PT and above
					IIF(d.PK_Event = @PK_Event_DR AND d.DSSPTeam = 'DS',1,0)																	AS Q09, --	DS (Non SP)
					IIF(d.PK_Event = @PK_Event_DR AND d.dQPDemotion = '1900-01-01' 
						AND d.dQPQualification BETWEEN @NewQPDateStart AND @NewQPDateEnd,1,0)													AS Q10, -- New Qualified Producer (Jul 2025 - Oct 2025)
					IIF(d.PK_Event = @PK_Event_CI AND d.DSSubTeam IN ('SP','WT'),1,0)															AS Q21, -- FQS non-TAB (SP & WT)
					IIF(d.PK_Event = @PK_Event_DR AND d.DSSubTeam = 'PQP' AND @CurrentDatetime BETWEEN '2025-10-01' AND '2025-10-31' 
						AND NOT EXISTS (SELECT 1 FROM #DSSNAPSHOT WHERE PK_Distributor = d.PK_Distributor AND SUBTYPECODE = 'PQP'
												AND ROYALTYMONTH < 202510),1,0)																	AS Q31, -- New PQP (Pending Qualified Producer) (Oct 2025)
					IIF((d.PK_Event = @PK_Event_CO AND d.NewWTQualDate BETWEEN @NewWTQualDateStart AND  @NewWTQualDateEnd) 
						OR (d.PK_Event = @PK_Event_EC AND d.DSSPTeam = 'SP' AND d.[SPQualDate] BETWEEN '2025-03-01' AND '2025-06-30' ),1,0)		AS Q34, -- WT (WT Qual or Requal date Jun 2025 - Oct 2025) Volume month May 2025 - Sep 2025 OR FQS (SP Qual date Mar 2025 - Jun 2025)
					IIF(d.PK_Event = @PK_Event_CO AND d.DSSubTeam =	'WT',1,0)																	AS Q35, -- WT
					d.IsTicketPurchaser																											AS Q45, -- Ticket
					d.IsFromList																												AS Q47,	-- List
					IIF(D.DSSubTeam IN ('QS','QV','PQS','SQS','2QS','5QS'),1,0)																	AS Q48, -- Include: QS, QV, PQS, SQS, 2QS, 5QS SubTypeCodes
					d.IsFromCOP																													AS Q50	-- COP
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
				AND d.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR, @PK_Event_VE, @PK_Event_DR) 				

				UPDATE E
					SET	Q01 = ISNULL(IIF(d.DSSubTeam IN ('QS','QV','PQS','SQS','2QS','5QS') OR d.DSSPTeam = 'SP',1,0),0), --Q01 - QS and above Note: QS should include QS, QV, PQS, SQS, 2QS, 5QS
						Q36 =ISNULL((
								SELECT 1 FROM dbo.SubEventQualifier T (NOLOCK)
								INNER JOIN dbo.SubEvent S ON T.PK_SubEvent = S.PK_SubEvent
								WHERE S.PK_Event = 203602 AND S.SubEventNumber = 1 AND T.RemovedUTC='2049-12-31' AND T.PK_Distributor = d.PK_Distributor
								),0), -- Qualified to E1 of "26010 - Honors 2026" (PK 203602)
						Q37 = ISNULL(d.IsFromCOP,0)
				FROM #EventQual E
				INNER JOIN #DS AS d
					ON E.PK_Event = d.PK_Event AND E.PK_Distributor = d.PK_Distributor
				WHERE 
					d.PK_Event = @PK_Event_BL			

				-- New SP Bonus
				UPDATE D
				SET NewSPBonus = 1
				FROM #DS D
				WHERE 
				EXISTS (SELECT 1 FROM #bNewFQS WHERE PK_Event = D.PK_Event AND PK_Distributor = D.PK_Distributor)

				-- AWT (Non-TAB) (Qual dates Jun 2025 - Sep 2025) (Qualified OR Re-qualified)
				DROP TABLE IF EXISTS #AWT_QualRequal_Jun25Sep25
 
				SELECT d.PK_Distributor, d.PK_Event 
					INTO #AWT_QualRequal_Jun25Sep25
				FROM #DS AS d  
 				INNER JOIN dbo.[AWT] AS a WITH (NOLOCK)
 	 				ON d.PK_Distributor = a.PK_Distributor  AND a.IsNonTab = 1
				INNER JOIN [dbo].[AWT_Qualifiers_Tracking] AS t WITH (NOLOCK)
					ON a.PK_Distributor = t.PK_Distributor AND a.AWTYear = t.AWTYear
 				WHERE (a.AWTYear = 2025 AND (t.[Jun] = 1 OR t.[Jul] = 1 OR t.[Aug] = 1 OR t.[Sep] = 1))


				--Q7 AWT (Non-TAB) (Qual dates Jun 2025 - Sep 2025) (Qualified OR Re-qualified)
				UPDATE E
				SET	Q07 = 1
				FROM #EventQual E
				WHERE 
					EXISTS (SELECT 1 FROM #AWT_QualRequal_Jun25Sep25 WHERE PK_Event = E.PK_Event AND PK_Distributor = E.PK_Distributor)

				UPDATE D
				SET IsAWT2025 = 1
				FROM #DS D
				WHERE 
					EXISTS (SELECT 1 FROM #AWT_QualRequal_Jun25Sep25 WHERE PK_Event = D.PK_Event AND PK_Distributor = D.PK_Distributor)

			END
						
			------------------------------------------------------------------------------------------------
			-- List qualifications
			------------------------------------------------------------------------------------------------
			IF EXISTS (SELECT 1 FROM #ListsIDs) 
			BEGIN

				DROP TABLE IF EXISTS #UniqueListID

				SELECT DISTINCT ListID,IDENTITY(INT,1,1) AS ID  
				INTO #UniqueListID
				FROM #ListsIDs
				ORDER BY ListID

				SET @ColumnToPivot = ''
				SET @SqlStatement = ''

				SELECT 
					@ColumnToPivot+=QUOTENAME(m.ListID) + ','
				FROM 
					#UniqueListID AS  m
				ORDER BY 
					ListID;
									
				SET @ColumnToPivot = LEFT(@ColumnToPivot, LEN(@ColumnToPivot) - 1); -- remove the last comma
							 
				DROP TABLE IF EXISTS ##DSList_Pivot				
 
				SET @SqlStatement = N'SELECT A.PK_Distributor AS [PK_Distributor_List], A.PK_Event AS [PK_Event_List], ' + @ColumnToPivot  + 
				'INTO ##DSList_Pivot' +
				' FROM #EventQual A
				LEFT JOIN 
				(
					SELECT  PK_Distributor, PK_Event,' + @ColumnToPivot +' FROM 
					(
						SELECT  PK_Distributor,PK_Event, ListID, UniqueID
							FROM #DSList
					) P
					PIVOT
					(
					COUNT (UniqueID)
					FOR ListID IN
					( 
						'+ @ColumnToPivot +')
					) AS pvt
				) L
				ON A.PK_Distributor = L.PK_Distributor AND A.PK_Event = L.PK_Event'

				EXECUTE sp_executesql @SqlStatement
 
				IF OBJECT_ID('tempdb..##DSList_Pivot') IS NOT NULL
				BEGIN

					--) Setting default values on lists fields

					SET @SqlStatement = 'UPDATE P SET '

					SELECT 	@SqlStatement+=QUOTENAME(m.ListID) + '= ISNULL('+QUOTENAME(m.ListID)+',0), '
					FROM #UniqueListID AS  m
					ORDER BY m.ListID;

					SET @SqlStatement = LEFT(@SqlStatement, LEN(@SqlStatement) - 1) -- remove the last comma
					SET @SqlStatement= @SqlStatement + ' FROM ##DSList_Pivot AS P'

					EXECUTE sp_executesql @SqlStatement

				END

				DROP TABLE IF EXISTS #ListsQualificationMapping

				SELECT  PK_Event, ListID, QColumn = 'Q' +   IIF(QId < 10,  '0' + CAST(QId AS VARCHAR), CAST(QId  AS VARCHAR))  
				INTO #ListsQualificationMapping
				FROM #ListsQsMapping
			
				SET @SqlStatement = '';					

				SELECT  @SqlStatement += N'IF NOT EXISTS (SELECT 1 FROM tempdb.sys.columns WITH (NOLOCK) WHERE [object_id] = object_id(''tempdb..#EventQual'') AND name ='''+ [QColumn] +''') BEGIN ALTER TABLE #EventQual ADD [' + [QColumn] + '] BIT DEFAULT 0; END; '
				FROM #ListsQualificationMapping AS M

				EXECUTE sp_executesql @SqlStatement

				SET @SqlStatement = '';

				SELECT  @SqlStatement+= 'UPDATE E ' +
						' SET ' + [QColumn] + ' = L.[' + CAST(ListID AS NVARCHAR(MAX))  + ']' +
						' FROM #EventQual AS E INNER JOIN ##DSList_Pivot AS L
						ON E.PK_Event = L.PK_Event_List 
						AND E.PK_Distributor = L.PK_Distributor_List
						AND L.PK_Event_List = ' + CAST(PK_Event AS NVARCHAR(MAX)) + ';'							
				FROM #ListsQualificationMapping AS M
			 	
				EXECUTE sp_executesql @SqlStatement

			END
	
			------------------------------------------------------------------------------------------------
			-- SKUs qualifications
			------------------------------------------------------------------------------------------------
			IF EXISTS (SELECT 1 FROM #SKUs)
			BEGIN
			
				DROP TABLE IF EXISTS #UniqueSKUsID

				SELECT DISTINCT SKUCode,IDENTITY(INT,1,1) AS ID  
				INTO #UniqueSKUsID
				FROM #SKUs

				SET @ColumnToPivot = ''
				SET @SqlStatement = ''

				SELECT 
					@ColumnToPivot+=QUOTENAME(m.SKUCode) + ','
				FROM 
					#UniqueSKUsID AS  m
				ORDER BY 
					SKUCode;
									
				SET @ColumnToPivot = LEFT(@ColumnToPivot, LEN(@ColumnToPivot) - 1); -- remove the last comma
							 
				DROP TABLE IF EXISTS ##DSSKU_Pivot				
 
				SET @SqlStatement = N'SELECT A.PK_Distributor AS [PK_Distributor_SKU], A.PK_Event AS [PK_Event_SKU], ' + @ColumnToPivot  + 
				'INTO ##DSSKU_Pivot' +
				' FROM #EventQual A
				LEFT JOIN 
				(
					SELECT  PK_Distributor, PK_Event,' + @ColumnToPivot +' FROM 
					(
						SELECT  PK_Distributor,PK_Event, SKUCode, UniqueID
							FROM #DSSKUs
					) P
					PIVOT
					(
					COUNT (UniqueID)
					FOR SKUCode IN
					( 
						'+ @ColumnToPivot +')
					) AS pvt
				) L
				ON A.PK_Distributor = L.PK_Distributor AND A.PK_Event = L.PK_Event'

				EXECUTE sp_executesql @SqlStatement
 
				IF OBJECT_ID('tempdb..##DSSKU_Pivot') IS NOT NULL
				BEGIN

					--) Setting default values on lists fields

					SET @SqlStatement = 'UPDATE P SET '

					SELECT 	@SqlStatement+=QUOTENAME(m.SKUCode) + '= ISNULL('+QUOTENAME(m.SKUCode)+',0), '
					FROM #UniqueSKUsID AS  m
					ORDER BY m.SKUCode;

					SET @SqlStatement = LEFT(@SqlStatement, LEN(@SqlStatement) - 1) -- remove the last comma
					SET @SqlStatement= @SqlStatement + ' FROM ##DSSKU_Pivot AS P'

					EXECUTE sp_executesql @SqlStatement

				END

				DROP TABLE IF EXISTS #SKUsQualificationMapping

				SELECT QColumn = 'Q' +   IIF(QId < 10,  '0' + CAST(QId AS VARCHAR), CAST(QId  AS VARCHAR)),SKUCode, PK_Event 
				INTO #SKUsQualificationMapping
				FROM #SKUsQsMapping
			 
	
				SET @SqlStatement = '';
	
				SELECT  @SqlStatement += N'IF NOT EXISTS (SELECT 1 FROM tempdb.sys.columns WITH (NOLOCK) WHERE [object_id] = object_id(''tempdb..#EventQual'') AND name ='''+ [QColumn] +''') BEGIN ALTER TABLE #EventQual ADD [' + [QColumn] + '] BIT DEFAULT 0; END; '
				FROM #SKUsQualificationMapping AS M

				EXECUTE sp_executesql @SqlStatement

				SET @SqlStatement = '';

				SELECT  @SqlStatement+= 'UPDATE E ' +
					 ' SET ' + [QColumn] + ' = ' + STRING_AGG('L.[' + CAST(SKUCode AS NVARCHAR(MAX))  + ']' , ' | ') +
					 ' FROM #EventQual AS E INNER JOIN ##DSSKU_Pivot AS L
						ON E.PK_Event = L.PK_Event_SKU 
						AND E.PK_Distributor = L.PK_Distributor_SKU;'					
				FROM #SKUsQualificationMapping AS M
				GROUP BY QColumn
			 	
				EXECUTE sp_executesql @SqlStatement
		
			END	
			
			------------------------------------------------------------------------------------------------
			-- Volume qualifications
			------------------------------------------------------------------------------------------------
			BEGIN
			
			DROP TABLE IF EXISTS #QualificationsMapping

			SELECT 
			IDENTITY(INT,1,1) AS ID, 
			PK_Event,QualificationNumber,[Part], 
			IIF(QualificationNumber < 10, 'Q0' + CAST(QualificationNumber AS VARCHAR(5)), 'Q' + CAST(QualificationNumber AS VARCHAR(5))) AS  QColumn, 
			[HasQualReference],
			0 AS [ctrl]
			INTO #QualificationsMapping
			FROM #Event_SetupEventQualification
			ORDER BY PK_Event,QualificationNumber,[Part]

			--Getting qualifiers by qualification number
		
			DECLARE @QualificationNumber INT, @QPK_Event INT, @ID INT, @QPart INT, @QColumn VARCHAR(10)

			WHILE EXISTS (SELECT 1 FROM #QualificationsMapping AS m WHERE [ctrl] = 0 AND Part = 1)
			BEGIN
					
				SELECT @ID = MIN(ID) FROM #QualificationsMapping AS m WHERE [ctrl] = 0 AND Part = 1

				SELECT 
					@QualificationNumber = m.QualificationNumber,
					@QPK_Event = m.PK_Event,
					@QColumn = m.QColumn
				FROM #QualificationsMapping AS m WHERE [ID] = @ID

				DROP TABLE IF EXISTS #QAdditionalParts

				SELECT PK_Event,QualificationNumber,Part, 0 AS [ctrl] 
				INTO #QAdditionalParts
				FROM #QualificationsMapping AS m 
				WHERE PK_Event = @QPK_Event AND QualificationNumber = @QualificationNumber AND Part != 1
				AND [HasQualReference] = 1 

				DROP TABLE IF EXISTS ##QualVolumeQualifiers_25079

				SET @SqlStatement = ''

				SET @SqlStatement = N'SELECT Q1.PK_Event,Q1.PK_Distributor	
				INTO ##QualVolumeQualifiers_25079
				FROM #Event_DSQualPoints AS Q1 WHERE (Q1.QualificationNumber = '+ CAST(@QualificationNumber AS VARCHAR(10)) +' AND Q1.Part = 1 AND Q1.PK_Event =' + CAST(@QPK_Event AS VARCHAR(10)) +' ) '
					
				IF @SqlStatement != ''
				BEGIN
					WHILE EXISTS (SELECT 1 FROM #QAdditionalParts WHERE [ctrl] = 0)
					BEGIN

						SELECT @QPart = Part FROM #QAdditionalParts WHERE [ctrl] = 0 AND QualificationNumber = @QualificationNumber

						SET @SqlStatement += ' AND EXISTS ( SELECT Q'+ CAST(@QPart AS VARCHAR(5)) +'.PK_Distributor FROM #Event_DSQualPoints AS Q'+ CAST(@QPart AS VARCHAR(5)) +'  
						WHERE (Q'+ CAST(@QPart AS VARCHAR(5)) +'  .QualificationNumber = '+ CAST(@QualificationNumber AS VARCHAR(10)) +' AND Q'+CAST(@QPart AS VARCHAR(10))+'.Part = '+ CAST(@QPart AS VARCHAR(10)) +')
						AND Q1.PK_Distributor = Q'+ CAST(@QPart AS VARCHAR(5)) +'.PK_Distributor AND Q1.QualificationNumber = Q'+ CAST(@QPart AS VARCHAR(5)) +'.QualificationNumber AND Q1.PK_Event = Q'+ CAST(@QPart AS VARCHAR(5)) +'.PK_Event)'

						UPDATE #QAdditionalParts
						SET [ctrl] = 1
						WHERE QualificationNumber = @QualificationNumber AND Part = @QPart

					END
												
				END

				EXECUTE sp_executesql @SqlStatement

				SET @SqlStatement = ''

				SET @SqlStatement = 'UPDATE Q
				SET ' + @QColumn + ' = 1' +
				' FROM #EventQual Q
				INNER JOIN ##QualVolumeQualifiers_25079 AS QQ
				ON Q.PK_Event = QQ.PK_Event
				AND Q.PK_Distributor = QQ.PK_Distributor'

				EXECUTE sp_executesql @SqlStatement

				UPDATE #QualificationsMapping
				SET [ctrl] = 1
				WHERE ID = @ID

			END

			END
	
			DELETE FROM #EventQual
						WHERE ( 
								~Q01  & ~Q02 & ~Q03 & ~Q04 & ~Q05 &
								~Q06  & ~Q07 & ~Q08 & ~Q09 & ~Q10 &
								~Q11  & ~Q12 & ~Q13 & ~Q14 & ~Q15 &
								~Q16  & ~Q17 & ~Q18 & ~Q19 & ~Q20 &
								~Q21  & ~Q22 & ~Q23 & ~Q24 & ~Q25 &
								~Q26  & ~Q27 & ~Q28 & ~Q29 & ~Q30 &
								~Q31  & ~Q32 & ~Q33 & ~Q34 & ~Q35 &
								~Q36  & ~Q37 & ~Q38 & ~Q39 & ~Q40 &
								~Q41  & ~Q42 & ~Q43 & ~Q44 & ~Q45 &
								~Q46  & ~Q47 & ~Q48 & ~Q49 & ~Q50 
							)= 1 

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 1; 

		END
 
		--Step 8: Subevents
		IF @Step >= 8
		BEGIN

			PRINT 'Executing step 8'

			INSERT INTO #TimeLog VALUES ('Es #EventQual', 8, 1, GETUTCDATE(), NULL);
	 
			--PM
			UPDATE 
				#EventQual
			SET
				E01 = (((Q45 | Q50) & ((Q01 & (Q09 | Q13 | Q14)) | Q02 | Q03 | Q06)) | Q22),
				E02 = (((Q45 | Q50) & ((Q01 & (Q10 | Q11 | Q12 | Q15 | Q16)) | Q06 | Q07)) | Q08 | Q23),
				E04 = (((Q45 | Q50) & ((Q01 & (Q19 | Q20)) | Q06)) | Q25),
				E05 = (((Q45 | Q50) & (Q01 & Q21)) | Q26),
				E06 = (((Q45 | Q50) & (Q02 | Q03)) | Q27),
				E09 = (Q30),
				E10 = (Q31),
				E11 = (Q32),
				E12 = (Q33)
			WHERE PK_Event IN (@PK_Event_PM)

			UPDATE 
				#EventQual
			SET
				E03 = (((Q45 | Q50) & ((Q01 & (Q17 | Q18)) | Q06)) | Q24 | (Q04 & E01)),
				E07 = (E01 & Q28),
				E08 = ((E01 & ((Q45 | Q50) & (Q05))) | Q29)
			WHERE PK_Event IN (@PK_Event_PM)

			UPDATE 
				#EventQual
			SET
				E01 = (((Q45 | Q50) & ((Q01 & (Q09 | Q13 | Q14)) | Q02 | Q03 | Q06)) | Q21),
				E08 = (Q28)
			WHERE PK_Event IN (@PK_Event_PE,@PK_Event_CO,@PK_Event_GT_SV_HN_NI_CR)

			UPDATE 
				#EventQual
			SET
				E01 = (((Q45 | Q50) & ((Q01 & (Q09 | Q13 | Q14)) | Q02 | Q03 | Q06 | Q34)) | Q21),
				E08 = (Q28 | Q34)
			WHERE PK_Event IN (@PK_Event_EC)

			UPDATE 
				#EventQual
			SET
				E01 = (((Q45 | Q50) & ((Q01 & (Q09 | Q13 | Q14)) | Q02 | Q03) | Q06) | Q21)
			WHERE PK_Event IN (@PK_Event_BL)	

			UPDATE 
				#EventQual
			SET
				E03 = (((Q45 | Q50) & ((Q01 & (Q17 | Q18)) | Q06)) | Q23 | ((Q45 | Q50) & (Q04 & E01))),
				E04 = (((Q45 | Q50) & ((Q01 & (Q19 | Q20)) | Q06)) | Q24),
				E05 = (((Q45 | Q50) & (Q02 | Q03)) | Q25)
			WHERE PK_Event IN (@PK_Event_PE,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)

			UPDATE 
				#EventQual
			SET
				E02 = (((Q45 | Q50) & ((Q01 & (Q10 | Q11 | Q12 | Q15 | Q16)) | Q06 | Q07)) | Q08 | Q22)
			WHERE PK_Event IN (@PK_Event_PE,@PK_Event_GT_SV_HN_NI_CR)

			UPDATE 
				#EventQual
			SET
				E02 = (((Q45 | Q50) & ((Q01 & (Q10 | Q11 | Q12)) | Q06)) | Q08 | Q22)
			WHERE PK_Event IN (@PK_Event_BL)

			UPDATE 
				#EventQual
			SET
				E02 = (((Q45 | Q50) & ((Q01 & (Q10 | Q11 | Q12 | Q15 | Q16)) | Q06 | Q07)) | Q08 | Q22 | ((Q45 | Q50) & (E01 & Q05))),
				E10 = (((Q45 | Q50) & (E01 & Q05)) | Q31),
				E11 = (Q32),
				E12 = (Q33)
			WHERE PK_Event IN (@PK_Event_EC)

			UPDATE 
				#EventQual
			SET
				E06 = (E01 & Q26)
			WHERE PK_Event IN (@PK_Event_PE,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
								
			UPDATE 
				#EventQual
			SET
				E07 = (Q27) -- NOT BL
			WHERE PK_Event IN (@PK_Event_PE,@PK_Event_CO,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)
					
			UPDATE 
				#EventQual
			SET
				E10 = (Q31),
				E11 = (Q32)
			WHERE PK_Event IN (@PK_Event_PE,@PK_Event_GT_SV_HN_NI_CR)
			
		 	--PK_Event_AR_UY_PY
			UPDATE 
				#EventQual
			SET
				E01 = (((Q45 | Q50) & (Q01 | Q02 | Q03)) | Q18),
				E02 = (((Q45 | Q50) & ((Q01 & (Q09 | Q10 | Q11 | Q12 | Q13)) | Q06 | Q07)) | Q08 | Q19),
				E07 = (((Q45 | Q50) & (Q05 | Q07)) | Q08 | Q24),
				E12 = (Q30)
			WHERE PK_Event IN (@PK_Event_AR_UY)

		 	--VE
			UPDATE 
				#EventQual
			SET
				E01 = (((Q45 | Q50) & (Q01 | Q02 | Q03 | Q06)) | Q18),
				E02 = (((Q45 | Q50) & ((Q01 & (Q12 | Q13)) | Q07)) | Q05 | Q19 | Q07 | Q08),
				E07 = (Q24)
			WHERE PK_Event IN (@PK_Event_VE)

			--PK_Event_AR_UY_PY,PK_Event_VE
			UPDATE 
				#EventQual
			SET
				E03 = (((Q45 | Q50) & ((Q01 & (Q14 | Q15)) | Q06)) | Q20 | ((Q45 | Q50) & (Q04 & E01))),
				E04 = (((Q45 | Q50) & ((Q01 & (Q16 | Q17)) | Q06)) | Q21),
				E05 = (((Q45 | Q50) & (Q02 | Q03)) | Q22),
				E06 = (E01 & Q23),
				E08 = (Q25),
				E09 = (((Q45 | Q50) & (Q01 & Q26)) | Q27),
				E10 = (Q28),
				E11 = (Q29)
			WHERE PK_Event IN (@PK_Event_AR_UY,@PK_Event_VE)

		 	--CI
			UPDATE 
				#EventQual
			SET
				E01 = (((Q45 | Q50) & ((Q01 & (Q09 | Q13 | Q14)) | Q02 | Q03 | Q06)) | Q23),
				E04 = (((Q45 | Q50) & ((Q01 & (Q19 | Q20)) | Q06)) | Q26),
				E05 = (((Q45 | Q50) & (Q02 | Q03)) | Q27),
				E08 = (Q30),
				E09 = (Q31)
			WHERE PK_Event IN (@PK_Event_CI)

		 	--CI
			UPDATE 
				#EventQual
			SET
				E02 = (((Q45 | Q50) & ((Q01 & (Q10 | Q11 | Q12 | Q15 | Q16)) | Q06 | Q07 | (E01 & Q05))) | Q08 | Q24),
				E03 = (((Q45 | Q50) & ((Q01 & (Q17 | Q18)) | Q06)) | Q25 | ((Q45 | Q50) & (Q04 & E01))),
				E06 = (E01 & Q28),
				E07 = (((Q45 | Q50) & ((E01 & (Q05 | (Q21 & Q22))))) | Q08 | Q29),
				E10 = (((Q45 | Q50) & (Q01 & Q32)) | Q33),
				E11 = (Q34),
				E12 = (Q35)
			WHERE PK_Event IN (@PK_Event_CI)

		 	--CO
			UPDATE 
				#EventQual
			SET
				E02 = (((Q45 | Q50) & ((Q01 & (Q10 | Q11 | Q12 | Q15 | Q16)) | Q06 | Q07)) | Q08 | Q22),
				E10 = (((Q45 | Q50) & (Q34 | (Q36 & (Q05 | Q35)))) | Q31),
				E11 = (Q32),
				E12 = (Q33)
			WHERE PK_Event IN (@PK_Event_CO)

		 	--BL				
			UPDATE 
				#EventQual
			SET
				E07 = (((Q45 | Q50) & ((E01 & Q05))) | Q27),
				E09 = (Q29),
				E10 = (((Q45 | Q50) & (Q01 & Q30)) | Q31),
				E11 = (Q32),
				E12 = (Q33),
				E13 = (Q34),
				E14 = (Q35)
			WHERE PK_Event IN (@PK_Event_BL)

		 	--DR
			UPDATE 
				#EventQual
			SET
				E01 = (((Q45 | Q50) & ((Q01 & (Q12 | Q13 | Q14)) | Q02 | Q03 | Q06)) | Q19),
				E04 = (((Q45 | Q50) & ((Q01 & (Q17 | Q18)) | Q06)) | Q22),
				E05 = (((Q45 | Q50) & (Q02 | Q03)) | Q23),
				E07 = (Q25),
				E08 = (Q26)
			WHERE PK_Event IN (@PK_Event_DR)

			--DR
			UPDATE 
				#EventQual
			SET
				E02 = (((Q45 | Q50) & (((Q01 | (Q09 & Q11) | Q10 | Q31) & ~E01))) | Q20),
				E03 = (((Q45 | Q50) & ((Q01 & (Q15 | Q16)) | Q06 | (Q04 & E01))) | Q21),
				E06 = (E01 & Q24),
				E10 = (Q29),
				E11 = (Q30)
			WHERE PK_Event IN (@PK_Event_DR)

			--DR
			UPDATE 
				#EventQual
			SET
				E09 = (((Q45 | Q50) & (Q01 & Q29)) | Q30)
			WHERE PK_Event IN (@PK_Event_PE,@PK_Event_CO,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR)

			UPDATE 
				#EventQual
			SET
				E40 = (E01 | E02 | E03 | E04 | E05 | E06 | E07 | E08 | E09 | E10 | E11 | E12 | E13 | E14 | E15 | E16 | E17 | E18 | E19 | E20)
			WHERE PK_Event IN (@PK_Event_PM,@PK_Event_PE,@PK_Event_AR_UY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV_HN_NI_CR,@PK_Event_VE,@PK_Event_DR)

			DROP TABLE IF EXISTS dbo.WRK_SAMCAM_LDW_FSL_Oct25

			SELECT 
					PK_Event			
					,PK_Distributor		
					,DistributorID		
					,DSCurrentTeam		     
					,DSSubTeam			     
					,DSSPTeam			
					,NewSPQualDate		
					,NewWTQualDate		
					,dSPQualDate			
					,SPQualDate			
					,dSPReQualDate		
					,RequalSPQualDate	
					,CountryCode			
					,PK_Country			
					,QSQualDate					
					,QSActualQualDate		
					,dSPDemotionDate		
					,IsFromCOP			
					,IsFromList			
					,IsTicketPurchaser	
					,dQPQualification	
					,dQPDemotion			
					,IsAWT2025			
					,NewSPBonus			
			INTO dbo.WRK_SAMCAM_LDW_FSL_Oct25
			FROM #DS

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 8 AND [StepSubGroup] = 1;

		END

		--Step 10: [Event].[DSQual]	
		IF @Step >= 10
		BEGIN
			
			PRINT 'Executing step 10'

			IF @IsDevQA = 0
			BEGIN

				IF OBJECT_ID (N'[tmp].[DSQual]', N'U') IS NOT NULL 
				BEGIN
					DELETE dq			
					FROM [tmp].[DSQual] AS dq
						INNER JOIN #Locations AS l
							ON dq.PK_Event = l.PK_Event
				END

				DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Distributor_PK_Event]
							ON [Event].[DSQual];

				DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Event]
							ON [Event].[DSQual];

				DELETE dq			
				FROM [Event].[DSQual] AS dq
					INNER JOIN #Locations AS l
						ON dq.PK_Event = l.PK_Event

				INSERT INTO [Event].[DSQual](
				PK_Event		
				,PK_Distributor	
				,CreatedDate	
				,UpdatedDate	
				,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
				,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
				,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
				,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
				,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50					
				,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
				,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
				,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
				,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
				,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
				)
				SELECT
				PK_Event		
				,PK_Distributor	
				,CreatedDate	
				,UpdatedDate	
				,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
				,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
				,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
				,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
				,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50					
				,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
				,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
				,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
				,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
				,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
			FROM #EventQual

				CREATE INDEX [IX_Event_DSQual_PK_Event] ON [Event].[DSQual](PK_Event);
				CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);

			END
			
		END
	 
		--Step 11: SubEventQualifiers
		IF @Step >= 11  AND  @IsDevQA = 0
		BEGIN

			PRINT 'Executing step 11'
		
			DECLARE @Events VARCHAR(MAX)
				
			SELECT @Events = STRING_AGG(PK_Event,',') FROM #Locations

			EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
			@Events = @Events,
			@Source = 2,
			@EvaluateFormula = 0		

		END
	 
END

/******************************************************************************
				END PROCEDURE
******************************************************************************/
		
		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
		 	@StoredProcedureName = @StoredProcedure
		 	,@StartTime = @StartTime;

		IF @IsDevQA = 1
		BEGIN
		SELECT 
		 	[Milestone]		
		 	,[StepGroup]	
		 	,[StepSubGroup] 
		 	,[StepStart]	
		 	,[Duration]		
		FROM #TimeLog
		END	
		
END TRY
BEGIN CATCH
 	SET @Error = ERROR_NUMBER()
 	SET @ErrorMessage = ERROR_MESSAGE()
 	SET @StoredProcedure = ERROR_PROCEDURE()

 	IF @IsDevQA = 0 
	BEGIN  
		SELECT ERROR_LINE() AS ErrorLine;  		
		SELECT @Error AS [Error], @ErrorMessage AS [Error Message];
	END  

 	-- UPDATE ERROR LOG
 	EXEC dbo.usp_Utility_UpdateErrorLog 
 			@ProcedureName = @StoredProcedure
 			,@ErrorNumber = 3
 			,@ErrorMessage = @ErrorMessage
 			,@SQLErrorCode = @Error
 			,@SQLErrorMsg = @ErrorMessage
END CATCH;
END