CREATE PROCEDURE [dbo].[usp_EventAPI_Validate_UploadedMembers]
        @PK_Event int

		-- Optional
		,@UserName varchar(255) = NULL
		,@ChkSubEvent bit = 0
		,@ReturnValidRecords bit = 0
		,@ReturnInvalidRecords bit = 0

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
    OBJECT:	[dbo].[usp_EventAPI_Validate_UploadedMembers]
    
    USE:            
			DECLARE @e int, @em varchar(4000)
            
            EXEC [dbo].[usp_EventAPI_Validate_UploadedMembers]
				@PK_Event = 1
				,@ChkSubEvent = 0
                ,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]


    DESCRIPTION: [usp_EventAPI_Validate_UploadedMembers]

    NOTES:
			*	@ChkSubEvent = 1 to check than PK_SubEvent from [UploadedMemberStg] exists on [SubEvent], else it wil be ignored
			*	@DeleteDump = 1 will erase invalid records from previous loads, otherwise they will be kept in [UploadedMemberDump]
			*	@ReturnValidRecords and/or @ReturnInvalidRecords with 1 will return the dataset inserted/invalid.
				Use with caution; can return large amount of records

    DEPENDENCIES
    --------------------------------------------------------------------
    [UploadedMemberStg], [UploadedMember], [UploadedMemberDump], [UploadedMemberConfig], [Event], [SubEvent],
	[PubEvents].[dbo].[dimDistributor]

    VERSIONS
    --------------------------------------------------------------------
    1.0.0        2018-09-03     RogelioR        Initial
    1.1.0		 2019-07-15		alejandramed	Setting error parameters as optionals
	1.2.0		 2019-10-10		alejandramed	SRE Compliance 	
******************************************************************************/

    SET ANSI_NULLS ON
    SET QUOTED_IDENTIFIER ON
    SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidRecords int
			,@InvalidRecords int
			,@StatusCode VARCHAR(20) = 'COMPLETE'

	SELECT @Error = 0, @ErrorMessage = '', @UserName = ISNULL(@UserName, replace(suser_name(),'HERBALIFECORP\',''));

BEGIN TRY
        IF @IsDevQA = 1
            SELECT [PK_Event], COUNT(1) FROM [UploadedMemberStg] WITH (NOLOCK) GROUP BY [PK_Event];
		
/* ***************** SonarQube check 27 - "DELETE" and "UPDATE" statements should contain "WHERE" clauses */

		-- Check if there's another upload in progress; otherwise change status in [Running]
		IF (SELECT TOP 1 [Running] FROM [UploadedMemberConfig] WITH (NOLOCK)) = 1
			RAISERROR('Another upload is running', 16, 1);
		ELSE
			--UPDATE [UploadedMemberConfig] SET [Running] = 1;
			UPDATE [UploadedMemberConfig] SET [Running] = 1 WHERE [PK_UploadedMemberConfig] > 0;

/* ***************** SonarQube check 27 */

		-- Event must be valid
		IF NOT EXISTS (SELECT 1 FROM [dbo].[Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
			RAISERROR('Event does not exists', 16, 1);
			
		-- Clear previous records
		DELETE FROM [UploadedMember] WHERE [PK_Event] = @PK_Event;
		DELETE FROM [UploadedMemberDump] WHERE [PK_Event] = @PK_Event;
		
		IF OBJECT_ID('tempdb..#Members') IS NOT NULL
			DROP TABLE #Members;

		-- Check if ids for members and subevents are valid
		SELECT
				s.[PK_Event]
				,s.[PK_SubEvent]
				,s.[DistributorID]
				,CASE WHEN d.[StatusCode] = @StatusCode THEN 1 ELSE 0 END AS [ValidMember]
				,CASE WHEN se.[PK_SubEvent] IS NULL THEN 0 ELSE 1 END AS [ValidSubEvent]
			INTO #Members
			FROM [dbo].[UploadedMemberStg] AS s WITH (NOLOCK)
				LEFT JOIN [PubEvents].[dbo].[dimDistributor] AS d WITH (NOLOCK) ON s.[DistributorID] = d.[DistributorID]
				LEFT JOIN [SubEvent] AS se WITH (NOLOCK) ON se.[PK_SubEvent] = s.[PK_SubEvent]
					AND se.[PK_Event] = @PK_Event;

		-- Insert valid members
		INSERT INTO [UploadedMember] (
				[PK_Event]
				,[PK_SubEvent]
				,[DistributorID]
			)
			SELECT
					[PK_Event]
					,[PK_SubEvent]
					,[DistributorID]
				FROM #Members
				WHERE ValidMember = 1
					AND (@ChkSubEvent = 0 OR ValidSubEvent = 1);

		SELECT @ValidRecords =  @@ROWCOUNT;

		-- Insert invalid members and flags
		INSERT INTO [UploadedMemberDump] (
				[PK_Event]
				,[PK_SubEvent]
				,[DistributorID]
				,[ValidMember]
				,[ValidSubEvent]
			)
			SELECT
					[PK_Event]
					,[PK_SubEvent]
					,[DistributorID]
					,[ValidMember]
					,[ValidSubEvent]
				FROM #Members
				WHERE ValidMember = 0
					OR (@ChkSubEvent = 1 and ValidSubEvent = 0)
		
		SELECT @InvalidRecords = @@ROWCOUNT;

		-- Summary of the operation and update status
		SELECT @ValidRecords AS [MembersInserted], @InvalidRecords AS [InvalidRecords];

/* ***************** SonarQube check 28 - "DELETE" and "UPDATE" statements should contain "WHERE" clauses */
		UPDATE [UploadedMemberConfig] SET
			[Running] = 0
			,[LastUser] = @UserName
			,[LastRun] = getutcdate()
			WHERE [PK_UploadedMemberConfig] > 0;
/* ***************** SonarQube check 28 */

		-- Return detailed results. Can return a lot of data, use wisely
		IF @ReturnValidRecords = 1
			SELECT
					[PK_Event]
					,[PK_SubEvent]
					,[DistributorID]
				FROM [UploadedMember] WITH (NOLOCK)
				WHERE [PK_Event] = @PK_Event;

		IF @ReturnInvalidRecords = 1
			SELECT
					[PK_Event]
					,[PK_SubEvent]
					,[DistributorID]
					,[ValidMember]
					,[ValidSubEvent]
				FROM [UploadedMemberDump] WITH (NOLOCK)
				WHERE [PK_Event] = @PK_Event;

	-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

    END TRY
    BEGIN CATCH
        SET @Error = ERROR_NUMBER()
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @StoredProcedure = ERROR_PROCEDURE()

/* ***************** SonarQube check 29 - "DELETE" and "UPDATE" statements should contain "WHERE" clauses */
		UPDATE [UploadedMemberConfig] SET
			[Running] = 0
			,[LastUser] = @UserName
			,[LastRun] = getutcdate()
			WHERE [PK_UploadedMemberConfig] > 0;
/* ***************** SonarQube check 29 */

        IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

        -- UPDATE ERROR LOG
        EXEC dbo.usp_Utility_UpdateErrorLog
                @ProcedureName = @StoredProcedure
                ,@ErrorNumber = 3
                ,@ErrorMessage = @ErrorMessage
                ,@SQLErrorCode = @Error
                ,@SQLErrorMsg = @ErrorMessage
        RETURN
    END CATCH;
END;
GO

