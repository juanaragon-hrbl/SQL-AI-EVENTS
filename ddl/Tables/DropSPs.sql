CREATE TABLE [dbo].[DropSPs] (
    [ID]       INT           IDENTITY (1, 1) NOT NULL,
    [SPName]   VARCHAR (200) NULL,
    [NewName]  AS            ('z_'+[SPName]),
    [RenameYN] BIT           DEFAULT ((0)) NULL
);

