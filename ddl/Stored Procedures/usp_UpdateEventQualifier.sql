
CREATE PROCEDURE [dbo].[usp_UpdateEventQualifier]

	-- Error Parameters
	@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_UpdateEventQualifier]
	
	USE:			
			DECLARE @e int, @em varchar(4000)
			
			EXEC [dbo].[usp_UpdateEventQualifier]
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0										Initial
	2.0.0		2019-09-30		NoeG			SRE template applied
	
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE 
			@Timestamp datetime
			,@SQL nvarchar(4000)
			,@PK_Schedule int

		SET @Timestamp = GETUTCDATE()

		/******************************************************************************
			get schedule for update qualifications
		******************************************************************************/
		SELECT
			@PK_Schedule = PK_Schedule
		FROM
			dbo.Schedule WITH (NOLOCK)
		WHERE
			ScheduleName = 'Update Qualification'

		/******************************************************************************
			get list of stored procedures to execute for all events that need
			qualifications updated
		******************************************************************************/
		SET @SQL = ''

		DECLARE sp_cursor CURSOR FOR 
			SELECT
				'EXEC ' + E.StoredProcedure
			FROM
				dbo.Event E (NOLOCK)
			INNER JOIN
				dbo.EventSchedule S (NOLOCK)
				ON
					E.PK_Event = S.PK_Event
			WHERE
				S.PK_Schedule = @PK_Schedule
				AND
				@Timestamp BETWEEN S.BeginUTC AND S.EndUTC

		OPEN sp_cursor
		FETCH NEXT FROM sp_cursor INTO @SQL   

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC sp_executesql @SQL
			FETCH NEXT FROM sp_cursor INTO @SQL 
		END

		CLOSE sp_cursor
		DEALLOCATE sp_cursor

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