CREATE TABLE [dbo].[EventSubTypeGroupMaster] (
    [PK_EventSubTypeGroupMaster]  INT            IDENTITY (1, 1) NOT NULL,
    [EventSubTypeGroupMasterName] NVARCHAR (200) NOT NULL,
    [IsActive]                    BIT            DEFAULT ((1)) NULL,
    [IsAtomic]                    BIT            DEFAULT ((0)) NULL,
	[IsMajor] 					  BIT			 DEFAULT ((0)) NULL, 
    [CreatedDateUTC]              SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                   NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]             SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                  NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventSubTypeGroupMaster] PRIMARY KEY CLUSTERED ([PK_EventSubTypeGroupMaster] ASC),
    CONSTRAINT [IX_EventSubTypeGroupMaster_EventSubTypeGroupMasterName] UNIQUE NONCLUSTERED ([EventSubTypeGroupMasterName] ASC)
);


GO
-- =============================================
-- Author:		JuanH
-- Create date: 20-Nov-2012
-- Description:	Activate/Deactivate EventSubTypes
-- =============================================
CREATE TRIGGER dbo.trigg_Activate_EventSubTypes 
   ON  dbo.EventSubTypeGroupMaster 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF UPDATE(IsActive)
	BEGIN
		UPDATE 
			EVST
		SET 
			EVST.IsActive = GM.IsActive
			--,EVST.ModifiedBy = 'TRIGGER'
			,EVST.ModifiedDateUTC = GETUTCDATE()
		FROM
			dbo.EventSubTypes EVST
		INNER JOIN
			dbo.EventSubTypeGroup TG
		ON
			TG.PK_EventSubTypeGroup = EVST.PK_EventSubTypeGroup
		INNER JOIN
			inserted GM
		ON
			GM.PK_EventSubTypeGroupMaster = TG.PK_EventSubTypeGroupMaster
		AND 
			TG.PK_EventType = EVST.PK_EventType 
			 
	END
END
