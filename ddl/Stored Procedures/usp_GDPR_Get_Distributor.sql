CREATE PROCEDURE [dbo].[usp_GDPR_Get_Distributor]

	-- Mandatory Parameters
	  @DSRRequestId NVARCHAR(20) = ''
	 ,@DistributorId  NVARCHAR(30) = ''
	 ,@Email NVARCHAR(250) = ''
	 ,@SnowRequest NVARCHAR(20) = ''
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN

-- =======================================================================================
-- Author		Jair Lira Garcia
-- Create date  Oct2021
-- Description	Return Distributor data before anonymization
-- Parameters :  @Error  OUT Error number
--               @ErrorMessage OUT Error message
--              QA/DEV
--       	     @IsDevQA SMALLINT = 0 
--------------------------------------------------------------------
--    VERSIONS
--------------------------------------------------------------------
--    1.0.0       2022-02-28     Jair Lira        Initial. 
--    1.1.0       2022-04-27     Jair Lira        Email length was changed
--    1.2.0       2022-08-30     Jair Lira        Change on CEA Table 
-- ========================================================================================
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StartTime DATETIME = GETUTCDATE()
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
DECLARE @PK_Distributor INT = NULL,  @GDPRMasking INT = 0, @RetrievalCount INT = 0

BEGIN TRY

	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END

/******************************************************************************
	Get Pk_Distributor
******************************************************************************/
	SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WITH (NOLOCK) WHERE sDistributorID = @DistributorID

	IF @PK_Distributor IS NULL 
	BEGIN
		SET @PK_Distributor =0;
		THROW 60000, 'Warning: DistributorId was not found' , 1
	END


/******************************************************************************
	Check GDPR Masking
******************************************************************************/

	SELECT @GDPRMasking = COUNT(1)
	FROM [dbo].[GDPRDistributors] WITH (NOLOCK) 
	WHERE StatusCode = 1 and DistributorId = @DistributorId

	SELECT  @RetrievalCount = ISNULL(MAX(RetrievalCount) + 1,0) 
	FROM [dbo].[GDPRDistributors] WITH (NOLOCK)
	WHERE DistributorId = @DistributorId AND StatusCode = IIF(@GDPRMasking = 0, 0, 1)


/******************************************************************************
	Create Distributors temp table
******************************************************************************/

	IF OBJECT_ID('Tempdb..#DistTemp','U') IS NOT NULL DROP TABLE #DistTemp

	CREATE TABLE #DistTemp (
		DSRRequestId NVARCHAR(20),
		DistributorId NVARCHAR(30),
		SnowRequest NVARCHAR(20),
		Type BIT,
		RetrievalCount INT,
		Pk_distributor INT,
		FirstName NVARCHAR(150), 	
		LastName NVARCHAR(150), 
		FormerName NVARCHAR(150),
		MiddleName NVARCHAR(60),
		IdentificationNumber  NVARCHAR(100),
		TaxIdentificationNumber NVARCHAR(100),
		IdentityCard NVARCHAR(100),
		DOB DATETIME,
		CustomerNumber NVARCHAR(30),
		Address1 NVARCHAR(240),
		Address2 NVARCHAR(240),
		Address3 NVARCHAR(240),
		Address4 NVARCHAR(240),
		MobileNumber NVARCHAR(200),
		EmailAddress NVARCHAR(250),
		MaritalStatus NVARCHAR(100),
		SpouseFirstName NVARCHAR(150),
		SpouseLastName NVARCHAR(150),
		SpouseMiddleName NVARCHAR(150),
		Gender NVARCHAR(5),
		StatusCode INT,
		Message NVARCHAR(100))

-- Create Indexes
	CREATE INDEX IX_#DistTemp_Id ON #DistTemp(Pk_distributor)


	INSERT INTO #DistTemp (DSRRequestId, DistributorId, SnowRequest, Type, RetrievalCount, Pk_distributor)
	SELECT @DSRRequestId,@DistributorId,  @SnowRequest, 1, @RetrievalCount, @Pk_distributor

/******************************************************************************
Update GET dbo.EventsRegistration Information
******************************************************************************/
	IF NOT EXISTS (SELECT TOP 1 PK_Distributor FROM dbo.EventsRegistration WITH (NOLOCK) WHERE  PK_Distributor = @Pk_distributor and IsPrimaryGuest = 1)
	BEGIN
		UPDATE D
			SET FirstName = PD.FirstName,
				LastName =  PD.LastName,
				Address1 =  PD.Address1,
				Address2 =  PD.Address2,
				Address3 =  PD.Address3,
				Address4 =  PD.Address4,
				MobileNumber = PD.Phone,
				EmailAddress = PD.Email,
				SpouseFirstName = PD.SpouseFirstName,
				SpouseLastName = PD.SpouseLastName	    
		FROM #DistTemp D
		INNER JOIN Promo.dimDistributor PD WITH (NOLOCK) ON D.PK_Distributor = PD.PK_Distributor;
	END

	ELSE
	BEGIN
		UPDATE D
			SET FirstName = ER.FirstName,
				LastName =  ER.LastName,
				Address1 =  ER.AddressLine1,
				Address2 =  ER.AddressLine2,
				MobileNumber = ER.Phones,
				EmailAddress = ER.EmailAddress,
				SpouseFirstName = PD.SpouseFirstName,
				SpouseLastName = PD.SpouseLastName	  
		FROM #DistTemp D
		INNER JOIN dbo.EventsRegistration ER WITH (NOLOCK) ON D.PK_Distributor = ER.PK_Distributor
		INNER JOIN
			(SELECT  MAX(PK_EventsRegistration) AS PK_EventsRegistration FROM dbo.EventsRegistration WITH (NOLOCK) 
			WHERE  PK_Distributor = @Pk_distributor and IsPrimaryGuest = 1) LER
		ON
			ER.PK_EventsRegistration = LER.PK_EventsRegistration 
		LEFT JOIN Promo.dimDistributor PD WITH (NOLOCK) ON D.PK_Distributor = PD.PK_Distributor;

	END


/******************************************************************************
Update and GET dbo.TravelDetails Information
******************************************************************************/

	UPDATE D
		SET MiddleName = TD.MiddleName,
			IdentityCard =  TD.PassportNumber
	FROM #DistTemp D
	INNER JOIN dbo.TravelDetails TD WITH (NOLOCK) ON D.DistributorId = TD.DistributorID
	INNER JOIN 
		(SELECT MIN(PK_TravelDetails) as PK_TravelDetails FROM dbo.TravelDetails WITH (NOLOCK)
		WHERE DistributorID = @DistributorId and IsPrimaryGuest = 0) LTD
	ON  
		TD.PK_TravelDetails = LTD.PK_TravelDetails


/******************************************************************************
Update and GET dbo.VacationRegistration Information
******************************************************************************/

	UPDATE D
		SET DOB = VR.DateOfBirth
	FROM #DistTemp D
	INNER JOIN dbo.VacationRegistration VR WITH (NOLOCK) ON VR.PK_Distributor = D.PK_Distributor
	INNER JOIN 
		(SELECT MAX(PK_VacationRegistration) as PK_VacationRegistration FROM dbo.VacationRegistration WITH (NOLOCK)
		 WHERE Pk_distributor = @PK_Distributor AND DistributorType = 'D') LVR
	ON 
		LVR.PK_VacationRegistration = VR.PK_VacationRegistration


/******************************************************************************
Update and GET dbo.EventActivityParticipant Information
******************************************************************************/

	UPDATE D
		SET IdentificationNumber = EAP.IdentificationNumber
	FROM #DistTemp D
	INNER JOIN dbo.EventActivityTransaction EAT WITH (NOLOCK) ON D.DistributorId = EAT.DistributorId
	INNER JOIN dbo.EventActivityParticipant EAP WITH (NOLOCK)  ON EAT.PK_EventActivityTransaction = EAP.PK_EventActivityTransaction
	INNER JOIN 
		(SELECT MAX(PK_EventActivityParticipant) as PK_EventActivityParticipant FROM dbo.EventActivityParticipant WITH (NOLOCK) 
		WHERE IsDistributor = 1) LEAP 
	ON LEAP.PK_EventActivityParticipant = EAP.PK_EventActivityParticipant;


	UPDATE D
		SET Gender = A.Gender
	FROM #DistTemp D
	JOIN z_evp_cea_attendees.Distributors DT WITH (NOLOCK) ON DT.OriginalId = D.PK_Distributor
	JOIN z_evp_cea_attendees.Attendees A WITH (NOLOCK) ON DT.Id = A.DistributorID
	AND A.AttendeeTypeId = 'DS';


/******************************************************************************
	SELECT DATA
******************************************************************************/

	IF @@ERROR = 0 
	BEGIN

	-----INSERT DATA ON GDPRDistributors
	
		INSERT INTO [dbo].[GDPRDistributors] ([DSRRequestId] ,[Pk_Distributor],[DistributorId],[SnowRequest] ,[Type],[StatusCode] , [RetrievalCount])
		VALUES(@DSRRequestId, @Pk_distributor, @DistributorId,  @SnowRequest, 1, IIF(@GDPRMasking = 0, 0, 1), @RetrievalCount)


		SELECT TOP 1
	        IIF(@GDPRMasking = 0, 0, 1) as StatusCode,
			IIF(@GDPRMasking = 0,'GDPR Data Saved for ','GDPR Data already masked for ') + @Email as Message,
			DSRRequestId,
			DistributorId,
			Pk_distributor,
			SnowRequest,
			FirstName,
			LastName, 
			FormerName ,
			MiddleName,
			IdentificationNumber,
			TaxIdentificationNumber,
			IdentityCard,
			DOB,
			CustomerNumber,
			Address1,
			Address2,
			Address3,
			Address4,
			MobileNumber,
			EmailAddress,
			MaritalStatus,
			SpouseFirstName,
			SpouseLastName,
			SpouseMiddleName,
			Gender
		FROM #DistTemp
	END

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
	
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	INSERT INTO [dbo].[GDPRDistributors] ([DSRRequestId] ,[Pk_Distributor],[DistributorId],[SnowRequest] ,[Type],[StatusCode] , [RetrievalCount], [ErrorMessage])
		VALUES(@DSRRequestId, @Pk_distributor, @DistributorId,  @SnowRequest, 1, 2, @RetrievalCount, @ErrorMessage)

	-- UPDATE ERROR LOG
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage

    
	 SELECT 2 as StatusCode,
          IIF(@Pk_distributor <> 0 ,'Failed: GDPR Data masked for ','Warning: DistributorId was not found for ')  + @Email as Message,
		  NUll as Data



END CATCH
/******************************************************************************
	END PROCEDURE
******************************************************************************/
END

