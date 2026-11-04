CREATE VIEW [dbo].[v_CEA_SubEventAttendees]
AS 
SELECT D.OriginalId as Pk_Distributor,
       D.DsId as DistributorId,       
	   A.Id as AttendeeId,
	   A.AttendeeTypeId,
	   TLS.TicketId as Pk_EventTicket,
	   SA.EventId as Pk_Event,
	   SA.SubEventId 
FROM  [z_evp_cea_attendees].Distributors D WITH (NOLOCK)
INNER JOIN [z_evp_cea_attendees].Attendees A WITH (NOLOCK) ON D.Id = A.DistributorId
INNER JOIN [z_evp_cea_attendees].SubEventsAccess SA WITH (NOLOCK) ON SA.AttendeeId = A.Id
INNER JOIN (SELECT (SELECT OriginalId FROM [z_evp_cea_attendees].Tickets T WHERE T.Id = SS.TicketId) TicketId,  
                   S.SubEventId,
				   (SELECT TOP 1 TA.AssigneeId FROM [z_evp_cea_attendees].TicketAssignments TA WHERE TA.TicketId = SS.TicketId and Active = 1) AssigneeId
      FROM  [z_evp_cea_attendees].SessionsStatus SS WITH (NOLOCK)
	  INNER JOIN [z_evp_cea_events].Sessions S WITH (NOLOCK) ON S.Id = SS.SessionId
	  WHERE SS.Status = 1
		     AND EXISTS(SELECT 1 from [z_evp_cea_attendees].Tickets T WITH (NOLOCK) WHERE T.Id = SS.TicketId 
			 AND T.CheckInStatus = 1)
	  GROUP BY SS.TicketId,  S.SubEventId) TLS ON TLS.SubEventId = SA.SubEventId 
	  AND TLS.AssigneeId = SA.AttendeeId