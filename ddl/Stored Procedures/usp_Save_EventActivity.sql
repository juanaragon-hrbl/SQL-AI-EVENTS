CREATE PROCEDURE [dbo].[usp_Save_EventActivity]
        -- Mandatory Parameters
		@PK_Event					INT
		,@ActivityName				nVARCHAR(200)	
		,@ModifiedBy				nVARCHAR(50)
		-- Optional Parameters
		,@PK_EventActivity			INT				= NULL
		,@ActivitySequence			INT				= NULL
		,@MaxQty					INT				= NULL
		,@ActivityDesc				nVARCHAR(4000)	= NULL
		,@Location					nVARCHAR(200)   = NULL
		,@Address1					nVARCHAR(100)	= NULL
		,@Address2					nVARCHAR(100)	= NULL
		,@City						nVARCHAR(100)	= NULL
		,@StateProvince				nVARCHAR(100)	= NULL
		,@PostalCode				nVARCHAR(25)	= NULL
		,@PK_Country				INT				= NULL
		,@StartUTC					DATETIME		= NULL
		,@EndUTC					DATETIME		= NULL
		,@RegStartUTC				DATETIME		= NULL
		,@RegEndUTC					DATETIME		= NULL
		,@UnitPrice					DECIMAL			= NULL
		,@CurrencyType				VARCHAR(3)		= NULL
		,@CompQtyPerDS				INT				= 2
		,@MaxQtyPerDS				INT				= 4
		,@ReserveTimeOut			INT				= 1800
		,@PaymentTimeOut			INT				= 1800		
		-- Error Parameters
       ,@IsDevQA		BIT = 0  
	   ,@Error	int = 0 OUTPUT
	   ,@ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_Save_EventActivity

USE:	        Declare @e int, @em varchar(200)
                EXEC dbo.usp_Save_EventActivity
					 	 @PK_Event = 1
                        ,@ActivityName	= '06/25 Activity'
						,@ModifiedBy ='SandhyaP'
						-- Optional Parameters
						,@PK_EventActivity	= 5
						,@MaxQty			= NULL
						,@ActivityDesc		= 'You are so cool'
						,@Location			= 'Nokia Theatre'
						,@Address1			= '500 Figueroa'
						,@Address2			= NULL
						,@City				= 'Los Angeles'
						,@StateProvince		= 'CA'
						,@PostalCode		= '90001'
						,@PK_Country		= 10
						,@StartUTC			= '2015-06-26'
						,@EndUTC			= '2015-06-29'
						,@RegStartUTC		= '2015-07-01'
						,@RegEndUTC			= '2015-07-03'
						,@UnitPrice			= 150
						,@CompQtyPerDS		= 2
						,@MaxQtyPerDS		= 4
						,@ReserveTimeOut	= 900
						,@PaymentTimeOut	= 900		
						,@ErrorNumber = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
				Print @em

DESCRIPTION:	Return Activities for an Event
TABLES:			dbo.Event, dbo.EventActivity
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2015-06-19			SandhyaP				Intitial
2	2019-10-16			 JonathanO				Refactor code (SRE)
******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @StoredProcedure VARCHAR(100) = 'usp_Save_EventActivity'
DECLARE @MaxVar INT = 0
DECLARE @CurrentUTC DATETIME = GETUTCDATE()
Declare @Msg Varchar(256)
DECLARE @StartTime datetime2 = GETUTCDATE();

/* UPDATE IF EXISTS ELSE INSERT */

BEGIN TRY
BEGIN TRANSACTION

	/* CHECK IF THE EVENT ACTIVITY EXISTS  */

IF @PK_EventActivity IS NOT NULL
BEGIN
	If Not Exists (Select 1 From dbo.EventActivity WITH (NoLock) Where PK_EventActivity = @PK_EventActivity And DeletedUTC Is Null)
	Begin
		If @@TRANCOUNT > 0 Rollback
		Raiserror(50108,16,1,@PK_EventActivity)
	End
END

	;WITH ActivityTarget AS
	(
	  SELECT PK_EventActivity
			  ,PK_Event
			  ,ActivityName
			  ,ActivityDesc
			  ,ActivitySequence
			  ,Location
			  ,Address1
			  ,Address2
			  ,City
			  ,StateProvince
			  ,PostalCode
			  ,PK_Country
			  ,StartUTC
			  ,EndUTC
			  ,RegistrationStartUTC
			  ,RegistrationEndUTC
			  ,UnitPrice
			  ,CurrencyType
			  ,CompQtyPerDS
			  ,MaxQtyPerDS
			  ,MaxQty
			  ,SoldQty
			  ,ProcessingQty
			  ,AvailableQty
			  ,ReserveTimeOut
			  ,PaymentTimeOut
			  ,DeletedUTC
			  ,CreatedUTC
			  ,CreatedBy
			  ,ModifiedUTC
			  ,ModifiedBy
	  FROM dbo.EventActivity WITH (NOLOCK)
	  WHERE PK_Event = @PK_Event	
	)
	, ActivitySource AS
	(
	SELECT @PK_EventActivity PK_EventActivity
		  ,@PK_Event PK_Event
		  ,@ActivityName ActivityName
		  ,@ActivityDesc ActivityDesc
		  ,@ActivitySequence ActivitySequence
		  ,@Location Location
		  ,@Address1 Address1
		  ,@Address2 Address2
		  ,@City City
		  ,@StateProvince StateProvince
		  ,@PostalCode PostalCode
		  ,@PK_Country PK_Country
		  ,@StartUTC StartUTC
		  ,@EndUTC EndUTC
		  ,@RegStartUTC RegStartUTC
		  ,@RegEndUTC RegEndUTC
		  ,@UnitPrice UnitPrice
		  ,@CurrencyType CurrencyType
		  ,@CompQtyPerDS CompQtyPerDS
		  ,@MaxQtyPerDS MaxQtyPerDS
		  ,@MaxQty MaxQty
		  ,@ReserveTimeOut ReserveTimeOut
		  ,@PaymentTimeOut PaymentTimeOut
		  ,@CurrentUTC CurrentUTC
		  ,@ModifiedBy ModifiedBy
	)

	MERGE ActivityTarget As T
		USING ActivitySource As S
			ON (T.PK_EventActivity = S.PK_EventActivity OR T.ActivityName = S.ActivityName)
			And T.PK_Event = S.PK_Event
		WHEN Matched THEN UPDATE
			SET ActivityName			= S.ActivityName
				,ActivityDesc			= COALESCE(S.ActivityDesc, T.ActivityDesc)
				,ActivitySequence		= COALESCE(S.ActivitySequence, T.ActivitySequence)
				,Location				= COALESCE(S.Location, T.Location)
				,Address1				= COALESCE(S.Address1, T.Address1)
				,Address2				= COALESCE(S.Address2, T.Address2)
				,City					= COALESCE(S.City, T.City)
				,StateProvince			= COALESCE(S.StateProvince, T.StateProvince)
				,PostalCode				= COALESCE(S.PostalCode, T.PostalCode)
				,PK_Country				= COALESCE(S.PK_Country, T.PK_Country)
				,StartUTC				= COALESCE(S.StartUTC, T.StartUTC)
				,EndUTC					= COALESCE(S.EndUTC, T.EndUTC)
				,RegistrationStartUTC	= COALESCE(S.RegStartUTC, T.RegistrationStartUTC)
				,RegistrationEndUTC		= COALESCE(S.RegEndUTC, T.RegistrationEndUTC)
				,UnitPrice				= COALESCE(S.UnitPrice, T.UnitPrice)
				,CurrencyType			= COALESCE(S.CurrencyType, T.CurrencyType)
				,CompQtyPerDS			= COALESCE(S.CompQtyPerDS, T.CompQtyPerDS)
				,MaxQtyPerDS			= COALESCE(S.MaxQtyPerDS, T.MaxQtyPerDS)
				,ReserveTimeOut			= COALESCE(S.ReserveTimeOut, T.ReserveTimeOut)
				,PaymentTimeOut			= COALESCE(S.PaymentTimeOut, T.PaymentTimeOut)
				,ModifiedUTC			= S.CurrentUTC
				,ModifiedBy				= S.ModifiedBy
		WHEN NOT MATCHED THEN INSERT
				(PK_Event
			   ,ActivityName
			   ,ActivityDesc
			   ,ActivitySequence
			   ,Location
			   ,Address1
			   ,Address2
			   ,City
			   ,StateProvince
			   ,PostalCode
			   ,PK_Country
			   ,StartUTC
			   ,EndUTC
			   ,RegistrationStartUTC
			   ,RegistrationEndUTC
			   ,UnitPrice
			   ,CurrencyType
			   ,CompQtyPerDS
			   ,MaxQtyPerDS
			   ,MaxQty
			   ,SoldQty
			   ,ProcessingQty
			   ,AvailableQty
			   ,ReserveTimeOut
			   ,PaymentTimeOut
			   ,DeletedUTC
			   ,CreatedUTC
			   ,CreatedBy
			   ,ModifiedUTC
			   ,ModifiedBy)
		 VALUES (S.PK_Event
			   ,S.ActivityName
			   ,S.ActivityDesc
			   ,S.ActivitySequence
			   ,S.Location
			   ,S.Address1
			   ,S.Address2
			   ,S.City
			   ,S.StateProvince
			   ,S.PostalCode
			   ,S.PK_Country
			   ,S.StartUTC
			   ,S.EndUTC
			   ,S.RegStartUTC
			   ,S.RegEndUTC
			   ,S.UnitPrice
			   ,S.CurrencyType
			   ,S.CompQtyPerDS
			   ,S.MaxQtyPerDS
			   ,0
			   ,0
			   ,0
			   ,0
			   ,S.ReserveTimeOut
			   ,S.PaymentTimeOut
			   ,NULL
			   ,S.CurrentUTC
			   ,S.ModifiedBy
			   ,S.CurrentUTC
			   ,S.ModifiedBy
			   );


		SELECT @PK_EventActivity  = PK_EventActivity FROM dbo.EventActivity WITH (NOLOCK) WHERE ActivityName = @ActivityName AND PK_Event = @PK_Event
		SELECT @MaxVar = @MaxQty - MaxQty  FROM dbo.EventActivity WITH (NOLOCK) WHERE PK_EventActivity = @PK_EventActivity

		IF @MaxVar <> 0 
		BEGIN

			Exec usp_Update_ActivityInventory 
			@PK_EventActivity = @PK_EventActivity, 
			@MaxVar = @MaxVar, 
			@SoldVar = 0, 
			@ProcessingVar = 0, 
			@AvailableVar = 0

		END

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