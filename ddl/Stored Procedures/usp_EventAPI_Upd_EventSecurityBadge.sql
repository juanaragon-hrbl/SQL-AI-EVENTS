CREATE PROCEDURE [dbo].[usp_EventAPI_Upd_EventSecurityBadge]
	-- REQUIRED
	 @BadgeUID varchar(20)
	,@PK_EventsRegistration int
	,@PK_Distributor int
	,@DistributorID varchar(10)
	,@VendorEventID varchar(10)
	,@PK_Event int
	,@EventRegistrationName nvarchar(80)
	,@EventQualificationString varchar(500)
	-- OPTIONAL
    ,@BlackListCard int = 0
	,@ModifiedBy varchar(30) = NULL
	,@ModifiedDateUTC smalldatetime = NULL

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************

OBJECT:			dbo.usp_EventAPI_Upd_EventSecurityBadge
USE:	
		DECLARE @e int, @em varchar(4000)

		EXEC usp_EventAPI_Upd_EventSecurityBadge
					 @BadgeUID = '8393593983589'
				    ,@PK_EventsRegistration = 23452
					,@PK_Distributor = 364743
					,@DistributorID = '00893783'
					,@VendorEventID = 'E345'
					,@PK_Event = 22
					,@EventRegistrationName = 'Comini Comina'
					,@EventQualificationString = 'E01:E02:E03:E06'
					,@BlackListCard = 0
					,@ModifiedBy = NULL
					,@ModifiedDateUTC = NULL
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Inserts/Updates record in dbo.EventSecurityBadge

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.EventSecurityBadge

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	IniU	Initial
2	2019-09-05	NoeG	SRE template applied
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

	IF ISNULL(@BlackListCard,0) = 0
	BEGIN

	/******************************************************************************
	verify badge is not blacklisted
	******************************************************************************/
	IF EXISTS(SELECT 1 FROM dbo.EventSecurityBadge WITH (NOLOCK) WHERE BadgeUID = @BadgeUID and PK_BadgeStatus = 3)
	BEGIN
		SET @Error = 253
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END

	/******************************************************************************
	verify badge belongs to registrant/attendee
	******************************************************************************/
	IF EXISTS(SELECT 1 FROM dbo.EventSecurityBadge WITH (NOLOCK) WHERE BadgeUID = @BadgeUID and PK_EventsRegistration <> @PK_EventsRegistration)
	BEGIN
		SET @Error = 254
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END

	/******************************************************************************
	verify badge exist and belongs to attendee
	******************************************************************************/
	--IF EXISTS(SELECT 1 FROM dbo.EventSecurityBadge WHERE BadgeUID = @BadgeUID AND PK_EventsRegistration = @PK_EventsRegistration AND PK_BadgeStatus IN (1,2) AND IsActive = 1)
	--BEGIN TRY
	--UPDATE ESB
	--SET
	--	EventQualificationString = @EventQualificationString
	--	,EventRegistrationName = @EventRegistrationName
	--	,[ModifiedBy] = ISNULL(@ModifiedBy,replace(suser_sname(),'HERBALIFECORP\',''))
	--	,[ModifiedDateUTC] = ISNULL(@ModifiedDateUTC,GetUTCdate())
	--FROM 
	--	dbo.EventSecurityBadge ESB
	--WHERE 
	--	BadgeUID = @BadgeUID
	--	AND
	--	PK_EventsRegistration = @PK_EventsRegistration
	--END TRY
	--
	--BEGIN CATCH
	--	SET @Error = ERROR_NUMBER()
	--	SET @ErrorMessage = ERROR_MESSAGE()
	--	SET @StoredProcedure = ERROR_PROCEDURE()
	--	-- Update ErrorLog
	--	EXEC dbo.usp_Utility_UpdateErrorLog 
	--			@ProcedureName = @StoredProcedure
	--			,@ErrorNumber = 3
	--			,@ErrorMessage = @ErrorMessage OUTPUT
	--			,@SQLErrorCode = @Error
	--			,@SQLErrorMsg = @ErrorMessage
	--	RETURN 
	--END CATCH

	/*****************************************************************************************************
	If brand new badge for attendee OR verify badge exist and belongs to attendee to build badge history
	*****************************************************************************************************/
	IF NOT EXISTS (SELECT 1 FROM dbo.EventSecurityBadge WITH (NOLOCK) WHERE BadgeUID = @BadgeUID) OR EXISTS (SELECT 1 FROM dbo.EventSecurityBadge WITH (NOLOCK) WHERE BadgeUID = @BadgeUID AND PK_EventsRegistration = @PK_EventsRegistration AND PK_BadgeStatus IN (1,2) AND IsActive = 1)
	BEGIN
		-- Check attendee has any active card and inactivate the card(s)
		IF EXISTS(SELECT 1 FROM dbo.EventSecurityBadge WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_EventsRegistration AND PK_BadgeStatus IN (1,2) AND IsActive = 1)
		BEGIN
			BEGIN TRY
			UPDATE ESB
			SET
				IsActive = 0
				,[ModifiedBy] = ISNULL(@ModifiedBy,replace(suser_sname(),'HERBALIFECORP\',''))
				,[ModifiedDateUTC] = ISNULL(@ModifiedDateUTC,GetUTCdate())
			FROM 
				dbo.EventSecurityBadge ESB
			WHERE 
				PK_EventsRegistration = @PK_EventsRegistration
				AND
				PK_BadgeStatus IN (1,2)
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
		END
	
		-- Issue new card to attendee
		BEGIN TRY
		INSERT INTO dbo.EventSecurityBadge(
			CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
			,PK_Event
			,VendorEventID
			,PK_EventsRegistration
			,EventRegistrationName
			,PK_Distributor
			,DistributorID
			,BadgeUID
			,PK_BadgeStatus
			,EventQualificationString
			,IsActive)
		VALUES(
			 GetUTCdate()
			,ISNULL(@ModifiedBy,replace(suser_sname(),'HERBALIFECORP\',''))
			,GetUTCdate()
			,ISNULL(@ModifiedBy,replace(suser_sname(),'HERBALIFECORP\',''))
			,@PK_Event
			,@VendorEventID
			,@PK_EventsRegistration
			,@EventRegistrationName
			,@PK_Distributor
			,@DistributorID
			,@BadgeUID
			,1
			,@EventQualificationString
			,1
			)
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

	END

	END

	ELSE -- Intentionally blacklis card

	BEGIN

		BEGIN TRY
			UPDATE ESB
			SET
				PK_BadgeStatus = 3 -- Blacklist/Inactivate active badge
				,IsActive = 0
				,[ModifiedBy] = ISNULL(@ModifiedBy,replace(suser_sname(),'HERBALIFECORP\',''))
				,[ModifiedDateUTC] = ISNULL(@ModifiedDateUTC,GetUTCdate())
			FROM 
				dbo.EventSecurityBadge ESB
			WHERE 
				BadgeUID = @BadgeUID
	
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

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
END
GO

