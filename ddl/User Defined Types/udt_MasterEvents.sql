CREATE TYPE [dbo].[udt_MasterEvents] AS TABLE (
    [PK_MasterEvent] INT           NULL,
    [MasterEvent]    NVARCHAR (50) NULL,
    [IsAtomic]       BIT           NULL,
    [IsActive]       BIT           NULL,
    [CodeType]       INT           NULL,
    [CheckYN]        BIT           NULL,
    [IsEnabled]      BIT           NULL,
	[IsMajor]		 BIT           NULL);

