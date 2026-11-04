
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_Distinct_EventSubTypes]
		 @LocaleCode CHAR(5) = NULL
		,@EventTypeCode varchar(7) = 'ALL'
AS
BEGIN
SET NOCOUNT ON

DECLARE @PK_Locale int
DECLARE @PK_DefaultLocale int
DECLARE @tblEventType TABLE (PK_EventType int)

SELECT @PK_Locale = PK_Locale FROM dbo.Localeswith (nolock) WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales(nolock) WHERE LocaleCode = 'en-US'

IF @EventTypeCode = 'ALL'
BEGIN
	INSERT @tblEventType (PK_EventType)
	SELECT PK_EventType FROM dbo.EventType	(nolock)
END 

ELSE

IF @EventTypeCode = 'ALLCORP'
BEGIN
	INSERT @tblEventType (PK_EventType)
	SELECT PK_EventType FROM dbo.EventType(nolock) WHERE EventTypeCode IN ('CP','CE')	
	
END

ELSE

IF @EventTypeCode = 'DE'
BEGIN
	INSERT @tblEventType (PK_EventType)
	SELECT PK_EventType FROM dbo.EventType (nolock) WHERE EventTypeCode = @EventTypeCode
	
END

DECLARE @EventSubTypes TABLE (PK INT IDENTITY(1,1), EventSubTypeGroupMasterName varchar(200), EventSubType varchar(200), EventSubTypeLocal nvarchar(400))


INSERT INTO @EventSubTypes  --- GET THE TRANSLATIONS FIRST
SELECT DISTINCT EventSubTypeGroupMasterName, REPLACE(ES.EventSubType,'�','') EventSubType, REPLACE(COALESCE(ESLD.EventSubTypeDesc,ES.EventSubType),'�','') EventSubTypeLocal
FROM	
	dbo.EventSubTypes ES (nolock)
INNER JOIN 
	@tblEventType T
ON
	T.PK_EventType = ES.PK_EventType
INNER JOIN
	dbo.EventSubTypeLocaleDesc ESLD	(nolock)
	ON
		ES.PK_EventSubType = ESLD.PK_EventSubType
		AND
		ESLD.PK_Locale = COALESCE(@PK_Locale, @PK_DefaultLocale)
INNER JOIN
	dbo.EventSubTypeGroup(NOLOCK) ESG
ON
	ES.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
INNER JOIN
	dbo.EventSubTypeGroupMaster(NOLOCK) ESM
ON
	ESG.PK_EventSubTypeGroupMaster = ESM.PK_EventSubTypeGroupMaster
WHERE
	ES.IsActive = 1
ORDER BY 
	ESM.EventSubTypeGroupMasterName, REPLACE(COALESCE(ESLD.EventSubTypeDesc,ES.EventSubType),'�','')
	
INSERT INTO @EventSubTypes  --- GET THE SUBTYPES THAT DOESN'T HAVE ANY TRANSLATIONS
SELECT DISTINCT EventSubTypeGroupMasterName, REPLACE(ES.EventSubType,'�','') EventSubType, REPLACE(ES.EventSubType,'�','') EventSubTypeLocal
FROM	
	dbo.EventSubTypes ES(nolock)
INNER JOIN 
	@tblEventType T
ON
	T.PK_EventType = ES.PK_EventType	
INNER JOIN
	dbo.EventSubTypeGroup(NOLOCK) ESG
ON
	ES.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
INNER JOIN
	dbo.EventSubTypeGroupMaster(NOLOCK) ESM
ON
	ESG.PK_EventSubTypeGroupMaster = ESM.PK_EventSubTypeGroupMaster
WHERE
	ES.IsActive = 1
	AND
	ES.EventSubType NOT IN (SELECT EventSubType FROM @EventSubTypes WHERE EventSubType IS NOT NULL)
ORDER BY 
	ESM.EventSubTypeGroupMasterName, REPLACE(ES.EventSubType,'�','')

SELECT EventSubType, EventSubTypeLocal  -- SORT THEM TO GET THE TRANSLATIONS FIRST
FROM @EventSubTypes
ORDER BY PK	

END
