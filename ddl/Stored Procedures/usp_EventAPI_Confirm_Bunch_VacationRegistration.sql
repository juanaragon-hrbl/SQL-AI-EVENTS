
CREATE PROCEDURE [dbo].[usp_EventAPI_Confirm_Bunch_VacationRegistration]
	
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
      ,@Error int OUTPUT
      ,@ErrorMessage varchar(200) OUTPUT
      -- QA/DEV
      ,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Confirm_Bunch_VacationRegistration

DESCRIPTION:	Confirming Multiple Record and Updates in dbo.VacationRegistration table

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.VacationRegistration

VERSIONS
--------------------------------------------------------------------
1	2011-07-21		Jahnavi/Chandan		Initial
1.1 2012-06-26      SandhyaP	        Rename SP from usp_EventAPI_Confirm_Bunch_VacationRegistration_samcam to usp_EventAPI_Confirm_Bunch_VacationRegistration
									    Added PK_Event filter to WHERE clause
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_EventAPI_Confirm_Bunch_VacationRegistration'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'
SET @RecordStatus = 'C'
SET @ApprovalDate = SYSDATETIME()
/******************************************************************************
set variables for update
******************************************************************************/
SELECT
		@CreatedDate=COALESCE(@CreatedDate, CreatedDate)
		,@CreatedBy=COALESCE(@CreatedBy, CreatedBy)
		,@ModifiedDate=COALESCE(@ModifiedDate,ModifiedDate) 
		,@ModifiedBy=COALESCE(@ModifiedBy,ModifiedBy)
		,@PK_Distributor=COALESCE(@PK_Distributor, PK_Distributor)
		,@DistributorID=COALESCE(@DistributorID,DistributorID)
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
		 DistributorID= @DistributorID
		 AND
		 PK_Event = @PK_Event

/******************************************************************************
update record
******************************************************************************/
BEGIN TRY
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
		dbo.VacationRegistration WITH (NOLOCK)
	WHERE 
		 DistributorID = @DistributorID
		 AND
		 PK_Event = @PK_Event
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
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