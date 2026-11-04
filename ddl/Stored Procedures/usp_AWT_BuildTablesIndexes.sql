
CREATE PROCEDURE [dbo].[usp_AWT_BuildTablesIndexes]
	@AWTYear int = 2009
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_BuildTablesIndexes

USE:			dbo.usp_AWT_BuildTablesIndexes

DESCRIPTION:	rebuilds indexes for AWT tables


DEPENDENCIES
--------------------------------------------------------------------
everything

VERSIONS
--------------------------------------------------------------------
1	2010-01-05	Scott	Initial

******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	AWT
******************************************************************************/
IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_PK_Distributor')  DROP INDEX AWT.IX_AWT_PK_Distributor
CREATE INDEX IX_AWT_PK_Distributor ON dbo.AWT (PK_Distributor)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_AWTYear')  DROP INDEX AWT.IX_AWT_AWTYear
CREATE INDEX IX_AWT_AWTYear ON dbo.AWT (AWTYear)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_PK_MainDistributor')  DROP INDEX AWT.IX_AWT_PK_MainDistributor
CREATE INDEX IX_AWT_PK_MainDistributor ON dbo.AWT (PK_MainDistributor)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_DistributorID')  DROP INDEX AWT.IX_AWT_DistributorID
CREATE INDEX IX_AWT_DistributorID ON dbo.AWT (DistributorID)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_MainDistributorID')  DROP INDEX AWT.IX_AWT_MainDistributorID
CREATE INDEX IX_AWT_MainDistributorID ON dbo.AWT (MainDistributorID)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_COP')  DROP INDEX AWT.IX_AWT_COP
CREATE INDEX IX_AWT_COP ON dbo.AWT (COP)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Qual_SP')  DROP INDEX AWT.IX_AWT_Qual_SP
CREATE INDEX IX_AWT_Qual_SP ON dbo.AWT (Qual_SP)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Qual_G')  DROP INDEX AWT.IX_AWT_Qual_G
CREATE INDEX IX_AWT_Qual_G ON dbo.AWT (Qual_G)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Qual_W')  DROP INDEX AWT.IX_AWT_Qual_W
CREATE INDEX IX_AWT_Qual_W ON dbo.AWT (Qual_W)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Qual_AWT')  DROP INDEX AWT.IX_AWT_Qual_AWT
CREATE INDEX IX_AWT_Qual_AWT ON dbo.AWT (Qual_AWT)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_UplinePresID1')  DROP INDEX AWT.IX_AWT_UplinePresID1
CREATE INDEX IX_AWT_UplinePresID1 ON dbo.AWT (UplinePresID1)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_UplinePresID2')  DROP INDEX AWT.IX_AWT_UplinePresID2
CREATE INDEX IX_AWT_UplinePresID2 ON dbo.AWT (UplinePresID2)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_UplinePresID3')  DROP INDEX AWT.IX_AWT_UplinePresID3
CREATE INDEX IX_AWT_UplinePresID3 ON dbo.AWT (UplinePresID3)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_UplineSPID1')  DROP INDEX AWT.IX_AWT_UplineSPID1
CREATE INDEX IX_AWT_UplineSPID1 ON dbo.AWT (UplineSPID1)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_UplineSPID2')  DROP INDEX AWT.IX_AWT_UplineSPID2
CREATE INDEX IX_AWT_UplineSPID2 ON dbo.AWT (UplineSPID2)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_UplineSPID3')  DROP INDEX AWT.IX_AWT_UplineSPID3
CREATE INDEX IX_AWT_UplineSPID3 ON dbo.AWT (UplineSPID3)

/******************************************************************************
	AWT_Qualifiers
******************************************************************************/
IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Qualifiers_AWTYear')  DROP INDEX AWT_Qualifiers.IX_AWT_Qualifiers_AWTYear
CREATE INDEX IX_AWT_Qualifiers_AWTYear ON dbo.AWT_Qualifiers (AWTYear)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Qualifiers_PK_Distributor')  DROP INDEX AWT_Qualifiers.IX_AWT_Qualifiers_PK_Distributor
CREATE INDEX IX_AWT_Qualifiers_PK_Distributor ON dbo.AWT_Qualifiers (PK_Distributor)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Qualifiers_DistributorID')  DROP INDEX AWT_Qualifiers.IX_AWT_Qualifiers_DistributorID
CREATE INDEX IX_AWT_Qualifiers_DistributorID ON dbo.AWT_Qualifiers (DistributorID)

/******************************************************************************
	AWT_PrevQualifiers
******************************************************************************/
IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_PrevQualifiers_AWTYear')  DROP INDEX AWT_PrevQualifiers.IX_AWT_PrevQualifiers_AWTYear
CREATE INDEX IX_AWT_PrevQualifiers_AWTYear ON dbo.AWT_PrevQualifiers (AWTYear)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_PrevQualifiers_PK_Distributor')  DROP INDEX AWT_PrevQualifiers.IX_AWT_PrevQualifiers_PK_Distributor
CREATE INDEX IX_AWT_PrevQualifiers_PK_Distributor ON dbo.AWT_PrevQualifiers (PK_Distributor)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_PrevQualifiers_DistributorID')  DROP INDEX AWT_PrevQualifiers.IX_AWT_PrevQualifiers_DistributorID
CREATE INDEX IX_AWT_PrevQualifiers_DistributorID ON dbo.AWT_PrevQualifiers (DistributorID)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_PrevQualifiers_PK_AWT_Qualifiers')  DROP INDEX AWT_PrevQualifiers.IX_AWT_PrevQualifiers_PK_AWT_Qualifiers
CREATE INDEX IX_AWT_PrevQualifiers_PK_AWT_Qualifiers ON dbo.AWT_PrevQualifiers (PK_AWT_Qualifiers)

/******************************************************************************
	AWT_ManualOverride
******************************************************************************/
IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_ManualOverride_AWTYear')  DROP INDEX AWT_ManualOverride.IX_AWT_ManualOverride_AWTYear
CREATE INDEX IX_AWT_ManualOverride_AWTYear ON dbo.AWT_ManualOverride (AWTYear)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_ManualOverride_PK_Distributor')  DROP INDEX AWT_ManualOverride.IX_AWT_ManualOverride_PK_Distributor
CREATE INDEX IX_AWT_ManualOverride_PK_Distributor ON dbo.AWT_ManualOverride (PK_Distributor)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_ManualOverride_DistributorID')  DROP INDEX AWT_ManualOverride.IX_AWT_ManualOverride_DistributorID
CREATE INDEX IX_AWT_ManualOverride_DistributorID ON dbo.AWT_ManualOverride (DistributorID)

/******************************************************************************
	AWT_Accelerator
******************************************************************************/
IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Accelerator_AWTYear')  DROP INDEX AWT_Accelerator.IX_AWT_Accelerator_AWTYear
CREATE INDEX IX_AWT_Accelerator_AWTYear ON dbo.AWT_Accelerator (AWTYear)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Accelerator_PK_AWT_AcceleratorType')  DROP INDEX AWT_Accelerator.IX_AWT_Accelerator_PK_AWT_AcceleratorType
CREATE INDEX IX_AWT_Accelerator_PK_AWT_AcceleratorType ON dbo.AWT_Accelerator (PK_AWT_AcceleratorType)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Accelerator_Royaltymonth')  DROP INDEX AWT_Accelerator.IX_AWT_Accelerator_Royaltymonth
CREATE INDEX IX_AWT_Accelerator_Royaltymonth ON dbo.AWT_Accelerator (Royaltymonth)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Accelerator_COP')  DROP INDEX AWT_Accelerator.IX_AWT_Accelerator_COP
CREATE INDEX IX_AWT_Accelerator_COP ON dbo.AWT_Accelerator (COP)

/******************************************************************************
	AWT_Metrics
******************************************************************************/
IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Metrics_PK_Distributor')  DROP INDEX AWT_Metrics.IX_AWT_Metrics_PK_Distributor
CREATE INDEX IX_AWT_Metrics_PK_Distributor ON dbo.AWT_Metrics (PK_Distributor)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Metrics_DistributorID')  DROP INDEX AWT_Metrics.IX_AWT_Metrics_DistributorID
CREATE INDEX IX_AWT_Metrics_DistributorID ON dbo.AWT_Metrics (DistributorID)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Metrics_Royaltymonth')  DROP INDEX AWT_Metrics.IX_AWT_Metrics_Royaltymonth
CREATE INDEX IX_AWT_Metrics_Royaltymonth ON dbo.AWT_Metrics (Royaltymonth)

IF EXISTS (SELECT name FROM sysindexes WITH (NOLOCK) WHERE name = 'IX_AWT_Metrics_Qual_SP')  DROP INDEX AWT_Metrics.IX_AWT_Metrics_Qual_SP
CREATE INDEX IX_AWT_Metrics_Qual_SP ON dbo.AWT_Metrics (Qual_SP)

/******************************************************************************
	end procedure
******************************************************************************/
END