CREATE TABLE dbo.InvalidCharForXML (
		PK_InvalidCharForXML INT IDENTITY (1,1)
		,InvalidChar		  NVARCHAR(20)
		CONSTRAINT [IX_InvalidCharForXML_PK_InvalidCharForXML] PRIMARY KEY CLUSTERED ([PK_InvalidCharForXML] ASC)
)								
