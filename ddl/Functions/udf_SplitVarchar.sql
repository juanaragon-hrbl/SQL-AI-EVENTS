
CREATE FUNCTION [dbo].[udf_SplitVarchar](
	@s nvarchar(max)
	,@Delimiter nvarchar(10)
)
RETURNS TABLE
/******************************************************************************

	OBJECT:		dbo.[udf_SplitVarchar]
	
	USE:
			SELECT * FROM dbo.[udf_SplitVarchar]('es-PR,en-US', ',')
					
	DESCRIPTION:	Split a comma separated string into a single column table

	NOTES:
		Will return a table with row for every string chunk
	
	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-10-24		RogelioR		Initial
	
******************************************************************************/
AS
RETURN
	WITH cte AS(
		SELECT CAST('<r><l>' + REPLACE(@s, @Delimiter, '</l><l>') + '</l></r>' AS XML) AS x
	)
	SELECT 
			LTRIM(RTRIM(x.s.value('.[1]','nvarchar(max)'))) AS [String]
		FROM cte
			CROSS APPLY x.nodes('/r/l') AS x(s)