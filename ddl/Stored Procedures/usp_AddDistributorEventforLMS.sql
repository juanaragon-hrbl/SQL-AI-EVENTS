CREATE PROCEDURE [dbo].[usp_AddDistributorEventforLMS]
-- ================================================
/*
	OBJECT:		dbo.usp_AddDistributorEventforLMS
	USE:
	            EXEC dbo.usp_AddDistributorEventforLMS
			

	DESCRIPTION:	add event record for distributor
	NOTES:			
					
	DEPENDENCIES:

	---------------------------------------------------------------------------------------------
	SQL SERVER 2017	
	VERSIONS
	---------------------------------------------------------------------------------------------
	1	2018-11-29			Long Sheng   	  	Initial
	2	2020-05-20			Carlos Perez   	  	Validation and error message added
*/
-- ================================================
		@DistributorID VARCHAR(10),
		@PK_EVENT INT,
		@PK_EventTicket INT = NULL,
		@AddSpouse BIT = 0,
		@ErrorMessage VARCHAR(512) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @PK_Distributor INT
	DECLARE @FirstName nvarchar(150),
	        @LastName nvarchar(150),
			@SpouseFirstName nvarchar(150),
			@SpouseLastName nvarchar(150),
			@Team varchar(5),
			@User varchar(256)

	SELECT @PK_Distributor = nDistributorID, @FirstName = sFirstName, @LastName = sLastName, @Team = sTeam
	      , @SpouseFirstName = SpouseFirstName, @SpouseLastName = SpouseLastName, @User = replace(suser_sname(),'HERBALIFECORP\','')
	FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID

	IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.Event WITH(NOLOCK) WHERE PK_Event=@PK_EVENT)
	BEGIN
		SET @ErrorMessage = 'pk_event does not exist'
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.EventsRegistration WITH(NOLOCK) WHERE PK_Event=@PK_EVENT and DistributorID=@DistributorID)
		BEGIN
			SET @ErrorMessage = 'inserting duplicate event'
		END
		ELSE
		BEGIN
			IF @PK_Distributor IS NOT NULL
			BEGIN
				INSERT dbo.EventsRegistration(
												PK_Distributor
												,DistributorID
												,FirstName
												,LastName
												,AddressLine1
												,AddressLine2
												,City
												,State
												,ZipCode
												,Country
												,Phones
												,IsPrimaryGuest
												,HasCheckedIn
												,CreatedDateUTC
												,IsDistributor
												,CreatedBy
												,UnRegister
												,ModifiedDateUTC
												,IsPreRegistered
												,ModifiedBy
												,DistributorTeam
												,PK_EventTicket
												,PK_Event
												,PK_PrimaryLanguage,
												Registered)
				VALUES(@PK_Distributor,@DistributorID,@FirstName,@LastName,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,1,GETUTCDATE(),0,@User,0,GETUTCDATE(),0,@User,@Team,@PK_EventTicket,@PK_EVENT,NULL,1)
				IF @AddSpouse = 1
				BEGIN
					INSERT dbo.EventsRegistration(
												PK_Distributor
												,DistributorID
												,FirstName
												,LastName
												,AddressLine1
												,AddressLine2
												,City
												,State
												,ZipCode
												,Country
												,Phones
												,IsPrimaryGuest
												,HasCheckedIn
												,CreatedDateUTC
												,IsDistributor
												,CreatedBy
												,UnRegister
												,ModifiedDateUTC
												,IsPreRegistered
												,ModifiedBy
												,DistributorTeam
												,PK_EventTicket
												,PK_Event
												,PK_PrimaryLanguage,
												Registered)
					VALUES(@PK_Distributor,@DistributorID,@SpouseFirstName,@SpouseLastName,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,1,GETUTCDATE(),0,@User,0,GETUTCDATE(),0,@User,@Team,@PK_EventTicket,@PK_EVENT,NULL,1)

				END

			END

		END

	END

END