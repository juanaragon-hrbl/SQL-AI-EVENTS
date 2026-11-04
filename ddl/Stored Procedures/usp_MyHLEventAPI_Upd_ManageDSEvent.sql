CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_ManageDSEvent]
        --Mandatory Parameters
         @PK_Event INT
		,@LocaleCode CHAR(5)--Editing of the LocaleCode from the UI will be disabled once the Event is PUBLISHED This has to be handled at the UI layer
		,@PK_RefEvent INT = NULL
		,@EstimatedDS INT = NULL
		,@ActualDS INT = NULL
		,@EstimatedNonDS INT = NULL
		,@ActualNonDS INT = NULL		 
		,@ManageEventURL [udt_EventURL] READONLY
		,@DistributorNotes nVarchar(4000) = NULL
		,@ModifiedBy VARCHAR(30) = 'UsrSQLProd'
		,@ContactName nVARCHAR(200) = NULL
		,@ContactPhone nVARCHAR(100) = NULL
		,@ContactEmail nVarchar(100) = NULL
		,@Street nVARCHAR(1000) = NULL
		,@City nVARCHAR(200)  = NULL
		,@State nVARCHAR(100) = NULL
		,@ZipCode nVARCHAR(100) = NULL
		,@IsUpdate INT = 0
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT
		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Upd_ManageDSEvent
USE:
			DECLARE @e int, @em varchar(4000)
			declare @IsDevQA int
			
			DECLARE @ManageEventURLAttendance [udt_EventURL]
			INSERT @ManageEventURLAttendance values(61, 9859, 'en-US', 'test url type 66', null, null, 0)			
			
			EXEC usp_MyHLEventAPI_Upd_ManageDSEvent
					 @Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@PK_Event = 9859
					,@LocaleCode  = 'en-US'
					,@ManageEventURL = @ManageEventURLAttendance
					,@PK_RefEvent = 5775
					,@EstimatedDS = 101
					,@ActualDS = 97
					,@EstimatedNonDS = 111
					,@ActualNonDS = 1
					,@DistributorNotes = '@DistributorNotes'
					,@ContactName = 'ConName'
					,@ContactPhone = '999999999'
					,@ContactEmail = 'abc@xyz.com'
					,@Street = 'Street'
					,@City = 'Bangalore'
					,@State = 'Karnataka'
					,@ZipCode = '000000'
					,@IsUpdate = 0
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Updates the respective Event record into dbo.EventLocaleDesc, dbo.EventURL, dbo.EventManggeDetails

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventLocaleDesc, dbo.EventURL, dbo.EventManggeDetails

VERSIONS
--------------------------------------------------------------------
1	2013-08-21	Sushma	Initial
2	2019-08-14	NoeG	Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON	

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_EventType INT
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @ModifiedDate SMALLDATETIME


SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_EventType = PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCODE = 'DE'
SET @ModifiedDate = GETUTCDATE()

SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

--File Attachments from Manage tab for Attendance

	MERGE dbo.[EventURL] EA
	USING
	(
		SELECT @PK_Event AS [PK_Event], MEU.EventURL, MEU.EventURLDesc, MEU.Flyer, MEU.PK_EventURL, L.PK_Locale, MEU.IsDelete
		FROM @ManageEventURL MEU
		INNER JOIN dbo.Locales L WITH (NOLOCK) ON MEU.LocaleCode = L.LocaleCode
	) AS M
	ON EA.[PK_Event] = M.[PK_Event]
	AND EA.PK_EventURL = M.PK_EventURL
	WHEN NOT MATCHED THEN INSERT (PK_Event, EventURL, EventURLDesc, Flyer, PK_Locale, PK_EventURLType)
		VALUES(M.PK_Event, M.EventURL, M.EventURLDesc, M.Flyer, M.PK_Locale, 2)
	WHEN MATCHED AND M.IsDelete = 0 THEN UPDATE SET
	 [EventURL]= M.[EventURL]
	,[EventURLDesc] = M.[EventURLDesc]
	,[Flyer] = M.[Flyer]
	,[PK_Locale] = M.[PK_Locale]
	,[PK_EventURLType] = 2
	,ModifiedBy = @ModifiedBy
	WHEN MATCHED AND M.IsDelete = 1 THEN DELETE
	;	 
	 
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

BEGIN TRY

	UPDATE
		dbo.EventLocaleDesc
	SET 
		DistributorNotes = @DistributorNotes
	WHERE
		PK_Event =  @PK_Event
	
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

BEGIN TRY

	/* UPDATE THE EXISTING RECORD IN THE [EventManageDetails] */
	MERGE [EventManageDetails] EMD
	USING
	(
		SELECT @PK_RefEvent [PK_RefEvent], @EstimatedDS [EstimatedDS], @ActualDS [ActualDS], @EstimatedNonDS [EstimatedNonDS]
		,@ActualNonDS [ActualNonDS], @StartTime [StartTime], @ModifiedBy [ModifiedBy], @PK_Event [PK_Event]
		,@ContactName [ContactName], @ContactPhone [ContactPhone], @ContactEmail [ContactEmail], @Street [Street], @City [City]
		,@State [State], @ZipCode [ZipCode]
	) M
	ON EMD.PK_Event = M.PK_Event
	WHEN NOT MATCHED
	THEN INSERT ([PK_RefEvent], [EstimatedDS], [ActualDS], [EstimatedNonDS], [ActualNonDS], [ModifiedDate], [ModifiedBy], [PK_Event], [ContactName]
				, [ContactPhone], [ContactEmail], [Street], [City], [State], [ZipCode])
	VALUES (M.[PK_RefEvent], M.[EstimatedDS], M.[ActualDS], M.[EstimatedNonDS], M.[ActualNonDS], M.[StartTime], M.[ModifiedBy], M.[PK_Event], M.[ContactName]
				,M.[ContactPhone], M.[ContactEmail], M.[Street], M.[City], M.[State], M.[ZipCode])
	WHEN MATCHED THEN 
	UPDATE
	SET
		 ActualDS = M.ActualDS
		,ActualNonDS = M.ActualNonDS
		,EstimatedDS = M.EstimatedDS
		,EstimatedNonDS = M.EstimatedNonDS
		,PK_RefEvent = (CASE WHEN @IsUpdate = 1 THEN M.[PK_RefEvent] ELSE EMD.PK_RefEvent END)
		,ContactName = M.[ContactName]
		,ContactPhone = M.[ContactPhone]
		,ContactEmail = M.ContactEmail
		,[Street] = M.[Street]
		,City = M.City
		,State = M.State
		,ZipCode = M.ZipCode
		,[ModifiedDate] = M.StartTime
		,[ModifiedBy] = M.ModifiedBy
	;
	
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

-- UPDATE PROCESSING LOG
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime
	
	
	

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

