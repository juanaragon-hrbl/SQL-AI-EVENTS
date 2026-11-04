--
CREATE FUNCTION [dbo].[udf_SplitString](
	@Text NVARCHAR(MAX),
	@Delimiter NVARCHAR(50)
) RETURNS @t TABLE (PK_Id INT IDENTITY(1,1), Val NVARCHAR(MAX))
AS
BEGIN
	DECLARE @xml XML
	SET @xml = N'<t>' + REPLACE(@Text,@Delimiter,'</t><t>') + '</t>'

	INSERT INTO @t(val)
	SELECT 
		r.value('.','varchar(MAX)') as item
	FROM  
		@xml.nodes('/t') as records(r)
	RETURN
END