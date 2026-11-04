CREATE PROCEDURE [dbo].[usp_GDPR_Anonymize_Distributors]

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
-- Description	 Distributors data anonymization
-- Parameters :  @Error  OUT Error number
--               @ErrorMessage OUT Error message
--              QA/DEV
--       	     @IsDevQA SMALLINT = 0 
--------------------------------------------------------------------
--    VERSIONS
--------------------------------------------------------------------
--    1.0.0       2022-02-28     Jair Lira        Initial. 
--    1.1.0       2022-08-30     Jair Lira        Verify masking on possible unmasked Distributors. 
-- ========================================================================================
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StartTime DATETIME = GETUTCDATE()
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
DECLARE @DatabaseName NVARCHAR(100), @SchemaName NVARCHAR(100), @TableName NVARCHAR(100), @ConditionId NVARCHAR(MAX), @Id Int
DECLARE @Pk_Distributor NVARCHAR(MAX), @DistributorId NVARCHAR(MAX)

BEGIN TRY

	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END


/******************************************************************************
	GET  DAILY PII DISTRIBUTORS
******************************************************************************/
	DECLARE @dimDistributor table([Pk_Distributor] int, [DistributorId] NVARCHAR(30));

	INSERT INTO @dimDistributor SELECT Pk_Distributor, DistributorId FROM [dbo].[GDPRDistributors] WITH (NOLOCK) 
								WHERE StatusCode = 0 AND CONVERT(varchar(8),CreatedDateUTC,112) = CONVERT(varchar(8),DATEADD(day, -1, GETUTCDATE()),112) 
								UNION
							    SELECT  Pk_Distributor, DistributorId FROM [dbo].[GDPREmailNotes] WITH (NOLOCK) 
							    WHERE DistributorStatus = 1

	IF EXISTS (SELECT 1 FROM @dimDistributor)
	BEGIN

		SELECT @Pk_Distributor = STUFF((SELECT ',' + '''' +  CAST(Pk_Distributor AS varchar)  + ''''
		FROM @dimDistributor
		FOR XML PATH('')), 1,1, '')

		SELECT @DistributorId = STUFF((SELECT ',' + '''' + DistributorId + ''''
		FROM @dimDistributor
		FOR XML PATH('')), 1,1, '')


/******************************************************************************
	Mask Data on PubEventManagement DB
******************************************************************************/

		DECLARE @SQL NVARCHAR(MAX);

		DECLARE Distributor_cursor CURSOR FAST_FORWARD FOR

		SELECT
			Id, DatabaseName, SchemaName, TableName, ConditionId
		FROM
			[dbo].[GDPRTables] WITH (NOLOCK) 
		WHERE Removed = 0

		OPEN Distributor_cursor
		FETCH NEXT FROM Distributor_cursor INTO @Id, @DatabaseName,@SchemaName,@TableName, @ConditionId

		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @SQL =  'UPDATE ' +'[' +@DatabaseName+'].' + '[' +@SchemaName+'].' + '[' +@TableName+']' +' SET ' + STUFF((SELECT ', [' + GDC.ColumnName + '] = ' + '''' + GDE.Mask + '''' 
				FROM  [dbo].[GDPRColumns] GDC
				INNER JOIN [dbo].[GDPRDataElements] GDE ON GDC.GDPRColumnId = GDE.Id
				WHERE 
					GDPRTableId = @Id
				FOR XML PATH('')), 1,1, '')

				SET  @ConditionId = REPLACE(@ConditionId, '@Pk_Distributor', @Pk_Distributor);
				SET  @ConditionId = REPLACE(@ConditionId, '@DistributorId', @DistributorId);

				SET @SQL = @SQL  + ' WHERE ' + @ConditionId
				EXEC SP_EXECUTESQL @SQL;

				FETCH NEXT FROM Distributor_cursor INTO @Id, @DatabaseName,@SchemaName,@TableName, @ConditionId
			END
		CLOSE Distributor_cursor
		DEALLOCATE Distributor_cursor



/******************************************************************************
	UPDATE  GDPRDistributors TABLE
******************************************************************************/
		IF @@ERROR = 0 
		BEGIN

			UPDATE [dbo].[GDPRDistributors]
			SET ModifiedBy = replace(suser_sname(),'HERBALIFECORP\',''),
				ModifiedDateUTC = GETUTCDATE(),
				AnonymizedDistributor = 1
			WHERE StatusCode = 1 
			AND CONVERT(varchar(8),CreatedDateUTC,112) = CONVERT(varchar(8),DATEADD(day, -1, GETUTCDATE()),112) 
		END   
	END

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

