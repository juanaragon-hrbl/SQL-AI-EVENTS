CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DistributorGuests]
    -- REQUIRED
   @DistributorID varchar(10)
  ,@EventID int = NULL
      -- OPTIONAL
  ,@Error int OUTPUT
  ,@ErrorMessage varchar(200) OUTPUT      
      -- QA/DEV
  ,@IsDevQA bit = 0 
  

--
AS
BEGIN

/******************************************************************************
OBJECT:                 dbo.usp_EventAPI_Get_DistributorGuests

USE:              DECLARE @e int
                       ,@em varchar(200)
                EXEC usp_EventAPI_Get_DistributorGuests @DistributorID = '07165440'
                                                       ,@EventID=8 
                                                       ,@Error = @e OUTPUT  /* @e must be defined in the local call */
                                                                   ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
                                                                   ,@IsDevQA = 0

DESCRIPTION:      Get Distributor Guests

NOTES:                  

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1.2   2013-05-22 Ini Ukporo            Added code to handle Events that allow Pre-Registration well
1.1 2009-08-31 Sandhya Pendyala    Group ticket changes 
1     2009-01-23 Sandhya Pendyala    Initial

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
DECLARE @PK_SubEvent int
DECLARE @PK_EventsRegistration int
DECLARE @PK_SubEventQualifier int
DECLARE @IsPreRegistrationAllowed int 

SET @StoredProcedure = 'usp_EventAPI_Get_DistrubutorGuests'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'
SET @IsPreRegistrationAllowed = 0

/******************************************************************************
Get all the Distributor Guest Info for Registration
******************************************************************************/

IF EXISTS (SELECT nDistributorID FROM  dbo.v_Distributor WITH (NOLOCK) WHERE sDistributorID = @DistributorID)  
      BEGIN
       SELECT @PK_Distributor = nDistributorID FROM  dbo.v_Distributor WITH (NOLOCK) WHERE sDistributorID = @DistributorID
    END

IF @PK_Distributor IS NULL
BEGIN
      IF EXISTS (SELECT PK_Temp FROM  dbo.TempDistributors WITH (NOLOCK) WHERE DistributorID = @DistributorID)
      BEGIN
       SELECT @PK_Distributor = PK_Temp FROM dbo.TempDistributors WITH (NOLOCK) WHERE DistributorID = @DistributorID
    END
END

SELECT @IsPreRegistrationAllowed = ISNULL(IsPreRegistrationRequired,0) FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @EventID 



IF @PK_Distributor IS NOT NULL 
      BEGIN
            IF @IsPreRegistrationAllowed = 0
                  BEGIN

                        SELECT 
                           sDistributorID AS DistributorID
                          ,sFirstName 
                          ,sLastName
                          ,sTeam 
                          ,sType
                          ,Phone
                          ,'Distributor' AS DSClass
                          ,@PK_Distributor AS PK_Distributor
                        FROM 
                              dbo.v_distributorcontactdetails WITH (NOLOCK)          -- Distributor 
                        WHERE 
                           nDistributorID = @PK_Distributor            
                        UNION
                        SELECT
                              S.sDistributorID AS DistributorID
                           ,S.sSpouseFirstName
                           ,S.sSpouseLastName
                           ,D.sTeam
                           ,D.sType
                           ,D.Phone 
                           ,'Spouse' AS DSClass
                           ,@PK_Distributor AS PK_Distributor
                        FROM
                           dbo.v_DistributorSpouse  S  WITH (NOLOCK)      -- Distributor Spouse 
                        LEFT JOIN
                              dbo.v_distributorcontactdetails D WITH (NOLOCK)
                        ON
                              S.nDistributorID = D.nDistributorID
                        WHERE 
                              S.nDistributorID = @PK_Distributor
                        UNION
                        SELECT
                              T.DistributorID AS DistributorID
                              ,T.FirstName AS FirstName
                              ,T.LastName AS LastName
                              ,'' AS sTeam
                              ,'' AS sType
                              ,ISNULL(T.DayPhone,'')+' '+ISNULL(T.EveningPhone,'')+' '+ISNULL(T.MobilePhone,'') AS Phone
                              ,'Temp' AS DSClass
                              ,@PK_Distributor AS PK_Distributor
                        FROM
                              dbo.TempDistributors T WITH (NOLOCK)
                        WHERE
                              T.PK_Temp = @PK_Distributor
                              AND
                              NOT EXISTS (SELECT 1 FROM dbo.v_Distributor DS WITH (NOLOCK) WHERE DS.sDistributorID = T.DistributorID)
                  END
            ELSE
                  BEGIN
                        SELECT 
                           DS.sDistributorID AS DistributorID
                          ,COALESCE(ER.FirstName,DS.sFirstName) AS sFirstName
                          ,COALESCE(ER.LastName,DS.sLastName) AS sLastName
                          ,COALESCE(ER.DistributorTeam,DS.sTeam) AS sTeam 
                          ,DS.sType
                          ,COALESCE(ER.Phones,DS.Phone) AS Phone
                          ,'Distributor' AS DSClass
                          ,@PK_Distributor AS PK_Distributor
                        FROM 
                              dbo.v_distributorcontactdetails DS WITH (NOLOCK)          -- Distributor 
                        LEFT JOIN
                              dbo.EventsRegistration ER WITH (NOLOCK)
                        ON
                              DS.nDistributorID = ER.PK_Distributor 
                              AND
                              ER.PK_Event = @EventID 
                              AND
                              ER.HasCheckedIn = 0
                              AND
                              ER.IsPrimaryGuest = 0
                        WHERE 
                           DS.nDistributorID = @PK_Distributor            
                        UNION
                        SELECT
                            S.sDistributorID AS DistributorID
                           ,COALESCE(ER.FirstName,S.sSpouseFirstName) AS sSpouseFirstName
                           ,COALESCE(ER.LastName,S.sSpouseLastName) AS sSpouseLastName
                           ,COALESCE(ER.DistributorTeam,D.sTeam) AS sTeam
                           ,D.sType
                           ,COALESCE(ER.Phones,D.Phone) AS Phone
                           ,'Spouse' AS DSClass
                           ,@PK_Distributor AS PK_Distributor
                        FROM
                              dbo.v_distributorcontactdetails D WITH (NOLOCK)
                        LEFT JOIN
                              dbo.v_DistributorSpouse  S  WITH (NOLOCK)     -- Distributor Spouse 
                        ON
                              S.nDistributorID = D.nDistributorID
                        LEFT JOIN
                              dbo.EventsRegistration ER WITH (NOLOCK)
                        ON
                              D.nDistributorID = ER.PK_Distributor 
                              AND
                              ER.PK_Event = @EventID 
                              AND
                              ER.HasCheckedIn = 0
                              AND
                              ER.IsPrimaryGuest = 1
                        WHERE 
                              D.nDistributorID = @PK_Distributor  
                              AND (COALESCE(ER.FirstName,S.sSpouseFirstName) IS NOT NULL OR COALESCE(ER.LastName,S.sSpouseLastName) IS NOT NULL)
                        UNION
                        SELECT
                              T.DistributorID AS DistributorID
                              ,T.FirstName AS FirstName
                              ,T.LastName AS LastName
                              ,'' AS sTeam
                              ,'' AS sType
                              ,ISNULL(T.DayPhone,'')+' '+ISNULL(T.EveningPhone,'')+' '+ISNULL(T.MobilePhone,'') AS Phone
                              ,'Temp' AS DSClass
                              ,@PK_Distributor AS PK_Distributor
                        FROM
                              dbo.TempDistributors T WITH (NOLOCK)
                        WHERE
                              T.PK_Temp = @PK_Distributor
                              AND
                              NOT EXISTS (SELECT 1 FROM dbo.v_Distributor DS WITH (NOLOCK) WHERE DS.sDistributorID = T.DistributorID)
                              
                  END
   
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

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
      @StoredProcedureName = @StoredProcedure
      ,@StartTime = @StartTime  


/******************************************************************************
      end procedure
******************************************************************************/
END
GO

