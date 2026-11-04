CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventItemFulfillment]
 -- Mandatory
     @PK_Event INT
	,@DistributorID VARCHAR(10)

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Get_EventItemFulfillment

USE:
			DECLARE @e int, @em varchar(4000)

             EXEC dbo.usp_MyHLEventAPI_Get_EventItemFulfillment
				 @PK_Event = 1217
				,@DistributorID = '09557499'
				,@Error = @e OUTPUT  /* @e must be defined in the local call */
				,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */					
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Insert/Update the shipping details for the qualified DS

NOTES:	As per requirement, Ship To Home is not available for Jamaica & Canada.
 If Distributor Residence Country is Jamaica or Canada, please default as blank on UI. 

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2014-11-25 SushmaA 	Initial
2   2017-04-27 Juan     Add Shipping Name
3   2017-05-01 Juan    Remove Filter for country
4	2019-08-14	NoeG	Refactor code (SRE)

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

/* ***************** SonarQube check 97 and 98 - Output parameters should be assigned 
	SRE changes added
*/

SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT   E.PK_EventItemFulfillment
				,D.nDistributorID PK_Distributor
				,D.sDistributorID DistributorID
				,ISNULL(D.[sFirstName],'') +  ' ' + ISNULL(D.[sLastName],'') AS DSName
				,E.PK_Event
				,E.ShippingName
				,E.PK_ShippingMethod
				,COALESCE(EML.PK_EventMarketType, 0) PK_EventMarketType
				,E.PK_EventMarketLocation
				,COALESCE(E.EmailAddress, Replace(D.sEmail, 'Unknown', ''))  EmailAddress
				,COALESCE(E.Phone, Replace(D.Phone,'Unknown','')) Phone
				,EML.City PickupCity
				,EML.State PickupState
				,EML.CountryCodeISO PickupCountry
				,CO.nCountryID PK_PickupCountry
				,COALESCE(E.Address1, Replace(Replace(d.sStreet,'Unknown', ''),'NULL','')) Address1
				,COALESCE(E.Address2, '') Address2
				,COALESCE(E.City,  Replace(Replace(D.sCity,'Unknown', ''),'NULL','')) City
				,COALESCE(E.State, Replace(Replace(D.sDistributorStateOrProvince,'Unknown', ''),'NULL','')) State
				,COALESCE(E.PostalCode, Replace(Replace(D.sDistributorPostalCode,'Unknown', ''),'NULL','')) PostalCode
				,COALESCE(E.CountryCodeISO, C.sCountryCodeISO)  CountryCodeISO
				,E.PK_Country
				,CASE WHEN COALESCE(EML.Location, '') = '' THEN  EML.City + ', ' + EML.State + ' ' + SUBSTRING(CONVERT(VARCHAR(7),StartDate, 113), 4, 3) + ' ' 

					+ CASE WHEN CONVERT(VARCHAR(2), DATEPART(DD, StartDate)) = CONVERT(VARCHAR(2), DATEPART(DD, EndDate)) THEN CONVERT(VARCHAR(2), DATEPART(DD, EndDate)) ELSE CONVERT(VARCHAR(2), DATEPART(DD, StartDate)) + ' - ' + CONVERT(VARCHAR(2), DATEPART(DD, EndDate))
		 END
					ELSE EML.City + ', ' + EML.State + ' - ' + EML.Location END	 [Event]	
				,CASE WHEN ES.EndUTC >= @StartTime THEN 1 ELSE 0 END [IsRegEnabled]
				,CASE WHEN ER.PK_Distributor IS NOT NULL THEN 1 ELSE 0 END HasPickedup
		FROM 
			dbo.v_Distributor D
		LEFT JOIN
			dbo.EventItemFulfillment E WITH (NOLOCK)
		ON
			E.PK_Distributor = D.nDistributorID
			AND
			E.PK_Event = @PK_Event
		LEFT JOIN
			dbo.EventMarketLocation EML WITH (NOLOCK)
		ON
			E.PK_EventMarketLocation = EML.PK_EventMarketLocation
		LEFT JOIN
			dbo.v_Countries CO
		ON
			CO.sCountryCodeISO = EML.CountryCodeISO
		LEFT JOIN
			dbo.EventSchedule ES WITH (NOLOCK)
		ON
			COALESCE(E.PK_Event, @PK_Event) = ES.PK_Event
		AND
			ES.PK_Schedule = 11 --For Reward Registration
		LEFT JOIN
			dbo.v_Countries C
		ON
			C.sCountryCode = D.sDistributorCountryResidenceCode
		LEFT JOIN
			dbo.EventsRegistration ER WITH (NOLOCK)
		ON
			ER.PK_Event = E.PK_Event
			AND
			ER.PK_Distributor = D.nDistributorID
		WHERE
			D.sDistributorID = @DistributorID

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

