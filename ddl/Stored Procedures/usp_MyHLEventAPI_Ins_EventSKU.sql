CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Ins_EventSKU]
		-- Mandatory Parameters
		    @PK_Event INT
		   ,@SKUDetails [udt_SKUDetails] READONLY
		-- Error Parameters
		  ,@Error	INT = 0 OUTPUT
		  ,@ErrorMessage VARCHAR(4000) = '' OUTPUT
		-- QA/DEV
		  ,@IsDevQA BIT = 0
AS 

BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Ins_EventSKU
USE:
			declare @e int
			declare @em varchar(200)
			declare @IsDevQA int
			declare @EventID int
			DECLARE @SKU as udt_SKUDetails;

			insert @SKU (SKUCode,CountryCode, LocaleCode,SKUBeginDate,SKUEndDate)
			values ('A001','US','en-US','2012-10-01','2012-10-15')
			,('B001','BR','pt-BR','2012-10-01',null)
			,('C001','CR','es-CR',null,'2012-10-15')

			EXEC usp_MyHLEventAPI_Ins_EventSKU
					1025
					,@SKU
					,@e
					,@em
					

DESCRIPTION:	Inserts SKUCode into the EventSKU Table

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventSKU

VERSIONS
--------------------------------------------------------------------
	1.0.0	  2011-02-25	   PrabhuS	       Initial
	1.1.0	  2013-02-07       SandhyaP	       Changed the @SKUCountryCode parameter comma text field to @SKUDetails table variable
	1.2.0     2019-10-17       puertac		   SRE Implementation 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure VARCHAR(100)
DECLARE @StartTime DATETIME
DECLARE @SKUCountry TABLE (PK INT IDENTITY(1,1), SKUCode VARCHAR(4), CountryCode CHAR(2), PK_Country INT, LocaleCode CHAR(5), PK_Locale INT, SKUBeginDate DATETIME, SKUEndDate DATETIME)
DECLARE @EXTRACT VARCHAR(20)
DECLARE @START INT
DECLARE @StateDate DATETIME
DECLARE @Enddate DATETIME

/* SET THE VALUES FOR THE LOCAL VARIABLES */
SET @ErrorMessage = 'No Error.'
SET @StoredProcedure = 'usp_MyHLEventAPI_Ins_EventSKU'
SET @StartTime = GETUTCDATE()
SELECT @StateDate = CreateddateUTC-1 FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event
SELECT @Enddate = dEndUTC FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

IF NOT EXISTS (SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event)

BEGIN

	SET @Error = 1
	SET @ErrorMessage = 'There is no master record for this EventID'

END
ELSE
BEGIN

/* EXTRACT THE SKUCODE & COUNTRYCODE SEPARATELY FROM THE PASSED STRING */
--WHILE LEN(@SKUCountryCode) > 0

--BEGIN
--SET @START = CHARINDEX(';',@SKUCountryCode,1)

--SET @EXTRACT = SUBSTRING (@SKUCountryCode , 1, @START-1)

--INSERT INTO @SKUCountry (SKUCode, CountryCode, LocaleCode)
--SELECT
--	 SUBSTRING(@EXTRACT ,1,CHARINDEX(',',@EXTRACT)-1)
--	,SUBSTRING (@EXTRACT,CHARINDEX(',',@EXTRACT)+ 1,2)
--	,SUBSTRING (@EXTRACT,CHARINDEX(',',@EXTRACT)+ 4,5)
	
--SET @SKUCountryCode = SUBSTRING(@SKUCountryCode , @START +1,LEN(@SKUCountryCode))


/**** Reads from @SKUDetails **** commented the above part ****/

INSERT @SKUCountry (SKUCode, CountryCode, LocaleCode, SKUBeginDate, SKUEndDate)
SELECT SKUCode, CountryCode, LocaleCode, SKUBeginDate, SKUEndDate 
FROM @SKUDetails

END

/* UPDATE THE PK_Country VALUE FOR THE EXTRACTED COUNTRY LIST */
UPDATE
	T
SET
	T.PK_Country = C.nCountryID
FROM
	@SKUCountry T
INNER JOIN
	dbo.v_Countries C
ON
	T.CountryCode = C.sCountryCodeISO


/* UPDATE THE PK_Locale VALUE FOR THE EXTRACTED Locale Codes */
UPDATE
	T
SET
	T.PK_Locale = C.PK_Locale
FROM
	@SKUCountry T
INNER JOIN
	dbo.Locales C
ON
	T.LocaleCode = C.LocaleCode

/* INSERT THE SKU RECORDS IN TO THE EVENTSKU TABLE */
BEGIN TRY
INSERT
	dbo.EventSKU
(
	 PK_Event
	,SKUCode
	,SKUValidBeginUTC
	,SKUValidEndUTC
	,PK_EventSKUType
	,PK_Country
	,IsEventTicketSKU
	,PK_Locale
)
SELECT
	 @PK_Event
	,SKUCode
	,SKUBeginDate
	,SKUEndDate
	,1
	,PK_Country
	,1
	,PK_Locale
FROM
	@SKUCountry

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
			,@ErrorMessage = @ErrorMessage OUTPUT
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
	
	