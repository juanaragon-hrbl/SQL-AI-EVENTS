
CREATE PROCEDURE [dbo].[usp_Maintain_DistributorTransfer]
AS
BEGIN

/******************************************************************************
OBJECT:			usp_Maintain_DistributorTransfer

USE:	        
                 EXEC dbo.usp_Maintain_DistributorTransfer

DESCRIPTION:	process transfer on bizworks related table

NOTES:			

VERSIONS
----------------------------------------------------------------------------------
1	2016-02-04	EmiN	Intitial

******************************************************************************/



UPDATE 
	A
SET
	A.DistributorID = TF.RollupDS
	,A.PK_Distributor_EDW = D.nDistributorID
	,ModifiedDateUTC = GETUTCDATE()
	,ModifiedBy = 'PostSQL-TransferProc'
FROM 
	[dbo].[AWT_BizWork_Qualifiers] A WITH (NOLOCK)
INNER JOIN
	[dbo].[wrk_DistributorTransferExtract] TF WITH (NOLOCK)
	ON
		A.DistributorID = TF.FromDS
INNER JOIN 
	dbo.v_Distributor D
	ON 
		D.sDistributorID = TF.RollupDS

;WITH Dup AS
(
	SELECT
		PK_AWT_BizWork
	   ,PK_Distributor_EDW
	   ,PK_Distributor
	   ,DistributorID
	   ,AWTYear
	   ,DateAdded
	   ,Qual_AWT
	   ,CreatedDateUTC
	   ,CreatedBy
	   ,ModifiedDateUTC
	   ,ModifiedBy
		,ROW_NUMBER() OVER (PARTITION BY DistributorID, AWTYear ORDER BY Qual_AWT, DateAdded) AS Rnk
	FROM
		[dbo].[AWT_BizWork_Qualifiers] WITH (NOLOCK)
)

DELETE
FROM 
	Dup
WHERE 
	Rnk > 1

END
GO

