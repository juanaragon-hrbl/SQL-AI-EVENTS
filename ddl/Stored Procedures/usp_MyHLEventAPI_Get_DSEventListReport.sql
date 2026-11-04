CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_DSEventListReport]
		--Mandatory Parameters
		 @EventID nVARCHAR(4000) = NULL
		,@LocaleCode CHAR(5)
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_DSEventListReport

USE:	        
				DECLARE @e int, @em varchar(4000)
                 EXEC dbo.usp_MyHLEventAPI_Get_DSEventListReport
					     @EventID = '9876,9875,9874,9873,9869,9868,'
					    ,@LocaleCode = 'en-uk'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the Events and the statuses for events selected by the admin/distributor

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.EventLocaleDesc, dbo.EventCoordinatorDetail, dbo.Event

VERSIONS
----------------------------------------------------------------------------------
1	2013-09-12	SushmaA			Intitial
2	2019-08-14	NoeG			Refactor code (SRE)

******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	/* ***************** SonarQube check 91 and 92 - Output parameters should be assigned 
		SRE changes added
	*/

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/* DECLARE THE REQUIRED VARIABLES */
		DECLARE @PK_Locale INT
		DECLARE @HasAccess INT
		DECLARE @Len INT
		DECLARE @tbl TABLE(PK_Event INT)

		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode

		SET @Len = LEN(@EventID)

		WHILE @Len > 0
		BEGIN
			INSERT @tbl (PK_Event) SELECT LEFT(@EventID, CHARINDEX(',',@EventID)-1)
			SET @EventID = REPLACE(@EventID,LEFT(@EventID, CHARINDEX(',',@EventID)),'')
			SET @Len = LEN(@EventID)
		END

		--Retrieve all the EventGuestSpeaker information

		IF OBJECT_ID('tempdb..#EventGuestSpeakers') IS NOT NULL
			DROP TABLE #EventGuestSpeakers
    
		CREATE TABLE #EventGuestSpeakers
		(
			 PK_Event INT
			,EventSpeakerName1	nvarchar(200)
			,EventSpeakerTitle1 nvarchar(200)
			,EventSpeakerPhone1 varchar(20)
			,EventSpeakerEmail1 varchar(100)
			,EventSpeakerTeamLevel1 varchar(100)
			,EventSpeakerName2	nvarchar(200)
			,EventSpeakerTitle2 nvarchar(200)
			,EventSpeakerPhone2 varchar(20)
			,EventSpeakerEmail2 varchar(100)
			,EventSpeakerTeamLevel2 varchar(100)
		)

		INSERT INTO #EventGuestSpeakers(PK_Event, EventSpeakerName1, EventSpeakerTitle1, EventSpeakerPhone1, EventSpeakerEmail1, EventSpeakerTeamLevel1)
		SELECT A.PK_Event, A.EventSpeakerName, A.EventSpeakerTitle, A.EventSpeakerPhone, A.EventSpeakerEmail, A.EventSpeakerTeamLevel
		FROM
		(
			SELECT 
					EGS.PK_Event, EGS.EventSpeakerName, EGS.EventSpeakerTitle, EGS.EventSpeakerPhone, EGS.EventSpeakerEmail, EGS.EventSpeakerTeamLevel
					,PK_EventGuestSpeaker
					,ROW_NUMBER() OVER (PARTITION BY EGS.PK_Event ORDER BY EGS.PK_EventGuestSpeaker) AS RowNo
			FROM 
					dbo.EventGuestSpeakers EGS WITH (NOLOCK)
			INNER JOIN
				@tbl T
			ON
				EGS.PK_Event = T.PK_Event
		)A
		WHERE A.RowNo = 1


		UPDATE 
			E
		SET 
			E.EventSpeakerName2 = A.EventSpeakerName, 
			E.EventSpeakerTitle2 = A.EventSpeakerTitle, 
			E.EventSpeakerPhone2 = A.EventSpeakerPhone, 
			E.EventSpeakerEmail2 = A.EventSpeakerEmail, 
			E.EventSpeakerTeamLevel2 = A.EventSpeakerTeamLevel
		FROM
			#EventGuestSpeakers E
			INNER JOIN
			(
				SELECT 
						EGS.PK_Event, EGS.EventSpeakerName, EGS.EventSpeakerTitle, EGS.EventSpeakerPhone, EGS.EventSpeakerEmail, EGS.EventSpeakerTeamLevel
						,PK_EventGuestSpeaker
						,ROW_NUMBER() OVER (PARTITION BY EGS.PK_Event ORDER BY EGS.PK_EventGuestSpeaker) AS RowNo
				FROM 
						dbo.EventGuestSpeakers EGS WITH (NOLOCK)
				INNER JOIN
					@tbl T
				ON
					EGS.PK_Event = T.PK_Event
			)A ON E.PK_Event = A.PK_Event
		WHERE 
			A.RowNo = 2

		--Retrieve all the EventCoOrdinator information

		IF OBJECT_ID('tempdb..#EventCoOrdinator') IS NOT NULL
			DROP TABLE #EventCoOrdinator
    
		CREATE TABLE #EventCoOrdinator
		(
			 PK_Event INT
			,CreatedDistributorID varchar(10)
			,CoordinatorID1	nvarchar(10)
			,CoordinatorName1 nvarchar(500)
			,CoordinatorPhone1 varchar(200)
			,CoordinatorEmail1 varchar(400)
			,CoordinatorTitle1 varchar(200)
			,CoordinatorID2	nvarchar(10)
			,CoordinatorName2 nvarchar(500)
			,CoordinatorPhone2 varchar(200)
			,CoordinatorEmail2 varchar(400)
			,CoordinatorTitle2 varchar(200)
		)

		INSERT INTO #EventCoOrdinator(PK_Event, CreatedDistributorID, CoordinatorID1, CoordinatorName1, CoordinatorPhone1, CoordinatorEmail1, CoordinatorTitle1)
		SELECT A.PK_Event, A.CreatedDistributorID, A.CoordinatorID, A.CoordinatorName, A.CoordinatorPhone, A.CoordinatorEmail, A.CoordinatorTitle
		FROM
		(
			SELECT 
					ECD.PK_Event, E.CreatedDistributorID, ECD.CoordinatorID, ECD.CoordinatorName, ECD.CoordinatorPhone, ECD.CoordinatorEmail, ECD.CoordinatorTitle
					,ROW_NUMBER() OVER (PARTITION BY ECD.PK_Event ORDER BY ECD.PK_EventCoordinatorDetail) AS RowNo
			FROM 
					dbo.EventCoordinatorDetail ECD WITH (NOLOCK)
			INNER JOIN
				@tbl T
			ON
				ECD.PK_Event = T.PK_Event
			INNER JOIN	
				dbo.Event(NOLOCK) E
			ON
				ECD.PK_Event = E.PK_Event
		)A
		WHERE A.RowNo = 1

		UPDATE 
			E
		SET 
			E.CoordinatorID2 = A.CoordinatorID,
			E.CoordinatorName2 = A.CoordinatorName, 
			E.CoordinatorPhone2 = A.CoordinatorPhone, 
			E.CoordinatorEmail2 = A.CoordinatorEmail, 
			E.CoordinatorTitle2 = A.CoordinatorTitle 
		FROM
			#EventCoOrdinator E
			INNER JOIN
			(
				SELECT 
					ECD.PK_Event, E.CreatedDistributorID, ECD.CoordinatorID, ECD.CoordinatorName, ECD.CoordinatorPhone, ECD.CoordinatorEmail, ECD.CoordinatorTitle
					,ROW_NUMBER() OVER (PARTITION BY ECD.PK_Event ORDER BY ECD.PK_EventCoordinatorDetail) AS RowNo
			FROM 
					dbo.EventCoordinatorDetail ECD WITH (NOLOCK)
			INNER JOIN
				@tbl T
			ON
				ECD.PK_Event = T.PK_Event
			INNER JOIN		
				dbo.Event(NOLOCK) E
			ON
				ECD.PK_Event = E.PK_Event
			)A ON E.PK_Event = A.PK_Event
			AND E.CreatedDistributorID = A.CreatedDistributorID
		WHERE 
			A.RowNo = 2

		SELECT DISTINCT
			 E.PK_Event
			,E.EventName
			,E.EventVenueName
			,D.EventSubType [Type of Meeting]
			,COALESCE(ED.EventSummary, EDD.EventSummary) EventSummary
			,E.dStartUTC [EventStartDate]
			,E.dEndUTC [EventEndDate]
			,SUBSTRING(CONVERT(NVARCHAR(30),E.dStartUTC, 108), 1, 5) AS EventStartTime
			,SUBSTRING(CONVERT(NVARCHAR(30),E.dEndUTC, 108), 1, 5) AS EventEndTime
			,COALESCE(ED.EventDisplayAddress, EDD.EventDisplayAddress) Location 
			,E.EventCostDetails
			,E.EventDesc Agenda
			,E.IsActive
			,CASE WHEN E.PK_EventType = 3 AND (E.IsActive = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 0 THEN 0
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 1 THEN 1
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 2 THEN 2
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 3 THEN 3
				  WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4
				  WHEN E.PK_EventType IN (1,2) AND (E.IsPublish = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
				  END [EventStatus]
			,EGS.EventSpeakerName1
			,EGS.EventSpeakerTitle1
			,EGS.EventSpeakerTeamLevel1
			,EGS.EventSpeakerPhone1
			,EGS.EventSpeakerEmail1
			,EGS.EventSpeakerName2
			,EGS.EventSpeakerTitle2
			,EGS.EventSpeakerTeamLevel2
			,EGS.EventSpeakerPhone2
			,EGS.EventSpeakerEmail2
			,ECD.CoordinatorName1
			,ECD.CoordinatorPhone1
			,ECD.CoordinatorEmail1
			,ECD.CoordinatorTitle1
			,ECD.CoordinatorName2
			,ECD.CoordinatorPhone2
			,ECD.CoordinatorEmail2
			,ECD.CoordinatorTitle2
			,EMD.EstimatedDS
			,EMD.EstimatedNonDS
			,(EMD.EstimatedDS + EMD.EstimatedNonDS) [TotalEstimatedAttendees]
			,EMD.ActualDS
			,EMD.ActualNonDS
			,(EMD.ActualDS + EMD.ActualNonDS) [TotalActualAttendees]
			,EMD.PK_RefEvent
			,EMP.EstimatedDS [PreviousEventEstimatedDS]
			,EMP.EstimatedNonDS [PreviousEventEstimatedNonDS]
			,(EMP.EstimatedDS + EMP.EstimatedNonDS) [PreviousEventTotalEstimatedAttendees]
			,EMP.ActualDS [PreviousEventActualDS]
			,EMP.ActualNonDS [PreviousEventActualNonDS]
			,(EMP.ActualDS + EMP.ActualNonDS) [PreviousEventTotalActualAttendees]
	
		FROM
			dbo.Event E WITH (NOLOCK)
		INNER JOIN
			@tbl T
		ON 
			E.PK_Event = T.PK_Event
		INNER JOIN
		 (SELECT
			R.PK_Event
			,R.PK_EventSubType
			,COALESCE(ELD.EventSubTypeDesc , ESD.EventSubType) EventSubType
		  FROM
			(SELECT
				 EST.PK_Event
				,MIN(EST.PK_EventSubType) PK_EventSubType
			 FROM
				dbo.EventEventSubType EST WITH (NOLOCK)	 
			 GROUP BY
				EST.PK_Event
			 )R	
			 INNER JOIN
				dbo.EventSubTypes ESD WITH (NOLOCK)
			 ON
				R.PK_EventSubType = ESD.PK_EventSubType
			 LEFT JOIN
				dbo.EventSubTypeLocaleDesc ELD WITH (NOLOCK)
			 ON 
					ESD.PK_EventSubType = ELD.PK_EventSubType
				AND
					ELD.PK_Locale = @PK_Locale
		) D
		ON
			D.PK_Event = E.PK_Event
		LEFT JOIN
			dbo.EventLocaleDesc ED WITH (NOLOCK)
		ON
			E.PK_Event = ED.PK_Event
		AND
			ED.PK_Locale = @PK_Locale
		LEFT JOIN
			dbo.EventLocaleDesc EDD WITH (NOLOCK)
		ON
			E.PK_Event = EDD.PK_Event
		AND
			EDD.PK_Locale = EDD.PK_DefaultLocale
		LEFT JOIN
			#EventGuestSpeakers EGS
		ON 
			E.PK_Event = EGS.PK_Event
		LEFT JOIN
			#EventCoOrdinator ECD
		ON
			E.PK_Event = ECD.PK_Event
		LEFT JOIN
			dbo.EventManageDetails EMD WITH (NOLOCK)
		ON
			E.PK_Event = EMD.PK_Event
		LEFT JOIN
			dbo.EventManageDetails EMP WITH (NOLOCK)
		ON
			EMD.PK_RefEvent = EMP.PK_Event
		ORDER BY
			 [EventStartDate] DESC
			,E.EventName

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

