CREATE PROCEDURE [dbo].[usp_AWT_upd_isNonTab]
	@AWTYear int
	,@IsDevQA bit = 0

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_upd_isNonTab

USE:			EXEC dbo.usp_AWT_upd_isNonTab
					@AWTYear = 2009
					,@IsDevQA = 1

DESCRIPTION:	updates isNonTab column

DEPENDENCIES
--------------------------------------------------------------------
VERSIONS
--------------------------------------------------------------------
	1.0.0	 2010-01-05    Scott	     Initial
    1.2.0	 2019-10-11    puertac	     SRE Implementation
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	update isNonTAB
******************************************************************************/
DECLARE @NonTABDate SMALLDATETIME
		,@StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
			SELECT @NonTABDate = NonTABDate FROM dbo.AWT_Definitions WITH (NOLOCK) WHERE AWTYear = @AWTYear

			-- GET Qual must be greater than or equal to this date to be non-tab
			-- or if GET Qual is less than the DS is not a non-TAB

			UPDATE
				A
			SET
				IsNonTAB = CASE WHEN Qual_G <= @NonTABDate THEN 0 ELSE 1 END
			FROM
				dbo.AWT A
			WHERE
				A.AWTYear = @AWTYear

			/******************************************************************************
				end procedure
			******************************************************************************/
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
END