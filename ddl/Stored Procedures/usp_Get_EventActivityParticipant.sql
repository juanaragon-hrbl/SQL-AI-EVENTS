CREATE PROCEDURE [dbo].[usp_Get_EventActivityParticipant]
	@PK_EventActivityTransaction Int,
	@Locale Varchar(5) = 'en-US'
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_Get_EventActivityParticipant

USE:	        EXEC dbo.usp_Get_EventActivityParticipant
					@PK_EventActivityTransaction

DESCRIPTION:	Get the list of participants based on the transaction ID

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2015-07-30	ThomasG		Intitial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON


	;WITH MealTypeLocale(PK_MealType, MealType, PK_Locale)
	AS
	(SELECT PK_MealType, MealType, ML.PK_Locale
	 FROM dbo.MealTypeLocale ML (NoLock)
	 INNER JOIN
		dbo.Locales L (NoLock)
     ON ML.PK_Locale = L.PK_Locale
	 AND L.LocaleCode = @Locale
	 )	
	Select 
		P.PK_EventActivityParticipant,
		P.PK_EventActivityTransaction,
		T.ConfirmationNumber, 
		P.Name,
		P.Email,
		P.PhoneNumber,
		P.DOB,
		L.LanguageName TourLanguage,
		L.LanguageNativeName TourLanguageLocalized, 
		P.IdentificationNumber,
		P.IdentificationExpDate,
		P.IsDistributor,
		P.PK_MealType,
		M.MealType,
		ML.MealType MealTypeLocalized, 
		P.MealNote,
		P.TourLanguage [TourLanguageID],
		P.FlightOption
	From dbo.EventActivityParticipant P (NoLock)
		Inner Join dbo.EventActivityTransaction T (NoLock)
			On P.PK_EventActivityTransaction = T.PK_EventActivityTransaction
		Left Join GlobalOps.dbo.HiTra_t_Language L (NoLock) 
			On P.TourLanguage = L.LanguageID
		Left Join dbo.MealType M (NoLock)
			On P.PK_MealType = M.PK_MealType
		Left Join MealTypeLocale ML (NoLock)
			On M.PK_MealType = ML.PK_MealType
	Where T.PK_EventActivityTransaction = @PK_EventActivityTransaction

END