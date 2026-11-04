/*********************************************************************************************************************
	OBJECT:		

	USE:		

	DESCRIPTION: 
	NOTES:			

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2010
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1	2017-09-27   LehiD  	Initial 

***********************************************************************************************************************************/

CREATE FUNCTION dbo.ufn_PeriodTable(@StartDate SMALLDATETIME, @EndDate SMALLDATETIME, @Duration SMALLINT)
RETURNS @PeriodTable TABLE
(
StartDate SMALLDATETIME,
EndDate SMALLDATETIME
)
BEGIN
DECLARE @TempDate SMALLDATETIME
SET @TempDate = @StartDate

WHILE @TempDate <= @EndDate
BEGIN
       IF DATEADD(month,@Duration - 1,@TempDate) <= @EndDate
       INSERT INTO @PeriodTable (StartDate, EndDate) VALUES(@TempDate,DATEADD(month,@Duration - 1,@TempDate))
       SET @TempDate = DATEADD(month,1,@TempDate)
END
RETURN;
END