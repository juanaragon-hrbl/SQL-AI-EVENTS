CREATE PROCEDURE [dbo].[usp_EventAPI_Get_LocalQualifications]
	-- Required
	@DistributorID varchar(10) = null
	,@PK_Event int = NULL
	,@PK_SubEvent int = NULL

	-- Error
	,@Error				int OUTPUT 
	,@ErrorMessage		nvarchar(200) OUTPUT
	
	-- QA/DEV
	,@IsDevQA			bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			dbo.usp_EventAPI_Get_LocalQualifications
	
	USE:			
			DECLARE		@e int, @em varchar(max)

			EXEC usp_EventAPI_Get_LocalQualifications
					@DistributorID = NULL
					--,@PK_Event = 
					,@PK_SubEvent = NULL
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
			
			SELECT @e, @em

	DESCRIPTION:	Get qualified distributors from [LocalSubEventQualifier]

	NOTES:

	DEPENDENCIES (PROD)
	--------------------------------------------------------------------
	[dbo].[LocalSubEventQualifier]

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-12-06		RogelioR		Initial
	
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	SET ANSI_NULLS ON
	SET ANSI_PADDING ON

	DECLARE @StoredProcedure varchar(255) = 'usp_EventAPI_Get_LocalQualifications';

	BEGIN TRY;
		SELECT @Error = 0, @ErrorMessage = 'No Error';
		
		SELECT DISTINCT
				q.[DistributorID]
				,q.[QualificationTime]
				,q.[TimeZone]
				,q.[Notes]
				,d.[sFirstName] AS [FirstName]
				,d.[sLastName] AS [LastName]
				,d.[sSubTeam] AS [TeamLevel]
				,d.[sDistributorCountryProcessingCode] AS [COP]
				,d.[sDistributorCountryResidenceCode] AS [COR]
			FROM [dbo].[LocalSubEventQualifier] AS q WITH (NOLOCK)
				INNER JOIN [v_Distributor] AS d ON d.[sDistributorID] = q.[DistributorID]
			WHERE (@PK_Event IS NULL OR q.[PK_Event] = @PK_Event)
				AND (@DistributorID IS NULL OR q.[DistributorID] = @DistributorID)
				AND (@PK_SubEvent IS NULL OR q.[PK_SubEvent] = @PK_SubEvent)
				
	END TRY
	BEGIN CATCH
		SELECT 
				@Error = ERROR_NUMBER()
				,@ErrorMessage = ERROR_MESSAGE()
				,@StoredProcedure = ERROR_PROCEDURE();

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage;
	END CATCH;
END;