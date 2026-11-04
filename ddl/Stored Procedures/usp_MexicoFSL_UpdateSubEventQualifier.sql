
CREATE PROCEDURE [dbo].[usp_MexicoFSL_UpdateSubEventQualifier]
	 @ProcessCount INT
	 ,@TabName varchar(200)
	 ,@IsDevQA bit = 0	-- optional
--WITH EXECUTE AS 'dbo'
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MexicoFSL_UpdateSubEventQualifier

USE:		EXEC dbo.usp_MexicoFSL_UpdateSubEventQualifier

DESCRIPTION:    Write Star Promotion Qualifiers to SubEventQualifier table in IA for Event ID given.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2010

VERSIONS
--------------------------------------------------------------------
1	2017-03-31  Prashanth  	Initial
2	2019-11-04	NoeG		SRE Hardcode changed

******************************************************************************/
 
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/******************************************************************************
	VARIABLE DECLARETION
******************************************************************************/
DECLARE  @PK_SubEvent1 INT
		,@PK_SubEvent2 INT
		,@PK_SubEvent3 INT
		,@PK_SubEvent4 INT
		,@PK_SubEvent5 INT
		,@PK_SubEvent6 INT
		,@PK_SubEvent7 INT
		,@PK_SubEvent8 INT
		,@PK_SubEvent9 INT
		,@SQLStatement nVarchar(1000)
		,@Count INT = 1
		,@PK_InEvent INT 
		,@ValidDate DATETIME = '2049-12-31'
		,@UsrSQLProd VARCHAR(20) = 'UsrSQLProd'


IF OBJECT_ID('WRK_MexicoFSL','U') IS NOT NULL DROP TABLE dbo.WRK_MexicoFSL

SET @SQLStatement = 'SELECT PK_Distributor INTO dbo.WRK_MexicoFSL FROM dbo.'+@TabName

IF OBJECT_ID('WRK_MexicoFSL','U') IS NOT NULL DROP TABLE dbo.WRK_MexicoFSL

EXEC sp_executesql @SQLStatement

CREATE INDEX IX_WRK_MexicoFSL_PK_Distributor ON dbo.WRK_MexicoFSL(PK_Distributor)

WHILE @Count <= 4
BEGIN
	
	IF @ProcessCount = 1
	BEGIN
		SET @PK_InEvent = CASE WHEN @Count = 1 THEN 10373
							   WHEN @Count = 2 THEN 10374
							   WHEN @Count = 3 THEN 10584
							   WHEN @Count = 4 THEN 10590 END
	END
	
	IF @ProcessCount = 2
	BEGIN					   
		SET @PK_InEvent = CASE WHEN @Count = 1 THEN 10592
							   WHEN @Count = 2 THEN 11344
							   WHEN @Count = 3 THEN 11562
							   WHEN @Count = 4 THEN 11563 END			   
	END
	
	IF @ProcessCount = 3
	BEGIN				   
		SET @PK_InEvent = CASE WHEN @Count = 1 THEN 11564
							   WHEN @Count = 2 THEN 11565
							   WHEN @Count = 3 THEN 11566
							   END

		IF @Count = 3 
			SET @Count = 5
	END
			
	SET @Count += 1


	/******************************************************************************
		SELECT PK_SubEvent for each subevent 
	******************************************************************************/
	SELECT @PK_SubEvent1 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 1
	SELECT @PK_SubEvent2 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 2
	SELECT @PK_SubEvent3 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 3
	SELECT @PK_SubEvent4 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 4
	SELECT @PK_SubEvent5 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 5
	SELECT @PK_SubEvent6 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 6
	SELECT @PK_SubEvent7 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 7
	SELECT @PK_SubEvent8 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 8
	SELECT @PK_SubEvent9 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 9


BEGIN
	/**********************************************************************************************
	UPDATE THE RECORDS IN THE SUBEVENT QUALIFIERS IF THE RECORDS DOES NOT EXIST IN THE TEMP TABLE
	***********************************************************************************************/
	/* Star 1 */
	
	UPDATE
		SQ
	SET
			RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_MexicoFSL T (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND SQ.PK_SubEvent = @PK_SubEvent1
		AND T.IsE1 = 1
	LEFT JOIN
		dbo.EventsRegistration ER (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent 
	AND
		SQ.PK_SubEvent = @PK_SubEvent1
	
	
	UPDATE
		SQ
	SET
			RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_MexicoFSL T (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND SQ.PK_SubEvent = @PK_SubEvent2
		AND T.IsE2 = 1
	LEFT JOIN
		dbo.EventsRegistration ER (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent 
	AND
		SQ.PK_SubEvent = @PK_SubEvent2



	IF @PK_InEvent NOT IN (10373,10374,10584,10590,10592,11344)
	BEGIN
		/* Star 2 */
		UPDATE
			SQ
		SET
			 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
			,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
			,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
		FROM
			dbo.SubEventQualifier SQ (NOLOCK)
		LEFT JOIN
			dbo.WRK_MexicoFSL T (NOLOCK) 
		ON
			T.PK_Distributor = SQ.PK_Distributor 
			AND SQ.PK_Event = @PK_InEvent 
			AND PK_SubEvent = @PK_SubEvent3
			AND T.IsE3 = 1
		LEFT JOIN
			dbo.EventsRegistration ER (NOLOCK)
		ON
			ER.PK_Event = @PK_InEvent 
			AND
			ER.PK_Distributor = T.PK_Distributor
		WHERE
			SQ.PK_Event = @PK_InEvent
		AND
			SQ.PK_SubEvent = @PK_SubEvent3
		
		/* Star 3 */
		UPDATE
			SQ
		SET
				RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
			,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
			,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
		FROM
			dbo.SubEventQualifier SQ (NOLOCK)
		LEFT JOIN
			dbo.WRK_MexicoFSL T (NOLOCK) 
		ON
			T.PK_Distributor = SQ.PK_Distributor 
			AND SQ.PK_Event = @PK_InEvent 
			AND PK_SubEvent = @PK_SubEvent4
			AND T.IsE4 = 1
		LEFT JOIN
			dbo.EventsRegistration ER (NOLOCK)
		ON
			ER.PK_Event = @PK_InEvent 
			AND
			ER.PK_Distributor = T.PK_Distributor
		WHERE
			SQ.PK_Event = @PK_InEvent
		AND
			SQ.PK_SubEvent = @PK_SubEvent4
	END
			
	/* Star 4 */
	UPDATE
		SQ
	SET
			RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_MexicoFSL T (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent5
		AND T.IsE5 = 1
	LEFT JOIN
		dbo.EventsRegistration ER (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent5
		
	/* Star 5 */
	UPDATE
		SQ
	SET
			RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_MexicoFSL T (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent6
		AND T.IsE6 = 1
	LEFT JOIN
		dbo.EventsRegistration ER (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent6
			
			
	UPDATE
		SQ
	SET
			RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_MexicoFSL T (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent7
		AND T.IsE7 = 1
	LEFT JOIN
		dbo.EventsRegistration ER (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent7


	UPDATE
		SQ
	SET
			RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_MexicoFSL T (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent8
		AND T.IsE8 = 1
	LEFT JOIN
		dbo.EventsRegistration ER (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent8

	
	UPDATE
		SQ
	SET
			RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_MexicoFSL T (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent9
		AND T.IsE9 = 1
	LEFT JOIN
		dbo.EventsRegistration ER (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent9
	
END
		
	
BEGIN
	/**********************************************************************************************
		INSERT THE NEW QUALIFIERS THAT ARE NOT ALREADY IN THE SUBEVENT QUALIFIER TABLE 
	***********************************************************************************************/
	/*Level 5*/
	
	
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
		,@PK_InEvent
		,@PK_SubEvent1
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
		dbo.WRK_MexicoFSL T (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
			dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
			SQ1.PK_Event = @PK_InEvent 
			AND SQ1.PK_SubEvent = @PK_SubEvent1 
			AND SQ1.RemovedUTC = @ValidDate 
			AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE1 = 1
		AND
		SQ1.PK_Distributor IS NULL
	
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
		,@PK_InEvent
		,@PK_SubEvent2
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
		dbo.WRK_MexicoFSL T (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
			dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
			SQ1.PK_Event = @PK_InEvent 
			AND SQ1.PK_SubEvent = @PK_SubEvent2 
			AND SQ1.RemovedUTC = @ValidDate 
			AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE2 = 1
		AND
		SQ1.PK_Distributor IS NULL



	IF @PK_InEvent NOT IN (10373,10374,10584,10590,10592,11344)
	BEGIN
		/*Level 2*/
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
			,@PK_InEvent
			,@PK_SubEvent3
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
			dbo.WRK_MexicoFSL T (NOLOCK)
		INNER JOIN
			dbo.v_Distributor DS
		ON
			T.PK_Distributor = DS.nDistributorID
		LEFT JOIN
				dbo.SubEventQualifier SQ1 (NOLOCK) 
		ON
				SQ1.PK_Event = @PK_InEvent 
				AND SQ1.PK_SubEvent = @PK_SubEvent3 
				AND SQ1.RemovedUTC = @ValidDate 
				AND T.PK_Distributor = SQ1.PK_Distributor
		WHERE
			T.IsE3 = 1
		AND
			SQ1.PK_Distributor IS NULL

		/*Level 3*/
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
			,@PK_InEvent
			,@PK_SubEvent4
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
			dbo.WRK_MexicoFSL T (NOLOCK)
		INNER JOIN
			dbo.v_Distributor DS
		ON
			T.PK_Distributor = DS.nDistributorID
		LEFT JOIN
				dbo.SubEventQualifier SQ1 (NOLOCK) 
		ON
				SQ1.PK_Event = @PK_InEvent 
				AND SQ1.PK_SubEvent = @PK_SubEvent4 
				AND SQ1.RemovedUTC = @ValidDate 
				AND T.PK_Distributor = SQ1.PK_Distributor
		WHERE
			T.IsE4 = 1
		AND
			SQ1.PK_Distributor IS NULL

	END
		
	/*Level 4*/
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
		,@PK_InEvent
		,@PK_SubEvent5
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
		dbo.WRK_MexicoFSL T (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
			dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
			SQ1.PK_Event = @PK_InEvent 
			AND SQ1.PK_SubEvent = @PK_SubEvent5 
			AND SQ1.RemovedUTC = @ValidDate 
			AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE5 = 1
	AND
		SQ1.PK_Distributor IS NULL
		
	/*Level 5*/
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
		,@PK_InEvent
		,@PK_SubEvent6
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
		dbo.WRK_MexicoFSL T (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
			dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
			SQ1.PK_Event = @PK_InEvent 
			AND SQ1.PK_SubEvent = @PK_SubEvent6 
			AND SQ1.RemovedUTC = @ValidDate 
			AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE6 = 1
	AND
		SQ1.PK_Distributor IS NULL
			
			
	/*Level 6*/
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
		,@PK_InEvent
		,@PK_SubEvent7
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
		dbo.WRK_MexicoFSL T (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
			dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
			SQ1.PK_Event = @PK_InEvent 
			AND SQ1.PK_SubEvent = @PK_SubEvent7 
			AND SQ1.RemovedUTC = @ValidDate 
			AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE7 = 1
	AND
		SQ1.PK_Distributor IS NULL



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
		,@PK_InEvent
		,@PK_SubEvent8
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
		dbo.WRK_MexicoFSL T (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
			dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
			SQ1.PK_Event = @PK_InEvent 
			AND SQ1.PK_SubEvent = @PK_SubEvent8
			AND SQ1.RemovedUTC = @ValidDate 
			AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE8 = 1
	AND
		SQ1.PK_Distributor IS NULL


	/*Level 6*/
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
		,@PK_InEvent
		,@PK_SubEvent9
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
		dbo.WRK_MexicoFSL T (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
			dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
			SQ1.PK_Event = @PK_InEvent 
			AND SQ1.PK_SubEvent = @PK_SubEvent9 
			AND SQ1.RemovedUTC = @ValidDate 
			AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE9 = 1
	AND
		SQ1.PK_Distributor IS NULL
		
END


/******************************************************************************
	UPDATE EVENT QUALIFIER
******************************************************************************/	
EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = @PK_InEvent

END

/******************************************************************************
	END PROCEDURE
******************************************************************************/	
END