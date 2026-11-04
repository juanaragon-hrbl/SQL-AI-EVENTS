CREATE PROCEDURE [dbo].[usp_GDPR_Validate_PubEventPubData]
	 
	-- Error Parameters
	@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN

-- =======================================================================================
-- Author		Jair Lira Garcia
-- Create date  Oct2021
-- Description	Verify and Validate PUBEVENT/PUBDATA Distributor Data being anonymized
-- Parameters :  @Error  OUT Error number
--               @ErrorMessage OUT Error message
--              QA/DEV
--       	     @IsDevQA SMALLINT = 0 
--------------------------------------------------------------------
--    VERSIONS
--------------------------------------------------------------------
--    1.0.0       2022-02-28     Jair Lira        Initial. 
--    1.1.0       2022-04-27     Jair Lira        Date was added 
--    1.2.0       2022-08-30     Jair Lira        Verify masking on PubEventManagement tables 
-- ========================================================================================
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StartTime DATETIME = GETUTCDATE()
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)

BEGIN TRY

	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END

/******************************************************************************
	GET PII DISTRIBUTORS ANONIMYZED 1 MONTH BEFORE
******************************************************************************/

DECLARE @Pk_Distributor NVARCHAR(MAX), @DistributorId NVARCHAR(MAX)
DECLARE @dimDistributor table([Pk_Distributor] int, [DistributorId] NVARCHAR(30));

INSERT INTO @dimDistributor SELECT Pk_Distributor, DistributorId FROM [dbo].[GDPRDistributors] WITH (NOLOCK) 
							WHERE StatusCode = 1 AND (CONVERT(varchar(8),CreatedDateUTC,112) >= CONVERT(varchar(8),DATEADD(MONTH, -1, GETUTCDATE()),112) 
							OR CONVERT(varchar(8),ModifiedDateUTC,112) >= CONVERT(varchar(8),DATEADD(MONTH, -1, GETUTCDATE()),112))
							UNION
							SELECT  Pk_Distributor, DistributorId FROM [dbo].[GDPREmailNotes] WITH (NOLOCK) 
							WHERE DistributorStatus = 1

IF EXISTS (SELECT 1 FROM @dimDistributor)
BEGIN

	IF OBJECT_ID('Tempdb..#TempPIIColumns','U') IS NOT NULL DROP TABLE #TempPIIColumns
	CREATE TABLE #TempPIIColumns (
	PK_Distributor INT, 
	DistributorId NVARCHAR(30),
	TableName nvarchar(200),
	GDPRColumns nvarchar(4000))

	IF OBJECT_ID('Tempdb..#PIIColumns','U') IS NOT NULL DROP TABLE #PIIColumns
	CREATE TABLE #PIIColumns (
	PK_Distributor INT, 
	DistributorId NVARCHAR(30),
	TableName nvarchar(200),
	GDPRColumns nvarchar(4000))

	DECLARE @DatabaseName NVARCHAR(100), @SchemaName NVARCHAR(100), @TableName NVARCHAR(100), @ConditionId NVARCHAR(MAX), @Id Int;
	DECLARE @SQL NVARCHAR(MAX);


/******************************************************************************
	Verify Distributor anonymization on PUBEVENTMANAGEMENT DB
******************************************************************************/

	SELECT @Pk_Distributor = MIN(Pk_Distributor) FROM @dimDistributor

	WHILE @Pk_Distributor IS NOT NULL
	BEGIN

		SELECT @DistributorId = DistributorId FROM @dimDistributor WHERE Pk_Distributor = @Pk_Distributor				

		SELECT @Id = MIN(Id) FROM[dbo].[GDPRTables] WITH (NOLOCK) WHERE Active = 1

		   WHILE @Id IS NOT NULL
		   BEGIN
				SELECT	@DatabaseName = DatabaseName, 
						@SchemaName = SchemaName, 
						@TableName = TableName, 
						@ConditionId = ConditionId
				FROM  [dbo].[GDPRTables] WITH (NOLOCK) 
				WHERE Id = @Id

			    SET  @SQL = 'INSERT INTO #TempPIIColumns([PK_Distributor], [DistributorId], [TableName], [GDPRColumns]) '
				SET @SQL = @SQL + 'SELECT ' + @Pk_Distributor + ',' + '''' + @DistributorId + '''' + ',' + '''' +  @DatabaseName  + '.'  +  @SchemaName  + '.'  +  @TableName + ''''   + ','
				SET @SQL =  @SQL + STUFF((SELECT  '+''|''+ ' + IIF(GDE.ColumnName in ('DOB' ,'DateOfMarriage','IdentityCardDate'),  'CONVERT(VARCHAR(10),' +  GDC.ColumnName  + ',120)' , 'CONVERT(VARCHAR,[' +  GDC.ColumnName + '])' ) + ''
				FROM  [dbo].[GDPRColumns] GDC
				INNER JOIN [dbo].[GDPRDataElements] GDE ON GDC.GDPRColumnId = GDE.Id
				WHERE GDPRTableId = @Id
				FOR XML PATH('')), 1,1, '')

				SET  @ConditionId = REPLACE(@ConditionId, '@Pk_Distributor', '''' +  CAST(@Pk_Distributor AS varchar)  + '''');				
				SET  @ConditionId = REPLACE(@ConditionId, '@DistributorId', '''' +  CAST(@DistributorId AS varchar)  + '''');

				SET @SQL = @SQL + 'FROM ' +'[' +@DatabaseName+'].' + '[' +@SchemaName+'].' + '[' +@TableName+']' + ' WITH (NOLOCK)'
				SET @SQL = @SQL  + ' WHERE ' + @ConditionId 
		
				EXEC SP_EXECUTESQL @SQL;				

				SELECT @Id = MIN(Id) FROM[dbo].[GDPRTables] WITH (NOLOCK) WHERE Active = 1 AND Id > @Id
			END
	
		SELECT @Pk_Distributor = MIN(Pk_Distributor) FROM @dimDistributor WHERE Pk_Distributor > @Pk_Distributor
	END
	
	INSERT INTO #PIIColumns
	SELECT Pk_Distributor,
	       DistributorId, 
			'Please verify Distributor masking on ' + TableName,
			A.[String]			   
	FROM #TempPIIColumns TC WITH (NOLOCK)
	CROSS APPLY  udf_SplitVarchar(REPLACE(TC.GDPRColumns,'&','Y'), '|') AS A;


	BEGIN
		; WITH NoMaskDs As
		(
			SELECT PK_Distributor,
			TableName,
			DistributorId
			FROM #PIIColumns N 
			WHERE REPLACE(TRIM(GDPRColumns),'X','') <> ''  	
			AND GDPRColumns NOT LIKE ( '%[*]%')
			AND GDPRColumns IS NOT NULL
			AND GDPRColumns NOT IN( '1900-01-01','Unknown','0')
			GROUP BY [PK_Distributor],[TableName], [DistributorId]
		)

	MERGE [dbo].[GDPREmailNotes] GDPR
		USING NoMaskDs D
		ON 
			GDPR.Pk_Distributor = D.Pk_Distributor and GDPR.Note = D.TableName
		WHEN MATCHED  THEN
		UPDATE
		SET GDPR.DistributorStatus = 1
		   ,GDPR.ModifiedDateUTC = Getutcdate()		   
		   ,GDPR.ModifiedBy = replace(suser_sname(),'HERBALIFECORP\','')
   
		WHEN NOT MATCHED  BY SOURCE THEN UPDATE SET GDPR.DistributorStatus = 0, GDPR.ModifiedDateUTC = Getutcdate(), GDPR.ModifiedBy = replace(suser_sname(),'HERBALIFECORP\','')
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (Pk_Distributor 
					,DistributorId
					,DistributorStatus
					,Note  
					)
			VALUES (D.Pk_Distributor
					,D.DistributorId
					,1
					,D.TableName
					);
	END

	UPDATE GDPRD
	SET ModifiedDateUTC = GETUTCDATE(),
	ModifiedBy = replace(suser_sname(),'HERBALIFECORP\','')
	FROM [dbo].[GDPRDistributors] GDPRD (NOLOCK)
	JOIN [dbo].[GDPREmailNotes] GDPREN (NOLOCK) ON GDPRD.Pk_Distributor = GDPREN.Pk_Distributor
	and DistributorStatus = 1
	and StatusCode = 1;

END

EXEC [dbo].[usp_GDPR_Anonymize_Distributors];

/******************************************************************************
	If not mask data on PUBEVENT and PUBDATA DB then send email notification
******************************************************************************/

	SELECT DistributorId, substring(Note,1,100) as Description, CreatedDateUTC as Date  FROM [dbo].[GDPREmailNotes] WITH (NOLOCK)
	WHERE DistributorStatus = 1  ORDER BY CreatedDateUTC,Pk_Distributor	


	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
	
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
END CATCH
/******************************************************************************
	END PROCEDURE
******************************************************************************/
END