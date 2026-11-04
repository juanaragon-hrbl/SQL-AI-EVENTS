CREATE VIEW [dbo].[v_CEA_EventAttendees]
AS 
SELECT
	D.OriginalId as PK_Distributor, 
	D.DsId as DistributorID, 
	A.FirstName, 
	A.LastName, 
	D.Address, 
	D.CountryOfProcessingId as COP,
	A.Email,
	IIF(A.AttendeeTypeId='DS', 1,0) as IsDistributor,
	T.CheckInStatus as HasCheckedIn,
	T.CheckInDate,
	T.IsManual,
	T.LastUpdateBy,
	D.TeamLevelId as DistributorTeam,
	T.Id as PK_EventTicket,
	T.EventId as PK_Event,
	D.Language
FROM 
	[z_evp_cea_attendees].[Distributors] D (NOLOCK)
INNER JOIN  [z_evp_cea_attendees].[Attendees] A (NOLOCK)
ON
   D.Id = A.DistributorId
INNER JOIN  [z_evp_cea_attendees].[TicketAssignments] TA (NOLOCK) 
ON 
   A.Id = ISNULL(TA.AssigneeID,TA.AssignerId) AND TA.Active = 1
INNER JOIN [z_evp_cea_attendees].[Tickets] T (NOLOCK) 
ON 
	 T.Id = TA.TicketId
UNION
SELECT
	D.OriginalId as PK_Distributor, 
	D.DsId as DistributorID, 
	A.FirstName, 
	A.LastName, 
	D.Address, 
	D.CountryOfProcessingId as COP,
	A.Email,
	1 as IsDistributor,
	T.CheckInStatus as HasCheckedIn,
	T.CheckInDate,
	T.IsManual,
	T.LastUpdateBy,
	D.TeamLevelId as DistributorTeam,
	T.Id as PK_EventTicket,
	T.EventId as PK_Event,
	D.Language
FROM 
	[z_evp_cea_attendees].[Distributors] D (NOLOCK)
INNER JOIN  [z_evp_cea_attendees].[Attendees] A (NOLOCK)
ON
   D.Id = A.DistributorId
   AND A.AttendeeTypeId='DS'
INNER JOIN [z_evp_cea_attendees].[Tickets] T (NOLOCK) 
ON 
   T.OriginalDistributorId = D.OriginalId
WHERE NOT EXISTS(SELECT 1 FROM [z_evp_cea_attendees].[TicketAssignments] TA (NOLOCK) WHERE TA.TicketId = T.Id)