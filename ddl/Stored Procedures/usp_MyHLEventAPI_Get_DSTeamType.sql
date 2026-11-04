CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_DSTeamType]
	-- Optional Parameters
	@LocaleCode  VARCHAR(10) = 'en-US'
	,@DistributorID VARCHAR(10) = NULL

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_DSTeamType

USE:	        
				DECLARE @e int, @em varchar(4000)
                 EXEC usp_MyHLEventAPI_Get_DSTeamType
					  @LocaleCode = 'bg-BG'
					 ,@DistributorID = '2222222222'
					 ,@Error = @e OUTPUT  /* @e must be defined in the local call */
					 ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Get the Team Levels for display in drop down when DS ID is passed and also when DS ID is not passed

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.GuestSpeakers

VERSIONS (PROD)
--------------------------------------------------------------------
1.0		2011-01-28		PrabhuS			Intitial
1.1		2017-09-05		RogelioR		Exclude Preferred Member Promotions teams
1.2		2019-08-14		NoeG			Refactor code (SRE)
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

IF @DistributorID IS NULL

BEGIN

	BEGIN TRY 

		SELECT
			DT.DSTeamTypeCode
		   ,COALESCE(DLT.DSTeamTypeDesc, DLT1.DSTeamTypeDesc) DSTeamTypeDesc
		FROM 
			dbo.DSTeamType DT  WITH(NOLOCK) 
		LEFT JOIN
			dbo.DSTeamTypeLocaleDesc DLT  WITH(NOLOCK) 
		ON
			DT.DSTeamTypeCode = DLT.DSTeamTypeCode
			AND
			DLT.PK_Locale = CASE WHEN @PK_Locale IS NULL THEN @PK_DefaultLocale ELSE @PK_Locale END
		LEFT JOIN
			dbo.DSTeamTypeLocaleDesc DLT1  WITH(NOLOCK) 
		ON
			DT.DSTeamTypeCode = DLT1.DSTeamTypeCode
			AND
			DLT1.PK_Locale = @PK_DefaultLocale
		WHERE 
			DT.DSTeamTypeCode NOT IN ('BCM', 'SCM', 'GCM', 'PCM')	-- Do not include the codes for Preferred Member Promotions

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

ELSE
BEGIN
	BEGIN TRY

		SELECT
			@SubTypeCode = S.SubTypeCode
		FROM
			PubEvents.dbo.dimDistributor D WITH(NOLOCK)
		INNER JOIN
			PubEvents.dbo.dimDSSubType S WITH(NOLOCK)
		ON
			D.PK_DSSubType = S.PK_DSSubType
		WHERE
			D.DistributorID = @DistributorID

		SELECT @PK_Order = TeamOrder FROM dbo.DSTeamType  WITH(NOLOCK) WHERE DSTeamTypeCode = @SubTypeCode

		SELECT
			DT.DSTeamTypeCode
			,COALESCE(DLT.DSTeamTypeDesc,DLT1.DSTeamTypeDesc,'')DSTeamTypeDesc
		FROM 
			dbo.DSTeamType DT  WITH(NOLOCK) 
		LEFT JOIN
			dbo.DSTeamTypeLocaleDesc DLT  WITH(NOLOCK) 
		ON
			DT.DSTeamTypeCode = DLT.DSTeamTypeCode
			AND
			DLT.PK_Locale = @PK_Locale
		LEFT JOIN
			dbo.DSTeamTypeLocaleDesc DLT1  WITH(NOLOCK) 
		ON
			DT.DSTeamTypeCode = DLT1.DSTeamTypeCode
			AND
			DLT1.PK_Locale = @PK_DefaultLocale
		WHERE
			DT.TeamOrder >= @PK_Order
			AND
			DT.DSTeamTypeCode NOT IN ('BCM', 'SCM', 'GCM', 'PCM')	-- Do not include the codes for Preferred Member Promotions

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

/* END PROCEDURE */

END
GO

