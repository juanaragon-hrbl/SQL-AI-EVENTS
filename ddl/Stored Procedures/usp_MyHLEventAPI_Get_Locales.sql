
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_Locales] 
		-- Optional Parameters	
		@UserID VARCHAR(30) = NULL
		,@IsMember BIT = 0
		
	            
AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_Locales

USE:	        DECLARE @e INT, @em VARCHAR(20)
                 EXEC dbo.usp_MyHLEventAPI_Get_Locales
                     -- Mandatory Parameters
                     @UserID = '420025069'
                     ,@IsMember = 1
                     
                     select * from dbo.EVENTATACCESSUSER
					 select top 10 * from dbo.eventdsaccess
                 
DESCRIPTION:	Retrieves all locales based on user access

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2016-06-20			SandhyaP			Intitial
******************************************************************************/


/*******************************************************************************************
	POPULATE LOCALES DRIVEN BY USER/MEMBER ACCESS IF PROVIDED ELSE DEFAULT LOCALE LIST
*******************************************************************************************/

;WITH StaffAccess (PK_Locale,  LocaleCode, LanguageCountryRegion)
AS
(
SELECT
	 L.PK_Locale
	,L.LocaleCode
	,L.LanguageCountryRegion
FROM
	dbo.Locales L (nolock)
INNER JOIN
	dbo.EventATAccessUserModules EUM (nolock)
ON
	EUM.PK_Locale = L.PK_Locale
INNER JOIN
	dbo.EventATAccessUser EU (nolock)
ON
	EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
WHERE
	EU.EventATAccessUserName = @UserID	
	AND 
	@IsMember = 0				
)
,DSAccess (PK_Locale, LocaleCode, LanguageCountryRegion)
AS
(
SELECT
	 L.PK_Locale
	,L.LocaleCode
	,L.LanguageCountryRegion
FROM 
	dbo.Locales L (nolock)
INNER JOIN
	dbo.EventSubTypeLocaleDesc ESL  (nolock)
ON   
	L.PK_Locale=ESL.PK_Locale 
INNER JOIN
	dbo.EventDSAccess EDA (nolock)
ON
	ESL.PK_EventSubTypeLocaleDesc=EDA.PK_EventSubTypeLocaleDesc
WHERE
	EDA.DistributorID = @UserID	
	AND 
	@IsMember = 1					
)
SELECT DISTINCT
	 L.PK_Locale
	,L.LocaleCode
	,L.LanguageCountryRegion
FROM 
	dbo.Locales L (NOLOCK)
LEFT JOIN
	StaffAccess S
ON
	L.PK_Locale = S.PK_Locale
LEFT JOIN
	DSAccess D
ON
	L.PK_Locale = D.PK_Locale
WHERE
	L.PK_Locale = CASE WHEN @UserID <> '' AND @IsMember = 0 THEN S.PK_Locale 
								WHEN @UserID <> '' AND @IsMember = 1 THEN D.PK_Locale ELSE L.PK_Locale END


/******************************************************************************
	END PROCEDURE
******************************************************************************/
END