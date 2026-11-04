
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DistributorRegistration]
    -- REQUIRED
   @DistributorID varchar(10)
  ,@EventID int
      -- OPTIONAL
  ,@Error int OUTPUT
  ,@ErrorMessage varchar(200) OUTPUT      
      -- QA/DEV
  ,@IsDevQA bit = 0 

--
AS
BEGIN

/******************************************************************************
OBJECT:                 dbo.usp_EventAPI_Get_DistributorRegistration

USE:              DECLARE @e int
                       ,@em varchar(200)
                EXEC usp_EventAPI_Get_DistributorRegistration @DistributorID = '09505905'
                                                       ,@EventID=22 
                                                       ,@Error = @e OUTPUT  /* @e must be defined in the local call */
                                                                   ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
                                                                   ,@IsDevQA = 0

DESCRIPTION:      Returns registration information for distributorship

NOTES:                  

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1     2009-01-23 Sandhya      Initial
2     2013-02-01 IniU         Added logic to distinguish event with or without badge burning and with or without badge printing. See the variable @IsBadgePrinting
                                    .Net please note that you will have to decide which "Badge" label link to display. If @IsBadgePrinting = 0, then the label will be as currently
                                    displayed "Badge" and will call the Badge Burning form. If @IsBadgePrinting = 1, then the label link to display will be "Badge Printing" and will 
                                    call the new functionality/form for badge printing.
                                    Also, note that as currently exist, if badge has been burned, the status says "Badge Issued". That is, HasCheckedIn value will be 2. If badge has 
                                    been printed, the status should say "Badge Printed". That is, HasCheckedIn value will be 3. So you need to include "Badge Printed" in your Attendee Status Enumeration

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
      variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime
DECLARE @PK_Distributor int
DECLARE @IsBadgePrinting bit = 0

SET @StoredProcedure = 'usp_EventAPI_Get_DistributorRegistration'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
Get all the Registration Info for the Distributorship
******************************************************************************/

IF NOT EXISTS (SELECT nDistributorID FROM  dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID)
BEGIN
      SET @Error = 188
      -- Update ErrorLog
      EXEC dbo.usp_Utility_UpdateErrorLog 
            @ProcedureName = @StoredProcedure 
            ,@ErrorNumber = @Error
            ,@ErrorMessage = @ErrorMessage OUTPUT
      RETURN 
END

-- Determine If Event Requires Badge Printing or Not
BEGIN
      SELECT 
            @IsBadgePrinting = IsBadgePrinting
      FROM
            dbo.Event (NOLOCK)
      WHERE
            PK_Event = @EventID
END

  BEGIN TRY
  
      IF @IsBadgePrinting = 0 -- IF Badge Printing Is Not Enabled For the Event 
    BEGIN
            SELECT 
                  A.PK_EventsRegistration 
                  ,A.PK_Distributor
                  ,A.DistributorID
                  ,A.FirstName 
                  ,A.LastName 
                  ,A.AddressLine1
                  ,A.AddressLine2
                  ,A.City 
                  ,A.State
                  ,A.ZipCode
                  ,A.Phones
                  ,A.FaxNo
                  ,A.EmailAddress
                  ,A.IsPrimaryGuest
                  ,CASE WHEN B.PK_EventsRegistration IS NOT NULL THEN 2 ELSE A.HasCheckedIn END AS HasCheckedIn
                  ,A.IsDistributor
                  ,A.IsPreRegistered
                  ,A.UnRegister  
                  ,A.CreatedDateUTC
                  ,A.CreatedBy
                  ,A.ModifiedDateUTC
                  ,A.ModifiedBy
                  ,A.PK_EventTicket
                  ,A.PK_Event
                  ,A.PK_PrimaryLanguage
                  ,A.PK_SecondaryLanguage
                  ,A.PK_EventHotel
                  ,A.Registered
                  ,@IsBadgePrinting AS IsBadgePrinting
                  ,LM.Language
            FROM
                  dbo.EventsRegistration A (NOLOCK)
            LEFT JOIN
                  dbo.EventSecurityBadge B (NOLOCK)
            ON
                  B.PK_EventsRegistration = A.PK_EventsRegistration
                  AND
                  ISNULL(B.IsActive,0) = 1
            LEFT JOIN
				 dbo.v_LanguageMapping LM (NOLOCK)
			ON
				A.PK_PrimaryLanguage = LM.PK_Language 
            WHERE
                  A.DistributorID = @DistributorID
                  AND
                  A.PK_Event = @EventID
                  AND
                  A.HasCheckedIn = 1
      END
      ELSE        -- IF Badge Printing Is Enabled For the Event
      BEGIN
            SELECT 
                  A.PK_EventsRegistration 
                  ,A.PK_Distributor
                  ,A.DistributorID
                  ,A.FirstName 
                  ,A.LastName 
                  ,A.AddressLine1
                  ,A.AddressLine2
                  ,A.City 
                  ,A.State
                  ,A.ZipCode
                  ,A.Phones
                  ,A.FaxNo
                  ,A.EmailAddress
                  ,A.IsPrimaryGuest
                  ,CASE WHEN B.PK_EventsRegistration IS NOT NULL THEN 3 ELSE A.HasCheckedIn END AS HasCheckedIn
                  ,A.IsDistributor
                  ,A.IsPreRegistered
                  ,A.UnRegister  
                  ,A.CreatedDateUTC
                  ,A.CreatedBy
                  ,A.ModifiedDateUTC
                  ,A.ModifiedBy
                  ,A.PK_EventTicket
                  ,A.PK_Event
                  ,A.PK_PrimaryLanguage
                  ,A.PK_SecondaryLanguage
                  ,A.PK_EventHotel
                  ,A.Registered
                  ,@IsBadgePrinting AS IsBadgePrinting
                  ,LM.Language
            FROM
                  dbo.EventsRegistration A (NOLOCK)
            LEFT JOIN
                  dbo.EventBadgePrinting B (NOLOCK)
            ON
                  B.PK_EventsRegistration = A.PK_EventsRegistration
            LEFT JOIN
				 dbo.v_LanguageMapping LM (NOLOCK)
			ON
				A.PK_PrimaryLanguage = LM.PK_Language 
            WHERE
                  A.DistributorID = @DistributorID
                  AND
                  A.PK_Event = @EventID
                  AND
                  A.HasCheckedIn = 1
      END

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