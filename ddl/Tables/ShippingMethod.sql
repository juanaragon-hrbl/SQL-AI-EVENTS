CREATE TABLE [dbo].[ShippingMethod] (
    [PK_ShippingMethod] INT           IDENTITY (1, 1) NOT NULL,
    [ShippingMethod]    VARCHAR (20)  NOT NULL,
    [CreatedDateUTC]    SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]         NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_ShippingMethod] PRIMARY KEY CLUSTERED ([PK_ShippingMethod] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ShippingMethod_ShippingMethod]
    ON [dbo].[ShippingMethod]([ShippingMethod] ASC);

