CREATE PROCEDURE [dbo].[usp_NAM_DV_Promo_Details] 
	@DistributorID VARCHAR(20) ,
	@Page INT = 1 , 
	@CountRow INT = 50,
	@RowCount INT OUTPUT
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_NAM_DV_Promo_Details

USE:	 
			DECLARE @e int, @em varchar(4000)
			declare @IsDevQA int 
			declare @r int      
	EXEC usp_NAM_DV_Promo_Details  '10Y0350974'  ,1 ,50 ,@r output ,@e output , @em output, 1

	select @r, @e AS [Error], @em AS [Error Message]

DESCRIPTION:	This is a custom stored procedure that retreievs all the downline details for the 
                NAM Documented Volume Promo Mini Ipad

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.agg_NAM_DV_Promo 

VERSIONS
----------------------------------------------------------------------------------
1	2017-02-13	Juan	Intitial
3   2017-02-23  Juan	inluded myDV column
4   2017-02-24  Juan	Redesing of table
5   2017-02-24  Juan	New Colum Status, indicate if MB is in progress of qualifying  1= In Progress & 0 = Disqualified
6   2017-03-07  Juan	PCM will show on DL Progress

******************************************************************************/
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		IF OBJECT_ID('tempdb..#agg_NAM_DV_Promo','U') IS NOT NULL DROP TABLE #agg_NAM_DV_Promo
		CREATE TABLE #agg_NAM_DV_Promo
		(	
			RoyaltyMonth DATE ,
			DistributorID VARCHAR(20),
			DownlineID VARCHAR(20),
			DL_COP CHAR(2),
			DLTypeCode CHAR(3),
			SponsorID VARCHAR(20),
			SPLevel INT,
			TV money DEFAULT 0,
			DV money DEFAULT 0,
			DL_DVPerc money DEFAULT 0,
			UL_DVPerc AS (ISNULL(DV,0) / ISNULL(NULLIF(TV,0),1)),
			Receipts INT DEFAULT 0,
			IsQualified INT DEFAULT 0,
			QualifiedMonths INT DEFAULt 0,
			HasDownlineSP BIT DEFAULT 0,
		)

		CREATE INDEX IX_agg_NAM_DV_Promo_PK_Distributor ON #agg_NAM_DV_Promo (DownlineID,RoyaltyMonth) INCLUDE (SPLevel,DL_COP,DLTypeCode)

		INSERT INTO #agg_NAM_DV_Promo 
		(	RoyaltyMonth,
			DistributorID,
			DownlineID ,
			DL_COP,
			DLTypeCode,
			SponsorID,
			SPLevel ,
			TV,
			DV,
			DL_DVPerc,
			Receipts ,
			IsQualified ,
			QualifiedMonths,
			HasDownlineSP)
		SELECT
			RoyaltyMonth,
			DistributorID,
			DownlineID ,
			DL_COP,
			DLTypeCode,
			SponsorID,
			SPLevel ,
			TV,
			DV * 100 AS DV,
			DVPerc  * 100 AS DVPerc,
			Receipts ,
			CASE WHEN DLTypeCode = 'PCM' THEN 0 ELSE IsQualified END,
			SUM(IsQualified) OVER (Partition By RoyaltyMonth,DownlineID) QualifiedMonths,
			HasDownlineSP
		FROM 
			dbo.agg_NAM_DV_Promo WITH (NOLOCK) -- QA & PROD
		WHERE 
			distributorID = @DistributorID
			AND 
			DownlineID <> DistributorID 
			AND
			DL_COP IN ('US','PR')
			AND
			RoyaltyMonth  >= '2017-03-01' -- Promotion Starts in March

		IF OBJECT_ID('tempdb..#Downline','U') IS NOT NULL DROP TABLE #Downline
		CREATE TABLE #Downline 
		(
			PK INT IDENTITY (1,1) PRIMARY Key,
			SPLevel INT,
			ID VARCHAR(20),
			Name VARCHAR (200),
			DLTypeCode CHAR(3),
			[Status] INT,
			HasDL BIT,
			HasReceipt VARCHAR(3),
			TV money,
			UL_DVPerc money,
			DL_DVPerc money,
			Email VARCHAR(100),
			Phone VARCHAR(50),
			SponsorName VARCHAR (200)
		)

		DECLARE @DisplayDate DATE = DATEADD(d,-1,GETDATE()) --On 1st day of Month, still display previous month

		IF @DisplayDate >= '2017-05-01' 
		SET @DisplayDate = '2017-04-01'

		INSERT INTO #Downline (SpLevel,ID,Name,DLTypeCode,[Status],HasDL,HasReceipt,TV,UL_DVPerc,DL_DVPerc,Email,Phone,SponsorName)
		SELECT
			SPLevel -1 AS SPLevel,
			DownlineID,
			ds1.sFirstName + ' ' + ds1.sLastName,
			DLTypeCode,
			CASE WHEN IsQualified = -1 THEN 1 ELSE IsQualified END,
			HasDownlineSP,
			CASE WHEN Receipts > 0 THEN 1 ELSE 0 END AS HasReceipt,
			TV,
			UL_DVPerc,
			DL_DVPerc,
			ds1.sEmail,
			ds1.Phone,
			ds2.sFirstName + ' ' + ds2.sLastName
		FROM
			#agg_NAM_DV_Promo P
		INNER JOIN
			v_Distributor DS1
		ON
			P.DownlineID = DS1.sDistributorID
		LEFT JOIN
			v_Distributor  DS2
		ON
			ds2.sDistributorID = P.SponsorID
		WHERE
			MONTH(RoyaltyMonth) = MONTH(@DisplayDate) 
		ORDER BY
			SPLevel

		SET @RowCount = @@ROWCOUNT

		/**********
		Determine status of Previous Month to determine if MB in progress or disqualified
		********/

		UPDATE D
			SET [Status] = 0
		FROM
			#Downline D
		INNER JOIN
			#agg_NAM_DV_Promo A
		ON
			A.DownlineID = D.ID
		WHERE
			MONTH(A.RoyaltyMonth) = MONTH(@DisplayDate) - 1
			AND
			A.IsQualified = 0


		DECLARE @MaxNum INT , @MinNum INT 

		SET @MaxNum = @Page * @CountRow
		SET @MinNum = @MaxNum - @CountRow


		SELECT 
		*		
		FROM
			#Downline
		WHERE
			PK > @MinNum AND PK <= @MaxNum

		ORDER BY PK

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
END
GO

