CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_TeamLevelAccess]	
	-- MANDATORY
	@TeamLevelAccess udt_TeamLevelAccess READONLY
	
	-- Error Parameters
	,@Error	INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA TINYINT = 0
AS
BEGIN
/****************************************************************************************************************
OBJECT:		dbo.usp_EventsAT_Upd_TeamLevelAccess
USE:
			DECLARE @e int, @em varchar(4000)
			DECLARE @TeamLevelAccess udt_TeamLevelAccess
			
			INSERT INTO @TeamLevelAccess 
			VALUES  ('PT',799,1)
				   ,('QP',798,1)
				   ,('GT',850,0)

			EXEC usp_EventsAT_Upd_TeamLevelAccess
					 @TeamLevelAccess = @TeamLevelAccess
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
	                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
			
DESCRIPTION:	
NOTES:	
DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1.0.0	  2021-05-18		jesussal 		Initial

*************************************************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @nSubTypeCode INT
DECLARE @sSubTypeCode VARCHAR(5)

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

SELECT @sSubTypeCode = (SELECT TOP 1 [SubTypeCode] FROM @TeamLevelAccess)

SELECT @nSubTypeCode = B.PK_DSSubType	 
	--,@sCountryCode = sDistributorCountryProcessingCode
FROM [PubEvents].[dbo].[dimDSSubType] B WITH(NOLOCK)
WHERE B.SubTypeCode  = @sSubTypeCode

BEGIN TRY 

	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END

	/****************************************************************************	
	         Hidden/Transition Team Levels, now linked to QS & QP  
	****************************************************************************/
	DROP TABLE IF EXISTS #TeamCodes		
		
	SELECT SubTypeCode
	      ,PK_EventSubTypeLocaleDesc
	      ,CheckedYN
		  ,[Message]
	INTO #TeamCodes 
	FROM @TeamLevelAccess

IF EXISTS (SELECT 1 FROM #TeamCodes WHERE SubTypeCode = 'QP')
	BEGIN
		INSERT INTO #TeamCodes 
		SELECT  DT.DSTeamTypeCode 
			   ,T.PK_EventSubTypeLocaleDesc
			   ,T.CheckedYN
			   ,T.[Message]
		FROM  DSTeamType DT WITH (NOLOCK)
		INNER JOIN #TeamCodes T
			ON DT.TransitionLevelGroup = T.SubTypeCode
		WHERE DT.TransitionLevelGroup = 'QP' 
	END

	IF EXISTS (SELECT 1 FROM #TeamCodes WHERE SubTypeCode = 'QS')
	BEGIN
		INSERT INTO #TeamCodes 
		SELECT  DT.DSTeamTypeCode 
			   ,T.PK_EventSubTypeLocaleDesc
			   ,T.CheckedYN
			   ,T.[Message]
		FROM  DSTeamType DT WITH (NOLOCK)
		INNER JOIN #TeamCodes T
			ON DT.TransitionLevelGroup = T.SubTypeCode
		WHERE TransitionLevelGroup = 'QS' 
	END

	DROP TABLE IF EXISTS #tblTeamLevelAccess

	CREATE TABLE #tblTeamLevelAccess  (
		[PK_DSSubType] INT,
		[SubTypeCode] NVARCHAR(5),
		[PK_EventSubTypeLocaleDesc] INT,
		[CheckedYN] INT,
		[Message] NVARCHAR(max)
	)

	INSERT INTO #tblTeamLevelAccess
	(
		PK_DSSubType
		,[SubTypeCode] 
		,[PK_EventSubTypeLocaleDesc]	
		,[CheckedYN]
		,[Message]
	)
	SELECT B.[PK_DSSubType]
		  ,TL.[SubTypeCode] 
		  ,TL.[PK_EventSubTypeLocaleDesc]
		  ,[CheckedYN]
		  ,[Message]
	FROM #TeamCodes TL
	INNER JOIN dbo.EventSubTypeLocaleDesc ESL WITH(NOLOCK)
		ON	TL.[PK_EventSubTypeLocaleDesc] = ESL.PK_EventSubTypeLocaleDesc
		inner join [PubEvents].[dbo].[dimDSSubType] B WITH(NOLOCK)
		on B.SubTypeCode  = TL.[SubTypeCode]

	
	/******************************************************************************
	  Insert New Master Events and SubEvents that are assigned to the TeamLevel
	******************************************************************************/ 
	INSERT [dbo].[EventTeamLevelAccess]
	(
		 [PK_DSSubType]
		,[SubTypeCode]
		,[PK_EventSubTypeLocaleDesc]
		,[Message]
	)
	SELECT DISTINCT
		 DA.PK_DSSubType
		,DA.SubTypeCode
		,DA.PK_EventSubTypeLocaleDesc
		,DA.[Message]
	FROM #tblTeamLevelAccess DA
	WHERE NOT EXISTS (SELECT PK_DSSubType FROM dbo.EventTeamLevelAccess WITH(NOLOCK) WHERE PK_DSSubType = DA.PK_DSSubType AND PK_EventSubTypeLocaleDesc = DA.PK_EventSubTypeLocaleDesc)	
	AND DA.CheckedYN  = 1

	/******************************************************************************
		Update Message that are assigned to the TeamLevel
	******************************************************************************/	

	UPDATE  TL
	SET  TL.[Message] = Da.[Message]
	FROM  [dbo].[EventTeamLevelAccess] TL
	INNER JOIN  #tblTeamLevelAccess DA
	On  TL. [PK_DSSubType] = DA.PK_DSSubType and
	TL.[PK_EventSubTypeLocaleDesc] = DA.PK_EventSubTypeLocaleDesc
		
	/******************************************************************************
		Delete Events and SubEvents that are assigned to the TeamLevel
	******************************************************************************/	
	DELETE 	EDA
	FROM dbo.EventTeamLevelAccess EDA 
	INNER JOIN #tblTeamLevelAccess TL
		ON EDA.[SubTypeCode] = TL.SubTypeCode	
		AND TL.PK_EventSubTypeLocaleDesc = EDA.PK_EventSubTypeLocaleDesc
	WHERE TL.CheckedYN = 0	
	
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
END CATCH
END
