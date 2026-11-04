CREATE PROCEDURE [dbo].[usp_EventAPI_Get_InventoryURL]
	--Required
	@DistributorID varchar(10)
	,@EventID int

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_InventoryURL

USE:            DECLARE @e int, @em varchar(max)

                EXEC usp_EventAPI_Get_InventoryURL 
					@DistributorID = 'LOR003672'
                   ,@EventID=166
                   ,@Error = @e OUTPUT  /* @e must be defined in the local call */
                   ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
                   ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:      Get Distributor Inventory String for inventory popup

NOTES:                  

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1		2009-04-03		Scott			Initial
1.1		2019-05-21		alejandramed	Homologating of standard error handling	
1.2		2019-07-15		alejandramed	Setting error parameters as optionals
1.3		2019-10-08		alejandramed	SRE Compliance 
1.4		2022-09-21		alejandramed	Including EventID in the URL
1.5		2022-11-07		alejandramed	Forcing inventory path on Q3 environment
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY
	
	/******************************************************************************
      variable declaration
	******************************************************************************/
	DECLARE 
		  @PK_Distributor int
		  , @PK_SubEvent int
		  , @PK_EventsRegistration int
		  , @PK_SubEventQualifier int
		  , @e int
		  , @em varchar(200)
		  , @URL varchar(1000)
		  , @Team varchar(1)
		  , @isChair varchar(1) = '0'
		  , @isFounder varchar(1) = '0'
		  , @COP varchar(2)
		  , @SubTeam   varchar(5) 
		  , @DSType varchar(2)
		  --, @RemovedUTC DATETIME = '2049-12-31'
		  , @InventoryPath NVARCHAR(200) 

		IF (@@servername = 'ZUSW2Q3ENSQLDB')
		BEGIN
			SET @InventoryPath = 'https://er.myhrbl.com/Resource/Global/EventInventory/'
		END
		ELSE
		BEGIN
			SET @InventoryPath = '/Resource/Global/EventInventory/'
		END
	/******************************************************************************
	Check if Distributor exist
	******************************************************************************/

	IF EXISTS  (SELECT nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
					UNION
					  SELECT PK_Temp FROM dbo.TempDistributors WITH (NOLOCK) WHERE DistributorID = @DistributorID)
   
	BEGIN

		-- Get country of processing 
		SELECT @COP = sDistributorCountryProcessingCode 
				 ,@SubTeam = sSubTeam 
				 ,@DSType  = sType 
				 ,@isChair = CASE WHEN sSubTeam IN ('CC','FC') THEN '1' ELSE '0' END
				 ,@isFounder = CASE WHEN sSubTeam = 'FC' THEN '1' ELSE '0' END
		FROM 
			  dbo.v_Distributor 
		WHERE 
			  sDistributorID = @DistributorID
      
		/******************************************************************************
		Get all the Distributor Info for Registration
		******************************************************************************/



		--    SET @URL = 'http://www.keota.org/eventInventory/?eid=eid_2009ExtBR&t='
		--    SET @URL = 'http://www.keota.org/eventInventory/' + CONVERT(varchar,@EventID) + '/index.htm?eid=&t='
			  SET @URL = @InventoryPath + CONVERT(varchar,@EventID) + '/index.htm?eid='+ CONVERT(varchar,@EventID) +'&t='

			  -- get team status
			  SELECT
					@URL = @URL + LOWER(COALESCE(LEFT(CASE WHEN sType = 'SP' and sTeam IS NULL THEN sType ELSE sTeam END,1),''))
			  FROM
					dbo.v_Distributor (NOLOCK)
			  WHERE
					sDistributorID = @DistributorID

			  -- add chairman's club status
			  SELECT @URL = @URL + '&cc=' + @isChair

			  -- add founders cirlce status
			  SELECT @URL = @URL + '&f=' + @isFounder
      
			  -- add COP
			  SELECT @URL = @URL + '&cop=' + @COP
      
			  -- add sub team status
			  SELECT @URL = @URL + '&st=' + @SubTeam 
      
			  -- add DS Type (SP or DS)
			  SELECT @URL = @URL + '&dt=' + @DSType

			  SELECT 
				 @URL = @URL + '&se' + CONVERT(varchar,S.SubEventNumber) + '=' + CONVERT(varchar,COALESCE(SQ.Qualified,0)) 
			  FROM 
				 dbo.SubEvent S  WITH (NOLOCK)
			  LEFT JOIN
				 dbo.SubEventQualifier SQ WITH (NOLOCK)
			  ON 
				 SQ.PK_SubEvent = S.PK_SubEvent
				 AND
				 SQ.DistributorID = @DistributorID
					and sq.removedutc = '2049-12-31'
			  WHERE
				 S.PK_Event = @EventID
			  ORDER BY
				 S.SubEventNumber

			  SELECT @URL
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
		  End procedure
	******************************************************************************/
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
END