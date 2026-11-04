CREATE PROCEDURE [dbo].[usp_EventAPI_Get_GroupTicketHeader]  
  @PK_Event int  
 ,@DistributorID varchar(10)  
		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS  
BEGIN  
/******************************************************************************  
OBJECT:   dbo.usp_EventAPI_Get_GroupTicketHeader  
  
USE:
        Declare @e int, @em varchar(4000)  
        EXEC usp_EventAPI_Get_GroupTicketHeader  
			@PK_Event = 240  
			,@DistributorID = '37042411'  
			,@Error = @e OUTPUT  /* @e must be defined in the local call */  
			,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */  
            ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]
  
DESCRIPTION: Retrieves the header Records for group ticket assignment for the purchaser  
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
dbo.EventTicketAssignment  
  
VERSIONS  
--------------------------------------------------------------------  
1	2010-07-13	Prabhu	Intitial  
2	2019-09-05	NoeG	SRE template applied
******************************************************************************/  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
/******************************************************************************  
 variable declaration  
******************************************************************************/  
	DECLARE   
	 @PK_Distributor int  
	 ,@PurchasedBy int  
	 ,@AssignedTo int  
	 ,@AssignedBy int  
	 ,@CanAssign int  
  
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

		/******************************************************************************  
		  Check If Distributor Exists  
		******************************************************************************/  
  
		IF EXISTS ( SELECT nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID )  
		   BEGIN  
		   SELECT @PK_Distributor = nDistributorID FROM dbo.v_DistributorUnionTemp  WHERE sDistributorID = @DistributorID AND DSClass IN ('Distributor','Temp')  
		   END  
		ELSE  
		  BEGIN  
		 SET @Error = 8  
		 -- Update ErrorLog  
		 EXEC dbo.usp_Utility_UpdateErrorLog   
		  @ProcedureName = @StoredProcedure   
		  ,@ErrorNumber = @Error  
		  ,@ErrorMessage = @ErrorMessage OUTPUT  
		 RETURN   
		  END  
  
		/******************************************************************************  
		 get tickets purchased by distributor  
		******************************************************************************/  
		SELECT  
		 @PurchasedBy = COUNT(PK_EventTicket)  
		FROM  
		 dbo.EventTickets WITH (NOLOCK)  
		WHERE  
		 PK_Event = @PK_Event  
		 AND PK_Purchaser = @PK_Distributor  
   
		/******************************************************************************  
		 get tickets assigned to distributor by other distributors  
		 do not include self assigned tickets  
		 include any tickets that were ever assigned  
		******************************************************************************/  
  
		SELECT  
		 @AssignedTo = COUNT(DISTINCT ETA.PK_EventTicket)  
		FROM  
		 dbo.EventTicketAssignment ETA WITH (NOLOCK)
		INNER JOIN  
		 dbo.EventTickets ET WITH (NOLOCK)  
		 ON  
		  ETA.PK_EventTicket = ET.PK_EventTicket  
		  AND ET.PK_Event = @PK_Event  
		WHERE  
		 ETA.PK_ToDistributor = @PK_Distributor  
		 AND ETA.PK_FromDistributor != ETA.PK_ToDistributor  
  
		/******************************************************************************  
		 get tickets assigned by distributor to other distributors  
		 do not include self assigned tickets  
		 include any tickets that were ever assigned  
		******************************************************************************/  
  
		SELECT  
		 @AssignedBy = COUNT(DISTINCT ETA.PK_EventTicket)  
		FROM  
		 dbo.EventTicketAssignment ETA WITH (NOLOCK)  
		INNER JOIN  
		 dbo.EventTickets ET WITH (NOLOCK)  
		 ON  
		  ETA.PK_EventTicket = ET.PK_EventTicket  
		  AND ET.PK_Event = @PK_Event  
		WHERE  
		 ETA.PK_FromDistributor = @PK_Distributor  
		 AND ETA.PK_FromDistributor != ETA.PK_ToDistributor  
  
		/******************************************************************************  
		 get numbers of tickets that can be assigned  
		 use ValidToDateUTC to get accurate count of what's left  
		******************************************************************************/  
  
		SELECT  
		 @CanAssign = COUNT(ETA.PK_EventTicket)  
		FROM  
		 dbo.EventTicketAssignment ETA WITH (NOLOCK)  
		INNER JOIN  
		 dbo.EventTickets ET WITH (NOLOCK)  
		 ON  
		  ETA.PK_EventTicket = ET.PK_EventTicket  
		  AND ET.IsTicketUsed = 0  
		  AND ET.PK_Event = @PK_Event  
		WHERE  
		 ETA.PK_ToDistributor = @PK_Distributor  
		 AND ETA.ValidToDateUTC = '2049-12-31'  
  
		--IF @CanAssign = 0  
		-- BEGIN  
		-- SET @Error = 266  
		-- -- Update ErrorLog  
		-- EXEC dbo.usp_Utility_UpdateErrorLog   
		--  @ProcedureName = @StoredProcedure   
		--  ,@ErrorNumber = @Error  
		--  ,@ErrorMessage = @ErrorMessage OUTPUT  
		-- RETURN   
		--  END  
  
		/******************************************************************************  
		select record  
		******************************************************************************/  
  
	BEGIN TRY
  
		/* Group Ticket Header */  
  
		SELECT @PurchasedBy As TicketsPurchased   
			  ,@AssignedTo As TicketsAssignedToMe  
			  ,@AssignedBy As TicketsAssignedByMe  
			  ,@CanAssign As TicketsAvailableToAssign  
  
		/* Assigned Tickets by distributor */  
  
		SELECT  
		 D.sDistributorID As DistributorID  
		   ,D.sFirstName AS 'First Name'  
		   ,D.sLastName AS 'Last Name'  
		   ,COUNT(ETA.PK_EventTicket) As QuantityAssigned  
		   ,CASE WHEN SUM(CAST(ET.IsTicketUsed AS INT)) > 0 THEN 'Registered!' END 'Registration Status'  
		   ,D.sType
		FROM  
		 dbo.EventTicketAssignment ETA WITH (NOLOCK)  
		INNER JOIN  
		 dbo.EventTickets ET WITH (NOLOCK)  
		 ON  
		  ETA.PK_EventTicket = ET.PK_EventTicket  
		  AND ET.PK_Event = @PK_Event  
		INNER JOIN  
			(SELECT Distinct nDistributorID, sDistributorID, sFirstName, sLastName, sType 
			 FROM dbo.v_DistributorUnionTemp WHERE DSClass IN ('Distributor','Temp')) D  
			ON  
				ETA.PK_ToDistributor = D.nDistributorID  
		WHERE  
		 ETA.PK_FromDistributor = @PK_Distributor  
		 AND ETA.PK_FromDistributor != ETA.PK_ToDistributor  
		 AND ETA.ValidToDateUTC = '12-31-2049'  
		GROUP BY  
			D.sDistributorID  
		   ,D.sFirstName  
		   ,D.sLastName 
		   ,D.sType 
    
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