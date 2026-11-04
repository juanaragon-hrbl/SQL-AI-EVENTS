CREATE TABLE [dbo].[VacationRegistration] (
    [PK_VacationRegistration] INT             IDENTITY (1, 1) NOT NULL,
    [CreatedDate]             DATETIME        DEFAULT (getdate()) NULL,
    [CreatedBy]               VARCHAR (30)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDate]            DATETIME        DEFAULT (getdate()) NULL,
    [ModifiedBy]              VARCHAR (30)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                INT             NULL,
    [PK_Distributor]          INT             NULL,
    [DistributorID]           VARCHAR (10)    NULL,
    [FirstName]               VARCHAR (40)    NULL,
    [MiddleName]              VARCHAR (40)    NULL,
    [LastName]                VARCHAR (40)    NULL,
    [DistributorType]         CHAR (1)        NULL,
    [PK_Nationality]          INT             NULL,
    [PK_TravelDocumentType]   INT             NULL,
    [DocumentType]            VARCHAR (100)   NULL,
    [DocumentNumber]          VARCHAR (100)   NULL,
    [DocumentExpiryDate]      DATETIME        NULL,
    [RecordStatus]            CHAR (1)        NULL,
    [ApprovalDate]            DATETIME        NULL,
    [ApprovedBy]              VARCHAR (30)    NULL,
    [TeamStatus]              VARCHAR (50)    NULL,
    [Email]                   VARCHAR (250)   NULL,
    [Phone]                   VARCHAR (50)    NULL,
    [Mobile]                  VARCHAR (50)    NULL,
    [ConfirmationNO]          INT             NULL,
    [CountryName]             VARCHAR (50)    NULL,
    [DateOfBirth]             SMALLDATETIME   NULL,
    [DocumentIssueDate]       SMALLDATETIME   NULL,
    [PreMedicalConditions]    NVARCHAR (4000) NULL,
    [CountryOfResidence]      NVARCHAR (30)   NULL,
    [FileType]                NVARCHAR (40)   NULL,
    [FilePath]                NVARCHAR (1000) NULL,
    [FileName]                NVARCHAR (100)  NULL,
    CONSTRAINT [CS_VacationRegistration_PK_VacationRegistration] PRIMARY KEY CLUSTERED ([PK_VacationRegistration] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_VacationRegistration_PK_Distributor]
    ON [dbo].[VacationRegistration]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_VacationRegistration_DistributorID]
    ON [dbo].[VacationRegistration]([DistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_VacationRegistration_DocumentNumber]
    ON [dbo].[VacationRegistration]([DocumentNumber] ASC);


GO
CREATE TRIGGER tgrEvent_VacationRegistration
ON dbo.VacationRegistration
AFTER INSERT
AS

DECLARE @TableName nVARCHAR(500)
SET @TableName = 'dbo.VacationRegistration'


INSERT INTO [dbo].[VacationRegistration_TrackChanges]
           (PK_VacationRegistration_TrackChanges
           ,[CreatedDate]
           ,[CreatedBy]
           ,[ModifiedDate]
           ,[ModifiedBy]
           ,[PK_Event]
           ,[PK_Distributor]
           ,[DistributorID]
           ,[FirstName]
           ,[MiddleName]
           ,[LastName]
           ,[DistributorType]
           ,[PK_Nationality]
           ,[PK_TravelDocumentType]
           ,[DocumentType]
           ,[DocumentNumber]
           ,[DocumentExpiryDate]
           ,[RecordStatus]
           ,[ApprovalDate]
           ,[ApprovedBy]
           ,[TeamStatus]
           ,[Email]
           ,[Phone]
           ,[Mobile]
           ,[ConfirmationNO]
           ,[CountryName]
           ,[DateOfBirth]
		   ,[DocumentIssueDate]
		   ,[PreMedicalConditions]
		   ,[CountryOfResidence]
		   ,[FileType]
		   ,[FilePath]
		   ,[FileName]	)
	SELECT [PK_VacationRegistration]
		  ,[CreatedDate]
		  ,[CreatedBy]
		  ,[ModifiedDate]
		  ,[ModifiedBy]
		  ,[PK_Event]
		  ,[PK_Distributor]
		  ,[DistributorID]
		  ,[FirstName]
		  ,[MiddleName]
		  ,[LastName]
		  ,[DistributorType]
		  ,[PK_Nationality]
		  ,[PK_TravelDocumentType]
		  ,[DocumentType]
		  ,[DocumentNumber]
		  ,[DocumentExpiryDate]
		  ,[RecordStatus]
		  ,[ApprovalDate]
		  ,[ApprovedBy]
		  ,[TeamStatus]
		  ,[Email]
		  ,[Phone]
		  ,[Mobile]
		  ,[ConfirmationNO]
		  ,[CountryName]
		  ,[DateOfBirth]
		  ,[DocumentIssueDate]
		  ,[PreMedicalConditions]
		  ,[CountryOfResidence]
		  ,[FileType]
		  ,[FilePath]
		  ,[FileName]	  	      
	  FROM Inserted