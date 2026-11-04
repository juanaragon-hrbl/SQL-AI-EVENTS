
/****** Object:  StoredProcedure [dbo].[usp_GetDistributorEvent]    Script Date: 9/14/2018 12:38 PM ******/

-- ================================================
/*
	OBJECT:		usp_getDistributorEvent
	USE:
	            EXEC usp_getDistributorEvent
			

	DESCRIPTION:	Monthly, (US and Canada only) Calculation Attendance
	NOTES:			Save distributor attandance number on LMS and PubEventManagement
					Will be save on 18, 19 and 20 for current month
					
	DEPENDENCIES:

	---------------------------------------------------------------------------------------------
	SQL SERVER 2017	
	VERSIONS
	---------------------------------------------------------------------------------------------
	1	2018-09-14		Carlos Perez	  	Initial
	2   2018-10-15      Long Sheng          remove some columns
	2	2019-08-14		NoeG				Refactor code (SRE)
	4   2019-11-01	    SushmaA			    Hard Coded Values - SRE
*/
-- ================================================

CREATE PROCEDURE [dbo].[usp_GetDistributorEvent]
	-- Parameters for the stored procedure
	--@DistributorID			varchar(14)
AS
BEGIN
	SET NOCOUNT ON;
	--*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+
	--			Loop
	--*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+
	DECLARE @CurrentMonth VARCHAR(2),
	@DistributorID varchar(14)



				DECLARE
				@CurrentDay				int = 0,
				@AddEvents				VARCHAR(20),    
				@CountryID				INT,    
				@PeriodInMonths			SMALLINT,    
				@MinEventCount			SMALLINT,   
				@EventsAttended			INT,    
				@FromDate				DATETIME,  
				@CorpEventsAttended		INT,                     
				@COP					VARCHAR(2),   
				@PK_Distributor			INT   
DECLARE @ThroughDate DATETIME = '2049-12-31'

SET @CurrentDay = (SELECT DATEPART(D, GETUTCDATE()));

IF(@CurrentDay in (18, 19, 20))
BEGIN
	BEGIN TRY

		BEGIN TRANSACTION
		SET @CurrentMonth = (SELECT DATEPART(M, GETUTCDATE()));
	
	/* ***************** SonarQube check 161 - "DELETE" and "UPDATE" statements should contain "WHERE" clauses */
		TRUNCATE TABLE dbo.DistributorEventAttendance 
	/* ***************** SonarQube check 161 */

		DECLARE DS_cursor CURSOR FOR
		SELECT DistributorID
		FROM dbo.EventQualifier q (NOLOCK) WHERE q.pk_event in (224,225,1001)
		ORDER BY DistributorID
	
		OPEN DS_cursor;
		FETCH DS_cursor INTO @DistributorID

		WHILE @@FETCH_STATUS = 0
		BEGIN
		
				-- Get the Distributor's CountryID, PK_Distributor, COP  
				SELECT @PK_Distributor  = nDistributorID  
				  ,@CountryID=nDistributorCOuntryProcessingID  
				  ,@COP=sDistributorCountryProcessingCode  
				FROM dbo.v_Distributor WITH (NOLOCK)  
				WHERE sDistributorID=@DistributorID   

				-- Get the PeriodInMonths (range) based on CountryID  
				SELECT @PeriodInMonths =  PeriodInMonths,  
					   @MinEventCount  =  MinEventCount      
				FROM dbo.LeadAssgnDSEventQual WITH (NOLOCK)  
				WHERE PK_Country = @CountryID  

				-- Calculate the date, back to 12 months from today  
				SET @FromDate = DATEADD(MM, -(@PeriodInMonths - 1), GETDATE())    
				SET @FromDate = CAST(CAST(YEAR(@FromDate) * 10000 + MONTH(@FromDate) * 100 + 01 AS VARCHAR(8)) AS DATETIME) 
				--******************************************************************
				-- Get the number of Corporate Events attended by the DistributorID'
				--******************************************************************  
				SELECT  @CorpEventsAttended = SUM(nCnt)   
				FROM   
					(SELECT COUNT(1) AS nCnt  
					FROM  
						(SELECT DISTINCT E.PK_Event   
						FROM dbo.EventType ET  WITH (NOLOCK)  

							INNER JOIN 

							dbo.Event E  WITH (NOLOCK)  
							ON ET.PK_EventType = E.PK_EventType  
							-- Transfers  

							INNER JOIN 

							--***************
								(SELECT DISTINCT PK_Event,PK_Distributor,HasCheckedIn,DA.nDistributorID,DA.nMainDistributorID 
								FROM dbo.EventsRegistration ER WITH (NOLOCK)  
									LEFT JOIN dbo.v_DistributorAssociate2 DA WITH (NOLOCK)  
									ON DA.Transfer = 1 AND DA.dThrough = @ThroughDate AND ER.PK_Distributor IN (DA.nDistributorID,DA.nMainDistributorID)  
				
								UNION
				  
								SELECT DISTINCT PK_Event,DA.nDistributorID AS PK_Distributor,HasCheckedIn,DA.nDistributorID,DA.nMainDistributorID 
								FROM dbo.EventsRegistration ER WITH (NOLOCK)  
									LEFT JOIN 
									dbo.v_DistributorAssociate2 DA WITH (NOLOCK)  
									ON DA.Transfer = 0 AND DA.dThrough = @ThroughDate AND ER.PK_Distributor = DA.nMainDistributorID ) ER  
							--***************

							ON E.PK_Event = ER.PK_Event  

						WHERE ET.EventTypeCode IN ('CE','CP','CR')  
							AND ER.PK_Distributor = ER.nDistributorID    
							AND @PK_Distributor IN (ER.nDistributorID,nMainDistributorID)  
							AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
							AND ER.HasCheckedIn = 1   

						UNION  

						SELECT DISTINCT E.PK_Event   
						FROM dbo.EventType ET WITH (NOLOCK)

							INNER JOIN 

							dbo.Event E  WITH (NOLOCK)  
							ON ET.PK_EventType = E.PK_EventType  
							-- Transfers  

							INNER JOIN 

							(SELECT DISTINCT PK_Event,PK_Distributor,HasCheckedIn,DA.nDistributorID,DA.nMainDistributorID 
							FROM dbo.EventsRegistration ER WITH (NOLOCK) 
				 
								LEFT JOIN 

								dbo.v_DistributorAssociate2 DA WITH (NOLOCK)  
								ON DA.Transfer = 1 AND DA.dThrough = @ThroughDate AND ER.PK_Distributor IN (DA.nDistributorID,DA.nMainDistributorID)   
				
							UNION  
				
							SELECT DISTINCT PK_Event,DA.nDistributorID AS PK_Distributor,HasCheckedIn,DA.nDistributorID,DA.nMainDistributorID 
							FROM dbo.EventsRegistration ER WITH (NOLOCK)  

								LEFT JOIN 
					
								dbo.v_DistributorAssociate2 DA WITH (NOLOCK)  
								ON DA.Transfer = 0 AND DA.dThrough = @ThroughDate AND ER.PK_Distributor = DA.nMainDistributorID) ER   
								ON E.PK_Event = ER.PK_Event  
							WHERE ET.EventTypeCode IN ('CE','CP','CR')  
								AND ER.PK_Distributor = ER.nMainDistributorID    
								AND @PK_Distributor IN (ER.nDistributorID,nMainDistributorID)  
								AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
								AND ER.HasCheckedIn = 1   
					
							UNION  
					
							SELECT DISTINCT E.PK_Event   
							FROM dbo.EventType ET WITH (NOLOCK)  
								INNER JOIN dbo.Event E  WITH (NOLOCK)  
								ON ET.PK_EventType = E.PK_EventType  
								INNER JOIN dbo.EventsRegistration ER WITH (NOLOCK)  
								ON E.PK_Event = ER.PK_Event  
							WHERE ET.EventTypeCode IN ('CE','CP','CR')  
								AND ER.PK_Distributor = @PK_Distributor   
								AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
								AND ER.HasCheckedIn = 1) TOT 
							
							UNION ALL  
  
							SELECT COUNT(1) AS nCnt  
							FROM 
								dbo.Event E WITH (NOLOCK)  

								INNER JOIN  

								dbo.EventType ET WITH (NOLOCK)  
								ON E.PK_EventType = ET.PK_EventType AND ET.EventTypeCode IN ('CE','CP','CR')  

								INNER JOIN  

								--*****************************
								--*****************************
								dbo.EventQualifier EQ WITH (NOLOCK)  
								ON E.PK_Event = EQ.PK_Event 

								INNER JOIN  

								(SELECT DISTINCT PK_Event, PK_ToDistributor, ValidToDateUTC   
								FROM dbo.EventTicketAssignment ETAA WITH (NOLOCK)  
									LEFT JOIN dbo.v_DistributorAssociate2 DA  
									ON ETAA.PK_ToDistributor IN (DA.nMainDistributorID,DA.nDistributorID)   
									AND DA.Transfer = 1   
									AND DA.dThrough = @ThroughDate  
								WHERE ETAA.ValidToDateUTC = @ThroughDate  
						   
								UNION  
						
								SELECT DISTINCT PK_Event, DA.nDistributorID AS PK_ToDistributor, ValidToDateUTC   
								FROM dbo.EventTicketAssignment ETAA WITH (NOLOCK)  
									LEFT JOIN dbo.v_DistributorAssociate2 DA  
									ON ETAA.PK_ToDistributor = DA.nMainDistributorID  
									AND DA.Transfer = 0   
									AND DA.dThrough = @ThroughDate  
								WHERE ETAA.ValidToDateUTC = @ThroughDate) ETA 
					
						 
								ON ETA.PK_Event = E.PK_Event AND ETA.PK_ToDistributor = EQ.PK_Distributor AND ETA.ValidToDateUTC = @ThroughDate  
					
								LEFT JOIN  
					
								(SELECT PK_Event,COUNT(1) AS nCnt   
								FROM dbo.EventsRegistration WITH (NOLOCK)  
								GROUP BY PK_Event  
								HAVING COUNT(1) > 10) ER  
								ON ER.PK_Event = E.PK_Event  
							
								INNER JOIN  
								--**
								(SELECT DISTINCT LEE.PK_EventType, LEE.PK_Event, LEE.PK_Distributor, LEE.PK_LeadEvent  
								FROM dbo.LeadEventsRegistration LEE WITH (NOLOCK)  
									LEFT JOIN dbo.v_DistributorAssociate2 DA  
									ON LEE.PK_Distributor IN (DA.nMainDistributorID,DA.nDistributorID) AND DA.Transfer = 1 AND DA.dThrough = @ThroughDate  
							
								UNION  
							
								SELECT DISTINCT LEE.PK_EventType, LEE.PK_Event, DA.nDistributorID AS PK_Distributor, LEE.PK_LeadEvent  
								FROM dbo.LeadEventsRegistration LEE WITH (NOLOCK)  
									LEFT JOIN dbo.v_DistributorAssociate2 DA  
									ON LEE.PK_Distributor = DA.nMainDistributorID AND DA.Transfer = 0 AND DA.dThrough = @ThroughDate) LE  
								--**
								ON LE.PK_EventType = E.PK_EventType AND LE.PK_Event = EQ.PK_Event AND LE.PK_Distributor = @PK_Distributor  
								WHERE EQ.PK_Distributor = @PK_Distributor AND ER.PK_Event IS NULL AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()    
								GROUP BY  E.dStartUTC,  E.EventName,E.EventCity, E.Location,  
										CASE WHEN LE.PK_Distributor IS NOT NULL THEN 1 ELSE 0 END, ET.PK_EventType, E.PK_Event, LE.PK_LeadEvent) CORP  
				--******************************************************************
				--******************************************************************

				--******************************************************************
				-- Get the total number of Events attended by the DistributorID  
				--******************************************************************
				SELECT @EventsAttended = SUM(nCnt)    
				FROM (SELECT  COUNT(1) AS nCnt      
					FROM (SELECT DISTINCT E.PK_Event   
						FROM dbo.EventType ET  WITH (NOLOCK)
							INNER JOIN dbo.Event E  WITH (NOLOCK) ON ET.PK_EventType = E.PK_EventType 
							INNER JOIN (SELECT DISTINCT PK_Event,PK_Distributor,HasCheckedIn,DA.nDistributorID,DA.nMainDistributorID 
										FROM dbo.EventsRegistration ER WITH (NOLOCK)  
											LEFT JOIN dbo.v_DistributorAssociate2 DA  WITH (NOLOCK) ON DA.Transfer = 1 AND DA.dThrough = @ThroughDate AND ER.PK_Distributor IN (DA.nDistributorID,DA.nMainDistributorID)   
										UNION  
										SELECT DISTINCT PK_Event,DA.nDistributorID AS PK_Distributor,HasCheckedIn,DA.nDistributorID,DA.nMainDistributorID 
										FROM dbo.EventsRegistration ER WITH (NOLOCK)  
											LEFT JOIN dbo.v_DistributorAssociate2 DA  WITH (NOLOCK) ON DA.Transfer = 0 AND DA.dThrough = @ThroughDate AND ER.PK_Distributor = DA.nMainDistributorID) ER   
							ON E.PK_Event = ER.PK_Event  

						WHERE ET.EventTypeCode IN ('CE','CP','CR')  
						AND ER.PK_Distributor = ER.nDistributorID    
						AND @PK_Distributor IN (ER.nDistributorID,nMainDistributorID)  
						AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
						AND ER.HasCheckedIn = 1   
		
						UNION  
    
						SELECT DISTINCT E.PK_Event   
						FROM dbo.EventType ET  WITH (NOLOCK)  
							INNER JOIN dbo.Event E  WITH (NOLOCK) ON ET.PK_EventType = E.PK_EventType  
							INNER JOIN (SELECT DISTINCT PK_Event,PK_Distributor,HasCheckedIn,DA.nDistributorID,DA.nMainDistributorID FROM dbo.EventsRegistration ER WITH (NOLOCK)  
							LEFT JOIN dbo.v_DistributorAssociate2 DA WITH (NOLOCK) ON DA.Transfer = 1 AND DA.dThrough = @ThroughDate AND ER.PK_Distributor IN (DA.nDistributorID,DA.nMainDistributorID)  
			
						UNION  

						SELECT DISTINCT PK_Event,DA.nDistributorID AS PK_Distributor,HasCheckedIn,DA.nDistributorID,DA.nMainDistributorID FROM dbo.EventsRegistration ER WITH (NOLOCK)  
							LEFT JOIN dbo.v_DistributorAssociate2 DA WITH (NOLOCK) ON DA.Transfer = 0 AND DA.dThrough = @ThroughDate AND ER.PK_Distributor = DA.nMainDistributorID ) ER ON E.PK_Event = ER.PK_Event  
						WHERE ET.EventTypeCode IN ('CE','CP','CR')  
						AND ER.PK_Distributor = ER.nMainDistributorID    
						AND @PK_Distributor IN (ER.nDistributorID,nMainDistributorID)  
						AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
						AND ER.HasCheckedIn = 1   

						UNION  

						SELECT DISTINCT E.PK_Event   
						FROM dbo.EventType ET WITH (NOLOCK)  
							INNER JOIN dbo.Event E  WITH (NOLOCK) ON ET.PK_EventType = E.PK_EventType  
							INNER JOIN dbo.EventsRegistration ER WITH (NOLOCK) ON E.PK_Event = ER.PK_Event  
						WHERE ET.EventTypeCode IN ('CE','CP','CR')  
						AND ER.PK_Distributor = @PK_Distributor   
						AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
						AND ER.HasCheckedIn = 1) TOT  
    
					UNION ALL  
  
					SELECT COUNT(1) AS nCnt  
					FROM dbo.Event E WITH (NOLOCK)  
						INNER JOIN dbo.EventType ET WITH (NOLOCK) ON E.PK_EventType = ET.PK_EventType AND ET.EventTypeCode IN ('CE','CP','CR') 
						--*****************************
						--*****************************
						INNER JOIN dbo.EventQualifier EQ WITH (NOLOCK) ON E.PK_Event = EQ.PK_Event 
						INNER JOIN (SELECT DISTINCT PK_Event, PK_ToDistributor, ValidToDateUTC   
									FROM dbo.EventTicketAssignment ETAA WITH (NOLOCK)  
										LEFT JOIN dbo.v_DistributorAssociate2 DA ON ETAA.PK_ToDistributor IN (DA.nMainDistributorID,DA.nDistributorID) AND DA.Transfer = 1 AND DA.dThrough = @ThroughDate  
									WHERE ETAA.ValidToDateUTC = @ThroughDate  
						
									UNION  

									SELECT DISTINCT PK_Event, DA.nDistributorID AS PK_ToDistributor, ValidToDateUTC   
									FROM dbo.EventTicketAssignment ETAA WITH (NOLOCK)  
										LEFT JOIN dbo.v_DistributorAssociate2 DA ON ETAA.PK_ToDistributor = DA.nMainDistributorID   AND DA.Transfer = 0   AND DA.dThrough = @ThroughDate  
									WHERE ETAA.ValidToDateUTC = @ThroughDate) ETA     
									ON ETA.PK_Event = E.PK_Event AND ETA.PK_ToDistributor = EQ.PK_Distributor AND ETA.ValidToDateUTC = @ThroughDate  
						LEFT JOIN	(SELECT PK_Event,COUNT(1) AS nCnt 
									FROM dbo.EventsRegistration WITH (NOLOCK)  
									GROUP BY PK_Event  
									HAVING COUNT(1) > 10) ER ON ER.PK_Event = E.PK_Event  
						INNER JOIN (SELECT DISTINCT LEE.PK_EventType, LEE.PK_Event, LEE.PK_Distributor, LEE.PK_LeadEvent  
									FROM dbo.LeadEventsRegistration LEE WITH (NOLOCK)  
										LEFT JOIN dbo.v_DistributorAssociate2 DA ON LEE.PK_Distributor IN (DA.nMainDistributorID,DA.nDistributorID) AND DA.Transfer = 1 AND DA.dThrough = @ThroughDate  
									UNION  
									SELECT DISTINCT LEE.PK_EventType, LEE.PK_Event, DA.nDistributorID AS PK_Distributor, LEE.PK_LeadEvent  
									FROM dbo.LeadEventsRegistration LEE WITH (NOLOCK)  
										LEFT JOIN dbo.v_DistributorAssociate2 DA 
											ON LEE.PK_Distributor = DA.nMainDistributorID AND DA.Transfer = 0 AND DA.dThrough = @ThroughDate) LE 
							ON LE.PK_EventType = E.PK_EventType AND LE.PK_Event = EQ.PK_Event AND LE.PK_Distributor = @PK_Distributor  
					WHERE EQ.PK_Distributor = @PK_Distributor AND ER.PK_Event IS NULL AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()    
					GROUP BY E.dStartUTC, E.EventName, E.EventCity, E.Location, CASE WHEN LE.PK_Distributor IS NOT NULL THEN 1 ELSE 0 END, ET.PK_EventType, E.PK_Event, LE.PK_LeadEvent  
  
					UNION ALL  
  
					SELECT  COUNT(1) AS nCnt   
					FROM dbo.EventType ET WITH (NOLOCK)  
						INNER JOIN (SELECT DISTINCT LE.EventDate, LE.PK_EventType, LE.PK_Event, LE.PK_Distributor, LE.CreatedBy  
									FROM dbo.LeadEventsRegistration LE WITH (NOLOCK)  
										LEFT JOIN dbo.v_DistributorAssociate2 DA 
											ON LE.PK_Distributor IN (DA.nMainDistributorID,DA.nDistributorID) AND DA.Transfer = 1 AND DA.dThrough = @ThroughDate  
						
									UNION  
						
									SELECT DISTINCT LE.EventDate, LE.PK_EventType, LE.PK_Event, DA.nDistributorID AS PK_Distributor, LE.CreatedBy  
									FROM dbo.LeadEventsRegistration LE WITH (NOLOCK)  
										LEFT JOIN dbo.v_DistributorAssociate2 DA 
											ON LE.PK_Distributor = DA.nMainDistributorID AND DA.Transfer = 0  AND DA.dThrough = @ThroughDate) E    
							ON ET.PK_EventType = E.PK_EventType    
					WHERE ET.EventTypeCode = 'LA' AND E.CreatedBy = @DistributorID AND E.EventDate > = @FromDate AND E.EventDate < = GETDATE()) AS A 
				--******************************************************************
				--******************************************************************
		
				-- Assign value to @AddEvents based on the above calculation  
  
				SET @AddEvents =	CASE 
									WHEN ((@CorpEventsAttended < 2) OR (@EventsAttended < @MinEventCount))   
										THEN 'AddEvents'  
									ELSE NULL  
									END 

				--******************************************************************
				--Save data (attaendance) on table "EventAttendance" (LMS "LeadAssignment" db and pubeventmanagement db)
				--******************************************************************
				If @DistributorID Is Not Null
				BEGIN
					INSERT INTO [dbo].[DistributorEventAttendance] (DistributorID,AddEvents,MinEventCount,EventsAttended,CorpEventsAttended)
					VALUES (@DistributorID, @AddEvents,@MinEventCount, @EventsAttended, @CorpEventsAttended) 
				END
				--******************************************************************
				--******************************************************************

				--**********************************************
				FETCH DS_cursor INTO @DistributorID
			END
		PRINT 'Done WHILE LOOP ';
		CLOSE DS_cursor;
		DEALLOCATE DS_cursor;
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		PRINT 'Error encountered'
		ROLLBACK TRANSACTION
	END CATCH
	
END
ELSE
BEGIN
	PRINT 'Day invalid'
END
			
	--*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+
	--*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+

END