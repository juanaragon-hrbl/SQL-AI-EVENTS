CREATE PROCEDURE [dbo].[usp_Update_BizworkReportEnabled]
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_Update_BizworkReportEnabled

USE:	        EXEC dbo.usp_Update_BizworkReportEnabled

DESCRIPTION:	This stored procedure is used to update IsPublish,IsBizworkReportEnabled real time in Events_BizWorks 
				
----------------------------------------------------------------------------------

VERSIONS
----------------------------------------------------------------------------------
1	2017-04-13	Prashanth Intitial
2   2019-10-17  SushmaA	  SRE updates for NOLOCK, NOCOUNT, SELECT *
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	Update EB
	Set    EB.IsPublish=E.IsPublish,
		   EB.IsBizworkReportEnabled=E.IsBizworkReportEnabled,
		   EB.ModifiedDate=E.ModifiedDateUTC,
		   EB.ModifiedBy=E.ModifiedBy
	From   dbo.Event E 
	Join   dbo.Event_Bizworks EB (NOLOCK)
	On     E.Pk_Event=EB.Pk_Event
	
	Update SEB
	Set    SEB.IncludeInBizworkReport=SE.IncludeInBizworkReport,
		   SEB.ModifiedDate=SE.ModifiedDateUTC,
		   SEB.ModifiedBy=SE.ModifiedBy
	From   dbo.SubEvent SE 
	Join   dbo.SubEvent_Bizworks SEB (NOLOCK)
	On     SE.Pk_Event=SEB.Pk_Event 
	AND    SE.Pk_Subevent=SEB.Pk_Subevent

END
