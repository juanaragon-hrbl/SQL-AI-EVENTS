CREATE TYPE [dbo].[udt_QualByPoints] AS TABLE (
    [StartDate]   DATE        NULL,
    [EndDate]     DATE        NULL,
    [Frequency]   SMALLINT    NULL,
    [Consecutive] BIT         NULL,
    [Accumulated] BIT         NULL,
    [MetricType]  VARCHAR (4) NULL,
    [MinPoints]   MONEY       NULL,
    [GoalPoints]  MONEY       NULL);

