CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_EventAudio]  
   --Mandatory Parameters  
   @PK_Event INT  
  ,@EventAudio udt_EventAudio READONLY  
  ,@ModifiedBy VARCHAR(10)  

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA TINYINT = 0
AS  
BEGIN  
  
/******************************************************************************  
OBJECT:  dbo.usp_MyHLEventAPI_Upd_EventAudio  
USE:  
	DECLARE @e int, @em varchar(4000)
   declare @IsDevQA int  
   declare @EventAudio udt_EventAudio  
   INSERT INTO @EventAudio VALUES (NULL, 'EventAudio', 'http:\\hyperlink', NULL, 2, 'en-US') 
     							 ,(NULL, 'EventAudio2', 'http:\\hyperlink2', NULL,2, 'en-US')
    
   EXEC usp_MyHLEventAPI_Upd_EventAudio  
      @PK_Event = 9574  
     ,@EventAudio = @EventAudio  
     ,@ModifiedBy = 'sushmaa'  
     ,@Error = @e OUTPUT  /* @e must be defined in the local call */  
     ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */  
	,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]
      
DESCRIPTION: Inserts/updates a record in dbo.EventAudio  
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
dbo.EventAudio  
  
VERSIONS  
--------------------------------------------------------------------  
1.0.1 	2013-01-17 		Sushma 		Initial  
1.0.2 	2016-11-11 		Sushma 		Included Event Video Section  
1.0.3 	2019-08-14 		NoeG		Refactor code (SRE)
1.0.4	2021-08-18 		puertac		BUG 742101 : Corporate Events/Promotions not save 2 videos
  
******************************************************************************/  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON   
  
/******************************************************************************  
 VARIABLE DECLARATION  
******************************************************************************/  
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';
  
/* Insert/Update the record into EventAudio table */  
BEGIN TRY  
  
  	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END
	
	MERGE dbo.[EventAudio] EA  
	USING  
	(  
		 SELECT @PK_Event AS [PK_Event], EA.PK_EventAudio,  EA.AudioName, EA.AudioHTML, EA.MediaType, EA.[AudioDesc]  
		 FROM @EventAudio EA INNER JOIN dbo.Locales L WITH (NOLOCK) ON EA.LocaleCode = L.LocaleCode
		 INNER JOIN dbo.Event E WITH (NOLOCK) ON L.PK_Locale = E.PK_DefaultLocale and E.PK_Event = @PK_Event
	) AS M  
	ON EA.[PK_Event] = M.[PK_Event]  
	AND EA.PK_EventAudio = M.PK_EventAudio  
	WHEN NOT MATCHED THEN INSERT (PK_Event, AudioName, AudioDesc, AudioHTML, PK_MediaType)  
	VALUES(M.PK_Event, M.AudioName, M.AudioName, M.AudioHTML, M.MediaType)  
	WHEN MATCHED THEN UPDATE SET  
	 [AudioName]= M.[AudioName]  
	,[AudioHTML] = M.[AudioHTML] 
	,[AudioDesc] = M.[AudioDesc]
	,[PK_MediaType] = M.[MediaType] 
	,ModifiedBy = @ModifiedBy  
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

	IF (@IsDevQA = 3)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END
    
	-- BUG 742101
	DROP TABLE IF EXISTS #EventAudio										

	SELECT ISNULL(E.PK_EventAudio,EA.PK_EventAudio) AS PK_EventAudio
		   ,E.AudioName
		   ,E.AudioHTML
		   ,E.AudioDesc
		   ,E.MediaType
		   ,E.LocaleCode
	INTO #EventAudio 
	FROM @EventAudio E
	LEFT JOIN EventAudio EA WITH (NOLOCK)
		ON  E.AudioName = EA.AudioName
		AND E.AudioHTML = EA.AudioHTML
		AND ISNULL(E.AudioDesc, '') = ISNULL(EA.AudioDesc,'')
		AND E.MediaType = EA.PK_MediaType
		AND EA.PK_Event = @PK_Event
							   
	-- END BUG 742101
	
	MERGE dbo.[EventAudioLocaleDesc] EA  
	USING  
	(  
		 SELECT @PK_Event AS [PK_Event],EA.PK_EventAudio,  
				EA.[AudioName], EA.[AudioHTML], EA.[AudioDesc], L.PK_Locale 
		 FROM #EventAudio EA 												-- BUG 742101
		 INNER JOIN dbo.Locales L WITH (NOLOCK) ON EA.LocaleCode = L.LocaleCode
	) AS M  
	ON EA.[PK_Event] = M.[PK_Event]  
	AND EA.PK_EventAudio = M.PK_EventAudio  
	AND EA.PK_Locale = M.PK_Locale
	WHEN NOT MATCHED THEN INSERT (PK_Event, PK_EventAudio, AudioName, AudioDesc, AudioHTML, PK_Locale)  
	VALUES(M.PK_Event, M.PK_EventAudio, M.AudioName, M.AudioDesc, M.AudioHTML, M.PK_Locale)  
	WHEN MATCHED THEN UPDATE SET  
	 [AudioName]= M.[AudioName]  
	,[AudioHTML] = M.[AudioHTML] 
	,[AudioDesc] = M.[AudioDesc]
	,[PK_Locale] = M.[PK_Locale] 
	,ModifiedBy = @ModifiedBy  
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
END CATCH  
  
/******************************************************************************  
 END PROCEDURE  
******************************************************************************/  
END