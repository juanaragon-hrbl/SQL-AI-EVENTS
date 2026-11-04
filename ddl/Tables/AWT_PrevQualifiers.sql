CREATE TABLE [dbo].[AWT_PrevQualifiers] (
    [PK_AWT_Qualifiers] INT           NOT NULL,
    [CreatedDateUTC]    DATETIME      NOT NULL,
    [CreatedBy]         VARCHAR (100) NOT NULL,
    [Flg1]              INT           NULL,
    [AWTYear]           INT           NOT NULL,
    [PK_Distributor]    INT           NOT NULL,
    [DistributorID]     VARCHAR (30)  NULL,
    [DateAdded]         SMALLDATETIME NULL,
    [Qual_AWT]          SMALLDATETIME NULL,
	[PastAWT]           VARCHAR (MAX)
);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_PrevQualifiers_PK_AWT_Qualifiers]
    ON [dbo].[AWT_PrevQualifiers]([PK_AWT_Qualifiers] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_PrevQualifiers_PK_Distributor]
    ON [dbo].[AWT_PrevQualifiers]([PK_Distributor] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_PrevQualifiers_DistributorID]
    ON [dbo].[AWT_PrevQualifiers]([DistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_PrevQualifiers_AWTYear]
    ON [dbo].[AWT_PrevQualifiers]([AWTYear] ASC);

