
CREATE FUNCTION [dbo].[udf_GetPeriodsByFrequency](
    @StartDate datetime2
    ,@EndDate datetime2
    ,@Frequency int
    ,@PeriodType int = 0
    ,@FilterByPeriod bit = 0
)
RETURNS TABLE
AS
/*-----------------------------------------------------------------------------
    
    OBJECT:            [dbo].[udf_GetPeriodsByFrequency]
    
    USE:    
        * @Frequency -> Number of months in the period (1 for no periods).
            !!! @Frequency 0 will get an error
        * @PeriodType -> 0 - EndDate is (StartDate + (@Frequency - 1))
                        1 - EndDate and StartDate are the same
        * @FilterByPeriod -> The result set only includes IsPeriodBase = 1
 
            SELECT * 
                FROM [dbo].[udf_GetPeriodsByFrequency](
                        '20180101'        -- StartDate
                        ,'20181201'        -- EndDate
                        ,2                -- Frequency
                        ,0                -- Period type
                        ,0                -- Filter by period
                    )
 
    DESCRIPTION: Returns a row for every period in a date range
        * The basic unit for period calculation is month
        * There will be n periods depending on the frequency. Each period will have n months and will be grouped by DateGroup.
        * Columns: The names are self explanatory; the first two columns for datetime and the last two for int yyyymmdd dates
            -- [n] Sequential number, starting with 0
            -- [PeriodGroup] Id column for periods defined by @Frequency
            -- [IsPeriodBase] This month is the period start
            -- [IsPeriodEnd] This month is the period end
 
    NOTES:
 
    DEPENDENCIES
    --------------------------------------------------------------------
 
    VERSIONS
    --------------------------------------------------------------------
    1.0.0        2018-08-29        RogelioR        Initial
    
-----------------------------------------------------------------------------*/
RETURN
    SELECT
            [n]
            ,([n] / @Frequency) AS [PeriodGroup]
            ,CASE WHEN [n] % @Frequency = 0 THEN 1 ELSE 0 END AS [IsPeriodBase]
            ,CASE WHEN (([n] + 1) % @Frequency) = 0 THEN 1 ELSE 0 END AS [IsPeriodEnd]
            ,DATEADD(MONTH, [n], @StartDate) AS [dStartDate]
            ,CASE WHEN @PeriodType = 0 THEN DATEADD(MONTH, [n] + (@Frequency - 1), @StartDate)
                    WHEN @PeriodType = 1 THEN DATEADD(MONTH, [n], @StartDate)
                END 
            AS [dEndDate]
            ,CAST(CONVERT(varchar(MAX), DATEADD(MONTH, [n], @StartDate), 112) AS int) AS [iStartDate]
            ,CAST(CONVERT(varchar(MAX), (
                CASE WHEN @PeriodType = 0 THEN DATEADD(MONTH, [n] + (@Frequency - 1), @StartDate)
                    WHEN @PeriodType = 1 THEN DATEADD(MONTH, [n], @StartDate)
                END), 112) AS int)
            AS [iEndDate]
        FROM [Numbers] WITH (NOLOCK)
        WHERE [n] <= DATEDIFF(MONTH, @StartDate, @EndDate)
            AND ((@FilterByPeriod = 0) OR (CASE WHEN [n] % @Frequency = 0 THEN 1 ELSE 0 END) = 1);