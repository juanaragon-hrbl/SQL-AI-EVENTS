CREATE PROCEDURE [dbo].[usp_Event_GenerateNote]
	@DistributorID VARCHAR(20) = NULL
	
	-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = NULL OUTPUT

	-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_Event_GenerateNote

USE:			DECLARE @DistributorID VARCHAR(20) = ''
                EXEC dbo.usp_Event_GenerateNote @DistributorID 

DESCRIPTION:	This stored procedure will be used to automatically generate SKU notes into EventDistributorNotes table for the SKUs that are flagged for "Generate Note" in dbo.EventSKU
				and the date is within the scheduled date for the event for automated sku notes in dbo.EventSchedule table. This stored procedure will be called at the end of every SKU job run 
				in dbo.usp_Event_UpdateEventTickets. If DistributorID is passed (during manually adding SKUs), then will only process for that Distributor, else will process for all for that event 
				for the SKUs where IsGenerateNote = 1. Procedure will only update notes for records where the combination of DS, Event, SKU, Order Number and Quantity has changed from previously generated and stored 
				note or where it is a completely new note to be generated. Where all the combinations remain the same, the note will not be touched.
				
				Updated to notes are ONLY performed if the member/DS has not registered and Checked in. Once checked in, notes are not touched.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
	1.0.0	2014-08-13		IniU		Initial
	1.1.0	2019-10-11		puertac		SRE Implementation 
	1.2.0	2019-10-30		puertac		SRE Implementation - Hardcode Review

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

DECLARE @EventNoteType INT = 61	
		,@ScheduleID INT = 10
	

	BEGIN TRY
			IF OBJECT_ID('tempdb..#NewNote', 'U') IS NOT NULL DROP TABLE #NewNote

			SELECT 
				PK_Distributor
				,PK_Event
				,PK_EventNoteType
				,SKUNote
				,QtyCheck
				,PK_EventDistributorNote
			INTO 
				#NewNote
			FROM
			(
			SELECT 
				skp.PK_Distributor_Purchaser AS PK_Distributor
				,'SKU='+es.SKUCode+ ' - '+es.SKUDesc+ '. Order No='+skp.OrderNumber + '. Quantity='+ CONVERT(VARCHAR(5),skp.Quantity)+' Tickets' AS SKUNote
				,skp.PK_Event
				,@EventNoteType AS PK_EventNoteType 
				,skp.PK_EventSKU
				,es.PK_EventSKU AS PK_EventSKu_ES
				,SUBSTRING(edn.notes,CHARINDEX('=',edn.notes)+1,CHARINDEX(' -',edn.notes)-CHARINDEX('=',edn.notes)-1) AS note_SKU
				,es.SKUCode
				,SUBSTRING(edn.notes,CHARINDEX('=',edn.notes,11)+1,CHARINDEX('. Quantity=',edn.notes)-CHARINDEX('=',edn.notes,11)-1) AS Notes_OrderNo
				,SUBSTRING(notes,CHARINDEX('Quantity=',notes)+9,CHARINDEX(' Tickets',notes)-(CHARINDEX('Quantity=',notes)+9)) AS Notes_Qty
				,skp.OrderNumber
				,skp.CreatedDateUTC
				,skp.OrderDate 
				,skp.Quantity
				,CASE WHEN ISNULL(SUBSTRING(edn.Notes,CHARINDEX('Quantity=',edn.Notes)+9,CHARINDEX(' Tickets',edn.Notes)-(CHARINDEX('Quantity=',edn.Notes)+9)),0) = 0 AND skp.Quantity <> 0 THEN 'New' 
					  WHEN ISNULL(SUBSTRING(edn.Notes,CHARINDEX('Quantity=',edn.Notes)+9,CHARINDEX(' Tickets',edn.Notes)-(CHARINDEX('Quantity=',edn.Notes)+9)),0) = skp.Quantity  THEN 'Same' 
					  WHEN ISNULL(SUBSTRING(edn.Notes,CHARINDEX('Quantity=',edn.Notes)+9,CHARINDEX(' Tickets',edn.Notes)-(CHARINDEX('Quantity=',edn.Notes)+9)),0) <> 0 
							AND ISNULL(SUBSTRING(edn.Notes,CHARINDEX('Quantity=',edn.Notes)+9,CHARINDEX(' Tickets',edn.Notes)-(CHARINDEX('Quantity=',edn.Notes)+9)),0) <> skp.Quantity THEN 'Changed' 
					  WHEN ISNULL(SUBSTRING(edn.Notes,CHARINDEX('Quantity=',edn.Notes)+9,CHARINDEX(' Tickets',edn.Notes)-(CHARINDEX('Quantity=',edn.Notes)+9)),0) <> 0 
							AND ISNULL(skp.Quantity,0) = 0 THEN 'Remove' END AS QtyCheck
				,edn.PK_EventDistributorNote  
			FROM 
				dbo.SKUPurchased skp WITH (NOLOCK) 
			INNER JOIN 
				dbo.EventSKU es WITH (NOLOCK)
			ON 
				skp.PK_Event = es.PK_Event  
				AND 
				skp.PK_EventSKU = es.PK_EventSKU 
				AND
				es.IsGenerateNote = 1
			INNER JOIN 
				dbo.EventSchedule sh WITH (NOLOCK)
			ON
				es.PK_Event = sh.PK_Event 
				AND
				sh.PK_Schedule = @ScheduleID -- Generate SKU Note Schedule
				AND
				GETUTCDATE() BETWEEN sh.BeginUTC AND sh.EndUTC 
			LEFT JOIN 
				dbo.EventDistributorNotes edn WITH (NOLOCK) 
			ON 
				skp.PK_Event = edn.PK_Event 
				AND
				edn.PK_EventNoteType = @EventNoteType
				AND 
				skp.PK_Distributor_Purchaser = edn.PK_Distributor 
				AND 
				es.SKUCode = SUBSTRING(edn.notes,CHARINDEX('=',edn.notes)+1,CHARINDEX(' -',edn.notes)-CHARINDEX('=',edn.notes)-1)
				AND 
				LTRIM(SUBSTRING(edn.notes,CHARINDEX('=',edn.notes,11)+1,CHARINDEX('. Quantity=',edn.notes)-CHARINDEX('=',edn.notes,11)-1)) = skp.OrderNumber 
			WHERE
				skp.DistributorID = CASE WHEN @DistributorID IS NULL THEN skp.DistributorID ELSE @DistributorID END
			) xx
			WHERE 
				QtyCheck IN ('New','Changed')
	
			CREATE INDEX IX_#NewNote_PK_Distributor ON #NewNote(PK_Distributor)
			CREATE INDEX IX_#NewNote_PK_EventDistributorNote ON #NewNote(PK_EventDistributorNote)
 
			-- update existing notes
			UPDATE 
				  en
			SET
				  Notes = nn.SKUNote
				  ,ModifiedDateUTC = GETUTCDATE()
			FROM 
				dbo.EventDistributorNotes en 
			INNER JOIN
				#NewNote nn
			ON 
				en.PK_Distributor = nn.PK_Distributor
				AND
				en.PK_EventDistributorNote = nn.PK_EventDistributorNote
			LEFT JOIN
				dbo.EventsRegistration ER WITH (NOLOCK)
			ON
				en.PK_Event = ER.PK_Event 
				AND
				en.PK_Distributor = ER.PK_Distributor 
				AND
				ER.HasCheckedIn = 1
			WHERE 
				nn.PK_EventDistributorNote IS NOT NULL
				AND
				ER.PK_EventsRegistration IS NULL
            
			-- insert new notes
			INSERT INTO dbo.EventDistributorNotes(PK_Distributor,PK_Event,PK_EventNoteType,Notes)
			SELECT 
				  en.PK_Distributor,
				  en.PK_Event,
				  en.PK_EventNoteType,
				  en.SKUNote
			FROM 
				#NewNote en
			LEFT JOIN
				dbo.EventsRegistration ER WITH (NOLOCK)
			ON
				en.PK_Event = ER.PK_Event 
				AND
				en.PK_Distributor = ER.PK_Distributor 
				AND
				ER.HasCheckedIn = 1
			WHERE 
				 PK_EventDistributorNote IS NULL	
				 AND ER.PK_EventsRegistration IS NULL

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH;
END