CREATE TABLE dbo.WRK_PhilippinesStarPerformerPromo_ConsecutiveMonths      
  (      
    PK INT IDENTITY(1,1)      
   ,PK_Distributor INT      
   ,ConsecutiveMonths INT                 
   ,StartDate	DATETIME
   ,VolumePoints MONEY DEFAULT 0.00
  )  

  