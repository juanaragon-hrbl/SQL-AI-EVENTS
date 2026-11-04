CREATE TABLE [dbo].[ColorTypes] (
    [PK_ColorType]     INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ColorDescription] VARCHAR (100) NOT NULL,
    [ColorType]        VARCHAR (30)  NOT NULL,
    [ColorValue]       VARCHAR (30)  NOT NULL,
    [ColorImage]       IMAGE         NULL,
    [CreatedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [ColorTypes_PK] PRIMARY KEY CLUSTERED ([PK_ColorType] ASC) WITH (FILLFACTOR = 80)
);

