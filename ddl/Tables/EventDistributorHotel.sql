CREATE TABLE [dbo].[EventDistributorHotel] (
    [PK_EventDistributorHotel] INT            IDENTITY (1, 1) NOT NULL,
    [CreatedDate]              DATETIME       DEFAULT (getdate()) NULL,
    [CreatedBy]                VARCHAR (30)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDate]             DATETIME       DEFAULT (getdate()) NULL,
    [ModifiedBy]               VARCHAR (30)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Distributor]           INT            NULL,
    [PK_EventHotel]            INT            NULL,
    [DistributorID]            VARCHAR (10)   NULL,
    [Nights]                   INT            NULL,
    [Rooms]                    INT            NULL,
    [GuestPerRoom]             INT            NULL,
    [RoomType]                 VARCHAR (200)  NULL,
    [CheckedIn]                BIT            DEFAULT ((1)) NULL,
    [CheckInDate]              DATETIME       NULL,
    [CheckOutDate]             DATETIME       NULL,
    [Comments]                 VARCHAR (1000) NULL,
    CONSTRAINT [CS_EventDistributorHotel_PK_EventDistributorHotel] PRIMARY KEY CLUSTERED ([PK_EventDistributorHotel] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventDistributorHotel_PK_Distributor]
    ON [dbo].[EventDistributorHotel]([PK_Distributor] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventDistributorHotel_DistributorID]
    ON [dbo].[EventDistributorHotel]([DistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventDistributorHotel_PK_EventHotel]
    ON [dbo].[EventDistributorHotel]([PK_EventHotel] ASC);

