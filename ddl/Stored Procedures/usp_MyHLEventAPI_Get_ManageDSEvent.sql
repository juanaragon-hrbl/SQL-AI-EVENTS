CREATE PROCEDURE dbo.usp_MyHLEventAPI_Get_ManageDSEvent
        -- Mandatory Parameters
         @UserID varchar(30)
		,@PK_Event INT
		,@LocaleCode CHAR(5)
		,@DistributorID VARCHAR(10)
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_ManageDSEvent

USE:
				DECLARE @e int, @em varchar(4000)
                 EXEC dbo.usp_MyHLEventAPI_Get_ManageDSEvent
						@UserID = 'SandhyaP'
					 	,@PK_Event = 5867
						,@LocaleCode = 'en-US'
						,@DistributorID = 'W1010993'
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
		                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]


DESCRIPTION:	Retrieves all the records for associated DS Event based on the PK_Event passed

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.EventManageDetails, dbo.EventURL, dbo.EventLocaleDesc

VERSIONS
----------------------------------------------------------------------------------
	1.0.0	2013-08-21		Sushma		Intitial
	1.1.0	2019-08-14		NoeG		Refactor code (SRE)
	1.2.0	2019-10-16      puertac		SRE Implementation

******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @PK_EventType INT
DECLARE @HasAccess INT

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @PK_Event

SELECT @Error = 0, @ErrorMessage = '';

/*Hide Deleted Events*/
IF EXISTS (SELECT 1 FROM dbo.EventDeleteQueue WITH(NOLOCK) WHERE PK_Event = @PK_Event)
BEGIN
	RETURN
END

BEGIN TRY
	/*Retrieve the EventManageDetails Previous Event info*/
	SELECT
		E.PK_Event
	   ,E.PK_RefEvent
	   ,E.PK_EventManageDetails
	   ,ER.EventName
	   ,ER.dStartUTC EventStartDate
	   ,ER.dEndUTC EventEndDate  
	   ,E.ActualDS
	   ,E.EstimatedDS
	   ,E.ActualNonDS
	   ,E.EstimatedNonDS
	   ,EMP.ActualDS [ReferenceActualDS]
	   ,EMP.EstimatedDS [ReferenceEstimatedDS]
	   ,EMP.ActualNonDS [ReferenceActualNonDS]
	   ,EMP.EstimatedNonDS [ReferenceEstimatedNonDS]
	   ,ED.PK_DefaultLocale
	   ,ED.PK_EventLocaleDesc
	   ,ED.DistributorNotes
	   ,ED.PK_Locale
	   ,@LocaleCode [LocaleCode]
	   ,E.ContactName
	   ,E.ContactPhone
	   ,E.ContactEmail
	   ,E.Street
	   ,E.City
	   ,E.State
	   ,E.ZipCode
   
	FROM	
		dbo.EventManageDetails E WITH(NOLOCK)
	INNER JOIN
		dbo.Event EP WITH(NOLOCK) 
	ON
		E.PK_Event = EP.PK_Event
	LEFT JOIN
		dbo.Event ER WITH(NOLOCK) 
	ON
		E.PK_RefEvent = ER.PK_Event
	LEFT JOIN
		dbo.EventLocaleDesc  ED WITH(NOLOCK)
	ON
		E.PK_Event = ED.PK_Event
	AND
		ED.PK_DefaultLocale = @PK_DefaultLocale
	LEFT JOIN
		dbo.EventManageDetails EMP WITH(NOLOCK)
	ON
		E.PK_RefEvent = EMP.PK_Event
	WHERE
		E.PK_Event = @PK_Event

	/*Retrieve the File Attachments*/

	SELECT	
		 E.PK_Event
		,E.PK_EventURL
		,E.PK_EventURLType
		,E.PK_Locale
		,E.EventURL
		,E.EventURLDesc
		,E.Flyer
	FROM	
		dbo.EventURL E WITH(NOLOCK)
	WHERE
		PK_Event = @PK_Event
	AND
		PK_EventURLType IN (2)
	
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
END CATCH;
		
/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
