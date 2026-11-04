CREATE TABLE [dbo].[SourceDate] (
    [MyDate] SMALLDATETIME NOT NULL,
    PRIMARY KEY CLUSTERED ([MyDate] ASC),
    CONSTRAINT [chk_MyDate] CHECK (datepart(day,[MyDate])=(1))
);

