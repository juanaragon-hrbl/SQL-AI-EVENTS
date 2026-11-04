CREATE PROCEDURE [dbo].[usp_QualStd]
	@UseAllQualfications bit = 0
	,@IsDevQA bit = 0
AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE
	@StoredProcedure varchar(100)
	,@ProcParam varchar(100)
	,@StartTime datetime

DECLARE @TV VARCHAR(5) = 'TV',
		@RO VARCHAR(5) = 'RO',
		@PPV VARCHAR(5) = 'PPV',
		@DLV VARCHAR(5) = 'DLV',
		@PLV VARCHAR(5) = 'PLV',
		@PB VARCHAR(5) = 'PB',
		@PBC VARCHAR(5) = 'PBC'

SET @StoredProcedure = OBJECT_NAME(@@PROCID)
SET @ProcParam = ''
SET @StartTime = GETUTCDATE()

IF EXISTS (SELECT 1 FROM [DevAdmin].[ScheduleException] WITH (NOLOCK)
WHERE Active = 1 AND CONVERT(DATE,GETUTCDATE()) BETWEEN StartDate AND EndDate
AND TRIM(REPLACE(REPLACE([StoredProcedureName],'[',''),']','')) = TRIM(REPLACE(REPLACE(@StoredProcedure,'[',''),']','')))
BEGIN
	PRINT 'ScheduleException; The process is skipped.'
	RETURN;
END
ELSE
BEGIN

	-- Disable Indexes
	ALTER INDEX IX_QualificationDistributor_Combine ON dbo.QualificationDistributor DISABLE
	ALTER INDEX IX_QualificationDistributor_PK_Country ON dbo.QualificationDistributor DISABLE
	ALTER INDEX IX_QualificationDistributor_PK_Distributor ON dbo.QualificationDistributor DISABLE
	ALTER INDEX IX_QualificationDistributor_RoyaltyMonth ON dbo.QualificationDistributor DISABLE

	-- Disable Foreign Constraint Check
	ALTER TABLE [dbo].[QualificationDistributor] NOCHECK CONSTRAINT [QualificationQualificationDistributor_FK]

	-- Update LeadAssignment Events If Necessary. 
	-- Scheduled within the called stored procedure to only update on the 16th, 17th and 18th day of each month
	-- when PB for Previous Month is assumed to have been completed.
	-- Intentionally made to run those 3 days just in case the run on the first days failed for what ever reason.
	-- Once updated, ok till the next PB Run
	-- Added PBC on 2015-04-02 on consecutive where production bonus of associate and main are combined. Used by lead assignment criteria
	-- Taking DistributorSet from dbo.AWT_Definitions according to the current year
	DECLARE @pInAWTPreviousYear INT = (SELECT DistributorSet FROM dbo.AWT_Definitions WITH (NOLOCK) WHERE AWTYear = YEAR(DATEADD(YEAR,-1,GETUTCDATE())))
	DECLARE @pInAWTCurrentYear INT = (SELECT DistributorSet FROM dbo.AWT_Definitions WITH (NOLOCK) WHERE AWTYear = YEAR(GETUTCDATE()))

	-- In case the AWT setup is not ready for the current year, the previous year config will be taken 
	IF @pInAWTCurrentYear IS NULL
	BEGIN
		SELECT @pInAWTPreviousYear = DistributorSet FROM dbo.AWT_Definitions WITH (NOLOCK) WHERE AWTYear = YEAR(DATEADD(YEAR,-2,GETUTCDATE())) 
		SELECT @pInAWTCurrentYear = DistributorSet FROM dbo.AWT_Definitions WITH (NOLOCK) WHERE AWTYear = YEAR(DATEADD(YEAR,-1,GETUTCDATE()))
	END

	EXEC dbo.usp_Update_LeadMgmtEvents @InAWTPreviousYear = @pInAWTPreviousYear, @InAWTCurrentYear = @pInAWTCurrentYear

	EXEC dbo.usp_QualStd_DSTypeSupervisor
	EXEC dbo.usp_QualStd_DSTypeNonSupervisor
	EXEC dbo.usp_QualStd_DSTypeQualifiedProducers
	EXEC dbo.usp_QualStd_DSTypeSuccessBuilders
	EXEC dbo.usp_QualStd_DSTypeSeniorConsultant
	EXEC dbo.usp_QualStd_DSTypeQualifyingSupervisor

	EXEC dbo.usp_QualStd_SPTeamChairmansClub
	EXEC dbo.usp_QualStd_SPPresKTeams
	EXEC dbo.usp_QualStd_SPTeamNone
	EXEC dbo.usp_QualStd_SPTeamDemoted

	EXEC dbo.usp_QualStd_SPTeam 'W'
	EXEC dbo.usp_QualStd_SPTeam 'G'
	EXEC dbo.usp_QualStd_SPTeam 'M'
	EXEC dbo.usp_QualStd_SPTeam 'P'

	EXEC dbo.usp_QualStd_TV_RO_PB_Single @TV ,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Single @RO,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Single @PPV,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Single @DLV,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Single @PLV,@UseAllQualfications,@IsDevQA 

	EXEC dbo.usp_QualStd_TV_RO_PB_Consecutive @TV,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Consecutive @RO,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Consecutive @PB,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Consecutive @PPV,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Consecutive @DLV,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Consecutive @PBC,@UseAllQualfications,@IsDevQA

	EXEC dbo.usp_QualStd_TV_RO_PB_Accumulated @TV,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Accumulated @RO,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Accumulated @PPV,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Accumulated @DLV,@UseAllQualfications,@IsDevQA
	EXEC dbo.usp_QualStd_TV_RO_PB_Accumulated @PLV,@UseAllQualfications,@IsDevQA

	-- Enable Indexes
	ALTER INDEX IX_QualificationDistributor_Combine ON dbo.QualificationDistributor REBUILD
	ALTER INDEX IX_QualificationDistributor_PK_Country ON dbo.QualificationDistributor REBUILD
	ALTER INDEX IX_QualificationDistributor_PK_Distributor ON dbo.QualificationDistributor REBUILD
	ALTER INDEX IX_QualificationDistributor_RoyaltyMonth ON dbo.QualificationDistributor REBUILD

	-- Enable Check Constraint
	ALTER TABLE [dbo].[QualificationDistributor] CHECK CONSTRAINT [QualificationQualificationDistributor_FK]

	EXEC dbo.usp_QualStd_Custom @IsDevQA

	/******************************************************************************
		end procedure
	******************************************************************************/
	EXEC usp_Utility_UpdateProcessingLog
		@StoredProcedureName = @StoredProcedure
		,@StoredProcedureParameters = @ProcParam
		,@StartTime = @StartTime
END
END