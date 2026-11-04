CREATE TABLE [dbo].[ColorByLevel] (
    [Level]      INT          NOT NULL,
    [ColorValue] VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_Level] PRIMARY KEY CLUSTERED ([Level] ASC)
);

