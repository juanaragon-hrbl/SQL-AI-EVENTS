CREATE VIEW [dbo].[Events_Promotions_DRS_070_05_APAC_CHINA]
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
WHERE VC.[sRegionCode] = 'AP' and VD.[sDistributorCountryProcessingCode] not in('VN') and E.[dEndUTC] < dateadd(yyyy,-30,GETUTCDATE())

