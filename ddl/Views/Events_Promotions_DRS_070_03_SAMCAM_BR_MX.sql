CREATE VIEW [dbo].[Events_Promotions_DRS_070_03_SAMCAM_BR_MX]
	AS 
SELECT          E.[PK_Event],
                E.[EventName],
                E.[dStartUTC],
				E.[dEndUTC],
				E.[Location],
                VD.[sDistributorId], 
                VD.[sFirstName],
				VD.[sLastName],
				VD.[sDistributorCountryProcessingCode],
				VD.[sStreet],
				'' [Address2],
				VD.[sCity],
				'' Country,
				VD.[sDistributorPostalCode],
				'' State,
				VD.[Phone],
				VD.[sEmail],
				VD.[SpouseFirstName],
				VD.[SpouseLastName]
FROM Promo.EventDistributor ED (NOLOCK)
INNER JOIN dbo.Event E (NOLOCK) ON ED.Pk_Event = E.Pk_Event
INNER JOIN v_distributor VD ON ED.Pk_Distributor = VD.nDistributorID
WHERE ((VD.[sDistributorCountryProcessingCode] in ('AR','EC','GT','HN') and E.[dEndUTC] < dateadd(yyyy,-5,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('PM') and E.[dEndUTC] < dateadd(yyyy,-7,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('BR','CO','CR','MX','PY','PE') and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('DR','SV') and E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('UY') and E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('AA','BL','CI','FG','GY','NI','VE') and E.[dEndUTC] < dateadd(yyyy,-3,GETUTCDATE()) ))
UNION 
SELECT          E.[PK_Event] ,
                E.[EventName],
                E.[dStartUTC],
				E.[dEndUTC],
				E.[Location],
				TB.[DistributorId], 
                TD.[FirstName],
				TD.[LastName],
				VD.[sDistributorCountryProcessingCode],
				TB.[Address1],
				TB.[Address2],
				TB.[City],
				TB.[Country],
				TB.[PostalCode],
				TB.[State],
				TB.[Phone],
				TB.[Email],
				'',
				''
FROM dbo.TravelBilling TB (NOLOCK)
INNER JOIN dbo.Event E (NOLOCK) ON TB.Pk_Event = E.Pk_Event
INNER JOIN dbo.TravelDetails TD (NOLOCK) on TB.DistributorId = TD.DistributorId
INNER JOIN v_distributor VD ON TB.DistributorId = VD.sDistributorID
WHERE ((VD.[sDistributorCountryProcessingCode] in ('AR','EC','GT','HN') and E.[dEndUTC] < dateadd(yyyy,-5,GETUTCDATE()) )
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
				ECD.[CoordinatorId], 
                ECD.[CoordinatorName], 
				'', 
				VD.[sDistributorCountryProcessingCode],
				'', 
				'', 
				'', 
				'',
				'',
				'', 
				ECD.[CoordinatorPhone], 
				ECD.[CoordinatorEmail],
				'',
				''
FROM dbo.EventCoordinatorDetail ECD (NOLOCK)
INNER JOIN dbo.Event E (NOLOCK) ON ECD.Pk_Event = E.Pk_Event
INNER JOIN v_distributor VD ON ECD.CoordinatorID = CONVERT(NVARCHAR(30),VD.nDistributorID)
INNER JOIN v_Countries VC ON VD.sDistributorCountryProcessingCode = VC.sCountryCode
WHERE ECD.Pk_Event IN(SELECT Pk_Event FROM dbo.Event WITH (NOLOCK) WHERE Version = 2)
 AND ((VD.[sDistributorCountryProcessingCode] in ('AR','EC','GT','HN') and E.[dEndUTC] < dateadd(yyyy,-5,GETUTCDATE()) )
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
				ECD.[CoordinatorId],
                ECD.[CoordinatorName], 			
				'', 
				VD.[sDistributorCountryProcessingCode],
				'', 
				'', 
				'', 
				'',
				'',
				'', 
				ECD.[CoordinatorPhone], 
				ECD.[CoordinatorEmail],
				'',
				''
FROM dbo.EventCoordinatorDetail ECD (NOLOCK)
INNER JOIN dbo.Event E (NOLOCK) ON ECD.Pk_Event = E.Pk_Event
INNER JOIN v_distributor VD ON ECD.CoordinatorID = VD.SDistributorID
INNER JOIN v_Countries VC ON VD.sDistributorCountryProcessingCode = VC.sCountryCode
WHERE ECD.Pk_Event IN(SELECT Pk_Event FROM dbo.Event WITH (NOLOCK) WHERE Version is null)
 AND ((VD.[sDistributorCountryProcessingCode] in ('AR','EC','GT','HN') and E.[dEndUTC] < dateadd(yyyy,-5,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('PM') and E.[dEndUTC] < dateadd(yyyy,-7,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('BR','CO','CR','MX','PY','PE') and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode]in ('DR','SV') and E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('UY') and E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('AA','BL','CI','FG','GY','NI','VE') and E.[dEndUTC] < dateadd(yyyy,-3,GETUTCDATE()) ))
