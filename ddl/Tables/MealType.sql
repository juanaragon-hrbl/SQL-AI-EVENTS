CREATE TABLE [dbo].[MealType] (
    [PK_MealType] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [MealType]    VARCHAR (128) NOT NULL,
    [CreatedUTC]  DATETIME      CONSTRAINT [DF_MealType_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]   NVARCHAR (50) CONSTRAINT [DF_MealType_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC] DATETIME      CONSTRAINT [DF_MealType_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]  NVARCHAR (50) CONSTRAINT [DF_MealType_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_MealType] PRIMARY KEY CLUSTERED ([PK_MealType] ASC)
);

