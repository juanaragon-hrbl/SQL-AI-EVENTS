CREATE PROCEDURE [dbo].[usp_QualStd_TV_RO_PB_Accumulated] 
	@QualificationType varchar(3) -- TV, RO, PB, PPV, DLV
	,@UseAllQualfications bit = 0 -- Default is to use only qualification that are used by current events

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
    OBJECT:            [dbo].[usp_QualStd_TV_RO_PB_Accumulated]
    
    USE:            
			DECLARE @e int, @em varchar(4000)
			
			EXEC [dbo].[usp_QualStd_TV_RO_PB_Accumulated]
				@QualificationType = 'TV'
				,@UseAllQualfications = 0
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
 
    DESCRIPTION:    
 
    NOTES:
 
    DEPENDENCIES
    --------------------------------------------------------------------
    
 
    VERSIONS
    --------------------------------------------------------------------
	1.1.0		2019-08-14		NoeG				Refactor code (SRE)
	1.1.1		2019-10-30		NoeG				SRE Hardcode changed
    
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@ProcParam varchar(100) = @QualificationType
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE 
			@minDate smalldatetime
			,@maxDate smalldatetime
			,@SQL nvarchar(max)
			,@metric varchar(1000)
			,@PK_QualificationType int
			,@PK_QualificationFrequencyType int

		/* Accumulated PK_QualificationFrequencyType = 1 */
		SET @PK_QualificationFrequencyType = 1

		/******************************************************************************************
			defined in dbo.QualificationType
			we're not hard coding the number in the parameter so the job call is more descriptive
			if the qual type is not specified correctly, the procedure will error out, which
			is what we want.
		8/9/2009 Ini: Added code to implement 5GET5 Type scenarios. Will have to be robustly tested.
		3/8/2011 Ini: Added code to split the implementation of accumulate in all months or accumulate in any combination of months within a month range
		10/29/2015 Ini: Added code PLV to represent combination of PPV+DLV logic
		******************************************************************************************/
		IF @QualificationType NOT IN ('TV','RO','PB','PPV','DLV','PLV')
		BEGIN
			SET @ErrorMessage = 'Qualification Type Not Valid: ' + @StoredProcedure + ' ' + @ProcParam
			RAISERROR (@ErrorMessage,18,1)
			RETURN
		END

		SELECT
			@PK_QualificationType = CASE @QualificationType
										WHEN 'TV' THEN 1
										WHEN 'RO' THEN 2
										WHEN 'PB' THEN 3 
										WHEN 'PPV' THEN 16 
										WHEN 'DLV' THEN 17
										WHEN 'PLV' THEN 37 END
								
		SELECT
			@metric = 	CASE @QualificationType
							WHEN 'TV' THEN 'CASE WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mVolumePoints >= PA.BreakPoint THEN F.mVolumePoints + PA.AcceleratorPoint WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mVolumePoints < PA.BreakPoint THEN F.mVolumePoints*2 ELSE F.mVolumePoints END'
							WHEN 'RO' THEN 'CASE WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mRoyaltyOverrides + F.mMainRoyaltyOverrides >= PA.BreakPoint THEN F.mRoyaltyOverrides + F.mMainRoyaltyOverrides + PA.AcceleratorPoint WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mRoyaltyOverrides + F.mMainRoyaltyOverrides < PA.BreakPoint THEN (F.mRoyaltyOverrides + F.mMainRoyaltyOverrides)*2 ELSE F.mRoyaltyOverrides + F.mMainRoyaltyOverrides END'
							WHEN 'PB' THEN 'CASE WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mProductionBonus >= PA.BreakPoint THEN F.mProductionBonus + PA.AcceleratorPoint WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mProductionBonus < PA.BreakPoint THEN F.mProductionBonus*2 ELSE F.mProductionBonus END' 
							WHEN 'PPV' THEN 'CASE WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mPersonalPurchaseVolume >= PA.BreakPoint THEN F.mPersonalPurchaseVolume + PA.AcceleratorPoint WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mPersonalPurchaseVolume < PA.BreakPoint THEN F.mPersonalPurchaseVolume*2 ELSE F.mPersonalPurchaseVolume END'
							WHEN 'DLV' THEN 'CASE WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mDownLineVolume >= PA.BreakPoint THEN F.mDownLineVolume + PA.AcceleratorPoint WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mDownLineVolume < PA.BreakPoint THEN F.mDownLineVolume*2 ELSE F.mDownLineVolume END' 
							WHEN 'PLV' THEN 'CASE WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND ISNULL(F.mDownLineVolume,0)+ISNULL(F.mPersonalPurchaseVolume,0) >= PA.BreakPoint THEN ISNULL(F.mDownLineVolume,0)+ISNULL(F.mPersonalPurchaseVolume,0) + PA.AcceleratorPoint WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND ISNULL(F.mDownLineVolume,0)+ISNULL(F.mPersonalPurchaseVolume,0) < PA.BreakPoint THEN (ISNULL(F.mDownLineVolume,0)+ISNULL(F.mPersonalPurchaseVolume,0))*2 ELSE ISNULL(F.mDownLineVolume,0)+ISNULL(F.mPersonalPurchaseVolume,0) END' END

		--SELECT
		--	@metric = 	CASE @QualificationType
		--					WHEN 'TV' THEN 'CASE WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mVolumePoints >= PA.BreakPoint THEN F.mVolumePoints + PA.AcceleratorPoint ELSE F.mVolumePoints END'
		--					WHEN 'RO' THEN 'CASE WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mRoyaltyOverrides + F.mMainRoyaltyOverrides >= PA.BreakPoint THEN F.mRoyaltyOverrides + F.mMainRoyaltyOverrides + PA.AcceleratorPoint ELSE F.mRoyaltyOverrides + F.mMainRoyaltyOverrides END'
		--					WHEN 'PB' THEN 'CASE WHEN PA.PK_PromotionAccelerator IS NOT NULL AND F.dRoyaltyMonth = PM.RoyaltyMonth AND F.mProductionBonus >= PA.BreakPoint THEN F.mProductionBonus + PA.AcceleratorPoint ELSE F.mProductionBonus END' END

		/******************************************************************************************
			get date range in aggFQS_ID
		******************************************************************************************/
		SELECT
			@minDate = MIN(dRoyaltyMonth)
			,@maxDate = MAX(dRoyaltyMonth)
		FROM
			dbo.v_aggFQS_ID

		IF @IsDevQA = 1 SELECT @minDate AS '@minDate', @maxDate AS '@maxDate'

		/******************************************************************************************
			get qualifications	
		******************************************************************************************/
		if object_id('tempdb..##qualification') is not null drop table ##qualification
		CREATE TABLE ##qualification (
			PK_Qualification int
			,QualificationMetric money
			,QualificationFrequency int
			,QualificationDuration int
			,RoyaltyMonth smalldatetime
			,PK_PromotionAccelerator int
		)

		IF @UseAllQualfications = 0
		BEGIN
			INSERT
				##qualification
			(
				PK_Qualification
				,QualificationMetric
				,QualificationFrequency
				,QualificationDuration
				,RoyaltyMonth
				,PK_PromotionAccelerator
			)
			SELECT DISTINCT   /* Added Distinct to eliminate duplicate entries -- Sandhya */ 
				Q.PK_Qualification
				,CONVERT(money,Q.QualificationMetric)
				,Q.QualificationFrequency
				,Q.QualificationDuration
				,M.dMonth
				,SEQ.PK_PromotionAccelerator
			FROM
				dbo.Qualification Q WITH(NOLOCK)
			INNER JOIN
				dbo.SubEventQualification SEQ WITH(NOLOCK)
				ON
					Q.PK_Qualification = SEQ.PK_Qualification
			INNER JOIN 
				dbo.EventSchedule ES WITH(NOLOCK)
				ON 
					SEQ.PK_Event = ES.PK_Event
					AND
					ES.PK_Schedule = 5 -- Update Qualfication from dbo.Schedule
					AND
					@StartTime BETWEEN ES.BeginUTC AND ES.EndUTC
			CROSS JOIN
				dbo.v_Months M
			WHERE
				Q.QualificationFrequency = 0	-- This filter is added 3/8/2011 to only do for where all months are in the accumulation
				AND
				M.dMonth BETWEEN SEQ.ValidFromDateUTC AND SEQ.ValidThroughDateUTC  
		  --    /* ValidFromDateUTC is replaced with ValidThroughDateUTC so it doesnt count prior to ValidFromDateUTC in the below temp table -- Sandhya */ 
				AND
				Q.PK_QualificationType = @PK_QualificationType
				AND
				Q.PK_QualificationFrequencyType = @PK_QualificationFrequencyType

		END ELSE BEGIN
	
			INSERT
				##qualification
			(
				PK_Qualification
				,QualificationMetric
				,QualificationFrequency
				,QualificationDuration
				,RoyaltyMonth
				,PK_PromotionAccelerator
			)
			SELECT
				DISTINCT
				Q.PK_Qualification
				,CONVERT(money,Q.QualificationMetric)
				,Q.QualificationFrequency
				,Q.QualificationDuration
				,M.dMonth
				,NULL
			FROM
				dbo.Qualification Q WITH(NOLOCK)
			CROSS JOIN
				dbo.v_Months M
			WHERE
				Q.QualificationFrequency = 0	-- This filter is added 3/8/2011 to only do for where all months are in the accumulation
				AND
				M.dMonth BETWEEN @minDate AND @maxDate
				AND
				Q.PK_QualificationType = @PK_QualificationType
				AND
				Q.PK_QualificationFrequencyType = @PK_QualificationFrequencyType

		END

		CREATE INDEX IX_qualification_PK_Qualification ON ##qualification (PK_Qualification)
		CREATE INDEX IX_qualification_QualificationMetric ON ##qualification (QualificationMetric)
		CREATE INDEX IX_qualification_QualificationFrequency ON ##qualification (QualificationFrequency)
		CREATE INDEX IX_qualification_QualificationDuration ON ##qualification (QualificationDuration)
		CREATE INDEX IX_qualification_RoyaltyMonth ON ##qualification (RoyaltyMonth)

		IF @IsDevQA = 1 SELECT PK_Qualification, QualificationMetric, QualificationFrequency, QualificationDuration, RoyaltyMonth, PK_PromotionAccelerator FROM ##qualification

		/******************************************************************************************
			get qualifiers		
		******************************************************************************************/
		IF OBJECT_ID('tempdb..##Quals') IS NOT NULL DROP TABLE ##Quals
		CREATE TABLE ##Quals (
			PK_Qualification int
			,PK_Distributor int
			,RoyaltyMonth smalldatetime
			,VolumePoints money
			,PK_Country int
			,IsDeleted bit
			,IsType23 bit
			,IsDNR bit
		)

		SET @SQL = '
		INSERT
			##Quals
		(
			PK_Qualification
			,PK_Distributor
			,RoyaltyMonth
			,PK_Country
			,IsDeleted
			,IsType23
			,IsDNR
		)
		SELECT
			Q.PK_Qualification
			,F.nDistributorID
			,Q.RoyaltyMonth
			,C.nCountryID
			,CASE WHEN F.dDeleted = ''' + CONVERT(varchar,@ValidDate) + ''' THEN 0 ELSE 1 END
			,F.nIsAssocType23
			,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
		FROM
			##qualification Q
		INNER JOIN
			dbo.v_aggFQS_ID F
			ON
				F.dRoyaltyMonth BETWEEN DATEADD(m,-(Q.QualificationDuration)+1,Q.RoyaltyMonth) AND Q.RoyaltyMonth
		INNER JOIN
				dbo.v_Countries C
			ON
				F.sCOP = C.sCountryCode
		LEFT JOIN
			dbo.v_DistributorDoNotRecognize R
			ON
				F.nDistributorID = R.PK_Distributor
		LEFT JOIN
			dbo.PromotionAccelerator PA WITH(NOLOCK)
		ON
			Q.PK_PromotionAccelerator = PA.PK_PromotionAccelerator
		AND 
			PA.PK_QualificationType = ' + CONVERT(varchar,@PK_QualificationType) + '
		LEFT JOIN
			dbo.PromotionAcceleratorMonths PM WITH(NOLOCK)
		ON
			PA.PK_PromotionAccelerator = PM.PK_PromotionAccelerator
		AND
			F.dRoyaltyMonth = PM.RoyaltyMonth
		LEFT JOIN
			dbo.PromotionAcceleratorCountry PC WITH(NOLOCK)
		ON
			PC.PK_PromotionAcceleratorMonth = PM.PK_PromotionAcceleratorMonth
		AND 
			PC.PK_Country = C.nCountryID
		GROUP BY
			Q.PK_Qualification
			,Q.QualificationMetric
			,F.nDistributorID
			,Q.RoyaltyMonth
			,C.nCountryID
			,CASE WHEN F.dDeleted = ''' + CONVERT(varchar,@ValidDate) + ''' THEN 0 ELSE 1 END
			,F.nIsAssocType23
			,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
		HAVING
			SUM(' + @metric + ') >= Q.QualificationMetric'

		IF @IsDevQA = 1 PRINT @SQL
		EXEC sp_executesql @SQL

		CREATE INDEX IX_##Quals_PK_DS_Qual_RoyaltyMonth ON ##Quals(PK_Distributor,PK_Qualification,RoyaltyMonth)
		/******************************************************************************
			Merge distributors from qualfication in production table
		******************************************************************************/
		; WITH Qualifiers(PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR) AS
		(SELECT QD.PK_Qualification,QD.PK_Distributor,QD.RoyaltyMonth,QD.PK_Country,QD.IsDeleted,QD.IsType23,QD.IsDNR 
		 FROM dbo.QualificationDistributor QD WITH (NOLOCK) 
		 INNER JOIN ##qualification Q ON QD.PK_Qualification = Q.PK_Qualification AND QD.RoyaltyMonth = Q.RoyaltyMonth) 
		 MERGE Qualifiers QL
		 USING ##Quals DQ
		 ON QL.PK_Distributor = DQ.PK_Distributor AND QL.PK_Qualification = DQ.PK_Qualification AND QL.RoyaltyMonth = DQ.RoyaltyMonth
		 WHEN MATCHED AND (QL.IsDeleted <> DQ.IsDeleted OR QL.IsType23 <> DQ.IsType23 OR QL.IsDNR <> DQ.IsDNR) THEN
		 UPDATE
			SET
				QL.PK_Country = DQ.PK_Country
				,QL.IsDeleted = DQ.IsDeleted
				,QL.IsType23 = DQ.IsType23
				,QL.IsDNR = DQ.IsDNR
		WHEN NOT MATCHED BY SOURCE THEN
			DELETE
		WHEN NOT MATCHED BY TARGET THEN
			INSERT	(PK_Qualification
					,PK_Distributor
					,RoyaltyMonth
					,PK_Country
					,IsDeleted
					,IsType23
					,IsDNR
				   )
			VALUES (DQ.PK_Qualification
					,DQ.PK_Distributor
					,DQ.RoyaltyMonth
					,DQ.PK_Country
					,DQ.IsDeleted
					,DQ.IsType23
					,DQ.IsDNR
				   );

		/******************************************************************************
			clean up
		******************************************************************************/
		IF OBJECT_ID('tempdb..##Quals') IS NOT NULL DROP TABLE ##Quals
		IF OBJECT_ID('tempdb..##qualification') IS NOT NULL DROP TABLE ##qualification

		/******************************************************************************************
			get qualifications	
		******************************************************************************************/
		if object_id('tempdb..##qualificationCombine') is not null drop table ##qualificationCombine
		CREATE TABLE ##qualificationCombine (
			PK_Qualification int
			,QualificationMetric money
			,QualificationFrequency int
			,QualificationDuration int
			,RoyaltyMonth smalldatetime
			,PK_PromotionAccelerator int
		)

		IF @UseAllQualfications = 0
		BEGIN
			INSERT
				##qualificationCombine
			(
				PK_Qualification
				,QualificationMetric
				,QualificationFrequency
				,QualificationDuration
				,RoyaltyMonth
				,PK_PromotionAccelerator
			)
			SELECT DISTINCT   /* Added Distinct to eliminate duplicate entries -- Sandhya */ 
				Q.PK_Qualification
				,CONVERT(money,Q.QualificationMetric)
				,Q.QualificationFrequency
				,Q.QualificationDuration
				,M.dMonth
				,SEQ.PK_PromotionAccelerator
			FROM
				dbo.Qualification Q WITH(NOLOCK)
			INNER JOIN
				dbo.SubEventQualification SEQ WITH(NOLOCK)
				ON
					Q.PK_Qualification = SEQ.PK_Qualification
			INNER JOIN 
				dbo.EventSchedule ES WITH(NOLOCK)
				ON 
					SEQ.PK_Event = ES.PK_Event
					AND
					ES.PK_Schedule = 5 -- Update Qualfication from dbo.Schedule
					AND
					@StartTime BETWEEN ES.BeginUTC AND ES.EndUTC
			CROSS JOIN
				dbo.v_Months M
			WHERE
				Q.QualificationFrequency > 0	-- This filter is added 3/8/2011 to only do for where all possible combinations of months is applicable
				AND
				M.dMonth BETWEEN SEQ.ValidFromDateUTC AND SEQ.ValidThroughDateUTC  
		  --    /* ValidFromDateUTC is replaced with ValidThroughDateUTC so it doesnt count prior to ValidFromDateUTC in the below temp table -- Sandhya */ 
				AND
				Q.PK_QualificationType = @PK_QualificationType
				AND
				Q.PK_QualificationFrequencyType = @PK_QualificationFrequencyType

		END ELSE BEGIN
	
			INSERT
				##qualificationCombine
			(
				PK_Qualification
				,QualificationMetric
				,QualificationFrequency
				,QualificationDuration
				,RoyaltyMonth
				,PK_PromotionAccelerator
			)
			SELECT
				DISTINCT
				Q.PK_Qualification
				,CONVERT(money,Q.QualificationMetric)
				,Q.QualificationFrequency
				,Q.QualificationDuration
				,M.dMonth
				,NULL
			FROM
				dbo.Qualification Q WITH(NOLOCK)
			CROSS JOIN
				dbo.v_Months M 
			WHERE
				Q.QualificationFrequency > 0	-- This filter is added 3/8/2011 to only do for where all possible combinations of months is applicable
				AND
				M.dMonth BETWEEN @minDate AND @maxDate
				AND
				Q.PK_QualificationType = @PK_QualificationType
				AND
				Q.PK_QualificationFrequencyType = @PK_QualificationFrequencyType

		END

		CREATE INDEX IX_qualificationCombine_PK_Qualification ON ##qualificationCombine (PK_Qualification)
		CREATE INDEX IX_qualificationCombine_QualificationMetric ON ##qualificationCombine (QualificationMetric)
		CREATE INDEX IX_qualificationCombine_QualificationFrequency ON ##qualificationCombine (QualificationFrequency)
		CREATE INDEX IX_qualificationCombine_QualificationDuration ON ##qualificationCombine (QualificationDuration)
		CREATE INDEX IX_qualificationCombine_RoyaltyMonth ON ##qualificationCombine (RoyaltyMonth)

		IF @IsDevQA = 1 SELECT PK_Qualification, QualificationMetric, QualificationFrequency, QualificationDuration, RoyaltyMonth, PK_PromotionAccelerator FROM ##qualificationCombine

		/******************************************************************************************
			get qualifiers		
		******************************************************************************************/
		IF OBJECT_ID('tempdb..##QualsCombine') IS NOT NULL DROP TABLE ##QualsCombine
		CREATE TABLE ##QualsCombine (
			PK_Qualification int
			,PK_Distributor int
			,RoyaltyMonth smalldatetime
			,VolumePoints money
			,PK_Country int
			,IsDeleted bit
			,IsType23 bit
			,IsDNR bit
		)

		SET @SQL = '
		;WITH Q_Members(PK_Qualification,PK_Distributor,sCOP,QualificationMonth,RoyaltyMonth,dDeleted,nIsAssocType23,PK_PromotionAccelerator,
						QualificationFrequency,QualificationDuration,QualificationMetric,Metric,nRow) 
		AS  (    
		SELECT   
			Q.PK_Qualification   
			,F.nDistributorID   
			,F.sCOP   
			,Q.RoyaltyMonth AS QualificationMonth  
			,F.dRoyaltyMonth   
			,F.dDeleted   
			,F.nIsAssocType23   
			,Q.PK_PromotionAccelerator   
			,Q.QualificationFrequency  
			,Q.QualificationDuration 
			,Q.QualificationMetric
			,' + @metric + ' AS VP
			,ROW_NUMBER() OVER (PARTITION BY F.nDistributorID ORDER BY ' + @metric + ' DESC) AS nRow
		FROM   ##qualificationCombine Q  
		INNER JOIN   
		dbo.v_aggFQS_ID F   
		ON    F.dRoyaltyMonth BETWEEN DATEADD(m,-(Q.QualificationDuration)+1,Q.RoyaltyMonth) AND Q.RoyaltyMonth 
		INNER JOIN    dbo.v_Countries C   
		ON    F.sCOP = C.sCountryCode   
		LEFT JOIN   dbo.PromotionAccelerator PA WITH(NOLOCK) 
		ON   Q.PK_PromotionAccelerator = PA.PK_PromotionAccelerator AND PA.PK_QualificationType = 1  
		LEFT JOIN   dbo.PromotionAcceleratorMonths PM WITH(NOLOCK)
		ON   PA.PK_PromotionAccelerator = PM.PK_PromotionAccelerator AND F.dRoyaltyMonth = PM.RoyaltyMonth  
		LEFT JOIN   dbo.PromotionAcceleratorCountry PC WITH(NOLOCK)  
		ON   PC.PK_PromotionAcceleratorMonth = PM.PK_PromotionAcceleratorMonth AND PC.PK_Country = C.nCountryID  
		) 
		INSERT
			##QualsCombine
		(
			PK_Qualification
			,PK_Distributor
			,RoyaltyMonth
			,PK_Country
			,IsDeleted
			,IsType23
			,IsDNR
			,VolumePoints
		)
		SELECT
			Q.PK_Qualification
			,Q.PK_Distributor
			,Q.QualificationMonth
			,C.nCountryID
			,CASE WHEN Q.dDeleted = ''' + CONVERT(varchar,@ValidDate) + ''' THEN 0 ELSE 1 END
			,Q.nIsAssocType23
			,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
			,SUM(Q.Metric)
		FROM
			Q_Members Q  
		INNER JOIN   
			##qualificationCombine QL  
		ON   
			Q.PK_Qualification = QL.PK_Qualification   
			AND 
			Q.QualificationFrequency = QL.QualificationFrequency  
			AND 
			Q.QualificationDuration = QL.QualificationDuration 
			AND 
			QL.RoyaltyMonth = Q.QualificationMonth 
		INNER JOIN    
			dbo.v_Countries C   
		ON    
			Q.sCOP = C.sCountryCode  
		LEFT JOIN   
			dbo.v_DistributorDoNotRecognize R   
		ON    
			Q.PK_Distributor = R.PK_Distributor  
		LEFT JOIN   
			dbo.PromotionAccelerator PA  
		ON   
			Q.PK_PromotionAccelerator = PA.PK_PromotionAccelerator  
			AND    
			PA.PK_QualificationType = ' + CONVERT(varchar,@PK_QualificationType) + '  
		LEFT JOIN   
			dbo.PromotionAcceleratorMonths PM  
		ON   
			PA.PK_PromotionAccelerator = PM.PK_PromotionAccelerator  
			AND   
			Q.RoyaltyMonth = PM.RoyaltyMonth  
		LEFT JOIN   
			dbo.PromotionAcceleratorCountry PC  
		ON   
			PC.PK_PromotionAcceleratorMonth = PM.PK_PromotionAcceleratorMonth  
			AND    
			PC.PK_Country = C.nCountryID  
		WHERE   
			Q.nRow <= QL.QualificationFrequency
		GROUP BY   
			Q.PK_Qualification   
			,Q.QualificationMetric   
			,Q.PK_Distributor  
			,Q.QualificationMonth 
			,C.nCountryID   
			,CASE WHEN Q.dDeleted = ''' + CONVERT(varchar,@ValidDate) + ''' THEN 0 ELSE 1 END   
			,Q.nIsAssocType23   
			,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END  
		HAVING   
			SUM(Q.Metric) >= Q.QualificationMetric'

		IF @IsDevQA = 1 PRINT @SQL
		EXEC sp_executesql @SQL

		CREATE INDEX IX_##QualsCombine_PK_DS_Qual_RoyaltyMonth ON ##QualsCombine(PK_Distributor,PK_Qualification,RoyaltyMonth)
		/******************************************************************************
			Merge distributors from qualfication in production table
		******************************************************************************/
		; WITH Qualifiers(PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR) AS
		(SELECT QD.PK_Qualification,QD.PK_Distributor,QD.RoyaltyMonth,QD.PK_Country,QD.IsDeleted,QD.IsType23,QD.IsDNR 
		 FROM dbo.QualificationDistributor QD WITH (NOLOCK) 
		 INNER JOIN ##qualificationCombine Q ON QD.PK_Qualification = Q.PK_Qualification AND QD.RoyaltyMonth = Q.RoyaltyMonth) 
		 MERGE Qualifiers QL
		 USING ##QualsCombine DQ
		 ON QL.PK_Distributor = DQ.PK_Distributor AND QL.PK_Qualification = DQ.PK_Qualification AND QL.RoyaltyMonth = DQ.RoyaltyMonth
		 WHEN MATCHED AND (QL.IsDeleted <> DQ.IsDeleted OR QL.IsType23 <> DQ.IsType23 OR QL.IsDNR <> DQ.IsDNR) THEN
		 UPDATE
			SET
				QL.PK_Country = DQ.PK_Country
				,QL.IsDeleted = DQ.IsDeleted
				,QL.IsType23 = DQ.IsType23
				,QL.IsDNR = DQ.IsDNR
		WHEN NOT MATCHED BY SOURCE THEN
			DELETE
		WHEN NOT MATCHED BY TARGET THEN
			INSERT	(PK_Qualification
					,PK_Distributor
					,RoyaltyMonth
					,PK_Country
					,IsDeleted
					,IsType23
					,IsDNR
				   )
			VALUES (DQ.PK_Qualification
					,DQ.PK_Distributor
					,DQ.RoyaltyMonth
					,DQ.PK_Country
					,DQ.IsDeleted
					,DQ.IsType23
					,DQ.IsDNR
				   );

		/******************************************************************************
			clean up
		******************************************************************************/
		IF OBJECT_ID('tempdb..##QualsCombine') IS NOT NULL DROP TABLE ##QualsCombine
		IF OBJECT_ID('tempdb..##qualificationCombine') IS NOT NULL DROP TABLE ##qualificationCombine

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StoredProcedureParameters = @ProcParam
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
	END CATCH

/******************************************************************************
	end procedure
******************************************************************************/

END