CREATE VIEW [dbo].[Events_Promotions_DRS_070_05_EMEA]
	AS 
SELECT distinct         E.[PK_Event] ,
                        E.[EventName],
                        E.[dStartUTC],
				        E.[dEndUTC],
				        E.[Location],
						VD.[sDistributorId],
                        VD.[sFirstName],
                        VD.[sLastName],
						VD.[sDistributorCountryProcessingCode],
				        VD.[sStreet],
				        VD.[sEmail]
FROM v_distributor VD 
INNER JOIN v_Countries VC ON VD.sDistributorCountryProcessingCode = VC.sCountryCode
INNER JOIN z_evp_cea_attendees.Distributors D (NOLOCK) ON VD.sDistributorId = D.DsId
INNER JOIN z_evp_cea_attendees.TicketAssignments TA (NOLOCK) on D.Id = TA.DistributorId
INNER JOIN z_evp_cea_attendees.Tickets T (NOLOCK) on TA.TicketId = T.Id
INNER JOIN dbo.Event E (NOLOCK) ON T.EventId = E.Pk_Event
WHERE ((VD.[sDistributorCountryProcessingCode] in ('UA') 
      and E.[dEndUTC] < convert(char(8), DATEADD(year, -15, getUTCdate()), 112))
or (VD.[sDistributorCountryProcessingCode] in ('FR','SR') 
	   and	E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()))
or (VD.[sDistributorCountryProcessingCode] in ('PL') 
	   and	E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()))
or ((VC.[sRegionCode] = 'EU' and VD.[sDistributorCountryProcessingCode] not in('UA','FR','SR','PL')) and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE())) )
