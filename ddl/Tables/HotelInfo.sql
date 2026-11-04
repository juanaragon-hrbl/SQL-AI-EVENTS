CREATE TABLE [dbo].[HotelInfo] (
    [PK_HotelInfo]    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [HotelName]       VARCHAR (200) NOT NULL,
    [AddressLine1]    VARCHAR (200) NOT NULL,
    [AddressLine2]    VARCHAR (200) NULL,
    [City]            VARCHAR (100) NOT NULL,
    [State]           VARCHAR (100) NULL,
    [PK_Country]      INT           NOT NULL,
    [Phones]          VARCHAR (100) NULL,
    [Fax]             VARCHAR (100) NULL,
    [EmailAddress]    VARCHAR (100) NULL,
    [ContactPerson]   VARCHAR (100) NULL,
    [CreatedDateUTC]  DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Locale]       INT           NULL,
    CONSTRAINT [HotelInfo_PK] PRIMARY KEY CLUSTERED ([PK_HotelInfo] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_HotelInfo_PK_Locale]
    ON [dbo].[HotelInfo]([PK_Locale] ASC);

