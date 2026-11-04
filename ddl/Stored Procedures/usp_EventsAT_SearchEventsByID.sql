CREATE PROCEDURE [dbo].[usp_EventsAT_SearchEventsByID]
	@UserID VARCHAR(30) -- Pass the UserID value to perform actions based on the user access level.
	,@PK_Event AS INT
-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT
	,@IsDevQA  bit = 0	

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_SearchEvents

USE:
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.usp_EventsAT_SearchEventsByID

							-- Mandatory Parameters
							 @UserID = 'Juanah'
							 ,@PK_Event = 1653
							
							-- Error Parameters
							 ,@Error = @e OUTPUT
							 ,@ErrorMessage = @em OUTPUT
							 ,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves  events based on the ID

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2013-06-17		JuanaH		Intitial
2	2019-08-08		NoeG		Refactor code (SRE)
******************************************************************************/

--DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @HasQualifications INT
DECLARE @HasAccess INT
DECLARE @Subtbl TABLE(PK_EventSubType INT)

/* ***************** SonarQube check 75 and 76 - Output parameters should be assigned 
	SRE changes added
*/

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
Check passed event has Qualification
******************************************************************************/

	BEGIN TRY

		SELECT @HasQualifications = CASE WHEN COUNT(PK_SubEvent) > 0 THEN 1 ELSE 0 END FROM dbo.SubEventQualification (NOLOCK) WHERE PK_Event = @PK_Event

		SELECT @HasAccess = 
			CASE WHEN COUNT(DISTINCT E.PK_Event) > 0 THEN 1 ELSE 0 END
		FROM
		(	
		SELECT DISTINCT E.PK_Event	
		FROM 
			dbo.EventATAccessUser (NOLOCK) EU
		INNER JOIN 
			dbo.EventATAccessUserModules (NOLOCK) EUM
			ON
				EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
		INNER JOIN 
			dbo.Locales (NOLOCK) L
			ON
				L.PK_Locale = EUM.PK_Locale
		INNER JOIN 
			dbo.v_Countries C
			ON
				SUBSTRING(L.LocaleCode, CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.sCountryCodeISO
		INNER JOIN 
			dbo.EventDistributorCountry (NOLOCK) EC
			ON
				C.nCountryID = EC.PK_Country
		INNER JOIN 
			dbo.Event (NOLOCK) E
			ON 
				EC.PK_Event = E.PK_Event  
				AND
				E.PK_Event = @PK_Event                                        
		WHERE
			EU.EventATAccessUserName = @UserID
			AND
			E.PK_EventType !=3  
		UNION
		SELECT DISTINCT E.PK_Event 
		FROM dbo.EventATAccessUser (NOLOCK) EU
		INNER JOIN 
			dbo.EventATAccessUserModules (NOLOCK) EUM
			ON 
				EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
		INNER JOIN 
			dbo.Locales (NOLOCK) L
			ON 
				L.PK_Locale = EUM.PK_Locale
		INNER JOIN 
			dbo.EventLocaleDesc (NOLOCK) ELD
			ON
				L.PK_Locale = ELD.PK_Locale
		INNER JOIN 
			dbo.Event (NOLOCK) E
			ON 
				ELD.PK_Event = E.PK_Event	
				AND
				E.PK_Event = @PK_Event                                          
		WHERE
			EU.EventATAccessUserName = @UserID
			AND
			E.PK_EventType = 3
		)E


		/*Hide Deleted Events*/
		IF EXISTS (SELECT 1 FROM dbo.EventDeleteQueue (NOLOCK) WHERE PK_Event = @PK_Event)
			RETURN


		SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales (Nolock) WHERE LocaleCode = 'en-US'


		SELECT TOP 1
			 E.PK_Event
			,ED.EventName
			,CASE WHEN E.dStartUTC = E.dEndUTC THEN CONVERT(VARCHAR,E.dStartUTC,101) ELSE CONVERT(VARCHAR(20),E.dStartUTC) + ' - ' + CONVERT(VARCHAR(20),E.dEndUTC) END EventDate
			,E.dStartUTC EventStartDate
			,E.dEndUTC EventEndDate
			,E.PK_EventType
			,EST.PK_EventSubType
			,EST.EventSubType
			,ISNULL(ED.EventVenuename,'') EventVenueName
			,ISNULL(ED.EventDisplayAddress, '') EventDisplayAddress
			,B.DSTeamTypeCode
			,B.DSTeamTypeDesc
			,ISNULL(ED.EventAddress, '') EventAddress
			,ISNULL(ED.EventCity, E.EventCity) EventCity
			,ISNULL(ED.EventState, E.EventState) EventState
			,ISNULL(E.EventZipCode , '') EventZipCode
			,C.sCountryCodeISO EventCountry
			,C.sCountryName EventCountryName 
			,ISNULL(EI.PK_EventImageType,'') EventImageType 
			,ISNULL(EI.EventImageLocation, '') EventImageLocation
			,CASE WHEN ED.EventSummary IS NULL THEN (SELECT ISNULL(EventSummary,EventDesc) FROM dbo.EventLocaleDesc (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale) ELSE ED.EventSummary END EventDesc
			,CASE WHEN E.PK_EventType = 3 AND (E.IsActive = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 0 THEN 0
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 1 THEN 1
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 2 THEN 2
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 3 THEN 3
				  WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4
				  WHEN E.PK_EventType IN (1,2) AND (E.IsPublish = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
				  END STATUS
			,E.CreatedDateUTC CreatedDate
			,E.ModifiedDateUTC LastUpdatedDate
			,E.ModifiedBy LastUpdatedBy
			,NULL Distance
			,L.LocaleCode
			,E.IsActive
			,E.IsPublish
			,E.MakePublic IsPublic
			,E.IsPreRegistrationRequired
			,@HasAccess HasAccess
			,@HasQualifications HasQualifications 
			,EU.EventURLDesc AS [GalleryName]
			,EU.EventURL AS [GalleryURL]	
		FROM
			dbo.Event E (NOLOCK)	
		INNER JOIN
			dbo.EventCountry EC (NOLOCK)
		ON
			E.PK_Event = EC.PK_Event
		INNER JOIN
			dbo.v_Countries C
		ON
			EC.PK_Country = C.nCountryID
		INNER JOIN
			dbo.Locales L (NOLOCK)
		ON
			E.PK_DefaultLocale = L.PK_Locale
		INNER JOIN
			dbo.EventLocaleDesc ED (NOLOCK)
		ON
			E.PK_Event = ED.PK_Event
	
		LEFT JOIN
			dbo.EventEventSubType EEST (NOLOCK)
		ON
			E.PK_Event = EEST.PK_Event
		LEFT JOIN
			dbo.EventSubTypes EST (NOLOCK)
		ON
			EST.PK_EventSubType = EEST.PK_EventSubType
		INNER JOIN
			(
		SELECT
			 A.PK_Event
			,DT.DSTeamTypeCode
			,DTL.DSTeamTypeDesc
		FROM
			dbo.DSTeamType DT (NOLOCK)
		INNER JOIN
			(SELECT 
				 EDT.PK_Event
				,MAX(DT.TeamOrder) TeamOrder
			FROM 
				dbo.EventDSTeamType EDT (NOLOCK)
			INNER JOIN
				dbo.DSTeamType DT (NOLOCK)
			ON
				EDT.DSTeamTypeCode = DT.DSteamTypeCode 
			 
			GROUP BY 	
				 EDT.PK_Event	
			)A
			ON
			DT.TeamOrder = A.TeamOrder
		LEFT JOIN dbo.DSTeamTypeLocaleDesc DTL (NOLOCK)
				ON
			DTL.DSTeamTypeCode = DT.DSTeamTypeCode
			AND
			PK_Locale = @PK_DefaultLocale

		) B
		ON
			E.PK_Event = B.PK_Event	


		LEFT JOIN
			dbo.EventImage EI (NOLOCK)
		ON
			E.PK_Event = EI.PK_Event
		LEFT JOIN
			dbo.EventURL EU (NOLOCK)
		ON 
			E.PK_Event = EU.PK_Event
			AND
			EU.PK_EventURLType = 3 --Fetch only the Photo Gallery
		WHERE
			E.PK_Event = @PK_Event

	

		/* SELECT THE GUEST SPEAKERS FOR THE PASSED PK_Event */

		SELECT
			 EG.PK_Event
			,EG.PK_EventGuestSpeaker
			,EG.PK_GuestSpeaker
			,EG.EventSpeakerName
		FROM
			dbo.EventGuestSpeakers EG (NOLOCK)
		WHERE
			EG.PK_Event = @PK_Event


		/* GET THE COUNT OF EVENTS BY TYPES */
		SELECT
			 E.dStartUTC
			,ET.PK_EventSubType
			,ES.EventSubType
			,COUNT(1) EventCount
		FROM
			dbo.Event E (NOLOCK)
		INNER JOIN
			dbo.EventEventSubType ET (NOLOCK)
		ON
			E.PK_EventType = ET.PK_EventType
			AND 
			E.PK_Event = ET.PK_Event
		INNER JOIN
			dbo.EventSubTypes ES (NOLOCK)
		ON
			ET.PK_EventSubType = ES.PK_EventSubType
			AND 
			ET.PK_EventType = ES.PK_EventType
		WHERE
			E.PK_Event = @PK_Event

		GROUP BY 
			  E.dStartUTC
			 ,ET.PK_EventSubType
			 ,ES.EventSubType

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
