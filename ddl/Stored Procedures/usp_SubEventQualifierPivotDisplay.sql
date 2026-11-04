
CREATE PROCEDURE [dbo].[usp_SubEventQualifierPivotDisplay]
	@EventID int

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_SubEventQualifierPivotDisplay]
	
	USE:			
			DECLARE @e int, @em varchar(4000)
			
			EXEC [dbo].[usp_SubEventQualifierPivotDisplay]
				@EventID = 0
				,@Error = @e OUTPUT
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

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE 
			@sql nvarchar(4000)
			,@SubEventCount int
			,@Counter int

		SELECT
			@SubEventCount = COUNT(*)
		FROM
			dbo.SubEvent (NOLOCK)
		WHERE
			PK_Event = @EventID

		SET @sql = '
		SELECT
			PK_Event
			,PK_Distributor'

		SET @Counter = 1
		WHILE @Counter <= @SubEventCount
		BEGIN
			SET @sql = @sql + '
			,E' + RIGHT('0' + CONVERT(varchar,@Counter),2)
			SET @Counter = @Counter + 1
		END

		SET @sql = @sql + '
		FROM
			dbo.SubEventQualifierPivot (NOLOCK)
		WHERE
			PK_Event = ' + CONVERT(varchar,@EventID)

		EXEC sp_executesql @sql

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