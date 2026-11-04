CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_DSEventCoordinatorDetails]
        -- Mandatory Parameters
		 @PK_Event INT
		,@CreatedDistributorID VARCHAR(10)
		,@CoOrdinatorDetails udt_EventCoOrdinatorDetail READONLY
		,@IsSeries BIT = 0 --By default opened in Instance, if opened in Series pass 1
		,@IsRecurring BIT = 0 -- Default 0; Will be 1 for Recurring Events only	

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN	

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Upd_DSEventCoordinatorDetails
USE:
			DECLARE @e int, @em varchar(4000)
			declare @IsDevQA int
			DECLARE @CoOrdinatorDetails udt_EventCoOrdinatorDetail
			
			INSERT INTO @CoOrdinatorDetails
			VALUES (NULL, NULL, NULL, 'Mark Hughes', '310-410-9600', 'MarkH@herbalife.com', 'Mr', 'Distributor', 'http:\\www.herbalife.com', 0)
			
			EXEC usp_MyHLEventAPI_Upd_DSEventCoordinatorDetails
					 @Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@PK_Event = 10031
					,@CoOrdinatorDetails = @CoOrdinatorDetails
					,@CreatedDistributorID = '1111111111'
					,@IsSeries = 1
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Updates record in dbo.EventCoordinatorDetail

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventCoordinator

VERSIONS
--------------------------------------------------------------------
1	2008-12-06	PrabhuS	Initial
2	2013-01-16	Sushma	Changes made for Title column of CoOrdinatorDetails
3	2014-07-10	Sushma	Changes made for TeamLevel and Website columns of CoOrdinatorDetails
4	2015-02-12	Sushma	Changes made for Recurring Events
5	2019-08-14	NoeG	Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON	

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @EventsToBeUpdated AS TABLE (PK_Event INT)

SELECT @Error = 0, @ErrorMessage = '';

SET @CreatedDistributorID = LTRIM(RTRIM(@CreatedDistributorID))

/*Validate special characters for Title */
--IF EXISTS (SELECT 1 WHERE REPLACE(REPLACE(REPLACE(REPLACE(@CoordinatorTitle, ',', ''), '.', ''), '-', ''), ' ', '') LIKE '%[^A-Za-z0-9]%') 
--BEGIN

--	SET @Error = 407
--	-- Update ErrorLog
--	EXEC dbo.usp_Utility_UpdateErrorLog 
--		@ProcedureName = @StoredProcedure 
--		,@ErrorNumber = @Error
--		,@ErrorMessage = @ErrorMessage OUTPUT
--	RETURN 
	
--END

/*Validate if the distributor exists*/
IF NOT EXISTS(SELECT TOP 1 nDistributorID FROM dbo.v_Distributor WITH (NOLOCK)
			WHERE sDistributorID = @CreatedDistributorID)
BEGIN
	SET @Error = 8
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END


/*Validate if the event exists*/
IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.Event WITH (NOLOCK)
			WHERE PK_Event = @PK_Event)
BEGIN
	SET @Error = 5
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END


/* UPDATE THE RECORD INTO EVENTCOORDINATORDETAIL TABLE */

BEGIN TRY

	MERGE
		dbo.EventCoOrdinatorDetail ECD
	USING
	(
		SELECT @PK_Event [PK_Event], @CreatedDistributorID [CreatedDistributorID], CD.PK_EventCoordinatorDetail, CD.CoordinatorID
				, LTRIM(RTRIM(CD.CoordinatorName)) CoordinatorName, LTRIM(RTRIM(CD.CoordinatorPhone)) CoordinatorPhone, LTRIM(RTRIM(CD.CoordinatorEmail)) CoordinatorEmail
				, LTRIM(RTRIM(CD.CoordinatorTitle)) CoordinatorTitle, LTRIM(RTRIM(CD.CoordinatorTeamLevel)) CoordinatorTeamLevel, LTRIM(RTRIM(CD.coordinatorWebsite)) coordinatorWebsite
				,CD.IsDelete, CASE WHEN (ISNULL(LTRIM(RTRIM(CD.CoordinatorName)), '') = '' AND ISNULL(LTRIM(RTRIM(CD.coordinatorWebsite)), '') = '' AND CD.IsDelete = 1)THEN 1 ELSE 0 END IsUpdate
		FROM @CoOrdinatorDetails CD
	) AS CD
	ON ECD.PK_Event = CD.PK_Event
	AND ECD.PK_EventCoordinatorDetail = CD.PK_EventCoordinatorDetail
	--AND ECD.[CreatedDistributorID] = CD.[CreatedDistributorID]
	WHEN NOT MATCHED THEN INSERT (PK_Event, CreatedDistributorID, CoordinatorID, CoordinatorName, CoordinatorPhone, CoordinatorEmail, CoordinatorTitle, 
									CoordinatorTeamLevel, coordinatorWebsite)
		VALUES (CD.PK_Event, CD.CreatedDistributorID, CD.CoordinatorID, CD.CoordinatorName, CD.CoordinatorPhone, CD.CoordinatorEmail, CD.CoordinatorTitle, 
									CD.CoordinatorTeamLevel, CD.coordinatorWebsite)
	WHEN MATCHED THEN
	UPDATE
	SET
		 CoordinatorName = CASE WHEN CD.IsUpdate = 1 THEN NULL ELSE CD.CoordinatorName END
		,CoordinatorPhone = CASE WHEN CD.IsUpdate = 1 THEN NULL ELSE CD.CoordinatorPhone END
		,CoordinatorEmail = CASE WHEN CD.IsUpdate = 1 THEN NULL ELSE CD.CoordinatorEmail END
		,CoordinatorTitle = CASE WHEN CD.IsUpdate = 1 THEN NULL ELSE CD.CoordinatorTitle END
		,CoordinatorTeamLevel = CASE WHEN CD.IsUpdate = 1 THEN NULL ELSE CD.CoordinatorTeamLevel END
		,CoordinatorWebsite = CASE WHEN CD.IsUpdate = 1 THEN NULL ELSE CD.CoordinatorWebsite END
		,CreatedDistributorID = CD.[CreatedDistributorID]
		,ModifiedDateUTC = @StartTime
	;
	
	UPDATE dbo.Event SET CreatedDistributorID = @CreatedDistributorID WHERE PK_Event = @PK_Event -- To be removed while the column gets deleted
	
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

--perform updates on all the future instances/instances in past that were not approved when opened in series
IF ( @IsSeries = 1 -- incase of child instance
	 OR
	 @IsRecurring = 1 -- in case of parent instance
	)
BEGIN
	BEGIN TRY
	
		INSERT INTO @EventsToBeUpdated (PK_Event)
		SELECT EC.PK_Event	
		FROM	
			dbo.Event E WITH (NOLOCK)
		INNER JOIN
			dbo.Event EP WITH (NOLOCK)
		ON
			EP.PK_Event = COALESCE(E.PK_OldEventAPP, E.PK_Event)
		AND
			E.PK_Event = @PK_Event
		INNER JOIN
			dbo.Event EC WITH (NOLOCK)
		ON
			EP.PK_Event = EC.PK_OldEventApp
		AND
			E.PK_Event <> EC.PK_Event
		WHERE	
			EC.EventApprovalStatus IN (0, 1, 3)
		AND
			(EC.dEndUTC >= CONVERT(DATE,GETUTCDATE(), 110))

		DELETE ECD FROM dbo.EventCoOrdinatorDetail ECD INNER JOIN @EventsToBeUpdated E ON ECD.PK_Event = E.PK_Event

		INSERT INTO dbo.EventCoordinatorDetail (PK_Event, CreatedDistributorID, CoordinatorID, CoOrdinatorName, CoOrdinatorPhone, CoOrdinatorEmail, CreatedBy, ModifiedBy
			, CoOrdinatorTitle, CoOrdinatorTeamLevel, CoOrdinatorWebsite, CreatedDateUTC, ModifiedDateUTC)
		SELECT
			  E.PK_Event, CreatedDistributorID, CoordinatorID, CoOrdinatorName, CoOrdinatorPhone, CoOrdinatorEmail, ModifiedBy, ModifiedBy, CoOrdinatorTitle, CoOrdinatorTeamLevel
			, CoOrdinatorWebsite, @StartTime, @StartTime
		FROM
			@EventsToBeUpdated E
		CROSS JOIN
			dbo.EventCoordinatorDetail ECD WITH (NOLOCK)
		WHERE 
			ECD.PK_Event = @PK_Event
	
	-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

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
END

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

