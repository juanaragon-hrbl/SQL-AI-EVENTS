CREATE PROCEDURE [dbo].[usp_RSMExtravaganza_UpdateSubEventQualifier]
	 @PK_InEvent INT
	 ,@TabName varchar(200)

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_RSMExtravaganza_UpdateSubEventQualifier

USE:			
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_RSMExtravaganza_UpdateSubEventQualifier
			@PK_InEvent = 0
			,@TabName = ''
			,@Error = @e OUTPUT
            ,@ErrorMessage = @em OUTPUT
            ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:   

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2015-06-30  OrlandoL  	Initial
2	2019-09-30	NoeG		SRE template applied
3	2019-10-30	NoeG		SRE Hardcode changed

******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'	

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/******************************************************************************
			VARIABLE DECLARETION
		******************************************************************************/
		DECLARE  @PK_SubEvent14 INT
				,@PK_SubEvent15 INT
				,@PK_SubEvent16 INT
				,@PK_SubEvent17 INT
				,@PK_SubEvent18 INT
				,@PK_SubEvent19 INT
				,@SQLStatement nVarchar(1000)


		/******************************************************************************
			SELECT PK_SubEvent for each subevent 
		******************************************************************************/
		IF @PK_InEvent = 2940
		BEGIN
			SELECT @PK_SubEvent14 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 11
			SELECT @PK_SubEvent15 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 12
		END
		ELSE
		BEGIN
			SELECT @PK_SubEvent14 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 14
			SELECT @PK_SubEvent15 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 15

			SELECT @PK_SubEvent16 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 16
			SELECT @PK_SubEvent17 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 17
			SELECT @PK_SubEvent18 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 18
			SELECT @PK_SubEvent19 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 19
		END

		--IF OBJECT_ID('WRK_RSMExtravaganza','U') IS NOT NULL DROP TABLE dbo.WRK_RSMExtravaganza

		--SET @SQLStatement = 'SELECT * INTO dbo.WRK_RSMExtravaganza FROM LS_SQL_BI_DB02.dbo.'+@TabName

		--IF OBJECT_ID('WRK_RSMExtravaganza','U') IS NOT NULL DROP TABLE dbo.WRK_RSMExtravaganza

		--EXEC sp_executesql @SQLStatement

		--CREATE INDEX IX_WRK_RSMExtravaganza_PK_Distributor ON dbo.WRK_RSMExtravaganza(PK_Distributor)
	
		/* IsE14Qualifier */
		UPDATE
			SQ
		SET
			 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
			,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
			,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
		FROM
			dbo.SubEventQualifier SQ (NOLOCK)
		LEFT JOIN
			dbo.WRK_RSMExtravaganza T (NOLOCK) 
		ON
			T.PK_Distributor = SQ.PK_Distributor 
			AND PK_Event = @PK_InEvent 
			AND PK_SubEvent = @PK_SubEvent14
			AND T.IsE14Qualifier = 1
		LEFT JOIN
			dbo.EventsRegistration ER (NOLOCK)
		ON
			ER.PK_Event = @PK_InEvent 
			AND
			ER.PK_Distributor = T.PK_Distributor
		WHERE
			SQ.PK_Event = @PK_InEvent
		AND
			SQ.PK_SubEvent = @PK_SubEvent14
	
		/* IsE15Qualifier */
		UPDATE
			SQ
		SET
			 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
			,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
			,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
		FROM
			dbo.SubEventQualifier SQ (NOLOCK)
		LEFT JOIN
			dbo.WRK_RSMExtravaganza T (NOLOCK) 
		ON
			T.PK_Distributor = SQ.PK_Distributor 
			AND PK_Event = @PK_InEvent 
			AND PK_SubEvent = @PK_SubEvent15
			AND T.IsE15Qualifier = 1
		LEFT JOIN
			dbo.EventsRegistration ER (NOLOCK)
		ON
			ER.PK_Event = @PK_InEvent 
			AND
			ER.PK_Distributor = T.PK_Distributor
		WHERE
			SQ.PK_Event = @PK_InEvent
		AND
			SQ.PK_SubEvent = @PK_SubEvent15
	
		IF @PK_InEvent != 2940
		BEGIN
			/* IsE16Qualifier */
			UPDATE
				SQ
			SET
				 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
				,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
				,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
			FROM
				dbo.SubEventQualifier SQ (NOLOCK)
			LEFT JOIN
				dbo.WRK_RSMExtravaganza T (NOLOCK) 
			ON
				T.PK_Distributor = SQ.PK_Distributor 
				AND PK_Event = @PK_InEvent 
				AND PK_SubEvent = @PK_SubEvent16
				AND T.IsE16Qualifier = 1
			LEFT JOIN
				dbo.EventsRegistration ER (NOLOCK)
			ON
				ER.PK_Event = @PK_InEvent 
				AND
				ER.PK_Distributor = T.PK_Distributor
			WHERE
				SQ.PK_Event = @PK_InEvent
			AND
				SQ.PK_SubEvent = @PK_SubEvent16
	
	
			/* IsE17Qualifier */
			UPDATE
				SQ
			SET
				 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
				,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
				,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
			FROM
				dbo.SubEventQualifier SQ (NOLOCK)
			LEFT JOIN
				dbo.WRK_RSMExtravaganza T (NOLOCK) 
			ON
				T.PK_Distributor = SQ.PK_Distributor 
				AND PK_Event = @PK_InEvent 
				AND PK_SubEvent = @PK_SubEvent17
				AND T.IsE17Qualifier = 1
			LEFT JOIN
				dbo.EventsRegistration ER (NOLOCK)
			ON
				ER.PK_Event = @PK_InEvent 
				AND
				ER.PK_Distributor = T.PK_Distributor
			WHERE
				SQ.PK_Event = @PK_InEvent
			AND
				SQ.PK_SubEvent = @PK_SubEvent17
	
			/* IsE18Qualifier */
			UPDATE
				SQ
			SET
				 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
				,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
				,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
			FROM
				dbo.SubEventQualifier SQ (NOLOCK)
			LEFT JOIN
				dbo.WRK_RSMExtravaganza T (NOLOCK) 
			ON
				T.PK_Distributor = SQ.PK_Distributor 
				AND PK_Event = @PK_InEvent 
				AND PK_SubEvent = @PK_SubEvent18
				AND T.IsE18Qualifier = 1
			LEFT JOIN
				dbo.EventsRegistration ER (NOLOCK)
			ON
				ER.PK_Event = @PK_InEvent 
				AND
				ER.PK_Distributor = T.PK_Distributor
			WHERE
				SQ.PK_Event = @PK_InEvent
			AND
				SQ.PK_SubEvent = @PK_SubEvent18


			/* IsE19Qualifier */
			UPDATE
				SQ
			SET
				 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
				,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
				,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
			FROM
				dbo.SubEventQualifier SQ (NOLOCK)
			LEFT JOIN
				dbo.WRK_RSMExtravaganza T (NOLOCK) 
			ON
				T.PK_Distributor = SQ.PK_Distributor 
				AND PK_Event = @PK_InEvent 
				AND PK_SubEvent = @PK_SubEvent19
				AND T.IsE19Qualifier = 1
			LEFT JOIN
				dbo.EventsRegistration ER (NOLOCK)
			ON
				ER.PK_Event = @PK_InEvent 
				AND
				ER.PK_Distributor = T.PK_Distributor
			WHERE
				SQ.PK_Event = @PK_InEvent
			AND
				SQ.PK_SubEvent = @PK_SubEvent19
		END	
	
	
		/*IsE14Qualifier*/
		INSERT
			dbo.SubEventQualifier
		(
			CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
			,PK_Event
			,PK_SubEvent
			,PK_Distributor
			,DistributorID
			,QualDate
			,AddedUTC
			,RemovedUTC
			,IsManualOverride
			,IsDeleted
			,IsDNR
			,IsType23
			,Qualified
			,Quantity
		)
		SELECT DISTINCT
			GETUTCDATE()
			,'UsrSQLProd'
			,GETUTCDATE()
			,'UsrSQLProd'
			,@PK_InEvent
			,@PK_SubEvent14
			,T.PK_Distributor
			,DS.sDistributorID
			,GETUTCDATE()
			,GETUTCDATE()
			,@ValidDate
			,0
			,0
			,0
			,0
			,1
			,NULL
		FROM
			dbo.WRK_RSMExtravaganza T (NOLOCK)
		INNER JOIN
			dbo.v_Distributor DS
		ON
			T.PK_Distributor = DS.nDistributorID
		LEFT JOIN
			 dbo.SubEventQualifier SQ1 (NOLOCK) 
		ON
			 SQ1.PK_Event = @PK_InEvent 
			 AND SQ1.PK_SubEvent = @PK_SubEvent14 
			 AND SQ1.RemovedUTC = @ValidDate 
			 AND T.PK_Distributor = SQ1.PK_Distributor
		WHERE
			T.IsE14Qualifier = 1
		AND
			SQ1.PK_Distributor IS NULL
	
		/*IsE15Qualifier*/
		INSERT
			dbo.SubEventQualifier
		(
			CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
			,PK_Event
			,PK_SubEvent
			,PK_Distributor
			,DistributorID
			,QualDate
			,AddedUTC
			,RemovedUTC
			,IsManualOverride
			,IsDeleted
			,IsDNR
			,IsType23
			,Qualified
			,Quantity
		)
		SELECT DISTINCT
			GETUTCDATE()
			,'UsrSQLProd'
			,GETUTCDATE()
			,'UsrSQLProd'
			,@PK_InEvent
			,@PK_SubEvent15
			,T.PK_Distributor
			,DS.sDistributorID
			,GETUTCDATE()
			,GETUTCDATE()
			,@ValidDate
			,0
			,0
			,0
			,0
			,1
			,NULL
		FROM
			dbo.WRK_RSMExtravaganza T (NOLOCK)
		INNER JOIN
			dbo.v_Distributor DS
		ON
			T.PK_Distributor = DS.nDistributorID
		LEFT JOIN
			 dbo.SubEventQualifier SQ1 (NOLOCK) 
		ON
			 SQ1.PK_Event = @PK_InEvent 
			 AND SQ1.PK_SubEvent = @PK_SubEvent15 
			 AND SQ1.RemovedUTC = @ValidDate 
			 AND T.PK_Distributor = SQ1.PK_Distributor
		WHERE
			T.IsE15Qualifier = 1
		AND
			SQ1.PK_Distributor IS NULL
	
		IF @PK_InEvent != 2940
		BEGIN
			/*IsE16Qualifier*/
			INSERT
				dbo.SubEventQualifier
			(
				CreatedDateUTC
				,CreatedBy
				,ModifiedDateUTC
				,ModifiedBy
				,PK_Event
				,PK_SubEvent
				,PK_Distributor
				,DistributorID
				,QualDate
				,AddedUTC
				,RemovedUTC
				,IsManualOverride
				,IsDeleted
				,IsDNR
				,IsType23
				,Qualified
				,Quantity
			)
			SELECT DISTINCT
				GETUTCDATE()
				,'UsrSQLProd'
				,GETUTCDATE()
				,'UsrSQLProd'
				,@PK_InEvent
				,@PK_SubEvent16
				,T.PK_Distributor
				,DS.sDistributorID
				,GETUTCDATE()
				,GETUTCDATE()
				,@ValidDate
				,0
				,0
				,0
				,0
				,1
				,NULL
			FROM
				dbo.WRK_RSMExtravaganza T (NOLOCK)
			INNER JOIN
				dbo.v_Distributor DS
			ON
				T.PK_Distributor = DS.nDistributorID
			LEFT JOIN
				 dbo.SubEventQualifier SQ1 (NOLOCK) 
			ON
				 SQ1.PK_Event = @PK_InEvent 
				 AND SQ1.PK_SubEvent = @PK_SubEvent16 
				 AND SQ1.RemovedUTC = @ValidDate 
				 AND T.PK_Distributor = SQ1.PK_Distributor
			WHERE
				T.IsE16Qualifier = 1
			AND
				SQ1.PK_Distributor IS NULL
	
	
			/*IsE17Qualifier*/
			INSERT
				dbo.SubEventQualifier
			(
				CreatedDateUTC
				,CreatedBy
				,ModifiedDateUTC
				,ModifiedBy
				,PK_Event
				,PK_SubEvent
				,PK_Distributor
				,DistributorID
				,QualDate
				,AddedUTC
				,RemovedUTC
				,IsManualOverride
				,IsDeleted
				,IsDNR
				,IsType23
				,Qualified
				,Quantity
			)
			SELECT DISTINCT
				GETUTCDATE()
				,'UsrSQLProd'
				,GETUTCDATE()
				,'UsrSQLProd'
				,@PK_InEvent
				,@PK_SubEvent17
				,T.PK_Distributor
				,DS.sDistributorID
				,GETUTCDATE()
				,GETUTCDATE()
				,@ValidDate
				,0
				,0
				,0
				,0
				,1
				,NULL
			FROM
				dbo.WRK_RSMExtravaganza T (NOLOCK)
			INNER JOIN
				dbo.v_Distributor DS
			ON
				T.PK_Distributor = DS.nDistributorID
			LEFT JOIN
				 dbo.SubEventQualifier SQ1 (NOLOCK) 
			ON
				 SQ1.PK_Event = @PK_InEvent 
				 AND SQ1.PK_SubEvent = @PK_SubEvent17 
				 AND SQ1.RemovedUTC = @ValidDate 
				 AND T.PK_Distributor = SQ1.PK_Distributor
			WHERE
				T.IsE17Qualifier = 1
			AND
				SQ1.PK_Distributor IS NULL
	
			/*IsE18Qualifier*/
			INSERT
				dbo.SubEventQualifier
			(
				CreatedDateUTC
				,CreatedBy
				,ModifiedDateUTC
				,ModifiedBy
				,PK_Event
				,PK_SubEvent
				,PK_Distributor
				,DistributorID
				,QualDate
				,AddedUTC
				,RemovedUTC
				,IsManualOverride
				,IsDeleted
				,IsDNR
				,IsType23
				,Qualified
				,Quantity
			)
			SELECT DISTINCT
				GETUTCDATE()
				,'UsrSQLProd'
				,GETUTCDATE()
				,'UsrSQLProd'
				,@PK_InEvent
				,@PK_SubEvent18
				,T.PK_Distributor
				,DS.sDistributorID
				,GETUTCDATE()
				,GETUTCDATE()
				,@ValidDate
				,0
				,0
				,0
				,0
				,1
				,NULL
			FROM
				dbo.WRK_RSMExtravaganza T (NOLOCK)
			INNER JOIN
				dbo.v_Distributor DS
			ON
				T.PK_Distributor = DS.nDistributorID
			LEFT JOIN
				 dbo.SubEventQualifier SQ1 (NOLOCK) 
			ON
				 SQ1.PK_Event = @PK_InEvent 
				 AND SQ1.PK_SubEvent = @PK_SubEvent18 
				 AND SQ1.RemovedUTC = @ValidDate 
				 AND T.PK_Distributor = SQ1.PK_Distributor
			WHERE
				T.IsE18Qualifier = 1
			AND
				SQ1.PK_Distributor IS NULL
	
			/*IsE19Qualifier*/
			INSERT
				dbo.SubEventQualifier
			(
				CreatedDateUTC
				,CreatedBy
				,ModifiedDateUTC
				,ModifiedBy
				,PK_Event
				,PK_SubEvent
				,PK_Distributor
				,DistributorID
				,QualDate
				,AddedUTC
				,RemovedUTC
				,IsManualOverride
				,IsDeleted
				,IsDNR
				,IsType23
				,Qualified
				,Quantity
			)
			SELECT DISTINCT
				GETUTCDATE()
				,'UsrSQLProd'
				,GETUTCDATE()
				,'UsrSQLProd'
				,@PK_InEvent
				,@PK_SubEvent19
				,T.PK_Distributor
				,DS.sDistributorID
				,GETUTCDATE()
				,GETUTCDATE()
				,@ValidDate
				,0
				,0
				,0
				,0
				,1
				,NULL
			FROM
				dbo.WRK_RSMExtravaganza T (NOLOCK)
			INNER JOIN
				dbo.v_Distributor DS
			ON
				T.PK_Distributor = DS.nDistributorID
			LEFT JOIN
				 dbo.SubEventQualifier SQ1 (NOLOCK) 
			ON
				 SQ1.PK_Event = @PK_InEvent 
				 AND SQ1.PK_SubEvent = @PK_SubEvent19
				 AND SQ1.RemovedUTC = @ValidDate 
				 AND T.PK_Distributor = SQ1.PK_Distributor
			WHERE
				T.IsE19Qualifier = 1
			AND
				SQ1.PK_Distributor IS NULL
		END
		/******************************************************************************
			UPDATE EVENT QUALIFIER
		******************************************************************************/	
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = @PK_InEvent

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

/******************************************************************************
	END PROCEDURE
******************************************************************************/	
END