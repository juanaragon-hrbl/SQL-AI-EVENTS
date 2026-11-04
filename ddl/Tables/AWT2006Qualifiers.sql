CREATE TABLE [dbo].[AWT2006Qualifiers] (
    [PK_AWT2006Qualifiers] INT             IDENTITY (1, 1) NOT NULL,
    [CreatedDateUTC]       DATETIME        DEFAULT (getutcdate()) NULL,
    [CreatedBy]            VARCHAR (20)    DEFAULT ('PrabhuS') NULL,
    [ModifiedDateUTC]      DATETIME        DEFAULT (getutcdate()) NULL,
    [ModifiedBy]           VARCHAR (20)    DEFAULT ('PrabhuS') NULL,
    [PK_Distributor]       INT             NULL,
    [DistributorID]        VARCHAR (10)    DEFAULT ('') NULL,
    [sFirstName]           NVARCHAR (500)  DEFAULT ('') NULL,
    [sLastName]            NVARCHAR (500)  DEFAULT ('') NULL,
    [sCOP]                 CHAR (2)        NULL,
    [sTeam]                CHAR (1)        NULL,
    [Qual_SP]              DATETIME        NULL,
    [sAddress]             NVARCHAR (1000) DEFAULT ('') NULL,
    [sCity]                NVARCHAR (250)  DEFAULT ('') NULL,
    [sState]               NVARCHAR (150)  DEFAULT ('') NULL,
    [sCountry]             NVARCHAR (250)  DEFAULT ('') NULL,
    [sPhone]               NVARCHAR (250)  DEFAULT ('') NULL,
    [sEmail]               NVARCHAR (500)  DEFAULT ('') NULL
);

