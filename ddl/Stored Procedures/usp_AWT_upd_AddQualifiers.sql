CREATE PROCEDURE [dbo].[usp_AWT_upd_AddQualifiers]
	@AWTYear int,


	   @IsDevQA			BIT = 0,   
	   @Error			int = 0 OUTPUT,
	   @ErrorMessage	varchar(4000) = NULL OUTPUT

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_upd_AddQualifiers

USE:			dbo.usp_AWT_upd_AddQualifiers
					@AWTYear = 2010
					,@IsDevQA = 1

DESCRIPTION:	update AWT_Qualifiers

DEPENDENCIES
--------------------------------------------------------------------
everything

VERSIONS
--------------------------------------------------------------------
1	2010-01-05	Scott		Initial
2	2019-10-14	JonathanO	Refactor code (SRE)

******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = 'usp_AWT_upd_AddQualifiers'

BEGIN TRY
/******************************************************************************
	delete any previous records for @AWTYear
******************************************************************************/
DELETE FROM 
	dbo.AWT_Qualifiers
WHERE
	AWTYear = @AWTYear

/******************************************************************************
	insert qualifiers
******************************************************************************/
INSERT
	dbo.AWT_Qualifiers
(
	AWTYear
	,PK_Distributor
	,DistributorID
	,DateAdded
	,Qual_AWT
)
SELECT
	AWTYear
	,PK_Distributor
	,DistributorID
	,DateAdded
	,Qual_AWT
FROM
	dbo.AWT WITH (NOLOCK)
WHERE
	AWTYear = @AWTYear
	AND
	NOT EXISTS (SELECT 1 FROM dbo.AWT_Qualifiers A WITH (NOLOCK) WHERE AWT.DistributorID = A.DistributorID AND AWT.AWTYear = A.AWTYear AND AWT.Qual_AWT = A.Qual_AWT)

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