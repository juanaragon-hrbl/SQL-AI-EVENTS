CREATE PROCEDURE [dbo].[usp_EventsAT_Validate_Distributor]
 -- MANDATORY  
 @LoggedUser nVARCHAR(20)  
 ,@DSID nVARCHAR(20)    /* pass DistributorID for search */  
 ,@Locale varchar(10)   
   
-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0
AS  
BEGIN  
  
  
/*  
OBJECT:  dbo.usp_EventsAT_Validate_Distributor  
  
USE:  
			DECLARE @e int, @em varchar(4000)
   EXEC usp_EventsAT_Validate_Distributor  
     @LoggedUser = 'Snigdhap'  
     ,@DSID  = '1111111111'  
     ,@Locale = 'en-us'  
     ,@Error = @e OUTPUT  -- @e must be defined in the local call   
     ,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
    ,@IsDevQA = 1

SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION: Validations: given DSID is valid or not, whether the DSID belongs to the region of loggedinuser and the distributor belongs to the market   
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------  
1	2012-10-07		OrlandoL		Initial  
2	2019-08-08		NoeG			Refactor code (SRE)
*/  
  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON  
  
/******************************************************************************  
 variable declaration  
******************************************************************************/  
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_Locale int  
  
SELECT @Error = 0, @ErrorMessage = '';
  
SELECT @PK_Locale = PK_Locale from dbo.Locales WITH(nolock) where LocaleCode = @Locale  
  
  
BEGIN TRY
		IF NOT EXISTS(SELECT TOP 1 nDistributorID FROM dbo.v_Distributor WITH(NOLOCK)  
		   WHERE sDistributorID = @DSID)  
		BEGIN  
			 SET @Error = 8  
			 -- Update ErrorLog  
			 EXEC dbo.usp_Utility_UpdateErrorLog   
			  @ProcedureName = @StoredProcedure   
			  ,@ErrorNumber = @Error  
			  ,@ErrorMessage = @ErrorMessage OUTPUT  
			 RETURN   
		END 

		IF EXISTS(SELECT TOP 1 nDistributorID FROM dbo.v_Distributor WITH(NOLOCK)
		   WHERE sDistributorID = @DSID and sType IN ('MB', 'NM'))  
		BEGIN  
			 SET @Error = 418  
			 -- Update ErrorLog  
			 EXEC dbo.usp_Utility_UpdateErrorLog   
			  @ProcedureName = @StoredProcedure   
			  ,@ErrorNumber = @Error  
			  ,@ErrorMessage = @ErrorMessage OUTPUT  
			 RETURN   
		END   
  
  
  
		/******************************************************************************  
		Be sure the DS belongs at least one of the Logged-user Markets   
		******************************************************************************/  
		--IF (SELECT PK_EventATAccessUserType FROM EventATAccessUser (NOLOCK) WHERE EventATAccessUserName = @LoggedUser) <> 1  
		--IF NOT EXISTS(SELECT TOP 1 nDistributorID FROM dbo.v_Distributor(NOLOCK)  
		--   WHERE sDistributorID = @DSID AND sDistributorCountryProcessingCode IN   
		--   (SELECT SUBSTRING(LocaleCode,4,2) FROM dbo.Locales WHERE PK_Locale = @PK_Locale AND PK_Locale IN   
		--   (SELECT PK_Locale FROM dbo.EventATAccessUserModules UM (NOLOCK) INNER JOIN EventATAccessUser AU (NOLOCK) ON UM.PK_EventATAccessUser = AU.PK_EventATAccessUser WHERE AU.EventATAccessUserName = @LoggedUser   
		--)))  
		--BEGIN  
		-- SET @Error = 297  
		-- -- Update ErrorLog  
		-- EXEC dbo.usp_Utility_UpdateErrorLog   
		--  @ProcedureName = @StoredProcedure   
		--  ,@ErrorNumber = @Error  
		--  ,@ErrorMessage = @ErrorMessage OUTPUT  
		-- RETURN   
		--END  
  
		 SELECT @DSID DistributorID  
  
  
		--IF NOT EXISTS(SELECT TOP 1 nDistributorID FROM dbo.v_Distributor(NOLOCK)  
		--   WHERE sDistributorID = @DSID AND sDistributorCountryProcessingCode IN   
		--   (SELECT SUBSTRING(LocaleCode,4,2) FROM dbo.Locales WHERE PK_Locale = @PK_Locale))  
		--BEGIN  
		-- SET @Error = 297  
		-- -- Update ErrorLog  
		-- EXEC dbo.usp_Utility_UpdateErrorLog   
		--  @ProcedureName = @StoredProcedure   
		--  ,@ErrorNumber = @Error  
		--  ,@ErrorMessage = @ErrorMessage OUTPUT  
		-- RETURN   
		--END  

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
END CATCH; 
   
  
  
/******************************************************************************  
 END Procedure  
******************************************************************************/  
END

