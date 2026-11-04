
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventSkuQualificationByMemberId]
         -- Mandatory Parameters      
		@MemberID varchar(20) 

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_EventSkuQualificationByMemberId

USE:	        
		Declare @e int, @em varchar(20)
        EXEC dbo.usp_MyHLEventAPI_Get_EventSkuQualificationByMemberId
			@MemberID = 'W1098839'
			,@Error = @e OUTPUT				-- @e must be defined in the local call   
			,@ErrorMessage = @em OUTPUT		-- @em must be defined in the local call   
			,@IsDevQA = 1  

		Print @em  

DESCRIPTION:	Retrieves all associated and active events and indicate if distributor passed qualifies

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.SubEvent, dbo.SubEventQualifiers

VERSIONS
----------------------------------------------------------------------------------
1	2016-04-26	IniU	Intitial
2	2019-08-14	NoeG	Refactor code (SRE)
3	2019-11-04	NoeG	SRE Hardcode changed
******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()			
			,@ValidDate DATETIME = '2049-12-31'
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/******************************************************************************
		 Get applicable and active event(s) and indicate if distributor qualifies
		******************************************************************************/
		; WITH EventSKU(PK_Event,SKUCode,IsEventTicketSKU)
		AS
		(SELECT 
			ES.PK_Event
			,ES.SKUCode
			,ES.IsEventTicketSKU 
		FROM
			dbo.Event E WITH (NOLOCK)
		INNER JOIN
			dbo.EventSKU ES WITH (NOLOCK)
		ON 
			E.PK_Event = ES.PK_Event
			AND
			E.PK_EventType IN (1,2,4)
			AND
			E.IsTicketforQualifiedDS = 1
			AND
			E.dEndUTC >= GETDATE()
		)
		SELECT
			ES.PK_Event
			,ES.SKUCode
			,ES.IsEventTicketSKU
			,CASE WHEN SQ.DistributorID IS NOT NULL THEN 1 ELSE 0 END AS IsQualified
		FROM
			EventSKU ES WITH (NOLOCK)
		OUTER APPLY (
			SELECT 
			DISTINCT 
				SEQ.PK_Event
				,SEQ.DistributorID 
		FROM
			dbo.SubEventQualifier SEQ WITH (NOLOCK)
		INNER JOIN
			dbo.SubEvent SE WITH (NOLOCK)
		ON
			SE.PK_Event = SEQ.PK_Event 
			AND
			SE.PK_SubEvent = SEQ.PK_SubEvent 
			AND
			SE.IsMainEventQual = 1
			AND
			SEQ.RemovedUTC = @ValidDate
			AND
			SE.PK_Event = ES.PK_Event 
			AND
			SEQ.DistributorID = @MemberID
		) SQ

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
	END CATCH
	
/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

