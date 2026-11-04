CREATE PROCEDURE [dbo].[usp_AWT_MAIN]
	@AWTYear int,


	   @IsDevQA			BIT = 0,   
	   @Error			int = 0 OUTPUT,
	   @ErrorMessage	varchar(4000) = NULL OUTPUT
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_MAIN

USE:			EXEC dbo.usp_AWT_MAIN
					@AWTYear = 2026
					,@IsDevQA = 0

DESCRIPTION:	runs awt


DEPENDENCIES
--------------------------------------------------------------------
everything

VERSIONS
--------------------------------------------------------------------
1	2010-01-05	Scott			Initial
2   2012-06-15  SandhyaP		usp_AWT_upd_DistributorSet will be writing to pubDim.dbo.dimDSSetMembers
3   2014-01-12  IniU			Add code to call stored procedure to maintain repeat AWT Qualifiers table
4	2019-10-14	JonathanO		Refactor code (SRE)
5   2020-07-07  Emi				change PastAWT to update after DateAdded step
6	2026-03-04	alejandramed	Reverts to the pre–Greater China logic 
7	2026-04-21	alejandramed	User Story 1443683: AWT 2026 - Split for WW qualifiers
								Revert this change on v8: Handle the promotion exclusively for the participating countries.
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)


DECLARE
	@StartTime datetime = GETUTCDATE()
	,@AWTStartMonth smalldatetime
	,@AWTEndMonth smalldatetime
	,@NonTABMonth smalldatetime
	,@RoyaltyMonth smalldatetime
	,@RO money
 
BEGIN TRY

IF EXISTS (SELECT 1 FROM [DevAdmin].[ScheduleException] WITH (NOLOCK)
WHERE Active = 1 AND CONVERT(DATE,GETUTCDATE()) BETWEEN StartDate AND EndDate
AND TRIM(REPLACE(REPLACE([StoredProcedureName],'[',''),']','')) = TRIM(REPLACE(REPLACE(@StoredProcedure,'[',''),']','')))
BEGIN
	PRINT 'ScheduleException; The process is skipped.'
	RETURN;
END
ELSE
BEGIN

	--Not exception

	/******************************************************************************
		get AWT definitions
	******************************************************************************/
	SELECT
		@AWTStartMonth = StartDate
		,@AWTEndMonth = EndDate
		,@NonTABMonth = NonTABDate
	FROM
		dbo.AWT_Definitions WITH (NOLOCK)
	WHERE
		AWTYear = @AWTYear

	/******************************************************************************
		set @RoyaltyMonth based on timestamp
		this is the royaltymonth for which the report is run
	******************************************************************************/

	SET @RoyaltyMonth = CONVERT(varchar,DATEADD(m,-1,DATEADD(d,-DAY(@StartTime)+1,@StartTime)),112)
	SELECT
		  @RO = SUM(F.mRoyaltyOverrides + ISNULL(F.mMainRoyaltyOverrides,0) - ISNULL(mGCAssocRoyaltyOverrides,0)) -- GC
	FROM
		  dbo.v_aggFQS_ID F WITH (NOLOCK)
	INNER JOIN
		  dbo.v_Distributor D WITH (NOLOCK)
		  ON
				F.nDistributorID = D.nDistributorID
	WHERE
		  dRoyaltyMonth = @RoyaltyMonth
		  AND
				(
					  F.nMainIsType23 = 0
					  OR
							(
								  F.nMainIsType23 = 1
								  AND F.nIsMainID = 0
							)
				)
            
	IF @RO < 10000000 -- change to previous month - 1; 1 million is an arbitrary number to be sure full RO load has occurred
		  SET @RoyaltyMonth = CONVERT(varchar,DATEADD(m,-2,DATEADD(d,-DAY(@StartTime)+1,@StartTime)),112)

	IF @isDevQA = 1
	BEGIN
		SELECT
			@AWTYear '@AWTYear'
			,@AWTStartMonth '@AWTStartMonth'
			,@AWTEndMonth '@AWTEndMonth'
			,@NonTABMonth '@NonTABMonth'
			,@RoyaltyMonth '@RoyaltyMonth'
	END

	IF @RoyaltyMonth = CONVERT(varchar,DATEADD(m,-1,DATEADD(d,-DAY(@StartTime)+1,@StartTime)),112)
	BEGIN

	/******************************************************************************
		rebuild indexes
	******************************************************************************/
	EXEC dbo.usp_AWT_BuildTablesIndexes

	/******************************************************************************
		get base metrics from aggregation table
	******************************************************************************/
	EXEC dbo.usp_AWT_ins_AWTMetrics
		@AWTYear = @AWTYear
		,@AWTStartMonth = @AWTStartMonth
		,@AWTEndMonth = @AWTEndMonth
		,@RoyaltyMonth = @RoyaltyMonth
		,@IsDevQA = @IsDevQA

	/******************************************************************************
		apply accelerators
	******************************************************************************/
	EXEC dbo.usp_AWT_ins_Accelerators @AWTYear = @AWTYear, @IsDevQA = @IsDevQA

	/******************************************************************************
		determine who qualified
	******************************************************************************/
	EXEC usp_AWT_DetermineQualifiers @IsDevQA = @IsDevQA

	/******************************************************************************
		insert distinct list of qualifiers and their qual date into dbo.AWT
	******************************************************************************/
	EXEC dbo.usp_AWT_ins_Qualifiers @AWTYear = @AWTYear, @IsDevQA = @IsDevQA

	/******************************************************************************
		update DateAdded
	******************************************************************************/
	EXEC dbo.usp_AWT_upd_DateAdded @AWTYear = @AWTYear, @IsDevQA = @IsDevQA

	/******************************************************************************
		determine PAST AWT
	******************************************************************************/
	EXEC dbo.usp_AWT_upd_PastAWT @AWTYear = @AWTYear

	/******************************************************************************
		update all the DSInfo
	******************************************************************************/
	EXEC dbo.usp_AWT_upd_DSInfo @AWTYear = @AWTYear, @IsDevQA = @IsDevQA

	/******************************************************************************
		update non TAB status
	******************************************************************************/
	EXEC dbo.usp_AWT_upd_isNonTab @AWTYear = @AWTYear, @IsDevQA = @IsDevQA

	/******************************************************************************
		update AWT_Qualifiers
	******************************************************************************/
	EXEC dbo.usp_AWT_upd_AddQualifiers @AWTYear = @AWTYear ,@IsDevQA = 1

	/******************************************************************************
		update distributor set 
	******************************************************************************/
	EXEC dbo.usp_AWT_upd_DistributorSet @AWTYear = @AWTYear

	/******************************************************************************
		update repeat AWT Qualifiers table
	******************************************************************************/
	EXEC dbo.usp_AWT_Qualifiers_Tracking @AWTYear = @AWTYear

			-- Update processing Log
			EXEC [dbo].[usp_Utility_UpdateProcessingLog]
					@StoredProcedureName = @StoredProcedure
					,@StartTime = @StartTime;

END
	ELSE PRINT 'Skipped process: Full RO load has not occurred yet'

END
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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;
