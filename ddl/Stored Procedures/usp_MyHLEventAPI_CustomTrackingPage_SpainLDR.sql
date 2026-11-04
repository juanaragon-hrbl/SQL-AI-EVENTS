CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_SpainLDR]  
 -- Mandatory parameters    
  @PK_Event INT = 65416    
 ,@LocaleCode CHAR(5)  = 'en-GB'
 -- Optional Parameters  
 ,@DistributorID VARCHAR(10) = '2222222222'  

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS  
BEGIN  
/******************************************************************************
OBJECT:			dbo.[usp_MyHLEventAPI_CustomTrackingPage_SpainLDR]

USE:		
		DECLARE @e int, @em varchar(4000)   
        
        EXEC dbo.[usp_MyHLEventAPI_CustomTrackingPage_SpainLDR]
			@PK_Event = 65416
			,@LocaleCode = 'en-GB'
			,@DistributorID = N'2222222222'
			,@Error = @e OUTPUT				-- @e must be defined in the local call   
			,@ErrorMessage = @em OUTPUT		-- @em must be defined in the local call   
			,@IsDevQA = 1  

		Print @em  

DESCRIPTION:	

NOTES:			

DEPENDENCIES

VERSIONS
----------------------------------------------------------------------------------
	1.0.0	2019-08-14		NoeG		Refactor code (SRE)
	1.1.0	2019-10-16      puertac		SRE Implementation 
	1.2.0	2019-10-31		puertac		SRE Implementation - Hardcode Review

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime DATETIME2 = GETUTCDATE()
			,@StartDate DATETIME = '2018-01-01'
			,@EndDate DATETIME = '2018-12-01'
			,@Month1 DATETIME = '2018-06-01'
			,@Month2 DATETIME = '2018-07-01'
			,@StatusCode VARCHAR (20) = 'COMPLETE'
			,@TVPs MONEY = 18000
			,@ROs MONEY = 120
			,@BaselineRO MONEY = 10000
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE @PK_Distributor INT, @TVAchieved MONEY = 0.00, @ROAchieved MONEY = 0.0
		, @BaselineROAchieved MONEY = 0.0
		, @IncreasedRO money = 0.00
		, @Level1ROAchieved MONEY = 0.00
		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WITH (NOLOCK) where sDistributorID = @DistributorID

		SELECT @TVAchieved = SUM(F.mVolumePoints), 
		@ROAchieved = SUM(F.mRoyaltyOverrides+F.mMainRoyaltyOverrides)
		FROM
		 dbo.v_aggFQS_ID F WITH (NOLOCK)
		where 
		 F.nDistributorID = @PK_Distributor
		and dRoyaltyMonth  BETWEEN @Month2 AND @EndDate

		SELECT 
		@BaselineROAchieved = SUM(F.mRoyaltyOverrides+F.mMainRoyaltyOverrides)
		FROM
		 dbo.v_aggFQS_ID F WITH (NOLOCK)
		where 
		 F.nDistributorID = @PK_Distributor
		and dRoyaltyMonth  BETWEEN @StartDate AND @Month1

		SET @BaselineROAchieved = ISNULL((CASE WHEN @BaselineROAchieved <= @BaselineRO THEN @BaselineRO ELSE @BaselineROAchieved END),0)
		SET @IncreasedRO = ((@BaselineROAchieved * 0.12) + @BaselineROAchieved)


		SELECT @Level1ROAchieved = SUM(AGG.mRoyaltyOverrides + AGG.mMainRoyaltyOverrides)
		FROM PubEvents.[dbo].[dimDSLngDownline_wBlock] A WITH (NOLOCK)
		INNER JOIN dbo.v_Distributor B  
		 ON A.PK_DSDownline = B.nDistributorID  
		 AND B.dSupervisorQualification >= @StartDate 
		 AND B.StatusCode = @StatusCode     
		INNER JOIN dbo.v_aggFQS_ID AGG  
		 ON B.nDistributorID = AGG.nDistributorID  
		 AND AGG.dRoyaltyMonth BETWEEN @Month2 AND @EndDate
		where A.PK_Distributor = @PK_Distributor and A.SPLevelFromUL = 2
		GROUP BY A.PK_Distributor 

		--Volume Points Table
		SELECT 
		 @TVPs 'TargetTVP'
		 ,ISNULL(@TVAchieved,0.00) 'TVPAchieved'
		 ,CASE WHEN (@TVPs - ISNULL(@TVAchieved,0.00) ) < 0 THEN 0 ELSE (@TVPs - ISNULL(@TVAchieved,0.00) ) END 'RemainingTVP'

		 --RO Points Table 1st Level
		SELECT 
		  @ROs 'TargetLevel1RO'
		 ,ISNULL(@Level1ROAchieved, 0) 'Level1ROAchieved'
		 ,(CASE WHEN (@ROs - ISNULL(@Level1ROAchieved, 0)) < 0 THEN 0 ELSE (@ROs - ISNULL(@Level1ROAchieved, 0)) END) 'RemainingLevel1RO'

		 --RO Points Table
		SELECT 
		  @BaselineROAchieved 'BaselineRO'
		 ,ISNULL(@IncreasedRO,0) 'IncreasedRO'
		 ,ISNULL(@ROAchieved,0) 'ROAchieved'
		 ,(CASE WHEN (ISNULL(@IncreasedRO,0) - ISNULL(@ROAchieved,0)) < 0 THEN 0 ELSE (ISNULL(@IncreasedRO,0) - ISNULL(@ROAchieved,0)) END) 'RemainingRO'

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

