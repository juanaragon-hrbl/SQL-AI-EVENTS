CREATE PROCEDURE [dbo].[usp_PromotionAccelerator_ProcessQualifers]
       @IsDevQA		BIT = 0,   
	   @Error	int = 0 OUTPUT,
	   @ErrorMessage varchar(4000) = NULL OUTPUT

AS
BEGIN

/*********************************************************************************************************************
	OBJECT:		dbo.usp_PromotionAccelerator_ProcessQualifers
		
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_PromotionAccelerator_ProcessQualifers 
				
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
	NOTES:		
			Check if work table exist

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2010
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1 
	2	2019-10-16	 JonathanO		Refactor code (SRE)


***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

BEGIN TRY

IF OBJECT_ID('dbo.wrkPromotionAcceleratorQualifier') IS NOT NULL 
   TRUNCATE TABLE dbo.wrkPromotionAcceleratorQualifier
ELSE
CREATE TABLE [dbo].[wrkPromotionAcceleratorQualifier](
	[PK_PromotionAcceleratorQualifier] [int] IDENTITY(1,1) NOT NULL,
	[RoyaltyMonth] [datetime] NOT NULL,
	[TotalPoints] [int] NOT NULL,
	[CreatedDateUTC] [datetime] NOT NULL DEFAULT GETUTCDATE(),
	[CreatedBy] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT replace(suser_sname(),'HERBALIFECORP\',''),
	[ModifiedDateUTC] [datetime] NULL,
	[ModifiedBy] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PK_Distributor] [int] NOT NULL,
	[PK_PromotionAcceleratorCountry] [int] NOT NULL
)
 

insert into dbo.wrkPromotionAcceleratorQualifier(
RoyaltyMonth,
TotalPoints,
PK_Distributor,
PK_PromotionAcceleratorCountry)
select am.RoyaltyMonth,
       case when p.PK_QualificationType = 1 Then agg.mVolumePoints + p.AcceleratorPoint
			when p.PK_QualificationType = 2 Then agg.mRoyaltyOverrides + mMainRoyaltyOverrides + p.AcceleratorPoint
			when p.PK_QualificationType = 3 Then agg.mProductionBonus + p.AcceleratorPoint
       else null end TotalPoints,
       agg.nDistributorID,
	   pc.PK_PromotionAcceleratorCountry
from   
	dbo.PromotionAccelerator p WITH (NOLOCK)
inner join
	dbo.promotionAcceleratorMonths am WITH (NOLOCK)
on  p.PK_promotionAccelerator = am.PK_promotionAccelerator
inner join 
    dbo.PromotionAcceleratorCountry pc WITH (NOLOCK)
on  pc.PK_PromotionAcceleratorMonth = am.PK_PromotionAcceleratorMonth
inner join
	dbReport.dbo.aggFQS_ID agg WITH (NOLOCK)
on  am.RoyaltyMonth = agg.dRoyaltyMonth
inner join dbo.v_Countries vc
on  vc.sCountryCode = agg.sCOP	
and vc.nCountryID = pc.PK_Country
where p.BreakPoint <= case when p.PK_QualificationType = 1 Then agg.mVolumePoints 
						   when p.PK_QualificationType = 2 Then agg.mRoyaltyOverrides + mMainRoyaltyOverrides 
						   when p.PK_QualificationType = 3 Then agg.mProductionBonus 
					  else p.BreakPoint-1 end    

/******************************************************************************
	replace production table
******************************************************************************/
IF OBJECT_ID('dbo.PromotionAcceleratorQualifier') IS NOT NULL 

	DROP TABLE dbo.PromotionAcceleratorQualifier
	EXEC sp_rename 'dbo.wrkPromotionAcceleratorQualifier','PromotionAcceleratorQualifier'


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

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;