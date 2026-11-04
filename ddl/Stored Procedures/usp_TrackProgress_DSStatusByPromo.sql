
CREATE PROCEDURE [dbo].[usp_TrackProgress_DSStatusByPromo]
		@PK_Event int
		,@DistributorID varchar(30)

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_TrackProgress_DSStatusByPromo]
	
	USE:			
			DECLARE @e int, @em varchar(4000)
			
			EXEC [dbo].[usp_TrackProgress_DSStatusByPromo]
				@PK_Event = 72107
				,@DistributorID = '2222222222'
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
	1.0.0		2018-10-02		RogelioR		Initial
	2.0.0		2019-09-30		NoeG			SRE template applied
	
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		WITH c AS (
			SELECT @DistributorID AS [DistributorID]
		)
		,d AS (
			SELECT
					w.[SponsorID], COUNT(*) AS [Downline]
				FROM [dbo].[WRK_NAMMAP2018] AS w (NOLOCK)
					LEFT JOIN [dbo].[v_dimDSLngDownline] AS d ON d.[PK_Distributor] = w.[PK_Distributor]
				WHERE w.[SponsorID] = @DistributorID
				GROUP BY w.[SponsorID]
		)
		SELECT 
				@PK_Event AS [PK_Event]
				,c.[DistributorID]
				,CASE WHEN w.[DistributorID] IS NOT NULL THEN 1 ELSE 0 END AS [IsEligible]
				,CASE WHEN ISNULL(w.[QualifiedPeriod], 0) > 0 THEN 1 ELSE 0 END AS [IsQualified]
				,CASE WHEN (SELECT [Downline] FROM d) > 1 THEN 1 ELSE 0 END AS [HasDownline]
				,0 AS [IsRewardClaimed]
			FROM c
				LEFT JOIN dbo.WRK_NAMMAP2018 AS w (NOLOCK) ON w.[DistributorID] = c.[DistributorID]
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
END;