CREATE PROCEDURE [dbo].[usp_EventActivityByDS]
	@PK_EventActivity Int,		-- Identifier for EventActivity
	@DistributorID Varchar(30),
	@Locale Varchar(5) = 'en-US'
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventActivityByDS

USE:	        EXEC dbo.usp_EventActivityByDS
					@PK_EventActivity = 11, 
					@DistributorID = '2222222222',
					@Locale = 'en-US'

DESCRIPTION:	Check amount of EventActivity tickets MB has already purchased 
				or pending purchase along with how much he/she is allowed to purchase

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2015-07-05	ThomasG		Intitial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	-- Declaration of Variables
	Declare @CompQtyAllowed Int, @TicketPurchased Int, @TicketPending Int, 
		@CompQty Int, @TotalPaid Numeric(17,4), @CurrencyType Varchar(3), 
		@CompQtyPerDS Int, @MaxQtyPerDS Int, @PK_Event Int

	-- Determine Comp Qty Per DS and Max Qty Per DS
	Select @CompQtyPerDS = IsNull(CompQtyPerDS,0), 
		@MaxQtyPerDS = IsNull(MaxQtyPerDS, 0)
	From dbo.EventActivity (NoLock) 
	Where PK_EventActivity = @PK_EventActivity

	-- Determine Comp Qty allowed for DS
	Select @CompQtyAllowed = Case When SpouseFirstName Is Null And SpouseLastName Is Null Then 1 Else 2 End
	From PubEvents.dbo.dimDistributor (NoLock) 
	Where DistributorID = @DistributorID
		And PK_DSStatus = 3	-- DS Status Complete

	-- Sum up all tickets purchased by DS
	Select @TicketPurchased = IsNull(Sum(T.TotalQty),0), 
		@CompQty = IsNull(Sum(T.CompQty),0), 
		@TotalPaid = IsNull(Sum(T.TotalPrice),0), 
		@CurrencyType = A.CurrencyType
	From dbo.EventActivityTransaction T (NoLock) 
		Inner Join dbo.EventActivity A (NoLock) 
			On T.PK_EventActivity = A.PK_EventActivity
	Where A.PK_EventActivity = @PK_EventActivity
		And ConfirmationNumber Is Not Null
		And DistributorID = @DistributorID
	Group By A.CurrencyType

	Select @TicketPending = IsNull(Sum(TotalQty),0)
	From dbo.EventActivityTransaction (NoLock) 
	Where PK_EventActivity = @PK_EventActivity
		And PK_TransactionStatus In (1,2,12)	-- Registering, Paying, Payment Error
		And DistributorID = @DistributorID

	Select @PK_Event = PK_Event from dbo.EventActivity (Nolock) Where PK_EventActivity = @PK_EventActivity

	-- Return result of current DS
	Select D.DistributorID, 
		D.FirstName, D.LastName, D.MiddleName, 
		D.SpouseFirstName, D.SpouseLastName, D.SpouseMiddleName, 
		DS.sEmail as Email, DS.Phone, 
		@TicketPurchased TicketPurchased, 
		@TotalPaid TotalPaid, 
		@CurrencyType CurrencyType, 
		@TicketPending TicketPending, 
		@CompQtyAllowed CompQtyAllowed, 
		@CompQty CompQty, 
		@MaxQtyPerDS MaxQtyPerDS,
		COALESCE(T.GuestFirstName,'') GuestFirstName,
		COALESCE(T.GuestLastName, '') GuestLastName,
		T.PK_TempGuest GuestID
	From PubEvents.dbo.dimDistributor (NoLock) D
	INNER JOIN dbo.v_Distributor DS 
	ON DS.sDistributorID = D.DistributorID
	LEFT JOIN dbo.TempGuests (NOLOCK) T
	ON D.Distributorid = T.Distributorid
	AND T.PK_Event = @PK_Event
	Where D.DistributorID = @DistributorID
		And PK_DSStatus = 3	-- DS Status Complete

	;WITH MealTypeLocale(PK_MealType, MealType, PK_Locale)
	AS
	(SELECT PK_MealType, MealType, ML.PK_Locale
	 FROM dbo.MealTypeLocale ML WITH (NOLOCK)
	 INNER JOIN
		dbo.Locales L WITH (NOLOCK)
     ON ML.PK_Locale = L.PK_Locale
	 AND L.LocaleCode = @Locale
	 )	 
	-- Get participants for all confirmed/approved transactions
	Select P.PK_EventActivityParticipant, 
		P.PK_EventActivityTransaction, 
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
		COALESCE(ML.MealType, M.MealType) MealTypeLocalized, 
		P.MealNote, 
		T.ConfirmationNumber,
		P.TourLanguage [TourLanguageID],
		P.FlightOption
	From dbo.EventActivityParticipant P WITH (NOLOCK)
		Inner Join dbo.EventActivityTransaction T WITH (NOLOCK)
			On P.PK_EventActivityTransaction = T.PK_EventActivityTransaction
		Left Join PubData.dbo.HiTra_t_Language L WITH (NOLOCK)
			On P.TourLanguage = L.LanguageID
		Left Join dbo.MealType M WITH (NOLOCK)
			On P.PK_MealType = M.PK_MealType
		Left Join MealTypeLocale ML WITH (NOLOCK)
			On M.PK_MealType = ML.PK_MealType		
	Where T.PK_EventActivity = @PK_EventActivity
		And T.DistributorID = @DistributorID
		And T.PK_TransactionStatus In (3,8) -- Confirmed transaction
		And T.ConfirmationNumber Is Not Null
END