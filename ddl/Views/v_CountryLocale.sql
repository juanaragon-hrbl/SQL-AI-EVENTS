

CREATE View [dbo].[v_CountryLocale] 
As
Select C.nCountryID, 
	C.sCountryCode, 
	C.sCountryCodeISO,
	C.sCountryName, 
	C.sRegionCode, 
	C.sRegionLabel, 
	IsNull(L.LocaleCode,'en-' + C.sCountryCodeISO) sLocaleCode, 
	IsNull(L.LanguageCountryRegion, C.sCountryName + ' - English') sLanguageCountryRegion, 
	Convert(Nvarchar(50),Case When Left(L.LocaleCode,2)='bs' Then 'Bosnian' Else tL.LanguageName End) sLanguageName
From dbo.v_Countries C 
	Left Join dbo.Locales L (NoLock) 
		On ISNULL(
			Case 
				When C.sCountryName = 'Russia' And C.sCountryCodeISO Is Null Then 'RU' 
				Else C.sCountryCodeISO 
			End,C.sCountryCodeISO) = RIGHT(L.LocaleCode,2)
	Left Join pubData.dbo.HiTra_t_Language tL (NoLock) 
		On ISNULL(
			Case 
				When C.sCountryName = 'Russia' And C.sCountryCodeISO Is Null Then 'ru' 
				Else LEFT(L.LocaleCode,2) 
			End,'en') = tL.LanguageCode_Old
Where C.sRegionCode Is Not Null