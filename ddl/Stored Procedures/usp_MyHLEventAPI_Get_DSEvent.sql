CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_DSEvent]
        -- Mandatory Parameters
         @UserID varchar(30)
		,@PK_Event INT
		,@LocaleCode CHAR(5)
		,@DistributorID VARCHAR(10)
		-- Optional Parameters
		,@IsSeries BIT = 0 --By default opened in Instance, if opened in Series pass 1
		,@IsParent BIT = 0 --If EventID is Parent id, Please pass 1
		
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_DSEvent

USE:
			DECLARE @e int, @em varchar(4000)
                 EXEC dbo.usp_MyHLEventAPI_Get_DSEvent
						@UserID = 'SandhyaP'
					 	,@PK_Event = 35575
						,@LocaleCode = 'en-US'
						,@DistributorID = ''
						,@IsSeries = 0
						,@IsParent = 0
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the records for associated DS Event based on the PK_Event passed

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.EventLocaleADesc, dbo.EventCoordinatorDetail, dbo.EventURL

VERSIONS (PROD)
----------------------------------------------------------------------------------
1	2010-12-01	Prabhu	Intitial
2 2013-01-16 Sushma Changes made for Title columns of EventGuestSpeakers and CoOrdinatorDetails 
					Included EventAudio files location retrieval  
3 2013-01-22 Sushma	Changes made for EventVenueName, IsSocialNetworkEnabled,IsAlwaysVisible, IsPreRegistrationRequired
4 2013-01-30 Sushma	Changes made for EventDistributionCountry table result set
5 2013-04-20   Juan   Not display for deleted events
6 2013-07-03 Sushma   Target Market CR Changes
7 2014-06-10 Sushma   Team Level Incorporation Changes
8 2015-02-12 Sandhya  Changes made for Recurring Events
9 2019-08-14 NoeG	Refactor code (SRE)

******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @PK_EventType INT
DECLARE @HasAccess INT
DECLARE @IsRecurringChild BIT = 0
DECLARE @IsMYHL BIT = 0

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT @Error = 0, @ErrorMessage = '';
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @PK_Event
SELECT @PK_EventType = PK_EventType FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @PK_Event

BEGIN TRY

		SELECT 
			@IsRecurringChild = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END
		FROM 
			dbo.Event  WITH(NOLOCK) 
		WHERE 
			PK_Event = @PK_Event
			AND 
			IsRecurring = 0 AND PK_OldEventApp IS NOT NULL
	
		/*Hide Deleted Events*/
		IF EXISTS (SELECT 1 FROM dbo.EventDeleteQueue WITH(NOLOCK) WHERE PK_Event = @PK_Event)
		BEGIN
			RETURN
		END

		SELECT @IsMYHL = CASE WHEN COALESCE(@DistributorID, '') <> '' THEN 1 ELSE 0 END

		IF @IsSeries = 1 --AND @IsParent = 0
		BEGIN
			IF  @IsMYHL = 1 --if logged in from MyHL
			BEGIN
		
		
				SELECT @PK_Event = COALESCE(MIN(A.PK_Event), @PK_Event) -- COALESCE to return self if the Event returned is Past Event/Inactive/Under review
				FROM
				(
				SELECT E2.PK_Event, MIN(E2.dStartUTC) StartDate
				FROM
					dbo.Event E WITH(NOLOCK)
				INNER JOIN
					dbo.Event E1 WITH(NOLOCK)
					ON
						E.PK_Event = @PK_Event
						AND
						E.PK_OldEventApp = E1.PK_Event
				INNER JOIN
					dbo.Event E2 WITH(NOLOCK)
					ON
						E1.PK_Event = E2.PK_OldEventApp
				WHERE 
						@StartTime <= E2.dEndUTC
						AND 
						E2.PK_OldEventApp IS NOT NULL
						AND
						E2.PK_Event NOT IN (SELECT PK_Event FROM dbo.EventDeleteQueue  WITH(NOLOCK) WHERE PK_Event IS NOT NULL) --exclude events to be deleted
						AND 
						E2.EventApprovalStatus <> 0 --exclude events that are under review
				GROUP BY 
						E2.PK_Event
				)A
			END		
			ELSE IF @IsMYHL = 0 -- if logged in as Admin
			BEGIN
				SELECT @PK_Event = MIN(A.PK_Event)
				FROM
				(
				SELECT E2.PK_Event, MIN(E2.dStartUTC) StartDate
				FROM
					dbo.Event E WITH(NOLOCK)
				INNER JOIN
					dbo.Event E1 WITH(NOLOCK)
					ON
						E.PK_Event = @PK_Event
						AND
						E.PK_OldEventApp = E1.PK_Event
				INNER JOIN
					dbo.Event E2 WITH(NOLOCK)
					ON
						E1.PK_Event = E2.PK_OldEventApp
				WHERE 
						@StartTime <= E2.dEndUTC
						AND 
						E2.PK_OldEventApp IS NOT NULL
						AND
						E2.PK_Event NOT IN (SELECT PK_Event FROM dbo.EventDeleteQueue  WITH(NOLOCK) WHERE PK_Event IS NOT NULL) --exclude events to be deleted
				GROUP BY 
						E2.PK_Event
				)A	
			END	 	
		END			 
		ELSE 
		BEGIN
	
			SELECT @PK_Event = CASE WHEN E.IsRecurring = 0 THEN E.PK_Event 
									WHEN E.IsRecurring = 1 AND E.EventApprovalStatus = 3 THEN E.PK_Event -- for recurring events that are saved as draft to return parent eventid (that has no children)
									WHEN @IsParent = 1 AND E.IsRecurring = 1 AND E.EventApprovalStatus = 1 THEN E.PK_Event -- for recurring events that are approved to return parent eventid right after creation
									WHEN @IsParent = 0 AND E.IsRecurring = 1 AND E.EventApprovalStatus = 0 THEN E.PK_Event -- for recurring events that are under review to return parent eventid right after creation
									ELSE NULL END
			FROM
				dbo.Event E WITH(NOLOCK)
			WHERE 
				E.PK_Event = @PK_Event

		END

		/******************************************************************************
		Check Staff has the permissions to the passed locale
		******************************************************************************/

		SELECT @HasAccess = 
			CASE WHEN COUNT(DISTINCT E.PK_Event) > 0 THEN 1 ELSE 0 END
		FROM
		(	
			SELECT DISTINCT E.PK_Event	
			FROM 
				dbo.EventATAccessUser EU WITH(NOLOCK)
			INNER JOIN 
				dbo.EventATAccessUserModules EUM WITH(NOLOCK)
				ON
					EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
			INNER JOIN 
				dbo.Locales L WITH(NOLOCK)
				ON
					L.PK_Locale = EUM.PK_Locale
			INNER JOIN 
				dbo.v_Countries C
				ON
					SUBSTRING(L.LocaleCode, CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.sCountryCodeISO
			INNER JOIN 
				dbo.EventDistributorCountry EC WITH(NOLOCK)
				ON
					C.nCountryID = EC.PK_Country
			INNER JOIN 
				dbo.Event E WITH(NOLOCK)
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
			FROM dbo.EventATAccessUser EU WITH(NOLOCK)
			INNER JOIN 
				dbo.EventATAccessUserModules EUM WITH(NOLOCK)
				ON 
					EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
			INNER JOIN 
				dbo.Locales L WITH(NOLOCK)
				ON 
					L.PK_Locale = EUM.PK_Locale
			INNER JOIN 
				dbo.EventLocaleDesc ELD WITH(NOLOCK)
				ON
					L.PK_Locale = ELD.PK_Locale
			INNER JOIN 
				dbo.Event E WITH(NOLOCK)
				ON 
					ELD.PK_Event = E.PK_Event	
					AND
					E.PK_Event = @PK_Event                                          
			WHERE
				EU.EventATAccessUserName = @UserID
				AND
				E.PK_EventType = 3
			UNION
			SELECT DISTINCT E.PK_Event 
			FROM 
				dbo.Event E WITH(NOLOCK)
			WHERE
				E.PK_EventType = 3
			AND 
				E.CreatedDistributorID = @DistributorID
		)E		
		
	
		IF (@DistributorID <> '' ) AND  NOT EXISTS (SELECT  1 from dbo.Event E WITH(NOLOCK) where E.CreatedDistributorID = @DistributorID)
		BEGIN
			SET @Error = 411
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 

		END

		IF @PK_EventType !=3

		BEGIN

			SET @Error = 1
			SET @ErrorMessage = 'This is not a Distributor Event'

		END

		ELSE
		BEGIN
		IF EXISTS (SELECT PK_Locale FROM dbo.EventLocaleDesc WITH(NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_Locale)
		BEGIN
		/* SELECT EVENT DETAILS FOR THE PASSED PK_EVENT */
		BEGIN TRY

		SELECT DISTINCT	E.PK_Event
			,ED.EventName
			,E.dStartUTC EventStartDate
			,E.dEndUTC EventEndDate
			,ED.EventAddress
			,ED.EventCity
			,ED.EventState
			,EC.PK_Country
			,C.sCountryCodeISO As EventCountry 
			,E.EventZipCode
			,E.EventApprovalStatus -- 0 = Under review; 1 = Approved; 2 = Rejected; 3 = Save As Draft
			,E.IsActive
			,E.IsPublish
			,E.DisplayStartDate DisplayStartDate
			,E.DisplayEndDate DisplayEndDate
			,ISNULL(ED.EventDisplayAddress,'') EventDisplayAddress
			,ISNULL(ED.EventTrainingLanguages, '') EventTrainingLanguages
			,ISNULL(ED.EventCostDetails, '') EventCostDetails
			,COALESCE(EU.Flyer, '') Flyer
 			,EU.PK_EventURL   
			,EU.EventURL
			,EI.PK_EventImage
			,EI.EventImageLocation
			,ISNULL(ED.EventDesc,'') EventDesc
			,ISNULL(ED.EventApprovalNotes, '') ApprovalNotes
			,ISNULL(ED.EventComments, '') Comments
			,L.LocaleCode
			,L.LanguageCountryRegion
			,E.CreatedDistributorID DistributorID
			,E.EventVenueName 
			,E.IsSocialNetworkEnabled
			,E.IsAlwaysVisible
			,E.IsPreRegistrationRequired
			,ED.EventSummary
			,@HasAccess HasAccess
			,CASE WHEN E.PK_EventType = 3 AND E.IsActive = 0 THEN 5 
				  WHEN E.PK_EventType != 3 AND (E.IsActive = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR COALESCE(E.RecurrenceEndDate, E.dEndUTC) < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
				  ELSE E.EventApprovalStatus END
			 AS [EventStatus]
			,SUBSTRING(CONVERT(NVARCHAR(30),E.dStartUTC, 108), 1, 5) AS EventStartTime
			,SUBSTRING(CONVERT(NVARCHAR(30),E.dEndUTC, 108), 1, 5) AS EventEndTime
			,E.MakePublic
			,R.RecurrenceCode AS [Repeat]
			,E.RecurrenceEndDate
			,E.IsRecurring
			,E.PK_OldEventApp
			,E.Latitude
			,E.Longitude
			,ED.Keywords
			,ISNULL(E.[Version], 1) AS [Version]
		FROM
			dbo.Event E WITH(NOLOCK)
		INNER JOIN
			dbo.EventLocaleDesc ED WITH(NOLOCK)
		ON
			E.PK_Event = ED.PK_Event
			AND ED.PK_Locale = @PK_Locale
		INNER JOIN
			dbo.Locales L WITH(NOLOCK)
		ON
			ED.PK_Locale = L.PK_Locale
		INNER JOIN
			dbo.EventCountry EC WITH(NOLOCK)
		ON
			E.PK_Event = EC.PK_Event
		INNER JOIN
			dbo.v_Countries C
		ON
			EC.PK_Country = C.nCountryID
		LEFT JOIN
			EventURL EU WITH(NOLOCK)
		ON
			E.PK_Event = EU.PK_Event
			AND EU.PK_Locale = @PK_Locale
			AND EU.PK_EventURLType = 1
		LEFT JOIN	
			dbo.EventImage EI WITH(NOLOCK)
		ON
			EI.PK_Event = E.PK_Event
		LEFT JOIN
			dbo.RecurrenceType R WITH(NOLOCK)
		ON
			E.PK_RecurrenceType = R.PK_RecurrenceType
		WHERE
			E.PK_Event = @PK_Event

		END TRY

		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage OUTPUT
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN 
		END CATCH
		END
		ELSE
		BEGIN

		BEGIN TRY

		SELECT DISTINCT E.PK_Event
			,ED.EventName
			,E.dStartUTC EventStartDate
			,E.dEndUTC EventEndDate
			,ED.EventAddress
			,ED.EventCity
			,ED.EventState
			,EC.PK_Country
			,C.sCountryCodeISO As EventCountry 
			,E.EventZipCode
			,E.EventApprovalStatus -- 0 = Under review; 1 = Approved; 2 = Rejected; 3 = Save As Draft
			,E.IsActive
			,E.IsPublish
			,E.DisplayStartDate DisplayStartDate
			,E.DisplayEndDate DisplayEndDate
			,ISNULL(ED.EventDisplayAddress,'') EventDisplayAddress
			,ISNULL(ED.EventTrainingLanguages, '') EventTrainingLanguages
			,ISNULL(ED.EventCostDetails, '') EventCostDetails
			,COALESCE(EU.Flyer, '') Flyer
 			,EU.PK_EventURL   
			,EU.EventURL
			,EI.PK_EventImage
			,EI.EventImageLocation
			,ISNULL(ED.EventDesc,'') EventDesc
			,ISNULL(ED.EventApprovalNotes, '') ApprovalNotes
			,ISNULL(ED.EventComments, '') Comments
			,L.LocaleCode
			,L.LanguageCountryRegion
			,E.CreatedDistributorID DistributorID
			,E.EventVenueName 
			,E.IsSocialNetworkEnabled
			,E.IsAlwaysVisible
			,E.IsPreRegistrationRequired
			,ED.EventSummary
			,@HasAccess HasAccess
			,CASE WHEN (E.IsActive = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
				  ELSE E.EventApprovalStatus END
			 AS [EventStatus]
			,SUBSTRING(CONVERT(NVARCHAR(30),E.dStartUTC, 108), 1, 5) AS EventStartTime
			,SUBSTRING(CONVERT(NVARCHAR(30),E.dEndUTC, 108), 1, 5) AS EventEndTime
			,E.MakePublic
			,R.RecurrenceCode AS [Repeat]
			,E.RecurrenceEndDate
			,E.IsRecurring
			,E.PK_OldEventApp
			,E.Latitude
			,E.Longitude
			,ISNULL(E.[Version], 1) AS [Version]
		FROM
			dbo.Event E WITH(NOLOCK)
		INNER JOIN
			dbo.EventLocaleDesc ED WITH(NOLOCK)
		ON
			E.PK_Event = ED.PK_Event
			AND ED.PK_Locale = @PK_DefaultLocale
		INNER JOIN
			dbo.Locales L WITH(NOLOCK)
		ON
			ED.PK_Locale = L.PK_Locale
			AND L.PK_Locale = @PK_DefaultLocale
		INNER JOIN
			dbo.EventCountry EC WITH(NOLOCK)
		ON
			E.PK_Event = EC.PK_Event
		INNER JOIN
			dbo.v_Countries C
		ON
			EC.PK_Country = C.nCountryID
		LEFT JOIN
			dbo.EventURL EU WITH(NOLOCK)
		ON
			E.PK_Event = EU.PK_Event
			AND EU.PK_Locale = @PK_DefaultLocale
			AND EU.PK_EventURLType = 1
		LEFT JOIN	
			dbo.EventImage EI WITH(NOLOCK)
		ON
			EI.PK_Event = E.PK_Event
		LEFT JOIN
			dbo.RecurrenceType R WITH(NOLOCK)
		ON
			E.PK_RecurrenceType = R.PK_RecurrenceType
		WHERE
			E.PK_Event = @PK_Event

		END TRY

		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage OUTPUT
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN 
		END CATCH
		END
		/* GET THE GUEST SPEAKERS FOR AN EVENT */

		BEGIN TRY

		SELECT
			 EGS.PK_Event
			,EGS.PK_EventGuestSpeaker
			,EGS.PK_GuestSpeaker
			,EGS.EventSpeakerName
			,EGS.EventSpeakerTitle
			,EGS.EventSpeakerPhone
			,EGS.EventSpeakerEmail 
			,EGS.EventSpeakerTeamLevel
		FROM
			dbo.EventGuestSpeakers EGS WITH(NOLOCK)
		WHERE
			EGS.PK_Event = @PK_Event
			
		END TRY

		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage OUTPUT
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN 
		END CATCH


		/* SELECT EVENT DETAILS FOR THE PASSED PK_EVENT */
		BEGIN TRY
		SELECT
			 E.PK_Event
			,EC.PK_EventCoordinatorDetail
			,E.CreatedDistributorID DistributorID
			,EC.CoordinatorName
			,EC.CoordinatorPhone
			,EC.CoordinatorEmail
			,EC.CoordinatorTitle 
			,EC.CoordinatorTeamLevel
			,EC.CoordinatorWebsite
		FROM
			dbo.Event E WITH(NOLOCK)
		LEFT JOIN 
			dbo.EventCoordinatorDetail EC WITH(NOLOCK)	 
		ON 
			EC.PK_Event = E.PK_Event
			AND
			--EC.CreatedDistributorID = COALESCE(@DistributorID,EC.CreatedDistributorID)		
			E.CreatedDistributorID = COALESCE(@DistributorID,E.CreatedDistributorID)		
		LEFT JOIN
			dbo.EventLocaleDesc ED  WITH(NOLOCK)
		ON
			E.PK_Event = ED.PK_Event
			AND
			ED.PK_Locale = @PK_Locale
		WHERE
			E.PK_Event = @PK_Event

		END TRY

		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage OUTPUT
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN 
		END CATCH

		/* GET THE EVENT SUBTYPES FOR THE PASSED EVENT */	
		BEGIN
		BEGIN TRY

		SELECT 
			 EST.PK_Event
			,EST.PK_EventSubType
			,ES.EventSubType
		FROM
			dbo.EventEventSubType EST WITH(NOLOCK)
		INNER JOIN
			dbo.EventSubTypes ES WITH(NOLOCK)
		ON 
			ES.PK_EventSubType = EST.PK_EventSubType
		AND
			EST.PK_Event = @PK_Event

		END TRY

		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage OUTPUT
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN 
		END CATCH
		END

		/* GET THE EVENT Audio FOR THE PASSED EVENT */ 
		BEGIN
		BEGIN TRY  
  
		SELECT   
		  EA.PK_EventAudio
		 ,EA.PK_Event  
		 ,EA.AudioName  
		 ,EA.AudioDesc  
		 ,EA.AudioHTML     
		FROM  
		 dbo.EventAudio EA WITH(NOLOCK)
		WHERE  
		 EA.PK_Event = @PK_Event  
  
		END TRY  
  
		BEGIN CATCH  
		 SET @Error = ERROR_NUMBER()  
		 SET @ErrorMessage = ERROR_MESSAGE()  
		 SET @StoredProcedure = ERROR_PROCEDURE()  
  
		 -- UPDATE ERROR LOG  
		 EXEC dbo.usp_Utility_UpdateErrorLog   
		   @ProcedureName = @StoredProcedure  
		   ,@ErrorNumber = 3  
		   ,@ErrorMessage = @ErrorMessage OUTPUT  
		   ,@SQLErrorCode = @Error  
		   ,@SQLErrorMsg = @ErrorMessage  
		 RETURN   
		END CATCH 
		END

		/* GET THE QUALIFIED COUNTRIES FOR THE PASSED EVENT */

		SELECT
			E.PK_Event
			,EDC.PK_Country
			,C.sCountryCodeISO As QualifiedCountryCode
		FROM
			dbo.Event E WITH(NOLOCK)
		LEFT JOIN
			dbo.EventDistributorCountry EDC WITH(NOLOCK)
		ON
			E.PK_Event = EDC.PK_Event	
		INNER JOIN
			dbo.v_Countries	C
		ON 
			EDC.PK_Country = C.nCountryID
		WHERE
			E.PK_Event = @PK_Event
	
		/*Retrieve the target markets*/
		SELECT
			 E.PK_Event
			,E.PK_EventDistributorCountryLocales
			,E.PK_Locale
			,L.LocaleCode
			,E.IsDefault
		FROM
			dbo.EventDistributorCountryLocales E WITH(NOLOCK)
		INNER JOIN
			dbo.Locales L WITH(NOLOCK)
		ON
			E.PK_Locale = L.PK_Locale
		WHERE
			E.PK_Event = @PK_Event

		/* GET THE EVENTDSTEAMTYPES FOR THE PASSED PK_Event */
		SELECT
			 ET.PK_Event
			,ET.PK_EventDSTeamType
			,ET.DSTeamTypeCode
			,COALESCE(DTD.DSTeamTypeDesc, DTL.DSTeamTypeDesc) [DSTeamTypeDesc]
		FROM
			dbo.EventDSTeamType ET WITH(NOLOCK)
		LEFT JOIN
			dbo.DSTeamTypeLocaleDesc DTD WITH(NOLOCK)--ACTUAL
		ON
			ET.DSTeamTypeCode = DTD.DSTeamTypeCode
		AND
			DTD.PK_Locale = @PK_Locale
		LEFT JOIN
			dbo.DSTeamTypeLocaleDesc DTL WITH(NOLOCK)--DEFAULT
		ON
			ET.DSTeamTypeCode = DTL.DSTeamTypeCode
		AND
			DTL.PK_Locale = 77
		WHERE
			ET.PK_Event = @PK_Event

		--IF @IsSeries = 0 and @IsRecurringChild = 1

		IF @IsParent = 1 

		BEGIN

		SELECT @PK_Event = MIN(PK_Event) FROM dbo.Event  WITH(NOLOCK) WHERE PK_OldEventApp = @PK_Event

		/* Retrieve the all child instances for a parent id passed */
		SELECT
			 E2.PK_Event
			 ,E2.PK_OldEventApp
			,E2.dStartUTC EventStartDate
			,E2.dEndUTC EventEndDate
			,E2.EventName
		FROM
			dbo.Event E WITH(NOLOCK) 
		INNER JOIN
			dbo.Event E1 WITH(NOLOCK)
			ON
				E.PK_Event = @PK_Event
				AND
				E.PK_OldEventApp = E1.PK_Event
		INNER JOIN
			dbo.Event E2 WITH(NOLOCK)
			ON
				E1.PK_Event = E2.PK_OldEventApp
		WHERE 
				@StartTime <= E2.dEndUTC
				AND 
				E2.PK_OldEventApp IS NOT NULL
				AND
				E2.PK_Event NOT IN (SELECT PK_Event FROM dbo.EventDeleteQueue  WITH(NOLOCK) WHERE PK_Event IS NOT NULL)
	

		END

		ELSE

		BEGIN

		/* Retrieve the sibling instance IDs for a child instance instance passed */
		SELECT
			 E2.PK_Event
			,E2.PK_OldEventApp
			,E2.dStartUTC EventStartDate
			,E2.dEndUTC EventEndDate
			,E2.EventName
		FROM
			dbo.Event E WITH(NOLOCK)
		INNER JOIN
			dbo.Event E1 WITH(NOLOCK)
			ON
				E.PK_Event = @PK_Event
				AND
				E.PK_OldEventApp = E1.PK_Event
		INNER JOIN
			dbo.Event E2 WITH(NOLOCK)
			ON
				E1.PK_Event = E2.PK_OldEventApp
		WHERE 
				@StartTime <= E2.dEndUTC
				AND 
				E2.PK_OldEventApp IS NOT NULL
				AND
				E2.PK_Event <> @PK_Event
				AND
				E2.PK_Event NOT IN (SELECT PK_Event FROM dbo.EventDeleteQueue  WITH(NOLOCK) WHERE PK_Event IS NOT NULL)
				AND
				E2.IsActive = 1
	
		END
	
		END
		-- UPDATE PROCESSING LOG
		EXEC dbo.usp_Utility_UpdateProcessingLog 
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime

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

