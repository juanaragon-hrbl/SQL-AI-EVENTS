CREATE PROCEDURE [dbo].[usp_EventAPI_Upd_VacationRegistration]
	 @PK_VacationRegistration int
	,@ModifiedDate datetime
	,@ModifiedBy varchar(30)
	,@PK_Event int
	,@DistributorID varchar(10)=Null 
	,@FirstName varchar(40)=Null 
	,@MiddleName varchar(40)=Null 
	,@LastName varchar(40)=Null 
	,@DistributorType char(1) 
	,@PK_Nationality int=Null 
	,@PK_TravelDocumentType int=Null 
	,@DocumentType varchar(100)=Null 
	,@DocumentNumber varchar(100)=Null 
	,@DocumentExpiryDate datetime=Null 
	,@RecordStatus char(1)=Null 
	,@ApprovalDate datetime 
	,@ApprovedBy varchar(30)=Null 
	,@TeamStatus varchar(250)=Null 
	,@Email varchar(250)=Null 
	,@Phone varchar(50)=Null 
	,@Mobile varchar(50)=Null 
	,@BirthDate SMALLDATETIME = NULL
	,@DocumentIssueDate SMALLDATETIME = NULL
	,@PreMedicalConditions nVARCHAR(4000) = NULL
    ,@CountryOfResidence nVARCHAR(30) = NULL
    ,@FileType nVARCHAR(40) = NULL
    ,@FilePath nVARCHAR(1000) = NULL
    ,@FileName nVARCHAR(100) = NULL		
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Upd_VacationRegistration

DESCRIPTION:	Updates record in dbo.VacationRegistration

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.VacationRegistration

VERSIONS
--------------------------------------------------------------------
1	2011-07-19	Jahnavi/Chandan	 Initial
1.1 2012-06-19  SandhyaP		 Renamed SP from usp_EventAPI_Upd_VacationRegistration_samcam to usp_EventAPI_Upd_VacationRegistration
								 Add new parameters - BirthDate, DocumentIssueDate, PreMedicalConditions, CountryOfResidence, FileType, FilePath, FileName
1.2 2019-09-05	NoeG			 SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	SELECT @PK_Nationality= nCountryID FROM dbo.v_Nationality WHERE nCountryID = @PK_Nationality

	SET @FirstName = LTRIM(RTRIM(@FirstName))
	SET @MiddleName = LTRIM(RTRIM(@MiddleName))
	SET @LastName = LTRIM(RTRIM(@LastName))

	/******************************************************************************
	be sure the value of FK exists in referenced table
	******************************************************************************/
	IF NOT EXISTS(SELECT PK_VacationRegistration FROM dbo.VacationRegistration WITH (NOLOCK) WHERE PK_VacationRegistration = @PK_VacationRegistration)
	BEGIN
		SET @Error = 87
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END



	/******************************************************************************
	be sure the value of FK exists in referenced table
	******************************************************************************/
	IF NOT EXISTS(SELECT PK_Event FROM dbo.EventQualifier WITH (NOLOCK) WHERE PK_Event = @PK_Event)
	BEGIN
		SET @Error = 37
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END


	/******************************************************************************
	update record
	******************************************************************************/
	BEGIN TRY
		UPDATE dbo.VacationRegistration 
		SET
	   
			 [ModifiedDate]=ISNULL(@ModifiedDate,Getdate())
			,[ModifiedBy] =ISNULL(@ModifiedBy,replace(suser_sname(),'HERBALIFECORP\',''))
			,[PK_Event]=@PK_Event
			,[DistributorID] =@DistributorID
			,[FirstName]=@FirstName
			,[MiddleName]=@MiddleName
			,[LastName]=@LastName
			,[DistributorType]=@DistributorType
			,[PK_Nationality]=@PK_Nationality
			,[PK_TravelDocumentType]=@PK_TravelDocumentType
			,[DocumentType]=@DocumentType
			,[DocumentNumber]=@DocumentNumber
			,[DocumentExpiryDate]=@DocumentExpiryDate
			,[RecordStatus]=@RecordStatus
			,[ApprovalDate]=@ApprovalDate
			,[ApprovedBy]=@ApprovedBy
			,[TeamStatus]=@TeamStatus		
			,[Email]=@Email
			,[Phone]=@Phone  
			,[Mobile]=@Mobile  
			,[DateOfBirth] = @BirthDate
			,[DocumentIssueDate] = @DocumentIssueDate
			,[PreMedicalConditions] = @PreMedicalConditions
			,[CountryOfResidence] = @CountryOfResidence
			,[FileType] = @FileType
			,[FilePath] = @FilePath
			,[FileName] = @FileName
			FROM 
			dbo.VacationRegistration 
		WHERE 
			PK_VacationRegistration = @PK_VacationRegistration

		-- Update processing Log
		EXEC dbo.usp_Utility_UpdateProcessingLog 
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime

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

/******************************************************************************
	end procedure
******************************************************************************/
END
GO

