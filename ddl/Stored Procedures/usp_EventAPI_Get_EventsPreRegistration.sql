CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventsPreRegistration]
	-- Mandatory Parameters
	  @DistributorID VARCHAR(10)
	 ,@PK_Event INT
	 ,@LocaleCode CHAR(5)
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_EventsPreRegistration

USE:		
			DECLARE @e int, @em varchar(4000)

			EXEC usp_EventAPI_Get_EventsPreRegistration
					 @DistributorID = '2222222222'
					,@PK_Event = 1226
					,@LocaleCode = 'en-US'
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.EventsRegistration with flag hasCheckedIn = 0

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventsRegistration

VERSIONS
--------------------------------------------------------------------
1	2010-11-24	Prabhu		Initial
2	2013-02-22	Sushma		A new result set added for the DS and Partner Info to be displayed on the same row
3	2015-08-17	OrlandoL	Add ER.CustomValue to SELECT
4	2017-01-30	RogelioR	Retrieve data when Partner/Member is not attending
5	2019-09-05	NoeG		SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_Locale INT
DECLARE @PK_EventHotel INT
DECLARE @FirstName VARCHAR(100)
DECLARE @LastName VARCHAR(100)
DECLARE @PK_Distributor INT
DECLARE @PK_DS INT
DECLARE @EventName nVARCHAR(100)

SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WITH (NOLOCK) WHERE sDistributorID = @DistributorID
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_EventHotel = PK_EventHotel FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_Event = @PK_Event AND DistributorID = @DistributorID AND IsPrimaryGuest = 1

SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
BE SURE THE VALUE OF FK EXISTS IN THE REFERENCED TABLE
******************************************************************************/
BEGIN TRY

	SELECT
		@FirstName = D.sFirstName
		,@LastName = D.sLastName
	FROM 
		dbo.v_Distributor D WITH (NOLOCK)
	LEFT JOIN
		dbo.v_MailingAddress MA WITH (NOLOCK)
	ON
		D.nDistributorID = MA.nDistributorID 
	WHERE 
		D.sDistributorID = @DistributorID

	IF NOT EXISTS (SELECT PK_Distributor FROM EventsRegistration WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor)-- AND FirstName = @FirstName)
	BEGIN

		SELECT @EventName = EventName FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

		SELECT
			NULL AS PK_EventsRegistration
			,D.[nDistributorID] AS PK_Distributor
			,D.[sDistributorID] AS DistributorID
			,'' AS PreferredName
			,ISNULL(D.[sFirstName],'') +  '; ' + ISNULL(D.[sLastName],'') AS DSName
			,CASE WHEN @PK_Event = 1226 THEN NULL ELSE D.[Phone] END AS [Main Phone]
			,CASE WHEN @PK_Event = 1226 THEN NULL ELSE D.[Phone] END AS [Mobile Phone]
			,ISNULL(DS.[sSpouseFirstName],'') +  ' ' + ISNULL(DS.[sSpouseLastName],'') AS [PartnerName]
			,'' AS [PartnerPreferredName]
			,CASE WHEN @PK_Event = 1226 THEN NULL ELSE M.sAddress1 END AS AddressLine1
			,CASE WHEN @PK_Event = 1226 THEN NULL ELSE M.sAddress2 END AS AddressLine2
			,CASE WHEN @PK_Event = 1226 THEN NULL ELSE M.sCity END AS City
			,CASE WHEN @PK_Event = 1226 THEN NULL ELSE M.sPostalCode END AS ZipCode
			,CASE WHEN @PK_Event = 1226 THEN NULL ELSE M.sState END AS State
			,CASE WHEN @PK_Event = 1226 THEN NULL ELSE M.sCountry END AS Country
			,CASE WHEN @PK_Event = 1226 THEN NULL ELSE D.sEmail END AS EmailAddress
			,NULL AS [IsPartnerAttending]
			,NULL AS [IsDistributor]
			,NULL AS [IsPreRegistered]
			,@PK_Event AS PK_Event 
			,@EventName AS EventName
			,NULL AS [PK_PrimaryLanguage]
			,NULL AS [PK_SecondaryLanguage] 
			,NULL AS [PK_EventHotel] 
			,1 AS IsPreRegRecordEditable 
			,NULL AS [IsUsingVolume]
			,NULL AS [Apartment]
			,NULL AS [MemberCustomValue]
			,NULL AS [PartnerCustomValue]
			,0 AS [IsMemberNotAttending]
		FROM
			dbo.v_Distributor D WITH (NOLOCK)
		LEFT JOIN
			  dbo.v_MailingAddress M WITH (NOLOCK)
		ON
			  D.nDistributorID = M.nDistributorID
		LEFT JOIN
			dbo.v_DistributorSpouse DS WITH (NOLOCK)
		ON
			D.nDistributorID = DS.nDistributorID 
		WHERE 
			D.sDistributorID = @DistributorID

	END
	ELSE 
	BEGIN

		;WITH cte AS (
			SELECT TOP 1 
					er.[PK_Distributor]
					,er.[PK_Event]
					,er.[DistributorID]
					,er.[FirstName]
					,er.[LastName]
					,er.[AddressLine1]
					,er.[AddressLine2]
					,er.[City]
					,er.[ZipCode]
					,er.[State]
					,er.[Country]
					,er.[EmailAddress]
					,er.[Phones]
					,er.[IsDistributor]
					,er.[IsPreRegistered]
					,er.[PK_PrimaryLanguage]
					,er.[PK_SecondaryLanguage] 
					,er.[PK_EventHotel]
					,d.[sFirstName]
					,d.[sLastName]
					,ds.[sSpouseFirstName]
					,ds.[sSpouseLastName]
					,ISNULL((SELECT TOP 1 PK_EventsRegistration 
									FROM EventsRegistration  WITH (NOLOCK)
									WHERE PK_Event =  @PK_Event 
										AND PK_Distributor = @PK_Distributor 
										AND FirstName = @FirstName)
								, PK_EventsRegistration
					) AS PK_EventsRegistration
				FROM EventsRegistration AS er WITH (NOLOCK)
					INNER JOIN v_Distributor AS d WITH (NOLOCK) ON d.nDistributorID = @PK_Distributor
					LEFT JOIN v_DistributorSpouse AS ds WITH (NOLOCK) ON ds.nDistributorID = d.nDistributorID
				WHERE pk_event = @PK_Event
					AND pk_distributor = @PK_Distributor
		)
		SELECT
		   c.[PK_EventsRegistration]
		   ,c.[PK_Distributor]
			,c.[DistributorID]
			,ISNULL(ER.DSPreferredName, c.sFirstName) PreferredName
			,ISNULL(ER.[FirstName], c.[sFirstName]) +  '; ' + ISNULL(ER.[LastName], c.[sLastName]) DSName
			--,CASE WHEN CHARINDEX(';', c.[Phones], 1 - 1) = 0 THEN c.[Phones] ELSE SUBSTRING (c.[Phones], 1, CHARINDEX(';', c.[Phones], 1 - 1) - 1) END AS [Main Phone]
			--,CASE WHEN CHARINDEX(';', c.[Phones], 1 - 1) > 0 THEN SUBSTRING(c.[Phones], CHARINDEX(';', c.[Phones], 1) + 1, LEN(c.[Phones])) ELSE NULL END as [Mobile Phone]
			,CASE WHEN CHARINDEX(';', c.[Phones], 0) = 0 THEN c.[Phones] ELSE SUBSTRING (c.[Phones], 1, CHARINDEX(';', c.[Phones], 0) - 1) END AS [Main Phone]
			,CASE WHEN CHARINDEX(';', c.[Phones], 0) > 0 THEN SUBSTRING(c.[Phones], CHARINDEX(';', c.[Phones], 1) + 1, LEN(c.[Phones])) ELSE NULL END as [Mobile Phone]
			,COALESCE(SP.FirstName, c.sSpouseFirstName + ' ') + COALESCE(SP.LastName, c.sSpouseLastName, '') AS [PartnerName]
			,SP.DSPreferredname AS [PartnerPreferredName]
			,c.[AddressLine1]
			,c.[AddressLine2]
			,c.[City]
			,c.[ZipCode]
			,c.[State]
			,c.[Country]
			,c.[EmailAddress]
			,CASE WHEN SP.PK_EventsRegistration IS NULL THEN 0 ELSE 1 END AS [IsPartnerAttending]
			,c.[IsDistributor]
			,c.[IsPreRegistered]
			,E.PK_Event
			,E.EventName
			,c.[PK_PrimaryLanguage]
			,c.[PK_SecondaryLanguage] 
			,c.[PK_EventHotel] 
			,ISNULL(E.IsPreRegRecordEditable,0) AS [IsPreRegRecordEditable]
			,ISNULL(ER.IsUsingVolume, SP.IsUsingVolume) AS [IsUsingVolume]
			,ISNULL(ER.Apartment, SP.Apartment) AS [Apartment]
			,ER.CustomValue AS MemberCustomValue
			,SP.CustomValue AS PartnerCustomValue
			,CASE WHEN ER.PK_EventsRegistration IS NULL THEN 1 ELSE 0 END AS [IsMemberNotAttending]
		FROM 
			cte AS c WITH (NOLOCK)
		LEFT JOIN
			dbo.EventsRegistration ER WITH (NOLOCK)
		ON
			ER.PK_Distributor = c.PK_Distributor
			AND
			ER.IsPrimaryGuest = 1
			AND
			ER.PK_Event =  @PK_Event
		INNER JOIN
			dbo.Event E WITH (NOLOCK)
		ON
			c.PK_Event = E.PK_Event
		LEFT JOIN
			dbo.EventsRegistration SP WITH (NOLOCK)
		ON
			c.DistributorID = SP.DistributorID
			AND
			c.PK_Distributor = SP.PK_Distributor
			AND
			SP.PK_Event = @PK_Event
			AND 
			SP.IsPrimaryGuest = 0
	END

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

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

BEGIN TRY

	/******************************************************************************
	SELECT THE HOTEL RECORDS FOR DISPLAY IN THE DROP DOWN
	******************************************************************************/
	IF EXISTS(SELECT DistributorID FROM dbo.EventsRegistration WITH (NOLOCK) WHERE DistributorID= @DistributorID AND PK_Event = @PK_Event and HasCheckedIn = 0)
	BEGIN
	SELECT
		 EH.PK_EventHotel
		,HI.HotelName
		,HI.AddressLine1
		,HI.AddressLine2
		,HI.City
		,EH.PK_Event
	FROM
		dbo.EventHotel EH WITH (NOLOCK)
	INNER JOIN
		dbo.Event E WITH (NOLOCK)
	ON
		EH.PK_Event = E.PK_Event
		AND EH.PK_Event = @PK_Event
		AND EH.PK_EventHotel = @PK_EventHotel
	INNER JOIN
		dbo.HotelInfo HI (NOLOCK)
	ON
		HI.PK_HotelInfo = EH.PK_HotelInfo
		AND EH.PK_Event = @PK_Event
		AND HI.PK_Locale = COALESCE(@PK_Locale,E.PK_DefaultLocale)
	END
	ELSE
	BEGIN
	SELECT
		 EH.PK_EventHotel
		,HI.HotelName
		,HI.AddressLine1
		,HI.AddressLine2
		,HI.City
		,EH.PK_Event
	FROM
		dbo.EventHotel EH WITH (NOLOCK)
	INNER JOIN
		dbo.Event E WITH (NOLOCK)
	ON
		EH.PK_Event = E.PK_Event
		AND EH.PK_Event = @PK_Event
	INNER JOIN
		dbo.HotelInfo HI (NOLOCK)
	ON
		HI.PK_HotelInfo = EH.PK_HotelInfo
		AND EH.PK_Event = @PK_Event
		AND HI.PK_Locale = COALESCE(@PK_Locale,E.PK_DefaultLocale)
	END

	/******************************************************************************
	SELECT THE AVAILABLE LANGUAGES FOR DISPLAY IN THE DROP DOWN
	******************************************************************************/
	SELECT
		PK_EventLanguage
		,LanguageName
	FROM
		dbo.EventLanguages WITH (NOLOCK)
	
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
/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

