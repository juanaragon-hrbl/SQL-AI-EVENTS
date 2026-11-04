CREATE PROCEDURE [dbo].[usp_EventAPI_Upd_DistributorSubEventRegistration]
-- REQUIRED
@DistributorID varchar(10)
,@EventID int
,@SubEventID nvarchar(500)
,@Qualified bit = 1
,@UserID varchar(50)
-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************

OBJECT: dbo.usp_EventAPI_Upd_DistributorSubEventRegistration
USE: 
			DECLARE @e int, @em varchar(4000)
			EXEC usp_EventAPI_Upd_DistributorSubEventRegistration 
					@DistributorID = '09674037'
					, @EventID=21, @SubEventID = 41 
					, @Qualified = 1
					, @UserID = 'SandhyaP'
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION: Insert/Delete the record in SubEventregistration based on the Qualification Overwrites during Registration
NOTES: 
DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent
VERSIONS
--------------------------------------------------------------------
1 2009-01-22	SandhyaP		Initial
2 2015-11-02	IniU			Added code to maintain subeventqualifier in QRCode database 
3 2019-09-05	NoeG			SRE template applied
4 2019-10-30	NoeG			SRE Hardcode changed
5 2022-01-05	Jairli			Sync CEA Model Qualifications
6 2022-09-09	alejandramed	Removing EventQRCode references
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE()
		,@ValidDate DATETIME = '2049-12-31'	

SELECT @Error = 0, @ErrorMessage = '';

DECLARE @PK_Distributor int
DECLARE @PK_SubEvent int
DECLARE @PK_EventsRegistration int
DECLARE @PK_SubEventQualifier int
DECLARE @SubEventQualCount int
DECLARE @SubEventDisQualCount int

/******************************************************************************
Check if the Distributor Exists both in Distributor and Temp Distributor tables
******************************************************************************/

IF NOT EXISTS (SELECT sDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
UNION
SELECT DistributorID FROM dbo.TempDistributors T WITH (NOLOCK) WHERE DistributorID = @DistributorID AND
   NOT EXISTS (SELECT 1 FROM dbo.v_Distributor D WHERE T.DistributorID = D.sDistributorID))
BEGIN
SET @Error = 8

-- Update ErrorLog
EXEC dbo.usp_Utility_UpdateErrorLog 
@ProcedureName = @StoredProcedure 
,@ErrorNumber = @Error
,@ErrorMessage = @ErrorMessage OUTPUT
RETURN 
END

/******************************************************************************
Check if the Event Exists
******************************************************************************/

IF NOT EXISTS (SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @EventID)
BEGIN
SET @Error = 169

-- Update ErrorLog
EXEC dbo.usp_Utility_UpdateErrorLog 
@ProcedureName = @StoredProcedure 
,@ErrorNumber = @Error
,@ErrorMessage = @ErrorMessage OUTPUT
RETURN 
END

DECLARE @STRSQL NVARCHAR(4000)


--SET @EVENTID = 23
--SET @SUBEVENTID = '1,2,3,4'
/******************************************************************************
Enclose passed subevent(s) for IN CLAUSE usage
******************************************************************************/
SET @SUBEVENTID = '(' + @SUBEVENTID + ')'
--SET @DistributorID = '07088868'

/******************************************************************************
create and insert matrix of all subevents for the event with distributor ID
******************************************************************************/

BEGIN TRY

	IF OBJECT_ID('TEMPDB..#DSQualMatrix') IS NOT NULL DROP TABLE #DSQualMatrix 

	SELECT DISTINCT 
		SE.PK_SubEvent
		,SE.SubEventNumber
		,@DistributorID DistributorID
	INTO
		#DSQualMatrix
	FROM 
		dbo.SubEvent SE WITH (NOLOCK) 
	WHERE
		SE.PK_Event = @EventID

	/******************************************************************************
	Validate if distributor qualified or not for all subevents for the event
	******************************************************************************/

	IF OBJECT_ID('tempdb..##qualifiers') IS NOT NULL DROP TABLE ##qualifiers

	SET @STRSQL = '
	SELECT 
	DS.PK_SubEvent
	,DS.SubEventNumber
	,DS.DistributorID
	,CASE WHEN DS.PK_SubEvent = SQ.PK_SubEvent AND DS.DistributorID = SQ.DistributorID THEN 1 ELSE 0 END Qualified
	INTO 
	##Qualifiers
	FROM 
	#DSQualMatrix DS
	LEFT JOIN
	(SELECT PK_SubEvent, DistributorID from SUBEVENTQUALIFIER WITH (NOLOCK) WHERE PK_Event = ' + LTRIM(STR(@EventID)) + ' AND RemovedUTC = ''' + CONVERT(varchar,@ValidDate) + ''') SQ  
	ON 
	DS.PK_SubEvent = SQ.PK_SubEvent AND DS.DistributorID = SQ.DistributorID

	ORDER BY 
	DS.PK_SubEvent'

	EXEC SP_EXECUTESQL @STRSQL  /* ln 140 added removedutc - sandhyap */

	/******************************************************************************
	Now set qualified to 1 for subevents passed in
	******************************************************************************/

	SET @STRSQL = '
	UPDATE Q
	SET 
	Qualified = 1
	FROM 
	##qualifiers Q
	WHERE
	SubEventNumber IN ' + @SUBEVENTID

	EXEC SP_EXECUTESQL @STRSQL

	/******************************************************************************
	set qualified for the rest of the subevents to 1
	******************************************************************************/

	SET @STRSQL = '
	UPDATE Q
	SET 
	Qualified = 0
	FROM 
	##qualifiers Q
	WHERE
	SubEventNumber NOT IN ' + @SUBEVENTID

	EXEC SP_EXECUTESQL @STRSQL

	/******************************************************************************
	get nDistributorID for distributor
	******************************************************************************/

	SELECT @PK_Distributor = D.nDistributorID FROM 
	(SELECT nDistributorID,sDistributorID  FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
	UNION
	SELECT PK_Temp AS nDistributorID,DistributorID AS sDistributorID FROM dbo.TempDistributors T WITH (NOLOCK) WHERE DistributorID = @DistributorID
	AND NOT EXISTS (SELECT 1 FROM dbo.v_Distributor D WHERE T.DistributorID = D.sDistributorID)
	) D 
	WHERE D.sDistributorID = @DistributorID

	/************************************************************************************************************************
	create records in subeventqualifier for distributor for all qualified subevents that are not already there 
	************************************************************************************************************************/

	INSERT INTO 
	dbo.SubEventQualifier 
	(
	PK_Event
	,PK_SubEvent
	,PK_Distributor
	,DistributorID
	,QualDate
	,AddedUTC
	,RemovedUTC
	,IsManualOverride
	,IsDeleted
	,IsDNR
	,IsType23
	,Qualified
	)
	SELECT
	@EventID
	,Q.PK_SubEvent
	,@PK_Distributor
	,@DistributorID
	,@StartTime
	,@StartTime
	,@ValidDate
	,1
	,0
	,0
	,0
	,1
	FROM 
	##qualifiers Q
	WHERE NOT EXISTS (SELECT 1 FROM dbo.SubEventQualifier S WITH (NOLOCK) 
						WHERE	S.PK_EVENT = @EventID
								AND S.DistributorID = @DistributorID 
								AND S.PK_SubEvent = Q.PK_SubEvent 
								AND S.DistributorID = Q.DistributorID)
	AND Q.Qualified = 1

	/**********************************************************************************
	set qualified to 0 for all subevents previously qualified but no longer qualified
	**********************************************************************************/
 
	UPDATE S
	SET Qualified = 0
		,IsManualOverride = 1
		,ModifiedDateUTC = @StartTime
		,ModifiedBy = @UserID
		,RemovedUTC = GETUTCDATE()
	FROM 
		dbo.SubEventQualifier S
	WHERE EXISTS (SELECT Q.PK_SubEvent FROM ##qualifiers Q 
							WHERE S.PK_SubEvent = Q.PK_SubEvent 
							AND S.DistributorID = Q.DistributorID 
							AND Q.Qualified=0)
	AND S.Qualified = 1

	/**********************************************************************************
	set qualified to 1 for all subevents previously not qualified but now qualified
	**********************************************************************************/

	UPDATE S
	SET Qualified = 1
		  ,IsManualOverride = 1
		  ,ModifiedDateUTC = @StartTime
		  ,ModifiedBy = @UserID
		  ,RemovedUTC = @ValidDate
	FROM 
		  dbo.SubEventQualifier S
	INNER JOIN 
		  ##qualifiers Q 
	ON      S.PK_SubEvent = Q.PK_SubEvent 
		  AND S.DistributorID = Q.DistributorID 
		  AND Q.Qualified=1
	INNER JOIN
		  (SELECT PK_SubEvent, MAX(PK_SubEventQualifier) AS PK_SubEventQualifier FROM dbo.SubEventQualifier WITH (NOLOCK) 
		  WHERE RemovedUTC <> @ValidDate AND DistributorID = @DistributorID
		  GROUP BY PK_SubEvent  
				) SQ
	ON
		  S.PK_SubEventQualifier = SQ.PK_SubEventQualifier                  
	WHERE (S.Qualified = 0 OR (ISNULL(S.RemovedUTC,@ValidDate) <> @ValidDate AND S.Qualified = 1)) 
	AND NOT EXISTS (SELECT 1 FROM dbo.SubEventQualifier EQ WITH (NOLOCK) WHERE EQ.PK_Event = S.PK_Event 
							AND EQ.PK_SubEvent = S.PK_SubEvent AND EQ.PK_Distributor = S.PK_Distributor 
							AND EQ.RemovedUTC = @ValidDate)

	/********************************************************************************************************************
	If Qualified flag passed is 1, check that Distributor registered for the event and get unique event registration PK
	********************************************************************************************************************/
	IF @Qualified = 1
	BEGIN
		IF EXISTS (SELECT PK_EventsRegistration FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_Distributor = @PK_Distributor AND PK_Event = @EventID)
		BEGIN
			SELECT @PK_EventsRegistration = PK_EventsRegistration FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_Distributor = @PK_Distributor AND PK_Event = @EventID

	/**************************************************************************************************************************************************
	Check if Distributor qualified for any subevent for the event and insert valid subeevent regsitration record where it does not exist already
	***************************************************************************************************************************************************/
			SELECT @SubEventQualCount = COUNT(1) FROM dbo.SubEventQualifier WITH (NOLOCK) WHERE PK_Distributor = @PK_Distributor AND PK_Event = @EventID AND Qualified = 1 AND RemovedUTC = @ValidDate
			IF @SubEventQualCount > 0
			BEGIN
				INSERT INTO [dbo].[SubEventRegistration]
					([CreatedBy]
					,[ModifiedBy]
					,[PK_EventsRegistration]
					,[PK_SubEventQualifier]
					,[Registered])
					SELECT
					@UserID
					,@UserID
					,R.PK_EventsRegistration
					,Q.PK_SubEventQualifier
					,@Qualified
				FROM
					dbo.SubEventQualifier Q WITH (NOLOCK) 
				INNER JOIN
					dbo.EventsRegistration R WITH (NOLOCK) 
				ON
					Q.PK_Distributor = R.PK_Distributor
					AND Q.PK_Event = R.PK_Event
				WHERE
					Q.PK_Distributor = @PK_Distributor
					AND Q.PK_Event = @EventID
					AND Q.Qualified = 1
									AND Q.RemovedUTC = @ValidDate
					AND NOT EXISTS (SELECT 1 FROM dbo.SubEventRegistration SR WITH (NOLOCK) 
										WHERE SR.PK_SubEventQualifier = Q.PK_SubEventQualifier
										AND	  SR.PK_EventsRegistration = R.PK_EventsRegistration
										AND   SR.Registered = 1)

	/*********************************************************************************************************************************************************
	Subevent registration record may exist but was set to not registered. For such records, turn the records back to registered for the appropriate subevents
	*********************************************************************************************************************************************************/
				UPDATE 
					SR
				SET 
					SR.Registered = 1
					,SR.ModifiedBY = @UserID
					,SR.ModifiedDateUTC = @StartTime
				FROM
					dbo.SubEventRegistration SR
				INNER JOIN
					dbo.EventsRegistration R WITH (NOLOCK) 
				ON
					SR.PK_EventsRegistration = R.PK_EventsRegistration
				INNER JOIN
					dbo.SubEventQualifier Q WITH (NOLOCK) 
				ON
					SR.PK_SubEventQualifier = Q.PK_SubEventQualifier
				WHERE
					Q.PK_Distributor = @PK_Distributor
					AND Q.PK_Event = @EventID
					AND Q.Qualified = 1
					AND EXISTS (SELECT 1 FROM dbo.SubEventRegistration SR WITH (NOLOCK) 
										WHERE SR.PK_SubEventQualifier = Q.PK_SubEventQualifier
										AND	  SR.PK_EventsRegistration = R.PK_EventsRegistration
										AND   SR.Registered = 0)

			END
		END

	/**************************************************************************************************************************************************
	Check if Distributor no longer qualifies for any subevent but had already registered. Set such subevent registration records to 0 if no attendance 
	***************************************************************************************************************************************************/
		SELECT @SubEventDisQualCount = COUNT(1) FROM dbo.SubEventQualifier WITH (NOLOCK) WHERE PK_Distributor = @PK_Distributor AND PK_Event = @EventID AND Qualified = 0
		IF @SubEventDisQualCount > 0
		BEGIN
				/*
				UPDATE 
					SR
				SET 
					SR.Registered = 0
					,SR.ModifiedBY = @UserID
					,SR.ModifiedDateUTC = @StartTime
				*/
				DELETE
					SR
				FROM
					dbo.SubEventRegistration SR WITH (NOLOCK) 
				INNER JOIN
					dbo.EventsRegistration R WITH (NOLOCK) 
				ON
					SR.PK_EventsRegistration = R.PK_EventsRegistration
				INNER JOIN
					dbo.SubEventQualifier Q WITH (NOLOCK) 
				ON
					SR.PK_SubEventQualifier = Q.PK_SubEventQualifier
				WHERE
					Q.PK_Distributor = @PK_Distributor
					AND Q.PK_Event = @EventID
					AND Q.Qualified = 0
					AND NOT EXISTS (SELECT 1 FROM dbo.SubEventAttendance SA WITH (NOLOCK) WHERE SA.PK_SubEventRegistration = SR.PK_SubEventRegistration)
		END
			

	ELSE IF @Qualified = 0

	/**************************************************************************************************************************************************
	Check if Distributor no longer qualifies for any subevent but had already registered. Set such subevent registration records to 0 if no attendance 
	***************************************************************************************************************************************************/
		/*
		UPDATE 
			SR
		SET 
			SR.Registered = 0
			,SR.ModifiedBY = @UserID
			,SR.ModifiedDateUTC = @StartTime
		*/
		DELETE
			SR 
		FROM
			dbo.SubEventRegistration SR WITH (NOLOCK) 
		INNER JOIN
			dbo.EventsRegistration R WITH (NOLOCK) 
		ON
			SR.PK_EventsRegistration = R.PK_EventsRegistration
		INNER JOIN
			dbo.SubEventQualifier Q WITH (NOLOCK) 
		ON
			SR.PK_SubEventQualifier = Q.PK_SubEventQualifier
		WHERE
			Q.PK_Distributor = @PK_Distributor
			AND Q.PK_Event = @EventID
			AND Q.Qualified = 0
			AND NOT EXISTS (SELECT 1 FROM dbo.SubEventAttendance SA WITH (NOLOCK) WHERE SA.PK_SubEventRegistration = SR.PK_SubEventRegistration)

	END

	/**************************************************************************************************************************************************
	Sync CEA Table Qualifications 
	***************************************************************************************************************************************************/
	EXEC z_evp_cea_maintenance.spcea_Event_UpdateSubEventQualifier @DistributorID,  @EventID

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


/******************************************************************************
end procedure
******************************************************************************/

END
GO

