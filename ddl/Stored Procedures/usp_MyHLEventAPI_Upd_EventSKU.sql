CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_EventSKU]
		-- Mandatory Parameters
		    @PK_Event INT
		   ,@SKUDetails [udt_EventSKU] READONLY
		   ,@ModifiedBy VARCHAR(30) = 'UsrSQLProd'
		   ,@IsFromAdmin BIT = 0
		-- Error Parameters
		   ,@Error INT OUTPUT
	       ,@ErrorMessage VARCHAR(200) OUTPUT
	    -- QA/DEV
		   ,@IsDevQA bit = 0
AS

BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Upd_EventSKU
USE:
			declare @e int
			declare @em varchar(200)
			declare @IsDevQA int
			declare @EventID int
			DECLARE @SKU as udt_EventSKU;
					
			insert into @SKU (PK_EventSKULocaleDesc, PK_event, PK_EventSKU, SKUCode, SKUDesc, SKUValidBeginUTC, SKUValidEndUTC, PK_Country, IsEventTicketSKU, SKUDescLocale, PK_Locale, PK_EventSKUType, IsDelete, IsTrackingVisible)
			values (1106, 729, 2986, 'E566','Dallas_July LDW - Early Bird', '2012-03-20 00:00:00', 	'2014-10-20 00:00:00', 10, 1, 'Dallas_July LDW - Early Bird', 77, 1, 0, 1)
			, (130, 729, 2987, 'E567','Dallas_July LDW - Advanced', '2012-03-20 00:00:00', 	'2014-10-20 00:00:00', 10,1, 'Dallas_July LDW - Advanced', 77, 1, 0, 1)
			, (131, 729, 2988, 'E568','Dallas_July LDW - New Supervisor/New Distributor', '2012-03-20 00:00:00', 	'2014-10-20 00:00:00',10, 1, 'Dallas_July LDW - New Supervisor/New Distributor', 77, 1, 0, 1)
			, (132, 729, 2989, 'E676','Dallas_July LDW - Distributor Saturday Training & Party Only', '2012-05-02 00:00:00', 	'2014-10-20 00:00:00', 10,1, 'Dallas_July LDW - Distributor Saturday Training & Party Only', 77, 1, 0, 1)
			, (133, 729, 2990, 'E685','Dallas_July LDW - Newly Converted Supervisor - Sunday Training', '2012-05-08 00:00:00', 	'2014-10-20 00:00:00',10, 1, 'Dallas_July LDW - Newly Converted Supervisor - Sunday Training', 77, 1, 0, 1)
			, (134, 729, 2991, 'E570','Dallas_July LDW - At the Door', '2012-03-20 00:00:00', 	'2014-10-20 00:00:00', 10,1, 'Dallas_July LDW - At the Door', 77, 1, 0, 0)
			

			EXEC usp_MyHLEventAPI_Upd_EventSKU
					@PK_Event = 729
					,@SKUDetails = @SKU
					,@ModifiedBy = 'SushmaA'
					,@Error = @e
					,@ErrorMessage = @em
					

DESCRIPTION:	Inserts/Updates SKUCode into the EventSKU Table and translations in EventSKULocaleDesc

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventSKU, dbo.EventSKULocaleDesc

VERSIONS
--------------------------------------------------------------------
1	2015-01-21	    SushmaA	        Initial
1	2015-06-25	    SushmaA	        IsTrackingVisible Changes
2	2018-09-25		RogelioR		Tickets with the same SKU Code were not saved correctly on [EventSKU]

******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	/******************************************************************************
		VARIABLE DECLARATION
	******************************************************************************/
	DECLARE @StoredProcedure VARCHAR(100)
	DECLARE @StartTime DATETIME
--	DECLARE @SKUData udt_EventSKU

	/* SET THE VALUES FOR THE LOCAL VARIABLES */
	SET @ErrorMessage = 'No Error.'
	SET @StoredProcedure = 'usp_MyHLEventAPI_Upd_EventSKU'
	SET @StartTime = GETUTCDATE()

	CREATE TABLE #SKUData (
		[n] int
		,[PK_EventSKULocaleDesc] [int] NULL
		,[PK_Event] [int] NULL
		,[PK_EventSKU] [int] NULL
		,[SKUCode] [varchar](4) NULL
		,[SKUDesc] [varchar](100) NULL
		,[SKUValidBeginUTC] [datetime] NULL
		,[SKUValidEndUTC] [datetime] NULL
		,[PK_Country] [int] NULL
		,[IsEventTicketSKU] [int] NULL
		,[SKUDescLocale] [nvarchar](200) NULL
		,[PK_Locale] [int] NULL
		,[PK_EventSKUType] [int] NULL
		,[IsDelete] [bit] NULL
		,[IsTrackingVisible] [bit] NULL
	);

	INSERT INTO #SKUData (
			[n]
			,[PK_EventSKULocaleDesc]
			,[PK_Event]
			,[PK_EventSKU]
			,[SKUCode]
			,[SKUDesc]
			,[SKUValidBeginUTC]
			,[SKUValidEndUTC]
			,[PK_Country]
			,[IsEventTicketSKU]
			,[SKUDescLocale]
			,[PK_Locale]
			,[PK_EventSKUType]
			,[IsDelete]
			,[IsTrackingVisible]
	)
	SELECT	
			ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [n]
			,[PK_EventSKULocaleDesc]
			,@PK_Event AS [PK_Event]
			,[PK_EventSKU]
			,[SKUCode]
			,[SKUDesc]
			,[SKUValidBeginUTC]
			,[SKUValidEndUTC]
			,[PK_Country]
			,[IsEventTicketSKU]
			,[SKUDescLocale]
			,[PK_Locale]
			,[PK_EventSKUType]
			,[IsDelete]
			,[IsTrackingVisible]
		FROM @SKUDetails;
	
	IF NOT EXISTS (SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event)
	BEGIN

		SET @Error = 1
		SET @ErrorMessage = 'There is no master record for this EventID'

	END


	/* INSERT/UPDATE THE SKU RECORDS IN TO THE EVENTSKU TABLE */
	BEGIN TRY
		IF @IsDevQA = 1
			SELECT 'MERGE into EventSKU'

		--delete the translations before deleting EventSKU
		DELETE ESL
			FROM dbo.EventSKULocaleDesc ESL WITH (NOLOCK)
				INNER JOIN #SKUData ESK ON ESL.PK_EventSKU = ESK.PK_EventSKU
			WHERE ESK.IsDelete = 1	

		DECLARE @es table (
			[n] int
			,[PK_EventSKU] int
		);

		--EventSKU Table
		MERGE dbo.EventSKU ESK
			USING (
					SELECT 
							SK.[n]
							,SK.PK_EventSKULocaleDesc
							,SK.PK_EventSKU
							,SK.SKUCode
							,SK.SKUDesc
							,SK.SKUValidBeginUTC
							,SK.SKUValidEndUTC
							,SK.PK_Country
							,SK.IsEventTicketSKU
							,SK.PK_Locale
							,SK.IsDelete
							,SK.PK_EventSKUType
							,@PK_Event AS [PK_Event]
							,@ModifiedBy AS [ModifiedBy]
							,@StartTime AS [StartTime]
							,[IsTrackingVisible]
						FROM #SKUData SK
					) AS S ON S.[PK_EventSKU] = ESK.[PK_EventSKU] AND ESK.PK_Event = S.[PK_Event]
			WHEN NOT MATCHED THEN 
				INSERT (
					[PK_Event]
					,[SKUCode]
					,[SKUDesc]
					,[IsEventTicketSKU]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[SKUValidBeginUTC]
					,[SKUValidEndUTC]
					,[PK_Country]
					,[PK_EventSKUType]
					,[IsTrackingVisible]
					,[IsFromAdmin]
				)
				VALUES (
					S.[PK_Event]
					,S.[SKUCode]
					,S.[SKUDesc]
					,S.[IsEventTicketSKU]
					,S.[StartTime]
					,S.[ModifiedBy]
					,S.[StartTime]
					,S.[ModifiedBy]
					,S.[SKUValidBeginUTC]
					,S.[SKUValidEndUTC]
					,S.[PK_Country]
					,S.[PK_EventSKUType]
					,S.[IsTrackingVisible]
					,@IsFromAdmin
				)
			WHEN MATCHED AND S.IsDelete = 1 THEN DELETE
			WHEN MATCHED AND S.IsDelete = 0 THEN
				UPDATE SET 
					[SKUDesc] = S.[SKUDesc]
					,[IsEventTicketSKU] = S.[IsEventTicketSKU]
					,[SKUValidBeginUTC] = S.[SKUValidBeginUTC]
					,[SKUValidEndUTC] = S.[SKUValidEndUTC]
					,[PK_EventSKUType] = S.[PK_EventSKUType]
					,[IsTrackingVisible] = S.[IsTrackingVisible]
					,[ModifiedDateUTC] = S.[StartTime]
					,[ModifiedBy] = s.[ModifiedBy]
			OUTPUT
					s.[n]
					,inserted.[PK_EventSKU]
				INTO @es
		;

	END TRY

	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH

	--update PK_EventSKU of newly inserted EventSKU
	UPDATE t SET
			t.[PK_EventSKU] = s.[PK_EventSKU]
		FROM #SKUData AS t
			INNER JOIN @es AS s ON s.[n] = t.[n]
	
	/* INSERT/UPDATE THE SKU RECORDS IN TO THE EventSKULocaleDesc TABLE */
	BEGIN TRY
		IF @IsDevQA = 1
			SELECT 'Merge into EventSKULocaleDesc'

	----EventSKULocaleDesc Table
		MERGE dbo.[EventSKULocaleDesc] ESK
			USING (
					SELECT 
							SK.PK_EventSKULocaleDesc
							,SK.PK_EventSKU
							,SK.SKUCode
							,SK.SKUDesc
							,SK.SKUValidBeginUTC
							,SK.SKUValidEndUTC
							,SK.PK_Country
							,SK.SKUDescLocale
							,SK.IsEventTicketSKU
							,SK.PK_Locale
							,SK.IsDelete
							,SK.PK_EventSKUType
							,@PK_Event AS [PK_Event]
							,@ModifiedBy AS [ModifiedBy]
							,@StartTime AS [StartTime]
						FROM #SKUData SK
				) AS S ON --ESK.PK_EventSKULocaleDesc = S.PK_EventSKULocaleDesc
					ESK.PK_Event = S.[PK_Event] AND ESK.PK_EventSKU = S.PK_EventSKU AND ESK.PK_Locale = S.PK_Locale
			WHEN NOT MATCHED THEN INSERT (PK_Event, PK_EventSKU, SKUDesc, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Locale)
				VALUES(S.PK_Event, S.PK_EventSKU, S.SKUDescLocale, S.[StartTime], S.[ModifiedBy], S.[StartTime], S.[ModifiedBy], S.PK_Locale)
			WHEN MATCHED AND S.IsDelete = 0 THEN
				UPDATE
					SET SKUDesc = S.SKUDescLocale
					, PK_Locale = S.PK_Locale
					, ModifiedDateUTC = S.[StartTime]
					, ModifiedBy  = s.ModifiedBy
		;	-- MERGE [EventSKULocaleDesc]

	END TRY

	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH

	-- UPDATE PROCESSING LOG
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
	
	/******************************************************************************
		END PROCEDURE	[usp_MyHLEventAPI_Upd_EventSKU]
	******************************************************************************/
END