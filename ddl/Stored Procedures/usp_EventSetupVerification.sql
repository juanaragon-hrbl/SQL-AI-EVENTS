CREATE PROCEDURE dbo.usp_EventSetupVerification
@PK_Event INT

-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventSetupVerification]
	
	USE:			
			DECLARE @e int, @em varchar(4000)
			
			EXEC [dbo].[usp_EventSetupVerification]
				@PK_Event = 2595
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0								Initial
	2.0.0		2019-09-30		NoeG	SRE template applied
	
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE @sOutput varchar(MAX)
	
			PRINT ('******************************************')
			PRINT ('             EVENT ID '+ CAST(@PK_Event as nvarchar(20)))
			PRINT ('******************************************')

			/*VERIFY EVENT TICKETS*/
			IF NOT EXISTS (SELECT NULL FROM Pubdbo.EventTickets WITH (NOLOCK) WHERE PK_Event = @PK_Event)
				PRINT ('Event Tickets NOT SET')

			/*VERIFY EVENT TICKETS*/
			IF NOT EXISTS (SELECT NULL FROM Pubdbo.EventDSTeamType WITH (NOLOCK) WHERE PK_Event = @PK_Event)
				PRINT ('Event Team Type NOT SET')

			/*VERIFY EVENT SCHEDULE*/
			SELECT @soutput = CONVERT(varchar(30),CAST(BeginUTC AS DATE),23) + ' to ' + CONVERT(varchar(30),CAST(endUTC AS DATE),23) FROM Pubdbo.EventSchedule WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Schedule = 5
			PRINT('Qualification Schedule Date: ' + ISNULL(@sOutput,'NULL'))
			SET @sOutput = NULL
	
			/*VERIFY EVENTEVENTSUBTYPE*/
			SELECT @soutput = b.EventSubtype FROM Pubdbo.EventEventSubtype a WITH (NOLOCK) 
			INNER JOIN 	Pubdbo.EventSubtypes b WITH (NOLOCK) ON 	a.PK_EventSubType = b.PK_EventSubType 	WHERE a.PK_Event = @PK_Event 
			PRINT('SubType: ' + ISNULL(@sOutput,'NULL'))
			SET @sOutput = NULL

			/*VERIFY EVENTLOCALE*/
			IF NOT EXISTS (SELECT NULL FROM Pubdbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event)
				PRINT ('Locale NOT SET')

			/*VERIFY EVENT Countries*/
			IF NOT EXISTS (SELECT NULL FROM Pubdbo.EventCountry WITH (NOLOCK) WHERE PK_Event = @PK_Event)
				PRINT ('Event Countries NOT SET')
			IF NOT EXISTS (SELECT NULL FROM Pubdbo.EventDistributorCountry WITH (NOLOCK) WHERE PK_Event = @PK_Event)
				PRINT ('Event Distributor Countries NOT SET')

			DECLARE @Event TABLE
			(
				PK_Event INT,
				dStartUTC DATE,
				dEndUTC DATE,
				DisplayStartDate DATE,
				DisplayEndDate DATE,
				PK_DefaultLocale INT,
				IsPublish BIT,
				IscustomTrackingSiteAvailable BIT,
				CustomTrackingSiteSPName VARCHAR(1000)
			)

			INSERT INTO @Event 
			SELECT 
				PK_Event,
				dStartUTC,
				dEndUTC, 
				DisplayStartDate ,
				DisplayEndDate,
				PK_DefaultLocale ,
				IsPublish ,
				IscustomTrackingSiteAvailable ,
				CustomTrackingSiteSPName 
			FROM
				Pubdbo.Event WITH (NOLOCK)
			WHERE
				PK_Event = @PK_Event

			/*VERIFY EVENT SCHEDULE*/
			SELECT @soutput = ISNULL(CONVERT(varchar(50),DisplayStartDate,23),'NULL') + ' to ' + ISNULL(CONVERT(varchar(50),DisplayEndDate,23),'NULL') FROM  @Event 
			PRINT('Display Dates: ' + @sOutput)
			SET @sOutput = NULL

			/*VERIFY EVENTEVENTSUBTYPE*/
			SELECT @soutput = b.LocaleCode FROM @Event a 
			INNER JOIN 	Pubdbo.Locales b  ON 	a.PK_DefaultLocale = b.PK_Locale 
			PRINT('Default Locale: ' + ISNULL(@sOutput,'NULL'))
			SET @sOutput = NULL
	
			/*Event Flags*/
			SELECT @soutput = IsPublish FROM @Event 
			PRINT('IsPublish: ' + ISNULL(@sOutput,'NULL'))
			SET @sOutput = NULL
	
			SELECT @soutput =IscustomTrackingSiteAvailable FROM @Event 	
			PRINT('IscustomTrackingSiteAvailable: ' + ISNULL(@sOutput,'NULL'))
	
			IF @soutput = '1' 
			BEGIN
				SELECT @soutput = 'Pubdbo.'+CustomTrackingSiteSPName FROM @Event
				PRINT ('CustomTrackingSiteSPName: ' + ISNULL(OBJECT_NAME(OBJECT_ID (@soutput,'P'),DB_ID('PubEventManagement')),'NOT FOUND'))
			END


			/*VERIFY Event Formula and SubEventQualifications*/
			EXEC dbo.usp_EventFormulaParser @PK_Event

			PRINT '**************** END *********************'

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