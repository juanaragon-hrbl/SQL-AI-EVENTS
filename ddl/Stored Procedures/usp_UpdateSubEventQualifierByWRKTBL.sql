CREATE PROCEDURE [dbo].[usp_UpdateSubEventQualifierByWRKTBL]
	 @Event NVARCHAR(MAX)
	 -- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_SAMCAMFSL_UpdateSubEventQualifierOct2017

USE:		EXEC dbo.usp_SAMCAMFSL_UpdateSubEventQualifierOct2017

DESCRIPTION:    Write Star Promotion Qualifiers to SubEventQualifier table in IA for Event ID given.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2010

VERSIONS
--------------------------------------------------------------------
1		2017-11-23	LehiD			Initial
1.1		2019-10-17	alejandramed	SRE Compliance 
******************************************************************************/
 
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

BEGIN TRY

		/******************************************************************************
			VARIABLE DECLARETION
		******************************************************************************/

		DECLARE @PK_Event INT
		IF OBJECT_ID('WRK_SubEventQualifier','U') IS NOT NULL DROP TABLE dbo.WRK_SubEventQualifier
		SELECT
			PK_Event,
			PK_Distributor,
			CONVERT(SMALLINT,RIGHT(SubEventName,2)) AS SubEventNumber,
			SubEventQual
		INTO dbo.WRK_SubEventQualifier 
		FROM
		(
		SELECT a.PK_Event, a.PK_Distributor, a.E01, a.E02, a.E03, a.E04, a.E05, a.E06, a.E07, a.E08, a.E09, a.E10, a.E11, a.E12, a.E13, a.E14, a.E15, a.E16, a.E17, a.E18, a.E19, a.E20, a.E21, a.E22, a.E23, a.E24, a.E25, a.E26, a.E27, a.E28, a.E29, a.E30, a.E31, a.E32, a.E33, a.E34, a.E35, a.E36, a.E37, a.E38, a.E39, a.E40, a.E41, a.E42, a.E43, a.E44, a.E45, a.E46, a.E47, a.E48, a.E49, a.E50
		FROM dbo.WRK_EventQual a WITH (NOLOCK)
		INNER JOIN dbo.udf_SplitString(@Event,',') b
		ON a.PK_Event = CAST(b.Val AS INT)
		) Main
		UNPIVOT
		(
		SubEventQual FOR SubEventName IN (E01,E02,E03,E04,E05,E06,E07,E08,E09,E10,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50)
		) AS unpvt
		WHERE SubEventQual = 1


		CREATE INDEX IX_WRK_SubEventQualifier_PK_Distributor ON dbo.WRK_SubEventQualifier(PK_Distributor)



			UPDATE
				SQ
			SET
				RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
				,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
				,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
			FROM
				dbo.udf_SplitString(@Event,',') EL
			INNER JOIN
				dbo.SubEvent SE WITH (NOLOCK)
			ON
				SE.PK_Event = CAST(EL.Val AS INT)
			INNER JOIN
				dbo.SubEventQualifier SQ WITH (NOLOCK)
			ON
				SE.PK_Event = SQ.PK_Event
				AND SE.PK_SubEvent = SQ.PK_SubEvent
				--AND SE.PK_Event IN (58571,58599,58598,58603,58604,58602,58600,58606,58605,58607,58608,58609,58613,58611,58610,58615,58614,58612)
				AND SQ.RemovedUTC = '2049-12-31'
				AND SQ.IsManualOverride != 1
			LEFT JOIN
				dbo.WRK_SubEventQualifier T WITH (NOLOCK)
			ON
				T.PK_Distributor = SQ.PK_Distributor 
		--		AND T.PK_Event IN (58571,58599,58598,58603,58604,58602,58600,58606,58605,58607,58608,58609,58613,58611,58610,58615,58614,58612)
				AND T.PK_Event = SE.PK_Event
				AND SE.SubEventNumber = T.SubEventNumber
				AND SQ.PK_SubEvent = SE.PK_SubEvent
				AND T.SubEventQual = 1
			LEFT JOIN
				dbo.EventsRegistration ER WITH (NOLOCK)
			ON
				ER.PK_Event = SE.PK_Event
				AND
				ER.PK_Distributor = T.PK_Distributor

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
				,SE.PK_Event
				,SE.PK_SubEvent
				,T.PK_Distributor
				,DS.sDistributorID
				,GETUTCDATE()
				,GETUTCDATE()
				,'2049-12-31'
				,0
				,0
				,0
				,0
				,1
				,NULL
			FROM
				dbo.udf_SplitString(@Event,',') EL
			INNER JOIN
				dbo.SubEvent SE WITH (NOLOCK)
			ON
				SE.PK_Event = CAST(EL.Val AS INT)
			INNER JOIN
				dbo.WRK_SubEventQualifier T WITH (NOLOCK)
				ON SE.PK_Event = T.PK_Event
				AND SE.SubEventNumber = T.SubEventNumber
		--		AND SE.PK_Event IN (58571,58599,58598,58603,58604,58602,58600,58606,58605,58607,58608,58609,58613,58611,58610,58615,58614,58612)
		--		AND T.PK_Event IN (58571,58599,58598,58603,58604,58602,58600,58606,58605,58607,58608,58609,58613,58611,58610,58615,58614,58612)
			INNER JOIN
				dbo.v_Distributor DS
			ON
				T.PK_Distributor = DS.nDistributorID
			LEFT JOIN
					dbo.SubEventQualifier SQ1 WITH (NOLOCK)
			ON
					SQ1.PK_Event = SE.PK_Event 
					AND SQ1.PK_SubEvent = SE.PK_SubEvent
					AND SQ1.RemovedUTC = '2049-12-31' 
					AND T.PK_Distributor = SQ1.PK_Distributor
			WHERE
				T.SubEventQual = 1
			AND
				SQ1.PK_Distributor IS NULL
		/******************************************************************************
			UPDATE EVENT QUALIFIER
		******************************************************************************/	

		DECLARE @Description AS nvarchar(400)
		DECLARE SubEventQualEngine CURSOR FOR SELECT CAST(Val AS INT) AS PK_Event FROM dbo.udf_SplitString(@Event,',')
		OPEN SubEventQualEngine
		FETCH NEXT FROM SubEventQualEngine INTO @PK_Event
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event
			FETCH NEXT FROM SubEventQualEngine INTO @Description
		END
		CLOSE SubEventQualEngine
		DEALLOCATE SubEventQualEngine

		/******************************************************************************
			END PROCEDURE
		******************************************************************************/	

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

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

