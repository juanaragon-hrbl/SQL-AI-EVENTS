CREATE TABLE [dbo].[WRK_CustomRegistration]
(
	PK_Event					INT,
	ListID						INT,
	LastExecutionUTCDate		DATETIME,
	SecondaryListID				INT NULL, 
    [ResetAttendees] BIT NULL DEFAULT 0
);
GO

CREATE CLUSTERED INDEX IX_WRK_CustomRegistration_PK_Event ON [dbo].[WRK_CustomRegistration](PK_Event);
