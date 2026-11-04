CREATE PROCEDURE [dbo].[usp_AWT_Qualifiers_Tracking]
	@AWTYear int
	,@IsDevQA bit = 0

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_Qualifiers_Tracking

USE:			EXEC dbo.usp_AWT_Qualifiers_Tracking
					@AWTYear = 2013
					,@IsDevQA = 1

DESCRIPTION:	Does a merge to flag the months a member has made AWT qualification for an AWT Year

DEPENDENCIES
--------------------------------------------------------------------
AWT Run

VERSIONS
--------------------------------------------------------------------
	1.0.0	2014-01-10	Ini		  Initial
	1.1.0	2019-10-11  puertac	  SRE Implementation

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
			/******************************************************************************
			Insert AWT qualifiers.
			******************************************************************************/

			DECLARE @LoopTime INT = 0
			DECLARE @RoyaltyLoop datetime

			INSERT INTO dbo.AWT_Qualifiers_Tracking (
				AWTYear
				,PK_Distributor
				,DistributorID
				,COP
				)
			SELECT
				@AWTYear 
				,AWT.PK_Distributor 
				,AWT.DistributorID 
				,DS.sDistributorCountryProcessingCode AS COP
			FROM
				dbo.AWT_Qualifiers AWT WITH (NOLOCK)
			INNER JOIN
				dbo.v_Distributor DS 
			ON
				AWT.PK_Distributor = DS.nDistributorID 
			LEFT JOIN
				dbo.AWT_Qualifiers_Tracking ATR WITH (NOLOCK) 
			ON
				AWT.AWTYear = @AWTYear 
				AND
				AWT.AWTYear = ATR.AWTYear
				AND	
				AWT.PK_Distributor = ATR.PK_Distributor
			WHERE
				AWT.AWTYear = @AWTYear 
				AND
				ATR.PK_Distributor IS NULL
	
			/******************************************************************************
			Update the month the made AWT. Supposedly first time in that AWT Circle
			******************************************************************************/

			UPDATE
				ATR 
			SET 
				Jan = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 1 THEN 1 ELSE Jan END
				,Feb = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 2 THEN 1 ELSE Feb END
				,Mar = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 3 THEN 1 ELSE Mar END	
				,Apr = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 4 THEN 1 ELSE Apr END 
				,May = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 5 THEN 1 ELSE May END
				,Jun = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 6 THEN 1 ELSE Jun END
				,Jul = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 7 THEN 1 ELSE Jul END
				,Aug = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 8 THEN 1 ELSE Aug END
				,Sep = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 9 THEN 1 ELSE Sep END
				,Oct = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 10 THEN 1 ELSE Oct END
				,Nov = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 11 THEN 1 ELSE Nov END
				,Dec = CASE WHEN DATEPART(MM,AWT.Qual_AWT) = 12 THEN 1 ELSE Dec END
			FROM
				dbo.AWT_Qualifiers_Tracking ATR (NOLOCK)
			INNER JOIN
				dbo.AWT_Qualifiers AWT (NOLOCK)
			ON
				ATR.AWTYear = AWT.AWTYear 
				AND
				ATR.AWTYear = @AWTYear 
				AND
				ATR.PK_Distributor = AWT.PK_Distributor 
	
			/******************************************************************************
				Update for repeat AWT months
			******************************************************************************/
			SET @LoopTime = 1
			WHILE @LoopTime <= 12
			BEGIN
			SET @RoyaltyLoop = CONVERT(DATETIME,CONVERT(VARCHAR(4),@AWTYear) + CASE WHEN LEN(@LoopTime) = 1 THEN '-0'+CONVERT(VARCHAR(1),@LoopTime) ELSE '-'+CONVERT(VARCHAR(2),@LoopTime) END + '-01',120)

			;WITH 
				DidAWT (PK_Distributor,RoyaltyMonth) AS
				(
					/* Get the months members did AWT */
					SELECT
						PK_Distributor
						,RoyaltyMonth
					FROM
						dbo.AWT_Metrics WITH (NOLOCK)
					WHERE
						AWTYear = @AWTYear
						AND
						didAWT = 1
						AND
						RoyaltyMonth = @RoyaltyLoop
				)
			UPDATE
				AWT 
			SET
				Jan = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 1 AND Jan <> 1 THEN 1 ELSE Jan END
				,Feb = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 2 AND Feb <> 1 THEN 1 ELSE Feb END
				,Mar = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 3 AND Mar <> 1 THEN 1 ELSE Mar END
				,Apr = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 4 AND Apr <> 1 THEN 1 ELSE Apr END
				,May = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 5 AND May <> 1 THEN 1 ELSE May END
				,Jun = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 6 AND Jun <> 1 THEN 1 ELSE Jun END
				,Jul = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 7 AND Jul <> 1 THEN 1 ELSE Jul END
				,Aug = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 8 AND Aug <> 1 THEN 1 ELSE Aug END
				,Sep = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 9 AND Sep <> 1 THEN 1 ELSE Sep END
				,Oct = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 10 AND Oct <> 1 THEN 1 ELSE Oct END
				,Nov = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 11 AND Nov <> 1 THEN 1 ELSE Nov END
				,Dec = CASE WHEN DATEPART(MM,YAWT.RoyaltyMonth) = 12 AND Dec <> 1 THEN 1 ELSE Dec END
				,ModifiedDateUTC = GETUTCDATE()
			FROM
				dbo.AWT_Qualifiers_Tracking AWT (NOLOCK)
			INNER JOIN
				DidAWT YAWT
			ON
				AWT.AWTYear = @AWTYear
				AND
				AWT.PK_Distributor = YAWT.PK_Distributor
	
			SET @LoopTime += 1

			END		
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