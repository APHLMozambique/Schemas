

use master
IF EXISTS(select * from sys.databases where name='OpenLDRData')
BEGIN
	IF EXISTS (SELECT * FROM OpenLDRData.dbo.VersionControl WHERE VersionStamp = '1.0.0')
	BEGIN
		set nocount on
			PRINT 'The database OpenLDRData already exists'
        	set nocount off
	END
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'OpenLDRData'
	ALTER DATABASE [OpenLDRData] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE [OpenLDRData]
END
GO
CREATE DATABASE OpenLDRData  
COLLATE SQL_Latin1_General_CP1_CI_AS;
GO


USE [OpenLDRData]
GO
/****** Object:  UserDefinedFunction [dbo].[GetAgeGroup]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[GetAgeGroup] (@InString Int)
RETURNS nvarchar(64)
WITH EXECUTE AS CALLER
AS
BEGIN
    -- notice the spaces before the age groups to help with sorting
    DECLARE @OutString nvarchar(64);

    IF (@InString Is Null) BEGIN
        SET @OutString = 'No Age Specified';
    END ELSE BEGIN
		SET @OutString = 
	        CASE 
			WHEN @InString < 2 THEN ' <2'
			WHEN @InString BETWEEN 2 and 5 THEN ' 2-5'
			WHEN @InString BETWEEN 6 and 14 THEN ' 6-14'
			WHEN @InString BETWEEN 15 and 49 THEN '15-49'
			WHEN @InString >= 50 THEN '50+'
			ELSE 'No Age Specified'
		    END;
    END;
	    
    RETURN(@OutString);

END;



GO
/****** Object:  UserDefinedFunction [dbo].[getHealthCareCode]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getHealthCareCode]
(
	-- Add the parameters for the function here
	@facilityCode varchar(20)
)
RETURNS VARCHAR(20)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @healthAreaCode varchar(20)

	SELECT @healthAreaCode = HealthcareDistrictCode FROM OpenLDRDict.dbo.viewFacilities dict WHERE dict.FacilityCode = @facilityCode

	-- Return the result of the function
	RETURN @healthAreaCode

END




GO
/****** Object:  UserDefinedFunction [dbo].[GetReasonForTest]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetReasonForTest] (@InString nvarchar(1024))
RETURNS nvarchar(64)
WITH EXECUTE AS CALLER
AS
BEGIN
    
    DECLARE @OutString nvarchar(64);

    IF (@InString Is Null) BEGIN
        SET @OutString = 'Reason Not Specified';
    END ELSE BEGIN
		SET @OutString = 
	        CASE 
			WHEN @InString = 'Nao Prenchido' THEN 'Not Specified'
			WHEN @InString = 'Suspect treatment failure' THEN 'Suspected treatment failure'
			WHEN @InString = 'Repiticas apos AMA' THEN 'Repeat after breastfeeding'
			WHEN @InString = 'Rotina' THEN 'Routine'
			WHEN @InString = '' THEN 'Reason Not Specified'
			ELSE @InString
		    END;
    END;
	    
    RETURN(@OutString);

END;



GO
/****** Object:  UserDefinedFunction [dbo].[getRequestIDsWithUpdatedDateTimeStamp]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[getRequestIDsWithUpdatedDateTimeStamp](@startDate date, @endDate date)
RETURNS @requestIDs TABLE (
   RequestID nvarchar(26) PRIMARY KEY CLUSTERED
) 
AS
BEGIN
	INSERT INTO @requestIDS
	SELECT Requests.RequestId
    FROM Requests LEFT JOIN LabResults ON Requests.RequestID = labResults.RequestID AND Requests.OBRSetID = LabResults.OBRSetID
    WHERE (
            (Requests.LIMSPanelCode = 'VIRAL')
            OR (Requests.LIMSPanelCode = 'HIVVL')
          )
    AND (
		(Requests.DateTimeStamp >= @startDate AND Requests.DateTimeStamp < @endDate)
		OR
		(LabResults.DateTimeStamp Is Not Null AND LabResults.DateTimeStamp >= @startDate AND LabResults.DateTimeStamp < @endDate)
		)
	GROUP BY Requests.RequestID;
 
   RETURN;
END;



GO
/****** Object:  UserDefinedFunction [dbo].[IfEmptyReturnValue]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[IfEmptyReturnValue] (@InString nvarchar(1024), @ReturnIfEmpty nvarchar(1024))
RETURNS nvarchar(1024)
WITH EXECUTE AS CALLER
AS
BEGIN
	-- This function is a kind of override for IsNull in order to not only check for Null values but for empty strings
	-- It is definitely a bit slower so if you need it to run on a large data set and know the exact values you are trying to eliminate it might
	-- be best to do it direclty in the SQL or making this function more direct.
	-- SELECT dbo.IfEmptyReturnValue(Null,'00');
	-- SELECT dbo.IfEmptyReturnValue('','00');
	-- SELECT dbo.IfEmptyReturnValue('    ','00');
	-- SELECT dbo.IfEmptyReturnValue('a','00');
    
    DECLARE @OutString nvarchar(1024);

    IF (@InString Is Null) BEGIN
        SET @OutString = @ReturnIfEmpty;
    END ELSE BEGIN
		SET @OutString = 
	        CASE LTRIM(RTRIM(@InString))
			WHEN '' THEN @ReturnIfEmpty
			ELSE @InString
		    END;
    END;
	    
    RETURN(@OutString);

END;


GO
/****** Object:  UserDefinedFunction [dbo].[ufn_GetAgeGroupJSON]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ufn_GetAgeGroupJSON] (@alias nvarchar(50))
RETURNS nvarchar(1000)
AS
BEGIN
RETURN REPLACE(N'{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365) IS NULL","then":"''N '''' Especif.''","alias":"' + @alias + '"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  < 2","then":"''< 2 Anos''","alias":"' + @alias + '"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  <= 5","then":"''2-5 Anos''","alias":"' + @alias + '"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  <= 14","then":"''6-14 Anos''","alias":"' + @alias + '"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  <= 49","then":"''15-49 Anos''","alias":"' + @alias + '"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  > 49","then":"''>= 50 Anos''","alias":"' + @alias + '"}
,{"else":"''N '''' Especif.''","alias":"' + @alias + '"}', Char(13)+Char(10), '')
END


GO
/****** Object:  UserDefinedFunction [dbo].[ViralLoadResultMerge]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ViralLoadResultMerge] (
				@HIVVL_Result nvarchar(1024),
				@LIMSCodedValue nvarchar(1024)
			--@PCR_ViralLoadCAPCTM nvarchar(1024)
			)
RETURNS nvarchar(1024)
WITH EXECUTE AS CALLER
AS
BEGIN
	-- This function examines four fields and returns a group the result belongs.
	-- The highest priority is given to the viral load result kicked off by the HIVVL panel and then viral load results kicked off by the PCR LIMSPanelCode
	-- Note that the PCR only results in the single result column PCR_ViralLoadCAPCTM <
    DECLARE @OutString nvarchar(1024);
	DECLARE @results TABLE(Code varchar(50), Value varchar(100))

	INSERT INTO @results VAlUES('TND','Nivel de detecçao baixo'),('LDL', 'Nivel de detecçao baixo'),('NEG', 'Negativo'),('POS','Positivo'),('I','Indeterminado')

	IF (@HIVVL_Result Is Null OR @HIVVL_Result = '') BEGIN
		SELECT @OutString = ISNULL(Value, @LIMSCodedValue) FROM @results WHERE Code = @LIMSCodedValue
	END
	ELSE
	BEGIN
		SET @OutString = @HIVVL_Result
	END
		
	    
    RETURN(@OutString);

END;



GO
/****** Object:  UserDefinedFunction [dbo].[ViralLoadResultRange]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ViralLoadResultRange] (
			@HIVVL_ViralLoadResult nvarchar(1024), 
			@HIVVL_ViralLoadCAPCTM nvarchar(1024)
			--@PCR_ViralLoadCAPCTM nvarchar(1024)
			)
RETURNS nvarchar(1024)
WITH EXECUTE AS CALLER
AS
BEGIN
	-- This function examines four fields and returns a group the result belongs.
	-- The highest priority is given to the viral load result kicked off by the HIVVL panel and then viral load results kicked off by the PCR LIMSPanelCode
	-- Note that the PCR only results in the single result column PCR_ViralLoadCAPCTM <
    DECLARE @OutString nvarchar(1024);

    IF (@HIVVL_ViralLoadResult Is Not Null) BEGIN
		-- Examinining the data for 2016 this means some variation on below detectable level is in this column
        SET @OutString = 'Suppressed';
    END ELSE BEGIN

	    IF (@HIVVL_ViralLoadCAPCTM Is Not Null) BEGIN
			IF (IsNumeric( @HIVVL_ViralLoadCAPCTM ) = 1) BEGIN
				IF ( @HIVVL_ViralLoadCAPCTM  < 1000 ) BEGIN
					SET @OutString = 'Suppressed';
				END ELSE BEGIN
					SET @OutString = 'Not Suppressed';
				END;

			END ELSE BEGIN
				-- HIVVL_ViralLoadResult must be text
				IF ( @HIVVL_ViralLoadCAPCTM  = 'Positive' ) BEGIN
					SET @OutString = 'Not Suppressed';
				END ELSE BEGIN
					SET @OutString = 
						CASE @HIVVL_ViralLoadCAPCTM 
						WHEN 'Interminado' THEN 'Indeterminate'
						WHEN 'Positive' THEN 'Not Suppressed'
						ELSE 'Suppressed'
						END;
				END;
			END;

		END /*ELSE BEGIN
			-- @HIVVL_ViralLoadCAPCTM Is Null so Look at PCR results
			
		    IF (@PCR_ViralLoadCAPCTM Is Not Null) BEGIN

				IF (IsNumeric(@PCR_ViralLoadCAPCTM) = 1) BEGIN
					IF ( @PCR_ViralLoadCAPCTM  < 1000 ) BEGIN
						SET @OutString = 'Suppressed';
					END ELSE BEGIN
						SET @OutString = 'Not Suppressed';
					END;

				END ELSE BEGIN
					-- HIVVL_ViralLoadResult must be text
					IF ( @PCR_ViralLoadCAPCTM  = 'Positive' ) BEGIN
						SET @OutString = 'Not Suppressed';
					END ELSE BEGIN
						SET @OutString = 
							CASE @PCR_ViralLoadCAPCTM 
							WHEN 'Interminado' THEN 'Indeterminate'
							WHEN 'Positive' THEN 'Not Suppressed'
							ELSE 'Suppressed'
							END;
					END;
				END;

			END ELSE BEGIN 
				-- All three values are null so return 'Untested
				SET @OutString = 'Not Suppressed';
			END;
		END;*/
		
    END;
	    
    RETURN(@OutString);

END;



GO
/****** Object:  Table [dbo].[AdminScriptRun_LDRData]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdminScriptRun_LDRData](
	[AdminScriptRunID] [int] IDENTITY(1,1) NOT NULL,
	[ScriptName] [nvarchar](255) NULL,
	[RunTime] [datetime] NULL,
 CONSTRAINT [aaaaaAdminScriptRunID_PK] PRIMARY KEY NONCLUSTERED 
(
	[AdminScriptRunID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LabResults]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LabResults](
	[DateTimeStamp] [datetime] NULL,
	[Versionstamp] [varchar](30) NULL,
	[LIMSDateTimeStamp] [datetime] NULL,
	[LIMSVersionStamp] [varchar](30) NULL,
	[RequestID] [varchar](26) NULL,
	[OBRSetID] [int] NULL,
	[OBXSetID] [int] NULL,
	[OBXSubID] [int] NULL,
	[LOINCCode] [varchar](30) NULL,
	[HL7ResultTypeCode] [varchar](2) NULL,
	[SIValue] [float] NULL,
	[SIUnits] [varchar](25) NULL,
	[SILoRange] [float] NULL,
	[SIHiRange] [float] NULL,
	[HL7AbnormalFlagCodes] [varchar](5) NULL,
	[DateTimeValue] [datetime] NULL,
	[CodedValue] [varchar](1) NULL,
	[ResultSemiquantitive] [int] NULL,
	[Note] [bit] NULL,
	[LIMSObservationCode] [varchar](10) NULL,
	[LIMSObservationDesc] [varchar](50) NULL,
	[LIMSRptResult] [varchar](80) NULL,
	[LIMSRptUnits] [varchar](25) NULL,
	[LIMSRptFlag] [varchar](25) NULL,
	[LIMSRptRange] [varchar](25) NULL,
	[LIMSCodedValue] [varchar](5) NULL,
	[WorkUnits] [float] NULL,
	[CostUnits] [float] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Monitoring]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Monitoring](
	[DateTimeStamp] [datetime] NULL,
	[Versionstamp] [varchar](30) NULL,
	[LIMSDateTimeStamp] [datetime] NULL,
	[LIMSVersionstamp] [varchar](30) NULL,
	[RequestID] [varchar](26) NULL,
	[OBRSetID] [int] NULL,
	[OBXSetID] [int] NULL,
	[OBXSubID] [int] NULL,
	[LOINCCode] [varchar](30) NULL,
	[ORGANISM] [varchar](50) NULL,
	[SurveillanceCode] [varchar](5) NULL,
	[SpecimenDateTime] [datetime] NULL,
	[LIMSObservationCode] [varchar](25) NULL,
	[LIMSObservationDesc] [varchar](50) NULL,
	[LIMSOrganismGroup] [varchar](25) NULL,
	[CodedValue] [varchar](1) NULL,
	[ResultSemiquantitive] [int] NULL,
	[ResultNotConfirmed] [bit] NULL,
	[ResistantDrugs] [varchar](250) NULL,
	[IntermediateDrugs] [varchar](250) NULL,
	[SensitiveDrugs] [varchar](250) NULL,
	[MDRCode] [char](1) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Patients]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Patients](
	[DateTimeStamp] [datetime] NULL,
	[Versionstamp] [varchar](30) NULL,
	[LIMSDateTimeStamp] [datetime] NULL,
	[LIMSVersionStamp] [varchar](30) NULL,
	[RequestID] [varchar](26) NULL,
	[REFNO] [varchar](56) NULL,
	[REGISTEREDDATE] [datetime] NULL,
	[LOCATION] [varchar](5) NULL,
	[WARD] [varchar](5) NULL,
	[HOSPID] [varchar](26) NULL,
	[NATIONALITY] [varchar](5) NULL,
	[NATIONALID] [varchar](26) NULL,
	[UNIQUEID] [varchar](31) NULL,
	[SURNAME] [varchar](31) NULL,
	[FIRSTNAME] [varchar](31) NULL,
	[INITIALS] [varchar](16) NULL,
	[REFDRCODE] [varchar](5) NULL,
	[REFDR] [varchar](41) NULL,
	[MEDAID] [varchar](5) NULL,
	[MEDAIDNO] [varchar](26) NULL,
	[BILLACCNO] [varchar](23) NULL,
	[TELHOME] [varchar](20) NULL,
	[TELWORK] [varchar](20) NULL,
	[MOBILE] [varchar](20) NULL,
	[EMAIL] [varchar](60) NULL,
	[DOB] [date] NULL,
	[DOBType] [varchar](25) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Requests]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Requests](
	[DateTimeStamp] [datetime] NULL,
	[Versionstamp] [varchar](30) NULL,
	[LIMSDateTimeStamp] [datetime] NULL,
	[LIMSVersionstamp] [varchar](30) NULL,
	[RequestID] [varchar](26) NULL,
	[OBRSetID] [int] NULL,
	[LOINCPanelCode] [varchar](10) NULL,
	[LIMSPanelCode] [varchar](10) NULL,
	[LIMSPanelDesc] [varchar](50) NULL,
	[HL7PriorityCode] [char](1) NULL,
	[SpecimenDateTime] [datetime] NULL,
	[LIMSPreReg_RegistrationDateTime] [datetime] NULL,
	[LIMSPreReg_ReceivedDateTime] [datetime] NULL,
	[LIMSPreReg_RegistrationFacilityCode] [varchar](15) NULL,
	[RegisteredDateTime] [datetime] NULL,
	[ReceivedDateTime] [datetime] NULL,
	[AnalysisDateTime] [datetime] NULL,
	[AuthorisedDateTime] [datetime] NULL,
	[AdmitAttendDateTime] [datetime] NULL,
	[CollectionVolume] [float] NULL,
	[RequestingFacilityCode] [varchar](15) NULL,
	[ReceivingFacilityCode] [varchar](10) NULL,
	[LIMSPointOfCareDesc] [varchar](50) NULL,
	[RequestTypeCode] [varchar](3) NULL,
	[ICD10ClinicalInfoCodes] [varchar](50) NULL,
	[ClinicalInfo] [varchar](250) NULL,
	[HL7SpecimenSourceCode] [varchar](10) NULL,
	[LIMSSpecimenSourceCode] [varchar](10) NULL,
	[LIMSSpecimenSourceDesc] [varchar](50) NULL,
	[HL7SpecimenSiteCode] [varchar](10) NULL,
	[LIMSSpecimenSiteCode] [varchar](10) NULL,
	[LIMSSpecimenSiteDesc] [varchar](50) NULL,
	[WorkUnits] [float] NULL,
	[CostUnits] [float] NULL,
	[HL7SectionCode] [varchar](3) NULL,
	[HL7ResultStatusCode] [char](1) NULL,
	[RegisteredBy] [varchar](250) NULL,
	[TestedBy] [varchar](250) NULL,
	[AuthorisedBy] [varchar](250) NULL,
	[OrderingNotes] [varchar](250) NULL,
	[EncryptedPatientID] [varchar](64) NULL,
	[AgeInYears] [int] NULL,
	[AgeInDays] [int] NULL,
	[HL7SexCode] [char](1) NULL,
	[HL7EthnicGroupCode] [char](3) NULL,
	[Deceased] [bit] NULL,
	[Newborn] [bit] NULL,
	[HL7PatientClassCode] [char](1) NULL,
	[AttendingDoctor] [varchar](50) NULL,
	[TestingFacilityCode] [varchar](10) NULL,
	[ReferringRequestID] [varchar](25) NULL,
	[Therapy] [varchar](250) NULL,
	[LIMSAnalyzerCode] [varchar](10) NULL,
	[TargetTimeDays] [int] NULL,
	[TargetTimeMins] [int] NULL,
	[LIMSRejectionCode] [varchar](10) NULL,
	[LIMSRejectionDesc] [varchar](250) NULL,
	[LIMSFacilityCode] [varchar](15) NULL,
	[Repeated] [tinyint] NULL,
	[LIMSVendorCode] [varchar](4) NULL,
	[RequestingFacilityNationalCode] [varchar](15) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VersionControl]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VersionControl](
	[DateTimeStamp] [datetime] NULL,
	[VersionActivationDate] [datetime] NULL,
	[VERBase] [int] NULL,
	[VERUpdate] [int] NULL,
	[VERBuild] [int] NULL,
	[VersionStamp] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[viewVL_Info]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[viewVL_Info]
AS 
-- This view grabs the request and extra registration information related to LIMSObservationCode = VIRAL
-- 24-Jul-19 Brett Staib - Added new info fields being added through VIRAL panel CONSE, LABLO
SELECT 
	req.RequestID, req.OBRSetID, req.LIMSPanelCode, req.LIMSPanelDesc, req.AgeInYears, req.AgeInDays, req.HL7SexCode, 
	req.SpecimenDatetime, req.RegisteredDateTime, req.ReceivedDateTime, req.AuthorisedDateTime, req.AnalysisDateTime, req.LIMSRejectionCode, req.LIMSRejectionDesc, 
	CASE WHEN preg.LIMSRptResult Is Null THEN 'Unreported'
		ELSE preg.LIMSRptResult
	END AS Pregnant, -- preg.LIMSObservationCode,
	CASE WHEN bf.LIMSRptResult Is Null THEN 'Unreported'
		ELSE bf.LIMSRptResult
	END AS BreastFeeding, -- bf.LIMSObservationCode,
	CASE WHEN ft.LIMSRptResult Is Null THEN 'Unreported'
		ELSE ft.LIMSRptResult
	END AS FirstTime, -- ft.LIMSObservationCode,
	CASE WHEN cday.LIMSRptResult Is Null THEN 'Unreported'
		ELSE cday.LIMSRptResult
	END AS CollectedDate, -- cday.LIMSObservationCode,
	ctime.LIMSRptResult AS CollectedTime, -- ctime.LIMSObservationCode,
	tarvd.LIMSRptResult AS DataDeInicioDoTARV, -- tarvd.LIMSObservationCode,
	tarvp.LIMSRptResult AS PrimeiraLinha, -- tarvp.LIMSObservationCode,
	tarvs.LIMSRptResult AS SegundaLinha, -- tarvs.LIMSObservationCode,
	TARVQ.LIMSRptResult AS ARTRegimen,
	LABTI.LIMSRptResult AS TypeOfSampleCollection, 
	VIRAD.LIMSRptResult AS LastViralLoadDate, 
	VIRR1.LIMSRptResult AS LastViralLoadResult, 
	LABNO.LIMSRptResult AS RequestingClinician, 
	CONSE.LIMSRptResult AS ConsentimentoParaContacto, 
	LABLO.LIMSRptResult AS LocalDeColheita, 
	dbo.GetReasonForTest(motivo.LIMSRptResult) AS ReasonForTest, 
	req.DateTimeStamp, req.Versionstamp, req.LIMSDateTimeStamp, req.LIMSVersionstamp,
	req.LOINCPanelCode,  req.HL7PriorityCode, req.AdmitAttendDateTime, req.CollectionVolume, 
	req.LIMSFacilityCode, limsFacility.[Description] AS LIMSFacilityName, limsFacility.ProvinceName AS LIMSProvinceName, limsFacility.DistrictName AS LIMSDistrictName,
	req.RequestingFacilityCode, requestingFacility.[Description] AS RequestingFacilityName, requestingFacility.ProvinceName AS RequestingProvinceName, requestingFacility.DistrictName AS RequestingDistrictName,
	req.ReceivingFacilityCode, receivingFacility.[Description] AS ReceivingFacilityName, receivingFacility.ProvinceName AS ReceivingProvinceName, receivingFacility.DistrictName AS ReceivingDistrictName,
	req.TestingFacilityCode, testingFacility.[Description] AS TestingFacilityName, testingFacility.ProvinceName AS testingProvinceName, testingFacility.DistrictName AS TestingDistrictName,
	req.LIMSPointOfCareDesc, req.RequestTypeCode, req.ICD10ClinicalInfoCodes, req.ClinicalInfo, req.HL7SpecimenSourceCode, req.LIMSSpecimenSourceCode, 
	req.LIMSSpecimenSourceDesc, req.HL7SpecimenSiteCode, req.LIMSSpecimenSiteCode, req.LIMSSpecimenSiteDesc, req.WorkUnits, req.CostUnits, 
	req.HL7SectionCode, req.HL7ResultStatusCode, req.RegisteredBy, req.TestedBy, req.AuthorisedBy, req.OrderingNotes, req.EncryptedPatientID, 
	req.HL7EthnicGroupCode, req.Deceased, req.Newborn, req.HL7PatientClassCode, req.AttendingDoctor, req.ReferringRequestID, 
	req.Therapy, req.LIMSAnalyzerCode, req.TargetTimeDays, req.TargetTimeMins, 
	req.Repeated
FROM Requests AS req
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'ENCON' -- Pregnant
) AS preg ON req.RequestID = preg.RequestID AND req.OBRSetID = preg.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'AMAME' -- Breast Feeding
) AS bf ON req.RequestID = bf.RequestID AND req.OBRSetID = bf.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'VIRAP' -- First time
) AS ft ON req.RequestID = ft.RequestID AND req.OBRSetID = ft.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'LABDA' -- Collection Day
) AS cday ON req.RequestID = cday.RequestID AND req.OBRSetID = cday.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'LABHO' -- Collection Hour
) AS ctime ON req.RequestID = ctime.RequestID AND req.OBRSetID = ctime.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'TARVD' -- Data de in¡cio do TARV
) AS tarvd ON req.RequestID = tarvd.RequestID AND req.OBRSetID = tarvd.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'TARVP' -- Primeira Linha
) AS tarvp ON req.RequestID = tarvp.RequestID AND req.OBRSetID = tarvp.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'TARVS' -- 
) AS tarvs ON req.RequestID = tarvs.RequestID AND req.OBRSetID = tarvs.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'ESCOL' --		Motivo da Requerimento
) AS motivo ON req.RequestID = motivo.RequestID AND req.OBRSetID = motivo.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'TARVQ' --		ART Regimen
) AS TARVQ ON req.RequestID = TARVQ.RequestID AND req.OBRSetID = TARVQ.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'LABTI' --		Type of Sample Collection
) AS LABTI ON req.RequestID = LABTI.RequestID AND req.OBRSetID = LABTI.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'VIRAD' --		Last Viral Load Date
) AS VIRAD ON req.RequestID = VIRAD.RequestID AND req.OBRSetID = VIRAD.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'VIRR1' --		Last Viral Load Result
) AS VIRR1 ON req.RequestID = VIRR1.RequestID AND req.OBRSetID = VIRR1.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'LABNO' --		Requesting Clinician
) AS LABNO ON req.RequestID = LABNO.RequestID AND req.OBRSetID = LABNO.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'CONSE' -- CONSE Consentimento para contacto
) AS CONSE ON req.RequestID = CONSE.RequestID AND req.OBRSetID = CONSE.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'LABLO' --	LABLO Local de colheita
) AS LABLO ON req.RequestID = LABLO.RequestID AND req.OBRSetID = LABLO.OBRSetID
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS limsFacility ON req.LIMSFacilityCode = limsFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS requestingFacility ON req.RequestingFacilityCode = requestingFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS receivingFacility ON req.ReceivingFacilityCode = receivingFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS testingFacility ON req.TestingFacilityCode = testingFacility.FacilityCode
WHERE req.LIMSPanelCode = 'VIRAL'



GO
/****** Object:  View [dbo].[viewVL_Result]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[viewVL_Result]
AS 
-- This view grabs the request and a little extra information about LIMSObservationCode = HIVVL
-- This query may eventually need to have some other technical information added like unit and reference ranges but for now just keeping it simple
SELECT 
	req.RequestID, req.OBRSetID, req.LIMSPanelCode, req.LIMSPanelDesc, req.AuthorisedDateTime AS HIVVL_AuthorisedDateTime, 
	req.LIMSRejectionCode AS HIVVL_LIMSRejectionCode, req.LIMSRejectionDesc AS HIVVL_LIMSRejectionDesc,
	[dbo].[ViralLoadResultMerge](hivvd.LIMSRptResult,hivvd.LIMSCodedValue) AS HIVVL_ViralLoadResult, 
	[dbo].[ViralLoadResultMerge](hivvr.LIMSRptResult,hivvr.LIMSCodedValue) AS HIVVL_ViralLoadCAPCTM, 
	[dbo].[ViralLoadResultMerge](hivvc.LIMSRptResult,hivvc.LIMSCodedValue) AS HIVVL_Low_value, 
	[dbo].[ViralLoadResultMerge](hivvf.LIMSRptResult,hivvf.LIMSCodedValue) AS HIVVL_Viral, 
	hivrl.LIMSRptResult AS HIVVL_VRLogValue,
	req.AgeInYears, req.AgeInDays, req.HL7SexCode, 
	req.SpecimenDatetime, req.RegisteredDateTime, req.ReceivedDateTime, req.AuthorisedDateTime, req.AnalysisDateTime, req.LIMSRejectionCode, req.LIMSRejectionDesc, 
	req.DateTimeStamp, req.Versionstamp, req.LIMSDateTimeStamp, req.LIMSVersionstamp,
	req.LOINCPanelCode,  req.HL7PriorityCode, req.AdmitAttendDateTime, req.CollectionVolume, 
	req.LIMSFacilityCode, limsFacility.[Description] AS LIMSFacilityName, limsFacility.ProvinceName AS LIMSProvinceName, limsFacility.DistrictName AS LIMSDistrictName,
	req.RequestingFacilityCode, requestingFacility.[Description] AS RequestingFacilityName, requestingFacility.ProvinceName AS RequestingProvinceName, requestingFacility.DistrictName AS RequestingDistrictName,
	req.ReceivingFacilityCode, receivingFacility.[Description] AS ReceivingFacilityName, receivingFacility.ProvinceName AS ReceivingProvinceName, receivingFacility.DistrictName AS ReceivingDistrictName,
	req.TestingFacilityCode, testingFacility.[Description] AS TestingFacilityName, testingFacility.ProvinceName AS testingProvinceName, testingFacility.DistrictName AS TestingDistrictName,
	req.LIMSPointOfCareDesc, req.RequestTypeCode, req.ICD10ClinicalInfoCodes, req.ClinicalInfo, req.HL7SpecimenSourceCode, req.LIMSSpecimenSourceCode, 
	req.LIMSSpecimenSourceDesc, req.HL7SpecimenSiteCode, req.LIMSSpecimenSiteCode, req.LIMSSpecimenSiteDesc, req.WorkUnits, req.CostUnits, 
	req.HL7SectionCode, req.HL7ResultStatusCode, req.RegisteredBy, req.TestedBy, req.AuthorisedBy, req.OrderingNotes, req.EncryptedPatientID, 
	req.HL7EthnicGroupCode, req.Deceased, req.Newborn, req.HL7PatientClassCode, req.AttendingDoctor, 
	req.ReferringRequestID, req.Therapy, req.LIMSAnalyzerCode, req.TargetTimeDays, req.TargetTimeMins, req.Repeated
FROM Requests AS req
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'HIVVD' -- CAP/CTM
) AS hivvd ON req.RequestID = hivvd.RequestID AND req.OBRSetID = hivvd.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'HIVVR' -- Viral Load Result
) AS hivvr ON req.RequestID = hivvr.RequestID AND req.OBRSetID = hivvr.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'HIVVC' -- HIV : Viral load (low value) 
) AS hivvc ON req.RequestID = hivvc.RequestID AND req.OBRSetID = hivvc.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'HIVVF' -- HIV Viral
) AS hivvf ON req.RequestID = hivvf.RequestID AND req.OBRSetID = hivvf.OBRSetID
LEFT JOIN (
	SELECT * FROM LabResults WHERE LIMSObservationCode = 'HIVRL' -- Log Value
) AS hivrl ON req.RequestID = hivrl.RequestID AND req.OBRSetID = hivrl.OBRSetID
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS limsFacility ON req.LIMSFacilityCode = limsFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS requestingFacility ON req.RequestingFacilityCode = requestingFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS receivingFacility ON req.ReceivingFacilityCode = receivingFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS testingFacility ON req.TestingFacilityCode = testingFacility.FacilityCode
WHERE req.LIMSPanelCode = 'HIVVL'





GO
/****** Object:  UserDefinedFunction [dbo].[getVL_Vendor1_AnalysisDatetime]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[getVL_Vendor1_AnalysisDatetime] (@startDate Date, @endDate Date)
RETURNS TABLE
AS RETURN (
-- 2-Oct-17 Brett Staib - Changed query to  get AnalysisDateTime and AuthorisedDateTime from HIVVL rather than from VIRAL panel
SELECT 	mainRequests.RequestID, result.AgeInDays, result.RegisteredDateTime, result.HL7SexCode, result.SpecimenDatetime, result.ReceivedDateTime,
 result.AnalysisDateTime, result.AuthorisedDateTime, result.LIMSRejectionCode, result.LIMSRejectionDesc, result.LIMSDateTimeStamp, result.Newborn,
 IsNull(info.Pregnant,'Unreported') AS Pregnant, IsNull(info.BreastFeeding,'Unreported') AS BreastFeeding,
 IsNull(info.FirstTime,'Unreported') AS FirstTime, info.CollectedDate, info.CollectedTime, info.DataDeInicioDoTARV, 
 IsNull(info.PrimeiraLinha, 'Unreported') AS PrimeiraLinha, 
 IsNull(info.SegundaLinha,'Unreported') AS SegundaLinha,
 IsNull(info.ARTRegimen, 'Unreported') AS ARTRegimen, 
 IsNull(info.TypeOfSampleCollection,'Unreported') AS TypeOfSampleCollection,
 IsNull(info.LastViralLoadDate, 'Unreported') AS LastViralLoadDate, 
 IsNull(info.LastViralLoadResult,'Unreported') AS LastViralLoadResult,
 IsNull(info.RequestingClinician, 'Unreported') AS RequestingClinician, 
 result.LIMSVersionstamp, result.LOINCPanelCode, result.HL7PriorityCode, result.AdmitAttendDateTime,  result.CollectionVolume,
 result.LIMSFacilityCode, result.LIMSFacilityName, result.LIMSProvinceName, result.LIMSDistrictName, 
 result.RequestingFacilityCode,  result.RequestingFacilityName,  result.RequestingProvinceName, result.RequestingDistrictName, 
 result.ReceivingFacilityCode,  result.ReceivingFacilityName,  result.ReceivingProvinceName, result.ReceivingDistrictName, 
 result.TestingFacilityCode, result.TestingFacilityName, result.TestingProvinceName, result.TestingDistrictName, 
 result.LIMSPointOfCareDesc,  result.RequestTypeCode, result.ICD10ClinicalInfoCodes, result.ClinicalInfo,
 result.HL7SpecimenSourceCode, result.LIMSSpecimenSourceCode,
 result.LIMSSpecimenSourceDesc, result.HL7SpecimenSiteCode, result.LIMSSpecimenSiteCode, result.LIMSSpecimenSiteDesc, result.WorkUnits, result.CostUnits,
 result.HL7SectionCode, result.HL7ResultStatusCode, result.RegisteredBy, result.TestedBy, result.AuthorisedBy, result.OrderingNotes, result.EncryptedPatientID,
 result.HL7EthnicGroupCode, result.Deceased, result.HL7PatientClassCode, result.AttendingDoctor,
 result.ReferringRequestID, result.Therapy, result.LIMSAnalyzerCode, result.TargetTimeDays, result.TargetTimeMins, result.Repeated,
 result.HIVVL_AuthorisedDateTime, result.HIVVL_LIMSRejectionCode, result.HIVVL_LIMSRejectionDesc, result.HIVVL_VRLogValue,
 [dbo].[ViralLoadResultRange] (HIVVL_ViralLoadResult, ISNULL(result.HIVVL_ViralLoadCAPCTM, ISNULL(result.HIVVL_Low_value, result.HIVVL_Viral))) AS ViralLoadResultCategory,
 result.HIVVL_ViralLoadResult, ISNULL(result.HIVVL_ViralLoadCAPCTM, ISNULL(result.HIVVL_Low_value, result.HIVVL_Viral)) HIVVL_ViralLoadCAPCTM, 
 [dbo].[GetAgeGroup](result.AgeInYears) AS AgeGroup,
 result.AgeInYears,
 IsNull(info.ReasonForTest,'Reason Not Specified') AS ReasonForTest,
 CONCAT(YEAR(result.RegisteredDateTime), '-', DatePart(QUARTER, result.RegisteredDateTime)) AS RegisteredYearAndQuarter,
 CONCAT(YEAR(result.RegisteredDateTime),'-',Month(result.RegisteredDateTime)) AS RegisteredYearAndMonth
FROM
-- First get a listing of all RequestIDs that look like they had an actual viral load test requested
(
    SELECT DISTINCT Requests.RequestId
    FROM Requests LEFT JOIN LabResults ON Requests.RequestID = labResults.RequestID AND Requests.OBRSetID = LabResults.OBRSetID
    WHERE (
            (Requests.LIMSPanelCode = 'VIRAL')
            OR (Requests.LIMSPanelCode = 'HIVVL')
        )
    AND Requests.AnalysisDateTime Is Not Null
    AND Requests.AnalysisDatetime >= @startDate AND Requests.AnalysisDatetime < @endDate
) AS mainRequests
LEFT JOIN viewVL_Info AS info ON mainRequests.RequestID = info.RequestID
LEFT JOIN viewVL_Result AS result ON mainRequests.RequestID = result.RequestID
)


GO
/****** Object:  UserDefinedFunction [dbo].[getVL_Vendor1_WithPatients_DateTimeStamp]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ########################################################
CREATE FUNCTION [dbo].[getVL_Vendor1_WithPatients_DateTimeStamp] (@startDate Datetime, @endDate Datetime)
RETURNS TABLE
AS RETURN (
-- select * from dbo.[getVL_Vendor1_DateTimeStamp]('2016-09-01','2016-12-01')
-- select * from dbo.[getVL_Vendor1_DateTimeStamp]('2016-01-01','2017-04-01') 
-- The only difference with this function and the RegisteredDatetime function is the sub query selecting RequestIDs
-- So if you are changing one just copy it and change the three column instances 
-- 2-Oct-17 Brett Staib - Changed query to  get AnalysisDateTime and AuthorisedDateTime from HIVVL rather than from VIRAL panel
-- 7-Dec-17 Brettt Staib - Changed the query do no longer have the sub query but instead do straight table joins 
--          It's important to note that I use the table alias result for the view returning the actual test results however,
--          this query starts with requests and does a left join into LabResults so it may have Requests without results but it serves
--          as a list of all requests as well as containing any possible result data. I use this view as the primary list of requests
--          to return because there might not be a row in the Info query if it was missing the Viral query (which is common)
SELECT patients.RequestID, patients.Versionstamp, patients.[REFNO],patients.[REGISTEREDDATE]
      ,patients.[LOCATION],patients.[WARD],patients.[HOSPID],patients.[NATIONALITY]
      ,patients.[NATIONALID],patients.[UNIQUEID], patients.SURNAME, patients.FIRSTNAME, 
	  patients.[INITIALS],patients.[REFDRCODE],patients.[REFDR],patients.[MEDAID],patients.[MEDAIDNO]
      ,patients.[BILLACCNO],patients.[TELHOME],patients.[TELWORK],patients.[MOBILE],patients.[EMAIL],
	  patients.DOB, patients.DOBType, result.AgeInDays, result.HL7SexCode,  result.SpecimenDatetime, result.ReceivedDateTime, result.RegisteredDateTime,
 result.AnalysisDateTime, result.AuthorisedDateTime, result.LIMSRejectionCode, result.LIMSRejectionDesc, result.LIMSDateTimeStamp, result.Newborn,
 IsNull(info.Pregnant,'Unreported') AS Pregnant, IsNull(info.BreastFeeding,'Unreported') AS BreastFeeding,
 IsNull(info.FirstTime,'Unreported') AS FirstTime, info.CollectedDate, info.CollectedTime, info.DataDeInicioDoTARV, 
 IsNull(info.PrimeiraLinha, 'Unreported') AS PrimeiraLinha, 
 IsNull(info.SegundaLinha,'Unreported') AS SegundaLinha,
 IsNull(info.ARTRegimen, 'Unreported') AS ARTRegimen, 
 IsNull(info.TypeOfSampleCollection,'Unreported') AS TypeOfSampleCollection,
 IsNull(info.LastViralLoadDate, 'Unreported') AS LastViralLoadDate, 
 IsNull(info.LastViralLoadResult,'Unreported') AS LastViralLoadResult,
 IsNull(info.RequestingClinician, 'Unreported') AS RequestingClinician, 
 result.LIMSVersionstamp, result.LOINCPanelCode, result.HL7PriorityCode, result.AdmitAttendDateTime, result.CollectionVolume,
 result.LIMSFacilityCode, result.LIMSFacilityName, result.LIMSProvinceName, result.LIMSDistrictName, 
 ISNULL(fac.MohFacilityCode, result.RequestingFacilityCode) RequestingFacilityCode, result.RequestingFacilityName, result.RequestingProvinceName, result.RequestingDistrictName, 
 result.ReceivingFacilityCode, result.ReceivingFacilityName, result.ReceivingProvinceName, result.ReceivingDistrictName, 
 result.TestingFacilityCode, result.TestingFacilityName, result.TestingProvinceName, result.TestingDistrictName, 
 result.LIMSPointOfCareDesc,  result.RequestTypeCode, result.ICD10ClinicalInfoCodes, result.ClinicalInfo,
 result.HL7SpecimenSourceCode, result.LIMSSpecimenSourceCode,
 result.LIMSSpecimenSourceDesc, result.HL7SpecimenSiteCode, result.LIMSSpecimenSiteCode, result.LIMSSpecimenSiteDesc, result.WorkUnits, result.CostUnits,
 result.HL7SectionCode, result.HL7ResultStatusCode, result.RegisteredBy, result.TestedBy, result.AuthorisedBy, result.OrderingNotes, result.EncryptedPatientID,
 result.HL7EthnicGroupCode, result.Deceased, result.HL7PatientClassCode, result.AttendingDoctor,
 result.ReferringRequestID, result.Therapy, result.LIMSAnalyzerCode, result.TargetTimeDays, result.TargetTimeMins, result.Repeated,
 result.HIVVL_AuthorisedDateTime, result.HIVVL_LIMSRejectionCode, result.HIVVL_LIMSRejectionDesc, result.HIVVL_VRLogValue,
 [dbo].[ViralLoadResultRange] (HIVVL_ViralLoadResult, ISNULL(result.HIVVL_ViralLoadCAPCTM, ISNULL(result.HIVVL_Low_value, result.HIVVL_Viral))) AS ViralLoadResultCategory,
 result.HIVVL_ViralLoadResult, ISNULL(result.HIVVL_ViralLoadCAPCTM, ISNULL(result.HIVVL_Low_value, result.HIVVL_Viral)) HIVVL_ViralLoadCAPCTM, 
 [dbo].[GetAgeGroup](result.AgeInYears) AS AgeGroup,
 result.AgeInYears,
 IsNull(info.ReasonForTest,'Reason Not Specified') AS ReasonForTest,
 CONCAT(YEAR(result.RegisteredDateTime), '-', DATEPART(QUARTER, result.RegisteredDateTime)) AS RegisteredYearAndQuarter,
 CONCAT(YEAR(result.RegisteredDateTime), '-', Month(result.RegisteredDateTime)) AS RegisteredYearAndMonth,
  --- New Lines
 IIF(info.DateTimeStamp IS NULL OR result.DateTimeStamp IS NULL, ISNULL(info.DateTimeStamp,result.DateTimeStamp), IIF(info.DateTimeStamp < result.DateTimeStamp, info.DateTimeStamp, result.DateTimeStamp)) AS DateTimeStamp,
 dbo.[getHealthCareCode] (result.RequestingFacilityCode) AS HealthcareDistrictCode,
 fac.HealthCareID AS FullHealthCareID
FROM
-- First get a listing of all RequestIDs that look like they had an actual viral load test requested
( 
	SELECT DISTINCT Requests.RequestId
    FROM Requests LEFT JOIN LabResults ON Requests.RequestID = labResults.RequestID AND Requests.OBRSetID = LabResults.OBRSetID
    WHERE (
            (Requests.LIMSPanelCode = 'VIRAL')
            OR (Requests.LIMSPanelCode = 'HIVVL')
          )
    AND (
		(Requests.DateTimeStamp >= @startDate AND Requests.DateTimeStamp < @endDate)
		OR
		(LabResults.DateTimeStamp Is Not Null AND LabResults.DateTimeStamp >= @startDate AND LabResults.DateTimeStamp < @endDate)
		)
) AS mainRequests
LEFT JOIN Patients AS patients ON patients.RequestID = mainRequests.RequestID
INNER JOIN viewVL_Result AS result ON mainRequests.RequestID = result.RequestID 
LEFT JOIN viewVL_Info AS info ON result.RequestID = info.RequestID -- AND result.OBRSetID = info.OBRSetID
LEFT JOIN OpenLDRDict.dbo.Facilities AS fac ON info.RequestingFacilityCode = fac.FacilityCode
)

GO
/****** Object:  UserDefinedFunction [dbo].[getVL_Vendor1_RegisteredDatetime]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[getVL_Vendor1_RegisteredDatetime] (@startDate Date, @endDate Date)
RETURNS TABLE
AS RETURN (
-- select * from dbo.getVL_Vendor1_RegisteredDatetime(DATEADD(DAY, -90, CURRENT_TIMESTAMP ), CURRENT_TIMESTAMP)
-- 2-Oct-17 Brett Staib - Changed query to  get AnalysisDateTime and AuthorisedDateTime from HIVVL rather than from VIRAL panel
-- 24-Jul-19 Brett Staib - updated query that retreives RequestIDs to not join in labresults; no need for it; it was just in there from cutting and pasting from DatetimeStamp view
SELECT 	mainRequests.RequestID, result.AgeInDays, result.RegisteredDateTime, result.HL7SexCode, result.SpecimenDatetime, result.ReceivedDateTime,
 result.AnalysisDateTime, result.AuthorisedDateTime, result.LIMSRejectionCode, result.LIMSRejectionDesc, result.LIMSDateTimeStamp, result.Newborn,
 IsNull(info.Pregnant,'Unreported') AS Pregnant, IsNull(info.BreastFeeding,'Unreported') AS BreastFeeding,
 IsNull(info.FirstTime,'Unreported') AS FirstTime, info.CollectedDate, info.CollectedTime, info.DataDeInicioDoTARV, 
 IsNull(info.PrimeiraLinha, 'Unreported') AS PrimeiraLinha, 
 IsNull(info.SegundaLinha,'Unreported') AS SegundaLinha,
 IsNull(info.ARTRegimen, 'Unreported') AS ARTRegimen, 
 IsNull(info.TypeOfSampleCollection,'Unreported') AS TypeOfSampleCollection,
 IsNull(info.LastViralLoadDate, 'Unreported') AS LastViralLoadDate, 
 IsNull(info.LastViralLoadResult,'Unreported') AS LastViralLoadResult,
 IsNull(info.RequestingClinician, 'Unreported') AS RequestingClinician, 
 IsNull(info.ConsentimentoParaContacto, 'Unreported') AS ConsentimentoParaContacto, 
 IsNull(info.LocalDeColheita, 'Unreported') AS LocalDeColheita, 
 result.LIMSVersionstamp, result.LOINCPanelCode, result.HL7PriorityCode, result.AdmitAttendDateTime,  result.CollectionVolume,
 result.LIMSFacilityCode, result.LIMSFacilityName, result.LIMSProvinceName, result.LIMSDistrictName, 
 result.RequestingFacilityCode,  result.RequestingFacilityName,  result.RequestingProvinceName, result.RequestingDistrictName, 
 result.ReceivingFacilityCode,  result.ReceivingFacilityName,  result.ReceivingProvinceName, result.ReceivingDistrictName, 
 result.TestingFacilityCode, result.TestingFacilityName, result.TestingProvinceName, result.TestingDistrictName, 
 result.LIMSPointOfCareDesc,  result.RequestTypeCode, result.ICD10ClinicalInfoCodes, result.ClinicalInfo,
 result.HL7SpecimenSourceCode, result.LIMSSpecimenSourceCode,
 result.LIMSSpecimenSourceDesc, result.HL7SpecimenSiteCode, result.LIMSSpecimenSiteCode, result.LIMSSpecimenSiteDesc, result.WorkUnits, result.CostUnits,
 result.HL7SectionCode, result.HL7ResultStatusCode, result.RegisteredBy, result.TestedBy, result.AuthorisedBy, result.OrderingNotes, result.EncryptedPatientID,
 result.HL7EthnicGroupCode, result.Deceased, result.HL7PatientClassCode, result.AttendingDoctor,
 result.ReferringRequestID, result.Therapy, result.LIMSAnalyzerCode, result.TargetTimeDays, result.TargetTimeMins, result.Repeated,
 result.HIVVL_AuthorisedDateTime, result.HIVVL_LIMSRejectionCode, result.HIVVL_LIMSRejectionDesc, result.HIVVL_VRLogValue,
 [dbo].[ViralLoadResultRange] (HIVVL_ViralLoadResult, ISNULL(result.HIVVL_ViralLoadCAPCTM, ISNULL(result.HIVVL_Low_value, result.HIVVL_Viral))) AS ViralLoadResultCategory,
 result.HIVVL_ViralLoadResult, ISNULL(result.HIVVL_ViralLoadCAPCTM, ISNULL(result.HIVVL_Low_value, result.HIVVL_Viral)) HIVVL_ViralLoadCAPCTM, 
 [dbo].[GetAgeGroup](result.AgeInYears) AS AgeGroup,
 result.AgeInYears,
 IsNull(info.ReasonForTest,'Reason Not Specified') AS ReasonForTest,
 CONCAT(YEAR(result.RegisteredDateTime), '-', DatePart(QUARTER, result.RegisteredDateTime)) AS RegisteredYearAndQuarter,
 CONCAT(YEAR(result.RegisteredDateTime),'-',Month(result.RegisteredDateTime)) AS RegisteredYearAndMonth
FROM
(
    SELECT DISTINCT Requests.RequestId
    FROM Requests 
	WHERE (
            (Requests.LIMSPanelCode = 'VIRAL')
            OR (Requests.LIMSPanelCode = 'HIVVL')
        )
    AND Requests.RegisteredDateTime Is Not Null
    AND Requests.RegisteredDatetime >= @startDate AND Requests.RegisteredDatetime < @endDate
) AS mainRequests
LEFT JOIN viewVL_Info AS info ON mainRequests.RequestID = info.RequestID
LEFT JOIN viewVL_Result AS result ON mainRequests.RequestID = result.RequestID
)


GO
/****** Object:  UserDefinedFunction [dbo].[getVL_Vendor1_DateTimeStamp]    Script Date: 27/08/2019 16:43:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[getVL_Vendor1_DateTimeStamp] (@startDate Date, @endDate Date)
RETURNS TABLE
AS RETURN (
-- select * from dbo.getVL_Vendor1_DateTimeStamp(DATEADD(DAY, -90, CURRENT_TIMESTAMP ), CURRENT_TIMESTAMP)
-- select * from dbo.[getVL_Vendor1_DateTimeStamp]('2016-09-01','2016-12-01')
-- select * from dbo.[getVL_Vendor1_DateTimeStamp]('2016-01-01','2017-04-01') 
-- The only difference with this function and the RegisteredDatetime function is the sub query selecting RequestIDs
-- So if you are changing one just copy it and change the three column instances 
-- 2-Oct-17 Brett Staib - Changed query to  get AnalysisDateTime and AuthorisedDateTime from HIVVL rather than from VIRAL panel
-- 7-Dec-17 Brett Staib - Changed the query do no longer have the sub query but instead do straight table joins 
--          It's important to note that I use the table alias result for the view returning the actual test results however,
--          this query starts with requests and does a left join into LabResults so it may have Requests without results but it serves
--          as a list of all requests as well as containing any possible result data. I use this view as the primary list of requests
--          to return because there might not be a row in the Info query if it was missing the Viral query (which is common)
-- 24-Jul-19 Brett Staib - Removed the function call to get the RequestIDs and put the SQL directly in this query. It doesn't
--           allow you have all related queries use the same exact list but the performance improvement is worth it (2:30->:56) 
SELECT 	mainRequests.RequestID, result.AgeInDays, result.RegisteredDateTime, result.HL7SexCode, result.SpecimenDatetime, result.ReceivedDateTime,
 result.AnalysisDateTime, result.AuthorisedDateTime, result.LIMSRejectionCode, result.LIMSRejectionDesc, result.LIMSDateTimeStamp, result.Newborn,
 IsNull(info.Pregnant,'Unreported') AS Pregnant, IsNull(info.BreastFeeding,'Unreported') AS BreastFeeding,
 IsNull(info.FirstTime,'Unreported') AS FirstTime, info.CollectedDate, info.CollectedTime, info.DataDeInicioDoTARV, 
 IsNull(info.PrimeiraLinha, 'Unreported') AS PrimeiraLinha, 
 IsNull(info.SegundaLinha,'Unreported') AS SegundaLinha,
 IsNull(info.ARTRegimen, 'Unreported') AS ARTRegimen, 
 IsNull(info.TypeOfSampleCollection,'Unreported') AS TypeOfSampleCollection,
 IsNull(info.LastViralLoadDate, 'Unreported') AS LastViralLoadDate, 
 IsNull(info.LastViralLoadResult,'Unreported') AS LastViralLoadResult,
 IsNull(info.RequestingClinician, 'Unreported') AS RequestingClinician, 
 IsNull(info.ConsentimentoParaContacto, 'Unreported') AS ConsentimentoParaContacto, 
 IsNull(info.LocalDeColheita, 'Unreported') AS LocalDeColheita, 
 result.LIMSVersionstamp, result.LOINCPanelCode, result.HL7PriorityCode, result.AdmitAttendDateTime,  result.CollectionVolume,
 result.LIMSFacilityCode, result.LIMSFacilityName, result.LIMSProvinceName, result.LIMSDistrictName, 
 result.RequestingFacilityCode,  result.RequestingFacilityName,  result.RequestingProvinceName, result.RequestingDistrictName, 
 result.ReceivingFacilityCode,  result.ReceivingFacilityName,  result.ReceivingProvinceName, result.ReceivingDistrictName, 
 result.TestingFacilityCode, result.TestingFacilityName, result.TestingProvinceName, result.TestingDistrictName, 
 result.LIMSPointOfCareDesc,  result.RequestTypeCode, result.ICD10ClinicalInfoCodes, result.ClinicalInfo,
 result.HL7SpecimenSourceCode, result.LIMSSpecimenSourceCode,
 result.LIMSSpecimenSourceDesc, result.HL7SpecimenSiteCode, result.LIMSSpecimenSiteCode, result.LIMSSpecimenSiteDesc, result.WorkUnits, result.CostUnits,
 result.HL7SectionCode, result.HL7ResultStatusCode, result.RegisteredBy, result.TestedBy, result.AuthorisedBy, result.OrderingNotes, result.EncryptedPatientID,
 result.HL7EthnicGroupCode, result.Deceased, result.HL7PatientClassCode, result.AttendingDoctor,
 result.ReferringRequestID, result.Therapy, result.LIMSAnalyzerCode, result.TargetTimeDays, result.TargetTimeMins, result.Repeated,
 result.HIVVL_AuthorisedDateTime, result.HIVVL_LIMSRejectionCode, result.HIVVL_LIMSRejectionDesc, result.HIVVL_VRLogValue,
  [dbo].[ViralLoadResultRange] (HIVVL_ViralLoadResult, ISNULL(result.HIVVL_ViralLoadCAPCTM, ISNULL(result.HIVVL_Low_value, result.HIVVL_Viral))) AS ViralLoadResultCategory,
 result.HIVVL_ViralLoadResult, ISNULL(result.HIVVL_ViralLoadCAPCTM, ISNULL(result.HIVVL_Low_value, result.HIVVL_Viral)) HIVVL_ViralLoadCAPCTM,  
 [dbo].[GetAgeGroup](result.AgeInYears) AS AgeGroup,
 result.AgeInYears,
 IsNull(info.ReasonForTest,'Reason Not Specified') AS ReasonForTest,
 CONCAT(YEAR(result.RegisteredDateTime), '-', DatePart(QUARTER, result.RegisteredDateTime)) AS RegisteredYearAndQuarter,
 CONCAT(YEAR(result.RegisteredDateTime),'-',Month(result.RegisteredDateTime)) AS RegisteredYearAndMonth
FROM
-- First get a listing of all RequestIDs that look like they had an actual viral load test requested
( 
	SELECT DISTINCT Requests.RequestId
    FROM Requests LEFT JOIN LabResults ON Requests.RequestID = labResults.RequestID AND Requests.OBRSetID = LabResults.OBRSetID
    WHERE (
            (Requests.LIMSPanelCode = 'VIRAL')
            OR (Requests.LIMSPanelCode = 'HIVVL')
          )
    AND (
		(Requests.DateTimeStamp >= @startDate AND Requests.DateTimeStamp < @endDate)
		OR
		(LabResults.DateTimeStamp Is Not Null AND LabResults.DateTimeStamp >= @startDate AND LabResults.DateTimeStamp < @endDate)
		)
) AS mainRequests
-- getRequestIDsWithUpdatedDateTimeStamp(@startDate, @endDate) 
INNER JOIN viewVL_Result AS result ON mainRequests.RequestID = result.RequestID 
LEFT JOIN viewVL_Info AS info ON result.RequestID = info.RequestID -- AND result.OBRSetID = info.OBRSetID
)


GO

INSERT INTO [OpenLDRData].[dbo].[VersionControl] VALUES(GETDATE(),GETDATE(),null,null,null,'1.0.0')

GO
