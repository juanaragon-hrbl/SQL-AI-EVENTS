
CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_DSAccess]	
	-- MANDATORY
	@DSAccess udt_DSAccess READONLY
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/*
OBJECT:		dbo.usp_EventsAT_Upd_DSAccess

USE:
			DECLARE @e int, @em varchar(4000)
			DECLARE @DSAccess udt_DSAccess
			
			INSERT INTO @DSAccess 
			VALUES  ('1111111111',799,1)
			,('1111111111',849,1)

			EXEC usp_EventsAT_Upd_DSAccess
					@DSAccess = @DSAccess
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
	                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
			
DESCRIPTION:	Update/Insert records into EventDSAccess

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2012-10-07		OrlandoL		Initial
2	2019-08-08		NoeG			Refactor code (SRE)
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @nDistributorID INT
DECLARE @sCountryCode varchar(2)
DECLARE @sDistributorID varchar(10)

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

SELECT @sDistributorID = (SELECT TOP 1 DistributorID FROM @DSAccess)

SELECT 
	@nDistributorID = B.nDistributorID 
	--,@sCountryCode = sDistributorCountryProcessingCode
FROM 
	dbo.v_Distributor B WITH(NOLOCK)
WHERE
	B.sDistributorID  = @sDistributorID


/******************************************************************************
	Declare a table to store the udt_DSAccess
******************************************************************************/
DECLARE @tblDSAccess TABLE (
	[PK_Distributor] INT,
	[DistributorID] NVARCHAR(50),
	[PK_EventSubTypeLocaleDesc] INT,
	[CheckedYN] [INT]
)

INSERT
	@tblDSAccess
(
	PK_Distributor
	,[DistributorID] 
	,[PK_EventSubTypeLocaleDesc]	
	,[CheckedYN]
)
SELECT
	 @nDistributorID
	,[DistributorID] 
	,DS.[PK_EventSubTypeLocaleDesc]
	,[CheckedYN]
FROM
	@DSAccess DS
INNER JOIN
	dbo.EventSubTypeLocaleDesc ESL WITH(NOLOCK)
	ON
		DS.[PK_EventSubTypeLocaleDesc] = ESL.PK_EventSubTypeLocaleDesc
--INNER JOIN 
--	dbo.Locales L	
--	ON
--		ESL.PK_Locale = L.PK_Locale
--WHERE
--	SUBSTRING(L.LocaleCode,4,LEN(L.LocaleCode)) = @sCountryCode
	
/******************************************************************************
  Insert New Master Events and SubEvents that are assigned to Distributor
******************************************************************************/
BEGIN TRY 

 
INSERT 
	[dbo].[EventDSAccess]
(
   [PK_Distributor]
   ,[DistributorID]
   ,[PK_EventSubTypeLocaleDesc]

)
SELECT DISTINCT
	DA.PK_Distributor
	,DA.DistributorID
	,DA.PK_EventSubTypeLocaleDesc
FROM
	@tblDSAccess DA

WHERE NOT EXISTS (SELECT PK_Distributor FROM dbo.EventDSAccess WITH(NOLOCK) WHERE PK_Distributor = DA.PK_Distributor AND PK_EventSubTypeLocaleDesc = DA.PK_EventSubTypeLocaleDesc)	
AND DA.CheckedYN  = 1
		
/******************************************************************************
  Delete Events and SubEvents that are assigned to Distributor
******************************************************************************/
	
DELETE 
	EDA
FROM
	dbo.EventDSAccess EDA WITH(NOLOCK)
INNER JOIN
	@tblDSAccess DS
	ON
		EDA.DistributorID = DS.DistributorID	
		AND 
		DS.PK_EventSubTypeLocaleDesc = EDA.PK_EventSubTypeLocaleDesc
WHERE 
	DS.CheckedYN = 0	
	
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
	end procedure
******************************************************************************/
END
