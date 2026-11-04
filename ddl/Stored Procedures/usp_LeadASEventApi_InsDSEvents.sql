
CREATE PROCEDURE [dbo].[usp_LeadASEventApi_InsDSEvents] 
			@OpType        CHAR(1),
			@DistributorID VARCHAR(10),
			@EventName     VARCHAR(200),
			@City          NVARCHAR(100),
			@EventDate     SMALLDATETIME,
			@PK_EventType  INT,
			@Qualified	   INT,
			@PurchasedSKU  INT,
			@Location	   NVARCHAR(300),
			@PK_Event	   INT,
			@PK_LeadEvent  INT
AS

BEGIN TRY
SET NOCOUNT ON

-- DECLARE LOCAL VARIABLES
DECLARE		@PK_Distributor INT
DECLARE		@AppliedDate SMALLDATETIME

IF ISNULL(@DistributorID, '') = '' OR LEN(@DistributorID) < 1 
BEGIN  
	RAISERROR('Please enter valid DistributorID', 16,1)  
    RETURN(-1)  
END 

SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WITH (NOLOCK) WHERE sDistributorID = @DistributorID
SET	   @AppliedDate = GETDATE()

IF @PK_Distributor IS NULL
BEGIN  
      RAISERROR('DistributorID does not exist in the view', 16,1)  
      RETURN(-1)  
END  

IF @OpType = 'D' AND @PK_LeadEvent IS NULL
BEGIN  
	RAISERROR('You must pass LeadEvent ID for this operation', 16,1)  
    RETURN(-1)  
END  
                   
BEGIN TRAN
IF @OpType = 'I'
BEGIN
PRINT 'INSERT RECORD IN dbo.LeadEventsRegistration TABLE' 

 		INSERT INTO [PubEventManagement].[dbo].[LeadEventsRegistration]
           (
           CreatedDate, 
           CreatedBy, 
           ModifiedDate, 
           ModifiedBy, 
           PK_EventType, 
           PK_Event, 
           PK_Distributor, 
           DistributorID, 
           EventName, 
           EventDate, 
           EventCity, 
           Location, 
           Qualified, 
           PurchasedSKU
           )
    VALUES( @AppliedDate	,
           @DistributorID	,
           @AppliedDate		,
           @DistributorID	,
           @PK_EventType	,
           @PK_Event		,
           @PK_Distributor	,
           @DistributorID	,
           @EventName		,
           @EventDate		,
           @City			,
           @Location		,
           @Qualified		,
           @PurchasedSKU)
END
IF @OpType = 'D'
BEGIN
PRINT 'DELETE RECORD FROM dbo.LeadEventsRegistration TABLE' 

    DELETE FROM dbo.LeadEventsRegistration WHERE PK_LeadEvent = @PK_LeadEvent AND PK_Distributor = @PK_Distributor
END       

COMMIT 
PRINT 'DONE'

END TRY

BEGIN CATCH  
	-- Error encountered  
	IF @@TRANCOUNT > 0
	BEGIN
		PRINT 'FAILED at stored procedure usp_LeadASEventApi_InsDSEvents'
		ROLLBACK  
	END
	
	-- Raise an error with the details of the exception  
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int  
	SELECT  @ErrMsg = ERROR_MESSAGE(),  
			@ErrSeverity = ERROR_SEVERITY()  

	RAISERROR(@ErrMsg, @ErrSeverity, 1)  

END CATCH       
GO

