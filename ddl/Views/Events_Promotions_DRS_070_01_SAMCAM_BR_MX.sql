CREATE VIEW [dbo].[Events_Promotions_DRS_070_01_SAMCAM_BR_MX]
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
WHERE ((VD.[sDistributorCountryProcessingCode] in ('AR','EC','GT','HN') and E.[dEndUTC] < dateadd(yyyy,-5,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('PM') and E.[dEndUTC] < dateadd(yyyy,-7,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('BR','CO','CR','MX','PY','PE') and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('DR','SV') and E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('UY') and E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('AA','BL','CI','FG','GY','NI','VE') and E.[dEndUTC] < dateadd(yyyy,-3,GETUTCDATE()) ))
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
WHERE ((VD.sDistributorCountryProcessingCode in ('AR','EC','GT','HN') and E.[dEndUTC] < dateadd(yyyy,-5,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('PM') and E.[dEndUTC] < dateadd(yyyy,-7,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('BR','CO','CR','MX','PY','PE') and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('DR','SV') and E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('UY') and E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('AA','BL','CI','FG','GY','NI','VE') and E.[dEndUTC] < dateadd(yyyy,-3,GETUTCDATE()) ))
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
WHERE  ((VD.sDistributorCountryProcessingCode in ('AR','EC','GT','HN') and E.[dEndUTC] < dateadd(yyyy,-5,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('PM') and E.[dEndUTC] < dateadd(yyyy,-7,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('BR','CO','CR','MX','PY','PE') and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('DR','SV') and E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('UY') and E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('AA','BL','CI','FG','GY','NI','VE') and E.[dEndUTC] < dateadd(yyyy,-3,GETUTCDATE()) ))
