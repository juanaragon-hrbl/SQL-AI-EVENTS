CREATE PROCEDURE [dbo].[usp_QualStd_SPTeam]
	@Team varchar(1)

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_QualStd_SPTeam]
	
	USE:			
			DECLARE @e int, @em varchar(4000)
			
			EXEC [dbo].[usp_QualStd_SPTeam]
				@Team = 'W'
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
	1.0.0										Initial
	2.0.0		2019-09-30		NoeG			SRE template applied
	2.0.1		2019-10-30		NoeG		SRE Hardcode changed
	
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@ProcParam varchar(100) = @Team
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE 
			@QualID int
			,@HistoryTeam int

		/******************************************************************************
			set team info
		******************************************************************************/
		IF OBJECT_ID('tempdb..#team') IS NOT NULL DROP TABLE #team
		CREATE TABLE #team (team char(2))

		IF @Team NOT IN ('W','G','M','P')
		BEGIN
			SET @ErrorMessage = 'Team Type Not Valid (Needs to be W,G,M, or P): ' + @StoredProcedure + ' ' + @ProcParam
			RAISERROR (@ErrorMessage,18,1)
			RETURN
		END

		IF @Team = 'W' 
		BEGIN
			INSERT #team (team) VALUES ('W')
			SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'WorldTeam'
			SELECT @HistoryTeam = LifeCycleCode From dbo.v_dimDSLifeCycle WITH (NOLOCK) WHERE LifeCycleName = 'Qual World Team'
		END

		IF @Team = 'G' 
		BEGIN
			INSERT #team (team) VALUES ('G')
			SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'GetTeam'
			SELECT @HistoryTeam = LifeCycleCode From dbo.v_dimDSLifeCycle WITH (NOLOCK) WHERE LifeCycleName = 'Qual Get Team'
		END

		IF @Team = 'M' 
		BEGIN
			INSERT #team (team) VALUES ('M')
			SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'MillTeam'
			SELECT @HistoryTeam = LifeCycleCode From dbo.v_dimDSLifeCycle WITH (NOLOCK) WHERE LifeCycleName = 'Qual Mill Team'
		END
	
		IF @Team = 'P'
		BEGIN
			INSERT #team (team) VALUES ('P')
			INSERT #team (team) VALUES ('A')
			INSERT #team (team) VALUES ('B')
			INSERT #team (team) VALUES ('C')
			SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'PresTeam'
			SELECT @HistoryTeam = LifeCycleCode From dbo.v_dimDSLifeCycle WITH (NOLOCK) WHERE LifeCycleName = 'Qual Pres Team'
		END

		/******************************************************************************
			get current world team and qual date
		******************************************************************************/
		CREATE TABLE #distqual (
			PK_Qualification int
			,PK_Distributor int
			,RoyaltyMonth smalldatetime
			,PK_Country int
			,IsDeleted bit
			,IsType23 bit
			,IsDNR bit
		)

		-- H.dThrough = '2049-12-31' because we want the currently active record associated to the distributor's current team.
		INSERT
			#distqual
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
				@QualID
				,D.PK_Distributor
				,MIN(H.dFrom)
				,D.PK_COP 
				,CASE WHEN D.StatusCode = 'COMPLETE' THEN 0 ELSE 1 END
				,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END
				,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
			FROM
				pubEvents.dbo.dimDistributor D WITH (NOLOCK)
			LEFT JOIN
				dbo.v_DistributorHistory H
				ON
				D.PK_Distributor = H.nDistributorIDFK
				AND
				H.nEventTypeLID = @HistoryTeam
				AND
				H.dThrough = @ValidDate
			LEFT JOIN
				(SELECT nDistributorID FROM dbo.v_IsType23Distributor) T
				ON D.PK_Distributor = T.nDistributorID
			LEFT JOIN
				dbo.v_DistributorDoNotRecognize R
				ON
				D.PK_Distributor = R.PK_Distributor
			WHERE
				LEFT(D.TeamCode,1) IN (SELECT team FROM #team)
			GROUP BY
				D.PK_Distributor
				,D.PK_COP
				,CASE WHEN D.StatusCode = 'COMPLETE' THEN 0 ELSE 1 END
				,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END
				,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
 
		 CREATE INDEX IX_#distqual_PK_Distributor ON #distqual(PK_Distributor)
		/******************************************************************************
			Merge distributors from qualfication in production table
		******************************************************************************/
		; WITH Teams(PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR) AS
		(SELECT PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR 
		 FROM dbo.QualificationDistributor WITH (NOLOCK) WHERE PK_Qualification = @QualID)
		 MERGE Teams SP
		 USING #distqual DQ
		 ON SP.PK_Distributor = DQ.PK_Distributor
		 WHEN MATCHED AND (SP.IsDeleted <> DQ.IsDeleted OR SP.IsType23 <> DQ.IsType23 OR SP.IsDNR <> DQ.IsDNR) THEN
		 UPDATE
			SET
				SP.RoyaltyMonth = DQ.RoyaltyMonth
				,SP.PK_Country = DQ.PK_Country
				,SP.IsDeleted = DQ.IsDeleted
				,SP.IsType23 = DQ.IsType23
				,SP.IsDNR = DQ.IsDNR
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

		DROP TABLE #distqual

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
GO

