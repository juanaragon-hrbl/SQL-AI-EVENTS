CREATE PROCEDURE [dbo].[usp_SubEventQualEngine_ProcessQualifications]
	@SubEventID int
	,@DropTableSQL nvarchar(max) OUTPUT
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_SubEventQualEngine_ProcessQualifications]
	
	USE:			

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.1.0		2019-08-14		NoeG				Refactor code (SRE)
	1.1.1		2019-11-04		NoeG				SRE Hardcode changed
	1.2.0		2019-11-25		alejandramed		Including QualificationType = 53 / QualificationAbbreviation = 'PPV+DLV+TVP'
	1.2.1       2019-12-16		puertac				Changed LEFT join for INNER join in 'PurchasedSKU' qualification
	1.2.2		2025-01-30		alejandramed		Including EventID and SubEventID as part of the parameters value on ProcessingLog record
******************************************************************************/

DECLARE
	@SQL nvarchar(max)
	,@EventID int
	,@MaxQualCount int
	,@ProcName varchar(100)
	,@ProcParam varchar(100)
	,@StartTime datetime
	,@BeginCurrMonth datetime
	,@KeepDNR bit
	,@KeepDeleted bit
	,@SPQualID int -- qual id of supervisor set
	,@PK_RefSubEvent int -- In case of applicable referenced subevent
	,@StartSPRequalMonth int
	,@EndSPRequalMonth int
	,@SPQualBegin int
	,@SPQualEnd int
	,@MonthsPointer int
	,@MonthsTotal int
	,@MonthsString nvarchar(max)
	,@ValidDate DATETIME = '2049-12-31'

DECLARE
	@PK_Qualification int
	,@SortOrder varchar(3)
	,@ValidFromDate smalldatetime
	,@ValidThroughDate smalldatetime
	,@IsQualMember bit
	,@QualificationType int
	,@QualificationFrequencyType int
	,@QualificationFrequency int
	,@QualificationValue VARCHAR(500)
	,@SubEventQualFilter varchar(100)
	,@ExtValidFromDate smalldatetime
	,@ExtValidThroughDate smalldatetime
	,@DateType varchar(30)
	,@MetricType varchar(10)
	,@LevelType varchar(10)
	,@BeginLevel smallint
	,@EndLevel smallint
	,@ExtSubEventQualFilter varchar(250)
	,@MonthFrequency smallint
	,@CountLimit smallint
	,@CountMax int


SELECT 
	@EventID = PK_Event
	,@KeepDNR = KeepDNR
	,@KeepDeleted = KeepDeleted
FROM 
	dbo.SubEvent 
WHERE 
	PK_SubEvent = @SubEventID

SET @ProcName = 'usp_SubEventQualEngine_ProcessQualifications'
SET @ProcParam = CONVERT(varchar,@EventID) + ', ' +  CONVERT(varchar,@SubEventID)
SET @StartTime = GETUTCDATE()
SET @BeginCurrMonth = CONVERT(DATETIME,CONVERT(varchar(8),GETUTCDATE(),120) + '01',120)
SELECT @SPQualID = PK_Qualification FROM dbo.Qualification WHERE QualificationAbbreviation = 'SP'

IF @IsDevQA = 1 PRINT '@SubEventID = ' + CONVERT(varchar,@SubEventID)
IF @IsDevQA = 1 PRINT '@SPQualID = ' + CONVERT(varchar,@SPQualID)
IF @IsDevQA = 1 PRINT '@EventID = ' + CONVERT(varchar,@EventID)
IF @IsDevQA = 1 PRINT '@KeepDNR = ' + CONVERT(varchar,@KeepDNR)
IF @IsDevQA = 1 PRINT '@KeepDeleted = ' + CONVERT(varchar,@KeepDeleted)

IF @KeepDNR = 0
BEGIN
	IF OBJECT_ID('tempdb..##DNR') IS NOT NULL DROP TABLE ##DNR
	SET @DropTableSQL = @DropTableSQL + 'IF OBJECT_ID(''tempdb..##DNR'') IS NOT NULL DROP TABLE ##DNR' + CHAR(13)
	CREATE TABLE ##DNR (PK_Distributor int)
	INSERT ##DNR (PK_Distributor) SELECT PK_Distributor FROM dbo.v_DistributorDoNotRecognize
END

/******************************************************************************
	get qualfications and write to temp tables
******************************************************************************/
DECLARE eq_cursor CURSOR STATIC FOR 
	SELECT
		S.PK_Qualification
		,CONVERT(varchar,S.SortOrder)
		,S.ValidFromDateUTC
		,S.ValidThroughDateUTC
		,S.IsQualMember
		,S.QualificationValue
		,S.SubEventQualFilter
		,Q.PK_QualificationType
		,Q.PK_QualificationFrequencyType
		,Q.QualificationFrequency
		,S.ExtValidFromDate
		,S.ExtValidThroughDate
		,S.DateType
		,S.MetricType
		,S.LevelType
		,S.BeginLevel
		,S.EndLevel
		,S.ExtSubEventQualFilter
		,S.MonthFrequency
		,S.CountLimit
		,S.CountMax
	FROM
		dbo.SubEventQualification S WITH (NOLOCK)
	INNER JOIN
		dbo.Qualification Q WITH (NOLOCK)
		ON
			S.PK_Qualification = Q.PK_Qualification
	WHERE
		S.PK_SubEvent = @SubEventID
	ORDER BY
		S.SortOrder

OPEN eq_cursor

SET @MaxQualCount = @@CURSOR_ROWS

FETCH NEXT FROM eq_cursor INTO  
	@PK_Qualification
	,@SortOrder
	,@ValidFromDate
	,@ValidThroughDate
	,@IsQualMember
	,@QualificationValue
	,@SubEventQualFilter
	,@QualificationType
	,@QualificationFrequencyType
	,@QualificationFrequency
	,@ExtValidFromDate 
	,@ExtValidThroughDate 
	,@DateType 
	,@MetricType 
	,@LevelType 
	,@BeginLevel 
	,@EndLevel 
	,@ExtSubEventQualFilter 
	,@MonthFrequency 
	,@CountLimit
	,@CountMax

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'IF OBJECT_ID(''tempdb..##Q' + @SortOrder + ''') IS NOT NULL DROP TABLE ##Q' + @SortOrder
	SET @DropTableSQL = @DropTableSQL + 'IF OBJECT_ID(''tempdb..##Q' + @SortOrder + ''') IS NOT NULL DROP TABLE ##Q' + @SortOrder + CHAR(13)
	IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
	EXEC sp_executesql @SQL

	SET @SQL = 'CREATE TABLE ##Q' + @SortOrder + ' (PK_Distributor int, QualDate smalldatetime)'
	IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
	EXEC sp_executesql @SQL

	IF @QualificationType = 7
	BEGIN
		/******************************************************************************
			for event specific @QualificationType=7
		******************************************************************************/
		/******************************************************************************
			Purchased SKU For Event
			note: don't limit sku purchases by distributor cop
		******************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'PurchasedSKU')
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.PK_Distributor_Purchaser,  MIN(S.OrderDate)'
				SET @SQL = @SQL + ' FROM dbo.SKUPurchased S WITH (NOLOCK) '

				IF @KeepDeleted = 0 
				BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorCurrent D ON S.PK_Distributor_Purchaser = D.nDistributorID'
				END
				ELSE
				BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_Distributor D ON S.PK_Distributor_Purchaser = D.nDistributorID'
				END

				SET @SQL = @SQL + ' WHERE S.PK_Event = ' + CONVERT(varchar,ISNULL(@ExtSubEventQualFilter,@EventID))

				IF @QualificationValue IS NOT NULL BEGIN
					SET @SQL = @SQL + ' AND S.PK_EventSKU = ' + CONVERT(varchar,@QualificationValue)
				END
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND S.OrderDate >= ''' + CONVERT(varchar,@ValidFromDate) + ''' AND S.OrderDate <= ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.PK_Distributor_Purchaser NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				SET @SQL = @SQL + ' GROUP BY S.PK_Distributor_Purchaser'
			END ELSE
			BEGIN
				/* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT QD.nDistributorID AS PK_Distributor, ''' + CONVERT(varchar,@BeginCurrMonth) + ''' AS QualDate'
				SET @SQL = @SQL + ' FROM dbo.v_Distributor QD WHERE QD.nDistributorID NOT IN'
				SET @SQL = @SQL + ' (SELECT PK_Distributor_Purchaser'
				SET @SQL = @SQL + ' FROM dbo.SKUPurchased WITH (NOLOCK) '
				SET @SQL = @SQL + ' WHERE PK_Event = ' + CONVERT(varchar,ISNULL(@ExtSubEventQualFilter,@EventID)) 
				IF @QualificationValue IS NOT NULL BEGIN
					SET @SQL = @SQL + ' AND PK_EventSKU = ' + CONVERT(varchar,@QualificationValue)
				END
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND OrderDate >= ''' + CONVERT(varchar,@ValidFromDate) + ''' AND OrderDate <= ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				SET @SQL = @SQL + ' )'

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				IF @KeepDeleted = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.StatusCode = ''COMPLETE'''
				END
			END
		END
		
		/******************************************************************************
			Have Event Ticket Available
		******************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'EventTicketAvailable')
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT ETA.PK_ToDistributor,  MIN(ETA.ValidFromDateUTC)'
				SET @SQL = @SQL + ' FROM dbo.EventTicketAssignment ETA (NOLOCK) '

				IF @KeepDeleted = 0 
				BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorCurrent D ON ETA.PK_ToDistributor = D.nDistributorID'
				END
				ELSE
				BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_Distributor D ON ETA.PK_ToDistributor = D.nDistributorID'
				END
				
				IF @QualificationValue IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + ' WHERE ETA.PK_Event = ' + CONVERT(varchar,@QualificationValue)
				END
				ELSE
				BEGIN
					SET @SQL = @SQL + ' WHERE ETA.PK_Event = ' + CONVERT(varchar,@EventID)
				END
				SET @SQL = @SQL + ' AND ETA.ValidToDateUTC = ''' + CONVERT(varchar,@ValidDate) + ''''
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND ETA.ValidFromDateUTC BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND ETA.PK_ToDistributor NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				SET @SQL = @SQL + ' GROUP BY ETA.PK_ToDistributor'
			END ELSE
			BEGIN
				/* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT QD.nDistributorID AS PK_Distributor, ''' + CONVERT(varchar,@BeginCurrMonth) + ''' AS QualDate'
				SET @SQL = @SQL + ' FROM dbo.v_Distributor QD WHERE NOT EXISTS'
				SET @SQL = @SQL + ' (SELECT 1 FROM dbo.EventTicketAssignment ETA (NOLOCK) '
				IF @QualificationValue IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + ' WHERE ETA.PK_Event = ' + CONVERT(varchar,@QualificationValue)
				END
				ELSE
				BEGIN
					SET @SQL = @SQL + ' WHERE ETA.PK_Event = ' + CONVERT(varchar,@EventID)
				END
				SET @SQL = @SQL + ' AND ETA.PK_ToDistributor = QD.nDistributorID '
				SET @SQL = @SQL + ' AND ETA.ValidToDateUTC = ''' + CONVERT(varchar,@ValidDate) + ''''
				
				SET @SQL = @SQL + ' )'

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				IF @KeepDeleted = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.StatusCode = ''COMPLETE'''
				END
			END
		END

		/******************************************************************************
			Attended an Event (QualID=63) 
	`		Implement when schema added to support this
		******************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'AttendedEvent')
			AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.PK_Distributor,  MIN(S.AttendanceFromTimeUTC) '
				SET @SQL = @SQL + ' FROM dbo.v_EventAttendance S'

				IF @KeepDeleted = 0 BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorCurrent D ON S.PK_Distributor = D.nDistributorID'
				END

				SET @SQL = @SQL + ' WHERE S.PK_Event = ' + CONVERT(varchar,@QualificationValue)

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.PK_Distributor NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				SET @SQL = @SQL + ' GROUP BY S.PK_Distributor '
			END ELSE
			BEGIN
				/* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT QD.PK_Distributor, MIN(QD.RoyaltyMonth)'
				SET @SQL = @SQL + ' FROM dbo.QualificationDistributor QD WITH (NOLOCK) WHERE QD.PK_Qualification = ' + CONVERT(varchar,@SPQualID)
				SET @SQL = @SQL + ' AND QD.PK_Distributor NOT IN'
				SET @SQL = @SQL + ' (SELECT DISTINCT PK_Distributor '
				SET @SQL = @SQL + ' FROM dbo.v_EventAttendance '
				SET @SQL = @SQL + ' WHERE PK_Event = ' + CONVERT(varchar,@QualificationValue) + ' )'

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.PK_Distributor NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				IF @KeepDeleted = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.IsDeleted = 0'
				END

				SET @SQL = @SQL + ' GROUP BY QD.PK_Distributor'
			END
		END

		/*************************************************************************************************
			Qualified for Promtotion (QualID=64)
			Implement when schema added to support this. Must have Qualification value specified
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'QualifiedPromotion')
           AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,  MIN(S.dFrom) '
				SET @SQL = @SQL + ' FROM dbo.v_DistributorGroupMember S'

				IF @KeepDeleted = 0 BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorCurrent D ON S.nDistributorID = D.nDistributorID'
				END

				SET @SQL = @SQL + ' WHERE S.nDistributorGroupID = ' + CONVERT(varchar,@QualificationValue)

				SET @SQL = @SQL + ' AND S.dThrough = ''' + CONVERT(varchar,@ValidDate) + ''' '

				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND S.dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				SET @SQL = @SQL + ' GROUP BY S.nDistributorID '
			END ELSE
			BEGIN
				/* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT QD.PK_Distributor, MIN(QD.RoyaltyMonth)'
				SET @SQL = @SQL + ' FROM dbo.QualificationDistributor QD WITH (NOLOCK) WHERE QD.PK_Qualification = ' + CONVERT(varchar,@SPQualID)
				SET @SQL = @SQL + ' AND QD.PK_Distributor NOT IN'
				SET @SQL = @SQL + ' (SELECT DISTINCT nDistributorID'
				SET @SQL = @SQL + ' FROM dbo.v_DistributorGroupMember'
				SET @SQL = @SQL + ' WHERE dThrough = ''' + CONVERT(varchar,@ValidDate) + ''' AND nDistributorGroupID = ' + CONVERT(varchar,@QualificationValue)
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''
				END
				SET @SQL = @SQL + ' )'

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.PK_Distributor NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				IF @KeepDeleted = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.IsDeleted = 0'
				END

				SET @SQL = @SQL + ' GROUP BY QD.PK_Distributor'
			END
		END

		/*************************************************************************************************
			Distributor of Specific Country (QualID=71)
			Distributors of specific country of processing for an event.
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DistributorsOfCOP')
           AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, '''+CONVERT(VARCHAR,@BeginCurrMonth)+''' AS QualDate '
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C ON C.sCountryCode = S.sDistributorCountryProcessingCode '
				
				IF @ExtSubEventQualFilter = 'COR'
					SET @SQL = @SQL + ' AND C.sCountryCode = S.sDistributorCountryResidenceCode '
				
				SET @SQL = @SQL + ' WHERE C.nCountryID IN (' + @QualificationValue + ')'
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND S.dDeleted BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

			END ELSE
            BEGIN
                /* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,  '''+CONVERT(VARCHAR,@BeginCurrMonth)+''' AS QualDate '
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C ON C.sCountryCode = S.sDistributorCountryProcessingCode '
				
				SET @SQL = @SQL + ' WHERE C.nCountryID NOT IN (' + @QualificationValue + ')' 
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND S.dDeleted BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
            END
		END

		/*************************************************************************************************
			Distributor of Specific Country of Residence(QualID=808)
			Distributors of specific country of residence.
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DistributorsOfCOR')
           AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, '''+CONVERT(VARCHAR,@BeginCurrMonth)+''' AS QualDate '
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C ON C.sCountryCode = S.sDistributorCountryResidenceCode '
				
				SET @SQL = @SQL + ' WHERE C.nCountryID IN (' + @QualificationValue + ')'
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND S.dDeleted BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

			END ELSE
            BEGIN
                /* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,  '''+CONVERT(VARCHAR,@BeginCurrMonth)+''' AS QualDate '
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C ON C.sCountryCode = S.sDistributorCountryResidenceCode '
				
				SET @SQL = @SQL + ' WHERE C.nCountryID != ' + CONVERT(varchar,@QualificationValue) 
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND S.dDeleted BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
            END
		END
		
		/*************************************************************************************************
			Distributor of Specific Country (QualID=815)
			Distributors of specific country of processing for an event.
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DistributorsByRegion')
           AND @SubEventQualFilter IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, '''+CONVERT(VARCHAR,@BeginCurrMonth)+''' AS QualDate '
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C ON C.sCountryCode = S.sDistributorCountryProcessingCode '
				
				SET @SQL = @SQL + ' WHERE C.sRegionCode = ''' + CONVERT(varchar,@SubEventQualFilter) + ''''
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND S.dDeleted BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				IF @ExtSubEventQualFilter IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND C.nCountryID NOT IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')' 
				END

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

			END ELSE
            BEGIN
                /* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,  '''+CONVERT(VARCHAR,@BeginCurrMonth)+''' AS QualDate '
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C ON C.sCountryCode = S.sDistributorCountryProcessingCode '

				SET @SQL = @SQL + ' WHERE C.sRegionCode != ''' + CONVERT(varchar,@SubEventQualFilter) + '''' 
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND S.dDeleted BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
            END
		END

		/*************************************************************************************************
			DS Point In Time Only Team (QualID=70)
			Distributors Point In Time Only Team.
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DSPointInTimeOnlyTeam')
           AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, MIN(H.dFrom) '
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorHistory H 
										ON S.nDistributorID = H.nDistributorIDFK 
										WHERE H.nEventTypeLID = ' + CONVERT(varchar,@QualificationValue)
				SET @SQL = @SQL + ' AND H.dThrough = ''' + CONVERT(varchar,@ValidDate) + ''' '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND H.dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				SET @SQL = @SQL + ' AND NOT EXISTS (SELECT 1 FROM dbo.v_DistributorHistory L 
									WHERE S.nDistributorID = L.nDistributorIDFK AND L.dThrough = ''2049-12-31''
									AND L.SortOrder > H.SortOrder '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND L.dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				SET @SQL = @SQL + ') '
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nDistributorID '

			END ELSE
            BEGIN
                /* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT D.nDistributorID,GETDATE() '
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent D '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor D '
                END
				SET @SQL = @SQL + ' WHERE NOT EXISTS ( SELECT VL.nDistributorID,VL.dFrom FROM '
				SET @SQL = @SQL + ' (SELECT S.nDistributorID, MIN(H.dFrom) AS dFrom'
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorHistory H 
										ON S.nDistributorID = H.nDistributorIDFK 
										AND H.nEventTypeLID = ' + CONVERT(varchar,@QualificationValue)
				SET @SQL = @SQL + ' AND H.dThrough = ''' + CONVERT(varchar,@ValidDate) + ''' '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND H.dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				SET @SQL = @SQL + ' AND NOT EXISTS (SELECT 1 FROM dbo.v_DistributorHistory L 
									WHERE S.nDistributorID = L.nDistributorIDFK AND L.dThrough = ''2049-12-31''
									AND L.SortOrder > H.SortOrder ' 
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND L.dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				SET @SQL = @SQL + ') '
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nDistributorID ) VL WHERE VL.nDistributorID = D.nDistributorID ) '
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND D.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
            END
		END
		
		/*************************************************************************************************
			DS Also Belong to this team at this date (QualID=300)
			Distributors Is/Was also a member of this team at this time.
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DSWasAlsoInTeamAtThisTime')
           AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, MIN(H.dFrom) '
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorHistory H 
										ON S.nDistributorID = H.nDistributorIDFK 
										WHERE H.nEventTypeLID = ' + CONVERT(varchar,@QualificationValue)
				SET @SQL = @SQL + ' AND H.dThrough = ''' + CONVERT(varchar,@ValidDate) + ''' '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NULL
				BEGIN
					SET @SQL = @SQL + ' AND ''' + CONVERT(varchar,@ValidFromDate) + ''' BETWEEN H.dFrom AND H.dThrough '
				END
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND H.dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nDistributorID '

			END ELSE
            BEGIN
                /* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT D.nDistributorID,GETDATE() '
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent D '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor D '
                END
				SET @SQL = @SQL + ' WHERE NOT EXISTS ( SELECT VL.nDistributorID,VL.dFrom FROM '
				SET @SQL = @SQL + ' (SELECT S.nDistributorID, MIN(H.dFrom) AS dFrom'
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorHistory H 
										ON S.nDistributorID = H.nDistributorIDFK 
										AND H.nEventTypeLID = ' + CONVERT(varchar,@QualificationValue)
				SET @SQL = @SQL + ' AND H.dThrough = ''' + CONVERT(varchar,@ValidDate) + ''' '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NULL
				BEGIN
					SET @SQL = @SQL + ' AND ''' + CONVERT(varchar,@ValidFromDate) + ''' BETWEEN H.dFrom AND H.dThrough '
				END
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND H.dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nDistributorID ) VL WHERE VL.nDistributorID = D.nDistributorID ) '
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND D.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
            END
		END
		
		/*************************************************************************************************
			DS Is Member of this team of greater (QualID=301)
			Distributors Is/Was a member of this team or greater at this time.
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DSTeamOrGreaterTeamAtThisTime')
           AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, MIN(H.dFrom) '
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorHistory H 
										ON S.nDistributorID = H.nDistributorIDFK 
									INNER JOIN dbo.v_dimDSLifeCycle LC
										ON LC.LifeCycleCode = ' + CONVERT(varchar,@QualificationValue) + '
										WHERE H.SortOrder >= LC.SortOrder 
										AND  H.nEventTypeLID NOT IN (242,243,244,245)' 
				SET @SQL = @SQL + ' AND H.dThrough = ''' + CONVERT(varchar,@ValidDate) + ''' '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NULL
				BEGIN
					SET @SQL = @SQL + ' AND ''' + CONVERT(varchar,@ValidFromDate) + ''' BETWEEN H.dFrom AND H.dThrough '
				END
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND H.dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nDistributorID '

			END ELSE
            BEGIN
                /* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT D.nDistributorID,GETDATE() '
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent D '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor D '
                END
				SET @SQL = @SQL + ' WHERE NOT EXISTS ( SELECT VL.nDistributorID,VL.dFrom FROM '
				SET @SQL = @SQL + ' (SELECT S.nDistributorID, MIN(H.dFrom) AS dFrom'
                BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
                ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
                END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorHistory H 
										ON S.nDistributorID = H.nDistributorIDFK 
									INNER JOIN dbo.v_dimDSLifeCycle LC
										ON LC.LifeCycleCode = ' + CONVERT(varchar,@QualificationValue) + '
										WHERE H.SortOrder >= LC.SortOrder ' 
				SET @SQL = @SQL + ' AND H.dThrough = ''' + CONVERT(varchar,@ValidDate) + ''' '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NULL
				BEGIN
					SET @SQL = @SQL + ' AND ''' + CONVERT(varchar,@ValidFromDate) + ''' BETWEEN H.dFrom AND H.dThrough '
				END
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND H.dFrom BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nDistributorID ) VL WHERE VL.nDistributorID = D.nDistributorID ) '
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND D.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
            END
		END

	END 

	ELSE IF @QualificationType = 9
	BEGIN
		/***************************************************************************************************************
			for user specified list @QualificationID=68: @QualificationValue MUST BE PROVIDED IN THE SETUP
		***************************************************************************************************************/
		/******************************************************************************
			List Provided By Business User
		******************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'UserList')
           AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,  MIN(S.dAdded) '
				SET @SQL = @SQL + ' FROM dbo.v_DistributorSet S'

				IF @KeepDeleted = 0 BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorCurrent D ON S.nDistributorID = D.nDistributorID'
				END

				SET @SQL = @SQL + ' WHERE S.nTypeLID = ' + CONVERT(varchar,@QualificationValue)

				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL 
					BEGIN
						SET @SQL = @SQL + ' AND S.dQualified BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + '''' 
					END

				SET @SQL = @SQL + ' AND S.dThrough = ''' + CONVERT(varchar,@ValidDate) + ''' '

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				SET @SQL = @SQL + ' GROUP BY S.nDistributorID '
			END ELSE
			BEGIN
				/* if a distributor is NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT QD.PK_Distributor, MIN(QD.RoyaltyMonth)'
				SET @SQL = @SQL + ' FROM dbo.QualificationDistributor QD WITH (NOLOCK) WHERE QD.PK_Qualification IN (' + CONVERT(varchar,@SPQualID) +',2)'
				IF @SubEventQualFilter IS NOT NULL 
                BEGIN
					SET @SQL = @SQL + ' AND QD.PK_Country IN (' + @SubEventQualFilter + ')'     
                END
				SET @SQL = @SQL + ' AND NOT EXISTS '
				SET @SQL = @SQL + ' (SELECT 1 FROM dbo.v_DistributorSet DS'
				SET @SQL = @SQL + ' WHERE DS.nDistributorID = QD.PK_Distributor AND DS.dThrough = ''2049-12-31'' AND DS.nTypeLID = ' + CONVERT(varchar,@QualificationValue) 

				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL 
					BEGIN
						SET @SQL = @SQL + ' AND DS.dQualified BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + '''' 
					END
				SET @SQL = @SQL + ' )'

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.PK_Distributor NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				IF @KeepDeleted = 0 BEGIN
					SET @SQL = @SQL + ' AND QD.IsDeleted = 0'
				END

				SET @SQL = @SQL + ' GROUP BY QD.PK_Distributor'
			END
    
		END 

	END 
	
	ELSE IF @QualificationType = 8
	
	BEGIN
	/***************************************************************************************************************
		for sponsoring @QualificationID=608: @QualificationValue and QualificationFilter MUST BE PROVIDED IN THE SETUP
	***************************************************************************************************************/
	/******************************************************************************
		This is for sponsoring either DS or SP
	******************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'NoOfSponsors')
           AND @QualificationValue IS NOT NULL AND @SubEventQualFilter IS NOT NULL
		BEGIN
			IF @IsQualMember = 1 AND @SubEventQualFilter = 'DS'
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				IF @KeepDeleted = 1 
				BEGIN
				   SET @SQL = @SQL + ' SELECT S.nSponsorID,'''+CONVERT(varchar,@ValidFromDate)+''''
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S'
				END
				IF @KeepDeleted = 0
				BEGIN
				   SET @SQL = @SQL + ' SELECT S.nSponsorID,'''+CONVERT(varchar,@ValidFromDate)+''''
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S'
				END
				SET @SQL = @SQL + ' WHERE 1 = 1 '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL 
					BEGIN
						SET @SQL = @SQL + ' AND S.dApplication BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + '''' 
					END
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nSponsorID '
				SET @SQL = @SQL + ' HAVING COUNT(1) >= ' + CONVERT(varchar,@QualificationValue)
			END 
			ELSE IF @IsQualMember = 1 AND @SubEventQualFilter = 'SP'
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				IF @KeepDeleted = 1 
				BEGIN
				   SET @SQL = @SQL + ' SELECT S.nSponsorID,'''+CONVERT(varchar,@ValidFromDate)+''''
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S'
				END
				IF @KeepDeleted = 0
				BEGIN
				   SET @SQL = @SQL + ' SELECT S.nSponsorID,'''+CONVERT(varchar,@ValidFromDate)+''''
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S'
				END
				SET @SQL = @SQL + ' WHERE 1 = 1 '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL 
					BEGIN
						SET @SQL = @SQL + ' AND S.dSupervisorQualification BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + '''' 
					END
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nSponsorID '
				SET @SQL = @SQL + ' HAVING COUNT(1) >= ' + CONVERT(varchar,@QualificationValue)
			END
			
			ELSE IF @IsQualMember = 1 AND @SubEventQualFilter = 'SB'
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				IF @KeepDeleted = 1 
				BEGIN
				   SET @SQL = @SQL + ' SELECT S.nSponsorID,'''+CONVERT(varchar,@ValidFromDate)+''''
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S'
				END
				IF @KeepDeleted = 0
				BEGIN
				   SET @SQL = @SQL + ' SELECT S.nSponsorID,'''+CONVERT(varchar,@ValidFromDate)+''''
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S'
				END
				SET @SQL = @SQL + ' WHERE 1 = 1 '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL 
					BEGIN
						SET @SQL = @SQL + ' AND S.dSBQualification BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + '''' 
					END
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nSponsorID '
				SET @SQL = @SQL + ' HAVING COUNT(1) >= ' + CONVERT(varchar,@QualificationValue)
			END
			
			ELSE IF @IsQualMember = 1 AND @SubEventQualFilter = 'QP'
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				IF @KeepDeleted = 1 
				BEGIN
				   SET @SQL = @SQL + ' SELECT S.nSponsorID,'''+CONVERT(varchar,@ValidFromDate)+''''
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S'
				END
				IF @KeepDeleted = 0
				BEGIN
				   SET @SQL = @SQL + ' SELECT S.nSponsorID,'''+CONVERT(varchar,@ValidFromDate)+''''
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S'
				END
				SET @SQL = @SQL + ' WHERE 1 = 1 '
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL 
					BEGIN
						SET @SQL = @SQL + ' AND S.dQPQualification BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + '''' 
					END
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				SET @SQL = @SQL + ' GROUP BY S.nSponsorID '
				SET @SQL = @SQL + ' HAVING COUNT(1) >= ' + CONVERT(varchar,@QualificationValue)
			END
    
    	END 

	END

	ELSE IF @QualificationType IN (10,14)
	BEGIN
		/***************************************************************************************************************************************
			For Special Orders with specific dates (Brazil in case) @QualificationType=10: Order begin/end dates MUST BE PROVIDED IN THE SETUP
		***************************************************************************************************************************************/
	
		IF EXISTS (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation IN ('DistributorOrdersVP','DistributorOrdersRO'))
           AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1

				-- Call procedure to generate entries into work table dbo.wrkAggAssc_AssocCombined

				EXEC dbo.usp_AggAssociations_VPRO
					@BeginDate       = @ValidFromDate
					,@EndDate        = @ValidThroughDate
					,@RequiredPoints = @QualificationValue
					,@QualType	     = @QualificationType
					,@RoyaltyMonth   = @SubEventQualFilter

				BEGIN
					/* if a distributor is a member of the qualification */
					SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
					SET @SQL = @SQL + ' SELECT S.nDistributorID,  MIN(S.dRoyaltyMonth) '
					SET @SQL = @SQL + ' FROM dbo.wrkAggAssc_AssocCombined S WITH (NOLOCK) '

					IF @KeepDeleted = 0 
						BEGIN
							SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorCurrent D ON S.nDistributorID = D.nDistributorID'
						END
					ELSE
						BEGIN
							SET @SQL = @SQL + ' INNER JOIN dbo.v_Distributor D ON S.nDistributorID = D.nDistributorID'
						END

					IF @KeepDNR = 0 BEGIN
						SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
					END

					SET @SQL = @SQL + ' GROUP BY S.nDistributorID '
				END 
			
		END 

	END 

	ELSE IF @QualificationType = 11
	BEGIN
		/*********************************************************************************************************************************************************
			For Special cases where SP Qual Date and VP for the Qual Date are compared. That is, Volume Points for the month of SP Qualification.
			@QualificationType=11: @QualificationValue MUST BE PROVIDED IN THE SETUP.
			This assumes that qualification will always be for members who meet the qualification type 
		*********************************************************************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'SPQualDateAndVP')
           AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
				BEGIN
					/* if a distributor is a member of the qualification */
					SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
					SET @SQL = @SQL + ' SELECT S.nDistributorID, S.dSPQualDate '
					SET @SQL = @SQL + ' FROM (SELECT D.nDistributorID,ISNULL(D.dSupervisorQualification,''1900-01-01'') dSPQualDate '
					IF @KeepDeleted = 0 
						BEGIN
							SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent D'
						END
					ELSE
						BEGIN
							SET @SQL = @SQL + ' FROM dbo.v_Distributor D'
						END
					IF @SubEventQualFilter IS NOT NULL -- This is where the qualification may apply filter by country for this QualType.
						BEGIN
							SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C '
							SET @SQL = @SQL + ' ON D.sDistributorCountryProcessingCode = C.sCountryCode '
							SET @SQL = @SQL + ' AND C.nCountryID = ' +  CONVERT(varchar,@SubEventQualFilter)
						END

					SET @SQL = @SQL + ' WHERE sType IN (''SP'',''RB'',''RS'') ) S '
					SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID AGG '
					SET @SQL = @SQL + ' ON AGG.nDistributorID = S.nDistributorID '
					SET @SQL = @SQL + ' WHERE AGG.dRoyaltyMonth = convert(datetime,CONVERT(char(6), S.dSPQualDate , 112) + ''01'')'
					IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
						BEGIN
							SET @SQL = @SQL + ' AND S.dSPQualDate BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
						END
					SET @SQL = @SQL + ' AND AGG.mVolumePoints >= ' + CONVERT(varchar,@QualificationValue)
					
					IF @KeepDNR = 0 
					BEGIN
						SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
					END

				END 
			    
		END 

	END 
	
	ELSE IF @QualificationType = 15
	BEGIN
		/*********************************************************************************************************************************************************
			This is to determine the PPV on a single order for the month(s) specified 
		*********************************************************************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'PPVOnAnOrder')
           AND @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
				BEGIN
					/* if a distributor is a member of the qualification */
					SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
					SET @SQL = @SQL + ' SELECT DISTINCT S.nDistributorIDFK, ' + '''' + CONVERT(varchar,@ValidThroughDate) + + ''' AS QualDate'
					SET @SQL = @SQL + ' FROM dbo.v_DistributorOrder S INNER JOIN '
					IF @KeepDeleted = 0 
						BEGIN
							SET @SQL = @SQL + ' dbo.v_DistributorCurrent D'
						END
					ELSE
						BEGIN
							SET @SQL = @SQL + ' dbo.v_Distributor D'
						END
						SET @SQL = @SQL + ' ON S.nDistributorIDFK = D.nDistributorID '
					
					IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
						BEGIN
							SET @SQL = @SQL + ' AND S.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
						END
					SET @SQL = @SQL + ' AND S.mVolumePoints >= ' + CONVERT(varchar,@QualificationValue)
					
					IF @KeepDNR = 0 
					BEGIN
						SET @SQL = @SQL + ' AND S.nDistributorIDFK NOT IN (SELECT PK_Distributor FROM ##DNR)'
					END
				END 
		END 
	END 
	
	ELSE IF @QualificationType = 19
	BEGIN
		/***************************************************************************************************************************************
			For requirements of sponsors with certain number of downlines within certain level who also have certain metric in month(s)
		***************************************************************************************************************************************/
	
		IF EXISTS (SELECT 1 FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation IN ('SponsorDLWithLevelAccMetric','SponsorDLWithLevelAnyMetric','SponsorDLWithLevelCMMetric')
					AND PK_Qualification = @PK_Qualification)
           AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL --AND @QualificationValue IS NOT NULL AND @MetricType IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
				IF @ExtValidThroughDate IS NULL 
				BEGIN
					SET @ExtValidThroughDate = @ValidThroughDate
				END
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT SLL.PK_Distributor, SLL.QualDate FROM ( '
				IF @QualificationFrequencyType IN (1,2) 
				BEGIN
					SET @SQL = @SQL + ' SELECT DLL.PK_Distributor,DLL.PK_DSDownline,DLL.QualDate, COUNT(1) AS nCnt FROM '
				END
				IF @QualificationFrequencyType = 3
				BEGIN
					SET @SQL = @SQL + ' SELECT DISTINCT SLL.PK_Distributor,SLL.PK_DSDownline,SLL.QualDate FROM ('
					SET @SQL = @SQL + ' SELECT DLL.PK_Distributor,DLL.PK_DSDownline,FV.dRoyaltyMonth,DLL.QualDate FROM '
				END
				
				IF @KeepDeleted = 1 
				BEGIN
				   SET @SQL = @SQL + ' (SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ExtValidThroughDate)+''' AS QualDate'
				   SET @SQL = @SQL + ' FROM dbo.v_dimDSLngDownline SP INNER JOIN dbo.v_Distributor DS ON SP.PK_Distributor = DS.nDistributorID'
				   SET @SQL = @SQL + ' INNER JOIN dbo.v_Distributor DL ON SP.PK_DSDownline = DL.nDistributorID'
				END
				ELSE
				BEGIN
				 SET @SQL = @SQL + ' (SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ExtValidThroughDate)+''' AS QualDate'
				   SET @SQL = @SQL + ' FROM dbo.v_dimDSLngDownline SP INNER JOIN dbo.v_DistributorCurrent DS ON SP.PK_Distributor = DS.nDistributorID'
				   SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorCurrent DL ON SP.PK_DSDownline = DL.nDistributorID'
				END
				IF @DateType = 'AppDate' 
				BEGIN
					SET @SQL = @SQL + ' AND DL.dApplication BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				IF @DateType = 'SPDate' 
				BEGIN
					SET @SQL = @SQL + ' AND DL.dSupervisorQualification BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				SET @SQL = @SQL + ' WHERE SP.PK_Distributor <> SP.PK_DSDownline '	-- To Exclude Self
				IF @LevelType = 'DS'												-- To Determine whether DS or SP Level to use
				BEGIN
					SET @SQL = @SQL + ' AND SP.DSLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)
				END
				ELSE
				BEGIN
					SET @SQL = @SQL + ' AND SP.SPLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)
				END
				IF @SubEventQualFilter IN ('DS','SP','USP')
				BEGIN
					IF @SubEventQualFilter = 'USP'
						SET @SQL = @SQL + ' AND DL.sType = ''SP'''
					ELSE
						SET @SQL = @SQL + ' AND DL.sType = ''' + @SubEventQualFilter + ''''
				END
				IF @ExtSubEventQualFilter IS NOT NULL 
				BEGIN
					IF @ExtSubEventQualFilter = 'TAB' -- To Filter By TAB
					   SET @SQL = @SQL + ' AND ISNULL(DL.sTeam,''SP'') IN (''G'',''M'',''P'',''A'',''B'',''C'')' 
					ELSE IF @ExtSubEventQualFilter = 'NonTAB' -- To Filter By NonTAB 
					   SET @SQL = @SQL + ' AND ISNULL(DL.sTeam,''SP'') NOT IN (''G'',''M'',''P'',''A'',''B'',''C'')'
					ELSE IF @MetricType = 'DL' AND @ExtSubEventQualFilter IS NOT NULL -- To Filter By COP
					BEGIN
					   SET @SQL = @SQL + ' AND DL.nDistributorCountryProcessingID IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')' 
					   SET @SQL = @SQL + ' AND DS.nDistributorCountryProcessingID IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')' 
					END
					ELSE
						SET @SQL = @SQL + ' AND DS.nDistributorCountryProcessingID IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')' 
				END 
				SET @SQL = @SQL + ' ) DLL '
				
				IF @MetricType IS NOT NULL AND @MetricType != 'DL'
				BEGIN
				
				IF @QualificationFrequencyType IN (1,2) AND @SubEventQualFilter = 'SP'
				BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID FV ON DLL.PK_DSDownline = FV.nDistributorID '
					SET @SQL = @SQL + ' AND FV.dRoyaltyMonth BETWEEN FV.dQual_SP AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				END
				ELSE IF @QualificationFrequencyType IN (1,2)
				BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID FV ON DLL.PK_DSDownline = FV.nDistributorID '
					SET @SQL = @SQL + ' AND FV.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				END
				
				IF @QualificationFrequencyType = 3
				BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID FV ON DLL.PK_DSDownline = FV.nDistributorID 
										INNER JOIN dbo.v_aggFQS_ID FV2 ON DLL.PK_DSDownline = FV2.nDistributorID '
					SET @SQL = @SQL + ' AND FV2.dRoyaltyMonth BETWEEN DATEADD(M,-'+CONVERT(varchar,(@MonthFrequency-1))+',FV.dRoyaltyMonth) AND FV.dRoyaltyMonth'
					IF @MetricType = 'TV'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mVolumePoints >= '+CONVERT(varchar,@QualificationValue) 
						SET @SQL = @SQL + ' AND FV2.mVolumePoints >= '+CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'PPV'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mPersonalPurchaseVolume >= '+CONVERT(varchar,@QualificationValue) 
						SET @SQL = @SQL + ' AND FV2.mPersonalPurchaseVolume >= '+CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'DLV'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mDownLineVolume >= '+CONVERT(varchar,@QualificationValue) 
						SET @SQL = @SQL + ' AND FV2.mDownLineVolume >= '+CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'RO'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mRoyaltyOverrides + FV.mMainRoyaltyOverrides >= '+CONVERT(varchar,@QualificationValue) 
						SET @SQL = @SQL + ' AND FV2.FV.mRoyaltyOverrides + FV.mMainRoyaltyOverrides >= '+CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'PB'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mProductionBonus >= '+CONVERT(varchar,@QualificationValue) 
						SET @SQL = @SQL + ' AND FV2.mProductionBonus >= '+CONVERT(varchar,@QualificationValue)
					END
					SET @SQL = @SQL + ' AND FV.dRoyaltyMonth BETWEEN DATEADD(M,'+CONVERT(varchar,(@MonthFrequency-1))+','''+CONVERT(varchar,@ExtValidFromDate) +''') AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				END
				
				IF @QualificationFrequencyType = 2
				BEGIN
					IF @MetricType = 'TV'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mVolumePoints >= ' + CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'PPV'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mPersonalPurchaseVolume >= ' + CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'DLV'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mDownLineVolume >= ' + CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'RO'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mRoyaltyOverrides + FV.mMainRoyaltyOverrides >= ' + CONVERT(varchar,@QualificationValue)
					END	
					IF @MetricType = 'PB'
					BEGIN
						SET @SQL = @SQL + ' AND FV.mProductionBonus >= ' + CONVERT(varchar,@QualificationValue)
					END
				END
				
				END
				
				IF @QualificationFrequencyType IN (1,2)
				BEGIN
					SET @SQL = @SQL + ' GROUP BY DLL.PK_Distributor,DLL.PK_DSDownline,DLL.QualDate '	
				END
				IF @QualificationFrequencyType = 2
				BEGIN
					SET @SQL = @SQL + ' HAVING COUNT(1) >= ' + CONVERT(varchar,@MonthFrequency) + ') SLL '
				END
				
				IF @MetricType IS NOT NULL AND @MetricType != 'DL'
				BEGIN
				
				IF @QualificationFrequencyType = 1	
				BEGIN
					IF @MetricType = 'TV'
					BEGIN
						SET @SQL = @SQL + ' HAVING SUM(FV.mVolumePoints) >= ' + CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'PPV'
					BEGIN
						SET @SQL = @SQL + ' HAVING SUM(FV.mPersonalPurchaseVolume) >= ' + CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'DLV'
					BEGIN
						SET @SQL = @SQL + ' HAVING SUM(FV.mDownLineVolume) >= ' + CONVERT(varchar,@QualificationValue)
					END
					IF @MetricType = 'RO'
					BEGIN
						SET @SQL = @SQL + ' HAVING SUM(FV.mRoyaltyOverrides + FV.mMainRoyaltyOverrides) >= ' + CONVERT(varchar,@QualificationValue)
					END	
					IF @MetricType = 'PB'
					BEGIN
						SET @SQL = @SQL + ' HAVING SUM(FV.mProductionBonus) >= ' + CONVERT(varchar,@QualificationValue)
					END
					
					SET @SQL = @SQL + ' ) SLL '
				END
				
				END
				IF @QualificationFrequencyType IN (1,2)
				BEGIN
					SET @SQL = @SQL + ' GROUP BY SLL.PK_Distributor,SLL.QualDate '
				END
				
				IF @QualificationFrequencyType = 3 
				BEGIN 
					SET @SQL = @SQL + ' GROUP BY DLL.PK_Distributor,DLL.PK_DSDownline,FV.dRoyaltyMonth,DLL.QualDate '
					SET @SQL = @SQL + '	HAVING COUNT(1) = ' + CONVERT(varchar,@MonthFrequency) + ') SLL'
					SET @SQL = @SQL + ' ) SLL GROUP BY SLL.PK_Distributor,SLL.QualDate '
				END
				
				IF ISNULL(@CountMax,0) = 0
					SET @SQL = @SQL + ' HAVING COUNT(1) >= ' + CONVERT(varchar,@CountLimit) 
				ELSE
					SET @SQL = @SQL + ' HAVING COUNT(1) BETWEEN ' + CONVERT(varchar,@CountLimit) + ' AND ' + CONVERT(varchar,@CountMax)
 
			END
			
		END 

		IF EXISTS (SELECT 1 FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation IN ('SponsorDLWithLevelCMMetricC')
					AND PK_Qualification = @PK_Qualification)
           AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL --AND @QualificationValue IS NOT NULL AND @MetricType IS NOT NULL
		BEGIN
				SET @SQL = '
				WITH 
					FirstDL (PK_Distributor, PK_FirstDownline) AS 
					(
						SELECT 
							PK_Distributor
							,PK_DSDownline 
						FROM
							dbo.v_dimDSLngDownline DL
						INNER JOIN
							dbo.v_Distributor DS
						ON
							DL.PK_Distributor = DS.nDistributorID 
						WHERE ' + CASE WHEN @LevelType = 'DS' THEN 
										' DL.DSLevelFromUL BETWEEN  2 AND 2 '
									   WHEN @LevelType = 'SP' THEN 
										' DL.SPLevelFromUL BETWEEN  2 AND 2 ' 
								  END + 
								  CASE WHEN @ExtSubEventQualFilter IS NOT NULL AND @ExtSubEventQualFilter NOT IN ('TAB','NonTAB','NonFQS') THEN
									' AND DS.nDistributorCountryProcessingID IN ('+ CONVERT(varchar(100),@ExtSubEventQualFilter) +')' 
								  ELSE ' AND 1 = 1 ' END + '
					),
					LevelDL(PK_Distributor,PK_FirstDownline, PK_DSDownline) AS
					(
						SELECT 
							FL.PK_Distributor
							,FL.PK_FirstDownline
							,DL.PK_DSDownline 
						FROM
							FirstDL FL
						INNER JOIN 
							dbo.v_dimDSLngDownline DL
						ON
							FL.PK_FirstDownline = DL.PK_Distributor 
						INNER JOIN 
							dbo.v_Distributor DS 
						ON
							DL.PK_DSDownline = DS.nDistributorID 
						CROSS APPLY 
							ufn_GetConsecutive(DS.nDistributorID,''' + CONVERT(VARCHAR,@ExtValidFromDate) + ''',''' + CONVERT(varchar,@ExtValidThroughDate) + ''',' + CONVERT(varchar,@QualificationValue) + ',' + CONVERT(varchar,@MonthFrequency) + ',''' + CONVERT(varchar,@MetricType) + ''') MT
						WHERE
							'+
						CASE WHEN @LevelType = 'SP' THEN
							'DL.SPLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel) + ' AND ' + CONVERT(VARCHAR,@EndLevel) + ''
						ELSE
							'DL.DSLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel) + ' AND ' + CONVERT(VARCHAR,@EndLevel) END +
							CASE WHEN @SubEventQualFilter IS NOT NULL THEN
									' AND (DS.sType = ''' + @SubEventQualFilter + '''' +
									CASE WHEN @ExtSubEventQualFilter = 'NonFQS' THEN ' OR DS.dSupervisorQualification > MT.BeginMonth'
									END + ')'
							ELSE ' AND 1 = 1 ' END + 
							CASE WHEN @DateType = 'SPDate' THEN
									' AND DS.dSupervisorQualification BETWEEN ''' +  CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
								 WHEN @DateType = 'AppDate'	THEN 
									' AND DS.dApplication BETWEEN ''' +  CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
							ELSE ' AND 1 = 1 ' END + 
							CASE WHEN @ExtSubEventQualFilter IS NOT NULL AND @ExtSubEventQualFilter NOT IN ('TAB','NonTAB','NonFQS') THEN
									' AND DS.nDistributorCountryProcessingID IN ('+ CONVERT(varchar(100),@ExtSubEventQualFilter) +')' 
								 WHEN @ExtSubEventQualFilter = 'TAB' THEN
									' AND ISNULL(DS.sTeam,''SP'') IN (''G'',''M'',''P'',''A'',''B'',''C'')' 
								 WHEN @ExtSubEventQualFilter = 'NonTAB' THEN
									' AND ISNULL(DS.sTeam,''SP'') NOT IN (''G'',''M'',''P'',''A'',''B'',''C'')' 
								  ELSE ' AND 1 = 1 ' END + '
						GROUP BY
							FL.PK_Distributor 
							,FL.PK_FirstDownline 
							,DL.PK_DSDownline 
					), FinalCount AS
					(
							SELECT
								PK_Distributor,
								COUNT(1) AS TotalCount     
							FROM         
								LevelDL
							GROUP BY
								PK_Distributor      
					) 
				INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)' +
				' SELECT
					PK_Distributor
					,''' + CONVERT(VARCHAR,@ExtValidThroughDate) + ''' AS RoyaltyMonth
				FROM
					FinalCount ' 
			    
			    IF ISNULL(@CountMax,0) = 0
					SET @SQL = @SQL + ' WHERE TotalCount >= ' + CONVERT(varchar,@CountLimit) 
				ELSE
					SET @SQL = @SQL + ' WHERE TotalCount BETWEEN ' + CONVERT(varchar,@CountLimit) + ' AND ' + CONVERT(varchar,@CountMax)
		END
	END
	
	ELSE IF @QualificationType IN (20,21,22,23)
	BEGIN
		/*********************************************************************************************************************************************************
			This is to baseline increase based on the metric over a certain amount
		*********************************************************************************************************************************************************/
		IF @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
			AND @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
				BEGIN
					/* if a distributor is a member of the qualification */
					SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
					
					
					SET @SQL = @SQL + ' SELECT INC.PK_Distributor,' + '''' + CONVERT(varchar,@ValidThroughDate) + + ''' AS QualDate'
					SET @SQL = @SQL + ' FROM (SELECT '
					SET @SQL = @SQL + ' VL.nDistributorID AS PK_Distributor,CON.nCountryID,SUM(CASE ' + CONVERT(varchar,@QualificationType)
					SET @SQL = @SQL + ' WHEN 20 THEN VL.mVolumePoints '
					SET @SQL = @SQL + ' WHEN 21 THEN ISNULL(VL.mRoyaltyOverrides,0)+ISNULL(VL.mMainRoyaltyOverrides,0) '
					SET @SQL = @SQL + ' WHEN 22 THEN VL.mProductionBonus '
					SET @SQL = @SQL + ' WHEN 23 THEN VL.mPersonalPurchaseVolume '	
					SET @SQL = @SQL + ' END) AS IncMetric '
					SET @SQL = @SQL + ' FROM dbo.v_aggFQS_ID VL INNER JOIN dbo.v_Countries CON ON VL.sCOP = CON.sCountryCode '
					SET @SQL = @SQL + ' WHERE VL.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
					IF 	@DateType = 'Region'
					BEGIN
						SET @SQL = @SQL + ' AND CON.sRegionCode = ''' + @ExtSubEventQualFilter + ''''
					END 
					IF 	@DateType = 'Country'
					BEGIN
						SET @SQL = @SQL + ' AND CON.nCountryID IN (' + CONVERT(varchar(250),@ExtSubEventQualFilter) + ')'
					END
					SET @SQL = @SQL + ' GROUP BY VL.nDistributorID, CON.nCountryID) INC '
					SET @SQL = @SQL + ' LEFT JOIN '
					SET @SQL = @SQL + ' (SELECT '
					SET @SQL = @SQL + ' VL.nDistributorID AS PK_Distributor,CON.nCountryID,SUM(CASE ' + CONVERT(varchar,ISNULL(@CountMax,@QualificationType))
					SET @SQL = @SQL + ' WHEN 20 THEN VL.mVolumePoints '
					SET @SQL = @SQL + ' WHEN 21 THEN ISNULL(VL.mRoyaltyOverrides,0)+ISNULL(VL.mMainRoyaltyOverrides,0) '
					SET @SQL = @SQL + ' WHEN 22 THEN VL.mProductionBonus '
					SET @SQL = @SQL + ' WHEN 23 THEN VL.mPersonalPurchaseVolume '

					IF @LevelType = 'average' 
						SET @SQL = @SQL + ' END)/(DATEDIFF(MONTH, ''' + CONVERT(varchar,@ValidFromDate) + ''' , ''' + CONVERT(varchar,@ValidThroughDate) + ''')+1) AS BaseMetric '
					ELSE
						SET @SQL = @SQL + ' END) AS BaseMetric '

					SET @SQL = @SQL + ' FROM dbo.v_aggFQS_ID VL INNER JOIN dbo.v_Countries CON ON VL.sCOP = CON.sCountryCode '
					SET @SQL = @SQL + ' WHERE VL.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
					IF 	@DateType = 'Region'
					BEGIN
						SET @SQL = @SQL + ' AND CON.sRegionCode = ''' + @ExtSubEventQualFilter + ''''
					END 
					IF 	@DateType = 'Country'
					BEGIN
						SET @SQL = @SQL + ' AND CON.nCountryID IN (' + CONVERT(varchar(250),@ExtSubEventQualFilter) + ')'
					END
					SET @SQL = @SQL + ' GROUP BY VL.nDistributorID, CON.nCountryID) BASE '
					SET @SQL = @SQL + ' ON INC.PK_Distributor = BASE.PK_Distributor '
					IF @MetricType = 'Percent'
						SET @SQL = @SQL + ' WHERE ((ISNULL(INC.IncMetric,0) - ISNULL(BASE.BaseMetric,0))*100)/(CASE WHEN ISNULL(BASE.BaseMetric,0) = 0 THEN 1 ELSE BASE.BaseMetric END) >= ' + CONVERT(varchar,@QualificationValue) 
					ELSE
						SET @SQL = @SQL + '	WHERE ISNULL(INC.IncMetric,0) - ISNULL(BASE.BaseMetric,0) >= ' + CONVERT(varchar,@QualificationValue)							
					IF @KeepDNR = 0 
					BEGIN
						SET @SQL = @SQL + ' AND INC.PK_Distributor NOT IN (SELECT PK_Distributor FROM ##DNR)'
					END
				END
			ELSE
				BEGIN
					SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
					SET @SQL = @SQL + ' SELECT QD.PK_Distributor, MIN(QD.RoyaltyMonth)'
					SET @SQL = @SQL + ' FROM dbo.QualificationDistributor QD WITH (NOLOCK) '
					SET @SQL = @SQL + ' INNER JOIN dbo.v_Distributor DS ON QD.PK_Distributor = DS.nDistributorID '
					SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries CN ON DS.nDistributorCountryProcessingID = CN.nCountryID '
					SET @SQL = @SQL + ' WHERE QD.PK_Qualification = ' + CONVERT(varchar,@SPQualID)
					SET @SQL = @SQL + ' AND NOT EXISTS '
					
					SET @SQL = @SQL + '( SELECT INC.PK_Distributor,' + '''' + CONVERT(varchar,@ValidThroughDate) + + ''' AS QualDate'
					SET @SQL = @SQL + ' FROM (SELECT '
					SET @SQL = @SQL + ' VL.nDistributorID AS PK_Distributor,CON.nCountryID,SUM(CASE ' + CONVERT(varchar,@QualificationType)
					SET @SQL = @SQL + ' WHEN 20 THEN VL.mVolumePoints '
					SET @SQL = @SQL + ' WHEN 21 THEN ISNULL(VL.mRoyaltyOverrides,0)+ISNULL(VL.mMainRoyaltyOverrides,0) '
					SET @SQL = @SQL + ' WHEN 22 THEN VL.mProductionBonus '
					SET @SQL = @SQL + ' WHEN 23 THEN VL.mPersonalPurchaseVolume '	
					SET @SQL = @SQL + ' END) AS IncMetric '
					SET @SQL = @SQL + ' FROM dbo.v_aggFQS_ID VL INNER JOIN dbo.v_Countries CON ON VL.sCOP = CON.sCountryCode '
					SET @SQL = @SQL + ' WHERE VL.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
					IF 	@DateType = 'Region'
					BEGIN
						SET @SQL = @SQL + ' AND CON.sRegionCode = ''' + @ExtSubEventQualFilter + ''''
					END 
					IF 	@DateType = 'Country'
					BEGIN
						SET @SQL = @SQL + ' AND CON.nCountryID IN (' + CONVERT(varchar,@ExtSubEventQualFilter) + ')'
					END
					SET @SQL = @SQL + ' GROUP BY VL.nDistributorID, CON.nCountryID) INC '
					SET @SQL = @SQL + ' LEFT JOIN '
					SET @SQL = @SQL + ' (SELECT '
					SET @SQL = @SQL + ' VL.nDistributorID AS PK_Distributor,CON.nCountryID,SUM(CASE ' + CONVERT(varchar,@QualificationType)
					SET @SQL = @SQL + ' WHEN 20 THEN VL.mVolumePoints '
					SET @SQL = @SQL + ' WHEN 21 THEN ISNULL(VL.mRoyaltyOverrides,0)+ISNULL(VL.mMainRoyaltyOverrides,0) '
					SET @SQL = @SQL + ' WHEN 22 THEN VL.mProductionBonus '
					SET @SQL = @SQL + ' WHEN 23 THEN VL.mPersonalPurchaseVolume '	
					SET @SQL = @SQL + ' END) AS BaseMetric '
					SET @SQL = @SQL + ' FROM dbo.v_aggFQS_ID VL INNER JOIN dbo.v_Countries CON ON VL.sCOP = CON.sCountryCode '
					SET @SQL = @SQL + ' WHERE VL.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
					IF 	@DateType = 'Region'
					BEGIN
						SET @SQL = @SQL + ' AND CON.sRegionCode = ''' + @ExtSubEventQualFilter + ''''
					END 
					IF 	@DateType = 'Country'
					BEGIN
						SET @SQL = @SQL + ' AND CON.nCountryID IN (' + CONVERT(varchar,@ExtSubEventQualFilter) + ')'
					END
					SET @SQL = @SQL + ' GROUP BY VL.nDistributorID, CON.nCountryID) BASE '
					SET @SQL = @SQL + ' ON INC.PK_Distributor = BASE.PK_Distributor '
					IF @MetricType = 'Percent'
						SET @SQL = @SQL + ' WHERE ((ISNULL(INC.IncMetric,0) - ISNULL(BASE.BaseMetric,0))*100)/(CASE WHEN ISNULL(BASE.BaseMetric,0) = 0 THEN 1 ELSE BASE.BaseMetric END) >= ' + CONVERT(varchar,@QualificationValue) 
					ELSE
						SET @SQL = @SQL + '	WHERE ISNULL(INC.IncMetric,0) - ISNULL(BASE.BaseMetric,0) >= ' + CONVERT(varchar,@QualificationValue)					
					SET @SQL = @SQL + ' AND INC.PK_Distributor = QD.PK_Distributor '
					IF 	@DateType = 'Region'
					BEGIN
						SET @SQL = @SQL + ' AND CN.sRegionCode = ''' + @ExtSubEventQualFilter + ''''
					END 
					IF 	@DateType = 'Country'
					BEGIN
						SET @SQL = @SQL + ' AND CN.nCountryID IN (' + CONVERT(varchar,@ExtSubEventQualFilter) + ')'
					END
					SET @SQL = @SQL + ' ) GROUP BY QD.PK_Distributor '
				END 
		END 
	END
	
	ELSE IF @QualificationType = 24
	BEGIN
		/***************************************************************************************************************************************
			For requirements of sponsors with certain number of downlines and AWT / TAB or NON-TAB
		***************************************************************************************************************************************/
	
		IF EXISTS (SELECT 1 FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation IN ('SponsorDLDS-AWTNON-TAB','SponsorDLDS-AWTTAB')
					AND PK_Qualification = @PK_Qualification) AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
					--AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT SLL.PK_Distributor, SLL.QualDate FROM ( '
				SET @SQL = @SQL + ' SELECT DLL.PK_Distributor,DLL.QualDate, COUNT(1) AS nCnt FROM '
				IF @KeepDeleted = 1 
				BEGIN
				   SET @SQL = @SQL + ' (SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ValidThroughDate)+''' AS QualDate'
				   SET @SQL = @SQL + ' FROM dbo.v_dimDSLngDownline SP INNER JOIN dbo.v_Distributor DS ON SP.PK_Distributor = DS.nDistributorID'
				   SET @SQL = @SQL + ' INNER JOIN dbo.AWT AWT (NOLOCK) ON SP.PK_DSDownline = AWT.PK_Distributor'
				END
				ELSE
				BEGIN
				   SET @SQL = @SQL + ' (SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ValidThroughDate)+''' AS QualDate'
				   SET @SQL = @SQL + ' FROM dbo.v_dimDSLngDownline SP INNER JOIN dbo.v_DistributorCurrent DS ON SP.PK_Distributor = DS.nDistributorID'
				   SET @SQL = @SQL + ' INNER JOIN dbo.AWT AWT (NOLOCK) ON SP.PK_DSDownline = AWT.PK_Distributor'
				END
				IF @LevelType = 'isNonTAB' 
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 1'
				END
				IF @LevelType = 'isTAB' 
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 0'
				END
				
				SET @SQL = @SQL + ' WHERE SP.PK_Distributor <> SP.PK_DSDownline '	-- To Exclude Self
				SET @SQL = @SQL + ' AND SP.SPLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1) 

				IF @QualificationValue IS NOT NULL
					SET @SQL = @SQL + ' AND AWT.AWTYear = '+ CONVERT(varchar,@QualificationValue) 
				
				SET @SQL = @SQL + ' AND AWT.Qual_AWT BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''

				IF @ExtSubEventQualFilter IS NOT NULL								-- To Filter By COP
				BEGIN
					SET @SQL = @SQL + ' AND DS.nDistributorCountryProcessingID IN (' + CONVERT(varchar,@ExtSubEventQualFilter) + ')'
				END
				
				IF ISNULL(@MetricType,'XX') = 'FirstTime'
					SET @SQL = @SQL + ' AND SP.PK_DSDownline NOT IN (SELECT PK_Distributor FROM AWT A (NOLOCK) WHERE A.AWTYear NOT IN ('+ CONVERT(varchar,@QualificationValue)+'))'
				
				SET @SQL = @SQL + ' ) DLL '
		
				SET @SQL = @SQL + ' GROUP BY DLL.PK_Distributor,DLL.QualDate) SLL '
				IF ISNULL(@CountMax,0) = 0
					SET @SQL = @SQL + ' WHERE SLL.nCnt >= ' + CONVERT(varchar,@CountLimit) 
				ELSE
					SET @SQL = @SQL + ' WHERE SLL.nCnt BETWEEN ' + CONVERT(varchar,@CountLimit) + ' AND ' + CONVERT(varchar,@CountMax)
  
			END

		END
		
		IF EXISTS (SELECT 1 FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation IN ('SponsorDLDSWithTickets')
					AND PK_Qualification = @PK_Qualification) AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
					AND @LevelType IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT SLL.PK_Distributor, SLL.QualDate FROM ( '
				SET @SQL = @SQL + ' SELECT DLL.PK_Distributor,DLL.QualDate, COUNT(1) AS nCnt FROM ('
				IF @KeepDeleted = 1 
				BEGIN
				   SET @SQL = @SQL + ' SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ValidThroughDate)+''' AS QualDate'
				   SET @SQL = @SQL + ' FROM dbo.v_dimDSLngDownline SP INNER JOIN dbo.v_Distributor DS ON SP.PK_Distributor = DS.nDistributorID'
				   SET @SQL = @SQL + ' INNER JOIN dbo.SKUPurchased S (NOLOCK) ON SP.PK_DSDownline = S.PK_Distributor_Purchaser'
				   SET @SQL = @SQL + ' INNER JOIN dbo.v_Distributor DL (NOLOCK) ON SP.PK_DSDownline = DL.nDistributorID'
				END
				ELSE
				BEGIN
				   SET @SQL = @SQL + ' SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ValidThroughDate)+''' AS QualDate'
				   SET @SQL = @SQL + ' FROM dbo.v_dimDSLngDownline SP INNER JOIN dbo.v_DistributorCurrent DS ON SP.PK_Distributor = DS.nDistributorID'
				   SET @SQL = @SQL + ' INNER JOIN dbo.SKUPurchased S (NOLOCK) ON SP.PK_DSDownline = S.PK_Distributor_Purchaser'
				   SET @SQL = @SQL + ' INNER JOIN dbo.v_DistributorCurrent DL (NOLOCK) ON SP.PK_DSDownline = DL.nDistributorID'
				END
				
				IF @MetricType = 'NoTeam' 
				BEGIN
					SET @SQL = @SQL + ' AND ISNULL(DL.sTeam,''SP'') NOT IN (''W'',''G'',''M'',''P'',''A'',''B'',''C'')' 
				END
				
				IF @MetricType = 'NoTABTeam' 
				BEGIN
					SET @SQL = @SQL + ' AND ISNULL(DL.sTeam,''SP'') NOT IN (''G'',''M'',''P'',''A'',''B'',''C'')' 
				END
				
				IF @MetricType = 'TABTeam' 
				BEGIN
					SET @SQL = @SQL + ' AND ISNULL(DL.sTeam,''SP'') IN (''G'',''M'',''P'',''A'',''B'',''C'')' 
				END
				
				SET @SQL = @SQL + ' WHERE SP.PK_Distributor <> SP.PK_DSDownline '	-- To Exclude Self
				IF @LevelType = 'DS'												-- To Determine whether DS or SP Level to use
				BEGIN
					SET @SQL = @SQL + ' AND SP.DSLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)
				END
				ELSE
				BEGIN
					SET @SQL = @SQL + ' AND SP.SPLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)
				END

				SET @SQL = @SQL + ' AND S.PK_Event = ' + CONVERT(varchar,@EventID)

				IF @QualificationValue IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + ' AND S.PK_EventSKU = ' + CONVERT(varchar,@QualificationValue)
				END

				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND S.OrderDate >= ''' + CONVERT(varchar,@ValidFromDate) + ''' AND S.OrderDate <= ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END

				IF @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND DL.dSupervisorQualification BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				END

				IF @ExtSubEventQualFilter IS NOT NULL								-- To Filter By COP
				BEGIN
					SET @SQL = @SQL + ' AND DS.nDistributorCountryProcessingID IN (' + CONVERT(varchar,@ExtSubEventQualFilter) + ')'
				END
				
				IF @KeepDNR = 0 
				BEGIN
					SET @SQL = @SQL + ' AND S.PK_Distributor_Purchaser NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

				SET @SQL = @SQL + ' GROUP BY SP.PK_Distributor,SP.PK_DSDownline) DLL '
		
				SET @SQL = @SQL + ' GROUP BY DLL.PK_Distributor,DLL.QualDate) SLL '

				SET @SQL = @SQL + ' WHERE SLL.nCnt >= ' + CONVERT(varchar,@CountLimit) 
  
			END

		END  
	END
	
	ELSE IF @QualificationType = 12
	BEGIN
		/*********************************************************************************************************************************************************
			For Special cases where SP Qual Date and RO for the Qual Date are compared. That is, RO for the month of SP Qualification.
			@QualificationType=12: @QualificationValue MUST BE PROVIDED IN THE SETUP.
			This assumes that qualification will always be for members who meet the qualification type 
		*********************************************************************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'SPQualDateAndRO')
           AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
				BEGIN
					/* if a distributor is a member of the qualification */
					SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
					SET @SQL = @SQL + ' SELECT S.nDistributorID, S.dSPQualDate '
					SET @SQL = @SQL + ' FROM (SELECT D.nDistributorID,ISNULL(D.dSupervisorQualification,''1900-01-01'') dSPQualDate '
					IF @KeepDeleted = 0 
						BEGIN
							SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent D'
						END
					ELSE
						BEGIN
							SET @SQL = @SQL + ' FROM dbo.v_Distributor D'
						END
					IF @SubEventQualFilter IS NOT NULL -- This is where the qualification may apply filter by country for this QualType.
						BEGIN
							SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C '
							SET @SQL = @SQL + ' ON D.sDistributorCountryProcessingCode = C.sCountryCode '
							SET @SQL = @SQL + ' AND C.nCountryID = ' +  CONVERT(varchar,@SubEventQualFilter)
						END

					SET @SQL = @SQL + ' WHERE sType IN (''SP'',''RB'',''RS'') ) S '
					SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID AGG '
					SET @SQL = @SQL + ' ON AGG AGG.nDistributorID = S.nDistributorID '
					SET @SQL = @SQL + ' WHERE AGG.dRoyaltyMonth = convert(datetime,CONVERT(char(6), S.dSPQualDate , 112) + ''01'')'
					SET @SQL = @SQL + ' AND AGG.mRoyaltyOverrides + AGG.mMainRoyaltyOverrides >= ' + CONVERT(varchar,@QualificationValue)
					
					IF @KeepDNR = 0 
					BEGIN
						SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
					END

				END 
			    
		END 

	END 

	ELSE IF @QualificationType = 25
	BEGIN
	/*************************************************************************************************	 
		Accumulate Combined TVP and RO  Between Perdiod ValidFromDate to ValidThroughDate 
	*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'CombineTVPandRO')
		AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, ''' + CONVERT(varchar,@ValidThroughDate) + ''' AS QualDate'
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID AGG 
										ON S.nDistributorID = AGG.nDistributorID 
										WHERE AGG.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				
				IF @SubEventQualFilter = 'VP2'
					SET @SQL = @SQL + ' GROUP BY S.nDistributorID '	
								+ 'HAVING SUM(ISNULL(AGG.mVolumePoints*2,0) + ISNULL(AGG.mRoyaltyOverrides,0) + ISNULL(AGG.mMainRoyaltyOverrides,0)) >= ' + CONVERT(varchar,@QualificationValue)
				ELSE IF @SubEventQualFilter = 'VP3'
					SET @SQL = @SQL + ' GROUP BY S.nDistributorID '	
								+ 'HAVING SUM(ISNULL(AGG.mVolumePoints*3,0) + ISNULL(AGG.mRoyaltyOverrides,0) + ISNULL(AGG.mMainRoyaltyOverrides,0)) >= ' + CONVERT(varchar,@QualificationValue)
				ELSE IF @SubEventQualFilter = 'PPVDLV'
					SET @SQL = @SQL + ' GROUP BY S.nDistributorID '	
								+ 'HAVING SUM(ISNULL(AGG.mPersonalPurchaseVolume,0) + ISNULL(AGG.mDownlineVolume,0)) >= ' + CONVERT(varchar,@QualificationValue)
				ELSE
					SET @SQL = @SQL + ' GROUP BY S.nDistributorID '	
								+ 'HAVING SUM(ISNULL(AGG.mVolumePoints,0) + ISNULL(AGG.mRoyaltyOverrides,0) + ISNULL(AGG.mMainRoyaltyOverrides,0)) >= ' + CONVERT(varchar,@QualificationValue)
			END ELSE
			BEGIN
				/* if a distributor is a NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, ''' + CONVERT(varchar,@ValidThroughDate) + ''' AS QualDate'
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END
				SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID AGG 
										ON S.nDistributorID = AGG.nDistributorID AND S.sType = ''' + 'SP' + '''
										WHERE AGG.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				
				IF @SubEventQualFilter = 'VP2'
					SET @SQL = @SQL + ' GROUP BY S.nDistributorID '	
								+ 'HAVING SUM(ISNULL(AGG.mVolumePoints*2,0) + ISNULL(AGG.mRoyaltyOverrides,0) + ISNULL(AGG.mMainRoyaltyOverrides,0)) < ' + CONVERT(varchar,@QualificationValue)
				ELSE
					SET @SQL = @SQL + ' GROUP BY S.nDistributorID '	
								+ 'HAVING SUM(ISNULL(AGG.mVolumePoints,0) + ISNULL(AGG.mRoyaltyOverrides,0) + ISNULL(AGG.mMainRoyaltyOverrides,0)) < ' + CONVERT(varchar,@QualificationValue)
			END
		END
		
		/*****************************************************************************************************************	 
			Accumulate Combined TVP and PPV Between Perdiod ValidFromDate to ValidThroughDate and based on Qual SP Date 
		*****************************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'CombinedPPVandTVP')
		AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL AND @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, ''' + CONVERT(varchar,@ValidThroughDate) + ''' AS QualDate'

				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				
				   
				SET @SQL = @SQL +	'LEFT JOIN
										(
											SELECT
												nDistributorID,ISNULL(SUM(mPersonalPurchaseVolume),0) AS PPV
											FROM
												dbo.v_aggFQS_ID 
											WHERE
												dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND CASE WHEN dQual_SP > ''' + CONVERT(varchar,@ValidThroughDate) + '''
												THEN ''' + CONVERT(varchar,@ValidThroughDate) + ''' ELSE DATEADD(mm,-1,dQual_SP) END
											GROUP BY
												nDistributorID
										) A	
									ON
										S.nDistributorID = A.nDistributorID
									LEFT JOIN
										(
											SELECT
												nDistributorID,SUM(mVolumePoints) AS TVP
											FROM
												dbo.v_aggFQS_ID 
											WHERE
												dRoyaltyMonth BETWEEN CASE WHEN dQual_SP < ''' + CONVERT(varchar,@ValidFromDate) + '''
												THEN ''' + CONVERT(varchar,@ValidFromDate) + ''' ELSE dQual_SP END AND ''' + CONVERT(varchar,@ValidThroughDate) + '''
											GROUP BY
												nDistributorID
										) B
									ON
										S.nDistributorID = B.nDistributorID'
				IF @ExtSubEventQualFilter IS NOT NULL
					SET @SQL = @SQL +	' WHERE
										S.nDistributorCountryProcessingID IN (' + CONVERT(VARCHAR,@ExtSubEventQualFilter) + ')'
				SET @SQL = @SQL +	'	GROUP BY
										S.nDistributorID,A.PPV,B.TVP
										HAVING
										ISNULL(A.PPV,0) + ISNULL(B.TVP,0) >= ' + CONVERT(varchar,@QualificationValue)
			END
		END
	END
	ELSE IF @QualificationType = 26
	BEGIN
		/***************************************************************************************************************************************
			Bonus for every AWT downline 
		***************************************************************************************************************************************/
	
		IF EXISTS (SELECT 1 FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation IN ('ACCTVPAWTBonus')
					AND PK_Qualification = @PK_Qualification) AND @SubEventQualFilter IS NOT NULL AND @MetricType IS NOT NULL 
					AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT SLL.PK_Distributor, SLL.QualDate FROM ( '
				SET @SQL = @SQL + ' SELECT DLL.PK_Distributor,DLL.QualDate, COUNT(1) AS nCnt, DLL.mTV FROM '

				/* ************ SonarQ check 48 - All branches in a conditional structure should not have exactly the same implementation */
				----IF @KeepDeleted = 1 
				----BEGIN
				   SET @SQL = @SQL + ' (SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ValidThroughDate)+''' AS QualDate, MIN(DS.mTV) AS mTV FROM'
				   SET @SQL = @SQL + ' (SELECT DS.nDistributorID, min(DS.nDistributorCountryProcessingID) nDistributorCountryProcessingID, SUM(F.mVolumePoints) AS mTV
										FROM dbo.v_DistributorCurrent DS INNER JOIN dbo.v_aggFQS_ID F (NOLOCK) ON DS.nDistributorID = F.nDistributorID
										WHERE F.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				   SET @SQL = @SQL + '	GROUP BY DS.nDistributorID) DS'
				   SET @SQL = @SQL + ' INNER JOIN dbo.v_dimDSLngDownline SP ON SP.PK_Distributor = DS.nDistributorID'
				   --SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID F (NOLOCK) ON SP.PK_Distributor = F.nDistributorID'
				   SET @SQL = @SQL + ' INNER JOIN dbo.AWT AWT (NOLOCK) ON SP.PK_DSDownline = AWT.PK_Distributor'
				----END
				----ELSE
				----BEGIN
				----   SET @SQL = @SQL + ' (SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ValidThroughDate)+''' AS QualDate, MIN(DS.mTV) AS mTV FROM'
				----   SET @SQL = @SQL + ' (SELECT DS.nDistributorID, min(DS.nDistributorCountryProcessingID) nDistributorCountryProcessingID, SUM(F.mVolumePoints) AS mTV
				----						FROM dbo.v_DistributorCurrent DS INNER JOIN dbo.v_aggFQS_ID F (NOLOCK) ON DS.nDistributorID = F.nDistributorID
				----						WHERE F.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				----   SET @SQL = @SQL + '	GROUP BY DS.nDistributorID) DS'
				----   SET @SQL = @SQL + ' INNER JOIN dbo.v_dimDSLngDownline SP ON SP.PK_Distributor = DS.nDistributorID'
				----   --SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID F (NOLOCK) ON SP.PK_Distributor = F.nDistributorID'
				----   SET @SQL = @SQL + ' INNER JOIN dbo.AWT AWT (NOLOCK) ON SP.PK_DSDownline = AWT.PK_Distributor'
				----END
				/* ************ SonarQ check 48 */
				
				IF @LevelType = 'isNonTAB' 
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 1'
				END
				IF @LevelType = 'isTAB' 
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 0'
				END
				
				IF @DateType = 'PQAWT'
				BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.AWT PAW (NOLOCK) ON SP.PK_Distributor = PAW.PK_Distributor' 
					
					IF @QualificationValue IS NOT NULL
						SET @SQL = @SQL + ' AND PAW.AWTYear = '+ CONVERT(varchar,@QualificationValue)

					IF @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
						SET @SQL = @SQL + ' AND PAW.Qual_AWT BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				END

				SET @SQL = @SQL + ' WHERE SP.PK_Distributor <> SP.PK_DSDownline '	-- To Exclude Self
				
				IF @LevelType = 'DS'												-- To Determine whether DS or SP Level to use
					SET @SQL = @SQL + ' AND SP.DSLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)
				ELSE
					SET @SQL = @SQL + ' AND SP.SPLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)

				
				IF @QualificationValue IS NOT NULL
					SET @SQL = @SQL + ' AND AWT.AWTYear = '+ CONVERT(varchar,@QualificationValue)
				
				
				IF @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
					SET @SQL = @SQL + ' AND AWT.Qual_AWT BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''

				IF @ExtSubEventQualFilter IS NOT NULL								-- To Filter By COP
				BEGIN
					SET @SQL = @SQL + ' AND DS.nDistributorCountryProcessingID IN (' + CONVERT(varchar,@ExtSubEventQualFilter) + ')'
				END
				
				SET @SQL = @SQL + ' GROUP BY SP.PK_Distributor,SP.PK_DSDownline) DLL '
		
				SET @SQL = @SQL + ' GROUP BY DLL.PK_Distributor,DLL.QualDate,DLL.mTV  
									HAVING (COUNT(1)*'+CONVERT(varchar,@SubEventQualFilter)+')+DLL.mTV >= '+ CONVERT(varchar,@MetricType)+'	
				) SLL '
				
  
			END
			ELSE
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT SLL.PK_Distributor, SLL.QualDate FROM ( '
				SET @SQL = @SQL + ' SELECT DLL.PK_Distributor,DLL.QualDate, COUNT(1) AS nCnt, DLL.mTV FROM '

				/* ************ SonarQ check 49 - All branches in a conditional structure should not have exactly the same implementation */
				----IF @KeepDeleted = 1 
				----BEGIN
				   SET @SQL = @SQL + ' (SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ValidThroughDate)+''' AS QualDate, MIN(DS.mTV) AS mTV FROM'
				   SET @SQL = @SQL + ' (SELECT DS.nDistributorID, min(DS.nDistributorCountryProcessingID) nDistributorCountryProcessingID, SUM(F.mVolumePoints) AS mTV
										FROM dbo.v_DistributorCurrent DS INNER JOIN dbo.v_aggFQS_ID F (NOLOCK) ON DS.nDistributorID = F.nDistributorID
										WHERE F.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				   SET @SQL = @SQL + '	GROUP BY DS.nDistributorID) DS'
				   SET @SQL = @SQL + ' INNER JOIN dbo.v_dimDSLngDownline SP ON SP.PK_Distributor = DS.nDistributorID'
				   --SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID F (NOLOCK) ON SP.PK_Distributor = F.nDistributorID'
				   SET @SQL = @SQL + ' INNER JOIN dbo.AWT AWT (NOLOCK) ON SP.PK_DSDownline = AWT.PK_Distributor'
				----END
				----ELSE
				----BEGIN
				----   SET @SQL = @SQL + ' (SELECT SP.PK_Distributor,SP.PK_DSDownline,'''+CONVERT(varchar,@ValidThroughDate)+''' AS QualDate, MIN(DS.mTV) AS mTV FROM'
				----   SET @SQL = @SQL + ' (SELECT DS.nDistributorID, min(DS.nDistributorCountryProcessingID) nDistributorCountryProcessingID, SUM(F.mVolumePoints) AS mTV
				----						FROM dbo.v_DistributorCurrent DS INNER JOIN dbo.v_aggFQS_ID F (NOLOCK) ON DS.nDistributorID = F.nDistributorID
				----						WHERE F.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				----   SET @SQL = @SQL + '	GROUP BY DS.nDistributorID) DS'
				----   SET @SQL = @SQL + ' INNER JOIN dbo.v_dimDSLngDownline SP ON SP.PK_Distributor = DS.nDistributorID'
				----   --SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID F (NOLOCK) ON SP.PK_Distributor = F.nDistributorID'
				----   SET @SQL = @SQL + ' INNER JOIN dbo.AWT AWT (NOLOCK) ON SP.PK_DSDownline = AWT.PK_Distributor'
				----END
				/* ************ SonarQ check 49 */
				
				IF @LevelType = 'isNonTAB' 
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 1'
				END
				IF @LevelType = 'isTAB' 
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 0'
				END
				
				IF @DateType = 'PQAWT'
				BEGIN
					SET @SQL = @SQL + ' INNER JOIN dbo.AWT PAW (NOLOCK) ON SP.PK_Distributor = PAW.PK_Distributor AND PAW.AWTYear = '+ CONVERT(varchar,@QualificationValue)

					IF @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
						SET @SQL = @SQL + ' AND PAW.Qual_AWT BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				END

				SET @SQL = @SQL + ' WHERE SP.PK_Distributor <> SP.PK_DSDownline '	-- To Exclude Self
				SET @SQL = @SQL + ' AND SP.SPLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1) 
				SET @SQL = @SQL + ' AND AWT.AWTYear = '+ CONVERT(varchar,@QualificationValue)
				
				IF @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
					SET @SQL = @SQL + ' AND AWT.Qual_AWT BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''

				IF @ExtSubEventQualFilter IS NOT NULL								-- To Filter By COP
				BEGIN
					SET @SQL = @SQL + ' AND DS.nDistributorCountryProcessingID IN (' + CONVERT(varchar,@ExtSubEventQualFilter) + ')'
				END
				
				SET @SQL = @SQL + ' GROUP BY SP.PK_Distributor,SP.PK_DSDownline) DLL '
		
				SET @SQL = @SQL + ' GROUP BY DLL.PK_Distributor,DLL.QualDate,DLL.mTV  
									HAVING (COUNT(1)*'+CONVERT(varchar,@SubEventQualFilter)+')+DLL.mTV < '+ CONVERT(varchar,@MetricType)+'	
				) SLL '
				
  
			END

		END  
	END
	ELSE IF @QualificationType = 27
	BEGIN
		/***************************************************************************************************************************************
			Achieve certein metric First Time Ever
		***************************************************************************************************************************************/
	
		IF EXISTS (SELECT 1 FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation IN ('FirstTimeMetricAchiever')
					AND PK_Qualification = @PK_Qualification) AND @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL 
					AND @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL AND @SubEventQualFilter IS NOT NULL AND @MetricType IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AS QualDate'
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END
				SET @SQL = @SQL + ' INNER JOIN dbo.QualificationDistributor QD WITH (NOLOCK) 
										ON S.nDistributorID = QD.PK_Distributor 
										WHERE QD.PK_Qualification = '+ CONVERT(varchar,@SubEventQualFilter) +' AND QD.RoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				
				IF @ExtSubEventQualFilter IS NOT NULL  
					SET @SQL = @SQL + ' AND S.nDistributorCountryProcessingID IN ('+ CONVERT(varchar(100),@ExtSubEventQualFilter) +')'
				
				IF @MonthFrequency IS NULL
				BEGIN	
					SET @SQL = @SQL + '	EXCEPT
										SELECT DISTINCT nDistributorID AS PK_Distributor,''' + CONVERT(varchar,@ExtValidFromDate) + ''' AS QualDate FROM dbo.v_aggFQS_ID '

					SET @SQL = @SQL + '	WHERE dRoyaltyMonth BETWEEN '''+ CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''

				
					IF @MetricType = 'TV'
						BEGIN
							SET @SQL = @SQL + ' AND mVolumePoints >= ' + CONVERT(varchar,@QualificationValue)
						END
						IF @MetricType = 'PPV'
						BEGIN
							SET @SQL = @SQL + ' AND mPersonalPurchaseVolume >= ' + CONVERT(varchar,@QualificationValue)
						END
						IF @MetricType = 'DLV'
						BEGIN
							SET @SQL = @SQL + ' AND mDownLineVolume >= ' + CONVERT(varchar,@QualificationValue)
						END
						IF @MetricType = 'RO'
						BEGIN
							SET @SQL = @SQL + ' AND (mRoyaltyOverrides + mMainRoyaltyOverrides) >= ' + CONVERT(varchar,@QualificationValue)
						END	
						IF @MetricType = 'PB'
						BEGIN
							SET @SQL = @SQL + ' AND mProductionBonus >= ' + CONVERT(varchar,@QualificationValue)
						END
				END
				ELSE
				BEGIN
					SET @SQL = @SQL + '	EXCEPT
										SELECT 
											PK_Distributor,
											''' + CONVERT(varchar,@ExtValidFromDate) + '''
										FROM 
											ufn_GetASP ('''+ CONVERT(varchar,@ValidFromDate) + ''',''' + CONVERT(varchar,@ValidThroughDate) + ''','+CONVERT(varchar,@QualificationValue)+',''' + CONVERT(varchar,@MonthFrequency) + ''',''' + CONVERT(varchar,@MetricType) + ''',' + CONVERT(varchar,ISNULL(@ExtSubEventQualFilter,'NULL')) + ')  '
				END
			END

		END 
		
		IF EXISTS (SELECT 1 FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation IN ('FirstTimeDLMetricAchiever')
					AND PK_Qualification = @PK_Qualification) AND @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL 
					AND @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL AND @SubEventQualFilter IS NOT NULL AND @MetricType IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT DISTINCT SLL.nDistributorID, ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AS QualDate FROM ('
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + 'SELECT S.nDistributorID FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + 'SELECT S.nDistributorID FROM dbo.v_Distributor S '
				END


				SET @SQL = @SQL + ' INNER JOIN dbo.v_dimDSLngDownline SP ON SP.PK_Distributor = S.nDistributorID 
									INNER JOIN dbo.QualificationDistributor QD WITH (NOLOCK) 
										ON SP.PK_DSDownline = QD.PK_Distributor 
										WHERE QD.PK_Qualification = '+ CONVERT(varchar,@SubEventQualFilter) +' AND QD.RoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				
				IF @ExtSubEventQualFilter IS NOT NULL  
					SET @SQL = @SQL + ' AND S.nDistributorCountryProcessingID IN ('+ CONVERT(varchar(100),@ExtSubEventQualFilter) +')'
				

				SET @SQL = @SQL + ' AND SP.PK_Distributor <> SP.PK_DSDownline '	-- To Exclude Self
				IF @LevelType = 'DS'												-- To Determine whether DS or SP Level to use
				BEGIN
					SET @SQL = @SQL + ' AND SP.DSLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)
				END
				ELSE
				BEGIN
					SET @SQL = @SQL + ' AND SP.SPLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)
				END

				IF @MonthFrequency IS NULL
				BEGIN	
					SET @SQL = @SQL + '	AND	NOT EXISTS (
										SELECT 1 FROM dbo.v_aggFQS_ID A '

					SET @SQL = @SQL + '	WHERE dRoyaltyMonth BETWEEN '''+ CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''

				
					IF @MetricType = 'TV'
						BEGIN
							SET @SQL = @SQL + ' AND mVolumePoints >= ' + CONVERT(varchar,@QualificationValue)
						END
						IF @MetricType = 'PPV'
						BEGIN
							SET @SQL = @SQL + ' AND mPersonalPurchaseVolume >= ' + CONVERT(varchar,@QualificationValue)
						END
						IF @MetricType = 'DLV'
						BEGIN
							SET @SQL = @SQL + ' AND mDownLineVolume >= ' + CONVERT(varchar,@QualificationValue)
						END
						IF @MetricType = 'RO'
						BEGIN
							SET @SQL = @SQL + ' AND (mRoyaltyOverrides + mMainRoyaltyOverrides) >= ' + CONVERT(varchar,@QualificationValue)
						END	
						IF @MetricType = 'PB'
						BEGIN
							SET @SQL = @SQL + ' AND mProductionBonus >= ' + CONVERT(varchar,@QualificationValue)
						END

						SET @SQL = @SQL + ' AND SP.PK_DSDownline = A.nDistributorID)'

						SET @SQL = @SQL + ' GROUP BY S.nDistributorID
											HAVING COUNT(DISTINCT SP.PK_DSDownline) > = ' + CONVERT(varchar,@CountLimit) + ' 
											) SLL'
				END
			END

		END
		 
	END	
	
	ELSE IF @QualificationType = 28
	BEGIN
	/*************************************************************************************************	 
		Strictly for determining repeat AWT qualifiers within a specific month
	*************************************************************************************************/
		IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL AND @QualificationValue IS NOT NULL
		BEGIN
		
			SET @MonthsPointer = DATEPART(MONTH,CONVERT(varchar,@ValidFromDate))
			SET @MonthsTotal = 0
			SET @MonthsString = ''

			IF  DATEPART(YEAR,CONVERT(varchar,@ValidFromDate)) = DATEPART(YEAR,CONVERT(varchar,@ValidThroughDate))
				SET @MonthsTotal = (CONVERT (int, DATEPART(MONTH,CONVERT(varchar,@ValidThroughDate))) - CONVERT (int, @MonthsPointer))+1										
			ELSE
				SET @MonthsTotal = 12 - CONVERT (int, @MonthsPointer) +1						
					
				SET @MonthsString = ' AND ('

				WHILE  @MonthsTotal > 0
					BEGIN
						SET @MonthsTotal = @MonthsTotal -1
						
						SET @MonthsString = @MonthsString +( CASE @MonthsPointer
								WHEN 1  THEN ' JAN=1 '
								WHEN 2  THEN ' FEB=1 '	
								WHEN 3  THEN ' MAR=1 '
								WHEN 4  THEN ' APR=1 '
								WHEN 5  THEN ' MAY=1 '
								WHEN 6  THEN ' JUN=1 ' 
								WHEN 7  THEN ' JUL=1 ' 
								WHEN 8  THEN ' AUG=1 '
								WHEN 9  THEN ' SEP=1 '
								WHEN 10 THEN ' OCT=1 '
								WHEN 11 THEN ' NOV=1 '
								WHEN 12 THEN ' DEC=1 '
						END)

							SET @MonthsPointer = @MonthsPointer + 1

							IF @MonthsTotal > 0
									SET @MonthsString= @MonthsString +' OR '
							ELSE
									SET @MonthsString= @MonthsString +' ) '
				END	

			IF @IsQualMember = 1			
			BEGIN
				/* if a distributor is a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, ''' + CONVERT(varchar,@ValidThroughDate) + ''' AS QualDate'
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END		

				SET @SQL = @SQL + ' INNER JOIN dbo.AWT_Qualifiers_Tracking AWT (NOLOCK)
										ON S.nDistributorID = AWT.PK_Distributor
										AND AWT.AWTYear = ' + CONVERT(varchar,@QualificationValue) + 
									    @MonthsString +
									  ' WHERE 1 = 1 '

				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				
			END ELSE
			BEGIN
				/* if a distributor is a NOT a member of the qualification */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID, ''' + CONVERT(varchar,@ValidThroughDate) + ''' AS QualDate'
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END
				SET @SQL = @SQL + ' WHERE NOT EXISTS (SELECT 1 FROM dbo.AWT_Qualifiers_Tracking AWT (NOLOCK) 
										WHERE S.nDistributorID = AWT.PK_Distributor 
										AND AWT.AWTYear = ' + CONVERT(varchar,@QualificationValue) +
										@MonthsString +')'
										
				IF @KeepDNR = 0 BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

			END
		END 
		
	END
	
	ELSE IF @QualificationType = 29
	BEGIN
	/*************************************************************************************************	 
		Strictly for determining first time AWT qualifiers 
	*************************************************************************************************/
		IF @QualificationValue IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if a first time AWT qualifier for that AWT year */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,AWT.Qual_AWT AS QualDate'
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END
				SET @SQL = @SQL + ' INNER JOIN dbo.AWT AWT (NOLOCK)
										ON S.nDistributorID = AWT.PK_Distributor
										AND AWT.AWTYear = ' + CONVERT(varchar,@QualificationValue)  
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND AWT.Qual_AWT BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END						
				SET @SQL = @SQL + ' WHERE AWT.PastAWT = ''' + 'No' + ''''	
				
				IF @LevelType = 'NonTAB'
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 1'
				END
				ELSE IF @LevelType = 'TAB'
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 0'
				END
				
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' AND AWT.IsDeleted = 0 '
				END					  
				IF @KeepDNR = 0 
				BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				
			END ELSE
			BEGIN
				/* if an AWT qualifier but not a first time AWT qualifier */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,AWT.Qual_AWT AS QualDate'
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END
				SET @SQL = @SQL + ' INNER JOIN dbo.AWT AWT (NOLOCK)
										ON S.nDistributorID = AWT.PK_Distributor
										AND AWT.AWTYear = ' + CONVERT(varchar,@QualificationValue)  
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND AWT.Qual_AWT BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END						
				SET @SQL = @SQL + ' WHERE AWT.PastAWT <> ''' + 'No' + ''''						
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' AND AWT.IsDeleted = 0 '
				END					  
				IF @KeepDNR = 0 
				BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

			END
		END 
		
	END
	
	ELSE IF @QualificationType = 30
	BEGIN
		/*************************************************************************************************	 
			Strictly for determining downlines by line for a metric 
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DownlineByLine')
           AND @QualificationValue IS NOT NULL AND @MetricType IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = '
				WITH 
					FirstDL (PK_Distributor, PK_FirstDownline) AS 
					(
						SELECT 
							PK_Distributor
							,PK_DSDownline 
						FROM
							dbo.v_dimDSLngDownline DL
						INNER JOIN
							dbo.v_Distributor DS
						ON
							DL.PK_DSDownline = DS.nDistributorID 
						WHERE ' + CASE WHEN @LevelType = 'DS' THEN 
										' DL.DSLevelFromUL BETWEEN  2 AND 2 '
									   WHEN @LevelType = 'SP' THEN 
										' DL.SPLevelFromUL BETWEEN  2 AND 2 ' 
								  END + '
					),
					LevelDL(PK_Distributor,PK_FirstDownline, PK_DSDownline, Metric, TotalSP) AS
					(
						SELECT 
							FL.PK_Distributor
							,FL.PK_FirstDownline
							,DL.PK_DSDownline 
							,' + CASE WHEN @MetricType = 'PPV' THEN 
											' SUM(MT.mPersonalPurchaseVolume) ' 
									  WHEN @MetricType = 'TV' THEN 
											' SUM(MT.mVolumePoints) '
									  WHEN @MetricType = 'RO' THEN 
											' SUM(ISNULL(MT.mRoyaltyOverrides,0) + ISNULL(MT.mMainRoyaltyOverrides,0)) '
									  WHEN @MetricType = 'PB' THEN 
											' SUM(ISNULL(MT.mProductionBonus,0)) '
								  END + 'AS Metric  
							,COUNT(DISTINCT DL.PK_DSDownline) AS TotalSP
						FROM
							FirstDL FL
						INNER JOIN 
							dbo.v_dimDSLngDownline DL
						ON
							FL.PK_FirstDownline = DL.PK_Distributor 
						INNER JOIN 
							dbo.v_Distributor DS 
						ON
							DL.PK_DSDownline = DS.nDistributorID 
						LEFT JOIN 
							dbo.v_aggFQS_ID MT
						ON
							DL.PK_DSDownline = MT.nDistributorID 
							AND
							MT.dRoyaltyMonth BETWEEN ''' + CONVERT(VARCHAR,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + '''
						WHERE
							'+
						CASE WHEN @LevelType = 'SP' THEN
							'DL.SPLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel) + ' AND ' + CONVERT(VARCHAR,@EndLevel) + ''
						ELSE
							'DL.DSLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel) + ' AND ' + CONVERT(VARCHAR,@EndLevel) END +
							CASE WHEN @SubEventQualFilter IS NOT NULL THEN
									' AND DS.sType = ''' + @SubEventQualFilter + '''' 
							ELSE ' AND 1 = 1 ' END + 
							CASE WHEN @DateType = 'SPDate' THEN
									' AND DS.dSupervisorQualification BETWEEN ''' +  CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
								 WHEN @DateType = 'AppDate'	THEN 
									' AND DS.dApplication BETWEEN ''' +  CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
							ELSE ' AND 1 = 1 ' END + 
							CASE WHEN @ExtSubEventQualFilter IS NOT NULL THEN
									' AND DS.nDistributorCountryProcessingID IN ('+ CONVERT(varchar,@ExtSubEventQualFilter) +')' 
							ELSE ' AND 1 = 1 ' END +	
								'
						GROUP BY
							FL.PK_Distributor 
							,FL.PK_FirstDownline 
							,DL.PK_DSDownline 
						HAVING ' + 
							CASE WHEN @MetricType = 'PPV' THEN 
									' SUM(MT.mPersonalPurchaseVolume) ' 
								 WHEN @MetricType = 'TV' THEN 
									' SUM(MT.mVolumePoints) ' 
								 WHEN @MetricType = 'RO' THEN
									' SUM(ISNULL(MT.mRoyaltyOverrides,0) + ISNULL(MT.mMainRoyaltyOverrides,0)) '
								 WHEN  @MetricType = 'PB' THEN 
									' SUM(ISNULL(MT.mProductionBonus,0)) ' 
							 END + ' >= '
   								 + CONVERT(VARCHAR,@QualificationValue) + '
					),
					SemiFinalCount(PK_Distributor,TotalCountPerLeg) AS       
					(
							SELECT
								PK_Distributor,
								COUNT(1)        
							FROM         
								LevelDL         
							GROUP BY         
								PK_Distributor,PK_FirstDownline        
					),					
					FinalCount(PK_Distributor,TotalCount) AS
					(
						SELECT 
							PK_Distributor 
							,COUNT(1)
						FROM
							SemiFinalCount 
						GROUP BY
							PK_Distributor 
					)
				INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)' +
				'SELECT
					PK_Distributor
					,''' + CONVERT(VARCHAR,@ExtValidThroughDate) + ''' AS RoyaltyMonth
				FROM
					FinalCount ' 
			    
			    IF ISNULL(@CountMax,0) = 0
					SET @SQL = @SQL + ' WHERE TotalCount >= ' + CONVERT(varchar,@CountLimit) 
				ELSE
					SET @SQL = @SQL + ' WHERE TotalCount BETWEEN ' + CONVERT(varchar,@CountLimit) + ' AND ' + CONVERT(varchar,@CountMax)
				
			END 
		END 
		
		/*************************************************************************************************	 
			Strictly for determining downlines by line for a metric 
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DownlineByLineConsecutive')
           AND @QualificationValue IS NOT NULL AND @MetricType IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = '
				WITH 
					FirstDL (PK_Distributor, PK_FirstDownline) AS 
					(
						SELECT 
							PK_Distributor
							,PK_DSDownline 
						FROM
							dbo.v_dimDSLngDownline DL
						WHERE ' + CASE WHEN @LevelType = 'DS' THEN 
										' DL.DSLevelFromUL BETWEEN  2 AND 2 '
									   WHEN @LevelType = 'SP' THEN 
										' DL.SPLevelFromUL BETWEEN  2 AND 2 ' 
								  END + '
					),
					LevelDL(PK_Distributor,PK_FirstDownline, PK_DSDownline) AS
					(
						SELECT 
							FL.PK_Distributor
							,FL.PK_FirstDownline
							,DL.PK_DSDownline 
						FROM
							FirstDL FL
						INNER JOIN 
							dbo.v_dimDSLngDownline DL
						ON
							FL.PK_FirstDownline = DL.PK_Distributor 
						INNER JOIN 
							dbo.v_Distributor DS 
						ON
							DL.PK_DSDownline = DS.nDistributorID 
						INNER JOIN 
							ufn_GetConsecutiveBasedSPDate(''' + CONVERT(VARCHAR,@ExtValidFromDate) + ''',''' + CONVERT(varchar,@ExtValidThroughDate) + ''',' + CONVERT(varchar,@QualificationValue) + ',' + CONVERT(varchar,@MonthFrequency) + ',''' + CONVERT(varchar,@MetricType) + ''', NULL) MT
						ON
							DL.PK_DSDownline = MT.PK_Distributor 
						WHERE
							'+
						CASE WHEN @LevelType = 'SP' THEN
							'DL.SPLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel) + ' AND ' + CONVERT(VARCHAR,@EndLevel) + ''
						ELSE
							'DL.DSLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel) + ' AND ' + CONVERT(VARCHAR,@EndLevel) END +
							CASE WHEN @SubEventQualFilter IS NOT NULL THEN
									' AND DS.sType = ''' + @SubEventQualFilter + '''' 
							ELSE ' AND 1 = 1 ' END + 
							CASE WHEN @DateType = 'SPDate' THEN
									' AND DS.dSupervisorQualification BETWEEN ''' +  CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
								 WHEN @DateType = 'AppDate'	THEN 
									' AND DS.dApplication BETWEEN ''' +  CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
							ELSE ' AND 1 = 1 ' END + 
							CASE WHEN @ExtSubEventQualFilter IS NOT NULL THEN
									' AND DS.nDistributorCountryProcessingID IN ('+ CONVERT(varchar,@ExtSubEventQualFilter) +')' 
							ELSE ' AND 1 = 1 ' END +	
								'
						GROUP BY
							FL.PK_Distributor 
							,FL.PK_FirstDownline 
							,DL.PK_DSDownline 
					),
					SemiFinalCount(PK_Distributor,TotalCountPerLeg) AS       
					(
							SELECT
								PK_Distributor,
								COUNT(1)        
							FROM         
								LevelDL         
							GROUP BY         
								PK_Distributor,PK_FirstDownline        
					),					
					FinalCount(PK_Distributor,TotalCount) AS
					(
						SELECT 
							PK_Distributor 
							,COUNT(1)
						FROM
							SemiFinalCount 
						GROUP BY
							PK_Distributor 
					)
				INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)' +
				'SELECT
					PK_Distributor
					,''' + CONVERT(VARCHAR,@ExtValidThroughDate) + ''' AS RoyaltyMonth
				FROM
					FinalCount ' 
			    
			    IF ISNULL(@CountMax,0) = 0
					SET @SQL = @SQL + ' WHERE TotalCount >= ' + CONVERT(varchar,@CountLimit) 
				ELSE
					SET @SQL = @SQL + ' WHERE TotalCount BETWEEN ' + CONVERT(varchar,@CountLimit) + ' AND ' + CONVERT(varchar,@CountMax)
				
			END 
		END 

		/*************************************************************************************************	 
			Strictly for determining downlines by line with split metric PPV+DLV and TVP for FQS
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DownlineByLineSplitMetric')
           AND @QualificationValue IS NOT NULL AND @LevelType IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = '
				WITH 
					FirstDL (PK_Distributor, PK_FirstDownline) AS 
					(
						SELECT          
							PK_Distributor         ,
							PK_DSDownline         
						FROM         
							dbo.v_Distributor D
						INNER JOIN
							dbo.v_dimDSLngDownline DL        
						ON
							D.nDistributorID = DL.PK_Distributor 
						WHERE ' + CASE WHEN @LevelType = 'DS' THEN 
										' DL.DSLevelFromUL BETWEEN  2 AND 2 '
									   WHEN @LevelType = 'SP' THEN 
										' DL.SPLevelFromUL BETWEEN  2 AND 2 ' 
								  END + 
								  CASE WHEN @ExtSubEventQualFilter IS NOT NULL THEN
									' AND D.nDistributorCountryProcessingID IN ('+ CONVERT(varchar,@ExtSubEventQualFilter) +')' END + '
					),
					LevelDL(PK_Distributor,PK_FirstDownline, PK_DSDownline, TotalVP) AS
					(
						SELECT 
							FL.PK_Distributor
							,FL.PK_FirstDownline
							,DL.PK_DSDownline 
							,V.TotalVP
						FROM
							FirstDL FL
						INNER JOIN 
							dbo.v_dimDSLngDownline DL
						ON
							FL.PK_FirstDownline = DL.PK_Distributor 
						INNER JOIN 
							dbo.v_Distributor DS 
						ON
							DL.PK_DSDownline = DS.nDistributorID 
				
						LEFT JOIN          
						(
							SELECT
								A.nDistributorID, SUM(A.TotalVP) AS TotalVP
							FROM
								(
									SELECT
										vAgg.nDistributorID
										,dRoyaltyMonth
										,CASE WHEN dRoyaltyMonth < '+ CASE WHEN @MetricType = 'QSVolume' THEN 'ISNULL(vAgg.dQual_QS,ISNULL(vAgg.dQual_SP,DATEADD(MM,1,dRoyaltyMonth)))'
																		   ELSE 'ISNULL(vAgg.dQual_SP,DATEADD(MM,1,dRoyaltyMonth))' END	
											  +' THEN (SUM(ISNULL(vAgg.mPersonalPurchaseVolume, 0)) + SUM(ISNULL(vAgg.mDownLineVolume, 0)) + SUM(ISNULL(vAgg.mGroupVolume, 0))) 
											  ELSE SUM(ISNULL(vAgg.mVolumePoints, 0)) END AS TotalVP
									FROM		
										v_aggFQS_ID vAgg
									WHERE
										vAgg.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''' 	
									GROUP BY 
										vAgg.nDistributorID,dRoyaltyMonth,'+ CASE WHEN @MetricType = 'QSVolume' THEN 'ISNULL(vAgg.dQual_QS,vAgg.dQual_SP)'
																		   ELSE 'vAgg.dQual_SP' END	
											  +'
								) A 
							GROUP BY 
								A.nDistributorID
						) V
						ON
							DL.PK_DSDownline = V.nDistributorID 
						WHERE
							'+
						CASE WHEN @LevelType = 'SP' THEN
							'DL.SPLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel) + ' AND ' + CONVERT(VARCHAR,@EndLevel) + ''
						ELSE
							'DL.DSLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel) + ' AND ' + CONVERT(VARCHAR,@EndLevel) END +
							CASE WHEN @SubEventQualFilter IS NOT NULL THEN
									' AND DS.sType = ''' + @SubEventQualFilter + '''' 
							ELSE ' AND 1 = 1 ' END + 
							CASE WHEN @DateType = 'SPDate' THEN
									' AND DS.dSupervisorQualification BETWEEN ''' +  CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
								 WHEN @DateType = 'AppDate'	THEN 
									' AND DS.dApplication BETWEEN ''' +  CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
							ELSE ' AND 1 = 1 ' END +	
								'
								   AND V.TotalVP >= ' + CONVERT(VARCHAR,@QualificationValue) + '
					),
					SemiFinalCount(PK_Distributor,TotalCountPerLeg) AS       
					(
							SELECT
								PK_Distributor,
								COUNT(1)        
							FROM         
								LevelDL         
							GROUP BY         
								PK_Distributor,PK_FirstDownline        
					),					
					FinalCount(PK_Distributor,TotalCount) AS
					(
						SELECT 
							PK_Distributor 
							,COUNT(1)
						FROM
							SemiFinalCount 
						GROUP BY
							PK_Distributor 
					)
				INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)' +
				'SELECT
					PK_Distributor
					,''' + CONVERT(VARCHAR,@ExtValidThroughDate) + ''' AS RoyaltyMonth
				FROM
					FinalCount ' 
				IF ISNULL(@CountMax,0) = 0
					SET @SQL = @SQL + ' WHERE TotalCount >= ' + CONVERT(varchar,@CountLimit) 
				ELSE
					SET @SQL = @SQL + ' WHERE TotalCount BETWEEN ' + CONVERT(varchar,@CountLimit) + ' AND ' + CONVERT(varchar,@CountMax)
				
			END 
		END

		/*************************************************************************************************	 
			Strictly for determining downlines by line with split metric PPV+DLV and TVP for FQS
		*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'DownlineBySPQualDate')
           AND @QualificationValue IS NOT NULL AND @LevelType IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = 
				'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)' +
				'SELECT
					DL.PK_Distributor,
					''' + CONVERT(VARCHAR,@ValidThroughDate) + ''' AS RoyaltyMonth
				FROM 
					dbo.v_Distributor D (NOLOCK) 
				INNER JOIN
					dbo.v_dimDSLngDownline DL (NOLOCK)
				ON
					D.nDistributorID = DL.PK_Distributor
					AND
					'+
						CASE WHEN @LevelType = 'SP' THEN
							'DL.SPLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel+1) + ' AND ' + CONVERT(VARCHAR,@EndLevel+1) + ''
						ELSE
							'DL.DSLevelFromUL BETWEEN ' + CONVERT(VARCHAR,@BeginLevel+1) + ' AND ' + CONVERT(VARCHAR,@EndLevel+1) END + '
				INNER JOIN
					dbo.v_Distributor DD (NOLOCK)
				ON
					DL.PK_DSDownline = DD.nDistributorID 
				INNER JOIN
					ufn_GetASP ('''+ CONVERT(varchar,@ValidFromDate) + ''',''' + CONVERT(varchar,@ValidThroughDate) + ''','+CONVERT(varchar,@QualificationValue)+',''' + CONVERT(varchar,@MonthFrequency) + ''',''' + CONVERT(varchar,@MetricType) + ''',NULL)  C
				ON
					DL.PK_DSDownline = C.PK_Distributor
				WHERE 
					(DD.dSupervisorQualification IS NULL OR DD.dSupervisorQualification > ''' + CONVERT(VARCHAR,@ExtValidThroughDate) + ''') 
					AND
					D.nDistributorCountryProcessingID IN ('+ CONVERT(varchar(100),@ExtSubEventQualFilter) +')	
					AND
					'+CASE WHEN @SubEventQualFilter IS NOT NULL THEN
									'DS.sType = ''' + @SubEventQualFilter + '''' 
							ELSE ' 1 = 1 ' END  + '
				GROUP BY
					DL.PK_Distributor
				HAVING
					COUNT(1) >= ' + CONVERT(varchar,@CountLimit) 
				
			END 
		END
		
	END
	
	ELSE IF @QualificationType = 31
	BEGIN
	/********************************************************************************************************************************************************	 
		Strictly for determining qualifiers or non qualifiers of a referenced subevent within the same event or referenced PK_Event in SubEventQualFilter
	*********************************************************************************************************************************************************/
		IF @QualificationValue IS NOT NULL
		BEGIN
			SELECT @PK_RefSubEvent = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = ISNULL(@MetricType,@EventID) AND SubEventNumber = @QualificationValue
			IF @IsQualMember = 1
			BEGIN
				/* Get the qualifiers for the referenced subevent within the same event */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT SEQ.PK_Distributor,''' + CONVERT(varchar,@BeginCurrMonth) + ''' AS QualDate
									FROM dbo.SubEventQualifier SEQ WITH (NOLOCK) 
									WHERE SEQ.PK_Event = ' + CONVERT(VARCHAR,ISNULL(@MetricType,@EventID)) +
									' AND SEQ.PK_SubEvent = ' + CONVERT(VARCHAR,@PK_RefSubEvent) + 
									' AND SEQ.RemovedUTC = ''' + CONVERT(varchar,@ValidDate) + ''' '	  
				IF @KeepDNR = 0 
				BEGIN
					SET @SQL = @SQL + ' AND SEQ.PK_Distributor NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				
			END ELSE
			BEGIN
				/* get non qualifiers based on applicable filter(s) */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,''' + CONVERT(varchar,@BeginCurrMonth) + ''' AS QualDate '
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END
				SET @SQL = @SQL + ' LEFT JOIN dbo.SubEventQualifier SEQ WITH (NOLOCK) 
										ON S.nDistributorID = SEQ.PK_Distributor
										AND SEQ.PK_Event = ' + CONVERT(VARCHAR,ISNULL(@MetricType,@EventID)) +
								  ' AND SEQ.PK_SubEvent = ' + CONVERT(VARCHAR,@PK_RefSubEvent) + 
								  ' AND SEQ.RemovedUTC = ''' + CONVERT(varchar,@ValidDate) + ''' '	  
				
				SET @SQL = @SQL + ' WHERE 1 = 1 '
				IF @SubEventQualFilter IS NOT NULL
				BEGIN
					IF @SubEventQualFilter IN ('SP','DS') 
					BEGIN
						SET @SQL = @SQL + ' AND S.sType = ''' + CONVERT(VARCHAR,@SubEventQualFilter) + ''''
						IF @SubEventQualFilter = 'SP' AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
						BEGIN
							SET @SQL = @SQL + ' AND S.dSupervisorQualification BETWEEN ''' + CONVERT(VARCHAR,@ValidFromDate) + ''' AND ''' + CONVERT(VARCHAR,@ValidThroughDate) + ''''
						END
						IF @SubEventQualFilter = 'DS' AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
						BEGIN
							SET @SQL = @SQL + ' AND S.dApplication BETWEEN ''' + CONVERT(VARCHAR,@ValidFromDate) + ''' AND ''' + CONVERT(VARCHAR,@ValidThroughDate) + ''''
						END
					END
				END
				
				IF @ExtSubEventQualFilter IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorCountryProcessingID IN (' + CONVERT(VARCHAR(100),@ExtSubEventQualFilter) + ')' 
				END						
				SET @SQL = @SQL + ' AND SEQ.PK_Distributor IS NULL '			  
				IF @KeepDNR = 0 
				BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END

			END
		END 
		
	END
	ELSE IF @QualificationType = 32
	BEGIN
	/*******************************************************************************************************************************************************	 
		Strictly for determining qualifiers who met certain total metric within a period and also did minimum metric in at least certain number of months
	*******************************************************************************************************************************************************/
		IF @QualificationValue IS NOT NULL AND @MetricType IS NOT NULL AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL AND @SubEventQualFilter IS NOT NULL
		   AND @MonthFrequency IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = 'INSERT ##Q'+ @SortOrder +' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + '
				SELECT
				F1.PK_Distributor
				,''' + CONVERT(VARCHAR,@ValidThroughDate) + ''' AS RoyaltyMonth
				FROM
				(
					SELECT 
					a.nDistributorID AS PK_Distributor
					,a.dRoyaltyMonth AS RoyaltyMonth
					,'+ CASE WHEN @MetricType = 'PPV' THEN 
							 	'a.mPersonalPurchaseVolume'
							WHEN @MetricType = 'TV' THEN 
								'a.mVolumePoints' 
							WHEN @MetricType = 'RO' THEN 
								'(a.mRoyaltyOverrides + a.mMainRoyaltyOverrides) AS mRoyaltyOverrides'
							WHEN @MetricType = 'PB' THEN 
								'a.mProductionBonus' 
							 END + '
					,ROW_NUMBER () OVER (partition by a.nDistributorID ORDER BY a.nDistributorID, a.mVolumePoints DESC) AS RowNo
					FROM dbo.v_aggFQS_ID a
					where a.dRoyaltyMonth BETWEEN ''' + CONVERT(VARCHAR,@ValidFromDate) +''' AND ''' + CONVERT(VARCHAR,@ValidThroughDate) + '''
					and ' + CASE WHEN @MetricType = 'PPV' THEN 
									' a.mPersonalPurchaseVolume'
								 WHEN @MetricType = 'TV' THEN 
									' a.mVolumePoints' 
								 WHEN @MetricType = 'RO' THEN 
									' a.mRoyaltyOverrides + a.mMainRoyaltyOverrides'
								 WHEN @MetricType = 'PB' THEN 
									' a.mProductionBonus' 
								  END + ' >= '+ CONVERT(VARCHAR,@QualificationValue) +'
				) F1
				INNER JOIN
				(
					SELECT 
					a.nDistributorID AS PK_Distributor
					,a.dRoyaltyMonth AS RoyaltyMonth
					,'+ CASE WHEN @MetricType = 'PPV' THEN 
							 	' a.mPersonalPurchaseVolume'
							WHEN @MetricType = 'TV' THEN 
								' a.mVolumePoints' 
							WHEN @MetricType = 'RO' THEN 
								' (a.mRoyaltyOverrides + a.mMainRoyaltyOverrides) AS mRoyaltyOverrides'
							WHEN @MetricType = 'PB' THEN 
								' a.mProductionBonus' 
							 END + '
					,ROW_NUMBER () OVER (partition by a.nDistributorID ORDER BY a.nDistributorID, a.mVolumePoints DESC) AS RowNo
					FROM dbo.v_aggFQS_ID a
					where a.dRoyaltyMonth BETWEEN ''' + CONVERT(VARCHAR,@ValidFromDate) + ''' AND ''' + CONVERT(VARCHAR,@ValidThroughDate) + '''
					and ' + CASE WHEN @MetricType = 'PPV' THEN 
									' a.mPersonalPurchaseVolume'
								 WHEN @MetricType = 'TV' THEN 
									' a.mVolumePoints' 
								 WHEN @MetricType = 'RO' THEN 
									' a.mRoyaltyOverrides + a.mMainRoyaltyOverrides'
								 WHEN @MetricType = 'PB' THEN 
									' a.mProductionBonus' 
								  END + ' >= '+ CONVERT(VARCHAR,@QualificationValue) +'
				) F2
				ON
				F1.PK_Distributor = F2.PK_Distributor 
				AND
				F2.RowNo <= F1.RowNo
				WHERE
					F1.RowNo >= '+ CONVERT(VARCHAR,@MonthFrequency) +'
				GROUP BY
				F1.PK_Distributor
				,'+ CASE WHEN @MetricType = 'PPV' THEN 
							 	'F1.mPersonalPurchaseVolume'
							WHEN @MetricType = 'TV' THEN 
								'F1.mVolumePoints' 
							WHEN @MetricType = 'RO' THEN 
								'F1.mRoyaltyOverrides'
							WHEN @MetricType = 'PB' THEN 
								'F1.mProductionBonus' 
							 END + '
				,F1.RowNo 
				HAVING
					'+ CASE WHEN @MetricType = 'PPV' THEN 
								'SUM(F2.mPersonalPurchaseVolume) ' 
							WHEN @MetricType = 'TV' THEN 
								'SUM(F2.mVolumePoints) '
							WHEN @MetricType = 'RO' THEN 
								'SUM(F2.mRoyaltyOverrides) '
							WHEN @MetricType = 'PB' THEN 
								'SUM(F2.mProductionBonus) '
							END + '>= '+ CONVERT(VARCHAR,@SubEventQualFilter) 
				
			END 
		END 
		
	END
	
	ELSE IF @QualificationType = 33
	BEGIN
	/**********************************************************************************************************	 
		Strictly for determining qualifiers based on SP Requal Year and Period
	**********************************************************************************************************/
		IF @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL 
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				SET @StartSPRequalMonth = CAST(CONVERT(CHAR(6), @ValidFromDate, 112) AS INT)
				SET @EndSPRequalMonth = CAST(CONVERT(CHAR(6), @ValidThroughDate, 112) AS INT)
				
				IF @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL 
				BEGIN
					SET @SPQualBegin = CAST(CONVERT(CHAR(8), @ExtValidFromDate, 112) AS INT)
					SET @SPQualEnd = CAST(CONVERT(CHAR(8), @ExtValidThroughDate, 112) AS INT)
				END
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = 'INSERT ##Q'+ @SortOrder +' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + '
				SELECT
				D.nDistributorID
				,''' + CONVERT(VARCHAR,@ValidThroughDate) + ''' AS RoyaltyMonth
				FROM pubEvents.dbo.dimDSRequalCycle RC (NOLOCK) INNER JOIN pubEvents.dbo.dimDSRetention DR (NOLOCK)
				ON RC.PK_RequalCycle = DR.PK_RequalCycle AND RC.RequalCycle = ' + CONVERT(VARCHAR,@QualificationValue) + ' 
				AND DR.IsRequalified = 1 AND DR.RequalMonth BETWEEN ' + CONVERT(VARCHAR,@StartSPRequalMonth) + ' 
				AND ' + CONVERT(VARCHAR,@EndSPRequalMonth) + ' 
				INNER JOIN pubEvents.dbo.dimDistributor DS (NOLOCK)
				ON DR.PK_Distributor = DS.PK_Distributor AND DS.PK_DSStatus = 3 
				INNER JOIN v_Distributor D ON DS.DistributorID = D.sDistributorID ' + ' 
				WHERE 1 = 1 '
				
				IF @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + ' AND DR.SPQualDate BETWEEN ' + CONVERT(VARCHAR,@SPQualBegin) + ' 
					AND ' + CONVERT(VARCHAR,@SPQualEnd)
				END
					
			END 
		END 
	END
	ELSE IF @QualificationType = 34
	BEGIN
	/**********************************************************************************************************	 
		Strictly for determining qualifiers based on AppDate
	**********************************************************************************************************/
		IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL 
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,''' + CONVERT(varchar,@ValidFromDate) + ''' AS QualDate '
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END

				SET @SQL = @SQL + ' WHERE S.dApplication BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(VARCHAR,@ValidThroughDate) + ''''

				IF @LevelType IS NOT NULL
					SET @SQL = @SQL + ' AND S.sType = '''+CONVERT(varchar,@LevelType)+''''
			END 
			ELSE
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT S.nDistributorID,''' + CONVERT(varchar,@ValidFromDate) + ''' AS QualDate '
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END

				SET @SQL = @SQL + ' WHERE S.dApplication < ''' + CONVERT(varchar,@ValidFromDate) + ''' OR S.dApplication > ''' + CONVERT(VARCHAR,@ValidThroughDate) + ''''

				
			END 
		END 
	END
	ELSE IF @QualificationType = 36
	BEGIN
	/*************************************************************************************************	 
		Strictly for determining Past AWT based on the period provided
	*************************************************************************************************/
		IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				/* if MB has past AWT */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT DISTINCT S.nDistributorID,AWT.Qual_AWT AS QualDate'
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM dbo.v_DistributorCurrent S '
				ELSE
				   SET @SQL = @SQL + ' FROM dbo.v_Distributor S '
				END
				SET @SQL = @SQL + ' INNER JOIN dbo.AWT AWT (NOLOCK)
										ON S.nDistributorID = AWT.PK_Distributor' 
				
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND AWT.Qual_AWT BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END						
								
				IF @LevelType = 'NonTAB'
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 1'
				END
				ELSE IF @LevelType = 'TAB'
				BEGIN
					SET @SQL = @SQL + ' AND AWT.isNonTAB = 0'
				END
				
				IF @ExtSubEventQualFilter IS NOT NULL								-- To Filter By COP
				BEGIN
					SET @SQL = @SQL + ' WHERE S.nDistributorCountryProcessingID IN (' + CONVERT(varchar,@ExtSubEventQualFilter) + ')'
				END
				
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' AND AWT.IsDeleted = 0 '
				END					  
				IF @KeepDNR = 0 
				BEGIN
					SET @SQL = @SQL + ' AND S.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
				END
				
			END 
		END 
		
	END

	ELSE IF @QualificationType = 38
	BEGIN
	/*************************************************************************************************	 
		Determines qualifiers using PPV + DLV and TVP as the case may be to meet the volume requirement
	*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'PPV+DLV_AND_TVP')
           AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL AND @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
						SET @SQL = '
						WITH 
							Metric1 (PK_Distributor, SPQualDate, PPVDLV) AS 
							(
								SELECT 
									F1.nDistributorID AS PK_Distributor
									,MIN(d1.dSupervisorQualification) AS SPQualDate
									,SUM(ISNULL(F1.mPersonalPurchaseVolume,0)+ISNULL(F1.mDownLineVolume,0)) AS PPVDLV
								FROM
									dbo.v_aggFQS_ID F1
								INNER JOIN
									dbo.v_Distributor d1
								ON
									F1.nDistributorID = d1.nDistributorID 
									AND
									d1.StatusCode = '+''''+'COMPLETE'+''''
								+ ' AND d1.sType = '+''''+'SP'+''''
				IF @SubEventQualFilter IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + 
					' AND d1.nDistributorCountryProcessingID IN (' + @SubEventQualFilter + ')'
				END
				IF @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND F1.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
				END
				IF @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND d1.dSupervisorQualification BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				END
				SET @SQL = @SQL + 
				' GROUP BY F1.nDistributorID),
				Metric2(PK_Distributor,SPQualDate,PPVDLV,TotalVP) AS
				(SELECT 
					ISNULL(M1.PK_Distributor,F2.nDistributorID) AS PK_Distributor
					,MIN(ISNULL(M1.SPQualDate,d2.dSupervisorQualification)) AS SPQualDate
					,MAX(ISNULL(M1.PPVDLV,0)) AS PPVDLV
					,SUM(ISNULL(F2.mVolumePoints,0)) AS TV
				FROM
					dbo.v_aggFQS_ID F2
				INNER JOIN
					dbo.v_Distributor d2
				ON
					F2.nDistributorID = d2.nDistributorID
					AND
					d2.StatusCode = '+''''+'COMPLETE'+''''
					+ ' AND d2.sType = '+''''+'SP'+''''
				IF @SubEventQualFilter IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + 
					' AND d2.nDistributorCountryProcessingID IN (' + @SubEventQualFilter + ')'
				END
				IF @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND F2.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
					SET @SQL = @SQL + ' AND d2.dSupervisorQualification BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
				END
				SET @SQL = @SQL + 
				' FULL OUTER JOIN  
					Metric1 M1
				 ON
					M1.PK_Distributor = F2.nDistributorID 
					GROUP BY
					ISNULL(M1.PK_Distributor,F2.nDistributorID)
					)	
					INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)' +
						'SELECT
							PK_Distributor
							,''' + CONVERT(VARCHAR,@ExtValidThroughDate) + ''' AS RoyaltyMonth
						FROM
							Metric2 
						WHERE PPVDLV + TotalVP >= ' + CONVERT(varchar,@QualificationValue) 	
			END 
		END 
		
	END
	ELSE IF @QualificationType = 39
	BEGIN
	/***************************************************************************************************************	 
		Determines qualifiers who achieve certein metric while SP and different metric while TAB in the period
	***************************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'AchievePointsSPORTAB')
           AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL AND @ExtSubEventQualFilter IS NOT NULL AND @CountLimit IS NOT NULL
           AND @CountMax IS NOT NULL AND @MonthFrequency IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
				SET @SQL = '
				;WITH TeamStatus (nDistributorID,SPQualDate,TABQualDate) AS
				(
					SELECT DISTINCT
						D.nDistributorID,
						CASE WHEN H.nDistributorIDFK IS NOT NULL THEN H.dFrom ELSE NULL END,
						CASE WHEN H2.nDistributorIDFK IS NOT NULL THEN H2.dFrom ELSE NULL END
					FROM
						dbo.v_Distributor D
					INNER JOIN
						dbo.v_DistributorHistory H
					ON
						D.nDistributorID = H.nDistributorIDFK
						AND
						H.nEventTypeLID = 223
					LEFT JOIN
						dbo.v_DistributorHistory H2
					ON
						D.nDistributorID = H2.nDistributorIDFK
						AND
						H2.nEventTypeLID = 225
					WHERE
						D.nDistributorCountryProcessingID IN ('+ CONVERT(varchar,@ExtSubEventQualFilter)  +')
						AND
						D.sType = ''SP''
						AND
						D.StatusCode = ''COMPLETE''
						AND
						H.dThrough = ''' + CONVERT(varchar,@ValidDate) + '''
				),
				SPVolume (nDistributorID,SPQualDate,TABQualDate,SPVP) AS
				(
					SELECT
						D.nDistributorID,
						D.SPQualDate,
						D.TABQualDate,
						CASE WHEN A.nDistributorID IS NULL THEN 0 ELSE COUNT(1) END
					FROM	
						TeamStatus D
					LEFT JOIN
						dbo.v_aggFQS_ID A
					ON
						D.nDistributorID = A.nDistributorID
						AND
						A.mVolumePoints >= '+ CONVERT(varchar,@CountLimit) +'
						AND
						A.dRoyaltyMonth BETWEEN '''+ CONVERT(varchar,@ValidFromDate) +''' AND CASE WHEN D.TABQualDate BETWEEN DATEADD(MM,1,'''+CONVERT(varchar,@ValidFromDate)+''') AND '''+ CONVERT(varchar,@ValidThroughDate) +''' THEN DATEADD(MM,-1,D.TABQualDate)
																			WHEN D.TABQualDate <= '''+ CONVERT(varchar,@ValidFromDate) +''' THEN NULL
																			WHEN D.TABQualDate > '''+ CONVERT(varchar,@ValidThroughDate) +''' THEN '''+ CONVERT(varchar,@ValidThroughDate) +''' 
																			ELSE '''+ CONVERT(varchar,@ValidThroughDate) +''' END
					GROUP BY
						D.nDistributorID,
						D.SPQualDate,
						D.TABQualDate,
						A.nDistributorID
				),
				TABVolume (nDistributorID,SPQualDate,TABQualDate,SPVP,TABVP) AS
				(
					SELECT
						D.nDistributorID,
						D.SPQualDate,
						D.TABQualDate,
						D.SPVP,
						CASE WHEN B.nDistributorID IS NULL THEN 0 ELSE COUNT(1) END
					FROM	
						SPVolume D
					LEFT JOIN
						dbo.v_aggFQS_ID B
					ON
						D.nDistributorID = B.nDistributorID
						AND
						mVolumePoints >= '+ CONVERT(varchar,@CountMax) +'
						AND
						B.dRoyaltyMonth BETWEEN CASE WHEN D.TABQualDate BETWEEN '''+ CONVERT(varchar,@ValidFromDate) +''' AND '''+ CONVERT(varchar,@ValidThroughDate) +''' THEN D.TABQualDate
														   WHEN D.TABQualDate < '''+ CONVERT(varchar,@ValidFromDate) +''' THEN '''+ CONVERT(varchar,@ValidFromDate) +''' ELSE NULL END 
											  AND '''+ CONVERT(varchar,@ValidThroughDate) +'''
					GROUP BY
						D.nDistributorID,
						D.SPQualDate,
						D.TABQualDate,
						D.SPVP,
						B.nDistributorID
				)
				
				INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)
				SELECT
					nDistributorID,
					''' + CONVERT(VARCHAR,@ValidThroughDate) + ''' AS RoyaltyMonth
				FROM
					TABVolume
				WHERE
					(SPVP+TABVP) >= '+ CONVERT(varchar,@MonthFrequency)
			END 
		END 
		
	END
	ELSE IF @QualificationType IN (40,41,42,43)
	BEGIN
		/*********************************************************************************************************************************************************
			This is to baseline increase based on the metric over a certain amount
		*********************************************************************************************************************************************************/
		IF @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
			AND @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
		BEGIN
			
			SET @SQL = ';WITH QualPeriod(PK_Distributor,RoyaltyMonth,Increment,Months,Metric) AS '
					SET @SQL = @SQL + ' (SELECT D.nDistributorID AS PK_Distributor,F.dRoyaltyMonth AS RoyaltyMonth,' +@QualificationValue+ ' AS Increment,'  
					SET @SQL = @SQL + ' DATEDIFF(M,'+''''+CONVERT(varchar,@ExtValidFromDate)+''''+','+''''+CONVERT(varchar,@ExtValidThroughDate)+''''+')+1 AS Months,'
					SET @SQL = @SQL + ' CASE ' + CONVERT(varchar,@QualificationType)
					SET @SQL = @SQL + ' WHEN 40 THEN F.mVolumePoints '
					SET @SQL = @SQL + ' WHEN 41 THEN ISNULL(F.mRoyaltyOverrides,0)+ISNULL(F.mMainRoyaltyOverrides,0) '
					SET @SQL = @SQL + ' WHEN 42 THEN F.mProductionBonus '
					SET @SQL = @SQL + ' WHEN 43 THEN F.mPersonalPurchaseVolume '	
					SET @SQL = @SQL + ' END AS Metric '
					SET @SQL = @SQL + ' FROM ' 
					IF @KeepDeleted = 0
					   SET @SQL = @SQL + ' dbo.V_DistributorCurrent D '
					ELSE
					   SET @SQL = @SQL + ' dbo.V_Distributor D '
					SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C ON D.nDistributorCountryProcessingID = C.nCountryID ' 
					IF 	@DateType = 'Region'
					BEGIN
						SET @SQL = @SQL + ' AND C.sRegionCode = ''' + @ExtSubEventQualFilter + ''''
					END 
					IF 	@DateType = 'Country'
					BEGIN
						SET @SQL = @SQL + ' AND C.nCountryID IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')'
					END
					SET @SQL = @SQL + ' INNER JOIN dbo.v_aggFQS_ID F ON D.nDistributorID = F.nDistributorID '
					SET @SQL = @SQL + ' AND F.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
					SET @SQL = @SQL + ')' 
					SET @SQL = @SQL + ', WithBaseline(PK_Distributor,RoyaltyMonth,Metric,Months) AS '
					SET @SQL = @SQL + ' (SELECT Q.PK_Distributor,RoyaltyMonth,Q.Metric,Q.Months '
					SET @SQL = @SQL + ' FROM QualPeriod Q LEFT JOIN dbo.v_aggFQS_ID F1 ON Q.PK_Distributor = F1.nDistributorID '
					SET @SQL = @SQL + ' AND F1.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
					SET @SQL = @SQL + ' GROUP BY Q.PK_Distributor,Q.RoyaltyMonth,Q.Metric,Q.Months,Q.Increment '
					SET @SQL = @SQL + ' HAVING ISNULL(Q.Metric,0) >= SUM(CASE ' + CONVERT(varchar,@QualificationType)
					SET @SQL = @SQL + ' WHEN 40 THEN F1.mVolumePoints '
					SET @SQL = @SQL + ' WHEN 41 THEN ISNULL(F1.mRoyaltyOverrides,0)+ISNULL(F1.mMainRoyaltyOverrides,0) '
					SET @SQL = @SQL + ' WHEN 42 THEN F1.mProductionBonus '
					SET @SQL = @SQL + ' WHEN 43 THEN F1.mPersonalPurchaseVolume '	
					SET @SQL = @SQL + ' END)/(DATEDIFF(M,'+''''+CONVERT(varchar,@ValidFromDate)+''''+','+''''+CONVERT(varchar,@ValidThroughDate)+''''+')+1)+Q.Increment)'
					SET @SQL = @SQL + ', Qualifiers(PK_Distributor) AS '
					SET @SQL = @SQL + ' (SELECT PK_Distributor FROM WithBaseline GROUP BY PK_Distributor,Months HAVING COUNT(1) >= Months) '
					SET @SQL = @SQL + ' INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
					IF @IsQualMember = 1
						BEGIN
						 SET @SQL = @SQL + ' SELECT PK_Distributor, '+''''+CONVERT(varchar,@ExtValidThroughDate) + '''' + ' FROM Qualifiers '
						END
					ELSE
						BEGIN
							SET @SQL = @SQL + ' SELECT D1.nDistributorID AS PK_Distributor, '+''''+CONVERT(varchar,@ExtValidThroughDate) + '''' + ' FROM '
							IF @KeepDeleted = 0
								SET @SQL = @SQL + ' dbo.V_DistributorCurrent D1 '
							ELSE
							SET @SQL = @SQL + ' dbo.V_Distributor D1 '

							SET @SQL = @SQL + ' INNER JOIN dbo.v_Countries C ON D1.nDistributorCountryProcessingID = C.nCountryID ' 
							IF 	@DateType = 'Region'
							BEGIN
								SET @SQL = @SQL + ' AND C.sRegionCode = ''' + @ExtSubEventQualFilter + ''''
							END 
							IF 	@DateType = 'Country'
							BEGIN
								SET @SQL = @SQL + ' AND C.nCountryID IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')'
							END
							SET @SQL = @SQL + ' WHERE NOT EXISTS(SELECT 1 FROM Qualifiers Q WHERE Q.PK_Distributor = D1.nDistributorID)'
						END
			END 
	END
	ELSE IF @QualificationType = 44
	BEGIN
		/*********************************************************************************************************************************************************
			This is to baseline increase based on the metric over a certain amount
		*********************************************************************************************************************************************************/
		IF @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
			AND @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
		BEGIN
			
			SET @SQL = '
			;WITH MB AS 
			(
				SELECT 
					D.nDistributorID,
					A.nDistributorID AS DownlineID,
					dRoyaltyMonth,
					mVolumePoints,
					ROW_NUMBER() OVER(PARTITION BY A.nDistributorID ORDER BY dRoyaltyMonth) AS ROWMonth 
				FROM
					dbo.v_Distributor D
				INNER JOIN
					dbo.v_dimDSLngDownline DL
				ON
					D.nDistributorID = DL.PK_Distributor
				INNER JOIN
					dbo.v_aggFQS_ID A
				ON
					DL.PK_DSDownline = A.nDistributorID
					AND
					mVolumePoints >= '+ CONVERT(VARCHAR,@QualificationValue) +'
					AND
					dRoyaltyMonth BETWEEN '''+ CONVERT(VARCHAR,@ExtValidFromDate) +''' AND '''+ CONVERT(VARCHAR,@ExtValidThroughDate) +'''
				WHERE
					DL.SPLevelFromUL BETWEEN '+ CONVERT(varchar,@BeginLevel+1) +' AND '+ CONVERT(varchar,@EndLevel+1) +'
					AND
					D.nDistributorCountryProcessingID IN ('+ CONVERT(varchar(100),@ExtSubEventQualFilter) +')
					AND
					D.StatusCode = ''COMPLETE''
					AND
					D.sType = ''SP''
			),
			MBConsecutive AS
			(
				SELECT DISTINCT
					nDistributorID,
					DownlineID
				FROM 
					MB
				GROUP BY 
					nDistributorID,DownlineID,DATEADD(mm,-ROWMonth,dRoyaltyMonth)
				HAVING
					COUNT(mVolumePoints) >= '+ CONVERT(VARCHAR,@MonthFrequency) +'
			),
			MBBonus AS
			(
				SELECT
					nDistributorID,COUNT(1) AS Qty
				FROM
					MBConsecutive 
				GROUP BY
					nDistributorID
			),
			MBFinal AS
			(
				SELECT 
					D.nDistributorID, 
					SUM(CASE WHEN dRoyaltyMonth = '''+ CONVERT(VARCHAR,@DateType) +''' THEN CASE WHEN mVolumePoints >= '+ CONVERT(VARCHAR,@CountLimit) +' THEN (mVolumePoints+'+ CONVERT(VARCHAR,@CountLimit) +') ELSE mVolumePoints*2 END ELSE mVolumePoints END) AS TotalAccumulated,
					(CASE WHEN M.nDistributorID IS NOT NULL THEN M.Qty*'+ CONVERT(VARCHAR,@MetricType) +' ELSE 0 END) AS Bonus
				FROM 
					dbo.v_Distributor D
				INNER JOIN
					[dbo].[v_aggFQS_ID] A
				ON
					D.nDistributorID = A.nDistributorID
					AND 
					dRoyaltyMonth BETWEEN '''+ CONVERT(VARCHAR,@ValidFromDate) +''' AND '''+ CONVERT(VARCHAR,@ValidThroughDate) +'''
				LEFT JOIN
					MBBonus M
				ON
					D.nDistributorID = M.nDistributorID
				WHERE
					D.nDistributorCountryProcessingID IN ('+ CONVERT(varchar(100),@ExtSubEventQualFilter) +')
					AND
					D.StatusCode = ''COMPLETE''
					AND
					D.sType = ''SP''
				GROUP BY
					D.nDistributorID,M.nDistributorID,M.Qty
			)	

			INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)
			SELECT 
				nDistributorID, GETUTCDATE() AS QualMonth
			FROM 
				MBFinal
			WHERE
				TotalAccumulated+Bonus >= '+ CONVERT(VARCHAR,@SubEventQualFilter) +'' 
		END 
	END
	ELSE IF @QualificationType = 45
	BEGIN
		/*********************************************************************************************************************************************************
			This is to baseline increase based on the metric over a certain amount
		*********************************************************************************************************************************************************/
		IF @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
			AND @ExtValidFromDate IS NOT NULL AND @ExtValidThroughDate IS NOT NULL
		BEGIN
			
			SET @SQL  = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
			SET @SQL = @SQL + ' SELECT INC.nDistributorID,' + '''' + CONVERT(varchar,@ValidThroughDate) + + ''' AS QualDate'
			SET @SQL = @SQL + ' FROM dbo.v_Distributor D
            LEFT JOIN
			(
				select
				a.nDistributorID, ISNULL(SUM(a.[BaseVolume]),0) [BaseVolume]
				from(
					SELECT
					 vAgg.nDistributorID,dRoyaltyMonth
					,case when dRoyaltyMonth < vAgg.dQual_SP then (sum(ISNULL(vAgg.mPersonalPurchaseVolume, 0)) + sum(ISNULL(vAgg.mDownLineVolume, 0))) 
							else sum(ISNULL(vAgg.mVolumePoints, 0)) end [BaseVolume]
					FROM		
						v_aggFQS_ID(NOLOCK) vAgg
					INNER JOIN
						dbo.v_Distributor DS ON vAgg.nDistributorID = DS.nDistributorID
					INNER JOIN	
						dbo.v_Countries CN ON DS.nDistributorCountryProcessingID = CN.nCountryID
					WHERE 1 = 1'
			SET @SQL = @SQL + '
					AND 
						vAgg.dRoyaltyMonth between '''+ CONVERT(varchar,@ExtValidFromDate) + ''' AND ''' + CONVERT(varchar,@ExtValidThroughDate) + ''''
			IF 	@DateType = 'Region'
			BEGIN
				SET @SQL = @SQL + ' AND CN.sRegionCode = ''' + @ExtSubEventQualFilter + ''''
			END 
			IF 	@DateType = 'Country'
			BEGIN
				SET @SQL = @SQL + ' AND CN.nCountryID IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')'
			END			
			SET @SQL = @SQL + '	GROUP BY vAgg.nDistributorID,dRoyaltyMonth, dQual_SP
				) a group by a.nDistributorID
			) Baseline
			ON
				D.nDistributorID = Baseline.nDistributorID
			LEFT JOIN
			(
				select
				a.nDistributorID, SUM(a.IncVolume) [IncVolume]
				from(
					SELECT
					 vAgg.nDistributorID,dRoyaltyMonth
					,case when dRoyaltyMonth < vAgg.dQual_SP then (sum(ISNULL(vAgg.mPersonalPurchaseVolume, 0)) + sum(ISNULL(vAgg.mDownLineVolume, 0))) 
							else sum(ISNULL(vAgg.mVolumePoints, 0)) end [IncVolume]
					FROM		
						v_aggFQS_ID(NOLOCK) vAgg
					INNER JOIN
						dbo.v_Distributor DS ON vAgg.nDistributorID = DS.nDistributorID
					INNER JOIN	
						dbo.v_Countries CN ON DS.nDistributorCountryProcessingID = CN.nCountryID
			WHERE 1 = 1'
			SET @SQL = @SQL + '
					AND 
						vAgg.dRoyaltyMonth between '''+ CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
			IF 	@DateType = 'Region'
			BEGIN
				SET @SQL = @SQL + ' AND CN.sRegionCode = ''' + @ExtSubEventQualFilter + ''''
			END 
			IF 	@DateType = 'Country'
			BEGIN
				SET @SQL = @SQL + ' AND CN.nCountryID IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')'
			END				
			SET @SQL = @SQL + '			GROUP BY vAgg.nDistributorID,dRoyaltyMonth, dQual_SP
				) a group by a.nDistributorID
			)Inc
			ON D.nDistributorID = Inc.nDistributorID'
			IF @MetricType = 'Percent'
				SET @SQL = @SQL + ' 
			WHERE ((ISNULL(INC.IncVolume,0) - ISNULL(Baseline.BaseVolume,0))*100)/(CASE WHEN ISNULL(Baseline.BaseVolume,0) = 0 THEN 1 ELSE Baseline.BaseVolume END) >= ' + CONVERT(varchar,@QualificationValue) 
			ELSE
				SET @SQL = @SQL + '	
			WHERE ISNULL(INC.IncVolume,0) - ISNULL(Baseline.BaseVolume,0) >= ' + CONVERT(varchar,@QualificationValue) +
			'AND D.StatusCode = ''COMPLETE'' AND D.nDistributorCountryProcessingID IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')'
			IF @KeepDNR = 0 
			BEGIN
				SET @SQL = @SQL + ' AND INC.nDistributorID NOT IN (SELECT PK_Distributor FROM ##DNR)'
			END
		END
	END
	ELSE IF @QualificationType = 46
	BEGIN
		/*********************************************************************************************************************************************************
			Sponsor MB who achieve points in consecutive months from AppDate or SPDate
		*********************************************************************************************************************************************************/
		IF @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
			AND @MetricType IS NOT NULL AND @MonthFrequency IS NOT NULL AND @CountLimit IS NOT NULL
			AND @BeginLevel IS NOT NULL AND @EndLevel IS NOT NULL AND @LevelType IS NOT NULL AND @ExtSubEventQualFilter IS NOT NULL
			AND @DateType IS NOT NULL
		BEGIN
			SET @SQL = '
			INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)
			SELECT 
				D.nDistributorID,
				''' + CONVERT(varchar,@ValidThroughDate) + '''
			FROM
				dbo.v_Distributor D
			INNER JOIN
				dbo.v_dimDSLngDownline DL
			ON
				D.nDistributorID = DL.PK_Distributor
			INNER JOIN
				(
					SELECT
						DLD.nDistributorID
					FROM
						dbo.v_Distributor DLD
					INNER JOIN
						dbo.v_aggFQS_ID F
					ON
						F.nDistributorID = DLD.nDistributorID
					WHERE
						'+ CASE WHEN @LevelType = 'DS' THEN 'dRoyaltyMonth BETWEEN DATEADD(mm,DATEDIFF(mm,0,dApplication),0) AND DATEADD(MM,'+ CONVERT(VARCHAR,@MonthFrequency-1) +',DATEADD(mm,DATEDIFF(mm,0,dApplication),0))'
								WHEN @LevelType = 'SP' THEN 'dRoyaltyMonth BETWEEN dSupervisorQualification AND DATEADD(MM,'+ CONVERT(VARCHAR,@MonthFrequency-1) +',dSupervisorQualification)'
						END +
						'
						AND
						'+ CASE WHEN @MetricType = 'PPV' THEN 'mPersonalPurchaseVolume >= '+ CONVERT(VARCHAR,@QualificationValue)  
								WHEN @MetricType = 'TV' THEN 'mVolumePoints >= '+ CONVERT(VARCHAR,@QualificationValue) 
								WHEN @MetricType = 'RO' THEN 'mRoyaltyOverrides+mMainRosyaltyOverrides >= '+ CONVERT(VARCHAR,@QualificationValue) 
						END +
						'
						AND
						'+ CASE WHEN @DateType = 'AppDate' THEN 'DLD.dApplication BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + '''' 
								WHEN @DateType = 'SPDate' THEN 'DLD.dSupervisorQualification BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''''
						END +'
					GROUP BY
						DLD.nDistributorID
					HAVING
						COUNT(DLD.nDistributorID) >= '+ CONVERT(VARCHAR,@MonthFrequency) +'
				) A
			ON
				DL.PK_DSDownline = A.nDistributorID
			WHERE
				D.nDistributorCountryProcessingID IN (' + CONVERT(varchar,@ExtSubEventQualFilter) + ')
				AND
				D.StatusCode = ''COMPLETE''
				AND
				'+ CASE WHEN @LevelType = 'DS' THEN 'DL.DSLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1) 
						WHEN @LevelType = 'SP' THEN 'DL.SPLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1) 
				END+'
			GROUP BY
				D.nDistributorID
			HAVING
				COUNT(1) >= '+ CONVERT(VARCHAR,@CountLimit)
		END
	END
	ELSE IF @QualificationType = 47
	BEGIN
		/*********************************************************************************************************************************************************
			Accumulate certein points in any months non-consecutive
		*********************************************************************************************************************************************************/
		IF @QualificationValue IS NOT NULL AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
			AND @MetricType IS NOT NULL AND @MonthFrequency IS NOT NULL AND @LevelType IS NOT NULL AND @ExtSubEventQualFilter IS NOT NULL
		BEGIN
			SET @SQL = '
					;WITH MB AS 
					(
						SELECT 
							A.nDistributorID,
							dRoyaltyMonth,'+
							CASE WHEN @MetricType = 'PPV' THEN 'mPersonalPurchaseVolume'
								 WHEN @MetricType = 'TV' THEN 'mVolumePoints'
								 WHEN @MetricType = 'RO' THEN 'mRoyaltyOverrides+mRoyaltyOverrides' END +' AS [Points], ROW_NUMBER() OVER(PARTITION BY A.nDistributorID ORDER BY '+
							CASE WHEN @MetricType = 'PPV' THEN 'mPersonalPurchaseVolume'
								 WHEN @MetricType = 'TV' THEN 'mVolumePoints'
								 WHEN @MetricType = 'RO' THEN 'mRoyaltyOverrides+mRoyaltyOverrides' END +' DESC) AS ROWMonth 
						FROM
							dbo.v_Distributor D
						INNER JOIN
							dbo.v_aggFQS_ID A
						ON
							D.nDistributorID = A.nDistributorID
						WHERE
							dRoyaltyMonth BETWEEN '''+CONVERT(VARCHAR,@ValidFromDate)+''' AND '''+CONVERT(VARCHAR,@ValidThroughDate)+'''
							AND
							sType = '''+CONVERT(VARCHAR(10),@LevelType)+'''
							AND
							D.nDistributorCountryProcessingID IN ('+CONVERT(VARCHAR(100),@ExtSubEventQualFilter)+')
					),
					MBACCAnyMonth AS
					(
						SELECT
							nDistributorID
						FROM 
							MB
						WHERE
							ROWMonth <= '+CONVERT(VARCHAR(10),@MonthFrequency)+'
						GROUP BY 
							nDistributorID
						HAVING
							SUM([Points]) >= '+CONVERT(VARCHAR(10),@QualificationValue)+'
					)


					INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)
						SELECT
							nDistributorID,
							''' + CONVERT(varchar,@ValidThroughDate) + '''
						FROM
							MBACCAnyMonth' 
		END
	END
	ELSE IF @QualificationType = 48
	BEGIN
	/*************************************************************************************************	 
		Determines qualifiers using PPV + DLV OR TVP as the case may be to meet the volume requirement
	*************************************************************************************************/
		IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'PPV+DLV_OR_TVP')
           AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
		BEGIN
			IF @IsQualMember = 1
			BEGIN
						SET @SQL = '
						WITH MB AS 
						(
							SELECT 
							A.nDistributorID,
							dRoyaltyMonth,
							CASE WHEN ISNULL(dQual_QS,dQual_SP) <= dRoyaltyMonth THEN mVolumePoints ELSE mPersonalPurchaseVolume+mDownlineVolume END AS [Points],							
							ROW_NUMBER() OVER(PARTITION BY A.nDistributorID ORDER BY dRoyaltyMonth) AS ROWMonth 
							FROM
							dbo.v_Distributor D
							INNER JOIN
							dbo.v_aggFQS_ID A
							ON
							D.nDistributorID = A.nDistributorID
							WHERE
							CASE WHEN ISNULL(dQual_QS,dQual_SP) <= dRoyaltyMonth THEN mVolumePoints ELSE mPersonalPurchaseVolume+mDownlineVolume END >= ''' + CONVERT(varchar,@QualificationValue) + '''
							AND
							dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + '''
							AND D.StatusCode = '+''''+'COMPLETE'+''''
				IF @SubEventQualFilter IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + 
					' AND D.nDistributorCountryProcessingID IN (' + @SubEventQualFilter + ')'
				END
				SET @SQL = @SQL + 
				') , Final AS 
					(
						SELECT DISTINCT nDistributorID,
						DATEADD(mm,-ROWMonth,dRoyaltyMonth) AS [Month]						
						FROM 
						MB a
						GROUP BY 
						nDistributorID,DATEADD(mm,-ROWMonth,dRoyaltyMonth)
						HAVING
						COUNT([Points]) >= ' + CONVERT(varchar,@MonthFrequency) + '
					)
					INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)' +
						'SELECT 
							nDistributorID,
							MIN([Month]) AS [QualDate]
						FROM
							Final
						GROUP BY
							nDistributorID					
					'	
			END 
		END 
	END
	ELSE IF @QualificationType = 49
	BEGIN
	/**********************************************************************************************************	 
		Strictly for determining qualifiers based on having or not having downline
	**********************************************************************************************************/
			IF @IsQualMember = 1
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT DL.PK_Distributor,''' + CONVERT(varchar,@BeginCurrMonth) + ''' AS QualDate '
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM pubEvents.dbo.dimDSLngDownLine_wBlock DL WITH (NOLOCK) INNER JOIN pubEvents.dbo.dimDistributor DS WITH (NOLOCK) ON DL.Pk_Distributor = DS.PK_Distributor AND DS.StatusCode = '+'''COMPLETE'''
				ELSE
				   SET @SQL = @SQL + ' FROM pubEvents.dbo.dimDSLngDownLine_wBlock DL WITH (NOLOCK) INNER JOIN pubEvents.dbo.dimDistributor DS WITH (NOLOCK) ON DL.Pk_Distributor = DS.PK_Distributor '
				END

				SET @SQL = @SQL + ' WHERE DL.DSLevelFromUL = 1 AND DL.DLCount > ' + CONVERT(VARCHAR(10),@CountLimit)
				IF 	@ExtSubEventQualFilter IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND DS.PK_COP IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')'
				END
			END 
			ELSE -- Have no downline
			BEGIN
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT DL.PK_Distributor,''' + CONVERT(varchar,@BeginCurrMonth) + ''' AS QualDate '
				BEGIN
				IF @KeepDeleted = 0 
				   SET @SQL = @SQL + ' FROM pubEvents.dbo.dimDSLngDownLine_wBlock DL WITH (NOLOCK) INNER JOIN pubEvents.dbo.dimDistributor DS WITH (NOLOCK) ON DL.Pk_Distributor = DS.PK_Distributor AND DS.StatusCode = '+'''COMPLETE'''
				ELSE
				   SET @SQL = @SQL + ' FROM pubEvents.dbo.dimDSLngDownLine_wBlock DL WITH (NOLOCK) INNER JOIN pubEvents.dbo.dimDistributor DS WITH (NOLOCK) ON DL.Pk_Distributor = DS.PK_Distributor '
				END

				SET @SQL = @SQL + ' WHERE DL.DSLevelFromUL = 1 AND DL.DLCount <= ' + + CONVERT(VARCHAR(10),@CountLimit)
				IF 	@ExtSubEventQualFilter IS NOT NULL
				BEGIN
					SET @SQL = @SQL + ' AND DS.PK_COP IN (' + CONVERT(varchar(100),@ExtSubEventQualFilter) + ')'
				END
			END 
	END
	ELSE IF @QualificationType = 50
	BEGIN
	/**********************************************************************************************************	 
		Strictly for determining qualifiers based on having specified minimum number of downlines
		consecutively in the specified months within the specified application month period of 
		the indicated DS downline level(s)
	**********************************************************************************************************/
			IF @IsQualMember = 1
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT DISTINCT PK_Distributor, ''' + CONVERT(varchar,@ValidFromDate) + ''' AS QualDate' 
				SET @SQL = @SQL + ' FROM ( '
				SET @SQL = @SQL + ' SELECT RSL.PK_Distributor,RSL.ApplicationMonth,RSL.MonthCount,RSL.LRank,RSL.IntermittentMonth'
				SET @SQL = @SQL + ' ,Convert(Varchar(6),DateAdd(MM,-RSL.IntermittentMonth+1,Convert(Varchar(6),RSL.ApplicationMonth) + ''01''),112) AS ConsecutiveMonthStart				,ROW_NUMBER() OVER (PARTITION BY RSL.PK_Distributor, DateAdd(MM,-RSL.IntermittentMonth,Convert(Varchar(6),RSL.ApplicationMonth) + ''01'') ORDER BY RSL.ApplicationMonth) AS ConsecutiveMonth '
				SET @SQL = @SQL + ' FROM ( '
				SET @SQL = @SQL + ' SELECT DLL.PK_Distributor,DLL.ApplicationMonth,COUNT(1) AS MonthCount'
				SET @SQL = @SQL + ' ,RANK() OVER (PARTITION BY DLL.PK_Distributor ORDER BY DLL.ApplicationMonth) AS LRank '
				SET @SQL = @SQL + ' ,ROW_NUMBER() OVER (PARTITION BY DLL.PK_Distributor ORDER BY DLL.ApplicationMonth) AS IntermittentMonth '
				SET @SQL = @SQL + ' FROM '
				SET @SQL = @SQL + '( SELECT DS.PK_Distributor,DL.PK_DSDownline,LEFT(DSL.ApplicationDate,6) AS ApplicationMonth '
				SET @SQL = @SQL + ' FROM pubEvents.dbo.dimDistributor DS WITH (NOLOCK) INNER JOIN pubEvents.dbo.dimDSLngDownLine_wBlock DL WITH (NOLOCK) ON DS.Pk_Distributor = DL.PK_Distributor '
				SET @SQL = @SQL + ' AND DL.DSLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1) 
				SET @SQL = @SQL + ' INNER JOIN pubEvents.dbo.dimDistributor DSL WITH (NOLOCK) ON DSL.PK_Distributor = DL.PK_DSDownline '
				SET @SQL = @SQL + ' WHERE DS.PK_COP = '+ CONVERT(varchar,@QualificationValue) 
				SET @SQL = @SQL + ' AND DSL.ApplicationDate BETWEEN ''' + CONVERT(varchar,@ValidFromDate,112) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate,112) + ''''
				IF @SubEventQualFilter IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + ' AND DSL.PK_COP IN (' + @SubEventQualFilter + ') '
				END
				SET @SQL = @SQL + ' ) DLL '
				SET @SQL = @SQL + ' GROUP BY DLL.PK_Distributor,DLL.ApplicationMonth '
				SET @SQL = @SQL + ' HAVING COUNT(1) >= ' + CONVERT(varchar,@CountLimit)
				SET @SQL = @SQL + ' ) RSL '
				SET @SQL = @SQL + ' ) XL '
				SET @SQL = @SQL + ' WHERE ConsecutiveMonth >= ' + CONVERT(varchar,@MonthFrequency)
			END 
	END
	ELSE IF @QualificationType = 51    
  BEGIN      
  /**********************************************************************************************************        
   Strictly for determining qualifiers based on all the active downline supervisors     
   (yy volumes made in A Consecutive months) and based on the downline count    
   the upline can earn xx bonus along with certain TVP made on his own.     
  **********************************************************************************************************/      
   IF @IsQualMember = 1      
    BEGIN   
 SET @SQL = '  
  ;WITH Downline AS  
  (  
  SELECT DISTINCT  
   D.nDistributorID AS UplineID,  
   F.PK_Distributor AS DownlineID       
  FROM  
   dbo.v_Distributor D  
  INNER JOIN  
   dbo.v_dimDSLngDownline DL  
  ON  
   D.nDistributorID = DL.PK_Distributor  
  INNER JOIN  
   ufn_GetASP ('''+CONVERT(varchar,@ExtValidFromDate,112) + ''', '''+CONVERT(varchar,@ExtValidThroughDate,112) + ''','+ CONVERT(varchar,@QualificationValue)+',' + CONVERT(varchar,@MonthFrequency)+','
   IF @LevelType = 'DS'
 SET @SQL = @SQL + '''PLV''  '
 ELSE
    SET @SQL = @SQL + '''TV''  '
  SET @SQL = @SQL + ',NULL) F   
  ON  
   DL.PK_DSDownline = F.PK_Distributor
  INNER JOIN
   dbo.v_Distributor DLD
  ON
   DLD.nDistributorID = DL.PK_Distributor  
  WHERE   
   D.nDistributorCountryProcessingID = '+ CONVERT(varchar,@ExtSubEventQualFilter)+'  
  AND  
   D.StatusCode = ''COMPLETE''  
   AND  
   D.sType = ''SP''  
   AND
   DLD.sType = ISNULL('''+@LevelType+''',DLD.sType)
   '
   IF @LevelType = 'DS'            -- To Determine whether DS or SP Level to use    
    BEGIN    
     SET @SQL = @SQL + ' AND DL.DSLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)    
    END    
    ELSE    
    BEGIN    
     SET @SQL = @SQL + ' AND DL.SPLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)    
    END  
    SET @SQL = @SQL + ' GROUP BY D.nDistributorID, F.PK_Distributor '
  IF @DateType = 'FirstTime'
  BEGIN
   SET @SQL = @SQL + '
   EXCEPT
   SELECT DISTINCT  
   D.nDistributorID AS UplineID,  
   F.PK_Distributor AS DownlineID       
  FROM  
   dbo.v_Distributor D  
  INNER JOIN  
   dbo.v_dimDSLngDownline DL  
  ON  
   D.nDistributorID = DL.PK_Distributor  
  INNER JOIN  
   ufn_GetASP (DATEADD(M,-'+CONVERT(varchar,(@CountLimit-1))+','''+CONVERT(varchar,@ExtValidFromDate,112) + '''),DATEADD(M,-1,'''+CONVERT(varchar,@ExtValidFromDate,112) + '''),'+ CONVERT(varchar,@QualificationValue)+',' + CONVERT(varchar,@MonthFrequency)+','
 IF @LevelType = 'DS'
 SET @SQL = @SQL + '''PLV''  '
 ELSE
    SET @SQL = @SQL + '''TV''  '
  SET @SQL = @SQL + ',NULL) F  
  ON  
   DL.PK_DSDownline = F.PK_Distributor  
   INNER JOIN
   dbo.v_Distributor DLD
  ON
   DLD.nDistributorID = DL.PK_Distributor 
  WHERE   
   D.nDistributorCountryProcessingID = '+ CONVERT(varchar,@ExtSubEventQualFilter)+'  
  AND  
   D.StatusCode = ''COMPLETE''  
   AND  
   D.sType = ''SP'' 
    AND
   DLD.sType = ISNULL('''+@LevelType+''',DLD.sType)'     
  IF @LevelType = 'DS'            -- To Determine whether DS or SP Level to use    
    BEGIN    
     SET @SQL = @SQL + ' AND DL.DSLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)    
    END    
    ELSE    
    BEGIN    
     SET @SQL = @SQL + ' AND DL.SPLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)    
    END  
    SET @SQL = @SQL + ' GROUP BY D.nDistributorID, F.PK_Distributor '
  END
  SET @SQL = @SQL + '
  ), MB AS  
  (  
   SELECT UplineID, COUNT(DISTINCT DownlineID) DownlineCount FROM Downline group by UplineID  
  )  
  ,  
  MBTotal AS  
  (  
   SELECT A.nDistributorID, SUM(A.mVolumePoints) [UplineVolume], (ISNULL(DownlineCount,0) * '+ CONVERT(varchar,@MetricType)+') [BonusAccumulated]    
   FROM MB   
   RIGHT JOIN dbo.v_aggFQS_ID A ON MB.UplineID = A.nDistributorID  
   WHERE A.dRoyaltyMonth BETWEEN '''+CONVERT(varchar,@ValidFromDate,112) + ''' AND '''+CONVERT(varchar,@ValidThroughDate,112)+'''  
   GROUP BY A.nDistributorID, DownlineCount  
  )'  
  SET @SQL = @SQL + 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)    
  SELECT nDistributorID,'''+ CONVERT(varchar,@ValidFromDate,112) + ''' AS QualDate FROM MBTotal WHERE ([UplineVolume] + [BonusAccumulated]) >= '+ CONVERT(varchar,@SubEventQualFilter)  
    
    END       
  END    
  ELSE IF @QualificationType = 52
	BEGIN
	/**********************************************************************************************************	 
		Strictly for determining qualifiers based on having specified minimum number of downlines
		per month and total number of downlines in any x number of months in a y month period.
	**********************************************************************************************************/
			IF @IsQualMember = 1
			BEGIN
				/* Form Query to determine qualifiers based on all the criteria setup */
				SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
				SET @SQL = @SQL + ' SELECT PK_Distributor, ''' + CONVERT(varchar,@BeginCurrMonth) + ''' AS QualDate' 
				SET @SQL = @SQL + ' FROM '
				SET @SQL = @SQL + ' (SELECT DS.PK_Distributor,LEFT(DSL.ApplicationDate,6) AS ApplicationMonth '
				SET @SQL = @SQL + ' FROM pubEvents.dbo.dimDistributor DS WITH (NOLOCK) '
				SET @SQL = @SQL + ' INNER JOIN pubEvents.dbo.dimDSLngDownLine_wBlock DL WITH (NOLOCK) '
				SET @SQL = @SQL + ' ON DS.PK_Distributor = DL.PK_Distributor '
				SET @SQL = @SQL + ' AND DL.DSLevelFromUL BETWEEN ' + CONVERT(varchar,@BeginLevel+1) + ' AND ' +  CONVERT(varchar,@EndLevel+1)
				IF @QualificationValue IS NOT NULL 
				BEGIN
					SET @SQL = @SQL + ' AND DS.PK_COP IN (' + @QualificationValue + ') '
				END
				SET @SQL = @SQL + ' INNER JOIN pubEvents.dbo.dimDistributor DSL WITH (NOLOCK) '
				SET @SQL = @SQL + ' ON DSL.PK_Distributor = DL.PK_DSDownline '
				SET @SQL = @SQL + ' WHERE DSL.ApplicationDate BETWEEN ''' + CONVERT(varchar,DATEADD(M,-(@MonthFrequency+1),@BeginCurrMonth),112) + ''' AND ''' + CONVERT(varchar,DATEADD(D,-1,@BeginCurrMonth),112) + ''''
				SET @SQL = @SQL + ' GROUP BY DS.PK_Distributor, LEFT(DSL.ApplicationDate,6) '
				SET @SQL = @SQL + ' HAVING COUNT(1) >= ' + CONVERT(varchar,@CountLimit)
				SET @SQL = @SQL + ' ) ML '
				SET @SQL = @SQL + ' GROUP BY ML.PK_Distributor ' 
				SET @SQL = @SQL + ' HAVING COUNT(1) >= ' + CONVERT(varchar,@CountMax)
			END 
	END
	ELSE
	IF @QualificationType = 53
	BEGIN
		/*************************************************************************************************	 
			Determines qualifiers using PPV + DLV + TVP as the case may be to meet the volume requirement
		*************************************************************************************************/
			IF @PK_Qualification = (SELECT PK_Qualification FROM dbo.Qualification WHERE LTRIM(RTRIM(QualificationAbbreviation)) = 'PPV+DLV+TVP')
			   AND @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
			BEGIN
			IF @IsQualMember = 1
			BEGIN

					SET @SQL = ';WITH MB AS 
							(
								SELECT
								A.nDistributorID, SUM(A.TotalVP) AS TotalVP
							FROM
								(
									SELECT
										vAgg.nDistributorID
										,dRoyaltyMonth
										,CASE WHEN dRoyaltyMonth < '+ CASE WHEN @MetricType = 'QSVolume' THEN 'ISNULL(vAgg.dQual_QS,ISNULL(vAgg.dQual_SP,DATEADD(MM,1,dRoyaltyMonth)))'
																		   ELSE 'ISNULL(vAgg.dQual_SP,DATEADD(MM,1,dRoyaltyMonth))' END	
											  +' THEN (SUM(ISNULL(vAgg.mPersonalPurchaseVolume, 0)) + SUM(ISNULL(vAgg.mDownLineVolume, 0)) + SUM(ISNULL(vAgg.mGroupVolume, 0))) 
											  ELSE SUM(ISNULL(vAgg.mVolumePoints, 0)) END AS TotalVP
									FROM		
										v_aggFQS_ID vAgg
									WHERE
										vAgg.dRoyaltyMonth BETWEEN ''' + CONVERT(varchar,@ValidFromDate) + ''' AND ''' + CONVERT(varchar,@ValidThroughDate) + ''' 	
									GROUP BY 
										vAgg.nDistributorID,dRoyaltyMonth,'+ CASE WHEN @MetricType = 'QSVolume' THEN 'ISNULL(vAgg.dQual_QS,ISNULL(vAgg.dQual_SP,DATEADD(MM,1,dRoyaltyMonth)))'
																		   ELSE 'ISNULL(vAgg.dQual_SP,DATEADD(MM,1,dRoyaltyMonth))' END	
											  +'
								) A 
							GROUP BY 
								A.nDistributorID
						 )'
				 
				SET @SQL = @SQL +
					'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)' +
						'SELECT 
							nDistributorID,'''
							+ CONVERT(varchar,@ValidThroughDate) + '''AS [QualDate]
						FROM
							MB GROUP BY nDistributorID HAVING SUM(TotalVP) >= ' + CONVERT(varchar,@QualificationValue)


			END 
			END
	END
	ELSE
	BEGIN
		/******************************************************************************
			for all qualification types except event specific 
		******************************************************************************/
		/* 
			@QualificationFrequencyType = 3
			for accumulated TV/RO/PB we must change @ValidFromDate to reflect the 
			first month its possible to attain the qualification.  
				Example - 2500 TV 3CM JAN07-JUN07
				The first month it's possible is Mar because Mar is the first time
				anyone can have 3 consecutive months in the date range.
		*/

		/* ************ SonarQ check 50 - Variables should not be self-assigned */
		----IF @QualificationFrequencyType = 3
		----BEGIN
		----	--SET @ValidFromDate = DATEADD(m,@QualificationFrequency-1,@ValidFromDate)
		----	SET @ValidFromDate = @ValidFromDate
		----END
		/* ************ SonarQ check 50 */

		/* if a distributor is a member of the qualification */
		IF @IsQualMember = 1
		BEGIN
			SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
			SET @SQL = @SQL + ' SELECT QD.PK_Distributor, MIN(QD.RoyaltyMonth)'
			SET @SQL = @SQL + ' FROM dbo.QualificationDistributor QD WITH (NOLOCK) '
			SET @SQL = @SQL + ' WHERE QD.PK_Qualification = ' + CONVERT(varchar,@PK_Qualification)

			IF @KeepDNR = 0 BEGIN
				SET @SQL = @SQL + ' AND QD.PK_Distributor NOT IN (SELECT PK_Distributor FROM ##DNR)'
			END

			IF @KeepDeleted = 0 BEGIN
				SET @SQL = @SQL + ' AND QD.IsDeleted = 0'
			END

			SET @SQL = @SQL + 
					CASE 
						WHEN @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
						THEN	' AND QD.RoyaltyMonth BETWEEN ''' + 
								CONVERT(varchar,@ValidFromDate,112) + 
								''' AND ''' + CONVERT(varchar,@ValidThroughDate,112) + ''''
						ELSE '' END
			SET @SQL = @SQL + ' GROUP BY QD.PK_Distributor'
		END ELSE

		/* if a distributor is NOT a member of the qualification */
		BEGIN
			SET @SQL = 'INSERT ##Q' + @SortOrder + ' (PK_Distributor,QualDate)'
			SET @SQL = @SQL + ' SELECT QD.PK_Distributor, MIN(QD.RoyaltyMonth)'
			SET @SQL = @SQL + ' FROM dbo.QualificationDistributor QD WITH (NOLOCK) '
			SET @SQL = @SQL + ' WHERE QD.PK_Qualification IN (' + CONVERT(varchar,@SPQualID)+',2)'
			SET @SQL = @SQL + ' AND NOT EXISTS'
			SET @SQL = @SQL + ' (SELECT 1 FROM dbo.QualificationDistributor WITH (NOLOCK) WHERE PK_Distributor = QD.PK_Distributor AND PK_Qualification = ' + CONVERT(varchar,@PK_Qualification)

			IF @KeepDNR = 0 BEGIN
				SET @SQL = @SQL + ' AND QD.PK_Distributor NOT IN (SELECT PK_Distributor FROM ##DNR)'
			END

			IF @KeepDeleted = 0 BEGIN
				SET @SQL = @SQL + ' AND QD.IsDeleted = 0'
			END

			SET @SQL = @SQL + 
					CASE 
						WHEN @ValidFromDate IS NOT NULL AND @ValidThroughDate IS NOT NULL
						THEN	' AND RoyaltyMonth BETWEEN ''' + 
								CONVERT(varchar,@ValidFromDate,112) + 
								''' AND ''' + CONVERT(varchar,@ValidThroughDate,112) + ''''
						ELSE '' END
			SET @SQL = @SQL + ')'
			SET @SQL = @SQL + ' GROUP BY QD.PK_Distributor'
		END
	END

	IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
	EXEC sp_executesql @SQL

	SET @SQL = 'CREATE INDEX IX_Q' + @SortOrder + '_PK_Distributor ON ##Q' + @SortOrder + ' (PK_Distributor)'
	SET @SQL = @SQL + CHAR(13) + 'CREATE INDEX IX_Q' + @SortOrder + '_QualDate ON ##Q' + @SortOrder + ' (QualDate)'
	IF @IsDevQA = 1 BEGIN PRINT convert(varchar(20),getdate())+@SQL PRINT REPLICATE('-',80) END
	EXEC sp_executesql @SQL

	FETCH NEXT FROM eq_cursor INTO  
		@PK_Qualification
		,@SortOrder
		,@ValidFromDate
		,@ValidThroughDate
		,@IsQualMember
		,@QualificationValue
		,@SubEventQualFilter
		,@QualificationType
		,@QualificationFrequencyType
		,@QualificationFrequency
		,@ExtValidFromDate 
		,@ExtValidThroughDate 
		,@DateType 
		,@MetricType 
		,@LevelType 
		,@BeginLevel 
		,@EndLevel 
		,@ExtSubEventQualFilter 
		,@MonthFrequency 
		,@CountLimit
		,@CountMax

END 

CLOSE eq_cursor
DEALLOCATE eq_cursor

/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime

END