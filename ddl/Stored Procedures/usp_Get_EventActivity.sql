CREATE PROCEDURE [dbo].[usp_Get_EventActivity]
        -- Mandatory Parameters
		@PK_Event					INT
		,@DistributorID				VARCHAR(10)		
		,@LocaleCode				CHAR(5)
		-- Optional Parameters
		,@ActivityName				nVARCHAR(400)	= NULL
		,@StartUTC					DATETIME		= NULL
		,@EndUTC					DATETIME		= NULL
		,@PK_Country                INT             = NULL
		,@RegStartUTC				DATETIME		= NULL
		,@RegEndUTC					DATETIME		= NULL
		,@ReturnActive				BIT				= 1  -- Exclude Deleted Activity(s)
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT
		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_Get_EventActivity

USE:
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.usp_Get_EventActivity
					 	 @PK_Event = 2595
						,@DistributorID = '20248746'
						,@LocaleCode = 'ZH-hk'
                        ,@ReturnActive = 1
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Return Activities, Event and DS info 
TABLES:			dbo.Event, dbo.EventActivity
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2015-07-14		SandhyaP	Intitial
2	2019-08-14		NoeG		Refactor code (SRE)
3	2019-11-04		NoeG		SRE Hardcode changed
******************************************************************************/


/* DECLARE THE REQUIRED VARIABLES */
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'

	/* ***************** SonarQube check 79 and 80 - Output parameters should be assigned 
		SRE changes added
	*/
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE @CurrentUTC DATETIME = GETUTCDATE()
		DECLARE @PK_Locale INT
		DECLARE @PK_DefaultLocale INT

		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

		DECLARE @EventActivity TABLE
			(PK_EventActivity int  NOT NULL,
			PK_Event int NOT NULL,
			ActivityName nvarchar(200) NOT NULL,
			ActivityDesc nvarchar(MAX) NULL,
			ActivitySequence int NULL,
			Location nvarchar(200) NULL,
			Address1 nvarchar(100) NULL,
			Address2 nvarchar(100) NULL,
			City nvarchar(100) NULL,
			StateProvince nvarchar(100) NULL,
			PostalCode varchar(25) NULL,
			PK_Country int NULL,
			StartUTC datetime NULL,
			EndUTC datetime NULL,
			RegistrationStartUTC datetime NULL,
			RegistrationEndUTC datetime NULL,
			UnitPrice decimal(17, 2) NULL,
			CurrencyType varchar(3) NULL,
			CompQtyPerDS int NULL,
			MaxQtyPerDS int NULL,
			MaxQty int NOT NULL,
			SoldQty int NOT NULL,
			ProcessingQty int NOT NULL,
			AvailableQty int NOT NULL,
			ReserveTimeOut int NOT NULL,
			PaymentTimeOut int NOT NULL,
			DeletedUTC datetime NULL,
			CreatedUTC datetime NOT NULL,
			CreatedBy nvarchar(50) NOT NULL,
			ModifiedUTC datetime NOT NULL,
			ModifiedBy nvarchar(50) NOT NULL)


		Declare @e int, @em varchar(200)
		INSERT @EventActivity EXEC dbo.usp_Get_EventActivityList
				 @PK_Event = @PK_Event
				,@ReturnActive = @ReturnActive
				,@Error = @e OUTPUT  /* @e must be defined in the local call */
				,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */

		/* GET THE ACTIVITY INFO AND IF DS IS REGISTERED FOR ACTIVITY(S) */

		SELECT EA.PK_EventActivity
			  ,EA.PK_Event
			  ,COALESCE(EAL.ActivityName, EA.ActivityName) AS ActivityName
			  ,COALESCE(EAL.ActivityDesc, EA.ActivityDesc) AS ActivityDesc
			  ,EA.ActivitySequence
			  ,COALESCE(EAL.Location, EA.Location) AS Location
			  ,COALESCE(EAL.Address1, EA.Address1) AS Address1
			  ,COALESCE(EAL.Address2, EA.Address2) AS Address2
			  ,COALESCE(EAL.City, EA.City) AS City
			  ,COALESCE(EAL.StateProvince, EA.StateProvince) AS StateProvince
			  ,COALESCE(EAL.PostalCode, EA.PostalCode) AS PostalCode
			  ,EA.PK_Country
			  ,EA.StartUTC
			  ,EA.EndUTC
			  ,EA.RegistrationStartUTC
			  ,EA.RegistrationEndUTC
			  ,EA.UnitPrice
			  ,EA.CurrencyType
			  ,EA.CompQtyPerDS
			  ,EA.MaxQtyPerDS
			  ,EA.MaxQty
			  ,EA.SoldQty
			  ,EA.ProcessingQty
			  ,EA.AvailableQty
			  ,EA.ReserveTimeOut
			  ,EA.PaymentTimeOut
			  ,EA.DeletedUTC
			  ,EA.CreatedUTC
			  ,EA.CreatedBy
			  ,EA.ModifiedUTC
			  ,EA.ModifiedBy
			  ,CASE WHEN EA.PK_EventActivity = T.PK_EventActivity THEN 1 ELSE 0 END IsActivityRegistered
		FROM  @EventActivity EA
		LEFT JOIN
			dbo.EventActivityLocale EAL WITH (NOLOCK)
		ON
			EA.PK_EventActivity = EAL.PK_EventActivity
			AND
			EAL.PK_Locale = @PK_Locale
		LEFT JOIN
			(SELECT DISTINCT EA.PK_Event, ET.PK_EventActivity
			 FROM dbo.EventActivityTransaction ET WITH (NOLOCK) 
			 INNER JOIN
			 dbo.Eventactivity EA WITH (NOLOCK)
			 ON EA.PK_EventActivity = ET.PK_EventActivity
			 INNER JOIN 
			 dbo.EventActivityParticipant EP WITH (NOLOCK) 
			 ON ET.PK_EventActivityTransaction = EP.PK_EventActivityTransaction
			 AND ET.DistributorID = @DistributorID
			 WHERE EA.PK_Event = @PK_Event 
			 AND ET.PK_TransactionStatus IN (3,8)
			 AND ET.ConfirmationNumber IS NOT NULL) T
		ON
			EA.PK_Event = T.PK_Event AND EA.PK_EventActivity = T.PK_EventActivity

		/* GET THE ASSET INFO FOR RESPECTIVE ACTIVITY(S) LISTED FROM ABOVE */

		SELECT EAA.PK_EventActivityAsset
			,EAA.PK_AssetType
			,EAA.PK_EventActivity 
			,EAA.ActivityAsset
			,EAA.AssetOrder
			,EAA.CreatedUTC
			,EAA.CreatedBy
			,EAA.ModifiedUTC
			,EAA.ModifiedBy
		FROM	
			@EventActivity EA
		INNER JOIN
			dbo.EventActivityAsset EAA WITH (NOLOCK)
			ON
				EA.PK_EventActivity = EAA.PK_EventActivity
		WHERE
			PK_Event = @PK_Event
	

		/* GET THE EVENT INFO  */

		SELECT 
			E.PK_Event
 			,ISNULL(ED.EventName, (SELECT DISTINCT EventName FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_DefaultLocale AND PK_Event = @PK_Event)) EventName  
			,ISNULL(ED.EventLocation, (SELECT DISTINCT EventLocation FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_DefaultLocale AND PK_Event = @PK_Event)) EventLocation
			,ISNULL(ED.EventAddress, (SELECT DISTINCT EventAddress FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_DefaultLocale AND PK_Event = @PK_Event)) EventAddress
			,ISNULL(ED.EventCity, E.EventCity) EventCity
			,ISNULL(ED.EventState, E.EventState) EventState
			,C.sCountryName EventCountry
			,ISNULL(E.EventZipCode, '') EventZipCode
			,ISNULL(ED.EventDisplayAddress,(SELECT DISTINCT EventDisplayAddress FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_DefaultLocale AND PK_Event = @PK_Event)) EventDisplayAddress
			,ISNULL(ED.EventDesc, (SELECT DISTINCT EventDesc FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale)) EventDesc
			,ISNULL(ED.EventSummary, (SELECT DISTINCT EventSummary FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale)) EventSummary
			,EI.EventImageLocation AS EventLogo	
		FROM
			dbo.Event E WITH (NOLOCK)
		INNER JOIN
			dbo.EventCountry EC WITH (NOLOCK)
		ON
			E.PK_Event = EC.PK_Event
		INNER JOIN
			dbo.v_Countries C
		ON
			EC.PK_Country = C.nCountryID
		LEFT JOIN
			dbo.EventLocaleDesc ED WITH (NOLOCK)
		ON
			E.PK_Event = ED.PK_Event
			AND
			(ED.PK_Locale = CASE WHEN @PK_Locale IS NULL THEN ED.PK_Locale ELSE @PK_Locale END)
		LEFT JOIN
			dbo.EventImage EI WITH (NOLOCK)
		ON
			E.PK_Event = EI.PK_Event
			AND
			EI.PK_EventImageType = 1
		WHERE
			E.PK_Event = @PK_Event

		/* GET THE DS QUALIFIED/TICKETS INFO AND ACTIVITY REGISTERED FLAG */

		SELECT 
			@DistributorID AS DistributorID
			,S.sFirstName AS FirstName
			,S.sLastName AS LastName
			,ISNULL(D.Qualified, 0) AS IsQualified
			,ISNULL(A.EventTicketPurchased, 0) AS EventTicketPurchased
			,ISNULL(T.IsRegistered, 0) AS IsRegistered
		FROM
			dbo.Event E WITH (NOLOCK)
		LEFT JOIN
			(SELECT DISTINCT SQ.PK_Event, DistributorID, SQ.Qualified
			 FROM dbo.SubEventQualifier SQ WITH (NOLOCK) 
			 INNER JOIN dbo.SubEvent SE WITH (NOLOCK) ON SQ.PK_SubEvent = SE.PK_SubEvent AND SE.SubEventNumber IN (1) /* modified by SandhyaP */
			 WHERE SE.PK_Event = @PK_Event AND SQ.DistributorID = @DistributorID AND SQ.RemovedUTC = @ValidDate)D
		ON
			E.PK_Event = D.PK_Event
		LEFT JOIN
			(SELECT SKU.PK_Event, SKU.DistributorID, SUM(SKU.Quantity) EventTicketPurchased
			 FROM dbo.SKUPurchased SKU WITH (NOLOCK) INNER JOIN dbo.EventSKU ES WITH (NOLOCK) 
			 ON ES.PK_EventSKU = SKU.PK_EventSKU AND IsEventTicketSKU = 1 
			 WHERE SKU.PK_Event = @PK_Event AND SKU.DistributorID = @DistributorID
			 GROUP BY SKU.PK_Event, SKU.DistributorID )A
		ON
			E.PK_Event = A.PK_Event
		INNER JOIN
			dbo.v_Distributor S
		ON
			S.sDistributorID = @DistributorID
		LEFT JOIN
			(SELECT EA.PK_Event, CASE WHEN COUNT(ET.PK_EventActivityTransaction) > 0 THEN 1 ELSE 0 END AS IsRegistered
			 FROM dbo.EventActivityTransaction ET WITH (NOLOCK) 
			 INNER JOIN
			 dbo.Eventactivity EA WITH (NOLOCK)
			 ON EA.PK_EventActivity = ET.PK_EventActivity
			 AND ET.DistributorID = @DistributorID
			 INNER JOIN 
			 dbo.EventActivityParticipant EP WITH (NOLOCK) 
			 ON ET.PK_EventActivityTransaction = EP.PK_EventActivityTransaction	 
			 WHERE EA.PK_Event = @PK_Event 
			 AND ET.PK_TransactionStatus IN (3,8) 
			 AND ET.ConfirmationNumber IS NOT NULL
			 GROUP BY EA.PK_Event) T -- Confirmed registrants only
		ON
			E.PK_Event = T.PK_Event
		WHERE
			E.PK_Event = @PK_Event

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

