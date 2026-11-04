
CREATE PROCEDURE [dbo].[usp_GrpTktsAPI_Get_Login]
	-- REQUIRED
	 @UserName				nVARCHAR(50)
	,@Password			    nVARCHAR(50)

	-- OUTPUT
	,@Error					INT				OUTPUT
	,@ErrorMessage			VARCHAR(200)	OUTPUT


AS
BEGIN

/******************************************************************************

	OBJECT:			dbo.usp_GrpTktsAPI_Get_Login

	USE:			EXEC usp_GrpTktsAPI_Get_Login
					-- REQUIRED
							@UserName		= 'PrabhuS'
							@Password	    = 'herbalife'
					-- OUTPUT
							,@Error			= @e	OUTPUT	/* @e must be defined in the local call */
							,@ErrorMessage	= @em	OUTPUT	/* @em must be defined in the local call */

DESCRIPTION:	Retrives a list of records from dbo.GroupTicketsUsers

	NOTES:			

	DEPNDENCIES
	--------------------------------------------------------------------
	dbo.GroupTicketsUsers

	SQL SERVER 2008
	VERSIONS
	--------------------------------------------------------------------
	1	2010-07-13	            PrabhuS	                    Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON


/******************************************************************************
                          VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure	VARCHAR(100)
DECLARE @StartTime			DATETIME
DECLARE @IsDevQA			BIT

SET @StoredProcedure		= 'usp_GrpTktsAPI_Get_Login'
SET @StartTime				= GETUTCDATE()
SET @IsDevQA				= 0
SET @Error					= 0
SET @ErrorMessage			= 'No Error.'


/******************************************************************************
	                  BE SURE THE QUERY RETURNS A VALUE
******************************************************************************/
IF NOT EXISTS( 
		SELECT		
					 GTU.[UserName]
					,GTU.[Password]
		FROM		
					[dbo].[GroupTicketsUsers] GTU WITH (NOLOCK)
		WHERE		
					GTU.[UserName]	= @UserName
				AND	GTU.[Password]	= @Password
	)
	
	BEGIN
		SET @Error				= 272

		-- UPDATE Error Log
		EXEC dbo.usp_Utility_UpdateErrorLog 
			 @ProcedureName		= @StoredProcedure 
			,@ErrorNumber		= @Error
			,@ErrorMessage		= @ErrorMessage OUTPUT
		RETURN 
	END


-- UPDATE Processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	 @StoredProcedureName	= @StoredProcedure
	,@StartTime				= @StartTime

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

