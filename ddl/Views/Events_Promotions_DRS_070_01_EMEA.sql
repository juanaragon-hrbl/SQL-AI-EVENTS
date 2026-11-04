CREATE VIEW [dbo].[Events_Promotions_DRS_070_01_EMEA]
	AS 
SELECT          E.[PK_Event],
                E.[EventName],
                E.[dStartUTC],
				E.[dEndUTC],
				E.[Location],
                ER.[DistributorID], 
				ER.[FirstName], 
				ER.[LastName], 
				VD.[sDistributorCountryProcessingCode],
				ER.[AddressLine1], 
				ER.[Apartment], 
				ER.[AddressLine2], 
				ER.[City], 
				ER.[Country], 
				ER.[ZipCode], 
				ER.[State], 
				ER.[Phones], 
				ER.[EmailAddress], 
				ER.[FaxNo]
FROM dbo.EventsRegistration ER (NOLOCK)
INNER JOIN dbo.Event E (NOLOCK) ON ER.Pk_Event = E.Pk_Event
INNER JOIN v_distributor VD ON ER.Pk_Distributor = VD.nDistributorID
INNER JOIN v_Countries VC ON VD.sDistributorCountryProcessingCode = VC.sCountryCode
WHERE ((VD.[sDistributorCountryProcessingCode] in ('UA') 
      and E.[dEndUTC] < convert(char(8), DATEADD(year, -15, getUTCdate()), 112))
or (VD.[sDistributorCountryProcessingCode] in ('FR','SR') 
	   and	E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()))
or (VD.sDistributorCountryProcessingCode in ('PL') 
	   and	E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()))
or ((VC.[sRegionCode] = 'EU' and VD.[sDistributorCountryProcessingCode] not in('UA','FR','SR','PL')) and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE())) )	   
UNION 
SELECT           E.[PK_Event] ,
                 E.[EventName],
                 E.[dStartUTC],
				 E.[dEndUTC],
				 E.[Location],
                 SEQ.[DistributorID], 
                 VD.[sFirstName], 
				 VD.[sLastName],
				 VD.[sDistributorCountryProcessingCode],
				 VD.[sStreet],
				 '', 
				 '', 
				 '', 
				 '', 
				 '', 
				 '', 
				 '', 
				 VD.[sEmail],
				 ''
FROM dbo.SubEventQualifier SEQ (NOLOCK)
INNER JOIN dbo.Event E (NOLOCK) ON SEQ.Pk_Event = E.Pk_Event
INNER JOIN v_distributor VD ON SEQ.Pk_Distributor = VD.nDistributorID
INNER JOIN v_Countries VC ON VD.sDistributorCountryProcessingCode = VC.sCountryCode
WHERE ((VD.[sDistributorCountryProcessingCode] in ('UA') 
      and E.[dEndUTC] < convert(char(8), DATEADD(year, -15, getUTCdate()), 112))
or (VD.[sDistributorCountryProcessingCode] in ('FR','SR') 
	   and	E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()))
or (VD.[sDistributorCountryProcessingCode] in ('PL') 
	   and	E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()))
or ((VC.[sRegionCode] = 'EU' and VD.[sDistributorCountryProcessingCode] not in('UA','FR','SR','PL')) and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE())) )	
UNION 
SELECT          E.[PK_Event],
                E.[EventName],
                E.[dStartUTC],
				E.[dEndUTC],
				E.[Location],  
                ERA.[DistributorID], 
                ERA.[FirstName], 
				ERA.[LastName], 
				VD.[sDistributorCountryProcessingCode],
				ERA.[AddressLine1], 
				ERA.[Apartment], 
				ERA.[AddressLine2], 
				ERA.[City], 
				ERA.[Country], 
				ERA.[ZipCode], 
				ERA.[State], 
				ERA.[Phones], 
				ERA.[EmailAddress], 
				ERA.[FaxNo]
FROM dbo.EventsRegistration_Archive ERA (NOLOCK)
INNER JOIN dbo.Event E (NOLOCK) ON ERA.Pk_Event = E.Pk_Event
INNER JOIN v_distributor VD ON ERA.Pk_Distributor = VD.nDistributorID
INNER JOIN v_Countries VC ON VD.sDistributorCountryProcessingCode = VC.sCountryCode
WHERE ((VD.[sDistributorCountryProcessingCode] in ('UA') 
      and E.[dEndUTC] < convert(char(8), DATEADD(year, -15, getUTCdate()), 112))
or (VD.[sDistributorCountryProcessingCode] in ('FR','SR') 
	   and	E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()))
or (VD.[sDistributorCountryProcessingCode] in ('PL') 
	   and	E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()))
or ((VC.[sRegionCode] = 'EU' and VD.[sDistributorCountryProcessingCode] not in('UA','FR','SR','PL')) and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE())) )
