CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DistributorSearch]
	-- REQUIRED
	@DSSearch varchar(30)
	,@SearchType bit = 0

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_DistributorSearch

USE:	
		DECLARE @e int, @em varchar(max)
	
		EXEC usp_EventAPI_Get_DistributorSearch
					@DSSearch = 'Miller'
					,@SearchType = 1
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

DESCRIPTION:	Retrieves distributor information from Distributor, Temp and Spouse tables for any match by DistributorID, FirstName or LastName

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.v_Distributor
dbReport.tblDistributorSpouse
dbo.TempDistributor

VERSIONS
--------------------------------------------------------------------
1.0.0	 2009-02-26		Ini Ukporo			Initial
1.1.0	 2009-08-31		Sandhya Pendyala	revert back changes
1.2.0	 2018-07-12		Rogelior			Added [sDistributorCountryProcessingCode] column
1.3.0	 2019-05-21		alejandramed		Homologating of standard error handling
1.4.0    2019-07-15		alejandramed		Setting error parameters as optionals
1.5.0	 2019-10-14     puertac				SRE Implementation
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF @DSSearch IS NULL
BEGIN
	SET @Error = 219
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
select record
******************************************************************************/
BEGIN TRY 
  IF @SearchType = 0 -- SERACH ONLY BY DISTRIBUTORID 
    BEGIN 
      SELECT d.sdistributorid AS distributorid, 
             d.sfirstname     AS firstname, 
             d.slastname      AS lastname, 
             d.steam          AS team, 
             d.stype          AS TYPE, 
             cd.saddress      AS address, 
             cd.phone, 
             'Distributor'    AS dsclass,
			 d.sDistributorCountryProcessingCode AS [CountryProcessingCode]
       /*   ,CD.NationalID 
          ,CD.RegionLocalName 
          ,CD.RegionEnglishName  ----  Revert back changes (SandhyaP)  */
      FROM dbo.v_distributor d 
             LEFT JOIN dbo.v_distributorcontactdetails cd 
               ON cd.sdistributorid = d.sdistributorid 
      WHERE  d.sdistributorid = @DSSearch 
      /*     UNION 
   SELECT
    D.sDistributorID AS DistributorID 
    ,S.sSpouseFirstName AS FirstName 
    ,S.sSpouseLastName AS LastName 
    ,D.sTeam AS Team 
    ,D.sType AS Type 
    ,CD.sAddress AS Address 
    ,CD.Phone 
    ,'Spouse' AS DSClass 
  FROM  
    dbReport.dbo.tblDistributorSpouse S (NOLOCK) 
  LEFT JOIN 
    dbo.v_Distributor D 
  ON 
    S.nDistributorID = D.nDistributorID 
  LEFT JOIN 
    dbo.v_DistributorContactDetails CD 
    ON 
    CD.sDistributorID = D.sDistributorID 
  WHERE  
    S.sDistributorID = @DSSearch  
*/ 
      UNION 
      SELECT t.distributorid                                                                                                          AS distributorid, 
             t.firstname                                                                                                              AS firstname, 
             t.lastname                                                                                                               AS lastname, 
             ''                                                                                                                       AS team, 
             ''                                                                                                                       AS TYPE, 
             Isnull(Coalesce(t.address1,''),'') + ' ' + Isnull(Coalesce(t.address2,''),'') + ' ' + Isnull(Coalesce(t.address3,''),'') AS address, 
             t.dayphone                                                                                                               AS phone, 
             'Temp'                                                                                                                   AS dsclass,
			 t.Country																												  AS Country
         /*  ,EXT.NationalID 
             ,S.RegionLocal AS RegionLocalName 
             ,S.RegionEnglish AS RegionEnglishName   --- Revert back changes (SandhyaP) */
      FROM dbo.tempdistributors t WITH (NOLOCK) 
      --  LEFT JOIN dbo.tblDistributorExtn EXT (NOLOCK) 
      --   ON EXT.DistributorID = T.Distributorid 
      --        LEFT JOIN dbo.StoreRegion S (NOLOCK) 
      --   ON EXT.PK_Store = S.PK_Store 
      WHERE t.distributorid = @DSSearch AND NOT EXISTS (SELECT 1 FROM dbo.v_Distributor DS  WHERE DS.sDistributorID = t.DistributorID)
      ORDER BY 1 
    END 
  ELSE  -- SEARCH ONLY BY LAST NAME 
    BEGIN 
      SELECT   d.sdistributorid AS distributorid, 
               d.sfirstname     AS firstname, 
               d.slastname      AS lastname, 
               d.steam          AS team, 
               d.stype          AS TYPE, 
               cd.saddress      AS address, 
               cd.phone, 
               'Distributor'    AS dsclass,
			   d.sDistributorCountryProcessingCode AS [sDistributorCountryProcessingCode]
      --    ,CD.NationalID 
      --    ,CD.RegionLocalName 
      --    ,CD.RegionEnglishName 
      FROM dbo.v_distributor d 
               LEFT JOIN dbo.v_distributorcontactdetails cd 
                 ON cd.sdistributorid = d.sdistributorid 
      WHERE    Left(d.slastname,Len(@DSSearch)) = @DSSearch 
      /*   UNION 
SELECT 
D.sDistributorID AS DistributorID 
,S.sSpouseFirstName AS FirstName 
,S.sSpouseLastName AS LastName 
,D.sTeam AS Team 
,D.sType AS Type 
,CD.sAddress AS Address 
,CD.Phone 
,'Spouse' AS DSClass 
FROM  
dbReport.dbo.tblDistributorSpouse S (NOLOCK) 
LEFT JOIN 
dbo.v_Distributor D 
ON 
S.nDistributorID = D.nDistributorID 
LEFT JOIN 
dbo.v_DistributorContactDetails CD 
  ON 
CD.sDistributorID = D.sDistributorID 
WHERE  
LEFT(S.sSpouseLastName,len(@DSSearch)) = @DSSearch 
UNION 
SELECT 
T.DistributorID AS DistributorID 
,T.FirstName AS FirstName 
,T.LastName AS LastName 
,'' AS Team 
,'' AS Type 
,ISNULL(COALESCE(T.Address1,''),'') + ' ' + ISNULL(COALESCE(T.Address2,''),'') + ' ' + ISNULL(COALESCE(T.Address3,''),'') AS Address 
,T.DayPhone AS Phone 
,'Temp' AS DSClass 
FROM  
dbo.TempDistributors T (NOLOCK) 
WHERE  
LEFT(T.LastName,len(@DSSearch)) = @DSSearch */ 
      ORDER BY 1 
    END 
   
  IF @@ROWCOUNT = 0 
    BEGIN 
      SET @Error = 219 
       
      -- Update ErrorLog 
      EXEC dbo.Usp_utility_updateerrorlog 
        @ProcedureName = @StoredProcedure , 
        @ErrorNumber = @Error , 
        @ErrorMessage = @ErrorMessage OUTPUT 
       
      RETURN 
    END 
END TRY 

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

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
	End procedure
******************************************************************************/
END