CREATE TABLE [dbo].[QualificationDistributor] (
    [PK_QualificationDistributor] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CreatedDateUTC]              DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]                   VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]             DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                  VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Qualification]            INT           NULL,
    [PK_Distributor]              INT           NULL,
    [RoyaltyMonth]                SMALLDATETIME NULL,
    [PK_Country]                  INT           NULL,
    [IsDeleted]                   BIT           NULL,
    [IsDNR]                       BIT           NULL,
    [IsType23]                    BIT           NULL,
    CONSTRAINT [QualificationDistributor_PK] PRIMARY KEY CLUSTERED ([PK_QualificationDistributor] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE),
    CONSTRAINT [QualificationQualificationDistributor_FK] FOREIGN KEY ([PK_Qualification]) REFERENCES [dbo].[Qualification] ([PK_Qualification])
);


GO
CREATE NONCLUSTERED INDEX [IX_QualificationDistributor_PK_Distributor]
    ON [dbo].[QualificationDistributor]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_QualificationDistributor_PK_Qualification]
    ON [dbo].[QualificationDistributor]([PK_Qualification] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_QualificationDistributor_RoyaltyMonth]
    ON [dbo].[QualificationDistributor]([RoyaltyMonth] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_QualificationDistributor_Combine]
    ON [dbo].[QualificationDistributor]([PK_Qualification] ASC)
    INCLUDE([PK_Distributor], [RoyaltyMonth], [IsDeleted]);


GO
CREATE NONCLUSTERED INDEX [IX_QualificationDistributor_PK_Country]
    ON [dbo].[QualificationDistributor]([PK_Country] ASC) WITH (FILLFACTOR = 80);

