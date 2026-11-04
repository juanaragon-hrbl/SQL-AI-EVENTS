CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventsandPromotionsTracker]

		-- Error Parameters
		@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_EventsandPromotionsTracker

USE:  
		DECLARE @e int, @em varchar(4000)   

		EXEC [usp_EventAPI_Get_EventsandPromotionsTracker]
			@Error = @e OUTPUT				-- @e must be defined in the local call   
			,@ErrorMessage = @em OUTPUT		-- @em must be defined in the local call   
			,@IsDevQA = 1  

		Print @em  

DESCRIPTION:	Provides all the active events and promotions list for each eventcountry to be used for HCM/GOC application

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.Event, dbo.EventDistributorCountryLocales, dbo.SubEventQualification

VERSIONS
--------------------------------------------------------------------
1	2015-01-22	SushmaA		Initial
2	2017-02-21	RogelioR	Include Events that don't have SubEvents
3	2019-09-05	NoeG		SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT DISTINCT
				E.PK_Event
				,E.PK_EventType 
				,E.EventName
				,C.nCountryID [PK_Country]
				,C.sCountryCodeISO [sCountryCode]
				,L.LocaleCode
		FROM	
			dbo.Event E WITH (NOLOCK)
		LEFT JOIN
			dbo.SubEvent SE WITH (NOLOCK)
		ON
			E.PK_Event = SE.PK_Event
		INNER JOIN
			dbo.EventDistributorCountryLocales EC WITH (NOLOCK)
		ON
			E.PK_Event = EC.PK_Event
		INNER JOIN
			dbo.Locales L WITH (NOLOCK)
		ON
			EC.PK_Locale = L.PK_Locale
		INNER JOIN
			dbo.v_Countries C WITH (NOLOCK)
		ON
			SUBSTRING(L.LocaleCode, 4, 2) = C.sCountryCodeISO
		WHERE
			E.PK_EventType IN (1,2)
		AND
			GETUTCDATE() <= E.dEndUTC+1
		AND
			GETUTCDATE() BETWEEN E.DisplayStartDate AND (E.DisplayEndDate+1)
		AND
			E.IsActive = 1
		AND
			E.IsPublish = 1

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

END
GO

