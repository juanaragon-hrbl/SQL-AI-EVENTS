CREATE TABLE [dbo].[WRK_SubEventQualifier] (
    [PK_Event]       INT      NULL,
    [PK_Distributor] INT      NULL,
    [SubEventNumber] SMALLINT NULL,
    [SubEventQual]   BIT      NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_WRK_SubEventQualifier_PK_Distributor]
    ON [dbo].[WRK_SubEventQualifier]([PK_Distributor] ASC);

