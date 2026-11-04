CREATE PROCEDURE [dbo].[usp_EventsAT_Save_PMPromoQualification]    
	-- Required    
	@PK_Event  int
	,@UserName  nvarchar(250)
    
	-- Optional    
	,@CanDisplayQualPeriod   bit = null   -- Display qualification dates
	,@DisplayStartDate    datetime2 = null
	,@DisplayEndDate     datetime2 = null
	,@IsPublishQualTracking   bit = null   -- Publish qualifications tracker
	,@QualDesc      xml = null
	,@IsDisplayTVP     bit = null
	,@IsDisplayDV     bit = null
	,@IsDisplayPPV     bit = null
	,@PromotionCode varchar(255) = null
	,@DisplayQualStatus bit = 0
   
	-- Defaults    
	,@PK_SubEventType    int = 2
	,@MaxCapacity     int = 1
	,@ExpectedCapacity    int = 1
	,@Transaction     bit = 0
	,@ChkDates		bit = 0
    
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS    
BEGIN    
/******************************************************************************    
  
 OBJECT:   dbo.usp_EventsAT_Save_PMPromoQualification    
    
 USE:       

     DECLARE @QualDesc varchar(max) = N'  
			<QualDesc>  
				<PK_SubEvent>11605</PK_SubEvent>  
				<Locale>es-PR</Locale>  
				<Title>Puerto Rico</Title>  
				<Desc>Español Puerto Rico</Desc>  
				<Image>imagenpuertorico.png</Image>
				<IsTrackingVisible>1</IsTrackingVisible>
			</QualDesc>  
			<QualDesc>  
				<PK_SubEvent>11605</PK_SubEvent>  
				<Locale>es-US</Locale>  
				<Title>EU (Español)</Title>  
				<Desc>Español EU</Desc>
				<Image>imagenenesus.png</Image>  
				<IsTrackingVisible>1</IsTrackingVisible>
			</QualDesc>  
			<QualDesc>  
				<PK_SubEvent>11605</PK_SubEvent>  
				<Locale>en-US</Locale>  
				<Title>EU English</Title>  
				<Desc>EU english description</Desc>  
				<Image>imageneneu.png</Image>  
				<IsTrackingVisible>1</IsTrackingVisible>
			</QualDesc>'  
			,@QualDescXML xml  
			,@e int
			,@em varchar(4000)
   
	SELECT @QualDescXML = CAST(@QualDesc AS XML);  
  
	EXEC dbo.usp_EventsAT_Save_PMPromoQualification    
			@UserName = 'RogelioR'    
			,@PK_Event = 48102  
			,@CanDisplayQualPeriod = 0    
			,@IsPublishQualTracking = 0  
			,@QualDesc = @QualDescXML  
			-- Errors    
			,@Error = @e OUTPUT  /* @e must be defined in the local call */    
			,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */    
            ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]
         
 DESCRIPTION: Update the preferred member promotion dates    
 NOTES:    
    
 DEPENDENCIES    
 --------------------------------------------------------------------    
 dbo.Event    
     
 VERSIONS    
 --------------------------------------------------------------------    
 1.0.0		2017-04-12		RogelioR		Initial    
 2.0.0		2019-08-08		NoeG			Refactor code (SRE)
 2.0.1		2020-08-31		puertac			BUG 348551: Qualification Display Date and Publish Display Date use the same column
											Fix: Use QualificationDates instead of DisplayDates from dbo.Event table
 2.0.2		2020-10-12		puertac			BUG 404354 : PM promotions translate for Qualification display ??? - Title & Description
******************************************************************************/    
    
 SET ANSI_NULLS ON    
 SET QUOTED_IDENTIFIER ON    
 SET NOCOUNT ON    
     
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';
        
BEGIN TRY    
	IF NOT EXISTS ( SELECT 1 FROM [Event] wITH (NOLOCK) WHERE PK_Event = @PK_Event)    
	BEGIN    
		SELECT @ErrorMessage = 'The Event ' + CAST(@PK_Event AS VARCHAR(100)) + ' does not exists.';    
		RAISERROR(@ErrorMessage, 11, 1);    
		SELECT 0 AS PK_Event;    
	END      
    
	IF @ChkDates = 1
	BEGIN
		IF (@DisplayEndDate <= GETUTCDATE())    
		BEGIN    
		SELECT @ErrorMessage = 'The Event qualification end date cannot be before today.';    
		RAISERROR(@ErrorMessage, 11, 1);    
		SELECT 0 AS PK_Event;    
		END    
	END  

	IF (@DisplayEndDate <= @DisplayStartDate)    
	BEGIN    
		SELECT @ErrorMessage = 'The start qualification date cannot be greater than the end date.';
		RAISERROR(@ErrorMessage, 11, 1);
		SELECT 0 AS PK_Event;
	END
    
	IF @Transaction = 1 BEGIN TRANSACTION;
  
	-----------------------------------------------------------------------------------------------------------------------
	-- Qualification configuration
	--	
	WITH cte_qual AS (  
		SELECT
				ISNULL(@PK_Event, 0) AS [PK_Event]  
				,QualDesc.value('PK_SubEvent[1]', 'int') AS [PK_SubEvent]  
				,QualDesc.value('Locale[1]', 'varchar(5)') AS [LocaleCode]  
				,QualDesc.value('Title[1]', 'nvarchar(max)') AS [Title]					-- BUG 404354 changed from varchar to nvarchar
				,QualDesc.value('Desc[1]', 'nvarchar(max)') AS [QualDescription]		-- BUG 404354 changed from varchar to nvarchar
				,QualDesc.value('Image[1]', 'varchar(255)') AS [Image]  
				,QualDesc.value('IsTrackingVisible[1]', 'bit') AS [IsTrackingVisible]
			FROM @QualDesc.nodes('//QualDesc') AS t(QualDesc)  
	)  
	SELECT
			c.[PK_Event]  
			,c.[PK_SubEvent]
			,c.[LocaleCode]  
			,e.[PK_DefaultLocale]  
			,l.[PK_Locale]  
			,c.[Title]  
			,c.[QualDescription]  
			,c.[Image]
			,c.[IsTrackingVisible]
		INTO #s  
		FROM cte_qual AS c  
			INNER JOIN [dbo].[Event] AS e wITH (NOLOCK) ON e.[PK_Event] = c.[PK_Event]  
			INNER JOIN [dbo].[Locales] AS l wITH (NOLOCK) ON l.[LocaleCode] = c.[LocaleCode];

	-----------------------------------------------------------------------------------------------------------------------
	-- Update IsTrackingVisible
	--    
	WITH cte_subevent AS (
		SELECT [PK_SubEvent], MAX(CAST([IsTrackingVisible] AS INT)) AS [IsTrackingVisible]
			FROM #s
			GROUP BY [PK_SubEvent]
	)
	UPDATE se SET
			[isTrackingVisible] = c.[IsTrackingVisible]
		FROM [dbo].[SubEvent] AS se
			INNER JOIN cte_subevent AS c ON c.[PK_SubEvent] = se.[PK_SubEvent];

	-----------------------------------------------------------------------------------------------------------------------
	-- Qualification configuration
	--    
	UPDATE dbo.[Event] SET
			 QualPeriodStart = @DisplayStartDate					-- BUG 348551: Use QualificationDates instead of DisplayDates
			,QualPeriodEnd = @DisplayEndDate						-- BUG 348551: Use QualificationDates instead of DisplayDates
			,[CanDisplayQualPeriod] = @CanDisplayQualPeriod
			,[IsPublishQualTracking] = @IsPublishQualTracking
			,[CanAssignTickets] = 0
			,[ModifiedBy] = @UserName
			,[ModifiedDateUTC] = GETUTCDATE()
		WHERE [PK_Event] = @PK_Event;    
       
	UPDATE dbo.[EventExtn] SET
			[IsDisplayTVP] = @IsDisplayTVP
			,[IsDisplayDV] = @IsDisplayDV
			,[IsDisplayPPV] = @IsDisplayPPV
			,[PromotionCode] = @PromotionCode
			,[DisplayQualStatus] = @DisplayQualStatus
		WHERE [PK_Event] = @PK_Event;
    
	-----------------------------------------------------------------------------------------------------------------------
	-- Description on qualifications
	--    
	MERGE [dbo].[SubEventLocaleDesc] AS t  
		USING (SELECT
					[PK_SubEventLocaleDesc]
					,s.[PK_SubEvent]
					,s.[PK_Event]
					,s.[PK_Locale]
					,s.[PK_DefaultLocale]
					,s.[Title] AS [SubEventName]
					,s.[QualDescription] AS [SubEventQualDesc]
					,s.[Image]
					,GETUTCDATE() AS [CreatedDateUTC]
					,@UserName AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,@UserName AS [ModifiedBy]
				FROM #s AS s  
					LEFT JOIN [dbo].[SubEventLocaleDesc] AS se wITH (NOLOCK) ON s.[PK_Event] = se.[PK_Event]
						AND s.[PK_SubEvent] = se.[PK_SubEvent]
						AND s.[PK_Locale] = se.[PK_Locale]
			) AS s  
			ON (s.[PK_SubEventLocaleDesc] = t.[PK_SubEventLocaleDesc])
		WHEN MATCHED THEN
			UPDATE SET
				[SubEventName] = s.[SubEventName]
				,[SubEventQualDesc] = s.[SubEventQualDesc]
				,[Image] = s.[Image]
				,[ModifiedDateUTC] = s.[ModifiedDateUTC]
				,[ModifiedBy] = s.[ModifiedBy]
		WHEN NOT MATCHED BY TARGET THEN
			INSERT(
				[PK_SubEvent]
				,[PK_Event]
				,[PK_Locale]
				,[PK_DefaultLocale]
				,[SubEventName]
				,[SubEventQualDesc]
				,[Image]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
			)  
			VALUES(  
				s.[PK_SubEvent]
				,s.[PK_Event]
				,s.[PK_Locale]
				,s.[PK_DefaultLocale]
				,s.[SubEventName]
				,s.[SubEventQualDesc]
				,s.[Image]
				,s.[CreatedDateUTC]
				,s.[CreatedBy]
				,s.[ModifiedDateUTC]
				,s.[ModifiedBy]
			)
		WHEN NOT MATCHED BY SOURCE AND [PK_SubEvent] IN (SELECT [PK_SubEvent] FROM #s) AND PK_Locale IN (SELECT [PK_Locale] FROM #s) THEN
			DELETE
		-- OUTPUT $action, inserted.*  
	; -- Merge  
  
	IF @Transaction = 1 COMMIT TRANSACTION

	-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

	END TRY
    
	BEGIN CATCH
		IF @Transaction = 1
		BEGIN
			IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		END  
  
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
		RETURN;    
	END CATCH;    
END;