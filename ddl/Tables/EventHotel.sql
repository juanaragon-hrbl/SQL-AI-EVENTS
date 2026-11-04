CREATE TABLE [dbo].[EventHotel] (
    [PK_EventHotel]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [PK_HotelInfo]    INT           NOT NULL,
    [PK_Event]        INT           NOT NULL,
    CONSTRAINT [EventHotel_PK] PRIMARY KEY CLUSTERED ([PK_EventHotel] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventHotel_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [HotelInfoEventHotel_FK] FOREIGN KEY ([PK_HotelInfo]) REFERENCES [dbo].[HotelInfo] ([PK_HotelInfo])
);

