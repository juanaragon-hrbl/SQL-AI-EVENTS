
CREATE PROCEDURE [dbo].[usp_Utility_UpdateErrorLog]
	-- REQUIRED
	@ProcedureName  varchar(200)
	,@ErrorNumber int
	,@ErrorMessage varchar(200) OUTPUT
	-- OPTIONAL
	,@TransactionKey int = NULL
	,@SQLErrorCode int = NULL
	,@SQLErrorMsg varchar(200) = ''

AS
BEGIN
/******************************************************************************

	OBJECT:		dbo.usp_Utility_UpdateErrorLog

	USE:		EXEC usp_Utility_UpdateErrorLog
					-- REQUIRED
					@ProcedureName = 'usp_EventAPI_UpdateErrorLog'
					,@ErrorNumber = 10
					,@ErrorMessage = @e OUTPUT
					-- OPTIONAL
					,@TransactionKey = 2
					,@SQLErrorCode = 1
					,@SQLErrorMsg = 'Error'

	DESCRIPTION:	Inserts record into dbo.ErrorLog

	NOTES:			

	DEPENDENCIES
	--------------------------------------------------------------------
	SQL SERVER 2005
	dbo.ErrorLog

	VERSIONS
	--------------------------------------------------------------------
	1	2008-10-15	Aarti	Initial

******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET @ErrorMessage = 'No Error'

INSERT
	dbo.ErrorLog
(
	[CreatedDateUTC] 
	,[CreatedBy] 
	,[ModifiedDateUTC]
	,[ModifiedBy]
	,[PK_TransactionKey]
	,[PK_ErrorCode]
	,[SQLErrorCode]
	,[SQLErrorMsg]
	,[Program]
)
SELECT
	GETUTCDATE()
	,@ProcedureName
	,GETUTCDATE()
	,@ProcedureName
	,@TransactionKey
	,@ErrorNumber
	,@SQLErrorCode
	,@SQLErrorMsg
	,@ProcedureName

SELECT @ErrorMessage = ErrorMsg FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = @ErrorNumber

/******************************************************************************
	end procedure
******************************************************************************/
END
GO

