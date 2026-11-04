CREATE TABLE [dbo].[Currency] (
    [PK_Currency]     INT           NULL,
    [AlphaCode]       VARCHAR (3)   NULL,
    [Currency]        VARCHAR (255) NULL,
    [Active]          BIT           NULL,
    [CreatedDateUTC]  DATETIME2 (7) DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (255) DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME2 (7) DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (255) DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Currency_PK_Currency]
    ON [dbo].[Currency]([PK_Currency] ASC);

