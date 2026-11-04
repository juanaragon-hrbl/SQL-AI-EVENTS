
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_BreakoutSessionRegistrationStatus]
		@DistributorID VARCHAR(20)  
		,@EventID INT 
		,@SessionID INT = NULL 

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventAPI_Get_BreakoutSessionRegistrationStatus]
	
	USE:			
			DECLARE @e int, @em varchar(4000)

			EXEC [dbo].[usp_EventAPI_Get_BreakoutSessionRegistrationStatus]
				@DistributorID = '38854317'  
				,@EventID = 59881
				,@SessionID = 25111--NULL 

				,@IsDevQA = 0
				,@Error = @e output
				,@ErrorMessage = @em output

			SELECT @e AS [Error], @em AS [ErrorMessage]

	DESCRIPTION: Get Breakout Session Registration Status Info by @DistributorID, @EventID and optional @SessionID

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-01-14		NoeG		Initial
	1.0.1		2019-01-22		NoeG		- Changes to add the PreferredLocale Column
    1.0.2		2019-01-28		NoeG		- Changes to get Qualifications Information considering the Override Qualification
	1.0.3		2019-09-05		NoeG		SRE template applied
	1.0.4		2019-10-30		NoeG		SRE Hardcode changed
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'	

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT  se.PK_Event, se.PK_SubEvent BreakoutSessionID
				, isnull(SUM(case when BSA.IsOwner = 1 then 1 end),0) as IsMainRegistered
				, isnull(SUM(case when BSA.IsOwner = 0 then 1 end),0) as IsPartnerRegistered
				, case when isnull(MAX(SEQ.Qualifications),0) = 0 
						then NULL 
						else case when (MAX(cast(Override_IsQualified as int)) is null and MAX(DSQ.SubEventsNotQualifiedCounter) > 0) OR MAX(cast(Override_IsQualified as int)) = 0
								then 0 
								else 1 
							end 						 
					end as IsQualified

				, case when MAX(isnull(cast(sevx.ManageLanguages as int),0)) = 0
						then NULL 
						else isnull(MAX(BSA.PreferredLanguage),'')
					end as PreferredLocale
		FROM	SubEvent se WITH (NOLOCK)
				LEFT JOIN dbo.[SubEventExtn] sevx WITH (NOLOCK)
					on se.PK_Event = sevx.pk_event 
						AND se.PK_SubEvent = sevx.PK_SubEvent
				LEFT JOIN dbo.[BreakoutSessionAttendees] BSA WITH (NOLOCK)
					on	se.PK_SubEvent = BSA.PK_SubEvent
						AND BSA.DistributorID = @DistributorID
				LEFT JOIN (
							/* Has qualifications */
							SELECT	SE.PK_SubEvent, 
									count(BSE.PK_SubEvent) Qualifications 
							FROM	[SubEvent] AS SE WITH (NOLOCK)
									LEFT JOIN dbo.[BreakoutSessionSubEvent] BSE WITH (NOLOCK)
										ON SE.PK_Event = BSE.PK_Event
										AND SE.PK_SubEvent = BSE.BreakoutSession
							WHERE	SE.PK_Event = @EventID
									AND SE.PK_SubEvent = case when isnull(@SessionID,0) = 0 then SE.PK_SubEvent else @SessionID end 
									AND SE.PK_SubEventType = 5
							GROUP BY SE.PK_SubEvent				
							) SEQ
					ON se.PK_SubEvent = SEQ.PK_SubEvent
				LEFT JOIN (
							/* Distributor Qualifications */
							SELECT	BSE.BreakoutSession
									, sum(case when isnull(SEQ.PK_SubEvent,0) = 0 then 1 else 0 end ) SubEventsNotQualifiedCounter  /* increment in 1 for each session where DS is not qualified */
									, cast(max(cast (bsor.IsQualified as int)) as bit) Override_IsQualified
							FROM	[SubEvent] AS SE WITH (NOLOCK)
									INNER JOIN dbo.[BreakoutSessionSubEvent] BSE WITH (NOLOCK)
										ON	SE.PK_SubEvent = BSE.PK_SubEvent
									LEFT JOIN dbo.SubEventQualifier seq WITH (NOLOCK)
										ON SE.PK_SubEvent = SEQ.PK_SubEvent
											AND RemovedUTC = @ValidDate
											AND DistributorID = @DistributorID
									LEFT JOIN dbo.BreakoutSessionQualifierOverride bsor WITH (NOLOCK)
										ON bse.BreakoutSession = bsor.PK_SubEvent
											AND bsor.DistributorID = @DistributorID
							WHERE	BSE.BreakoutSession = case when isnull(@SessionID,0) = 0 then BSE.BreakoutSession else @SessionID end 
							GROUP BY BSE.BreakoutSession
							) DSQ
					on se.PK_SubEvent = DSQ.BreakoutSession
		WHERE	se.PK_Event = @EventID 
				AND se.PK_SubEvent = case when isnull(@SessionID,0) = 0 then se.PK_SubEvent else @SessionID end 
				AND se.PK_SubEventType = 5
		group by se.PK_Event, se.PK_SubEvent
	
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
END;
GO

