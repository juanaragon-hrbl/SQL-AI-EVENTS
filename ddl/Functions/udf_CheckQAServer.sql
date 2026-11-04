CREATE FUNCTION dbo.udf_CheckQAServer (
@ServerName VARCHAR(30)
)
/******************************************************************************
	OBJECT:		dbo.udf_CheckQAServer
	USE:	SELECT dbo.udf_CheckQAServer ('QAServer')

	DESCRIPTION:	Validation for QA Servers
	NOTES:
	DEPENDENCIES
	--------------------------------------------------------------------
	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2026-02-22		rosarioo		Initial
******************************************************************************/
RETURNS BIT
AS
BEGIN
DECLARE @Result BIT

    SELECT @Result = 
    CASE
	WHEN @ServerName = 'ZUSW2Q3ENSQLDB' THEN 1 
	WHEN @ServerName = 'ZUSW2Q3ENSQLDB'	THEN 1 
	WHEN @ServerName = 'ZUSW2Q2ENSQLDB'	THEN 1 
	WHEN @ServerName = 'ZUSW2Q1ENSQLDB'	THEN 1 
	WHEN @ServerName = 'ZUSWQAENSQL01'	THEN 1 

	ELSE 0 END
	-- Return the result of the function
	RETURN @Result
END

