
CREATE PROCEDURE [dbo].[usp_EventPromo_USPMPromo_Downline]      
  @DistributorID VARCHAR(10), 
  @PK_Event INT = 64065,           
  @Aggregate VARCHAR(10) = NULL,  
  @LocaleCode CHAR(5) = 'en-US'   ,
  @IncludeLevel0 INT = 1,  
  @IsSummary INT = 0,  
  @PageNumber INT = 1,  
  @PageSize INT = 99999,  
  @Offset INT = NULL,  
  @ColumnOrder udt_ReportColumnOrder READONLY,  
  @ColumnFilterString NVARCHAR(MAX) = ''
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
 
AS            
/* -----------------------------------------------------------------------------------------------------------------------------------------            
 OBJECT:   dbo.[usp_EventPromo_USPMPromo_Downline]        
 USAGE:     
   
  DECLARE @DSLevel udt_DSLevel           
  INSERT INTO @DSLevel VALUES (1),(2),(3)          
    
  DECLARE @ColumnOrder udt_ReportColumnOrder  

	DECLARE @e int, @em varchar(4000)
     
  EXEC dbo.[usp_EventPromo_USPMPromo_Downline]           
   @DistributorID = '09245618',  
   @PK_Event = 64065,    
   @LocaleCode = 'en-US' ,     
   @IsSummary = 0,  
   @PageNumber = 1,  
   @PageSize = 10,  
   @Offset = 0  
   --@ColumnOrder = @ColumnOrder  
   --@ColumnFilterString = @ColumnFilterString       

	,@Error = @e OUTPUT  -- @e must be defined in the local call 
	,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
	,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]
                  
              
            
 DESCRIPTION: Return Downline information for US PM Promo 2018 promotion           
            
 DEPENDENCIES            
 ---------------------------------------------------------------------------------------------------------------------------------------            
             
 VERSIONS            
 ----------------------------------------------------------------------------------------------------------------------------------------            
 1   2018-08-21  SushmaA	Initital  
 2	 2019-08-10	 RogelioR	Refactor code (SRE)
 3   2019-10-17  SushmaA	SRE updates for NOLOCK, NOCOUNT, SELECT *

----------------------------------------------------------------------------------------------------------------------------------------- */             
BEGIN     
	SET NOCOUNT ON;

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

			/* if column filter contains blacklist keyword, exit stored proc */  
		 IF dbo.ufn_Check_Blacklist (@ColumnFilterString) = 1  
		  RETURN --Exit   
  
		 /* declare variables */            
		 DECLARE @PK_Upline INT,            
		  @PK_MakeTop INT,                                
		  @ReportMonth DATETIME,  
		  @CurrentMonth DATETIME, 
		  @ReportMonth1 DATETIME  = '2018-08-01',
		  @ReportMonth2 DATETIME  = '2018-09-01',
		  @ReportMonth3 DATETIME  = '2018-10-01'

		  SET @CurrentMonth = GETDATE()  
		  SELECT @ReportMonth = CASE WHEN DAY(@CurrentMonth) < 2 THEN DATEADD(MONTH,DATEDIFF(MONTH,0,DATEADD(MONTH,-1,@CurrentMonth)),0) ELSE DATEADD(MONTH,DATEDIFF(MONTH,0,(@CurrentMonth)),0) END   

		 /* get report distributor pk*/  
		 SELECT @PK_Upline = PK_Distributor            
		 FROM PubEvents.dbo.dimDistributor (NOLOCK)            
		 WHERE DistributorID = @DistributorID            
            
		 SELECT @PK_MakeTop = PK_Distributor            
		 FROM PubEvents.dbo.dimDistributor (NOLOCK)            
		 WHERE DistributorID = @DistributorID            
                                 
                
		 /* Create work table */  
		 CREATE TABLE #MBDetails  
		 (  
		   PK_Distributor INT  
		  ,DistributorID VARCHAR(30)   
		  ,[Name] VARCHAR(100)  
		  ,ContractAcceptanceDate DATETIME  
		  ,TeamLevel VARCHAR(20)  
		  ,VolumeNeededInCurrentMonth MONEY   
		  ,CurrentCut INT  
		  ,Month1PPV MONEY DEFAULT 0  
		  ,Month2PPV MONEY DEFAULT 0  
		  ,Month3PPV MONEY DEFAULT 0  
		  ,Email VARCHAR(150)  
		  ,Phone VARCHAR(200)  
		  ,SponsorName VARCHAR(50)  
		  ,SponsorID VARCHAR(10)  
		  ,[FirstUplineTAB] VARCHAR(50)  
		  ,DSLevel INT  
		  ,[Aggregate] AS CASE CurrentCut WHEN 1 THEN '1st_Cut' WHEN 2 THEN '2nd_Cut' WHEN 3 THEN '3rd_Cut' END  
		  ,ApplicationDate DATETIME  
		  ,Goal MONEY
		  ,QualifyingGoalVolumeNeeded MONEY
		 )  
  
		 SELECT   
		  PK_DSDownline,  
		  DSLevelFromUL  
		 INTO #DL  
		 FROM   
		  PubEvents.dbo.dimDSLngDownline_wBlock DL (NOLOCK)  
		 WHERE    
		  PK_distributor = @PK_Upline  
		  AND IsVisible = 1  
   
  
		 INSERT #MBDetails  
		 (  
		  PK_Distributor  
		  ,DistributorID  
		  ,[Name]  
		  ,ApplicationDate  
		  ,TeamLevel  
		  ,VolumeNeededInCurrentMonth  
		  ,CurrentCut  
		  ,Month1PPV  
		  ,Month2PPV  
		  ,Month3PPV  
		  ,Email  
		  ,Phone  
		  ,SponsorName  
		  ,SponsorID  
		  ,[FirstUplineTAB]  
		  ,DSLevel  
		  ,Goal
		  ,QualifyingGoalVolumeNeeded
		 )  
		 SELECT --DISTINCT  
		  PK_Distributor   
		  ,DistributorID  
		  ,ISNULL(FirstName,'')+' '+ISNULL(LastName,'') AS Name  
		  ,AppDate  
		  ,CASE WHEN Team = 'BPM' THEN 'Bronze'
				WHEN Team = 'SPM' THEN 'Silver'
				WHEN Team = 'GPM' THEN 'Gold'		
			END
		  ,CASE WHEN Cut >= 3 THEN 0 WHEN CurrMonthPPVReqd < 0 THEN 0 ELSE CurrMonthPPVReqd END
		  ,case when N.QualifiedPeriod = 8 then 1
				WHEN N.QualifiedPeriod = 9 then 2
				WHEN N.QualifiedPeriod = 10 then 3
			ELSE  Cut  END
		  ,Month1PPV  
		  ,Month2PPV  
		  ,Month3PPV  
		  ,Email  
		  ,Phone  
		  ,SponsorName  
		  ,SponsorID  
		  ,FirstTABName AS [FirstUplineTAB]  
		  ,DSLevelFromUL AS DSLevel  
		  ,150.00
		  ,CASE WHEN Cut >= 3 THEN 0 
				WHEN MONTH(GETUTCDATE()) = '10' THEN CASE WHEN (450.00 - Month3PPV) >= 0 THEN (450.00 - Month3PPV) ELSE 0 END
				WHEN MONTH(GETUTCDATE()) = '09' THEN CASE WHEN (450.00 - Month2PPV) >= 0 THEN (450.00 - Month2PPV) ELSE 0 END
				WHEN MONTH(GETUTCDATE()) = '08' THEN CASE WHEN (450.00 - Month1PPV) >= 0 THEN (450.00 - Month1PPV) ELSE 0 END
			END
		 FROM dbo.WRK_USPMPromo2018 N WITH(NOLOCK)  
		 INNER JOIN #DL DL  
		  ON DL.PK_DSDownline = N.PK_Distributor  
		 --WHERE ((IsE1Qualifier = 0 AND Cut > 0) OR (IsE1Qualifier = 1 AND Cut = 3))  
  
		 /* return summary */  
		 DECLARE @CutAggregate AS TABLE ([Aggregate] VARCHAR(10))  
		 INSERT INTO @CutAggregate([Aggregate]) VALUES ('1st_Cut'),('2nd_Cut'),('3rd_Cut'), ('All')  
  
		 SELECT   
		  C.Aggregate,  
		  ISNULL(P.Value,0) AS Value  
		 FROM @CutAggregate C  
		 LEFT JOIN (  
		  SELECT   
		   CASE WHEN GROUPING([Aggregate]) = 1 then 'All' ELSE [Aggregate] END AS [Aggregate],  
		   COUNT(1) AS VALUE  
		  FROM #MBDetails  (NOLOCK)  
		  GROUP BY   
		   [Aggregate]  
		  WITH ROLLUP   
		 )P  
		  ON C.Aggregate = P.Aggregate  
  
		 IF @IsSummary = 0             
		 BEGIN    
		  --SELECT @OrderBy = CASE WHEN LEN(@OrderBy) > 1 THEN COALESCE(@OrderBy + ', ', '') ELSE '' END + ColumnName + ' '+ Sort  
		  --FROM @ColumnOrder   
  
		  /* set output column */    
		  DECLARE @OrderBy VARCHAR(MAX) = ''    
    
		  DECLARE @SQL_Columns VARCHAR(MAX) = '',    
		   @SQL_ColumnsVolume VARCHAR(MAX) = '',  
		   @VolumeNeeded VARCHAR(MAX) = '',   
		   @SQL_S NVARCHAR(MAX),  
		   @ReportMonthStr VARCHAR(10)  
     
		  SET @ReportMonthStr = REPLACE(CONVERT(VARCHAR(10),@ReportMonth,120),'-','_')     
  
		  SELECT @SQL_Columns =  
				  ' Month3PPV AS QualifyingVolume_' + REPLACE(CONVERT(VARCHAR(10),DATEADD(MONTH,0,@ReportMonth3),120),'-','_') +   
				  ',Month2PPV AS QualifyingVolume_' + REPLACE(CONVERT(VARCHAR(10),DATEADD(MONTH,0,@ReportMonth2),120),'-','_') +  
				  ',Month1PPV AS QualifyingVolume_' + REPLACE(CONVERT(VARCHAR(10),DATEADD(MONTH,0,@ReportMonth1),120),'-','_')   
       
		  --SELECT  @SQL_ColumnsVolume = 'VolumeNeededInCurrentMonth AS VolumeNeededInCurrentMonth_' + @ReportMonthStr  
  
		  SELECT  @VolumeNeeded = 'VolumeNeededInCurrentMonth'   
   
		  IF (LEN(@SQL_Columns) > 1)    
		   SET @SQL_Columns = LEFT(@SQL_Columns,LEN(@SQL_Columns))    
		  ELSE  
		   SET @SQL_Columns = 'NULL AS QualifyingVolume'    
  
		  IF (LEN(@SQL_Columns) > 1)    
		   SET @SQL_Columns = LEFT(@SQL_Columns,LEN(@SQL_Columns))    
		  ELSE  
		   SET @SQL_Columns = 'NULL AS QualifyingVolume'    
  
  
  
		  SELECT @OrderBy = CASE WHEN LEN(@OrderBy) > 1 THEN COALESCE(@OrderBy + ', ', '') ELSE '' END   
		  + REPLACE(ColumnName,@VolumeNeeded,'CASE WHEN '+@VolumeNeeded+' < = 0 THEN 999999 ELSE '+@VolumeNeeded+' END') + ' '+ Sort  
		  FROM @ColumnOrder   
  
		  IF @OrderBy = ''  
		   SET @OrderBy = 'CASE WHEN '+@VolumeNeeded+' < = 0 THEN 999999 ELSE '+@VolumeNeeded+' END ASC, CurrentCut DESC, Name ASC'  
            
		  /* determine record #s to return */  
		  DECLARE @FirstRecord INT   
		  DECLARE @LastRecord INT  
  
		  SELECT @FirstRecord = CASE WHEN @Offset IS NOT NULL THEN @Offset ELSE ( @PageNumber - 1 ) * @PageSize END  
		  SELECT @LastRecord = CASE WHEN @Offset IS NOT NULL THEN @Offset + @PageSize + 1   ELSE  ( @PageNumber * @PageSize + 1 ) END    
    
		  /* process column filter string */  
		  DECLARE @ColumnFilter VARCHAR(MAX) = ''  
     
		  IF LEN(@ColumnFilterString) > 0   
		   SELECT @ColumnFilter = ' WHERE ' + @ColumnFilterString  
   
   
		  /* return dataset */  
		  SET @SQL_S =  '  
		  SELECT *  
		  FROM(  
		   SELECT *   
			,COUNT(1) OVER() AS TotalRecords  
			,ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') AS RowNum  
		   FROM(  
			SELECT   
				 CASE CurrentCut WHEN 1 THEN ''1st_Cut''  
				  WHEN 2 THEN ''2nd_Cut''  
				  WHEN 3 THEN ''3rd_Cut''  
			  END AS [Aggregate]  
			 ,DSLevel - 1 AS DSLevel   
			 ,DistributorID  
			 ,[Name]  
			 ,ApplicationDate  
			 ,TeamLevel  
			 ,VolumeNeededInCurrentMonth
			 ,Goal
			 ,CurrentCut  
			 ,'+ @SQL_Columns + '   
			 ,Email  
			 ,Phone AS PhoneNumber  
			 ,SponsorID  
			 ,SponsorName  
			 ,[FirstUplineTAB] AS FirstUplineTABName  
			 ,450.00 [QualifyingGoalVolume]
			 ,[QualifyingGoalVolumeNeeded]
			FROM   
			 #MBDetails N  
			WHERE    
			 N.PK_Distributor != @PK_Upline  
			 AND  
			 (@Aggregate IS NULL OR (@Aggregate = N.[Aggregate]))  
		   ) T ' + @ColumnFilter + '  
		  )T   
		  WHERE RowNum > @FirstRecord AND RowNum < @LastRecord  
		  ORDER BY RowNum ASC '           
                  
		   --EXEC SP_EXECUTESQL @SQL_S, N'@FirstRecord INT, @LastRecord INT', @FirstRecord, @LastRecord  
		   EXEC SP_EXECUTESQL @SQL_S, N'@FirstRecord INT, @LastRecord INT, @PK_Upline INT, @Aggregate VARCHAR(50)', @FirstRecord, @LastRecord, @PK_Upline, @Aggregate  
		   --PRINT @SQL_S              
		 END          
		  /* return my data */  
		 IF @IncludeLevel0 = 1  
		 BEGIN  
		  DECLARE @IsEligibleForPromo INT = 0  
		  DECLARE @PK_Distributor INT, @Cut INT, @IsAchieved INT  
    
		  SELECT @Cut = Cut,  
			  @IsAchieved = IsE1Qualifier,  
			  @PK_Distributor = PK_Distributor  
		  FROM dbo.WRK_USPMPromo2018 (NOLOCK)   
		  WHERE PK_Distributor = @PK_MakeTop  
  
		  IF (@PK_Distributor IS NOT NULL)  
		  BEGIN  
		   IF (@IsAchieved = 1)  
			SET @IsEligibleForPromo = 2  
		   ELSE IF (@IsAchieved = 0 AND @Cut > 0)  
			SET @IsEligibleForPromo = 1  
		   ELSE   
			SET @IsEligibleForPromo = 3  
		  END  
  
		  DECLARE @RoyaltyMonth AS TABLE (RoyaltyMonth DATETIME)  
		  INSERT INTO @RoyaltyMonth (RoyaltyMonth)  VALUES ('2018-08-01'), ('2018-09-01'), ('2018-10-01')  
 
		  DECLARE @Month3Str VARCHAR(10) = CONVERT(VARCHAR(10),DATEADD(MONTH,0,@ReportMonth3),120)  
		  DECLARE @Month2Str VARCHAR(10) = CONVERT(VARCHAR(10),DATEADD(MONTH,0,@ReportMonth2),120)  
		  DECLARE @Month1Str VARCHAR(10) = CONVERT(VARCHAR(10),DATEADD(MONTH,0,@ReportMonth1),120)  
  
		  DECLARE @MyDataSQL NVARCHAR(MAX) = ''  
  
		  CREATE TABLE #MyData  
		  (  
		   RoyaltyMonth DATETIME,  
		   QualifyingVolume MONEY,  
		   IsQualified INT,  
		   ApplicationDate DATETIME,  
		   CurrentCut INT,  
		   IsAchieved INT,  
		   GoalVolume MONEY,  
		   PPV MONEY 
		  )  
  
		SET @MyDataSQL = '  
		   ;WITH CTE_TV AS   
		   (  
			SELECT   
			 RoyaltyMonth  
			 ,QualifyingVolume  
			 ,CASE WHEN QualifyingVolume >= GoalVolume THEN 1 ELSE 0 END AS IsQualified  
			 ,AppDate AS ApplicationDate  
			 ,CurrentCut  
			 ,IsQualifier  
			 ,GoalVolume  
			FROM (  
			 SELECT   
			  150.00 AS GoalVolume,  
			  Cut AS CurrentCut,   
			  Month1PPV AS [' + @Month1Str + '],  
			  Month2PPV AS [' + @Month2Str + '],  
			  Month3PPV AS [' + @Month3Str + '],  
			  AppDate,  
			  CASE WHEN IsE1Qualifier > 0 THEN 1 ELSE 0 END AS IsQualifier  
			 FROM dbo.WRK_USPMPromo2018  (nolock)  
			 WHERE PK_Distributor = @PK_MakeTop  
			) t  
			UNPIVOT (  
			 QualifyingVolume FOR RoyaltyMonth IN ([' + @Month1Str + '],[' + @Month2Str + '],[' + @Month3Str + '])
			) AS up  
		   ),  
		   CTE_PPV AS   
		   (  
			SELECT   
			 RoyaltyMonth,  
			 PPV  
			FROM (  
			 SELECT   
			  Month1PPV AS [' + @Month1Str + '],  
			  Month2PPV AS [' + @Month2Str + '],  
			  Month3PPV AS [' + @Month3Str + ']  
			 FROM dbo.WRK_USPMPromo2018  (nolock)  
			 WHERE PK_Distributor = @PK_MakeTop  
			) t  
			UNPIVOT (  
			 PPV FOR RoyaltyMonth IN ([' + @Month1Str + '],[' + @Month2Str + '],[' + @Month3Str + '])  
			) AS up  
		   )  
		   INSERT INTO #MyData (RoyaltyMonth, QualifyingVolume, IsQualified, ApplicationDate, CurrentCut, IsAchieved,GoalVolume,PPV)  
		   SELECT   
			TV.RoyaltyMonth,  
			TV.QualifyingVolume,  
			TV.IsQualified,  
			TV.ApplicationDate,  
			TV.CurrentCut,  
			TV.IsQualifier,  
			TV.GoalVolume,  
			PPV.PPV  
		   FROM CTE_TV TV  
		   LEFT JOIN CTE_PPV PPV  
			ON TV.RoyaltyMonth = PPV.RoyaltyMonth  
  
		  '  
		  EXEC SP_EXECUTESQL @MyDataSQL, N'@PK_MakeTop INT', @PK_MakeTop  
  
  
		  SELECT   
		   RM.RoyaltyMonth  
		   ,MD.GoalVolume AS GoalVolume  
		   ,CASE WHEN GETDATE() < RM.RoyaltyMonth THEN NULL ELSE MD.QualifyingVolume END AS QualifyingVolume  
		   ,CASE WHEN GETDATE() < RM.RoyaltyMonth THEN NULL ELSE MD.PPV END AS PPV  
		   ,MD.IsQualified AS IsQualified  
		   ,@IsEligibleForPromo AS IsEligibleForPromo  
		   ,CurrentCut  
		   ,ApplicationDate  
		   ,MD.IsAchieved  
		  FROM @RoyaltyMonth RM  
		  LEFT JOIN #MyData MD  
		   ON RM.RoyaltyMonth = MD.RoyaltyMonth  
    
		 END
 
		 RETURN 0

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
		   
END