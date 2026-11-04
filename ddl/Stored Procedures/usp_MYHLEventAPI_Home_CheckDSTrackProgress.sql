CREATE PROCEDURE [dbo].[usp_MYHLEventAPI_Home_CheckDSTrackProgress]
-- Mandatory
@DistributorID VARCHAR(20), 
@Locale VARCHAR(5) 
		
-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MYHLEventAPI_Home_CheckDSTrackProgress

USE:			
			DECLARE @e int, @em varchar(4000)
			EXEC dbo.usp_MYHLEventAPI_Home_CheckDSTrackProgress
			-- Mandatory
				@DistributorID = null
			-- Optional
				,@Locale = 'en-US'
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Landing Page -> Track Your Progress & Landing Page -> Track your Downline Progress
				This will check whether or not to enable the links above when the member logs in. 

VERSIONS
----------------------------------------------------------------------------------
1	2016-06-28			SandhyaP			 Landing Page
2	2019-09-30			NoeG				SRE template applied
3	2019-10-30			NoeG				SRE Hardcode changed
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
				 
		-- DECLARE THE LOCAL VARIABLES 

		DECLARE @PK_Locale INT
		DECLARE @DSTeam VARCHAR(10)
		DECLARE @DateFrom SMALLDATETIME 
		DECLARE @DateTo SMALLDATETIME
		DECLARE @CurrentDate DATE = CONVERT(DATE,GETUTCDATE(), 110)

		--- SET THE VARIABLES 
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WHERE LocaleCode = @Locale
		SET @DateFrom = GETUTCDATE()
		SET @DateTo = @ValidDate

		SELECT @DSTeam = sSubTeam FROM dbo.v_Distributor where sDistributorid = @DistributorID




		SELECT CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END HasTrackYourProgress
		FROM dbo.Event E (NoLock)
		INNER JOIN 
			dbo.EventCountry EC (NOLOCK) 
		ON 
			E.PK_Event = EC.PK_Event
		INNER JOIN 
			dbo.v_Countries (NOLOCK) VC 
		ON 
			EC.PK_Country = VC.nCountryID
		INNER JOIN 
			dbo.EventDistributorCountryLocales EDCL (NOLOCK)
		ON 
			E.PK_Event = EDCL.PK_Event
			AND
			EDCL.PK_Locale = @PK_Locale
		INNER JOIN
			(
				SELECT A.PK_Event, A.TeamOrder, DST.DSTeamTypeCode
				FROM (
				SELECT A.PK_Event 
					,MAX(B.TeamOrder) TeamOrder
				FROM dbo.EventDSteamType A (NOLOCK)
				INNER JOIN dbo.DSTeamType B (NOLOCK)
				ON A.DSTeamTypeCode = B.DSTeamTypeCode
				WHERE B.DSTeamTypeCode <> 'RC'
				GROUP BY A.PK_Event
				) A
				INNER JOIN
					dbo.DSTeamType (NOLOCK) DST
				ON
					A.TeamOrder = DST.TeamOrder
			) C
		ON 
			E.PK_Event = C.PK_Event
		INNER JOIN (Select Top 1 DSTeamTypeCode, TeamOrder From dbo.DSTeamType (NOLOCK) Where DSTeamTypeCode = COALESCE(@DSTeam,'FC')) DT
		ON 
			C.TeamOrder >= DT.TeamOrder
		WHERE
		(E.DisplayStartDate BETWEEN @DateFrom AND @DateTo OR E.DisplayEndDate BETWEEN @DateFrom AND @DateTo OR @DateFrom BETWEEN E.DisplayStartDate AND E.DisplayEndDate) 
		AND
		@CurrentDate BETWEEN DisplayStartDate AND (DisplayEndDate+1)
		AND 
		(CASE WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= @CurrentDate THEN 4  END) IN (4) /* Published */

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