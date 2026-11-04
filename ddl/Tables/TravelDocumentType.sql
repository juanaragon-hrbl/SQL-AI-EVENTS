CREATE TABLE [dbo].[TravelDocumentType] (
    [PK_TravelDocumentType] INT           NOT NULL,
    [DocumentTypeDesc]      VARCHAR (240) NOT NULL,
    [CreatedDate]           DATETIME      DEFAULT (getdate()) NULL,
    [CreatedBy]             VARCHAR (30)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDate]          DATETIME      DEFAULT (getdate()) NULL,
    [ModifiedBy]            VARCHAR (30)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [CS_TravelDocumentType_PK_TravelDocumentType] PRIMARY KEY CLUSTERED ([PK_TravelDocumentType] ASC)
);

