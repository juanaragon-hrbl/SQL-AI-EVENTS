CREATE VIEW v_LanguageMapping
AS
SELECT DL.PK_Language
, DL.LanguageCode
, DL.LanguageName
, Left(Coalesce(L.LocaleCode, ML.LocaleCode, 'en-US'),2) AS Language
FROM
PubEvents.dbo.dimDSLanguage DL (NoLock)
Left Join dbo.MapLanguageCode ML (NoLock)
              On DL.LanguageCode = ML.LanguageCode
Left Join 
       (
              Select Right(LocaleCode,2) CountryCode, 
                     Max(LocaleCode) LocaleCode
              From dbo.Locales 
              Group By Right(LocaleCode,2)
              Having Count(1) = 1
       ) L 
              On ML.LocaleCode = L.LocaleCode
LEFT JOIN
      pubEvents.dbo.dimCountry C
ON
      C.CountryCodeISO = L.CountryCode    
WHERE
      DL.LanguageCode NOT IN ('-1', '-2')