CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventsPreRegistrationReport]
        --Mandatory Parameters
		 @PK_Event INT

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_EventsPreRegistrationReport
USE:
			DECLARE @e int, @em varchar(max)

			EXEC usp_EventAPI_Get_EventsPreRegistrationReport
					 @PK_Event = 777
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves a record from dbo.EventsRegistration

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventsRegistration

VERSIONS
--------------------------------------------------------------------
1	2013-01-17	Sushma	Initial
2	2019-09-05	NoeG	SRE template applied

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON	

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
	DECLARE @EventType INT
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT @EventType = PK_EventType FROM dbo.Event WITH (nolock) WHERE PK_Event = @PK_Event

		IF @EventType IS NULL 
		BEGIN
			--EventType Error-- 
			RETURN
		END


		IF OBJECT_ID('tempdb..#PreReg') IS NOT NULL DROP TABLE #PreReg
		CREATE TABLE #PreReg (
			PK_EventsRegistration INT,
			DistributorID varchar(10),
			[First Name] nvarchar (50),
			[Last Name] nvarchar (50),
			[Preferred Name] nvarchar (50),
			Team varchar(3),
			[Country of Processing] varchar (2),
			Address1 nvarchar(500),
			Address2 nvarchar(500),
			Address3 nvarchar(100),
			[Main Phone] varchar(50),
			[Mobile Phone] varchar (50),
			[Email Address] varchar(100),
			[Primary Language] nvarchar (100),		
			[Is Partner Attending] varchar(2),
			[Partner Name] nvarchar(100),
			[Partner Preferred Name] nvarchar(50),
			[Pre-Registration Date] smalldatetime,
		--	[Pre-Registration Confirmation ID] nvarchar (20),
			[Pre-Registrant Type] varchar(15),	
		)
		CREATE UNIQUE INDEX [ix_PK_EventsRegistration]  ON #PreReg(PK_EventsRegistration) 
		CREATE INDEX [ix_DistributorID] ON #PreReg(DistributorID)

		INSERT INTO #PreReg 
		SELECT
			ER.PK_EventsRegistration
			,ER.DistributorID
			,ER.FirstName AS [FirstName]
			,ER.LastName AS [LastName]
			,ISNULL(ER.DSPreferredname,'') AS [Preferred Name]
			,ISNULL (D.sTeam,'') [DS Team]
			,D.sDistributorCountryProcessingCode [DS COP]
			,ISNULL(D.sStreet,'') [Address1]
			,ISNULL(D.sCity + ' ' + D.sDistributorStateOrProvince,'') [Address2]
			,ISNULL(D.sDistributorPostalCode,'')	[Address3] 
			--,ER.Phones
			--,SUBSTRING (ER.[Phones], 1, CHARINDEX(';', ER.[Phones], - 1)) [Main Phone]
			,CASE WHEN LEN(SUBSTRING (ER.[Phones], 1, CHARINDEX(';', ER.[Phones],1))) > 2 THEN  SUBSTRING (ER.[Phones], 1, CHARINDEX(';', ER.[Phones],1)) ELSE '' END AS [Main Phone]
			,CASE WHEN LEN(SUBSTRING(ER.[Phones], CHARINDEX(';', ER.[Phones], 1) + 1, LEN(ER.[Phones]))) > 2 THEN SUBSTRING(ER.[Phones], CHARINDEX(';', ER.[Phones], 1) + 1, LEN(ER.[Phones])) ELSE '' END AS [Mobile Phone]
			,ER.EmailAddress
			,ISNULL(D.sLanguagePreference,'') AS [Language]
			,'N'
			,''
			,''
			,ER.CreatedDateUTC	 
			,CASE WHEN ISNULL(ER.IsPublicUser,0) = 0 THEN 'Distributor' ELSE 'Public User' END
	 	 
		FROM
			dbo.EventsRegistration ER WITH (NOLOCK)
			INNER JOIN
			v_Distributor D
			ON
				ER.PK_Distributor = D.nDistributorID
		WHERE
			ER.PK_Event = @PK_Event
			AND
			ER.IsPrimaryGuest = 1
			AND
			ER.IsPreRegistered = 1

		/*Partner INFO*/
		UPDATE R
		SET 
			R.[Is Partner Attending] = 'Y' 
			,R.[Partner Name] = ISNULL(ER.FirstName,'') + ' ' + ISNULL(ER.LastName,'')
			,R.[Partner Preferred Name] = ISNULL(ER.DSPreferredname,'')

		FROM #PreReg R INNER JOIN dbo.EventsRegistration ER WITH(NOLOCK)
			ON R.DistributorID = ER.DistributorID
		WHERE
			ER.IsPrimaryGuest = 0
			AND
			ER.PK_Event = @PK_Event
			AND
			ER.IsPreRegistered = 1
	
		/*For Public Pre-Registration*/

		INSERT INTO #PreReg([First Name], [Last Name], [Email Address], [Main Phone], PK_EventsRegistration, [Pre-Registrant Type], [Pre-Registration Date])

		SELECT 
			 ER.FirstName
			,ER.LastName
			,ER.EmailAddress
			,ER.Phones
			,ER.PK_EventsRegistration
			,'Public User'
			,ER.CreatedDateUTC	
		FROM 
			dbo.EventsRegistration ER WITH (NOLOCK) 
		WHERE 
			ER.PK_Event = @PK_Event
		AND 
			ER.IsPublicUser = 1
	
		SELECT DISTINCT 
				R.DistributorID, 
				R.[First Name],
				R.[Last Name],
				R.[Preferred Name],
				R.Team,
				R.[Country of Processing],
				R.Address1,
				R.Address2,
				R.Address3,
				R.[Main Phone],
				R.[Mobile Phone],
				R.[Email Address],
				R.[Primary Language],
				CASE WHEN R.[Is Partner Attending] = 'Y' THEN 1 ELSE 0 END AS [Is Partner Attending],
				R.[Partner Name],
				R.[Partner Preferred Name],
				R.[Pre-Registration Date],
				CASE WHEN R.[Pre-Registrant Type] = 'Distributor' THEN R.DistributorID + '-' + CONVERT(VARCHAR, @PK_Event) 
					ELSE CONVERT(VARCHAR, PK_EventsRegistration) + '-' + CONVERT(VARCHAR, @PK_Event) END AS [Pre-Registration Confirmation ID],
				R.[Pre-Registrant Type],
				@EventType AS [EventType]
				FROM #PreReg R ORDER BY DistributorID 

	
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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;
