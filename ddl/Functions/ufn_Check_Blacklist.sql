-- =============================================
-- Author: JuanH
-- Create date: 2017-04-07
-- Description: Blacklist of SQL reservered words  to prevent SQL injection- Return Values 1 = fail / 0 = pass
-- =============================================
CREATE FUNCTION dbo.ufn_Check_Blacklist 
(
	@str_input nvarchar(max)
)
RETURNS BIT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result BIT

    SELECT @Result = 
    CASE 
        WHEN CHARINDEX('DROP',@str_input) > 0 THEN 1 
        WHEN CHARINDEX('CREATE',@str_input) > 0 THEN 1
        WHEN CHARINDEX('ALTER',@str_input) > 0 THEN 1 
		WHEN CHARINDEX('DELETE',@str_input) > 0 THEN 1
        WHEN CHARINDEX('MERGE',@str_input) > 0 THEN 1
        WHEN CHARINDEX('TRUNCATE',@str_input) > 0 THEN 1
        WHEN CHARINDEX('UPDATE',@str_input) > 0 THEN 1

		/* ***************** SonarQube check 117 - Related "IF"/"ELSE IF" statements and "WHEN" clauses in a "CASE" should not have the same condition */
        ----WHEN CHARINDEX('DELETE',@str_input) > 0 THEN 1
		/* ***************** SonarQube check 117 */

        WHEN CHARINDEX('INSERT',@str_input) > 0 THEN 1
        WHEN CHARINDEX('BEGIN',@str_input) > 0 THEN 1
        WHEN CHARINDEX('END',@str_input) > 0 THEN 1
        WHEN CHARINDEX('EXEC',@str_input) > 0 THEN 1
        WHEN CHARINDEX('TRAN',@str_input) > 0 THEN 1
        WHEN CHARINDEX('COMMIT',@str_input) > 0 THEN 1
        WHEN CHARINDEX('ROLLBACK',@str_input) > 0 THEN 1
        WHEN CHARINDEX('OPENQUERY',@str_input) > 0 THEN 1

        ELSE 0
	END

	-- Return the result of the function
	RETURN @Result

END