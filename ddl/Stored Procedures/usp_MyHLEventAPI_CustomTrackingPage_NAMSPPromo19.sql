CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMSPPromo19]  
	-- Mandatory parameters  
	@PK_Event INT = 23600  
	,@LocaleCode CHAR(5)  = 'en-us'  
	-- Optional Parameters  
	,@DistributorID VARCHAR(10) = '2222222222'  
	,@EnableDownline BIT = 0  
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS  
BEGIN   
/******************************************************************************  
OBJECT:   dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMSPPromo19  
  
USE:		USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC	[dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMSPPromo19]
					@PK_Event = 23600,
					@LocaleCode = N'en-US',
					@DistributorID = N'16013444',
					@EnableDownline = 1,
					@Error = @Error OUTPUT,
					@ErrorMessage = @ErrorMessage OUTPUT,
					@IsDevQA = 1

			SELECT	@Error as N'@Error',
					@ErrorMessage as N'@ErrorMessage'
			GO
  
DESCRIPTION: This is a custom stored procedure that retreievs all the details for the   
                NAM SP Promo 2019 based on the sections defined for the Tracking Page.  
                The sections are specific to every event based on what the region decides  
                to display on the tracking page  
  
NOTES:     
  
DEPENDENCIES  
----------------------------------------------------------------------------------  
dbo.Event, dbo.Subevent, dbo.EventLocaleADesc, dbo.SubeventLocaleDesc,   
dbo.v_aggFQS_ID,   
LS_SQL_BI_DB02.EventManagement.dbo.AWT,  
dbo.EventTrackingPageSection,  
dbo.EventEventTrackingPageSection  
  
VERSIONS  
----------------------------------------------------------------------------------  
1		2018-12-18		SushmaA Intitial  
1.1		2019-05-21		Including standard error handling
1.2		2019-07-15		Setting error parameters as optionals
1.3		2019-08-14		NoeG		Refactor code (SRE)
******************************************************************************/  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		BEGIN TRANSACTION  
		/* DECLARE THE REQUIRED VARIABLES */  
		DECLARE @PK_Distributor INT  
		DECLARE @PK_Locale INT  
		DECLARE @PK_DefaultLocale INT  
		DECLARE @COP CHAR (2) = NULL  
		DECLARE @MonthName VARCHAR(10)  
		DECLARE @sql1 NVARCHAR(MAX) = ''  
		DECLARE @Column1 VARCHAR(10) = ''  
		DECLARE @Column2 VARCHAR(10) = ''  
  
		/* SET THE VALUES FOR THE DECLARED VARIABLES */  
  
		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor With (NoLock) WHERE sDistributorID = @DistributorID  
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales With (NoLock) WHERE LocaleCode = @LocaleCode  
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event With (NoLock) WHERE PK_Event = @PK_Event  
  
		IF OBJECT_ID('tempdb..#MBDetails') IS NOT NULL DROP TABLE #MBDetails  
  
		IF OBJECT_ID('tempdb..#DL') IS NOT NULL DROP TABLE #DL  
  
		CREATE TABLE #MBDetails  
		(  
		  PK int IDENTITY(1,1) PRIMARY KEY  
		 ,PK_Distributor INT  
		 ,DistributorID VARCHAR(30)   
		 ,PK_Sponsor INT  
		 ,SponsorID VARCHAR(30)   
		 ,SponsorName VARCHAR(150)  
		 ,PK_Downline INT  
		 ,DownlineID VARCHAR(30)   
		 ,FirstName VARCHAR(150)  
		 ,LastName VARCHAR(150)  
		 ,AppDate DATETIME  
		 ,ContractAcceptanceDate INT  
		 ,QSQualDate INT  
		 ,SPQualDate INT  
		 ,Email VARCHAR(150)  
		 ,Phone VARCHAR(200)  
		 ,Team VARCHAR(50)  
		 ,COP VARCHAR(5)  
		 ,DSLevel INT  
		 ,JanVolume2019 MONEY DEFAULT 0  
		 ,FebVolume2019 MONEY DEFAULT 0  
		 ,MarVolume2019 MONEY DEFAULT 0  
		 ,AprVolume2019 MONEY DEFAULT 0  
		 ,MayVolume2019 MONEY DEFAULT 0  
		 ,JunVolume2019 MONEY DEFAULT 0  
		 ,JulVolume2019 MONEY DEFAULT 0  
		 ,AugVolume2019 MONEY DEFAULT 0  
		 ,SepVolume2019 MONEY DEFAULT 0  
		 ,OctVolume2019 MONEY DEFAULT 0  
		 ,NovVolume2019 MONEY DEFAULT 0  
		 ,DecVolume2019 MONEY DEFAULT 0  
		 ,JanVolume2020 MONEY DEFAULT 0  
		 ,FebVolume2020 MONEY DEFAULT 0  
		 ,QualifiedPeriod INT DEFAULT 0  
		 ,IsNotNewMBPromo INT   
		 ,IsE1Qualifier INT DEFAULT 0
		 ,Cut INT DEFAULT 0  
		)  
  
		CREATE NONCLUSTERED INDEX IX_PK_Distributor  
		ON #MBDetails (PK_Distributor) INCLUDE (ContractAcceptanceDate)  
  
			SELECT   
		  PK_DSDownline,  
		  DSLevelFromUL  
		 INTO #DL  
		 FROM   
		  PubEvents.dbo.dimDSLngDownline_wBlock DL With (NoLock)
		 WHERE    
		  PK_distributor = @PK_Distributor  
		  AND  
		  DSLevelFromUL <= 4  
   
		--SELECT <all> FROM #MBDetails  
  
		INSERT #MBDetails  
		(  
		  PK_Distributor   
		 ,DistributorID  
		 ,PK_Sponsor  
		 ,SponsorID  
		 --,SponsorName  
		 ,PK_Downline  
		 ,FirstName  
		 ,LastName  
		 --,AppDate  
		 ,ContractAcceptanceDate  
		 ,QSQualDate  
		 ,SPQualDate  
		 --,Email  
		 --,Phone  
		 --,Team  
		 ,COP  
		 ,DSLevel
		)  
		SELECT --DISTINCT  
		  PK_Distributor   
		 ,DistributorID  
		 ,PK_Sponsor  
		 ,SponsorID  
		 --,SponsorName  
		 ,#DL.PK_DSDownline  
		 ,FirstName  
		 ,LastName  
		 --,AppDate  
		 ,ContractAcceptanceDate  
		 ,QSQualDate  
		 ,SPQualDate  
		 --,Email  
		 --,Phone  
		 --,SubTypeCode  
		 ,CountryCode_COP  
		 ,DSLevelFromUL AS DSLevel   
		FROM   
		 PubEvents.[dbo].[dimDistributor] N WITH(NOLOCK)   
		INNER JOIN  
		 #DL  
		ON   
		 #DL.PK_DSDownline = N.PK_Distributor  
  
		UPDATE MB  
		SET DownlineID = D.sDistributorID, SponsorName = ISNULL(D.sFirstName,'') + ' ' + ISNULL(D.sLastName, '')
		FROM #MBDetails MB  
		JOIN dbo.v_Distributor D ON MB.PK_Downline = D.nDistributorID 

		UPDATE MB
		SET Team = d.sTeam, Email = D.sEmail, Phone = D.Phone, AppDate = D.dApplication
		FROM #MBDetails MB
		JOIN dbo.v_Distributor D ON MB.PK_Distributor = D.nDistributorID 
  
		UPDATE MB  
		SET JanVolume2019 = Vol.JanVolume2019  
		 ,FebVolume2019 = Vol.FebVolume2019  
		 ,MarVolume2019 = Vol.MarVolume2019  
		 ,AprVolume2019 = Vol.AprVolume2019  
		 ,MayVolume2019 = Vol.MayVolume2019  
		 ,JunVolume2019 = Vol.JunVolume2019  
		 ,JulVolume2019 = Vol.JulVolume2019  
		 ,AugVolume2019 = Vol.AugVolume2019  
		 ,SepVolume2019 = Vol.SepVolume2019  
		 ,OctVolume2019 = Vol.OctVolume2019  
		 ,NovVolume2019 = Vol.NovVolume2019  
		 ,DecVolume2019 = Vol.DecVolume2019  
		 ,JanVolume2020 = Vol.JanVolume2020  
		 ,FebVolume2020 = Vol.FebVolume2020 
		 ,IsE1Qualifier = Vol.IsE1Qualifier 
		 ,QualifiedPeriod = Vol.QualifiedPeriod
		 ,Cut = Vol.Cut
		FROM  
		#MBDetails MB  
		JOIN  
		WRK_NAMSPPromo2019  Vol WITH (NOLOCK)
		ON MB.PK_Distributor = Vol.PK_Distributor  


  
		IF @EnableDownline = 0  
		BEGIN  
   
    
		   SELECT --DISTINCT  
		   JanVolume2019  
		  ,FebVolume2019  
		  ,MarVolume2019  
		  ,AprVolume2019  
		  ,MayVolume2019  
		  ,JunVolume2019  
		  ,JulVolume2019  
		  ,AugVolume2019  
		  ,SepVolume2019  
		  ,OctVolume2019  
		  ,NovVolume2019  
		  ,DecVolume2019  
		  ,JanVolume2020  
		  ,FebVolume2020   
		  ,QualifiedPeriod 
		  ,AppDate    
		  ,CONVERT(datetime, convert(varchar(10), SPQualDate)) [SPQualDate]
		  ,IsE1Qualifier   
		 FROM   
		  #MBDetails  MB
		 WHERE   
		  PK_Distributor = @PK_Distributor  
		  AND  
		  DSLevel = 1 
  
  
			SELECT   
		   DSLevel - 1 AS DSLevel   
		  ,DownlineID AS DSID  
		  ,LastName  
		  ,FirstName   
		  ,Team  
		  ,SponsorName  
		  ,Email    
		  ,Phone   
		  ,AppDate  
		  ,CONVERT(datetime, convert(varchar(10), SPQualDate)) [SPQualDate]  
		  ,QualifiedPeriod   
		  ,JanVolume2019  
		  ,FebVolume2019  
		  ,MarVolume2019  
		  ,AprVolume2019  
		  ,MayVolume2019  
		  ,JunVolume2019  
		  ,JulVolume2019  
		  ,AugVolume2019  
		  ,SepVolume2019  
		  ,OctVolume2019  
		  ,NovVolume2019  
		  ,DecVolume2019  
		  ,JanVolume2020  
		  ,FebVolume2020   
		 FROM   
		  #MBDetails N  
		 WHERE    
		  --SPQualDate >= '2019-01-01'  
		  SPQualDate >= '20190101'  
		  AND  
		  N.PK_Distributor != @PK_Distributor 
		  AND
		  N.Cut > 0   
		 ORDER BY  
		  N.DSLevel,N.FirstName,N.LastName  
  
		END  
		ELSE  
		BEGIN  
			/**********************************************  
		  SELECT DATA TO FIRST GRID  
		 **********************************************/  
  
		 SELECT --DISTINCT  
		   JanVolume2019  
		  ,FebVolume2019  
		  ,MarVolume2019  
		  ,AprVolume2019  
		  ,MayVolume2019  
		  ,JunVolume2019  
		  ,JulVolume2019  
		  ,AugVolume2019  
		  ,SepVolume2019  
		  ,OctVolume2019  
		  ,NovVolume2019  
		  ,DecVolume2019  
		  ,JanVolume2020  
		  ,FebVolume2020   
		  ,QualifiedPeriod   
		  ,AppDate  
		  ,CONVERT(datetime, convert(varchar(10), SPQualDate)) [SPQualDate]
		  ,IsE1Qualifier   
		 FROM   
		  #MBDetails  
		 WHERE   
		  PK_Distributor = @PK_Distributor  
  
		END  
  
		/* ROLLBACK TRANSACTION IF ERROR OCCURED ANYWHERE */  
		IF @Error > 0  
		BEGIN  
		 ROLLBACK TRANSACTION  
		 PRINT 'Error Occured. No Record set was retrieved.'  
		END  
		ELSE  
		BEGIN  
		 COMMIT TRANSACTION  
		 PRINT 'All Records Selected Successfully'  
		END  
  
		-- Update processing Log
			EXEC [dbo].[usp_Utility_UpdateProcessingLog]
					@StoredProcedureName = @StoredProcedure
					,@StartTime = @StartTime;

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

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

/* END THE PROCEDURE */  
END;
GO
