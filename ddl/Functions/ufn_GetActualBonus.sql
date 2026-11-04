CREATE FUNCTION dbo.ufn_GetActualBonus(@Limit MONEY, @Bonus MONEY)
RETURNS MONEY
AS
BEGIN

    DECLARE @ActualBonus MONEY

    IF ISNULL((@Bonus / NULLIF(@Limit, 0)), 0) > 1
        SET @ActualBonus = @Limit * ISNULL(@Bonus / NULLIF(@Bonus, 0), 0)
    ELSE 
        SET @ActualBonus = @Bonus

    RETURN @ActualBonus

END