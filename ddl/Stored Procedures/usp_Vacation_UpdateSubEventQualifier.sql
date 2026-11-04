
CREATE PROCEDURE [dbo].[usp_Vacation_UpdateSubEventQualifier]
	 @PK_InEvent INT
	 ,@TabName varchar(200)
	 ,@IsDevQA bit = 0	-- optional
--
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_Vacation_UpdateSubEventQualifier

USE:		EXEC dbo.usp_Vacation_UpdateSubEventQualifier @InEvent = 853

DESCRIPTION:    Write Vacation Qualifiers to SubEventQualifier table in IA.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2014-02-14   Orlando  	Initial

******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/******************************************************************************
	VARIABLE DECLARETION
******************************************************************************/
DECLARE @PK_SubEvent1 INT
DECLARE @PK_SubEvent2 INT
DECLARE @PK_SubEvent3 INT
DECLARE @SQLStatement nVarchar(1000)
DECLARE @RemovedUTC DATETIME = '2049-12-31' 
DECLARE @User VARCHAR(20) = 'UsrSQLProd'
/******************************************************************************
	SELECT PK_SubEvent for each subevent of the event APAC Vacation requested
******************************************************************************/
SELECT @PK_SubEvent1 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 1
SELECT @PK_SubEvent2 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 2
SELECT @PK_SubEvent3 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 3

SET @SQLStatement = 'SELECT * INTO dbo.WRK_Vacation FROM dbo.'+@TabName

IF OBJECT_ID('WRK_Vacation', 'U') IS NOT NULL DROP TABLE dbo.WRK_Vacation

EXEC sp_executesql @SQLStatement

CREATE INDEX IX_WRK_Vacation_PK_Distributor ON dbo.WRK_Vacation(PK_Distributor)


IF @PK_InEvent != 3438
BEGIN
	/**********************************************************************************************
	UPDATE THE RECORDS IN THE SUBEVENT QUALIFIERS IF THE RECORDS DOES NOT EXIST IN THE TEMP TABLE
	***********************************************************************************************/
	/* LEVEL 1 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_Vacation T 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND SQ.PK_SubEvent = @PK_SubEvent1
		AND T.IsE1Qualifier = 1
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent1

	/* LEVEL 2 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_Vacation T 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent2
		AND T.IsE2Qualifier = 1
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent2
		
	/* VIP LEVEL */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_Vacation T 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent3
		AND T.IsE3Qualifier = 1
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent3
END
ELSE
BEGIN
	/* VIP LEVEL */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ (NOLOCK)
	LEFT JOIN
		dbo.WRK_Vacation T 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent1
		AND T.IsE4Qualifier = 1
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent1
END	


IF @PK_InEvent != 3438
BEGIN	
	/**********************************************************************************************
		INSERT THE NEW QUALIFIERS THAT ARE NOT ALREADY IN THE SUBEVENT QUALIFIER TABLE 
	***********************************************************************************************/
	/* LEVEL 1 */
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
		,@User
		,GETUTCDATE()
		,@User
		,@PK_InEvent
		,@PK_SubEvent1
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@RemovedUTC
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_Vacation T
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent1 
		 AND SQ1.RemovedUTC =  @RemovedUTC 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE1Qualifier = 1
		AND
		SQ1.PK_Distributor IS NULL

	/* LEVEL 2 */
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
		,@User
		,GETUTCDATE()
		,@User
		,@PK_InEvent
		,@PK_SubEvent2
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@RemovedUTC
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_Vacation T
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent2 
		 AND SQ1.RemovedUTC = @RemovedUTC 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE2Qualifier = 1
	AND
		SQ1.PK_Distributor IS NULL

	/* LEVEL 3 */
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
		,@User
		,GETUTCDATE()
		,@User
		,@PK_InEvent
		,@PK_SubEvent3
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@RemovedUTC
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_Vacation T
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent3 
		 AND SQ1.RemovedUTC = @RemovedUTC 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE3Qualifier = 1
	AND
		SQ1.PK_Distributor IS NULL
END
ELSE
BEGIN
	/* LEVEL 3 */
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
		,@User
		,GETUTCDATE()
		,@User
		,@PK_InEvent
		,@PK_SubEvent1
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@RemovedUTC
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_Vacation T
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1 (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent1 
		 AND SQ1.RemovedUTC = @RemovedUTC 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsE4Qualifier = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF OBJECT_ID('WRK_Vacation', 'U') IS NOT NULL DROP TABLE dbo.WRK_Vacation

/******************************************************************************
	UPDATE EVENT QUALIFIER
******************************************************************************/	
EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = @PK_InEvent


/******************************************************************************
	END PROCEDURE
******************************************************************************/	
END