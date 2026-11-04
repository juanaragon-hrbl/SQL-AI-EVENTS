CREATE PROCEDURE [dbo].[usp_AWT_upd_DistributorSet]
	@AWTYear int
	,@IsDevQA bit = 0

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_upd_DistributorSet

USE:			EXEC dbo.usp_AWT_upd_DistributorSet
					@AWTYear = 2011

DESCRIPTION:	update distributor set with AWT qualifiers

DEPENDENCIES
--------------------------------------------------------------------
VERSIONS
--------------------------------------------------------------------
1.1.0	2010-01-05	Scott	   Initial
1.2.0   2011-04-14  Prabhu     Changed to be residing on ETL instead of RPT
1.3.0   2012-06-15  IniU       Changed to EDW Distributor SET 
1.4.0   2012-10-12  IniU       Changed to DSLists Database
1.5.0	2019-10-11  puertac	   SRE Implementation 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @DistributorSet int
DECLARE @SetType int
DECLARE @SetTypeCode varchar(10)
DECLARE @DSSet int
DECLARE @SetName varchar(10)
DECLARE @CreatedBy varchar(30)
DECLARE @CreatedDate datetime
DECLARE @System int
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)

SET @SetTypeCode = 'AWT'
SET @SetName = 'AWT '+CONVERT(VARCHAR,@AWTYear)
SET @CreatedBy = 'AWT_upd_DistributorSet'
SET @CreatedDate = GETUTCDATE()
SET @System = 3

	BEGIN TRY
			/******************************************************************************
				get distributor set to update
			******************************************************************************/
			SELECT 
				@DistributorSet = DistributorSet
			FROM
				dbo.AWT_Definitions WITH (NOLOCK)
			WHERE
				AWTYear = @AWTYear

			/******************************************************************************
				if there is no distributor set end procedure
			******************************************************************************/
			IF @DistributorSet = 0 OR @DistributorSet IS NULL
			BEGIN
				RETURN
			END

			/******************************************************************************
				remove records from distributor set
			******************************************************************************/
			DELETE FROM
				DBLists.dbo.DSListDetail
			WHERE
				PK_DSList = @DistributorSet 

			/******************************************************************************
				add any record that don't exist in distributor set/members
			******************************************************************************/
			;WITH DSSet (PK_DSSet, PK_Distributor, Fromdate, ThroughDare, QualifiedDate, DelFlg, CreatedDate) AS
			(
				SELECT
					@DistributorSet
					,A.PK_Distributor
					,A.DateAdded
					,'2049-12-31'			
					,A.Qual_AWT
					,A.Flg1
					,A.CreatedDateUTC			
				FROM
					dbo.AWT_Qualifiers A WITH (NOLOCK)
				WHERE
					A.AWTYear = @AWTYear
			)

			INSERT INTO DBLists.dbo.DSListDetail
						(PK_DSList
						,PK_Distributor
						,DistributorID
						,ValidFromDateUTC
						,ValidThroughDateUTC
						,Date01
						,Date02
						,CreatedDateUTC
						,CreatedBy
						,ModifiedDateUTC
						,ModifiedBy)
			SELECT
						DS.PK_DSSet
						,DS.PK_Distributor
						,D.sDistributorID
						,DS.Fromdate
						,DS.ThroughDare
						,DS.QualifiedDate
						,NULL
						,CreatedDate
						,@CreatedBy
						,@CreatedDate
						,@CreatedBy
			FROM
				DSSet DS
			INNER JOIN
				dbo.v_Distributor D
			ON
				DS.PK_Distributor = D.nDistributorID  

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