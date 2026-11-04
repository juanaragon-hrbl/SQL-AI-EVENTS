CREATE PROCEDURE [dbo].[usp_MYHLEventAPI_Home_CheckDSAccess]
		-- Mandatory
		@DistributorID VARCHAR(20), 
		@Locale VARCHAR(5) 

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA TINYINT = 0
AS
BEGIN
/******************************************************************************
OBJECT:      dbo.usp_MYHLEventAPI_Home_CheckDSAccess

USE: 
			DECLARE @e int, @em varchar(4000)
			EXEC dbo.usp_MYHLEventAPI_Home_CheckDSAccess
				   -- Mandatory
				   @DistributorID = '114085120'
				   ,@Locale = 'es-MX'
				   ,@Error = @e OUTPUT
				   ,@ErrorMessage = @em OUTPUT
				   ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]


DESCRIPTION:  Landing Page -> Track Your Progress & Landing Page -> Track your Downline Progress
                             This will check whether or not to enable the links above when the member logs in. 

VERSIONS
----------------------------------------------------------------------------------
1.0.0		2016-06-28		SandhyaP            Landing Page
1.0.1		2019-04-01		SandhyaP			Add NOLOCK
1.0.2		2019-08-14		NoeG				Refactor code (SRE)
1.0.3		2019-10-17		alejandramed		SRE Compliance 
1.0.4		2021-10-05		ivanci				US 793980 - Self Organized events - Request Access Page - Enable/Disable feature   
1.0.5		2021-11-08      ivanci				BUG 835253 - Manage My Event display after remove DS from coordinator  
1.0.6		2024-03-20      ivanci				Check if access locale match with ds COP		
******************************************************************************/
                  
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

BEGIN TRY   
     
	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END
	  
	-- DECLARE THE LOCAL VARIABLES 

	DECLARE @PK_Locale INT
	DECLARE @DSTeam VARCHAR(10)
	DECLARE @DateFrom SMALLDATETIME 
	DECLARE @DateTo SMALLDATETIME
	DECLARE @PK_Distributor INT
	DECLARE @HasManageEventAccess BIT
	DECLARE @IsCoordinator BIT
    DECLARE @HasRequestAccessPageEnabled BIT
	DECLARE @HasRequestedAccess BIT
	DECLARE @Message nvarchar(4000)

	--- SET THE VARIABLES 
	SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @Locale
	SET @DateFrom = GETUTCDATE()
	SET @DateTo = '2049-12-31'
	SELECT @DSTeam = sSubTeam FROM dbo.v_Distributor WITH (NOLOCK) where sDistributorid = @DistributorID
	SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WITH (NOLOCK) where sDistributorid = @DistributorID
	SELECT @Error = 0, @ErrorMessage = '';

	/******************************************************************************
		   Return a boolean if member has Manage Events access
	******************************************************************************/

	SELECT @HasManageEventAccess = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END 
	FROM dbo.EventDSAccess eda WITH (NOLOCK)
    INNER JOIN EventSubTypeLocaleDesc stl WITH (NOLOCK)
			ON stl.pk_EventSubtypeLocaleDesc = eda.pk_EventSubtypeLocaleDesc AND stl.pk_Locale = @PK_Locale
	WHERE DistributorID = @DistributorID

	IF @HasManageEventAccess = 0
	BEGIN
			SELECT @HasManageEventAccess = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END 			
			FROM dbo.[EventTeamLevelAccess] etla WITH (NOLOCK)
			INNER JOIN EventSubTypeLocaleDesc stl WITH (NOLOCK)
				ON stl.pk_EventSubtypeLocaleDesc = etla.pk_EventSubtypeLocaleDesc AND stl.pk_Locale = @PK_Locale
		
			WHERE SubTypeCode = @DSTeam

            IF @HasManageEventAccess = 1
            BEGIN
                
                select @HasManageEventAccess = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END 
                FROM Locales L WITH (NOLOCK)
                INNER JOIN v_Distributor D 
                ON D.sDistributorID = @DistributorID
                WHERE L.PK_Locale = @PK_Locale AND RIGHT(L.LocaleCode, 2) = D.sDistributorCountryProcessingCode 
            END

			SELECT @HasRequestedAccess = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END 
			FROM dbo.[RequestedManageEventAccessLog] WITH (NOLOCK) 
			WHERE DistributorID = @DistributorID

			SET @Message = (SELECT TOP 1 etla.Message
			FROM dbo.[EventTeamLevelAccess] etla WITH (NOLOCK)
			INNER JOIN EventSubTypeLocaleDesc stl WITH (NOLOCK)
				ON stl.pk_EventSubtypeLocaleDesc = etla.pk_EventSubtypeLocaleDesc AND stl.pk_Locale = @PK_Locale)

			SELECT @IsCoordinator = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END  
			FROM [dbo].[EventCoordinatorDetail] ecd WITH (NOLOCK) 
            INNER JOIN [Event] e WITH (NOLOCK)														-- 1.0.5
				ON  e.PK_Event = ecd.PK_Event 
				AND e.[Version] = 2 
				AND e.[IsActive] = 1 
				AND e.[EventApprovalStatus] = 1
				AND e.[dEndUTC] >= GETUTCDATE()
				AND e.[IsPublish] = 1
            WHERE ecd.CreatedDistributorID = @DistributorID AND ecd.CoordinatorID IS NOT NULL;

            SELECT @HasRequestAccessPageEnabled = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END  
			FROM [dbo].[LocalesExtn] WITH (NOLOCK) WHERE [PK_Locale] = @PK_Locale AND ReqAccessPageDsEvents = 1;

			SELECT @HasManageEventAccess AS [HasManageEventAccess]
				,@Message AS [Message]
				,@HasRequestedAccess as [HasRequestedEventAccess]
				,@IsCoordinator as [IsCoordinator]
                ,@HasRequestAccessPageEnabled as [HasRequestAccessPageEnabled]

            SELECT @DSTeam

	END
	ELSE
		SELECT 
			@HasManageEventAccess AS [HasManageEventAccess]


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
	 
END CATCH;
END
