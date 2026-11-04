CREATE PROCEDURE [dbo].[usp_MYHLEventAPI_Home_TrackYourProgress]
-- Mandatory
@DistributorID VARCHAR(20), 
@Locale VARCHAR(5) 
-- Error Parameters
,@Error	INT = 0 OUTPUT
,@ErrorMessage VARCHAR(4000) = '' OUTPUT
-- QA/DEV
,@IsDevQA BIT = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MYHLEventAPI_Home_TrackYourProgress

USE:	        Declare @e int, @em varchar(20) 
				EXEC dbo.usp_MYHLEventAPI_Home_TrackYourProgress
						-- Mandatory
					 	 @DistributorID = '2222222222'
						 ,@Locale = 'en-US'

DESCRIPTION:	Landing Page -> Track Your Progress & Landing Page -> Track your Downline Progress
				This will check whether or not to enable the links above when the member logs in. 

VERSIONS
----------------------------------------------------------------------------------
	1.0.0	2016-06-28		SandhyaP		Landing Page
	1.1.0	2019-10-17		puertac			SRE Implementation 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON		
	
-- DECLARE THE LOCAL VARIABLES 

DECLARE @PK_Locale INT
DECLARE @DSTeam VARCHAR(10)
DECLARE @DateFrom SMALLDATETIME 
DECLARE @DateTo SMALLDATETIME
DECLARE @CurrentDate DATE = CONVERT(DATE,GETUTCDATE(), 110)
DECLARE @PK_Distributor INT
DECLARE @QualStartDate SMALLDATETIME = CONVERT(DATE,GETUTCDATE(), 110)
DECLARE @QualEndDate SMALLDATETIME = DATEADD(MM , -11, @QualStartDate)
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
			--- SET THE VARIABLES 
			SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @Locale
			SET @DateFrom = GETUTCDATE()
			SET @DateTo = '2049-12-31'
			SELECT @DSTeam = sSubTeam FROM dbo.v_Distributor WHERE sDistributorid = @DistributorID
			SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor where sDistributorid = @DistributorID
						
			/******************************************************************************
				Finanical Data for the Members
			******************************************************************************/

			/* GET THE 12 MONTHS VOLUME DETAILS FOR THE DS ID THAT WAS PASSED */
			If object_id('tempdb..#Vol') IS NOT NULL Drop Table #Vol
			Create Table #Vol
			(
				PK_Distributor Int, 
				dRoyaltyMonth VARCHAR(12), 
				PV Money, 
				GV Money, 
				PPV Money, 
				TV Money, 
				RO Money, 
				MainRO Money, 
				OV Money, 
				DLV Money, 
				PB Money
			)

			If @QualStartDate IS NOT NULL AND @QualEndDate IS NOT NULL AND @PK_Distributor IS NOT NULL
			Insert Into #Vol
			SELECT
				nDistributorID PK_Distributor
				,SUBSTRING(CONVERT(VARCHAR(12), dRoyaltyMonth , 106),1,2) + '-' + SUBSTRING(CONVERT(VARCHAR(12), dRoyaltyMonth , 106),4,3) + '-' + SUBSTRING(CONVERT(VARCHAR(12), dRoyaltyMonth , 106),8,5) dRoyaltyMonth
				,ISNULL(mPersonalVolume,0) AS PV
				,ISNULL(mGroupVolume,0) AS GV
				,ISNULL(mPersonalPurchaseVolume,0) AS PPV
				,ISNULL(mVolumePoints,0) AS TV
				,ISNULL(mRoyaltyOverrides,0) AS RO
				,ISNULL(mMainRoyaltyOverrides,0) AS MainRO
				,ISNULL(mOrganizationalVolume,0) OV
				,ISNULL(mDownlineVolume,0) AS DLV
				,ISNULL(mProductionBonus,0) AS PB
			FROM
				dbo.v_aggFQS_ID AG WITH (NOLOCK)
			WHERE
				dRoyaltyMonth BETWEEN @QualStartDate AND @QualEndDate
			AND
				nDistributorID = @PK_Distributor

	
			/* GET THE 12 MONTHS VOLUME DETAILS FOR THE DS ID THAT WAS PASSED */
			SELECT  PK_Distributor
				   ,dRoyaltyMonth As RoyaltyMonth
				   ,PV
				   ,GV
				   ,PPV
				   ,TV
				   ,RO + MainRO AS RO
				   ,OV
				   ,DLV
				   ,PB
			FROM
				#Vol A
			ORDER BY
				dRoyaltyMonth DESC


			/******************************************************************************
				Get All Active Events to show on track your progress page
			******************************************************************************/


			SELECT DISTINCT
				 E.PK_Event
				,ISNULL(EL.EventName, ELD.EventName)EventName
				,ISNULL(EL.EventDesc, ELD.EventName)EventDesc
				,ISNULL(E.dStartUTC, '') EventStartDate
				,ISNULL(E.dEndUTC, '') EventEndDate
				,E.PK_EventType
				,ISNULL(EL.EventVenuename, ELD.EventVenuename) EventVenueName
				,ISNULL(EL.EventDisplayAddress, ELD.EventDisplayAddress) EventDisplayAddress
				,ISNULL(EL.EventAddress, ELD.EventAddress) EventAddress
				,ISNULL(EL.EventCity, ELD.EventCity) EventCity
				,ISNULL(EL.EventState, ELD.EventState) EventState
				,ISNULL(E.EventZipCode , '') EventZipCode
				,VC.sCountryCodeISO EventCountry
				,VC.sCountryName EventCountryName  
				,COALESCE (CASE WHEN EIL.EventImageLocation = '' THEN NULL ELSE EIL.EventImageLocation END
						  ,CASE WHEN EID.EventImageLocation = '' THEN NULL ELSE EID.EventImageLocation END
						  ,EI.EventImageLocation) EventLogo
				,E.Latitude
				,E.Longitude
				,E.CanDisplayTicketDetails
				,E.IsTicketforQualifiedDS 
				,E.TicketThirdPartyLink  IsThirdPartyTicketPurchaseLink
				,EUT.EventURL TicketURL
				,EILB.EventImageLocation EventBanner -- Banner displayed in feature section
				,D.Qualified IsQualified
				,T.Tickets
				,E.QualPeriodStart	
				,E.QualPeriodEnd
			Into #MasterEvents	
			FROM dbo.Event E WITH (NOLOCK)
			INNER JOIN 
				dbo.EventCountry EC WITH (NOLOCK) 
			ON 
				E.PK_Event = EC.PK_Event
			INNER JOIN 
				dbo.v_Countries VC WITH (NOLOCK)
			ON 
				EC.PK_Country = VC.nCountryID
			INNER JOIN 
				dbo.EventDistributorCountryLocales EDCL WITH (NOLOCK)
			ON 
				E.PK_Event = EDCL.PK_Event
				AND
				EDCL.PK_Locale = @PK_Locale
			LEFT JOIN 
				dbo.EventLocaleDesc EL WITH (NOLOCK)
			ON 
				E.PK_Event = EL.PK_Event 
			AND 
				EL.PK_Locale = @PK_Locale	
			LEFT JOIN 
				dbo.EventLocaleDesc ELD WITH (NOLOCK)
			ON 
				E.PK_Event = ELD.PK_Event 
			AND 
				ELD.PK_Locale = E.PK_DefaultLocale 	
			INNER JOIN
				(
					SELECT A.PK_Event, A.TeamOrder, DST.DSTeamTypeCode
					FROM (
					SELECT A.PK_Event 
						,MAX(B.TeamOrder) TeamOrder
					FROM dbo.EventDSteamType A WITH (NOLOCK)
					INNER JOIN dbo.DSTeamType B WITH (NOLOCK)
					ON A.DSTeamTypeCode = B.DSTeamTypeCode
					WHERE B.DSTeamTypeCode <> 'RC'
					GROUP BY A.PK_Event
					) A
					INNER JOIN
						dbo.DSTeamType DST WITH (NOLOCK)
					ON
						A.TeamOrder = DST.TeamOrder
				) C
			ON 
				E.PK_Event = C.PK_Event
			INNER JOIN (Select Top 1 DSTeamTypeCode, TeamOrder FROM dbo.DSTeamType WITH (NOLOCK) WHERE DSTeamTypeCode = COALESCE(@DSTeam,'FC')) DT
			ON 
				C.TeamOrder >= DT.TeamOrder
			LEFT JOIN
			dbo.EventImage EI WITH (NOLOCK)
			ON
				E.PK_Event = EI.PK_Event
			AND
				EI.PK_EventImageType = 1		
			LEFT JOIN
			dbo.EventImageLocaleDesc EIL WITH (NOLOCK)
			ON
				EI.PK_Event = EIL.PK_Event
			AND
				EI.PK_EventImage = EIL.PK_EventImage
			AND
				EIL.PK_Locale = @PK_Locale
			LEFT JOIN
			dbo.EventImageLocaleDesc EID WITH (NOLOCK)
			ON
				EI.PK_Event = EID.PK_Event
			AND
				EI.PK_EventImage = EID.PK_EventImage
			AND
				EID.PK_Locale = E.PK_DefaultLocale	
			LEFT JOIN
			dbo.EventURL EUT WITH (NOLOCK)
			ON 		
				E.PK_Event = EUT.PK_Event
			AND
				EUT.PK_EventURLType = 5		
			AND
				EUT.PK_Locale = @PK_Locale	
			LEFT JOIN
			dbo.EventImage EIB WITH (NOLOCK)
			ON
				E.PK_Event = EIB.PK_Event
			AND
				EIB.PK_EventImageType = 2
			LEFT JOIN
			dbo.EventImageLocaleDesc EILB WITH (NOLOCK)
			ON
				EIB.PK_Event = EILB.PK_Event
			AND
				EIB.PK_EventImage = EILB.PK_EventImage
			AND
				EILB.PK_Locale = @PK_Locale		
			LEFT JOIN
				(SELECT DISTINCT SQ.PK_Event, DistributorID, SQ.Qualified
				 FROM dbo.SubEventQualifier SQ WITH (NOLOCK) 
				 INNER JOIN dbo.SubEvent SE WITH (NOLOCK) ON SQ.PK_SubEvent = SE.PK_SubEvent
				 WHERE SQ.PK_Distributor = @PK_Distributor AND SQ.RemovedUTC = '12-31-2049' AND SE.IsMainEventQual = 1)D
			ON
				E.PK_Event = D.PK_Event	
			LEFT JOIN
				(SELECT ETA.PK_Event, COUNT(1) Tickets
				 FROM dbo.EventTicketAssignment ETA WITH (NOLOCK) 
				 WHERE ETA.PK_ToDistributor = @PK_Distributor 
				 GROUP BY ETA.PK_Event) T
			ON
				E.PK_Event = T.PK_Event			
			WHERE
			(E.DisplayStartDate BETWEEN @DateFrom AND @DateTo OR E.DisplayEndDate BETWEEN @DateFrom AND @DateTo OR @DateFrom BETWEEN E.DisplayStartDate AND E.DisplayEndDate) 
			AND
			@CurrentDate BETWEEN DisplayStartDate AND (DisplayEndDate+1)
			AND (CASE WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= @CurrentDate THEN 4 END) IN (4) /* Published */



			/******************************************************************************
				All Active Corp Events based on Team level visibility and locale logged in
			******************************************************************************/

			SELECT EventName
				  ,EventDesc
				  ,EventStartDate
				  ,EventEndDate
				  ,EventVenueName
				  ,EventDisplayAddress
				  ,EventAddress
				  ,EventCity
				  ,EventState
				  ,EventZipCode
				  ,EventCountry
				  ,EventCountryName
				  ,EventLogo
				  ,IsThirdPartyTicketPurchaseLink
				  ,TicketURL
				  ,EventBanner
				  ,IsQualified
				  ,Tickets
			FROM #MasterEvents
			ORDER BY PK_Event



			/******************************************************************************
				All Active Events and Subevents and member qual status
			******************************************************************************/

			SELECT
				 SE.PK_SubEvent
				,SE.PK_Event
				,COALESCE(CASE WHEN SD.SubEventQualDesc = '' then null ELSE SD.SubEventQualDesc END
					, SE.SubEventName) SubEventName
				,ISNULL(SQ.Qualified,0) Qualified
				,COALESCE(CASE WHEN SD.SubEventQualDesc = '' then null ELSE SD.SubEventQualDesc END
						,SE.SubEventName) [SubEventQualDesc]
				,CASE WHEN SD.QualDesc = '' THEN NULL ELSE SD.QualDesc END [QualificiationDesc]
				,SE.PK_SubEventGroup
				,SEG.SubEventGroup [SubEventGroup]
				,SEE.Icon
				,SEE.Color
			FROM
			#MasterEvents M
			INNER JOIN
				dbo.SubEvent SE (NOLOCK)
			ON
				M.PK_Event = SE.PK_Event	
			LEFT JOIN
				dbo.SubeventLocaleDesc SD (NOLOCK)
			ON
				SE.PK_Event = SD.PK_Event
				AND SE.PK_SubEvent = SD.PK_Subevent
				AND SD.PK_Locale = @PK_Locale
			LEFT JOIN
				dbo.SubEventQualifier SQ (NOLOCK)
			ON
				SQ.PK_Event = SE.PK_Event
				AND SQ.PK_SubEvent = SE.PK_SubEvent
				AND SQ.RemovedUTC = '12-31-2049'
				AND SQ.PK_Distributor = @PK_Distributor
			LEFT JOIN
				  dbo.SubEventGroup(NOLOCK) SEG
			ON
				  SE.PK_SubEventGroup = SEG.PK_SubEventGroup
			LEFT JOIN
				  dbo.SubEventExtn(NOLOCK) SEE
			ON
				  SE.PK_SubEvent = SEE.PK_SubEvent	
				  AND
				  SE.PK_Event = SEE.PK_Event
			WHERE
				SE.IsTrackingVisible = 1
			ORDER BY
				SE.PK_Event, SE.SubEventNumber, SEG.DisplayOrder
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

END