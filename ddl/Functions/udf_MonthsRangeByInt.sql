CREATE FUNCTION [dbo].[udf_MonthsRangeByInt](@RootDate datetime2, @Months int, @Factor smallint)
		RETURNS TABLE
		AS
		RETURN 
			SELECT
					[n]
					,DATEADD(month, @Factor * [n], @RootDate) AS [dDate]
					,CAST(CONVERT(varchar(8), DATEADD(month, @Factor * [n], @RootDate), 112) AS int) AS [iDate]
					,DATEADD(DAY, 1, EOMONTH((DATEADD(month, @Factor * [n], @RootDate)), -1)) AS [dMonthStart]
					,CAST(CONVERT(varchar(8), DATEADD(DAY, 1, EOMONTH((DATEADD(month, @Factor * [n], @RootDate)), -1)), 112) AS int) AS [iMonthStart]
					,CAST(CONVERT(varchar(6), DATEADD(DAY, 1, EOMONTH((DATEADD(month, @Factor * [n], @RootDate)), -1)), 112) AS int) AS [iMonth]
				FROM [Numbers] WITH (NOLOCK)
				WHERE [n] < @Months