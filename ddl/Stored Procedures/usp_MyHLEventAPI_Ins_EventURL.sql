
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Ins_EventURL]
     -- Mandatory Parameters
	 @EventURL [udt_EventURL] READONLY

	 -- Optional
	 ,@PK_EventURLType	int = 1

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
	

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Ins_EventURL
USE:
			DECLARE @e int, @em varchar(4000)
			DECLARE @IsDevQA int
			DECLARE @EventURL [udt_EventURL]
			
			INSERT INTO @EventURL VALUES (0, 9576, 'es-AR', 'http://www.Yahoo.com', N'Me gusta mucho este sof�', NULL, 0 )  --INSERT
			, (6313, 9576, 'es-AR', 'http://www.Yahoo.com', N'Me gusta mucho este sof�', NULL, 0 ) --UPDATE
			, (6313, 9576, 'es-AR', 'http://www.Yahoo.com', N'Me gusta mucho este sof�', NULL, 1 ) --DELETE
			
			EXEC usp_MyHLEventAPI_Ins_EventURL
					 @EventURL
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

			
DESCRIPTION:	Inserts/updates/Deletes record(s) into/in/from dbo.EventURL table

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventURL

VERSIONS
--------------------------------------------------------------------
1	2010-12-07				PrabhuS				Initial
2	2011-01-28				PrabhuS				Updated to include Locale, Delete
3	2012-02-13				Sushma B			Changed it to table variable implementation
4	2017-05-09				RogelioR			Add parameter @PK_EventURLType to specify URL type
5	2019-08-14				NoeG				Refactor code (SRE)

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

SELECT @Error = 0, @ErrorMessage = '';
--SET @EventURL = LTRIM(RTRIM(@EventURL))
--SET @EventURLDesc = LTRIM(RTRIM(@EventURLDesc))
--SELECT @PK_Locale = PK_Locale FROM dbo.Locales WHERE LocaleCode = @LocaleCode


BEGIN TRY

	MERGE dbo.[EventURL] EUR
	USING
	(
		SELECT EUR.[PK_EventURL] 
		,EUR.[PK_Event]
		,EUR.[LocaleCode] 
		,EUR.[EventURL] 
		,EUR.[EventURLDesc]
		,EUR.[Flyer] 
		,EUR.[IsDelete]
		,L.PK_Locale, @PK_EventURLType AS PK_EventURLType
		FROM @EventURL EUR
		INNER JOIN
			dbo.Locales L WITH (NOLOCK)
			ON
			EUR.localeCode = L.LocaleCode
	) AS M
	ON M.PK_Event = EUR.PK_Event
	AND M.PK_EventURL = EUR.PK_EventURL
	AND M.PK_Locale = EUR.PK_Locale
	WHEN NOT MATCHED THEN INSERT (PK_Event, PK_Locale, EventURL, EventURLDesc, PK_EventURLType)
	VALUES(M.PK_Event, M.PK_Locale, M.EventURL, M.EventURLDesc, M.PK_EventURLType)
	WHEN MATCHED AND M.IsDelete = 1 THEN DELETE
	WHEN MATCHED AND M.IsDelete = 0 THEN
	UPDATE
	SET EventURL = LTRIM(RTRIM(M.EventURL))
	, EventURLDesc = LTRIM(RTRIM(M.EventURLDesc))
	, PK_EventURLType = M.PK_EventURLType
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
