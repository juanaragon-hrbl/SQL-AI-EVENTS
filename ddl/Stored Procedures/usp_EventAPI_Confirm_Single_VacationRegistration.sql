CREATE PROCEDURE [dbo].[usp_EventAPI_Confirm_Single_VacationRegistration]
	   @PK_VacationRegistration int
      ,@CreatedDate datetime
      ,@CreatedBy varchar(30)
      ,@ModifiedDate datetime
      ,@ModifiedBy varchar(30)
      ,@PK_Event int
      ,@PK_Distributor int
      ,@DistributorID varchar(10)
      ,@FirstName varchar(40)
      ,@MiddleName varchar(40)
      ,@LastName varchar(40)
      ,@DistributorType char(1)
      ,@PK_Nationality int
      ,@PK_TravelDocumentType int
      ,@DocumentType varchar(100)
      ,@DocumentNumber varchar(100)
      ,@DocumentExpiryDate datetime
      ,@RecordStatus char(1)
      ,@ApprovalDate datetime
      ,@ApprovedBy varchar(30)
      -- Error Parameters
	  ,@Error	INT = 0 OUTPUT
	  ,@ErrorMessage VARCHAR(4000) = NULL OUTPUT
	  -- QA/DEV
	  ,@IsDevQA BIT = 0
AS
BEGIN
/******************************************************************************
OBJECT:		    dbo.usp_EventAPI_Confirm_Single_VacationRegistration
DESCRIPTION:	Confirming single Record and Updates in dbo.VacationRegistration table
				
				EXEC usp_EventAPI_Confirm_Single_VacationRegistration
				 @PK_VacationRegistration = 256314
				,@CreatedDate = '2019-10-14'
				,@CreatedBy = 'adminuser'
				,@ModifiedDate = '2019-10-14'
				,@ModifiedBy = 'adminuser'
				,@PK_Event = 58721
				,@PK_Distributor = 2660938
				,@DistributorID = '10808335'
				,@FirstName = 'JEANINE M.'
				,@MiddleName = ''
				,@LastName = 'MACLARY'
				,@DistributorType = '1'
				,@PK_Nationality = 123654
				,@PK_TravelDocumentType = 5362
				,@DocumentType = 'passport'
				,@DocumentNumber = '12354685'
				,@DocumentExpiryDate = '2020-10-10'
				,@RecordStatus = 1
				,@ApprovalDate = '2019-10-14'
				,@ApprovedBy = 'adminuser'
NOTES:			
DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.VacationRegistration

VERSIONS
--------------------------------------------------------------------
1	2011-07-21		Jahnavi/Chandan		Initial
1.1 2012-06-26      SandhyaP	        Renamed SP from usp_EventAPI_Confirm_Single_VacationRegistration_SamCam to usp_EventAPI_Confirm_Single_VacationRegistration
										Added @PK_Event filter to the WHERE clause
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

SET @RecordStatus = 'C'
SET @ApprovalDate = SYSDATETIME() 

BEGIN TRY
/******************************************************************************
set variables for update
******************************************************************************/
SELECT
		@CreatedDate=COALESCE(@CreatedDate, CreatedDate)
		,@CreatedBy=COALESCE(@CreatedBy, CreatedBy)
		,@ModifiedDate=COALESCE(@ModifiedDate,ModifiedDate) 
		,@ModifiedBy=COALESCE(@ModifiedBy,ModifiedBy)
		,@PK_Distributor=COALESCE(@PK_Distributor, PK_Distributor)
		,@FirstName=COALESCE(@FirstName,FirstName)
		,@MiddleName=COALESCE(@MiddleName,MiddleName)
		,@LastName=COALESCE(@LastName, LastName)
		,@DistributorType=COALESCE(@DistributorType,DistributorType)
		,@PK_Nationality=COALESCE(@PK_Nationality,PK_Nationality)
		,@PK_TravelDocumentType=COALESCE(@PK_TravelDocumentType,PK_TravelDocumentType)
		,@DocumentType=COALESCE(@DocumentType,DocumentType)
		,@DocumentNumber=COALESCE(@DocumentNumber,DocumentNumber)
		,@DocumentExpiryDate=COALESCE(@DocumentExpiryDate,DocumentExpiryDate)
		,@RecordStatus=COALESCE(@RecordStatus, RecordStatus)
		,@ApprovalDate=COALESCE(@ApprovalDate,ApprovalDate)
		,@ApprovedBy=COALESCE(@ApprovedBy,ApprovedBy)
FROM 
		dbo.VacationRegistration WITH (NOLOCK)
WHERE 
		 PK_VacationRegistration= @PK_VacationRegistration
		 AND DistributorID = @DistributorID
		 AND PK_Event = @PK_Event

/******************************************************************************
update record
******************************************************************************/
	UPDATE dbo.VacationRegistration 
	SET
	     [CreatedDate]=@CreatedDate
		,[CreatedBy]=@CreatedBy
		,[ModifiedDate]=ISNULL(@ModifiedDate,Getdate())
		,[ModifiedBy] =ISNULL(@ModifiedBy,replace(suser_sname(),'HERBALIFECORP\',''))
		,[PK_Distributor]=@PK_Distributor
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
	FROM 
		dbo.VacationRegistration (NOLOCK)
	WHERE 
		PK_VacationRegistration= @PK_VacationRegistration
		and 
		DistributorID = @DistributorID
		AND
		PK_Event = @PK_Event	
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

/******************************************************************************
	end procedure
******************************************************************************/
END