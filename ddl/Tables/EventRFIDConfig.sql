CREATE TABLE [dbo].[EventRFIDConfig] (
    [PK_EventRFIDConfig] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Event]           INT           NOT NULL,
    [CreatedDate]        DATETIME      DEFAULT (getdate()) NULL,
    [CreatedBy]          VARCHAR (30)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDate]       DATETIME      DEFAULT (getdate()) NULL,
    [ModifiedBy]         VARCHAR (30)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [RFID_dllFileName]   VARCHAR (100) NULL,
    [RFID_dllNamespace]  VARCHAR (100) NULL,
    CONSTRAINT [CS_EventRFIDConfig_PK_EventRFIDConfig] PRIMARY KEY CLUSTERED ([PK_EventRFIDConfig] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EventRFIDConfig_PK_Event]
    ON [dbo].[EventRFIDConfig]([PK_Event] ASC);

