CREATE TABLE [dbo].[EventActivityParticipant] (
    [PK_EventActivityParticipant] INT            IDENTITY (1, 1) NOT NULL,
    [PK_EventActivityTransaction] INT            NOT NULL,
    [Name]                        NVARCHAR (200) NULL,
    [Email]                       NVARCHAR (100) NULL,
    [PhoneNumber]                 VARCHAR (50)   NULL,
    [DOB]                         SMALLDATETIME  NULL,
    [TourLanguage]                INT            NULL,
    [IdentificationNumber]        VARCHAR (50)   NULL,
    [IdentificationExpDate]       SMALLDATETIME  NULL,
    [IsDistributor]               BIT            NULL,
    [PK_MealType]                 SMALLINT       CONSTRAINT [DF_EventActivityParticipant_PK_MealType] DEFAULT ((1)) NOT NULL,
    [MealNote]                    NVARCHAR (256) NULL,
    [FlightOption]                NVARCHAR (50)  NULL,
    [CreatedUTC]                  DATETIME       CONSTRAINT [DF_EventActivityParticipant_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                   NVARCHAR (50)  CONSTRAINT [DF_EventActivityParticipant_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]                 DATETIME       CONSTRAINT [DF_EventActivityParticipant_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                  NVARCHAR (50)  CONSTRAINT [DF_EventActivityParticipant_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventActivityParticipant] PRIMARY KEY CLUSTERED ([PK_EventActivityParticipant] ASC),
    CONSTRAINT [FK_EventActivityParticipant_EventActivityPaymentLog] FOREIGN KEY ([PK_EventActivityTransaction]) REFERENCES [dbo].[EventActivityTransaction] ([PK_EventActivityTransaction]),
    CONSTRAINT [FK_EventActivityParticipant_MealType] FOREIGN KEY ([PK_MealType]) REFERENCES [dbo].[MealType] ([PK_MealType])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityParticipant_Email]
    ON [dbo].[EventActivityParticipant]([Email] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityParticipant_FirstName]
    ON [dbo].[EventActivityParticipant]([Name] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityParticipant_IdentificationNumber]
    ON [dbo].[EventActivityParticipant]([IdentificationNumber] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityParticipant_PhoneNumber]
    ON [dbo].[EventActivityParticipant]([PhoneNumber] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityParticipant_PK_EventActivityTransaction]
    ON [dbo].[EventActivityParticipant]([PK_EventActivityTransaction] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityParticipant_PK_MealType]
    ON [dbo].[EventActivityParticipant]([PK_MealType] ASC) WITH (FILLFACTOR = 80);

