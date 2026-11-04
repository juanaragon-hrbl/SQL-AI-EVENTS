CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_VacationRegistration]
--Mandetory
	@DistributorType char(1)
,@DistributorID varchar(10)	
,@PK_Event int
---Optional 
,@CreatedDate datetime  
,@CreatedBy varchar(30) 
,@FirstName varchar(40) = NULL
,@MiddleName Varchar(40) = NULL
,@LastName varchar(40)	= NULL
,@PK_Nationality int = NULL
,@PK_TravelDocumentType int = NULL
,@DocumentType varchar(100) = NULL
,@DocumentNumber varchar(100) = NULL
,@DocumentExpiryDate datetime = NULL
,@RecordStatus char(1) = NULL
,@ApprovalDate datetime = NULL
,@ApprovedBy varchar(30) = NULL
,@TeamStatus varchar(250) = NULL
,@Email varchar(250) = NULL
,@Phone varchar(50) = NULL
,@Mobile varchar(50) = NULL
,@BirthDate SMALLDATETIME = NULL
,@DocumentIssueDate SMALLDATETIME = NULL
,@PreMedicalConditions nVARCHAR(4000) = NULL
,@CountryOfResidence nVARCHAR(30) = NULL
,@FileType nVARCHAR(40) = NULL
,@FilePath nVARCHAR(1000) = NULL
,@FileName nVARCHAR(100) = NULL
-- Output Parameter
--,@ConfirmationNumber nVARCHAR(25) OUTPUT
-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0
,@RowIdentification varchar(200) OUTPUT
	
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Ins_VacationRegistration


DESCRIPTION:	Inserts record into dbo.VacationRegistration

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.VacationRegistration

VERSIONS
--------------------------------------------------------------------
1	2011-07-19   Jahnavi/Chandan	     Initial
1.1 2012-06-19   SandhyaP				 Renamed SP from usp_EventAPI_Ins_VacationRegistration_samcam to usp_EventAPI_Ins_VacationRegistration
										 Add new parameters - BirthDate, DocumentIssueDate, PreMedicalConditions, CountryOfResidence, FileType, FilePath, FileName
1.2	2019-09-05	 NoeG					 SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/

SELECT @PK_Nationality= nCountryID FROM dbo.v_Nationality WHERE nCountryID = @PK_Nationality
SELECT @PK_TravelDocumentType = PK_TravelDocumentType FROM dbo.TravelDocumentType WITH(NOLOCK) WHERE DocumentTypeDesc = @DocumentType
SELECT @PK_Event =PK_Event FROM dbo.EventQualifier WITH(NOLOCK) WHERE PK_Event = @PK_Event


DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	SET @FirstName = LTRIM(RTRIM(@FirstName))
	SET @MiddleName = LTRIM(RTRIM(@MiddleName))
	SET @LastName = LTRIM(RTRIM(@LastName))


	/******************************************************************************
	insert record
	******************************************************************************/
	BEGIN TRY

	/*Distributor Info 1st Block*/
	IF @DistributorType = 'B'

	BEGIN

	SELECT @FirstName = LTRIM(RTRIM(sFirstName)) FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
	SELECT @LastName = LTRIM(RTRIM(sLastName)) FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID

	INSERT
		dbo.VacationRegistration
	(
			 [CreatedDate]
			,[CreatedBy]
			,[PK_Event]
			,[DistributorID] 
			,[FirstName]
			,[MiddleName]
			,[LastName]		
			,[DistributorType]
			,[PK_Nationality] 
			,[PK_TravelDocumentType]
			,[DocumentType]
			,[DocumentNumber]
			,[DocumentExpiryDate]
			,[RecordStatus]
			,[ApprovalDate]
			,[ApprovedBy]
			,[TeamStatus]  
			,[Email]
			,[Phone]
			,[Mobile]
			,[DateOfBirth]
			,[DocumentIssueDate]
			,[PreMedicalConditions]
			,[CountryOfResidence]
			,[FileType]
			,[FilePath]
			,[FileName]		

	)
	SELECT
	 		 @CreatedDate
			,@CreatedBy	  
			,@PK_Event	 
			,@DistributorID 
			,@FirstName
			,@MiddleName
			,@LastName 
			,'B'
			,@PK_Nationality 
			,@PK_TravelDocumentType
			,@DocumentType
			,@DocumentNumber
			,@DocumentExpiryDate
			,@RecordStatus
			,@ApprovalDate
			,@ApprovedBy
			,@TeamStatus  
			,@Email  
			,@Phone  
			,@Mobile  
			,@BirthDate
			,@DocumentIssueDate
			,@PreMedicalConditions
			,@CountryOfResidence
			,@FileType
			,@FilePath
			,@FileName	

	END
	/*Distributor Info 2nd Block*/
	IF @DistributorType = 'D'
	BEGIN
	INSERT
		dbo.VacationRegistration
	(
			 [CreatedDate]
			,[CreatedBy]
			,[PK_Event]
			,[DistributorID] 
			,[FirstName]
			,[MiddleName]
			,[LastName]		
			,[DistributorType]
			,[PK_Nationality] 
			,[PK_TravelDocumentType]
			,[DocumentType]
			,[DocumentNumber]
			,[DocumentExpiryDate]
			,[RecordStatus]
			,[ApprovalDate]
			,[ApprovedBy]
			,[TeamStatus]  
			,[Email]
			,[Phone]
			,[Mobile]
			,[DateOfBirth]
			,[DocumentIssueDate]
			,[PreMedicalConditions]	
			,[CountryOfResidence]
			,[FileType]
			,[FilePath]
			,[FileName]				

	)
	SELECT
	 		 @CreatedDate
			,@CreatedBy
			,@PK_Event
			,@DistributorID 
			,@FirstName
			,@MiddleName
			,@LastName 
			,'D'
			,@PK_Nationality 
			,@PK_TravelDocumentType
			,@DocumentType
			,@DocumentNumber
			,@DocumentExpiryDate
			,@RecordStatus
			,@ApprovalDate
			,@ApprovedBy
			,@TeamStatus  
			,@Email  
			,@Phone  
			,@Mobile 
			,@BirthDate
			,@DocumentIssueDate
			,@PreMedicalConditions
			,@CountryOfResidence
			,@FileType
			,@FilePath
			,@FileName		
		
				
	END
	/*Spouse or Partner Info*/
	IF @DistributorType = 'S'
	BEGIN
	INSERT
		dbo.VacationRegistration
	(
			 [CreatedDate]
			,[CreatedBy]
			,[PK_Event]
			,[DistributorID] 
			,[FirstName]
			,[MiddleName]
			,[LastName]		
			,[DistributorType]
			,[PK_Nationality] 
			,[PK_TravelDocumentType]
			,[DocumentType]
			,[DocumentNumber]
			,[DocumentExpiryDate]
			,[RecordStatus]
 			,[ApprovalDate]
 			,[ApprovedBy]
			,[TeamStatus]  
			,[Email]
			,[Phone]
			,[Mobile]
			,[DateOfBirth]
			,[DocumentIssueDate]
			,[PreMedicalConditions]
			,[CountryOfResidence]
			,[FileType]
			,[FilePath]
			,[FileName]				
	)
	SELECT
	 		 @CreatedDate
			,@CreatedBy
			,@PK_Event
			,@DistributorID 
			,@FirstName
			,@MiddleName
			,@LastName 
			,'S'
			,@PK_Nationality 
			,@PK_TravelDocumentType
			,@DocumentType
			,@DocumentNumber
			,@DocumentExpiryDate
			,@RecordStatus
			,@ApprovalDate
			,@ApprovedBy
			,@TeamStatus  
			,@Email  
			,@Phone  
			,@Mobile 
			,@BirthDate
			,@DocumentIssueDate
			,@PreMedicalConditions		
			,@CountryOfResidence
			,@FileType
			,@FilePath
			,@FileName		
		
	END
		/*Guest Info*/
		IF @DistributorType = 'G'
	BEGIN
	INSERT
		dbo.VacationRegistration
	(
			 [CreatedDate]
			,[CreatedBy]
			,[PK_Event]
			,[DistributorID] 
			,[FirstName]
			,[MiddleName]
			,[LastName]		
			,[DistributorType]
			,[PK_Nationality] 
			,[PK_TravelDocumentType]
			,[DocumentType]
			,[DocumentNumber]
			,[DocumentExpiryDate]
			,[RecordStatus]
			,[ApprovalDate]
			,[ApprovedBy]
			,[TeamStatus]  
			,[Email]
			,[Phone]
			,[Mobile]
			,[DateOfBirth]
			,[DocumentIssueDate]
			,[PreMedicalConditions]	
			,[CountryOfResidence]
			,[FileType]
			,[FilePath]
			,[FileName]					

	)
	SELECT
	 		 @CreatedDate
			,@CreatedBy
			,@PK_Event
			,@DistributorID 
			,@FirstName
			,@MiddleName
			,@LastName 
			,'G'
			,@PK_Nationality 
			,@PK_TravelDocumentType
			,@DocumentType
			,@DocumentNumber
			,@DocumentExpiryDate
			,@RecordStatus
			,@ApprovalDate
			,@ApprovedBy
			,@TeamStatus  
			,@Email  
			,@Phone  
			,@Mobile 
			,@BirthDate
			,@DocumentIssueDate
			,@PreMedicalConditions		
			,@CountryOfResidence
			,@FileType
			,@FilePath
			,@FileName			
		
	END	 

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

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
	

	BEGIN
	SELECT @RowIdentification = PK_VacationRegistration  FROM VacationRegistration WITH (NOLOCK) ORDER BY PK_VacationRegistration ASC

	END 
/******************************************************************************
	end procedure
******************************************************************************/
END
GO

