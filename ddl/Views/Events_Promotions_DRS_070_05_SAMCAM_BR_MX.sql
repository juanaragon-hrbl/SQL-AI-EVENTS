CREATE VIEW [dbo].[Events_Promotions_DRS_070_05_SAMCAM_BR_MX]
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
INNER JOIN z_evp_cea_attendees.Distributors D (NOLOCK) ON VD.sDistributorId = D.DsId
INNER JOIN z_evp_cea_attendees.TicketAssignments TA (NOLOCK) on D.Id = TA.DistributorId
INNER JOIN z_evp_cea_attendees.Tickets T (NOLOCK) on TA.TicketId = T.Id
INNER JOIN dbo.Event E (NOLOCK) ON T.EventId = E.Pk_Event
WHERE ((VD.[sDistributorCountryProcessingCode] in ('AR','EC','GT','HN') and E.[dEndUTC] < dateadd(yyyy,-5,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('PM') and E.[dEndUTC] < dateadd(yyyy,-7,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('BR','CO','CR','MX','PY','PE') and E.[dEndUTC] < dateadd(yyyy,-10,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('DR','SV') and E.[dEndUTC] < dateadd(yyyy,-20,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('UY') and E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE()) )
		or (VD.[sDistributorCountryProcessingCode] in ('AA','BL','CI','FG','GY','NI','VE') and E.[dEndUTC] < dateadd(yyyy,-3,GETUTCDATE()) ))
