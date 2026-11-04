CREATE TABLE [dbo].[CountryPM] (
    [PK_CountryPM] INT IDENTITY (1, 1) NOT NULL,
    [PK_Country]   INT NULL,
    [HasDSAccess]  BIT NULL,
	[AllowCorporateEvent]    BIT DEFAULT ((0)) NULL,
    [AllowDistributorEvents] BIT DEFAULT ((0)) NULL,
    [AllowDistributorPromos] BIT DEFAULT ((0)) NULL,
    [AllowGTA]               BIT DEFAULT ((0)) NULL,
    [AllowPmPromos]          BIT DEFAULT ((0)) NULL,
    [AllowTrackProgress]     BIT DEFAULT ((0)) NULL,
    [AllowRegistration]      BIT DEFAULT ((0)) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_ContryPM_PK_Country]
    ON [dbo].[CountryPM]([PK_Country] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ContryPM_PK_CountryPM]
    ON [dbo].[CountryPM]([PK_CountryPM] ASC);