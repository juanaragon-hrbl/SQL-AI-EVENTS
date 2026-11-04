CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_EventItemFulfillment]
 -- Mandatory
     @PK_Event INT
    ,@DistributorID VARCHAR(10)
    ,@PK_ShippingMethod INT
 -- Optional
 	,@PK_EventMarketLocation INT = NULL
 	,@PK_EventItemFulfillment INT = NULL
	,@ShippingName NVARCHAR(240) = NULL
 	,@EmailAddress VARCHAR(100) = NULL
 	,@Phone VARCHAR(100) = NULL
 	,@Address1 NVARCHAR(480) = NULL
 	,@Address2 NVARCHAR(480) = NULL
 	,@City nVARCHAR(120) = NULL
 	,@State nVARCHAR(120) = NULL
 	,@PostalCode nVARCHAR(120) = NULL
 	,@CountryCodeISO nVARCHAR(10) = NULL
 	,@ModifiedBY VARCHAR(100) = NULL
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Upd_EventItemFulfillment

USE:
			DECLARE @e int, @em varchar(4000)

             EXEC dbo.usp_MyHLEventAPI_Upd_EventItemFulfillment
				 @PK_Event = 1217
				,@DistributorID = '2222222222'
				,@PK_ShippingMethod = 1
			 -- Optional
 				,@PK_EventMarketLocation = 1
 				,@PK_EventItemFulfillment = NULL
				,@ShippingName = 'John Doe'
 				,@EmailAddress  = 'mark.hughes@gmail.com'
 				,@Phone = '123-456-7890'
 				,@Address1 = NULL
 				,@Address2 = NULL
 				,@City = NULL
 				,@State = NULL
 				,@PostalCode = NULL
 				,@ModifiedBY = '2222222222'
 				,@CountryCodeISO = NULL
 				,@Error = @e OUTPUT
 				,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Insert/Update the shipping details for the qualified DS

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2014-11-25 SushmaA 	Initial
2   2017-04-27 Juan     Add Shipping Name
3	2019-08-14	NoeG	Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

DECLARE @PK_Country INT
DECLARE @PK_Distributor INT
	
SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT @PK_Country = DC.PK_Country FROM PubEvents.dbo.dimCountry DC WITH (NOLOCK) WHERE @CountryCodeISO = COALESCE(DC.CountryCodeISO, DC.CountryCode)
		SELECT @PK_Distributor = DC.PK_Distributor FROM PubEvents.dbo.dimDistributor DC WITH (NOLOCK) WHERE DistributorID = @DistributorID

		IF @PK_ShippingMethod = 1
		BEGIN

		SET @State = NULL
		SET @CountryCodeISO = NULL
		SET @PK_Country = NULL

		END

		MERGE 
			dbo.EventItemFulfillment EI
		USING
		(	SELECT @PK_EventItemFulfillment [PK_EventItemFulfillment], @PK_Event [PK_Event], @PK_Distributor [PK_Distributor], @DistributorID [DistributorID], @PK_ShippingMethod [PK_ShippingMethod]
			,@PK_EventMarketLocation [PK_EventMarketLocation], @ShippingName [ShippingName], @EmailAddress [EmailAddress], @Phone [Phone], @Address1 [Address1], @Address2 [Address2]
			,@City [City], @State [State], @PostalCode [PostalCode], @CountryCodeISO [CountryCodeISO], @PK_Country [PK_Country], @ModifiedBy [ModifiedBY]
		)AS M
		ON EI.PK_Event = M.PK_Event AND EI.DistributorID = M.DistributorID
		WHEN NOT MATCHED THEN INSERT (PK_Distributor, DistributorID, PK_Event, PK_ShippingMethod, PK_EventMarketLocation, ShippingName, EmailAddress, Phone,
			Address1, Address2, City, State, PostalCode, CountryCodeISO, PK_Country, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy)
		VALUES (M.PK_Distributor, M.DistributorID, M.PK_Event, M.PK_ShippingMethod, M.PK_EventMarketLocation, M.ShippingName, M.EmailAddress, M.Phone,
			M.Address1, M.Address2, M.City, M.State, M.PostalCode, M.CountryCodeISO, M.PK_Country, @StartTime, M.ModifiedBy, @StartTime, M.ModifiedBy)
		WHEN MATCHED THEN UPDATE
		SET
			PK_ShippingMethod = M.PK_ShippingMethod, 
			PK_EventMarketLocation = M.PK_EventMarketLocation, 
			ShippingName = M.ShippingName,
			EmailAddress = M.EmailAddress, 
			Phone = M.Phone,
			Address1 = M.Address1, 
			Address2 = M.Address2, 
			City = M.City, 
			State = M.State, 
			PostalCode = M.PostalCode, 
			CountryCodeISO = M.CountryCodeISO, 
			PK_Country = M.PK_Country, 
			CreatedDateUTC = @StartTime, 
			CreatedBy = M.ModifiedBy, 
			ModifiedDateUTC = @StartTime, 
			ModifiedBy = M.ModifiedBy
		;

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

