CREATE PROCEDURE [dbo].[usp_UpdateSubEventQualifierWRKTBL]

		-- Error Parameters
		@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_UpdateSubEventQualifierWRKTBL

USE:			
			DECLARE @e int, @em varchar(4000)
			EXEC dbo.usp_UpdateSubEventQualifierWRKTBL
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:    Write Star Promotion Qualifiers to SubEventQualifier table in IA for Event ID given.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2010

VERSIONS
--------------------------------------------------------------------
1	2017-11-23	LehiD		Initial
2	2019-09-30	NoeG		SRE template applied
3	2019-10-30	NoeG		SRE Hardcode changed
******************************************************************************/
 
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/******************************************************************************
	VARIABLE DECLARETION
******************************************************************************/

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'
			,@UsrSQLProd nvarchar(20) = 'UsrSQLProd'

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		IF OBJECT_ID('WRK_SubEventQualifier','U') IS NOT NULL DROP TABLE dbo.WRK_SubEventQualifier
		SELECT
			PK_Event,
			PK_Distributor,
			CONVERT(SMALLINT,RIGHT(SubEventName,2)) AS SubEventNumber,
			SubEventQual
		INTO dbo.WRK_SubEventQualifier 
		FROM
		(
		SELECT PK_Event,PK_Distributor,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
		FROM dbo.WRK_EventQual (NOLOCK)
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
				dbo.SubEvent SE (NOLOCK)
				INNER JOIN
				dbo.SubEventQualifier SQ (NOLOCK)
			ON
				SE.PK_Event = SQ.PK_Event
				AND SE.PK_SubEvent = SQ.PK_SubEvent
				AND SE.PK_Event IN (58571,58599,58598,58603,58604,58602,58600,58606,58605,58607,58608,58609,58613,58611,58610,58615,58614,58612)
				AND SQ.RemovedUTC = @ValidDate
				AND SQ.IsManualOverride != 1
			LEFT JOIN
				dbo.WRK_SubEventQualifier T 
			ON
				T.PK_Distributor = SQ.PK_Distributor 
				AND T.PK_Event IN (58571,58599,58598,58603,58604,58602,58600,58606,58605,58607,58608,58609,58613,58611,58610,58615,58614,58612)
				AND T.PK_Event = SE.PK_Event
				AND SE.SubEventNumber = T.SubEventNumber
				AND SQ.PK_SubEvent = SE.PK_SubEvent
				AND T.SubEventQual = 1
			LEFT JOIN
				dbo.EventsRegistration ER (NOLOCK)
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
				,@UsrSQLProd
				,GETUTCDATE()
				,@UsrSQLProd
				,SE.PK_Event
				,SE.PK_SubEvent
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
			FROM dbo.SubEvent SE (NOLOCK)
			INNER JOIN
				dbo.WRK_SubEventQualifier T (NOLOCK)
				ON SE.PK_Event = T.PK_Event
				AND SE.SubEventNumber = T.SubEventNumber
				AND SE.PK_Event IN (58571,58599,58598,58603,58604,58602,58600,58606,58605,58607,58608,58609,58613,58611,58610,58615,58614,58612)
				AND T.PK_Event IN (58571,58599,58598,58603,58604,58602,58600,58606,58605,58607,58608,58609,58613,58611,58610,58615,58614,58612)
			INNER JOIN
				dbo.v_Distributor DS
			ON
				T.PK_Distributor = DS.nDistributorID
			LEFT JOIN
					dbo.SubEventQualifier SQ1 (NOLOCK) 
			ON
					SQ1.PK_Event = SE.PK_Event 
					AND SQ1.PK_SubEvent = SE.PK_SubEvent
					AND SQ1.RemovedUTC = @ValidDate
					AND T.PK_Distributor = SQ1.PK_Distributor
			WHERE
				T.SubEventQual = 1
			AND
				SQ1.PK_Distributor IS NULL
		/******************************************************************************
			UPDATE EVENT QUALIFIER
		******************************************************************************/	
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58571
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58599
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58598
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58603
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58604
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58602
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58600
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58606
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58605
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58607
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58608
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58609
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58613
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58611
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58610
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58615
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58614
		EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = 58612

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