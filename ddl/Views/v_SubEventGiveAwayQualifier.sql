CREATE VIEW dbo.v_SubEventGiveAwayQualifier
AS
SELECT [PK_SubEventGiveAwayQualifier]
      ,[PK_Distributor]
      ,[PK_Event]
      ,[Pk_SubEvent]
      ,[CreatedDateUTC]
      ,[CreatedBy]
      ,[ModifiedDateUTC]
      ,[ModifiedBy]
      ,[Quantity]
      ,[RemovedUTC]
  FROM [dbo].[SubEventGiveAwayQualifier]