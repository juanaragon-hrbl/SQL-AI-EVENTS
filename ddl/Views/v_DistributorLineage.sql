

CREATE VIEW [dbo].[v_DistributorLineage]
AS
SELECT 
	--DSL.PK_DSLngUpline AS nLineageID
	DSL.PK_Distributor AS nDistributorID
	,DSL.PK_Sponsor AS nSponsorID
	,DSL.LineageTree AS vcLineage
	,DSL.Level AS nLevel
	,DSL.FirstUplineSP AS n1stSupervisorID
	,DSL.FirstUplineGet AS n1stGetTeamMemberID
	,DSL.FirstUplineMill AS n1stMillTeamMemberID
	,DSL.FirstUplinePres AS n1stPresidentID
	,DSL.FirstUplineCC AS n1stChairmanID
	,DSL.FirstUplineTAB AS nIstTABID
FROM
	pubEvents.dbo.dimDSLngUpline DSL (NOLOCK)