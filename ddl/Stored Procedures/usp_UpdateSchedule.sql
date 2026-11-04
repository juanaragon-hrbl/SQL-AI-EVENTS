CREATE PROCEDURE [dbo].[usp_UpdateSchedule]
	@PK_Event INT,
	@User VARCHAR(20),
	@IsPromotion BIT = 0
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_UpdateSchedule]
	
	USE:			
			

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-05-03		alejandramed		Initial
	1.1.0		2019-08-14		NoeG				Refactor code (SRE)
	1.2.0		2019-09-20		alejandramed		If @IsPromotion = 1, only PK_Schedule 5 is inserted
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	;WITH SourceSchedule (PK_Event, PK_Schedule, Descript, BeginUTC, EndUTC)
	AS (
	SELECT
		PK_Event,
		03 AS PK_Schedule,
		'Onsite Registration' AS Descript,
		DATEADD(WW,-1, dStartUTC) AS BeginUTC,
		DATEADD(DAY, 1, dEndUTC) AS EndUTC
	FROM dbo.[Event] (NOLOCK)
	WHERE
		PK_Event = @PK_Event

	UNION ALL

	SELECT
		E.PK_Event,
		05 AS PK_Schedule,
		'Update Qualification' AS Descript,
		DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) BeginUTC, 
		DATEADD(DAY, 1, E.dEndUTC) AS EndUTC
	FROM dbo.[Event] E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event
	UNION ALL

	SELECT
		E.PK_Event,
		06 AS PK_Schedule,
		'Update SKU Purchase' AS Descript,
		DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) BeginUTC, 
		DATEADD(DAY, 1 , E.dEndUTC) AS EndUTC
	FROM dbo.[Event] E (NOLOCK)
	WHERE
		E.PK_Event = @PK_Event

	UNION ALL

	SELECT
		PK_Event,
		08 AS PK_Schedule,
		'Blackberry Report' AS Descript,
		DATEADD(WW,-1, dStartUTC ) AS BeginUTC,
		DATEADD(DAY, 1, dEndUTC) AS EndUTC
	FROM dbo.[Event] (NOLOCK)
	WHERE PK_Event = @PK_Event

	UNION ALL
	SELECT
		E.PK_Event,
		10 AS PK_Schedule,
		'SKU Notes' AS Descript,
		DATEADD(WW,-1, e.dStartUTC ) AS BeginUTC,
		DATEADD(DAY, 1, e.dEndUTC) AS EndUTC
	FROM [Event] e (NOLOCK) 
	WHERE
		e.PK_Event = @PK_Event AND 
		EXISTS (SELECT 1 FROM dbo.EventSKU s (NOLOCK) 	
					WHERE
					s.PK_Event = @PK_Event AND s.IsGenerateNote = 1 )
	UNION ALL

	SELECT
		PK_Event,
		12 AS PK_Schedule,
		'Onsite Report' AS Descript,
		DATEADD(WW,-1, dStartUTC ) AS BeginUTC,
		DATEADD(MONTH, 1, dEndUTC) AS EndUTC
	FROM dbo.[Event] (NOLOCK)
	WHERE
		PK_Event = @PK_Event
	)

	MERGE dbo.EventSchedule AS Target
	USING SourceSchedule AS Source
	ON (Target.PK_Event = Source.PK_Event
		AND
		Target.PK_Schedule = Source.PK_Schedule)
	WHEN MATCHED AND ((Target.BeginUTC <> Source.BeginUTC OR Target.BeginUTC IS NULL) OR (Target.EndUTC <> Source.EndUTC OR Target.EndUTC IS NULL)) THEN
		UPDATE
			SET
				Target.ModifiedDateUTC	= GETUTCDATE(),
				Target.ModifiedBy		= @User,
				Target.BeginUTC			= Source.BeginUTC,
				Target.EndUTC			= Source.EndUTC  
	WHEN NOT MATCHED BY Target AND (@IsPromotion = 0 OR (@IsPromotion = 1 AND  Source.PK_Schedule = 5)) THEN 
		INSERT (CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Event, PK_Schedule, BeginUTC, EndUTC)	
		VALUES(GETUTCDATE(), @User, GETUTCDATE(), @User, Source.PK_Event, Source.PK_Schedule, Source.BeginUTC, Source.EndUTC)
;

	-- Update processing Log
	EXEC [dbo].[usp_Utility_UpdateProcessingLog]
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime;

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
GO

