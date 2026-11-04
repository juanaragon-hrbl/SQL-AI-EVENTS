CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_DSTeamTypeCached]
				  -- Optional Parameters
				  @LocaleCode  VARCHAR(10) = NULL
				-- Error Parameters
				,@Error int = 0 OUTPUT
				,@ErrorMessage varchar(4000) = '' OUTPUT

				-- QA/DEV
				,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.[usp_MyHLEventAPI_Get_DSTeamTypeCached]

USE:	        
				DECLARE @e int, @em varchar(4000)
                 EXEC [usp_MyHLEventAPI_Get_DSTeamTypeCached]
					  @LocaleCode = NULL
					 ,@Error = @e OUTPUT  /* @e must be defined in the local call */
					 ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Get the Team Levels for display in drop down when DS ID is passed and also when DS ID is not passed

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.DSTeamType, dbo.DSTeamTypeLocaleDesc

VERSIONS
--------------------------------------------------------------------
1.0		2014-11-03				SushmaA				Cache implementation for Search CR
2.0		2019-08-14				NoeG				Refactor code (SRE)

********************************************************************************************/

/* VARIABLE DECLARATION */
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_Locale INT
DECLARE @SubTypeCode VARCHAR(5)
DECLARE @PK_Order INT
DECLARE @PK_DefaultLocale INT
		
SELECT @Error = 0, @ErrorMessage = '';

SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = 'en-US'

	BEGIN TRY

		IF @LocaleCode IS NOT NULL
		BEGIN
			SELECT
				DT.DSTeamTypeCode
			   ,COALESCE(DLT.DSTeamTypeDesc, DLD.DSTeamTypeDesc) DSTeamTypeDesc
			   ,@PK_Locale PK_Locale
			   ,@LocaleCode LocaleCode
			   ,TeamOrder
			FROM 
				dbo.DSTeamType DT WITH(NOLOCK)
			LEFT JOIN
				dbo.DSTeamTypeLocaleDesc DLT WITH(NOLOCK)
			ON
				DT.DSTeamTypeCode = DLT.DSTeamTypeCode	
			AND
				DLT.PK_Locale = @PK_Locale--passed on Locale
			LEFT JOIN
				dbo.DSTeamTypeLocaleDesc DLD WITH(NOLOCK)
			ON
				DT.DSTeamTypeCode = DLD.DSTeamTypeCode	
			AND
				DLD.PK_Locale = 77 -- DEFAULT
			ORDER BY 
				DT.TeamOrder
		END
		ELSE
		BEGIN 
	
			IF OBJECT_ID('tempDB..#TeamTypes','U') IS NOT NULL
   			DROP TABLE #TeamTypes
	
			SELECT 
				 A.DSTeamTypeCode
				,A.DSTeamTypeDesc
				,A.PK_Locale
				,A.LocaleCode
				,A.TeamOrder
			INTO #TeamTypes
			FROM
			(
				SELECT
					DT.DSTeamTypeCode
				   ,DLT.DSTeamTypeDesc
				   ,L.PK_Locale
				   ,L.LocaleCode
				   ,TeamOrder
				FROM 
					dbo.DSTeamType DT WITH(NOLOCK)
				INNER JOIN
					dbo.DSTeamTypeLocaleDesc DLT WITH(NOLOCK)
				ON
					DT.DSTeamTypeCode = DLT.DSTeamTypeCode
				AND
					DLT.PK_Locale = 77
				CROSS JOIN
					dbo.Locales L WITH(NOLOCK)		
			) A
	
			update DT SET DT.DSTeamTypeDesc = DLT.DSTeamTypeDesc	
			FROM
				#TeamTypes DT
			INNER JOIN
				dbo.DSTeamTypeLocaleDesc DLT WITH(NOLOCK)
			ON
				DT.DSTeamTypeCode = DLT.DSTeamTypeCode	
			AND
				DLT.PK_Locale = DT.PK_Locale--passed on Locale
		
			SELECT 
				 A.DSTeamTypeCode
				,A.DSTeamTypeDesc
				,A.PK_Locale
				,A.LocaleCode
				,A.TeamOrder
			FROM 
				#TeamTypes	A

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
	END CATCH

/* END PROCEDURE */

END
GO

