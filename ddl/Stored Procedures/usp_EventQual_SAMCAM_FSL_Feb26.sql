CREATE PROCEDURE [dbo].[usp_EventQual_SAMCAM_FSL_Feb26]
	@Parameters NVARCHAR(MAX) = NULL
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_SAMCAM_FSL_Feb26

	USE:	
	
			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			
			SET @param =  N'{
				"step":11,
				"currentDatetime": null,
				"pkEventLog":204725,
				"execLog":1,
				"cleanUpTempData":0,
				"eligibleCountries":"NI,CI,DR,VE,CO,HN,GT,SV,CR,BL,PE,AR,UY,PM,EC",	
				"pK_Event_L1":204725,
				"ctry_L1":"NI",		
				"pK_Event_L2":204680,
				"ctry_L2":"CI",	
				"pK_Event_L3":204685,
				"ctry_L3":"DR",	
				"pK_Event_L4":204686,
				"ctry_L4":"VE",	
				"pK_Event_L5":204681,
				"ctry_L5":"CO",	
				"pK_Event_L6":204723,
				"ctry_L6":"HN",	
				"pK_Event_L7":204684,
				"ctry_L7":"GT,SV,CR",	
				"pK_Event_L8":204682,
				"ctry_L8":"BL",	
				"pK_Event_L9":204677,
				"ctry_L9":"PE",	
				"pK_Event_L10":204678,
				"ctry_L10":"AR,UY",	
				"pK_Event_L11":204675,
				"ctry_L11":"PM",	
				"pK_Event_L12":204683,
				"ctry_L12":"EC", 
				"newFqsQualDateStart":"2025-11-01",
				"newFqsQualDateEnd":"2026-02-01",
				"newFqsQualDateStartB":"2025-07-01",
				"newFqsQualDateEndB":"2025-10-01",
				"qSActualQualDateStart":"2026-02-01",
				"qSActualQualDateEnd":"2026-02-28",
				"newWTQualDateStart":"2025-11-01",
				"newWTQualDateEnd":"2026-02-01",
				"aWTQualDateStart":"2025-10-01",
				"aWTQualDateEnd":"2025-12-01",
				"aWTYear":2025,
				"isNonTAB":1,
				"newQPQualDateStart":"2025-11-01",
				"newQPQualDateEnd":"2026-02-01",
				"newSBQualDateStart":"2025-11-01",
				"newSBQualDateEnd":"2026-02-01",
				"newWTQualDateStart":"2025-11-01",
				"newWTQualDateEnd":"2026-02-01",
				"newGTQualDateStart":"2025-11-01",
				"newGTQualDateEnd":"2026-02-01",
				"newMTQualDateStart":"2025-11-01",
				"newMTQualDateEnd":"2026-02-01",
				"newPTQualDateStart":"2025-11-01",
				"newPTQualDateEnd":"2026-02-01",
				"newGPQualDateStart":"2025-11-01",
				"newGPQualDateEnd":"2026-02-01",
				"newMPQualDateStart":"2025-11-01",
				"newMPQualDateEnd":"2026-02-01",

				"bonusMetric":"TV",
				"isNewFQSBonusActive":1,
				"newFQSBonusDateStart":"2025-11-01",
				"newFQSBonusDateEnd":"2026-02-01",
				"newFQSBonusAppliesToL1":"16,17,18,19",
				"newFQSBonusAppliesToL2":"15,16,17,18,19,20",
				"newFQSBonusAppliesToL3":"15,16,17,18",
				"newFQSBonusAppliesToL4":"14,15,16,17",
				"newFQSBonusAppliesToL5":"15,16,17,18,19,20",
				"newFQSBonusAppliesToL6":"20,21,22,23,24,25,26,27",
				"newFQSBonusAppliesToL7":"15,16,17,18,19,20",
				"newFQSBonusAppliesToL8":"17,18,19,20",
				"newFQSBonusAppliesToL9":"15,16,17,18,19,20",
				"newFQSBonusAppliesToL10":"12,13,14,15,16,17",
				"newFQSBonusAppliesToL11":"15,16,17,18,19,20",
				"newFQSBonusAppliesToL12":"15,16,17,18,19,20",
				"isDoubleVolumeBonusActive":1, 
				"doubleVolumeMonth1":"2025-10-01",
				"doubleVolumeMonth1UpTo":5000,
				"doubleVolumeMonth2":"2025-12-01",
				"doubleVolumeMonth2UpTo":6000,			
				"doubleVolumeBonusAppliesToL1":"14,15,16,17,18,19",
				"doubleVolumeBonusAppliesToL2":"13,14,15,16,17,18,19,20",
				"doubleVolumeBonusAppliesToL3":"15,16,17,18",
				"doubleVolumeBonusAppliesToL4":"14,15,16,17",
				"doubleVolumeBonusAppliesToL5":"13,14,15,16,17,18,19,20",
				"doubleVolumeBonusAppliesToL6":"20,21,22,23,24,25,26,27",
				"doubleVolumeBonusAppliesToL7":"13,14,15,16,17,18,19,20",
				"doubleVolumeBonusAppliesToL8":"17,18,19,20",
				"doubleVolumeBonusAppliesToL9":"13,14,15,16,17,18,19,20",
				"doubleVolumeBonusAppliesToL10":"12,13,14,15,16,17",
				"doubleVolumeBonusAppliesToL11":"13,14,15,16,17,18,19,20",
				"doubleVolumeBonusAppliesToL12":"13,14,15,16,17,18,19,20"
			}'

			UPDATE [Shared].[QualsExecParams]
			SET Parameters = @param
			WHERE ProjectID = 26034

			EXEC dbo.usp_EventQual_SAMCAM_FSL_Feb26 @Parameters= @param, @IsDevQA = 0, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
			SELECT @e AS [Error], @em AS [ErrorMessage]

			GO

	DESCRIPTION: 

	NOTES:	

	DEBUG TABLES:	
		
	DEPENDENCIES:
	
	WORK TABLES (WRK):

	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2025-11-25			alejandramed			Initial 
	1.0.1	2025-12-03			alejandramed			User Story 1427297: 26034 - SAMCAM LDW (Elevate) Feb 2026 - BRD V2
	1.0.2	2025-12-15			alejandramed			User Story 1436423: 26034 - SAMCAM LDW (Elevate) Feb 2026 - BRD V3
	1.0.3	2025-12-18			alejandramed			User Story 1436780: 26034 - SAMCAM LDW (Elevate) Feb 2026 - BRD V4
***********************************************************************************************************************************/

	
	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_amed') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetDSVolume_amed] is missing, create it manually' AS [ErrorMessage]
	END

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_amed') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetQualifier_Points_amed] is missing, create it manually' AS [ErrorMessage]
	END

	SET NOCOUNT ON;

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY
		
	-- Variables for json values
	DECLARE  
		@Step INT, 	
		@CurrentDatetime DATETIME,		
		@PK_Event_Log INT,
		@ExecLog BIT,
		@CleanUpTempData BIT,
		@EligibleCountries VARCHAR(MAX),

		@PK_Event_L1 INT, 
		@Ctry_L1 VARCHAR(25),
		@PK_Event_L2 INT, 
		@Ctry_L2 VARCHAR(25),
		@PK_Event_L3 INT, 
		@Ctry_L3 VARCHAR(25),
		@PK_Event_L4 INT, 
		@Ctry_L4 VARCHAR(25),
		@PK_Event_L5 INT, 
		@Ctry_L5 VARCHAR(25),	
		@PK_Event_L6 INT, 
		@Ctry_L6 VARCHAR(25),
		@PK_Event_L7 INT, 
		@Ctry_L7 VARCHAR(25),
		@PK_Event_L8 INT,  
		@Ctry_L8 VARCHAR(25),
		@PK_Event_L9 INT, 
		@Ctry_L9 VARCHAR(25),
		@PK_Event_L10 INT, 
		@Ctry_L10 VARCHAR(25),
		@PK_Event_L11 INT, 
		@Ctry_L11 VARCHAR(25), 
		@PK_Event_L12 INT, 
		@Ctry_L12 VARCHAR(25), 
		@NewFQSQualDateStart DATE,
		@NewFQSQualDateEnd DATE, 
		@NewFQSQualDateStartB DATE,
		@NewFQSQualDateEndB DATE, 
		@QSActualQualDateStart DATE,
		@QSActualQualDateEnd DATE,		
		@AWTYear INT,
		@IsNonTAB BIT,
		@AWTQualDateStart DATE,
		@AWTQualDateEnd DATE,
		@NewQPQualDateStart DATE,
		@NewQPQualDateEnd DATE,
		@NewSBQualDateStart DATE,
		@NewSBQualDateEnd DATE,
		@NewWTQualDateStart DATE,
		@NewWTQualDateEnd DATE,
		@NewGTQualDateStart DATE,
		@NewGTQualDateEnd DATE,
		@NewGPQualDateStart DATE,
		@NewGPQualDateEnd DATE,
		@NewMTQualDateStart DATE,
		@NewMTQualDateEnd DATE,
		@NewMPQualDateStart DATE,
		@NewMPQualDateEnd DATE,
		@NewPTQualDateStart DATE,
		@NewPTQualDateEnd DATE,
		--Bonuses
		@BonusMetric VARCHAR(10),
		@IsNewFQSBonusActive BIT,
		@NewFQSBonusDateStart DATE,
		@NewFQSBonusDateEnd DATE,		
		@NewFQSBonusAppliesToL1 VARCHAR(MAX),
		@NewFQSBonusAppliesToL2 VARCHAR(MAX), 
		@NewFQSBonusAppliesToL3 VARCHAR(MAX), 
		@NewFQSBonusAppliesToL4 VARCHAR(MAX), 
		@NewFQSBonusAppliesToL5 VARCHAR(MAX), 
		@NewFQSBonusAppliesToL6 VARCHAR(MAX), 
		@NewFQSBonusAppliesToL7 VARCHAR(MAX), 
		@NewFQSBonusAppliesToL8 VARCHAR(MAX), 
		@NewFQSBonusAppliesToL9 VARCHAR(MAX), 
		@NewFQSBonusAppliesToL10 VARCHAR(MAX),
		@NewFQSBonusAppliesToL11 VARCHAR(MAX),
		@NewFQSBonusAppliesToL12 VARCHAR(MAX),
		@IsDoubleVolumeBonusActive BIT,
		@DoubleVolumeMonth1 DATE,
		@DoubleVolumeMonth1UpTo MONEY,
		@DoubleVolumeMonth2 DATE,
		@DoubleVolumeMonth2UpTo MONEY, 
		@DoubleVolumeBonusAppliesToL1 VARCHAR(MAX),
		@DoubleVolumeBonusAppliesToL2 VARCHAR(MAX), 
		@DoubleVolumeBonusAppliesToL3 VARCHAR(MAX), 
		@DoubleVolumeBonusAppliesToL4 VARCHAR(MAX), 
		@DoubleVolumeBonusAppliesToL5 VARCHAR(MAX), 
		@DoubleVolumeBonusAppliesToL6 VARCHAR(MAX), 
		@DoubleVolumeBonusAppliesToL7 VARCHAR(MAX), 
		@DoubleVolumeBonusAppliesToL8 VARCHAR(MAX), 
		@DoubleVolumeBonusAppliesToL9 VARCHAR(MAX), 
		@DoubleVolumeBonusAppliesToL10 VARCHAR(MAX),
		@DoubleVolumeBonusAppliesToL11 VARCHAR(MAX),
		@DoubleVolumeBonusAppliesToL12 VARCHAR(MAX)
 
	-- Getting parameters values for json
	SELECT   
		
		@Step 						= g.step,	
		@CurrentDatetime			= g.currentDatetime,
		@PK_Event_Log				= g.pkEventLog,
		@ExecLog					= g.execLog,
		@CleanUpTempData			= g.cleanUpTempData,
		@EligibleCountries 			= g.eligibleCountries, 
		--Custom fields
		@PK_Event_L1 				= g.pK_Event_L1,
		@Ctry_L1					= g.ctry_L1,
		@PK_Event_L2 				= g.pK_Event_L2,
		@Ctry_L2					= g.ctry_L2,
		@PK_Event_L3 				= g.pK_Event_L3,
		@Ctry_L3					= g.ctry_L3,
		@PK_Event_L4 				= g.pK_Event_L4,
		@Ctry_L4					= g.ctry_L4,
		@PK_Event_L5 				= g.pK_Event_L5,
		@Ctry_L5					= g.ctry_L5,
		@PK_Event_L6 				= g.pK_Event_L6,
		@Ctry_L6					= g.ctry_L6,
		@PK_Event_L7 				= g.pK_Event_L7,
		@Ctry_L7					= g.ctry_L7,
		@PK_Event_L8 				= g.pK_Event_L8,
		@Ctry_L8					= g.ctry_L8,
		@PK_Event_L9 				= g.pK_Event_L9,
		@Ctry_L9					= g.ctry_L9,
		@PK_Event_L10 				= g.pK_Event_L10,
		@Ctry_L10					= g.ctry_L10,
		@PK_Event_L11 				= g.pK_Event_L11,
		@Ctry_L11					= g.ctry_L11,
		@PK_Event_L12 				= g.pK_Event_L12,
		@Ctry_L12					= g.ctry_L12, 		
		@NewFQSQualDateStart 		= g.newFQSQualDateStart, 	
		@NewFQSQualDateEnd 			= g.newFQSQualDateEnd,	
		@NewFQSQualDateStartB 		= g.newFQSQualDateStartB, 	
		@NewFQSQualDateEndB 		= g.newFQSQualDateEndB,	
		@QSActualQualDateStart 		= g.qSActualQualDateStart, 	
		@QSActualQualDateEnd 		= g.qSActualQualDateEnd,			
		@AWTQualDateStart			= g.aWTQualDateStart, 
		@AWTQualDateEnd 			= g.aWTQualDateEnd, 	
		@AWTYear					= g.aWTYear,
		@IsNonTAB					= g.isNonTAB,
		@NewQPQualDateStart 		= g.newQPQualDateStart, 	
		@NewQPQualDateEnd 			= g.newQPQualDateEnd, 
		@NewSBQualDateStart 		= g.newSBQualDateStart, 	
		@NewSBQualDateEnd 			= g.newSBQualDateEnd, 
		@NewWTQualDateStart 		= g.newWTQualDateStart, 	
		@NewWTQualDateEnd 			= g.newWTQualDateEnd, 
		@NewGTQualDateStart 		= g.newGTQualDateStart, 	
		@NewGTQualDateEnd 			= g.newGTQualDateEnd,
		@NewGPQualDateStart 		= g.newGPQualDateStart, 	
		@NewGPQualDateEnd 			= g.newGPQualDateEnd,
		@NewMTQualDateStart 		= g.newMTQualDateStart, 	
		@NewMTQualDateEnd 			= g.newMTQualDateEnd, 
		@NewMPQualDateStart 		= g.newMPQualDateStart, 	
		@NewMPQualDateEnd 			= g.newMPQualDateEnd, 
		@NewPTQualDateStart 		= g.newPTQualDateStart, 	
		@NewPTQualDateEnd 			= g.newPTQualDateEnd,		
		--Bonuses	
		@BonusMetric				= g.bonusMetric,
		@IsNewFQSBonusActive 		= g.isNewFQSBonusActive, 	
		@NewFQSBonusDateStart 		= g.newFQSBonusDateStart,
		@NewFQSBonusDateEnd 		= g.newFQSBonusDateEnd, 
		@NewFQSBonusAppliesToL1 	= g.newFQSBonusAppliesToL1, 	
		@NewFQSBonusAppliesToL2 	= g.newFQSBonusAppliesToL2, 	
		@NewFQSBonusAppliesToL3 	= g.newFQSBonusAppliesToL3, 	
		@NewFQSBonusAppliesToL4 	= g.newFQSBonusAppliesToL4, 	
		@NewFQSBonusAppliesToL5 	= g.newFQSBonusAppliesToL5, 	
		@NewFQSBonusAppliesToL6 	= g.newFQSBonusAppliesToL6, 	
		@NewFQSBonusAppliesToL7 	= g.newFQSBonusAppliesToL7, 	
		@NewFQSBonusAppliesToL8 	= g.newFQSBonusAppliesToL8, 	
		@NewFQSBonusAppliesToL9 	= g.newFQSBonusAppliesToL9, 	
		@NewFQSBonusAppliesToL10 	= g.newFQSBonusAppliesToL10,	
		@NewFQSBonusAppliesToL11 	= g.newFQSBonusAppliesToL11,	
		@NewFQSBonusAppliesToL12 	= g.newFQSBonusAppliesToL12,	
		@IsDoubleVolumeBonusActive	= g.isDoubleVolumeBonusActive,
		@DoubleVolumeMonth1			= g.doubleVolumeMonth1,
		@DoubleVolumeMonth1UpTo		= g.doubleVolumeMonth1UpTo,
		@DoubleVolumeMonth2			= g.doubleVolumeMonth2, 
		@DoubleVolumeMonth2UpTo		= g.doubleVolumeMonth2UpTo,		
		@DoubleVolumeBonusAppliesToL1 	= g.doubleVolumeBonusAppliesToL1, 	
		@DoubleVolumeBonusAppliesToL2 	= g.doubleVolumeBonusAppliesToL2, 	
		@DoubleVolumeBonusAppliesToL3 	= g.doubleVolumeBonusAppliesToL3, 	
		@DoubleVolumeBonusAppliesToL4 	= g.doubleVolumeBonusAppliesToL4, 	
		@DoubleVolumeBonusAppliesToL5 	= g.doubleVolumeBonusAppliesToL5, 	
		@DoubleVolumeBonusAppliesToL6 	= g.doubleVolumeBonusAppliesToL6, 	
		@DoubleVolumeBonusAppliesToL7 	= g.doubleVolumeBonusAppliesToL7, 	
		@DoubleVolumeBonusAppliesToL8 	= g.doubleVolumeBonusAppliesToL8, 	
		@DoubleVolumeBonusAppliesToL9 	= g.doubleVolumeBonusAppliesToL9, 	
		@DoubleVolumeBonusAppliesToL10 	= g.doubleVolumeBonusAppliesToL10,	
		@DoubleVolumeBonusAppliesToL11 	= g.doubleVolumeBonusAppliesToL11,	
		@DoubleVolumeBonusAppliesToL12 	= g.doubleVolumeBonusAppliesToL12	 
	FROM OPENJSON(@Parameters)
	WITH ( 
			
			step INT '$.step',
			currentDatetime DATETIME '$.currentDatetime',
			pkEventLog INT '$.pkEventLog',
			execLog BIT '$.execLog',
			cleanUpTempData BIT '$.cleanUpTempData',
			eligibleCountries VARCHAR(MAX) '$.eligibleCountries',
			pK_Event_L1 INT '$.pK_Event_L1',
			ctry_L1 VARCHAR(25) '$.ctry_L1',
			pK_Event_L2 INT '$.pK_Event_L2',
			ctry_L2 VARCHAR(25) '$.ctry_L2',
			pK_Event_L3 INT '$.pK_Event_L3',
			ctry_L3 VARCHAR(25) '$.ctry_L3',
			pK_Event_L4 INT '$.pK_Event_L4',
			ctry_L4 VARCHAR(25) '$.ctry_L4',
			pK_Event_L5 INT '$.pK_Event_L5',
			ctry_L5 VARCHAR(25) '$.ctry_L5',
			pK_Event_L6 INT '$.pK_Event_L6',
			ctry_L6 VARCHAR(25) '$.ctry_L6',
			pK_Event_L7 INT '$.pK_Event_L7',
			ctry_L7 VARCHAR(25) '$.ctry_L7',
			pK_Event_L8 INT '$.pK_Event_L8',
			ctry_L8 VARCHAR(25) '$.ctry_L8',
			pK_Event_L9 INT '$.pK_Event_L9',
			ctry_L9 VARCHAR(25) '$.ctry_L9',
			pK_Event_L10 INT '$.pK_Event_L10',
			ctry_L10 VARCHAR(25) '$.ctry_L10',
			pK_Event_L11 INT '$.pK_Event_L11',
			ctry_L11 VARCHAR(25) '$.ctry_L11',
			pK_Event_L12 INT '$.pK_Event_L12',
			ctry_L12 VARCHAR(25) '$.ctry_L12',  
			newFqsQualDateStart DATE '$.newFqsQualDateStart',
			newFqsQualDateEnd DATE '$.newFqsQualDateEnd',
			newFqsQualDateStartB DATE '$.newFqsQualDateStartB',
			newFqsQualDateEndB DATE '$.newFqsQualDateEndB',
			qSActualQualDateStart DATE '$.qSActualQualDateStart',
			qSActualQualDateEnd DATE '$.qSActualQualDateEnd',			
			aWTQualDateStart DATE '$.aWTQualDateStart',
			aWTQualDateEnd DATE '$.aWTQualDateEnd',
			aWTYear	INT '$.aWTYear',
			isNonTAB BIT '$.isNonTAB',
			newQPQualDateStart DATE '$.newQPQualDateStart',
			newQPQualDateEnd DATE '$.newQPQualDateEnd',
			newSBQualDateStart DATE '$.newSBQualDateStart',
			newSBQualDateEnd DATE '$.newSBQualDateEnd',
			newWTQualDateStart DATE '$.newWTQualDateStart',
			newWTQualDateEnd DATE '$.newWTQualDateEnd',
			newGTQualDateStart DATE '$.newGTQualDateStart',
			newGTQualDateEnd DATE '$.newGTQualDateEnd',
			newGPQualDateStart DATE '$.newGPQualDateStart',
			newGPQualDateEnd DATE '$.newGPQualDateEnd',
			newMTQualDateStart DATE '$.newMTQualDateStart',
			newMTQualDateEnd DATE '$.newMTQualDateEnd',
			newMPQualDateStart DATE '$.newMPQualDateStart',
			newMPQualDateEnd DATE '$.newMPQualDateEnd',
			newPTQualDateStart DATE '$.newPTQualDateStart',
			newPTQualDateEnd DATE '$.newPTQualDateEnd',			
			--Bonuses
			bonusMetric	VARCHAR(10) '$.bonusMetric',
			isNewFQSBonusActive BIT '$.isNewFQSBonusActive',
			newFQSBonusDateStart DATE '$.newFQSBonusDateStart',
			newFQSBonusDateEnd DATE '$.newFQSBonusDateEnd',
			newFQSBonusAppliesToL1 VARCHAR(MAX) '$.newFQSBonusAppliesToL1',
			newFQSBonusAppliesToL2 VARCHAR(MAX) '$.newFQSBonusAppliesToL2',
			newFQSBonusAppliesToL3 VARCHAR(MAX) '$.newFQSBonusAppliesToL3',
			newFQSBonusAppliesToL4 VARCHAR(MAX) '$.newFQSBonusAppliesToL4',
			newFQSBonusAppliesToL5 VARCHAR(MAX) '$.newFQSBonusAppliesToL5',
			newFQSBonusAppliesToL6 VARCHAR(MAX) '$.newFQSBonusAppliesToL6',
			newFQSBonusAppliesToL7 VARCHAR(MAX) '$.newFQSBonusAppliesToL7',
			newFQSBonusAppliesToL8 VARCHAR(MAX) '$.newFQSBonusAppliesToL8',
			newFQSBonusAppliesToL9 VARCHAR(MAX) '$.newFQSBonusAppliesToL9',
			newFQSBonusAppliesToL10 VARCHAR(MAX) '$.newFQSBonusAppliesToL10',
			newFQSBonusAppliesToL11 VARCHAR(MAX) '$.newFQSBonusAppliesToL11',
			newFQSBonusAppliesToL12 VARCHAR(MAX) '$.newFQSBonusAppliesToL12',
			isDoubleVolumeBonusActive BIT '$.isDoubleVolumeBonusActive',
			doubleVolumeMonth1 DATE '$.doubleVolumeMonth1',
			doubleVolumeMonth1UpTo MONEY '$.doubleVolumeMonth1UpTo',
			doubleVolumeMonth2 DATE '$.doubleVolumeMonth2',
			doubleVolumeMonth2UpTo MONEY '$.doubleVolumeMonth2UpTo',			
			doubleVolumeBonusAppliesToL1 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL1',
			doubleVolumeBonusAppliesToL2 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL2',
			doubleVolumeBonusAppliesToL3 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL3',
			doubleVolumeBonusAppliesToL4 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL4',
			doubleVolumeBonusAppliesToL5 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL5',
			doubleVolumeBonusAppliesToL6 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL6',
			doubleVolumeBonusAppliesToL7 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL7',
			doubleVolumeBonusAppliesToL8 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL8',
			doubleVolumeBonusAppliesToL9 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL9',
			doubleVolumeBonusAppliesToL10 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL10',
			doubleVolumeBonusAppliesToL11 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL11',
			doubleVolumeBonusAppliesToL12 VARCHAR(MAX) '$.doubleVolumeBonusAppliesToL12'
		) AS g
	 
	-- Default values 
	 
	SET @Step = IIF(@Step IS NULL,11, @Step) 
	SET @CurrentDatetime = IIF(@CurrentDatetime IS NULL,GETDATE(), @CurrentDatetime)

	SELECT			
		@Step						AS [Step],			
		@CurrentDatetime			AS [CurrentDatetime],
		@PK_Event_Log				AS [PK_Event_Log],
		@ExecLog					AS [ExecLog],
		@CleanUpTempData			AS [CleanUpTempData],
		@EligibleCountries			AS [EligibleCountries],	 
		@PK_Event_L1				AS [PK_Event_L1],
		@Ctry_L1					AS [@Ctry_L1],
		@PK_Event_L2				AS [PK_Event_L2],
		@Ctry_L2					AS [@Ctry_L2],
		@PK_Event_L3				AS [PK_Event_L3],
		@Ctry_L3					AS [@Ctry_L3],
		@PK_Event_L4				AS [PK_Event_L4],
		@Ctry_L4					AS [@Ctry_L4],
		@PK_Event_L5				AS [PK_Event_L5],
		@Ctry_L5					AS [@Ctry_L5],
		@PK_Event_L6				AS [PK_Event_L6],
		@Ctry_L6					AS [@Ctry_L6],
		@PK_Event_L7				AS [PK_Event_L7],
		@Ctry_L7					AS [@Ctry_L7],
		@PK_Event_L8				AS [PK_Event_L8],
		@Ctry_L8					AS [@Ctry_L8],
		@PK_Event_L9				AS [PK_Event_L9],
		@Ctry_L9					AS [@Ctry_L9],
		@PK_Event_L10				AS [PK_Event_L10],
		@Ctry_L10					AS [@Ctry_L10],
		@PK_Event_L11				AS [PK_Event_L11],
		@Ctry_L11					AS [@Ctry_L11],
		@PK_Event_L12				AS [PK_Event_L12],
		@Ctry_L12					AS [@Ctry_L12], 
 	
		@NewFQSqualDateStart		AS [NewFQSQualDateStart],	
		@NewFQSqualDateEnd			AS [NewFQSQualDateEnd],	
		@NewFQSqualDateStartB		AS [NewFQSQualDateStartB],	
		@NewFQSqualDateEndB			AS [NewFQSQualDateEndB],	
		@QSActualQualDateStart		AS [QSActualQualDateStart],	
		@QSActualQualDateEnd		AS [QSActualQualDateEnd],		
		@AWTQualDateStart			AS [AWTQualDateStart], 
		@AWTQualDateEnd				AS [AWTQualDateEnd],
		@AWTYear					AS [AWTYear],
		@IsNonTAB					AS [IsNonTAB],
		@NewQPQualDateStart			AS [NewQPQualDateStart],		
		@NewQPQualDateEnd			AS [NewQPQualDateEnd],	
		@NewSBQualDateStart			AS [NewSBQualDateStart],		
		@NewSBQualDateEnd			AS [NewSBQualDateEnd],	
		@NewWTQualDateStart			AS [NewWTQualDateStart],		
		@NewWTQualDateEnd			AS [NewWTQualDateEnd],	
		@NewGTQualDateStart			AS [NewGTQualDateStart],		
		@NewGTQualDateEnd			AS [NewGTQualDateEnd],
		@NewGPQualDateStart			AS [NewGPQualDateStart],		
		@NewGPQualDateEnd			AS [NewGPQualDateEnd],
		@NewMTQualDateStart			AS [NewMTQualDateStart],		
		@NewMTQualDateEnd			AS [NewMTQualDateEnd],
		@NewMPQualDateStart			AS [NewMPQualDateStart],		
		@NewMPQualDateEnd			AS [NewMPQualDateEnd],
		@NewPTQualDateStart			AS [NewPTQualDateStart],		
		@NewPTQualDateEnd			AS [NewPTQualDateEnd],

		--Bonuses
		@BonusMetric				AS [BonusMetric],
		@IsNewFQSBonusActive		AS [IsNewFQSBonusActive],	
		@NewFQSBonusDateStart		AS [NewFQSBonusDateStart],	
		@NewFQSBonusDateEnd			AS [NewFQSBonusDateEnd],		
		@NewFQSBonusAppliesToL1		AS [NewFQSBonusAppliesToL1],
		@NewFQSBonusAppliesToL2		AS [NewFQSBonusAppliesToL2],
		@NewFQSBonusAppliesToL3		AS [NewFQSBonusAppliesToL3],
		@NewFQSBonusAppliesToL4		AS [NewFQSBonusAppliesToL4],
		@NewFQSBonusAppliesToL5		AS [NewFQSBonusAppliesToL5],
		@NewFQSBonusAppliesToL6		AS [NewFQSBonusAppliesToL6],
		@NewFQSBonusAppliesToL7		AS [NewFQSBonusAppliesToL7],
		@NewFQSBonusAppliesToL8		AS [NewFQSBonusAppliesToL8],
		@NewFQSBonusAppliesToL9		AS [NewFQSBonusAppliesToL9],
		@NewFQSBonusAppliesToL10	AS [NewFQSBonusAppliesToL10],
		@NewFQSBonusAppliesToL11	AS [NewFQSBonusAppliesToL11],
		@NewFQSBonusAppliesToL12	AS [NewFQSBonusAppliesToL12],		
		
		@IsDoubleVolumeBonusActive	AS [IsDoubleVolumeBonusActive],
		@DoubleVolumeMonth1			AS [DoubleVolumeMonth1],
		@DoubleVolumeMonth1UpTo		AS [DoubleVolumeMonth1UpTo],
		@DoubleVolumeMonth2			AS [DoubleVolumeMonth2],
		@DoubleVolumeMonth2UpTo		AS [DoubleVolumeMonth2UpTo], 
		
		@DoubleVolumeBonusAppliesToL1	AS [DoubleVolumeBonusAppliesToL1],
		@DoubleVolumeBonusAppliesToL2	AS [DoubleVolumeBonusAppliesToL2],
		@DoubleVolumeBonusAppliesToL3	AS [DoubleVolumeBonusAppliesToL3],
		@DoubleVolumeBonusAppliesToL4	AS [DoubleVolumeBonusAppliesToL4],
		@DoubleVolumeBonusAppliesToL5	AS [DoubleVolumeBonusAppliesToL5],
		@DoubleVolumeBonusAppliesToL6	AS [DoubleVolumeBonusAppliesToL6],
		@DoubleVolumeBonusAppliesToL7	AS [DoubleVolumeBonusAppliesToL7],
		@DoubleVolumeBonusAppliesToL8	AS [DoubleVolumeBonusAppliesToL8],
		@DoubleVolumeBonusAppliesToL9	AS [DoubleVolumeBonusAppliesToL9],
		@DoubleVolumeBonusAppliesToL10	AS [DoubleVolumeBonusAppliesToL10],
		@DoubleVolumeBonusAppliesToL11	AS [DoubleVolumeBonusAppliesToL11],
		@DoubleVolumeBonusAppliesToL12	AS [DoubleVolumeBonusAppliesToL12]

	------------------------------------------------------------------------------------------------
	-- Tables and variables
	------------------------------------------------------------------------------------------------
	BEGIN

		--Variables for logging
		DECLARE  
		 @PK_TimeLog1 datetime2
		,@StepGroup int					-- StepGroup
		,@StepSubGroup int				-- StepSubGroup
		,@Milestone varchar(255)		-- Milestone
		,@RowCount bigint = NULL

		DECLARE 
			@iStartDate int,
			@dStartDate datetime,
			@iEndDate int,
			@dEndDate datetime,
			@DSCountries VARCHAR(MAX),
			@MetricType VARCHAR(MAX) 

		DECLARE @ColumnToPivot NVARCHAR(MAX),
				@SqlStatement NVARCHAR(MAX)

		DROP TABLE IF EXISTS #LocationMapping

		CREATE TABLE #LocationMapping
		(			
			[PK_Event] [int], 
			[CountryCode]	varchar(20), 
			[CountryName] nvarchar(max),
			[PK_Country] [int],
			[ctrl] [bit] DEFAULT(0)
		)

		;WITH 
			cte_L1 AS ( SELECT @PK_Event_L1 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L1,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L2 AS ( SELECT @PK_Event_L2 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L2,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L3 AS ( SELECT @PK_Event_L3 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L3,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L4 AS ( SELECT @PK_Event_L4 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L4,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L5 AS ( SELECT @PK_Event_L5 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L5,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L6 AS ( SELECT @PK_Event_L6 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L6,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L7 AS ( SELECT @PK_Event_L7 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L7,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L8 AS ( SELECT @PK_Event_L8 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L8,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L9 AS ( SELECT @PK_Event_L9 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L9,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L10 AS ( SELECT @PK_Event_L10 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName],c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L10,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L11 AS ( SELECT @PK_Event_L11 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName],c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L11,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode),
			cte_L12 AS ( SELECT @PK_Event_L12 AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName],c.sCountryCode AS [CountryCode] FROM string_split(@Ctry_L12,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode)
		
		INSERT INTO #LocationMapping([PK_Event],[CountryCode],[CountryName],[PK_Country])
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L1 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L2 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L3 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L4 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L5 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L6 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L7 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L8 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L9 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L10 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L11 UNION	 
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L12  

		DROP TABLE IF EXISTS #LocationEventID

		SELECT DISTINCT [PK_Event] INTO #LocationEventID FROM #LocationMapping

		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			ListID INT,
			QId INT
		)

		INSERT INTO #ListsQsMapping(PK_Event,ListID,QId)
		SELECT eq.PK_Event, eq.QualificationValue,eq.QualificationNumber 
		FROM [Shared].[ExtensionQualification] AS eq WITH (NOLOCK) 
			INNER JOIN #LocationEventID AS l
				ON eq.PK_Event = l.PK_Event
		AND QualificationType = 'List'
	
		DROP TABLE IF EXISTS #SKUsQsMapping 

		CREATE TABLE #SKUsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			SKUCode VARCHAR(10),
			QId INT
		) 
		
		INSERT INTO #SKUsQsMapping(PK_Event,SKUCode,QId)
		SELECT eq.PK_Event, eq.QualificationValue,eq.QualificationNumber 
		FROM [Shared].[ExtensionQualification] AS eq WITH (NOLOCK) 
			INNER JOIN #LocationEventID AS l
				ON eq.PK_Event = l.PK_Event
		AND QualificationType = 'SKU'

		DROP TABLE IF EXISTS #TimeLog;  

		CREATE TABLE #TimeLog(
			[Milestone]		varchar(255)
			,[StepGroup]	tinyint
			,[StepSubGroup] tinyint
			,[StepStart]	datetime2
			,[Duration]		int
		);
  
		DROP TABLE IF EXISTS #Event_SetupEventQualification

		CREATE TABLE #Event_SetupEventQualification
		(
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
			[PeriodType]			tinyint, -- 1 Fixed period, 2 Relative period base on SPQualDate
			[MetricTypeDefinition]	VARCHAR(50) NULL
		)
 
		IF @IsDevQA = 0
		BEGIN	
		 
			INSERT INTO #Event_SetupEventQualification(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition,QSVolume)
			SELECT seq.PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition,QSVolume
			FROM [Event].[SetupEventQualification] AS seq WITH (NOLOCK)
				INNER JOIN #LocationEventID AS lm
					ON seq.PK_Event = lm.PK_Event

		END
		 				
		DROP TABLE IF EXISTS #tmp_DS

		CREATE TABLE #tmp_DS(
			[PK_Event] [int] NOT NULL,
			[PK_Distributor] [int] NULL,
			[DistributorID] VARCHAR(30),
			[iStartDate] [int] NULL,
			[iEndDate] [int] NULL,
			[dStartDate] [datetime] NULL,
			[dEndDate] [datetime] NULL,
			[dSPQualDate] [datetime] NULL,
			[PK_DSType] [int] NULL
		)

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
 
		--Quals block
	BEGIN 
		
		DECLARE @PK_EventMultiLocation VARCHAR(MAX) = (SELECT STRING_AGG(PK_Event,',') FROM #LocationEventID)

		IF @CleanUpTempData = 1 EXEC [Shared].[usp_CleanUp_TempData] @IsDevQA = 0 
	 
		IF (@IsDevQA = 2)
		BEGIN
			PRINT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1 
		END

		--Step 1: DS
		IF @Step >= 1 
		BEGIN

			PRINT 'Executing step 1'

			SELECT @StepGroup = 1, @StepSubGroup = 1, @Milestone = 'Getting Distributors from eligible countries';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

				DROP TABLE IF EXISTS #Countries

				CREATE TABLE #Countries
				(
					nCountryID		int,   
					sCountryCode	varchar(10), 
					sCountryCodeISO varchar(10), 
					sCountryName	varchar(150)
				)

				INSERT INTO #Countries(nCountryID,sCountryCode,sCountryCodeISO,sCountryName) 
					SELECT nCountryID,sCountryCode,sCountryCodeISO,sCountryName
					FROM dbo.v_Countries
					WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@EligibleCountries, ','))

				DROP TABLE IF EXISTS #DS

				CREATE TABLE #DS
				(
					PK_Event				int,
					PK_Distributor			int,   
					DSCurrentTeam			varchar(10),        
					DSSubTeam				varchar(10),        
					DSSPTeam				varchar(10),               
					dSPQualDate				datetime2,
					dSPRequalDate			datetime2,
					dSPDemotion				datetime2 default '1900-01-01',
					QSQualDate				smalldatetime,		
					QSActualQualDate		smalldatetime,	
					CountryCode				varchar(5),
					IsFromList				bit default(0),
					IsTicketPurchaser		bit default(0)

					--
					,NewSPQualDate		date 
					,NewWTQualDate		date default '1900-01-01'
					,IsAWTQualifier		BIT DEFAULT 0
					,NewGTQualDate		date default '1900-01-01'
					,NewGPQualDate		date default '1900-01-01'
					,NewMTQualDate		date default '1900-01-01'
					,NewMPQualDate		date default '1900-01-01'
					,NewPTQualDate		date default '1900-01-01'
					,NewQPQualDate		date default '1900-01-01'
					,NewSBQualDate		date default '1900-01-01'
				)

				INSERT INTO #DS
				(
					PK_Event,
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,
					dSPRequalDate,
					dSPDemotion,
					QSQualDate,
					QSActualQualDate,
					CountryCode
				)
				SELECT DISTINCT    
				l.PK_Event,
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate,    
				d.dSupervisorReQualification AS dSPRequalDate,
				D.dSPDemotion AS dSPDemotion, 
				D.dQSQualification AS dQSQualification,				
				D.dQSQualification_Actual AS dQSQualification_Actual,
				D.sDistributorCountryProcessingCode AS CountryCode
				FROM        
				dbo.v_Distributor AS D  
					INNER JOIN #LocationMapping AS l
						ON D.nDistributorCountryProcessingID = l.PK_Country				
				WHERE        
					D.StatusCode = 'COMPLETE' 
	 
				CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);

			SELECT @StepGroup = 1, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


		END
		
		--Step 2: List and SKUs 
		IF @Step >= 2 
		BEGIN

			PRINT 'Executing step 2'

			SELECT @StepGroup = 2, @StepSubGroup = 1, @Milestone = 'Getting Distributors from list';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

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
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,		
					dSPRequalDate,
					dSPDemotion,
					QSQualDate,
					QSActualQualDate,
					CountryCode,		
					IsFromList
				)
				SELECT DISTINCT  
				L.PK_Event,
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate, 
				d.dSupervisorReQualification AS dSPRequalDate,
				D.dSPDemotion AS dSPDemotion, 				
				D.dQSQualification AS dQSQualification,				
				D.dQSQualification_Actual AS dQSQualification_Actual,
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsFromList
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSList AS L
						ON D.nDistributorID = L.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = L.PK_Distributor AND T.PK_Event = L.PK_Event)

				UPDATE D
				SET IsFromList = 1
				FROM #DS AS D  
					INNER JOIN #DSList AS L
						ON D.PK_Distributor = L.PK_Distributor

			SELECT @StepGroup = 2, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

			SELECT @StepGroup = 2, @StepSubGroup = 2, @Milestone = 'Getting Distributors with SKU';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

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
					PK_Event INT 
				)

				INSERT INTO #SKUs(PK_Event,SKUCode)
				SELECT DISTINCT l.PK_Event, s.SKUCode
						FROM [dbo].[EventSKU] AS s WITH (NOLOCK) 
						INNER JOIN #LocationEventID AS l
						ON s.PK_Event = l.PK_Event

				INSERT INTO #DSSKUs(PK_Distributor,PK_EventSKU,PK_Event,SKUCode,UniqueID)
				SELECT DISTINCT et.PK_Distributor_Purchaser,esku.PK_EventSKU, s.PK_Event, esku.SKUCode ,CAST(l.PK_Event AS NVARCHAR(20)) + '-' + CAST(et.PK_Distributor_Purchaser AS NVARCHAR(20))+ '-'+ CAST(esku.SKUCode  AS NVARCHAR(20))  AS UniqueID 
				FROM #SKUs AS s 
					INNER JOIN dbo.EventSKU AS esku WITH (NOLOCK)
						ON s.SKUCode = esku.SKUCode
					INNER JOIN [dbo].[SKUPurchased] et WITH (NOLOCK)
						ON et.PK_EventSKU = esku.PK_EventSKU
					INNER JOIN #LocationEventID AS l
						ON et.PK_Event = l.PK_Event

				CREATE INDEX IX_DSSKUs_PK_Distributor ON #DSSKUs(PK_Distributor)

				INSERT INTO #DS
				(
					PK_Event,
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,		
					dSPRequalDate,
					dSPDemotion,
					QSQualDate,
					QSActualQualDate,
					CountryCode,
					IsTicketPurchaser
				)
				SELECT DISTINCT   
				S.PK_Event,
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,   
				d.dSupervisorReQualification AS dSPRequalDate,
				d.dSPDemotion AS dSPDemotion,
				D.dQSQualification AS dQSQualification,				
				D.dQSQualification_Actual AS dQSQualification_Actual,
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsTicketPurchaser
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSSKUs AS S
						ON D.nDistributorID = S.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = S.PK_Distributor AND T.PK_Event = S.PK_Event)

				UPDATE D
				SET IsTicketPurchaser = 1
				FROM #DS AS D  
					INNER JOIN #DSSKUs AS S
						ON D.PK_Distributor = S.PK_Distributor

			SELECT @StepGroup = 2, @StepSubGroup = 2
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

			
		END 

		--Step 2 (Extension): EventQual
		IF @Step >= 2
		BEGIN

			PRINT 'Executing step 2 (Extension)'

			SELECT @StepGroup = 2, @StepSubGroup = 3, @Milestone = 'Getting qualifications';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
			
				--NewFQS
				UPDATE D
				SET NewSPQualDate = IIF(D.dSPDemotion = '1900-01-01' OR D.dSPDemotion IS NULL, 
										D.dSPQualDate, -- First time ever / never demoted
										IIF(D.dSPQualDate > D.dSPReQualDate OR D.dSPReQualDate IS NULL ,D.dSPQualDate,D.dSPReQualDate) -- If demoted then get the latest date between SPQualDate and SPReQualDate
									)
				FROM #DS AS D  
				WHERE DSSPTeam = 'SP'

				--DSSNAPSHOT

				DROP TABLE IF EXISTS #DSSNAPSHOT

				SELECT
					DSN.PK_Distributor,
					DSN.ROYALTYMONTH,
					DSN.SUBTYPECODE,
					DSN.TEAMCODE
				INTO #DSSNAPSHOT
				FROM #DS AS d
					INNER JOIN [PubEventManagement].[Shared].[DSSNAPSHOT] AS DSN WITH (NOLOCK)
						 ON d.PK_Distributor = DSN.PK_Distributor			 
				ORDER BY PK_Distributor,ROYALTYMONTH DESC

				-- AWT (Non-TAB) Qual or Requal
				DROP TABLE IF EXISTS #AWT_QualRequal 

				SELECT PK_Distributor,IsNonTab, IsQualified,QualDate
				INTO #AWT_QualRequal
				FROM 
					(
					 SELECT  
						PK_Distributor,IsNonTab, IsQualified,
						CASE QualMonth  
							WHEN 'Jan' THEN  DATEFROMPARTS(@AWTYear, 1, 1)
							WHEN 'Feb' THEN  DATEFROMPARTS(@AWTYear, 2, 1)
							WHEN 'Mar' THEN  DATEFROMPARTS(@AWTYear, 3, 1)
							WHEN 'Apr' THEN  DATEFROMPARTS(@AWTYear, 4, 1)
							WHEN 'May' THEN  DATEFROMPARTS(@AWTYear, 5, 1)
							WHEN 'Jun' THEN  DATEFROMPARTS(@AWTYear, 6, 1)
							WHEN 'Jul' THEN  DATEFROMPARTS(@AWTYear, 7, 1)
							WHEN 'Aug' THEN  DATEFROMPARTS(@AWTYear, 8, 1)
							WHEN 'Sep' THEN  DATEFROMPARTS(@AWTYear, 9, 1)
							WHEN 'Oct' THEN  DATEFROMPARTS(@AWTYear, 10, 1)
							WHEN 'Nov' THEN  DATEFROMPARTS(@AWTYear, 11, 1)
							WHEN 'Dec' THEN  DATEFROMPARTS(@AWTYear, 12, 1)
						END AS QualDate 
					 FROM
						(
							SELECT d.PK_Distributor 
							,a.IsNonTab
							,a.AWTYear
							,a.Qual_AWT  
							,t.[Jan]
							,t.[Feb]
							,t.[Mar]
							,t.[Apr]
							,t.[May]
							,t.[Jun]
							,t.[Jul]
							,t.[Aug]
							,t.[Sep]
							,t.[Oct]
							,t.[Nov]
							,t.[Dec] 
						FROM #DS AS d  
 						INNER JOIN dbo.[AWT] AS a WITH (NOLOCK)
 	 						ON d.PK_Distributor = a.PK_Distributor 
						INNER JOIN [dbo].[AWT_Qualifiers_Tracking] AS t WITH (NOLOCK)
							ON a.PK_Distributor = t.PK_Distributor AND a.AWTYear = t.AWTYear
 						WHERE a.AWTYear = @AWTYear 
						) p	UNPIVOT (IsQualified FOR QualMonth IN ([Jan],[Feb],[Mar],[Apr],[May],[Jun],[Jul],[Aug],[Sep],[Oct],[Nov],[Dec])) AS up
					) AS qr
				WHERE IsQualified = 1
				AND isNonTAB = @IsNonTAB
				AND QualDate BETWEEN @AWTQualDateStart AND @AWTQualDateEnd
				 
				UPDATE D
				SET IsAWTQualifier = 1
				FROM #DS AS d
					INNER JOIN #AWT_QualRequal AS q
						ON d.PK_Distributor = q.PK_Distributor

				--New QP

				DROP TABLE IF EXISTS #CurrentQP

				SELECT 
					PK_Distributor,
					CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
					DSSubTeam AS SUBTYPECODE
				INTO #CurrentQP
				FROM #DS WHERE DSSubTeam = 'QP'
				GROUP BY PK_Distributor,DSSubTeam
			 
				DROP TABLE IF EXISTS #NewQP
			
				;WITH cte_QPBeforePeriod AS
				(
					SELECT DISTINCT PK_DISTRIBUTOR 
					FROM #DSSNAPSHOT WHERE TEAMCODE = 'W'  AND ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewQPQualDateStart, 112) AS int)
				
				),
				cte_NewQP AS 
				(

					SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH, 0 AS [IsCurrentStatus] 				
					FROM #DSSNAPSHOT AS s
					WHERE TEAMCODE = 'W' 
						AND ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewQPQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewQPQualDateEnd, 112) AS int)
						AND NOT EXISTS (SELECT 1 FROM cte_QPBeforePeriod AS pQP WHERE pQP.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
					GROUP BY PK_DISTRIBUTOR
					UNION
					SELECT PK_DISTRIBUTOR,ROYALTYMONTH,1 AS [IsCurrentStatus]  
					FROM #CurrentQP AS s
					WHERE NOT EXISTS (SELECT 1 FROM cte_QPBeforePeriod AS pqp WHERE pqp.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
				)

				SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) AS ROYALTYMONTH,MAX([IsCurrentStatus]) AS [IsCurrentStatus] 		
				INTO #NewQP
				FROM cte_NewQP
				GROUP BY PK_DISTRIBUTOR

				UPDATE D
					SET D.NewQPQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112), 
						ISNULL((SELECT CONVERT(DATETIME,CONVERT(VARCHAR,MIN(ROYALTYMONTH)) + '01',112) 
							FROM #DSSNAPSHOT WHERE PK_Distributor = D.PK_Distributor AND SUBTYPECODE = 'QP' GROUP BY PK_Distributor),'1900-01-01'))
				FROM #DS AS D 
				LEFT JOIN #NewQP DQ
					ON D.PK_Distributor = DQ.PK_Distributor

				--New SB

				DROP TABLE IF EXISTS #CurrentSB

				SELECT 
					PK_Distributor,
					CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
					DSSubTeam AS SUBTYPECODE
				INTO #CurrentSB
				FROM #DS WHERE DSSubTeam = 'SB'
				GROUP BY PK_Distributor,DSSubTeam
			 
				DROP TABLE IF EXISTS #NewSB
			
				;WITH cte_SBBeforePeriod AS
				(
					SELECT DISTINCT PK_DISTRIBUTOR 
					FROM #DSSNAPSHOT WHERE TEAMCODE = 'W'  AND ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewSBQualDateStart, 112) AS int)
				
				),
				cte_NewSB AS 
				(

					SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH, 0 AS [IsCurrentStatus] 				
					FROM #DSSNAPSHOT AS s
					WHERE TEAMCODE = 'W' 
						AND ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewSBQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewSBQualDateEnd, 112) AS int)
						AND NOT EXISTS (SELECT 1 FROM cte_SBBeforePeriod AS psb WHERE psb.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
					GROUP BY PK_DISTRIBUTOR
					UNION
					SELECT PK_DISTRIBUTOR,ROYALTYMONTH,1 AS [IsCurrentStatus]  
					FROM #CurrentSB AS s
					WHERE NOT EXISTS (SELECT 1 FROM cte_SBBeforePeriod AS pSB WHERE pSB.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
				)

				SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) AS ROYALTYMONTH,MAX([IsCurrentStatus]) AS [IsCurrentStatus] 		
				INTO #NewSB
				FROM cte_NewSB
				GROUP BY PK_DISTRIBUTOR

				UPDATE D
					SET D.NewSBQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112), 
						ISNULL((SELECT CONVERT(DATETIME,CONVERT(VARCHAR,MIN(ROYALTYMONTH)) + '01',112) 
							FROM #DSSNAPSHOT WHERE PK_Distributor = D.PK_Distributor AND SUBTYPECODE = 'SB' GROUP BY PK_Distributor),'1900-01-01'))
				FROM #DS AS D 
				LEFT JOIN #NewSB DQ
					ON D.PK_Distributor = DQ.PK_Distributor

				--New WT 

				DROP TABLE IF EXISTS #CurrentWT

				SELECT 
					PK_Distributor,
					CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
					DSSubTeam AS SUBTYPECODE
				INTO #CurrentWT
				FROM #DS WHERE DSSubTeam = 'WT'
				GROUP BY PK_Distributor,DSSubTeam
			 
				DROP TABLE IF EXISTS #NewWT
			
				;WITH cte_WTBeforePeriod AS
				(
					SELECT DISTINCT PK_DISTRIBUTOR 
					FROM #DSSNAPSHOT WHERE TEAMCODE = 'W'  AND ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewWTQualDateStart, 112) AS int)
				
				),
				cte_NewWT AS 
				(

					SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH, 0 AS [IsCurrentStatus] 				
					FROM #DSSNAPSHOT AS s
					WHERE TEAMCODE = 'W' 
						AND ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewWTQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewWTQualDateEnd, 112) AS int)
						AND NOT EXISTS (SELECT 1 FROM cte_WTBeforePeriod AS pwt WHERE pwt.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
					GROUP BY PK_DISTRIBUTOR
					UNION
					SELECT PK_DISTRIBUTOR,ROYALTYMONTH,1 AS [IsCurrentStatus]  
					FROM #CurrentWT AS s
					WHERE NOT EXISTS (SELECT 1 FROM cte_WTBeforePeriod AS pwt WHERE pwt.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
				)

				SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) AS ROYALTYMONTH,MAX([IsCurrentStatus]) AS [IsCurrentStatus] 		
				INTO #NewWT
				FROM cte_NewWT
				GROUP BY PK_DISTRIBUTOR

				UPDATE D
					SET D.NewWTQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112), 
						ISNULL((SELECT CONVERT(DATETIME,CONVERT(VARCHAR,MIN(ROYALTYMONTH)) + '01',112) 
							FROM #DSSNAPSHOT WHERE PK_Distributor = D.PK_Distributor AND SUBTYPECODE = 'WT' GROUP BY PK_Distributor),'1900-01-01'))
				FROM #DS AS D 
				LEFT JOIN #NewWT DQ
					ON D.PK_Distributor = DQ.PK_Distributor
 
				--New GT 

				DROP TABLE IF EXISTS #CurrentGT

				SELECT 
					PK_Distributor,
					CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
					DSSubTeam AS SUBTYPECODE
				INTO #CurrentGT
				FROM #DS WHERE DSSubTeam = 'GT'
				GROUP BY PK_Distributor,DSSubTeam
			 
				DROP TABLE IF EXISTS #NewGT
			
				;WITH cte_GTBeforePeriod AS
				(
					SELECT DISTINCT PK_DISTRIBUTOR 
					FROM #DSSNAPSHOT WHERE SUBTYPECODE = 'GT'  AND ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewGTQualDateStart, 112) AS int)
				
				),
				cte_NewGT AS 
				(

					SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH, 0 AS [IsCurrentStatus] 				
					FROM #DSSNAPSHOT AS s
					WHERE SUBTYPECODE = 'GT' 
						AND ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewGTQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewGTQualDateEnd, 112) AS int)
						AND NOT EXISTS (SELECT 1 FROM cte_GTBeforePeriod AS pgt WHERE pgt.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
					GROUP BY PK_DISTRIBUTOR
					UNION
					SELECT PK_DISTRIBUTOR,ROYALTYMONTH,1 AS [IsCurrentStatus]  
					FROM #CurrentGT AS s
					WHERE NOT EXISTS (SELECT 1 FROM cte_GTBeforePeriod AS pgt WHERE pgt.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
				)

				SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) AS ROYALTYMONTH,MAX([IsCurrentStatus]) AS [IsCurrentStatus] 		
				INTO #NewGT
				FROM cte_NewGT
				GROUP BY PK_DISTRIBUTOR

				UPDATE D
					SET D.NewGTQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112), 
						ISNULL((SELECT CONVERT(DATETIME,CONVERT(VARCHAR,MIN(ROYALTYMONTH)) + '01',112) 
							FROM #DSSNAPSHOT WHERE PK_Distributor = D.PK_Distributor AND SUBTYPECODE = 'GT' GROUP BY PK_Distributor),'1900-01-01'))
				FROM #DS AS D 
				LEFT JOIN #NewGT DQ
					ON D.PK_Distributor = DQ.PK_Distributor

				--New GP 

				DROP TABLE IF EXISTS #CurrentGP

				SELECT 
					PK_Distributor,
					CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
					DSSubTeam AS SUBTYPECODE
				INTO #CurrentGP
				FROM #DS WHERE DSSubTeam = 'GP'
				GROUP BY PK_Distributor,DSSubTeam
			 
				DROP TABLE IF EXISTS #NewGP
			
				;WITH cte_GPBeforePeriod AS
				(
					SELECT DISTINCT PK_DISTRIBUTOR 
					FROM #DSSNAPSHOT WHERE SUBTYPECODE = 'GP'  AND ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewGPQualDateStart, 112) AS int)
				
				),
				cte_NewGP AS 
				(

					SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH, 0 AS [IsCurrentStatus] 				
					FROM #DSSNAPSHOT AS s
					WHERE SUBTYPECODE = 'GP' 
						AND ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewGPQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewGPQualDateEnd, 112) AS int)
						AND NOT EXISTS (SELECT 1 FROM cte_GPBeforePeriod AS pGP WHERE pGP.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
					GROUP BY PK_DISTRIBUTOR
					UNION
					SELECT PK_DISTRIBUTOR,ROYALTYMONTH,1 AS [IsCurrentStatus]  
					FROM #CurrentGP AS s
					WHERE NOT EXISTS (SELECT 1 FROM cte_GPBeforePeriod AS pGP WHERE pGP.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
				)

				SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) AS ROYALTYMONTH,MAX([IsCurrentStatus]) AS [IsCurrentStatus] 		
				INTO #NewGP
				FROM cte_NewGP
				GROUP BY PK_DISTRIBUTOR

				UPDATE D
					SET D.NewGPQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112), 
						ISNULL((SELECT CONVERT(DATETIME,CONVERT(VARCHAR,MIN(ROYALTYMONTH)) + '01',112) 
							FROM #DSSNAPSHOT WHERE PK_Distributor = D.PK_Distributor AND SUBTYPECODE = 'GP' GROUP BY PK_Distributor),'1900-01-01'))
				FROM #DS AS D 
				LEFT JOIN #NewGP DQ
					ON D.PK_Distributor = DQ.PK_Distributor

				--New MT 

				DROP TABLE IF EXISTS #CurrentMT

				SELECT 
					PK_Distributor,
					CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
					DSSubTeam AS SUBTYPECODE
				INTO #CurrentMT
				FROM #DS WHERE DSSubTeam = 'MT'
				GROUP BY PK_Distributor,DSSubTeam
			 
				DROP TABLE IF EXISTS #NewMT
			
				;WITH cte_MTBeforePeriod AS
				(
					SELECT DISTINCT PK_DISTRIBUTOR 
					FROM #DSSNAPSHOT WHERE SUBTYPECODE = 'MT'  AND ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewMTQualDateStart, 112) AS int)
				
				),
				cte_NewMT AS 
				(

					SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH, 0 AS [IsCurrentStatus] 				
					FROM #DSSNAPSHOT AS s
					WHERE SUBTYPECODE = 'MT' 
						AND ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewMTQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewMTQualDateEnd, 112) AS int)
						AND NOT EXISTS (SELECT 1 FROM cte_MTBeforePeriod AS pmt WHERE pmt.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
					GROUP BY PK_DISTRIBUTOR
					UNION
					SELECT PK_DISTRIBUTOR,ROYALTYMONTH,1 AS [IsCurrentStatus]  
					FROM #CurrentMT AS s
					WHERE NOT EXISTS (SELECT 1 FROM cte_MTBeforePeriod AS pmt WHERE pmt.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
				)

				SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) AS ROYALTYMONTH,MAX([IsCurrentStatus]) AS [IsCurrentStatus] 		
				INTO #NewMT
				FROM cte_NewMT
				GROUP BY PK_DISTRIBUTOR

				UPDATE D
					SET D.NewMTQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112), 
						ISNULL((SELECT CONVERT(DATETIME,CONVERT(VARCHAR,MIN(ROYALTYMONTH)) + '01',112) 
							FROM #DSSNAPSHOT WHERE PK_Distributor = D.PK_Distributor AND SUBTYPECODE = 'MT' GROUP BY PK_Distributor),'1900-01-01'))
				FROM #DS AS D 
				LEFT JOIN #NewMT DQ
					ON D.PK_Distributor = DQ.PK_Distributor

				--New MP 

				DROP TABLE IF EXISTS #CurrentMP

				SELECT 
					PK_Distributor,
					CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
					DSSubTeam AS SUBTYPECODE
				INTO #CurrentMP
				FROM #DS WHERE DSSubTeam = 'MP'
				GROUP BY PK_Distributor,DSSubTeam
			 
				DROP TABLE IF EXISTS #NewMP
			
				;WITH cte_MPBeforePeriod AS
				(
					SELECT DISTINCT PK_DISTRIBUTOR 
					FROM #DSSNAPSHOT WHERE SUBTYPECODE = 'MP'  AND ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewMPQualDateStart, 112) AS int)
				
				),
				cte_NewMP AS 
				(

					SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH, 0 AS [IsCurrentStatus] 				
					FROM #DSSNAPSHOT AS s
					WHERE SUBTYPECODE = 'MP' 
						AND ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewMPQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewMPQualDateEnd, 112) AS int)
						AND NOT EXISTS (SELECT 1 FROM cte_MPBeforePeriod AS pMP WHERE pMP.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
					GROUP BY PK_DISTRIBUTOR
					UNION
					SELECT PK_DISTRIBUTOR,ROYALTYMONTH,1 AS [IsCurrentStatus]  
					FROM #CurrentMP AS s
					WHERE NOT EXISTS (SELECT 1 FROM cte_MPBeforePeriod AS pMP WHERE pMP.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
				)

				SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) AS ROYALTYMONTH,MAX([IsCurrentStatus]) AS [IsCurrentStatus] 		
				INTO #NewMP
				FROM cte_NewMP
				GROUP BY PK_DISTRIBUTOR

				UPDATE D
					SET D.NewMPQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112), 
						ISNULL((SELECT CONVERT(DATETIME,CONVERT(VARCHAR,MIN(ROYALTYMONTH)) + '01',112) 
							FROM #DSSNAPSHOT WHERE PK_Distributor = D.PK_Distributor AND SUBTYPECODE = 'MP' GROUP BY PK_Distributor),'1900-01-01'))
				FROM #DS AS D 
				LEFT JOIN #NewMP DQ
					ON D.PK_Distributor = DQ.PK_Distributor

				--New PT 

				DROP TABLE IF EXISTS #CurrentPT

				SELECT 
					PK_Distributor,
					CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
					DSSubTeam AS SUBTYPECODE
				INTO #CurrentPT
				FROM #DS WHERE DSSubTeam = 'PT'
				GROUP BY PK_Distributor,DSSubTeam
			 
				DROP TABLE IF EXISTS #NewPT
			
				;WITH cte_PTBeforePeriod AS
				(
					SELECT DISTINCT PK_DISTRIBUTOR 
					FROM #DSSNAPSHOT WHERE TEAMCODE = 'P'  AND ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewPTQualDateStart, 112) AS int)
				
				),
				cte_NewPT AS 
				(

					SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH, 0 AS [IsCurrentStatus] 				
					FROM #DSSNAPSHOT AS s
					WHERE TEAMCODE = 'P' 
						AND ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewPTQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewPTQualDateEnd, 112) AS int)
						AND NOT EXISTS (SELECT 1 FROM cte_PTBeforePeriod AS ppt WHERE ppt.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
					GROUP BY PK_DISTRIBUTOR
					UNION
					SELECT PK_DISTRIBUTOR,ROYALTYMONTH,1 AS [IsCurrentStatus]  
					FROM #CurrentPT AS s
					WHERE NOT EXISTS (SELECT 1 FROM cte_PTBeforePeriod AS ppt WHERE ppt.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
				)

				SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) AS ROYALTYMONTH,MAX([IsCurrentStatus]) AS [IsCurrentStatus] 		
				INTO #NewPT
				FROM cte_NewPT
				GROUP BY PK_DISTRIBUTOR

				UPDATE D
					SET D.NewPTQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112), 
						ISNULL((SELECT CONVERT(DATETIME,CONVERT(VARCHAR,MIN(ROYALTYMONTH)) + '01',112) 
							FROM #DSSNAPSHOT WHERE PK_Distributor = D.PK_Distributor AND SUBTYPECODE = 'PT' GROUP BY PK_Distributor),'1900-01-01'))
				FROM #DS AS D 
				LEFT JOIN #NewPT DQ
					ON D.PK_Distributor = DQ.PK_Distributor

			SELECT @StepGroup = 2, @StepSubGroup = 3
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


			SELECT @StepGroup = 2, @StepSubGroup = 4, @Milestone = '#EventQual';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

			INSERT INTO #EventQual(PK_Distributor,PK_Event)
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event] 
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
						 
				--L1 204725	Nicaragua								NI
				--L2 204680	Chile									CL
				--L3 204685	Republica Dominicana					DR
				--L4 204686	Venezuela								VE
				--L5 204681	Colombia 								CO
				--L6 204723	Honduras								HN
				--L7 204684	Guatemala - El Salvador - Costa Rica	GT/SV/CR 		
				--L9 204677	Peru									PE
				--L10 204678	Argentina - Uruguay					AR/UY
				--L11 204675	Panama								PM
				--L12 204683	Ecuador								EC 	
	 			UPDATE q
					SET	Q01 = IIF(d.DSSPTeam = 'SP' ,1,0) -- Q01: FQS and above
				FROM #EventQual AS q
					INNER JOIN #DS AS d
						ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event					
				WHERE d.PK_Event IN (@PK_Event_L1,@PK_Event_L2,@PK_Event_L3,@PK_Event_L4,@PK_Event_L5,@PK_Event_L6,@PK_Event_L7,@PK_Event_L9,@PK_Event_L10,@PK_Event_L11,@PK_Event_L12)
 	 			 		 
				--All locations
				--L1 204725	Nicaragua								NI
				--L2 204680	Chile									CL
				--L3 204685	Republica Dominicana					DR
				--L4 204686	Venezuela								VE
				--L5 204681	Colombia 								CO
				--L6 204723	Honduras								HN
				--L7 204684	Guatemala - El Salvador - Costa Rica	GT/SV/CR 
				--L8 204682	Bolivia									BL 		
				--L9 204677	Peru									PE
				--L10 204678	Argentina - Uruguay						AR/UY
				--L11 204675	Panama									PM
				--L12 204683	Ecuador									EC 
				UPDATE q
					SET	
						Q02 = IIF(dSPQualDate IS NOT NULL AND dSPDemotion IS NULL AND dSPQualDate BETWEEN @NewFQSQualDateStart AND @NewFQSQualDateEnd, 1, 0),	-- Q02: New FQS (SP Qual date Nov 2025 - Feb 2026) 
						Q03 = IIF(d.QSActualQualDate BETWEEN @QSActualQualDateStart AND @QSActualQualDateEnd,1,0),												-- Q03: QS, QV, PQS, SQS, 2QS, 5QS (Qual date: Feb 2026)
						Q04 = IIF(d.NewWTQualDate > d.NewSPQualDate AND d.NewWTQualDate BETWEEN @NewWTQualDateStart AND @NewWTQualDateEnd,1,0),					-- Q04: New WT (WT Qual date Nov 2025 - Feb 2026)
						Q05 = IIF(d.DSCurrentTeam IN ('G','M','P','A','B','C'), 1,0),																			-- Q05:	TAB team
						Q07 = IIF(d.IsAWTQualifier = 1, 1,0)																									-- Q07: AWT (Non-TAB) (Qual dates Oct 2025 - Dec 2025) (Qualified OR Re-qualified)
				FROM #EventQual AS q
					INNER JOIN #DS AS d
						ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event	
						
				-- L4 204686	Venezuela								VE
				UPDATE q
					SET	 Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0) , -- Q06: PT and above (COP VE)
						 Q28 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q27:  New GT and above (Team qual date Nov 2025 - Feb 2026) 
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L4
  
				--L8 204682	Bolivia									BL
				UPDATE q
					SET	 
						Q01 = ISNULL(IIF(d.DSSubTeam IN ('QS','QV','PQS','SQS','2QS','5QS') OR d.DSSPTeam = 'SP',1,0),0), -- Q01: QS and above Note: QS should include QS, QV, PQS, SQS, 2QS, 5QS
						Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),  -- Q06: PT and above (COP Bolivia)
						Q34 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewGPQualDate BETWEEN @NewGPQualDateStart AND @NewGPQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewMPQualDate BETWEEN @NewMPQualDateStart AND @NewMPQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q34:  New GT or New GP or New MT or New MP or New PT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L8

				--L10 204678	Argentina - Uruguay						AR/UY
				UPDATE q
					SET	Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),  -- Q06:  PT and above (COP AR or UY)
						Q30 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewGPQualDate BETWEEN @NewGPQualDateStart AND @NewGPQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewMPQualDate BETWEEN @NewMPQualDateStart AND @NewMPQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q34:  New GT or New GP or New MT or New MP or New PT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L10 

				--L2 204680	Chile									CL
				UPDATE q
					SET	 Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),  -- Q06:  PT and above (COP Chile)
						 Q21 = IIF(d.DSCurrentTeam IN ('SP','W'),1,0),			-- Q21: FQS non-TAB (SP & WT)
						 Q34 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewGPQualDate BETWEEN @NewGPQualDateStart AND @NewGPQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewMPQualDate BETWEEN @NewMPQualDateStart AND @NewMPQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q34:  New GT or New GP or New MT or New MP or New PT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L2

				--L1 204725	Nicaragua								NI
				UPDATE q
					SET	Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),							-- Q06:  PT and above (COP NI)
						Q32 = IIF(d.DSCurrentTeam = 'SP', 1,0),											-- Q32: SP only
						Q33 = IIF(d.DSCurrentTeam != 'SP', 1,0),										-- Q33: WT and above
						Q34 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd 
							OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd, 1,0)	-- Q34: New GT or New MT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L1

				--L3 204685	Republica Dominicana					DR
				UPDATE q
					SET	 Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),  -- Q06:  PT and above (COP Dominican Republic)
						 Q09 = IIF(d.DSCurrentTeam = 'DS',1,0),					--Q09:	DS (Non SP)
						 Q10 = IIF(d.NewQPQualDate BETWEEN @NewQPQualDateStart AND @NewQPQualDateEnd,1,0) 	--Q10:	New QP (Qualified Producer) (Oct 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L3

				--L5 204681	Colombia 								CO
				UPDATE q
					SET	 Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),  -- Q06:  PT and above (COP CO)
						 Q31 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewGPQualDate BETWEEN @NewGPQualDateStart AND @NewGPQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewMPQualDate BETWEEN @NewMPQualDateStart AND @NewMPQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q34:  New GT or New GP or New MT or New MP or New PT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L5

				--L6 204723	Honduras								HN
				UPDATE q
					SET	 Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),  -- Q06:  PT and above (COP HN)
						 Q09 = IIF(d.DSCurrentTeam = 'DS',1,0),					--Q09:	DS (Non SP)
						 Q10 = IIF(d.NewSBQualDate BETWEEN @NewSBQualDateStart AND @NewSBQualDateEnd,1,0), --Q10:	New SC (Success Builder) (Oct 2025 - Feb 2026)
						 Q47 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewGPQualDate BETWEEN @NewGPQualDateStart AND @NewGPQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewMPQualDate BETWEEN @NewMPQualDateStart AND @NewMPQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q34:  New GT or New GP or New MT or New MP or New PT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L6

				--L9 204677	Peru									PE
				UPDATE q
					SET	 Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0), -- Q06:  PT and above (COP PE)
						 Q31 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewGPQualDate BETWEEN @NewGPQualDateStart AND @NewGPQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewMPQualDate BETWEEN @NewMPQualDateStart AND @NewMPQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q34:  New GT or New GP or New MT or New MP or New PT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L9

				--L12 204683	Ecuador									EC 
				UPDATE q
					SET	 Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),  -- Q06:  PT and above (COP EC)
						 Q31 = IIF(dSPQualDate BETWEEN @NewFQSQualDateStartB AND @NewFQSQualDateEndB OR (dSPDemotion IS NOT NULL AND dSPRequalDate BETWEEN @NewFQSQualDateStartB AND @NewFQSQualDateEndB), 1, 0),	-- New FQS (SP Qual date Jul 01 2025 - Oct 01 2025) 
						 Q32 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewGPQualDate BETWEEN @NewGPQualDateStart AND @NewGPQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewMPQualDate BETWEEN @NewMPQualDateStart AND @NewMPQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q34:  New GT or New GP or New MT or New MP or New PT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L12

				--L7 204684	Guatemala - El Salvador - Costa Rica	GT/SV/CR
				UPDATE q
					SET	 Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),  -- Q06:  PT and above (COP GT, SV, CR)
						 Q31 = IIF(dSPQualDate BETWEEN @NewFQSQualDateStartB AND @NewFQSQualDateEndB OR (dSPDemotion IS NOT NULL AND dSPRequalDate BETWEEN @NewFQSQualDateStartB AND @NewFQSQualDateEndB), 1, 0),	-- New FQS (SP Qual date Jul 01 2025 - Oct 01 2025) 
						 Q32 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewGPQualDate BETWEEN @NewGPQualDateStart AND @NewGPQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewMPQualDate BETWEEN @NewMPQualDateStart AND @NewMPQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q34:  New GT or New GP or New MT or New MP or New PT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L7

				--L11 204675	Panama									PM
				UPDATE q
					SET	 Q06 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0),  -- Q06:  PT and above (COP Panama)
						 Q32 = IIF(dSPQualDate BETWEEN @NewFQSQualDateStartB AND @NewFQSQualDateEndB OR (dSPDemotion IS NOT NULL AND dSPRequalDate BETWEEN @NewFQSQualDateStartB AND @NewFQSQualDateEndB), 1, 0),	-- New FQS (SP Qual date Jul 01 2025 - Oct 01 2025) 
						 Q33 = IIF(d.NewGTQualDate BETWEEN @NewGTQualDateStart AND @NewGTQualDateEnd OR d.NewGPQualDate BETWEEN @NewGPQualDateStart AND @NewGPQualDateEnd OR d.NewMTQualDate BETWEEN @NewMTQualDateStart AND @NewMTQualDateEnd OR d.NewMPQualDate BETWEEN @NewMPQualDateStart AND @NewMPQualDateEnd OR d.NewPTQualDate BETWEEN @NewPTQualDateStart AND @NewPTQualDateEnd,1,0) -- Q34:  New GT or New GP or New MT or New MP or New PT (Qual date Nov 2025 - Feb 2026)
				FROM #EventQual AS q 
				INNER JOIN #DS AS d
				ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event		
				WHERE d.PK_Event = @PK_Event_L11  

			SELECT @StepGroup = 2, @StepSubGroup = 4
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


			SELECT @StepGroup = 2, @StepSubGroup = 5, @Milestone = 'WRK_26034_DSDetails';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone


			DROP TABLE IF EXISTS dbo.[WRK_26034_DSDetails]

			SELECT  
				PK_Event				
				,PK_Distributor			
				,DSCurrentTeam			
				,DSSubTeam				
				,DSSPTeam				
				,dSPQualDate				
				,dSPRequalDate			
				,dSPDemotion				
				,QSQualDate				
				,QSActualQualDate		
				,CountryCode				
				,IsFromList				
				,IsTicketPurchaser 
				,NewSPQualDate		
				,NewWTQualDate		
				,IsAWTQualifier		
				,NewGTQualDate
				,NewGPQualDate	
				,NewMTQualDate	
				,NewMPQualDate	
				,NewPTQualDate		
				,NewQPQualDate		
				,NewSBQualDate		
			INTO dbo.[WRK_26034_DSDetails]
			FROM #DS

			SELECT @StepGroup = 2, @StepSubGroup = 5
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


		END

		--Step 3: Volume		
		IF @Step >= 3 
		BEGIN
 
			SELECT @StepGroup = 3, @StepSubGroup = 1, @Milestone = 'Getting values from #Event_SetupEventQualification';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

				SELECT 
					@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
					@dStartDate = MIN(dStartDate),
					@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
					@dEndDate = MAX(dEndDate),
					@MetricType = STRING_AGG([MetricType], ','),
					@DSCountries = STRING_AGG([Countries],',')
				FROM #Event_SetupEventQualification AS s WITH (NOLOCK) 
	
				;WITH cte_MetricType AS (SELECT DISTINCT TRIM([value]) AS [metric] FROM STRING_SPLIT(@MetricType,','))
				 
				 SELECT @MetricType = STRING_AGG([metric],',') FROM cte_MetricType
				 
				-- Result set 
				SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate],@DSCountries AS [DSCountries],@MetricType AS [MetricType]
				 
			SELECT @StepGroup = 3, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

				------------------------------------------------------------------------------------------------
				-- 3.2 Getting #tmp_DS
				------------------------------------------------------------------------------------------------
			
				SELECT @StepGroup = 3, @StepSubGroup = 2, @Milestone = 'Getting #tmp_DS';
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

					DROP INDEX IF EXISTS IX_#tmp_DS_PK_Distributor ON #tmp_DS;

					DELETE #tmp_DS

					INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
					SELECT DISTINCT
						D.PK_Event AS [PK_Event],
						D.PK_Distributor AS PK_Distributor,
						DD.sDistributorID AS DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						DD.dSupervisorQualification 
					FROM #DS AS D
					INNER JOIN v_Distributor AS DD
						ON D.PK_Distributor = DD.nDistributorID		 

					CREATE INDEX IX_#tmp_DS_PK_Distributor ON #tmp_DS(PK_Distributor);	

					IF (@IsDevQA = 0)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_DS_PK_Distributor]
							ON [tmp].[DS];

						DELETE d FROM [tmp].[DS] AS d  
							INNER JOIN #LocationEventID AS lm
								ON d.PK_Event = lm.PK_Event

						INSERT INTO [tmp].[DS]([PK_Event],[PK_Distributor],[StartDate],[EndDate])
						SELECT 
							PK_Event AS [PK_Event],
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate]
						FROM #tmp_DS AS D  			 
						
						CREATE INDEX IX_DS_PK_Distributor ON [tmp].[DS](PK_Distributor) INCLUDE(PK_Event);

					END
					
				SELECT @StepGroup = 3, @StepSubGroup = 2
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

				------------------------------------------------------------------------------------------------
				-- 3.3 Getting [Event].[DSPoints]
				------------------------------------------------------------------------------------------------
			
				IF (@IsDevQA = 0)
				BEGIN
					
					SELECT @StepGroup = 3, @StepSubGroup = 3, @Milestone = 'Getting [Event].[DSPoints]';
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
					
					--Input
					--[tmp].[DS]
					--[Event].[SetupEventQualification]

					PRINT CONCAT('Getting volumen for: ', @PK_EventMultiLocation);

					--SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_EventMultiLocation, @SourceType = 3, @QualFilter = NULL, @KeepNegativeVolume =0, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
					--Output 
					-- [Event].[DSPoints]
					-- [tmp].[DSSummary] 

					IF @Error <> 0
					BEGIN
						SET @Error = @Error
						SET @ErrorMessage = @ErrorMessage
						RETURN;
					END

					SELECT @StepGroup = 3, @StepSubGroup = 3
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

		
				END
								
				------------------------------------------------------------------------------------------------
				-- 3.5 Getting #Event_DSPoints AND #Event_DSPoints_Validations
				------------------------------------------------------------------------------------------------
		 
				SELECT @StepGroup = 3, @StepSubGroup = 5, @Milestone = 'Getting #Event_DSPoints';
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
 
					INSERT INTO #Event_DSPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])
						SELECT 
							PK_Distributor,
							p.[PK_Event],
							p.PK_Country,
							[RoyaltyMonth],
							MetricType,
							[PersonalPoints] AS [PersonalPoints],
							[TransferPoints] AS [TransferPoints],
							[MainPoints] AS [MainPoints], 
							ROUND([Points],2) AS [Points],
							Bonus
						FROM [Event].[DSPoints] AS p WITH (NOLOCK)
							INNER JOIN #LocationEventID AS lm
								ON p.PK_Event = lm.PK_Event				 
									
				SELECT @StepGroup = 3, @StepSubGroup = 5
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


			SELECT @StepGroup = 3, @StepSubGroup = 6, @Milestone = 'Creating WRK_26034_DSPoints';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
 
			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])

			IF @IsDevQA = 0
			BEGIN
				 
				DROP TABLE IF EXISTS [dbo].[WRK_26034_DSPoints] 
					
				SELECT 
					p.PK_Distributor,
					p.[PK_Event],
					PK_Country,
					[RoyaltyMonth],
					MetricType,
					[PersonalPoints],
					[TransferPoints],
					[MainPoints], 
					[Points] 
				INTO [dbo].[WRK_26034_DSPoints] 
				FROM #Event_DSPoints AS p
					INNER JOIN #DS AS d
						ON p.PK_Distributor = d.PK_Distributor AND p.PK_Event = d.PK_Event

				CREATE INDEX IX_WRK_26034_DSPoints_PK_Distributor ON [dbo].[WRK_26034_DSPoints] (PK_Distributor);

			END
				
			SELECT @StepGroup = 3, @StepSubGroup = 6
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
					
		END
 
		--Step 4: Qualification definition
		IF @Step >= 4 
		BEGIN
				PRINT 'Executing step 4'

				------------------------------------------------------------------------------------------------
				-- 4.1 Getting all qualification definition for each DS
				------------------------------------------------------------------------------------------------

				SELECT @StepGroup = 4, @StepSubGroup = 1, @Milestone = 'Getting all qualification definition for each DS';
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

				
					DROP TABLE IF EXISTS #tmpQualDef

						SELECT  
							C.PK_Event, 
							A.StartDate AS dStartDate,
							A.EndDate AS dEndDate,
							CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
							CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
							C.Frequency AS Frequency,
							C.Consecutive AS Consecutive,
							C.Accumulated AS Accumulated,
							C.MetricType AS MetricType,
							C.GoalPoints AS GoalPoints,
							C.MinPoints AS MinPoints,
							C.QualificationNumber,
							C.Part, 
							C.Countries,
							C.QSVolume
						INTO #tmpQualDef
						FROM #Event_SetupEventQualification AS C WITH (NOLOCK)  			
							CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A

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

					INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,QSVolume)
						SELECT 
							D.PK_Event,
							D.PK_Distributor AS PK_Distributor,
							C.dStartDate,
							C.dEndDate,
							C.iStartDate,
							C.iEndDate,
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
							m.PK_AssociatedID AS PK_AssociatedID,
							C.Countries,
							C.QSVolume
						FROM #DS AS D					
							INNER JOIN #tmpQualDef AS C
								ON C.PK_Event = D.PK_Event
							LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
								ON D.PK_Distributor = M.PK_Distributor	 

					CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

				SELECT @StepGroup = 4, @StepSubGroup = 1
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

				IF @IsDevQA = 0
				BEGIN

					SELECT @StepGroup = 4, @StepSubGroup = 2, @Milestone = '[tmp].[DSQualDef] drop index';
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

					DROP INDEX IF EXISTS IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef];

					SELECT @StepGroup = 4, @StepSubGroup = 2
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
					
					SELECT @StepGroup = 4, @StepSubGroup = 3, @Milestone = '[tmp].[DSQualDef] delete';
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

					DELETE d 
						FROM [tmp].[DSQualDef] AS d
						INNER JOIN #LocationEventID AS lm
						ON d.PK_Event = lm.PK_Event		

					SELECT @StepGroup = 4, @StepSubGroup = 3
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
					
					SELECT @StepGroup = 4, @StepSubGroup = 4, @Milestone = '[tmp].[DSQualDef] insert';
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

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

				CREATE INDEX IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef](PK_Event);

				SELECT @StepGroup = 4, @StepSubGroup = 4
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
									
			END  

		END

		--Step 5: Bonuses
		IF @Step >= 5
		BEGIN			

			PRINT 'Executing step 5'

			-----------------------------------------------------------------------------------------------------------------
			-- 5.1 Getting NEW SP Bonus
			-----------------------------------------------------------------------------------------------------------------
		 
			--This Promotion is not applicable for Existing SPs
			--Applies for New SPs (SP for the first time) OR re-qualified SPs (that had a demotion and converted again to SP in the period)
		
			DROP TABLE IF EXISTS #NewFQSBonus
								 
			SELECT PK_Event,PK_Distributor,NewSPQualDate  AS SPQualDate,  CAST(CONVERT(varchar(6), NewSPQualDate, 112) AS int) AS iSPQualDate
			INTO #NewFQSBonus
			FROM #DS 
			WHERE 
				NewSPQualDate BETWEEN @NewFQSBonusDateStart AND @NewFQSBonusDateEnd  	
 
			DROP TABLE IF EXISTS [dbo].[WRK_26034_NewFQSBonusSummary]  

			SELECT 
				p.PK_Event,
				p.PK_Distributor,
				p.MetricType,
				p.RoyaltyMonth,
				[Points] AS [NewFQSBonus],
				b.iSPQualDate AS [iSPQualDate],
				CASE p.PK_Event
								WHEN @PK_Event_L1 THEN @NewFQSBonusAppliesToL1
								WHEN @PK_Event_L2 THEN @NewFQSBonusAppliesToL2
								WHEN @PK_Event_L3 THEN @NewFQSBonusAppliesToL3
								WHEN @PK_Event_L4 THEN @NewFQSBonusAppliesToL4
								WHEN @PK_Event_L5 THEN @NewFQSBonusAppliesToL5
								WHEN @PK_Event_L6 THEN @NewFQSBonusAppliesToL6
								WHEN @PK_Event_L7 THEN @NewFQSBonusAppliesToL7
								WHEN @PK_Event_L8 THEN @NewFQSBonusAppliesToL8
								WHEN @PK_Event_L9 THEN @NewFQSBonusAppliesToL9
								WHEN @PK_Event_L10 THEN @NewFQSBonusAppliesToL10
								WHEN @PK_Event_L11 THEN @NewFQSBonusAppliesToL11
								WHEN @PK_Event_L12 THEN @NewFQSBonusAppliesToL12 END AS BonusAppliesTo
			INTO [dbo].[WRK_26034_NewFQSBonusSummary] 
			FROM [dbo].[WRK_26034_DSPoints] AS p WITH (NOLOCK)
				INNER JOIN #NewFQSBonus AS b
					ON p.PK_Distributor = b.PK_Distributor AND p.PK_Event = b.PK_Event AND p.RoyaltyMonth >= iSPQualDate
			WHERE p.MetricType = @BonusMetric

			-----------------------------------------------------------------------------------------------------------------
			-- 5.5 Getting Double Volume Month Bonus
			-----------------------------------------------------------------------------------------------------------------

			SELECT @StepGroup = 5, @StepSubGroup = 5, @Milestone = 'Getting Double Volume Month Bonus';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
		
			DROP TABLE IF EXISTS #VolumeRank

			SELECT
				PK_Event,
				PK_Distributor,
				MetricType,
				RoyaltyMonth,
				[Points],
				ROW_NUMBER() OVER (PARTITION BY PK_Event,PK_Distributor, MetricType ORDER BY [Points] DESC) AS [Rank]
			INTO #VolumeRank
			FROM [dbo].[WRK_26034_DSPoints] WITH (NOLOCK) 
			WHERE RoyaltyMonth IN (CAST(CONVERT(varchar(6), @DoubleVolumeMonth1, 112) AS int),CAST(CONVERT(varchar(6), @DoubleVolumeMonth2, 112) AS int))
			AND MetricType = @BonusMetric

			DROP TABLE IF EXISTS [dbo].[WRK_26034_DoubleVolumeBonusSummary]  

			SELECT  vr.PK_Event,
					vr.PK_Distributor,
					vr.MetricType,
					vr.RoyaltyMonth,
					vr.[Points],
					IIF(vr.RoyaltyMonth = CAST(CONVERT(varchar(6), @DoubleVolumeMonth1, 112) AS int), 
						IIF(vr.[Points] >= @DoubleVolumeMonth1UpTo, @DoubleVolumeMonth1UpTo,[Points]),
							IIF(vr.RoyaltyMonth = CAST(CONVERT(varchar(6), @DoubleVolumeMonth2, 112) AS int),
								IIF(vr.[Points] >= @DoubleVolumeMonth2UpTo, @DoubleVolumeMonth2UpTo,[Points]),0)) AS [DoubleVolumeBonus],
					CASE vr.PK_Event
								WHEN @PK_Event_L1 THEN @DoubleVolumeBonusAppliesToL1
								WHEN @PK_Event_L2 THEN @DoubleVolumeBonusAppliesToL2
								WHEN @PK_Event_L3 THEN @DoubleVolumeBonusAppliesToL3
								WHEN @PK_Event_L4 THEN @DoubleVolumeBonusAppliesToL4
								WHEN @PK_Event_L5 THEN @DoubleVolumeBonusAppliesToL5
								WHEN @PK_Event_L6 THEN @DoubleVolumeBonusAppliesToL6
								WHEN @PK_Event_L7 THEN @DoubleVolumeBonusAppliesToL7
								WHEN @PK_Event_L8 THEN @DoubleVolumeBonusAppliesToL8
								WHEN @PK_Event_L9 THEN @DoubleVolumeBonusAppliesToL9
								WHEN @PK_Event_L10 THEN @DoubleVolumeBonusAppliesToL10
								WHEN @PK_Event_L11 THEN @DoubleVolumeBonusAppliesToL11
								WHEN @PK_Event_L12 THEN @DoubleVolumeBonusAppliesToL12 END AS BonusAppliesTo
			INTO [dbo].[WRK_26034_DoubleVolumeBonusSummary]
			FROM #VolumeRank AS vr
				LEFT JOIN #NewFQSBonus AS nfqs
					ON vr.PK_Distributor = nfqs.PK_Distributor -- This Promotion is not applicable for New Supervisors. 
			WHERE [Rank] = 1 AND nfqs.PK_Distributor IS NULL

			SELECT @StepGroup = 5, @StepSubGroup = 5
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
				 
 			------------------------------------------------------------------------------------------------
			-- 5.8 #Event_DSPoints_Summary
			------------------------------------------------------------------------------------------------
		 
			SELECT @StepGroup = 5, @StepSubGroup = 8, @Milestone = '#Event_DSPoints_Summary';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
			
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
					[MonthIndex] [int]
				)

				INSERT INTO #Event_DSPoints_Summary(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries,[MonthIndex])
					SELECT U.PK_Event,
							U.PK_Distributor,
							U.RoyaltyMonth,
							U.MetricType,
							U.PK_Country AS PK_Country,
							IIF((F.[QSVolume] = 0 AND U.RoyaltyMonth >= F.iSPQualDate) OR F.[QSVolume] IS NULL OR F.[QSVolume] = 1, SUM(ISNULL(U.Points,0)),0) AS [Points],  
							F.[QSVolume], 
							F.iSPQualDate,
							F.QualificationNumber,
							F.Part,
							F.iStartDate,
							F.iEndDate,
							F.Countries,
							ROW_NUMBER() OVER (PARTITION BY U.PK_Event,U.PK_Distributor,U.MetricType,U.PK_Country,F.QualificationNumber,F.Part,F.iStartDate ORDER BY U.RoyaltyMonth ASC) AS [MonthIndex]
					FROM #Event_DSPoints AS U WITH (NOLOCK) 
					INNER JOIN #DS AS d
						ON U.PK_Distributor = d.PK_Distributor AND U.PK_Event = d.PK_Event
					INNER JOIN #tmp_DSQualDef AS F
						ON u.PK_Distributor = F.PK_Distributor	
						WHERE 
							F.PK_Event = U.PK_Event
							AND
							F.MetricType = U.MetricType 
							AND 
							U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
							AND 
							(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
					GROUP BY U.PK_Event,U.PK_Distributor,U.RoyaltyMonth,U.MetricType,U.PK_Country,F.[QSVolume],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					
			SELECT @StepGroup = 5, @StepSubGroup = 8
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
 
			------------------------------------------------------------------------------------------------
			-- 5.9 WRK_26034_BonusPoints
			------------------------------------------------------------------------------------------------
		
			SELECT @StepGroup = 5, @StepSubGroup = 9, @Milestone = 'WRK_26034_BonusPoints';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
			
				DROP TABLE IF EXISTS #WRK_26034_BonusPoints

				--In case of multiple periods, the bonus should be assigned by period

				SELECT 
						U.PK_Event,
						U.PK_Distributor,
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
						IIF(U.QualificationNumber IN ( SELECT CAST([value] AS INT) AS [QId] FROM STRING_SPLIT(nsp.BonusAppliesTo,',')) 
								AND U.MetricType = @BonusMetric, ISNULL(nsp.[NewFQSBonus],0), 0) AS [NewFQSBonus], 
						IIF(U.QualificationNumber IN ( SELECT CAST([value] AS INT) AS [QId] FROM STRING_SPLIT(dbs.BonusAppliesTo,',')) 
								AND U.MetricType = @BonusMetric, ISNULL(dbs.[DoubleVolumeBonus],0), 0) AS [DoubleVolumeBonus]
					INTO #WRK_26034_BonusPoints
					FROM #Event_DSPoints_Summary AS U WITH (NOLOCK) 
						INNER JOIN v_Distributor AS d 
							ON u.PK_Distributor = d.nDistributorID
							LEFT JOIN [dbo].[WRK_26034_DoubleVolumeBonusSummary]   AS dbs 
								ON U.PK_Distributor = dbs.PK_Distributor AND U.PK_Event = dbs.PK_Event AND U.RoyaltyMonth = dbs.RoyaltyMonth AND U.MetricType = dbs.MetricType 
							LEFT JOIN [dbo].[WRK_26034_NewFQSBonusSummary]   AS nsp 
								ON U.PK_Distributor = nsp.PK_Distributor AND U.PK_Event = nsp.PK_Event AND U.RoyaltyMonth = nsp.RoyaltyMonth AND U.MetricType = nsp.MetricType 				
								
				CREATE INDEX IX_#WRK_26034_BonusPoints_PK_Distributor ON #WRK_26034_BonusPoints(PK_Distributor)
			
				IF @IsDevQA = 0
				BEGIN			
		
					DROP TABLE IF EXISTS [dbo].[WRK_26034_BonusPoints]

					SELECT 
							PK_Event,
							PK_Distributor,
							RoyaltyMonth,
							MetricType,
							PK_Country,
							[Points],
							[QSVolume], 
							iSPQualDate,
							QualificationNumber,
							Part,
							iStartDate,
							iEndDate,
							Countries, 
							[NewFQSBonus],
							[DoubleVolumeBonus]
						INTO [dbo].[WRK_26034_BonusPoints]
						FROM #WRK_26034_BonusPoints	

					CREATE INDEX IX_WRK_26034_BonusPoints_PK_Distributor ON [dbo].[WRK_26034_BonusPoints](PK_Distributor)

				END

			SELECT @StepGroup = 5, @StepSubGroup = 9
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
 
			------------------------------------------------------------------------------------------------
			-- 5.10 [tmp].[DSPointsSummary]
			------------------------------------------------------------------------------------------------
		
			SELECT @StepGroup = 5, @StepSubGroup = 10, @Milestone = '[tmp].[DSPointsSummary]';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
			
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
					[iSPQualDate] [int] NULL,
					[QualificationNumber] [int] NULL,
					[Part] [int] NULL,
					[HasBonus] [bit] NULL,
					[TotalPoints] [money] NULL,
					[iStartDate] [int] NULL,
					[iEndDate] [int] NULL,
					[Countries] [varchar](max) NULL
				)

				INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,QSVolume)
				SELECT 
					P.PK_Event AS PK_Event,
					P.PK_Distributor,
					P.RoyaltyMonth,
					P.MetricType,
					P.PK_Country,
					P.[Points],
					P.QualificationNumber,
					P.Part, 
					(ISNULL(P.[DoubleVolumeBonus],0) + ISNULL(P.[NewFQSBonus],0)) AS [Bonus],
					ISNULL(P.[Points],0) + (ISNULL(P.[DoubleVolumeBonus],0) + ISNULL(P.[NewFQSBonus],0)) AS [TotalPoints],
					P.iStartDate,
					P.iEndDate,
					P.QSVolume
				FROM #WRK_26034_BonusPoints AS P WITH (NOLOCK)
					 	
				IF @IsDevQA = 0
				BEGIN
			 
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t 
						INNER JOIN #LocationEventID AS l
							ON t.PK_Event = l.PK_Event

					INSERT INTO [tmp].[DSPointsSummary](PK_Event, PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,QSVolume)
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
							QSVolume
						FROM #tmp_DSPointsSummary

	 			END
		
			SELECT @StepGroup = 5, @StepSubGroup = 10
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
 
		END

		--Step 6: Qualifiers by volume	
		IF @Step >= 6
		BEGIN
			
			PRINT 'Executing step 6'

			------------------------------------------------------------------------------------------------
			-- 6.1 Getting qualifiers by volume according to qualification definitions
			------------------------------------------------------------------------------------------------

			SELECT @StepGroup = 6, @StepSubGroup = 1, @Milestone = 'Getting qualifiers by volume according to qualification definitions';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
	
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
		
				UPDATE #Executions
				SET Done = 1
				WHERE PK_Execution = @PK_Execution

				END
					 
				IF @IsDevQA = 0	
				BEGIN			 
					INSERT INTO #Event_DSQualPoints(PK_Event,PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						Q.PK_Event
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK)
						INNER JOIN #LocationEventID AS l
							ON Q.PK_Event = l.PK_Event
				END

			SELECT @StepGroup = 6, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
 
		END
	 
		--Step 7: Qualifications
		IF @Step >= 7
		BEGIN
			
			PRINT 'Executing step 7'

			SELECT @StepGroup = 7, @StepSubGroup = 1, @Milestone = 'Qualifications';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
		 
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

				SELECT QColumn = 'Q' +   IIF(QId < 10,  '0' + CAST(QId AS VARCHAR), CAST(QId  AS VARCHAR)), ListID, PK_Event 
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
						AND E.PK_Distributor = L.PK_Distributor_List WHERE E.PK_Event = ' + CAST(PK_Event AS NVARCHAR(MAX))  + ';'			
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
						AND E.PK_Distributor = L.PK_Distributor_List WHERE E.PK_Event = ' + CAST(PK_Event AS NVARCHAR(MAX))  + ';'						
				FROM #SKUsQualificationMapping AS M
				GROUP BY QColumn,PK_Event
			 	
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
			0 AS [ctrl]
			INTO #QualificationsMapping
			FROM #Event_SetupEventQualification
			WHERE QualificationNumber <= 50
			
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

				DROP TABLE IF EXISTS ##QualVolumeQualifiers

				SET @SqlStatement = ''

				SET @SqlStatement = N'SELECT Q1.PK_Event,Q1.PK_Distributor	
				INTO ##QualVolumeQualifiers
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
				INNER JOIN ##QualVolumeQualifiers AS QQ
				ON Q.PK_Event = QQ.PK_Event
				AND Q.PK_Distributor = QQ.PK_Distributor'

				EXECUTE sp_executesql @SqlStatement

				UPDATE #QualificationsMapping
				SET [ctrl] = 1
				WHERE ID = @ID

			END

			END

			SELECT @StepGroup = 7, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
			
		END

		--Step 8: Subevents
		IF @Step >= 8
		BEGIN

			PRINT 'Executing step 8'
			
			DECLARE 
				@PK_SubEvent INT,
				@PK_EventSubEvent INT,
				@SubEventNumber VARCHAR(10),
				@SubEventFormula VARCHAR(MAX)

			SELECT @StepGroup = 8, @StepSubGroup = 1, @Milestone = 'Subevent qualification on #EventQual';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
		  
			DROP TABLE IF EXISTS indi

			SELECT s.PK_Event
				,s.PK_SubEvent
				,s.SubEventNumber
				,CONCAT('E',(IIF(s.SubEventNumber<10, CONCAT('0',CAST(s.SubEventNumber AS VARCHAR(20))),CAST(s.SubEventNumber AS VARCHAR(20))))) AS SubEventNumberCode
				,s.SubEventFormula
				,ROW_NUMBER() OVER(ORDER BY s.PK_Event,s.SubEventNumber ASC) AS [Order]
				,CAST(0 AS BIT) AS ctrl
			INTO #SubEventsFormula
			FROM [SubEvent] AS s WITH (NOLOCK) 
				INNER JOIN #LocationEventID AS l
					ON s.PK_Event = l.PK_Event 
			WHERE SubEventFormula IS NOT NULL

			SET @SqlStatement = ''

			WHILE EXISTS (SELECT 1 FROM #SubEventsFormula AS se WHERE ctrl = 0)
			BEGIN
	
				SELECT TOP 1 @PK_SubEvent = PK_SubEvent FROM #SubEventsFormula WHERE ctrl = 0 ORDER BY [Order] ASC
		
				SELECT 
					@PK_EventSubEvent = PK_Event,
					@SubEventNumber = SubEventNumberCode,
					@SubEventFormula = SubEventFormula
				FROM #SubEventsFormula WHERE PK_SubEvent = @PK_SubEvent

				SET @SqlStatement = 'UPDATE #EventQual SET' + SPACE(1) + @SubEventNumber + ' = ('  +  @SubEventFormula  + ') WHERE PK_Event = ' + CAST(@PK_EventSubEvent AS VARCHAR(MAX))

				PRINT @SqlStatement
				EXEC (@SqlStatement)

				UPDATE #SubEventsFormula
				SET ctrl = 1
				WHERE PK_SubEvent = @PK_SubEvent
		
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

			SELECT @StepGroup = 8, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
			 
		END
 
		--Step 10: [Event].[DSQual]	
		IF @Step >= 10
		BEGIN
			
			PRINT 'Executing step 10'

			SELECT @StepGroup = 10, @StepSubGroup = 1, @Milestone = '[Event].[DSQual] and [tmp].[DSQual]';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
		 
			IF @IsDevQA = 0
			BEGIN

				DELETE dq			
				FROM [Event].[DSQual] AS dq
					INNER JOIN #LocationEventID AS l
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

				DROP TABLE IF EXISTS [tmp].[DSQual]  

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
				INTO [tmp].[DSQual]
				FROM #EventQual 

				CREATE INDEX IX_tmp_DSQual_PK_Event ON [tmp].[DSQual](PK_Event);

			END
	
			SELECT @StepGroup = 10, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
			
		END
		 
		--Step 11: SubEventQualifiers
		IF @Step >= 11 
		BEGIN
					
			PRINT 'Executing step 11'

			SELECT @StepGroup = 11, @StepSubGroup = 1, @Milestone = 'usp_EventPromo_UpdateSubEventQualifier';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
		  
			IF @IsDevQA = 0
			BEGIN
					
				EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
				@Events = @PK_EventMultiLocation,
				@Source = 2,
				@EvaluateFormula = 0

			END

			SELECT @StepGroup = 11, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
				
		END
 
	END

/******************************************************************************
				END PROCEDURE
******************************************************************************/
		
		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
		 	@StoredProcedureName = @StoredProcedure
		 	,@StartTime = @StartTime;
 		
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
 

 