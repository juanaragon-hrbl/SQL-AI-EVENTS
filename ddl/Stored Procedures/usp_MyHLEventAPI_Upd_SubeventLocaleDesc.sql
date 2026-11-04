CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_SubeventLocaleDesc]  
	@PK_Event INT -- PK_Event to be sent after the event is created  
	,@SubEvent udt_SubEvents READONLY    
	,@LocaleCode CHAR(5) -- localeCode that has to be passed based on the MYHL page          

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
		  
AS  
BEGIN  
/******************************************************************************  
OBJECT:  usp_MyHLEventAPI_Upd_SubeventLocaleDesc  
USE:  
	DECLARE @e int, @em varchar(4000)
	DECLARE @IsDevQA INT  
	DECLARE @SubEvent udt_SubEvents  
     
	INSERT @SubEvent VALUES(3242, 9063, 1,'General Training test', 'General Training locale', 'Trainings', 'board-ln-1', 'darkblue', 'myimage.jpg', 1, 1, 'SubEventGroupNameLocae',1,0)  
     
	EXEC usp_MyHLEventAPI_Upd_SubeventLocaleDesc  
		  @Error = @e OUTPUT  /* @e must be defined in the local call */  
		 ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */  
		 ,@PK_Event = 3242  
		 ,@SubEvent = @SubEvent    
		 ,@LocaleCode = 'nl-BE'  
		,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]
  
DESCRIPTION: Inserts/Updates records in dbo.SubEventLocaleDesc  
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
dbo.SubEventLocaleDesc  
  
VERSIONS  
--------------------------------------------------------------------  
1	2014-02-26	SushmaA			Initial  
2	2017-06-01	Prashanth		Select sub events to display in Bizworks Report
3	2018-08-07	RogelioR		Add [HideToPM] from [SubEventExtn]
4	2019-08-14	NoeG			Refactor code (SRE)

******************************************************************************/  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON  
  
/******************************************************************************  
 VARIABLE DECLARATION  
******************************************************************************/  
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_Locale INT  
DECLARE @PK_DefaultLocale INT  
DECLARE @IsChanged AS TABLE (PK_SubEvent INT, PK_SubEventGroup INT, IsChanged BIT DEFAULT 0)  
  
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode  
SELECT @PK_DefaultLocale = COALESCE(PK_DefaultLocale, 77) FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event  
  
SELECT @Error = 0, @ErrorMessage = '';
  
/******************************************************************************  
 UPDATE LOCALE SUBEVENT TABLE IF SUBEVENTGROUP IS CHANGED  
******************************************************************************/  
  
BEGIN TRY  
  
	IF @PK_Locale = @PK_DefaultLocale  
	BEGIN  
  
	 --updates when PK_SubEventGroup = 0  
   
	 UPDATE L SET   
	  L.SubEventGroupNameLocale = NULL  
	 FROM   
	  dbo.SubEventLocaleDesc L WITH (NOLOCK)   
	 JOIN   
	  @SubEvent SE   
	 ON   
	  L.PK_Subevent = SE.PK_Subevent   
	 WHERE   
	  L.PK_Event = @PK_Event   
	 AND   
	  SE.PK_SubEventGroup = 0  
   
   
	 INSERT INTO @IsChanged (PK_SubEvent, PK_SubEventGroup, IsChanged)  
	 SELECT  S.PK_SubEvent, SE.PK_SubEventGroup, (CASE WHEN S.PK_SubEventGroup <> SE.PK_SubEventGroup THEN 1 ELSE 0 END) FROM @SubEvent SE   
	  INNER JOIN dbo.SubEvent S WITH (NOLOCK) ON SE.PK_SubEvent = S.PK_SubEvent  
    
	 IF EXISTS (SELECT 1 FROM @IsChanged WHERE IsChanged = 1)   
	 BEGIN  
	   UPDATE L   
	   SET L.SubEventGroupNameLocale = LA.SubEventGroupNameLocale  
	   --SELECT L.SubEventGroupNameLocale, LA.SubEventGroupNameLocale, L.PK_SubEventLocaleDesc, LA.PK_SubEventLocaleDesc, LA.PK_SubEventGroup, L.PK_Locale  
	   FROM dbo.SubEventLocaleDesc L WITH (NOLOCK)    
	   JOIN  
	   (  
		SELECT DISTINCT  I.PK_SubEvent [SubEventToBeChanged], I.PK_SubEventGroup, SLU.PK_Locale, SLU.SubEventGroupNameLocale  
			,SL.PK_SubEventLocaleDesc  
		FROM @IsChanged I   
		JOIN   
		 dbo.SubEvent S WITH (NOLOCK)  
		ON   
		 S.PK_Event = @PK_Event   
		AND  
		 S.PK_SubEvent = I.PK_SubEvent  
		JOIN  
		(  
		 SELECT DISTINCT SL.PK_Locale, SL.SubEventGroupNameLocale, SE.PK_SubEventGroup, SE.PK_SubEvent  
		 from SubEventLocaleDesc sl WITH (NOLOCK) inner join dbo.SubEvent SE WITH (NOLOCK) on sl.PK_Subevent = SE.PK_SubEvent AND SE.PK_Event = sl.PK_Event   
		 WHERE SE.PK_Event = @PK_Event       
		)SLU ON I.PK_SubEventGroup = SLU.PK_SubEventGroup  AND SLU.PK_SubEvent <> I.PK_SubEvent        
		JOIN  
		 dbo.SubEventLocaleDesc SL WITH (NOLOCK)  
		ON  
		 I.PK_SubEvent = SL.PK_Subevent  
		AND  
		 SL.PK_Locale <> SL.PK_DefaultLocale  
		AND  
		 SL.PK_Locale = SLU.PK_Locale  
		WHERE   
		 I.IsChanged = 1  
		) LA  
	   ON L.PK_Event = @PK_Event AND L.PK_SuBEventLocaleDesc = LA.PK_SuBEventLocaleDesc AND L.PK_Locale = LA.PK_Locale  
	 END  
  
	END  
  
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
 UPDATE LOCALE SUBEVENT TABLE  
******************************************************************************/  
  
BEGIN TRY  
  
	MERGE dbo.[SubEventLocaleDesc] SEL  
	 USING  
	 (  
	  SELECT @PK_Event AS [PK_Event], @PK_Locale [PK_Locale], @PK_DefaultLocale [PK_DefaultLocale]  
	  ,SE.PK_SubEvent, SE.SubEventNumber, SE.SubEventName, SE.SubEventQualTxt, SE.QualDesc, SE.[Image]  
	  , SE.SubEventGroupNameLocale  
	  FROM @SubEvent SE  
	  INNER JOIN dbo.SubEvent S  WITH (NOLOCK)
	   ON SE.PK_SubEvent = S.PK_SubEvent  
	 ) AS M  
	 ON SEL.[PK_Event] = M.[PK_Event]  
	 AND SEL.PK_SubEvent = M.PK_SubEvent  
	 AND SEL.PK_Locale = M.PK_Locale  
	 WHEN NOT MATCHED THEN INSERT (PK_Event, PK_Subevent, PK_DefaultLocale, SubEventName, PK_Locale, SubEventQualDesc, QualDesc, [Image], SubEventGroupNameLocale)  
	  VALUES(M.PK_Event, M.PK_SubEvent, M.PK_DefaultLocale, M.SubEventName, M.PK_Locale, M.SubEventQualTxt, M.QualDesc, M.[Image], M.SubEventGroupNameLocale)  
	 WHEN MATCHED THEN UPDATE SET  
	  [SubEventQualDesc] = M.[SubEventQualTxt]  
	 ,[SubEventName] = M.[SubEventName]  
	 ,[QualDesc] = M.QualDesc   
	 ,[Image] = M.[Image]  
	 ,[SubEventGroupNameLocale] = M.[SubEventGroupNameLocale]  
	 ,[ModifiedDateUTC] = @StartTime   
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
  
	MERGE dbo.[SubEventExtn] SEE  
	 USING  (  
		  SELECT @PK_Event AS [PK_Event], SE.PK_SubEvent, SE.Icon, SE.Color, SE.HideToPM 
			FROM @SubEvent SE  
				INNER JOIN dbo.SubEvent S WITH (NOLOCK) ON SE.PK_SubEvent = S.PK_SubEvent  
		 ) AS M  ON SEE.[PK_Event] = M.[PK_Event]  
			AND SEE.[PK_SubEvent] = M.[PK_SubEvent]  
	 WHEN NOT MATCHED THEN INSERT (PK_Event, PK_Subevent, Icon, Color, HideToPM)  
	  VALUES(M.PK_Event, M.PK_SubEvent, M.Icon, M.Color, M.HideToPM)  
	 WHEN MATCHED THEN UPDATE SET  
	  [Icon] = M.[Icon]  
	 ,[Color] = M.[Color]  
	 ,[ModifiedDateUTC] = @StartTime
	 ,[HideToPM] = M.[HideToPM]
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
  
	MERGE dbo.[SubEvent] SE  
	 USING  
	 (  
	  SELECT SE.PK_Event, SE.PK_SubEvent, CASE WHEN SE.PK_SubEventGroup = 0 THEN NULL ELSE SE.PK_SubEventGroup END [PK_SubEventGroup], SE.IsTrackingVisible,SE.IncludeInBizworkReport  
	  FROM @SubEvent SE  
	  INNER JOIN dbo.SubEvent S  WITH (NOLOCK)
	   ON SE.PK_SubEvent = S.PK_SubEvent  
	   AND SE.PK_Event = S.PK_Event  
	 ) AS M  
	 ON SE.[PK_Event] = M.[PK_Event]  
	 AND SE.[PK_SubEvent] = M.[PK_SubEvent]  
	 WHEN MATCHED THEN UPDATE SET  
	  [PK_SubEventGroup] = M.[PK_SubEventGroup]  
	 ,[IsTrackingVisible] = M.[IsTrackingVisible]  
	 ,[IncludeInBizworkReport] = M.[IncludeInBizworkReport]
	 ,[ModifiedDateUTC] = @StartTime   
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

  
/******************************************************************************  
 UPDATE PROCESSING LOG  
******************************************************************************/  
EXEC dbo.usp_Utility_UpdateProcessingLog   
 @StoredProcedureName = @StoredProcedure  
 ,@StartTime = @StartTime  
  
/******************************************************************************  
 END PROCEDURE  
******************************************************************************/  
END
GO

