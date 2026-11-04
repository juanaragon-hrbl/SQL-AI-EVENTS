CREATE TYPE [dbo].[udt_Participant] AS TABLE (
    [PK_Participant]        INT            NULL,
    [Name]                  NVARCHAR (200) NULL,
    [Email]                 NVARCHAR (100) NULL,
    [PhoneNumber]           VARCHAR (50)   NULL,
    [DOB]                   SMALLDATETIME  NULL,
    [TourLanguage]          INT            NULL,
    [IdentificationNumber]  VARCHAR (50)   NULL,
    [IdentificationExpDate] SMALLDATETIME  NULL,
    [IsDistributor]         BIT            NULL,
    [PK_MealType]           SMALLINT       NULL,
    [MealNote]              NVARCHAR (256) NULL,
    [FlightOption]          NVARCHAR (50)  NULL);

