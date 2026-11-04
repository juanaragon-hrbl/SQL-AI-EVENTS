CREATE PROCEDURE [dbo].[usp_Save_EventActivityLocale]
        -- Mandatory Parameters
		 @PK_EventActivity			INT
		,@ActivityName				nVARCHAR(200)	
		,@LocaleCode				VARCHAR(5)				
		,@ModifiedBy				nVARCHAR(50)
		-- Optional Parameters
		,@ActivityDesc				nVARCHAR(MAX)	= NULL
		,@Location					nVARCHAR(200)   = NULL
		,@Address1					nVARCHAR(100)	= NULL
		,@Address2					nVARCHAR(100)	= NULL
		,@City						nVARCHAR(100)	= NULL
		,@StateProvince				nVARCHAR(100)	= NULL
		,@PostalCode				nVARCHAR(25)	= NULL		
		-- Error Parameters
	   ,@IsDevQA		BIT = 0  
	   ,@Error	int = 0 OUTPUT
	   ,@ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_Save_EventActivityLocale

USE:	        Declare @e int, @em varchar(200)
                EXEC dbo.usp_Save_EventActivityLocale
					 	 @PK_EventActivity	= 5		
                        ,@ActivityName	= '06/25 Activity'
						,@ModifiedBy ='SandhyaP'
						-- Optional Parameters
						,@ActivityDesc		= 'You are so cool'
						,@Location			= 'Nokia Theatre'
						,@Address1			= '500 Figueroa'
						,@Address2			= NULL
						,@City				= 'Los Angeles'
						,@StateProvince		= 'CA'
						,@PostalCode		= '90001'		
						,@ErrorNumber = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
				Print @em

DESCRIPTION:	Save translations for Activity
TABLES:			dbo.EventActivityLocale
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2015-08-03			SandhyaP				Intitial
******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @CurrentUTC DATETIME = GETUTCDATE()
DECLARE @PK_Locale INT
Declare @Msg Varchar(256)

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode

/* UPDATE IF EXISTS ELSE INSERT */

BEGIN TRY
BEGIN TRANSACTION

	/* CHECK IF THE EVENT ACTIVITY EXISTS  */

IF @PK_EventActivity IS NOT NULL
BEGIN
	If Not Exists (Select 1 From dbo.EventActivity WITH (NoLock) Where PK_EventActivity = @PK_EventActivity /*And DeletedUTC Is Null */)
	Begin
		If @@TRANCOUNT > 0 Rollback
		Raiserror(50108,16,1,@PK_EventActivity)
	End
END


	;WITH ActivityTarget AS
	(
	  SELECT   PK_EventActivityLocale
			  ,PK_EventActivity
			  ,PK_Locale
			  ,ActivityName
			  ,ActivityDesc
			  ,Location
			  ,Address1
			  ,Address2
			  ,City
			  ,StateProvince
			  ,PostalCode
			  ,CreatedUTC
			  ,CreatedBy
			  ,ModifiedUTC
			  ,ModifiedBy
	  FROM dbo.EventActivityLocale WITH (NOLOCK)
	  WHERE PK_EventActivity = @PK_EventActivity
			AND
			PK_Locale = @PK_Locale	
	)
	, ActivitySource AS
	(
	SELECT @PK_EventActivity PK_EventActivity
		  ,@PK_Locale PK_Locale
		  ,@ActivityName ActivityName
		  ,@ActivityDesc ActivityDesc
		  ,@Location Location
		  ,@Address1 Address1
		  ,@Address2 Address2
		  ,@City City
		  ,@StateProvince StateProvince
		  ,@PostalCode PostalCode
		  ,@CurrentUTC CurrentUTC
		  ,@ModifiedBy ModifiedBy
	)

	MERGE ActivityTarget As T
		USING ActivitySource As S
			ON (T.PK_EventActivity = S.PK_EventActivity AND T.PK_Locale = S.PK_Locale)
		WHEN Matched THEN UPDATE
			SET  
				 ActivityName			= COALESCE(S.ActivityName, T.ActivityName)
				,ActivityDesc			= COALESCE(S.ActivityDesc, T.ActivityDesc)
				,Location				= COALESCE(S.Location, T.Location)
				,Address1				= COALESCE(S.Address1, T.Address1)
				,Address2				= COALESCE(S.Address2, T.Address2)
				,City					= COALESCE(S.City, T.City)
				,StateProvince			= COALESCE(S.StateProvince, T.StateProvince)
				,PostalCode				= COALESCE(S.PostalCode, T.PostalCode)
				,ModifiedUTC			= S.CurrentUTC
				,ModifiedBy				= S.ModifiedBy
		WHEN NOT MATCHED THEN INSERT
				(PK_EventActivity
			   ,PK_Locale
			   ,ActivityName
			   ,ActivityDesc
			   ,Location
			   ,Address1
			   ,Address2
			   ,City
			   ,StateProvince
			   ,PostalCode
			   ,CreatedUTC
			   ,CreatedBy
			   ,ModifiedUTC
			   ,ModifiedBy)
		 VALUES (
			    S.PK_EventActivity
			   ,S.PK_Locale
			   ,S.ActivityName
			   ,S.ActivityDesc
			   ,S.Location
			   ,S.Address1
			   ,S.Address2
			   ,S.City
			   ,S.StateProvince
			   ,S.PostalCode
			   ,S.CurrentUTC
			   ,S.ModifiedBy
			   ,S.CurrentUTC
			   ,S.ModifiedBy
			   );


COMMIT TRANSACTION

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
	END PROCEDURE
******************************************************************************/
END;