USE [ViralLoadData]
GO
/****** Object:  UserDefinedFunction [dbo].[get_months_and_years_within_dateRange]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[get_months_and_years_within_dateRange]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[get_months_and_years_within_dateRange]
(	
	-- Add the parameters for the function here
	@startDate varchar(20),
	@endDate varchar(20)
)
RETURNS @table TABLE(Data varchar(50))
AS
BEGIN
  
	;WITH CTE AS
	(
		 SELECT CONVERT(DATE, @startDate) AS Dates
  
		 UNION ALL
  
		 SELECT DATEADD(MONTH, 1, Dates)
		 FROM CTE
		 WHERE CONVERT(DATE, Dates) <= CONVERT(DATE, @endDate)
	)
	INSERT INTO @table
	SELECT DATENAME(MONTH,Dates) + '' '' + DATENAME(YEAR, Dates) FROM CTE
	OPTION (maxrecursion 0)
	
	RETURN 
END



' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getHealthCareCode]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getHealthCareCode]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'-- =============================================
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


' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getInitialTestNationalSuppressionRateByAge]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getInitialTestNationalSuppressionRateByAge]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getInitialTestNationalSuppressionRateByAge] (@age1 int, @age2 int, @gender varchar(5), @startDate Date, @endDate Date)

RETURNS @supression TABLE(DistrictName varchar(100), X_Age varchar(100), Y_male int, Y_female int, TotalSuppressed int, Total int, total_percentage float)
AS 
BEGIN
	DECLARE @male int
	DECLARE @female int
	DECLARE @totalSuppressed int
	DECLARE @total int
	DECLARE @percentage float
	DECLARE @age varchar(20)
	DECLARE @table TABLE(idHealthFacility int, DistrictName varchar(100))
	DECLARE @supTable TABLE(DistrictName varchar(100), X_Age varchar(100), Y_male int, Y_female int, TotalSuppressed int, Total int, total_percentage float)
	DECLARE @i int 
	DECLARE @ord int
	DECLARE @district varchar(100)


	SET @age = (SELECT CONCAT(@age1, '' - '', @age2))

	INSERT INTO @table VALUES 
	(1, ''Distrito de Lichinga''),
	(2, ''Pemba''),
	(3, ''Nampula''),
	(4, ''Quelimane''),
	(5, ''Tete''),
	(6, ''Chimoio''),
	(7, ''Beira''),
	(8, ''Maxixe''),
	(9, ''Xai-Xai''),
	(10, ''Matola''),
	(11, ''Chockwe''),
	(12, ''Manhi‡a''),
	(13, ''Bilene''),
	(14, ''Namacurra''),
	(15, ''Mocuba''),
	(16, ''Nicoadala''),
	(17, ''Dondo''),
	(18, ''Moatize''), 
	(19, ''Nhamatanda'')
	SET @i = 1
	WHILE @i < (SELECT COUNT(1) + 1 FROM @table)
	BEGIN
		SELECT @ord = tbl.idHealthFacility, @district = tbl.DistrictName  FROM (
			SELECT idHealthFacility, DistrictName FROM @table
		) AS tbl
		WHERE @i = tbl.idHealthFacility 

		SELECT 
			@totalSuppressed  = COUNT(1),
			@male   = COUNT(iif(HL7SexCode = ''M'',1,NULL)),
			@female = COUNT(iif(HL7SexCode = ''F'',1,NULL))
		FROM ViralLoadData.dbo.VlData 
		WHERE ViralLoadResultCategory = ''Suppressed'' AND AnalysisDateTime >= @startDate AND 
			  AnalysisDateTime <= @endDate AND AgeInYears >= @age1 AND AgeInYears <= @age2 AND
			  RequestingDistrictName = @district

		SELECT @total = COUNT(1) FROM ViralLoadData.dbo.VlData 
		WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory <> '''' AND AgeInYears <= @age2 AND
		RequestingDistrictName = @district

		SET @total = (SELECT iif(@total = 0, 1, @total))
		SET @percentage = (SELECT (@totalSuppressed/@total)*100)

		INSERT INTO @supTable
		SELECT @district, @age, @male, @female, @totalSuppressed, @total, @percentage
		
		SET @i = @i + 1

	END

	INSERT INTO @supression
	SELECT '''', @age, SUM(Y_male), SUM(Y_female), SUM(TotalSuppressed), SUM(Total), SUM(total_percentage) FROM @supTable

	RETURN 

END



' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getInitialTestSuppressionRateByAge]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getInitialTestSuppressionRateByAge]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getInitialTestSuppressionRateByAge] (@age1 int, @age2 int, @gender varchar(5), @startDate Date, @endDate Date)

RETURNS @supression TABLE(DistrictName varchar(100), X_Age varchar(100), Y_male int, Y_female int, TotalSuppressed int, Total int, total_percentage float)
AS 
BEGIN
	DECLARE @male int
	DECLARE @female int
	DECLARE @totalSuppressed int
	DECLARE @total int
	DECLARE @percentage float
	DECLARE @age varchar(20)
	DECLARE @table TABLE(idHealthFacility int, DistrictName varchar(100))
	DECLARE @i int 
	DECLARE @ord int
	DECLARE @district varchar(100)


	SET @age = (SELECT CONCAT(@age1, '' - '', @age2))

	INSERT INTO @table VALUES 
	(1, ''Distrito de Lichinga''),
	(2, ''Pemba''),
	(3, ''Nampula''),
	(4, ''Quelimane''),
	(5, ''Tete''),
	(6, ''Chimoio''),
	(7, ''Beira''),
	(8, ''Maxixe''),
	(9, ''Xai-Xai''),
	(10, ''Matola''),
	(11, ''Chockwe''),
	(12, ''Manhi‡a''),
	(13, ''Bilene''),
	(14, ''Namacurra''),
	(15, ''Mocuba''),
	(16, ''Nicoadala''),
	(17, ''Dondo''),
	(18, ''Moatize''), 
	(19, ''Nhamatanda'')
	SET @i = 1
	WHILE @i < (SELECT COUNT(1) + 1 FROM @table)
	BEGIN
		SELECT @ord = tbl.idHealthFacility, @district = tbl.DistrictName  FROM (
			SELECT idHealthFacility, DistrictName FROM @table
		) AS tbl
		WHERE @i = tbl.idHealthFacility 

		SELECT 
			@totalSuppressed  = COUNT(1),
			@male   = COUNT(iif(HL7SexCode = ''M'',1,NULL)),
			@female = COUNT(iif(HL7SexCode = ''F'',1,NULL))
		FROM ViralLoadData.dbo.VlData 
		WHERE ViralLoadResultCategory = ''Suppressed'' AND AnalysisDateTime >= @startDate AND 
			  AnalysisDateTime <= @endDate AND AgeInYears >= @age1 AND AgeInYears <= @age2 AND
			  RequestingDistrictName = @district

		SELECT @total = COUNT(1) FROM ViralLoadData.dbo.VlData 
		WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory <> '''' AND AgeInYears <= @age2 AND
		RequestingDistrictName = @district

		SET @percentage = (SELECT (@totalSuppressed/@total)*100)

		INSERT INTO @supression
		SELECT @district, @age, @male, @female, @totalSuppressed, @total, @percentage
		SET @i = @i + 1

	END

	RETURN 

END



' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getNationalSuppressionRateByAge]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getNationalSuppressionRateByAge]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getNationalSuppressionRateByAge] (@age1 int, @age2 int, @gender varchar(5), @startDate Date, @endDate Date)

RETURNS @supression TABLE(X_Age varchar(100), Y_male int, Y_female int, TotalSuppressed int, Total int, total_percentage float)
AS 
BEGIN
	DECLARE @male int
	DECLARE @female int
	DECLARE @totalSuppressed int
	DECLARE @total int
	DECLARE @percentage float
	DECLARE @age varchar(20)

	SET @age = (SELECT CONCAT(@age1,'' - '',@age2))

	
	SELECT 
		@totalSuppressed  = COUNT(1),
		@male   = COUNT(iif(HL7SexCode = ''M'',1,NULL)),
		@female = COUNT(iif(HL7SexCode = ''F'',1,NULL))
	FROM ViralLoadData.dbo.VlData WHERE ViralLoadResultCategory = ''Suppressed'' AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND AgeInYears >= @age1 AND AgeInYears <= @age2 

	SELECT @total = COUNT(1) FROM ViralLoadData.dbo.VlData 
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory <> '''' AND AgeInYears <= @age2 

	SET @total = (SELECT iif(@total = 0, 1, @total))
	SET @percentage = (SELECT (@totalSuppressed/@total)*100)

	INSERT INTO @supression
	SELECT @age, @male, @female, @totalSuppressed, @total, (@totalSuppressed/@total)*100


	RETURN 
END



' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getNotInitialTestNationalSuppressionRateByAge]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getNotInitialTestNationalSuppressionRateByAge]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getNotInitialTestNationalSuppressionRateByAge] (@age1 int, @age2 int, @gender varchar(5), @startDate Date, @endDate Date)

RETURNS @supression TABLE(DistrictName varchar(100), X_Age varchar(100), Y_male int, Y_female int, TotalSuppressed int, Total int, total_percentage float)
AS 
BEGIN
	DECLARE @male int
	DECLARE @female int
	DECLARE @totalSuppressed int
	DECLARE @total int
	DECLARE @percentage float
	DECLARE @age varchar(20)
	DECLARE @table TABLE(idHealthFacility int, DistrictName varchar(100))
	DECLARE @tempTable TABLE(Ord int, DistrictName varchar(100))
	DECLARE @supTable TABLE(DistrictName varchar(100), X_Age varchar(100), Y_male int, Y_female int, TotalSuppressed int, Total int, total_percentage float)
	DECLARE @i int 
	DECLARE @ord int
	DECLARE @district varchar(100)


	SET @age = (SELECT CONCAT(@age1, '' - '', @age2))

	INSERT INTO @table VALUES 
	(1, ''Distrito de Lichinga''),
	(2, ''Pemba''),
	(3, ''Nampula''),
	(4, ''Quelimane''),
	(5, ''Tete''),
	(6, ''Chimoio''),
	(7, ''Beira''),
	(8, ''Maxixe''),
	(9, ''Xai-Xai''),
	(10, ''Matola''),
	(11, ''Chockwe''),
	(12, ''Manhi‡a''),
	(13, ''Bilene''),
	(14, ''Namacurra''),
	(15, ''Mocuba''),
	(16, ''Nicoadala''),
	(17, ''Dondo''),
	(18, ''Moatize''), 
	(19, ''Nhamatanda'')

	INSERT INTO @tempTable
	SELECT ROW_NUMBER() OVER(ORDER BY tbl.HealthcareAreaCode), tbl.HealthcareAreaDesc  FROM (
			SELECT * FROM OpenLDRDict.dbo.HealthcareAreas AS dict WHERE dict.HealthcareAreaDesc NOT IN (SELECT DistrictName FROM @table) AND LEN(dict.HealthcareAreaCode) = 8
		) AS tbl

	SET @i = 1
	WHILE @i < (SELECT COUNT(1) + 1 FROM OpenLDRDict.dbo.HealthcareAreas AS dict WHERE dict.HealthcareAreaDesc NOT IN (SELECT DistrictName FROM @table) AND LEN(dict.HealthcareAreaCode) = 8)
	BEGIN
		SELECT @ord = Ord, @district = DistrictName FROM @tempTable WHERE Ord = @i
		
		SELECT 
			  @totalSuppressed  = COUNT(1),
			  @male   = COUNT(iif(HL7SexCode = ''M'',1,NULL)),
			  @female = COUNT(iif(HL7SexCode = ''F'',1,NULL))
		FROM  ViralLoadData.dbo.VlData 
		WHERE ViralLoadResultCategory = ''Suppressed'' AND AnalysisDateTime >= @startDate AND 
			  AnalysisDateTime <= @endDate AND AgeInYears >= @age1 AND AgeInYears <= @age2 AND   
			  RequestingDistrictName = @district

		SELECT @total = COUNT(1) FROM ViralLoadData.dbo.VlData 
		WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory <> '''' AND AgeInYears <= @age2 AND
		RequestingDistrictName = @district
		SET @total = (SELECT iif(@total = 0, 1, @total))
		SET @percentage = (SELECT (@totalSuppressed/@total)*100)

		INSERT INTO @supTable
		SELECT @district, @age, @male, @female, @totalSuppressed, @total, @percentage
		
		SET @i = @i + 1

	END

	INSERT INTO @supression
	SELECT '''', @age, SUM(Y_male), SUM(Y_female), SUM(TotalSuppressed), SUM(Total), SUM(total_percentage) FROM @supTable

	RETURN 

END



' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getNumberOfSamples]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getNumberOfSamples]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getNumberOfSamples]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(100), NAME VARCHAR(200), COLLECTED int, RECEIVED int, REGISTERED int, TESTED int, AUTHORISED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @samplesCollected int
	DECLARE @samplesRegistered int
	DECLARE @samplesReceived int
	DECLARE @samplesTested int
	DECLARE @samplesAuthorized int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )

	SET @startDate = CONCAT(@startDate, '' 00:00'')
	SET @endDate   = CONCAT(@endDate, '' 23:59:59'')

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')


		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories))
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(SpecimenDatetime >= @startDate AND SpecimenDatetime <= @endDate, 1, NULL)),
				   @samplesReceived    = COUNT(iif(ReceivedDatetime >= @startDate AND ReceivedDatetime <= @endDate, 1, NULL)),
				   @samplesRegistered  = COUNT(iif(RegisteredDatetime >= @startDate AND RegisteredDatetime <= @endDate, 1, NULL)),
				   @samplesTested      = COUNT(iif(AnalysisDatetime >= @startDate AND AnalysisDatetime <= @endDate, 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(AuthorisedDatetime >= @startDate AND AuthorisedDatetime <= @endDate, 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id

			SELECT TOP 1 @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(SpecimenDatetime >= @startDate AND SpecimenDatetime <= @endDate, 1, NULL)),
				   @samplesReceived    = COUNT(iif(ReceivedDatetime >= @startDate AND ReceivedDatetime <= @endDate, 1, NULL)),
				   @samplesRegistered  = COUNT(iif(RegisteredDatetime >= @startDate AND RegisteredDatetime <= @endDate, 1, NULL)),
				   @samplesTested      = COUNT(iif(AnalysisDatetime >= @startDate AND AnalysisDatetime <= @endDate, 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(AuthorisedDatetime >= @startDate AND AuthorisedDatetime <= @endDate, 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'')
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(SpecimenDatetime >= @startDate AND SpecimenDatetime <= @endDate, 1, NULL)),
				   @samplesReceived    = COUNT(iif(ReceivedDatetime >= @startDate AND ReceivedDatetime <= @endDate, 1, NULL)),
				   @samplesRegistered  = COUNT(iif(RegisteredDatetime >= @startDate AND RegisteredDatetime <= @endDate, 1, NULL)),
				   @samplesTested      = COUNT(iif(AnalysisDatetime >= @startDate AND AnalysisDatetime <= @endDate, 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(AuthorisedDatetime >= @startDate AND AuthorisedDatetime <= @endDate, 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') 
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(SpecimenDatetime >= @startDate AND SpecimenDatetime <= @endDate, 1, NULL)),
				   @samplesReceived    = COUNT(iif(ReceivedDatetime >= @startDate AND ReceivedDatetime <= @endDate, 1, NULL)),
				   @samplesRegistered  = COUNT(iif(RegisteredDatetime >= @startDate AND RegisteredDatetime <= @endDate, 1, NULL)),
				   @samplesTested      = COUNT(iif(AnalysisDatetime >= @startDate AND AnalysisDatetime <= @endDate, 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(AuthorisedDatetime >= @startDate AND AuthorisedDatetime <= @endDate, 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') 
			SELECT @name = ''MOZAMBIQUE''
		  END
		ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(SpecimenDatetime >= @startDate AND SpecimenDatetime <= @endDate, 1, NULL)),
				   @samplesReceived    = COUNT(iif(ReceivedDatetime >= @startDate AND ReceivedDatetime <= @endDate, 1, NULL)),
				   @samplesRegistered  = COUNT(iif(RegisteredDatetime >= @startDate AND RegisteredDatetime <= @endDate, 1, NULL)),
				   @samplesTested      = COUNT(iif(AnalysisDatetime >= @startDate AND AnalysisDatetime <= @endDate, 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(AuthorisedDatetime >= @startDate AND AuthorisedDatetime <= @endDate, 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') 
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @samplesCollected, @samplesReceived, @samplesRegistered, @samplesTested, @samplesAuthorized, @total

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getNumberOfSamplesByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getNumberOfSamplesByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getNumberOfSamplesByMonth]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), YEAR int, MONTH VARCHAR(20), COLLECTED int, RECEIVED int, REGISTERED int, TESTED int, AUTHORISED int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @samplesCollected int
	DECLARE @samplesRegistered int
	DECLARE @samplesReceived int
	DECLARE @samplesTested int
	DECLARE @samplesAuthorized int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories))
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(@monthID = MONTH(SpecimenDatetime) AND @year = YEAR(SpecimenDatetime), 1, NULL)),
				   @samplesReceived    = COUNT(iif(@monthID = MONTH(ReceivedDatetime) AND @year = YEAR(ReceivedDatetime), 1, NULL)),
				   @samplesRegistered  = COUNT(iif(@monthID = MONTH(RegisteredDatetime) AND @year = YEAR(RegisteredDatetime), 1, NULL)),
				   @samplesTested      = COUNT(iif(@monthID = MONTH(AnalysisDatetime) AND @year = YEAR(AnalysisDatetime), 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(@monthID = MONTH(AuthorisedDatetime) AND @year = YEAR(AuthorisedDatetime), 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id

			SELECT TOP 1 @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(@monthID = MONTH(SpecimenDatetime) AND @year = YEAR(SpecimenDatetime), 1, NULL)),
				   @samplesReceived    = COUNT(iif(@monthID = MONTH(ReceivedDatetime) AND @year = YEAR(ReceivedDatetime), 1, NULL)),
				   @samplesRegistered  = COUNT(iif(@monthID = MONTH(RegisteredDatetime) AND @year = YEAR(RegisteredDatetime), 1, NULL)),
				   @samplesTested      = COUNT(iif(@monthID = MONTH(AnalysisDatetime) AND @year = YEAR(AnalysisDatetime), 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(@monthID = MONTH(AuthorisedDatetime) AND @year = YEAR(AuthorisedDatetime), 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') 
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(@monthID = MONTH(SpecimenDatetime) AND @year = YEAR(SpecimenDatetime), 1, NULL)),
				   @samplesReceived    = COUNT(iif(@monthID = MONTH(ReceivedDatetime) AND @year = YEAR(ReceivedDatetime), 1, NULL)),
				   @samplesRegistered  = COUNT(iif(@monthID = MONTH(RegisteredDatetime) AND @year = YEAR(RegisteredDatetime), 1, NULL)),
				   @samplesTested      = COUNT(iif(@monthID = MONTH(AnalysisDatetime) AND @year = YEAR(AnalysisDatetime), 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(@monthID = MONTH(AuthorisedDatetime) AND @year = YEAR(AuthorisedDatetime), 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') 
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		ELSE IF (@id = ''MZ'')  -- NATIONAL
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(@monthID = MONTH(SpecimenDatetime) AND @year = YEAR(SpecimenDatetime), 1, NULL)),
				   @samplesReceived    = COUNT(iif(@monthID = MONTH(ReceivedDatetime) AND @year = YEAR(ReceivedDatetime), 1, NULL)),
				   @samplesRegistered  = COUNT(iif(@monthID = MONTH(RegisteredDatetime) AND @year = YEAR(RegisteredDatetime), 1, NULL)),
				   @samplesTested      = COUNT(iif(@monthID = MONTH(AnalysisDatetime) AND @year = YEAR(AnalysisDatetime), 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(@monthID = MONTH(AuthorisedDatetime) AND @year = YEAR(AuthorisedDatetime), 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') 
			SELECT @name = ''MOZAMBIQUE''
		  END
		ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @samplesCollected   = COUNT(iif(@monthID = MONTH(SpecimenDatetime) AND @year = YEAR(SpecimenDatetime), 1, NULL)),
				   @samplesReceived    = COUNT(iif(@monthID = MONTH(ReceivedDatetime) AND @year = YEAR(ReceivedDatetime), 1, NULL)),
				   @samplesRegistered  = COUNT(iif(@monthID = MONTH(RegisteredDatetime) AND @year = YEAR(RegisteredDatetime), 1, NULL)),
				   @samplesTested      = COUNT(iif(@monthID = MONTH(AnalysisDatetime) AND @year = YEAR(AnalysisDatetime), 1, NULL)),
				   @samplesAuthorized  = COUNT(iif(@monthID = MONTH(AuthorisedDatetime) AND @year = YEAR(AuthorisedDatetime), 1, NULL)),
				   @total = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') 
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END


		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, @samplesCollected, @samplesReceived, @samplesRegistered, @samplesTested, @samplesAuthorized
	
		SET @i = @i + 1
	END

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getRequestIDsWithUpdatedDateTimeStamp]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getRequestIDsWithUpdatedDateTimeStamp]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getRequestIDsWithUpdatedDateTimeStamp](@startDate datetime)
RETURNS @requestIDs TABLE (
   RequestID nvarchar(26) PRIMARY KEY CLUSTERED
) 
AS
BEGIN
	INSERT INTO @requestIDS
	SELECT req.RequestId
    FROM OpenLDRData.dbo.Requests req LEFT JOIN OpenLDRData.dbo.LabResults res ON req.RequestID = res.RequestID AND req.OBRSetID = res.OBRSetID
    WHERE (
            (req.LIMSPanelCode = ''VIRAL'')
            OR (req.LIMSPanelCode = ''HIVVL'')
          )
    AND (
		(req.DateTimeStamp > @startDate)
		OR
		(res.DateTimeStamp Is Not Null AND res.DateTimeStamp > @startDate)
		) 
	GROUP BY req.RequestID
 
   RETURN;
END;



' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getResultsMissingByProvince]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getResultsMissingByProvince]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getResultsMissingByProvince] (@startDate Date, @endDate Date)

RETURNS @resultsWaiting TABLE(Name varchar(100),Total int, ARTRegimen float, SpecimenDatetime float, Age float, TreatmentLine float, ReasonForTest float, Gender float, Pregnant float, Breastfeeding float)
AS 
BEGIN
	DECLARE @tableProvinces TABLE(Ord int, Nome varchar(100))
	DECLARE @ord int
	DECLARE @provinceName varchar(100)
	DECLARE @i int
	DECLARE @ARTRegimen float
	DECLARE @SpecimenDate float
	DECLARE @AgeInYears float
	DECLARE @TreatmentLine float
	DECLARE @ReasonForTest float
	DECLARE @Gender float
	DECLARE @Pregnant float
	DECLARE @Breastfeeding float
	DECLARE @Total float

	INSERT INTO @tableProvinces
	SELECT ROW_NUMBER() OVER(ORDER BY vl.RequestingProvinceName), vl.RequestingProvinceName FROM (SELECT DISTINCT(RequestingProvinceName) FROM VlData WHERE RequestingProvinceName IS NOT NULL) AS vl --FROM ViralLoadData.dbo.VlData vl
	SET @i = 1
	WHILE @i < (SELECT COUNT(*)+1 FROM @tableProvinces)
	BEGIN
		SELECT @ord = Ord, @provinceName = Nome FROM @tableProvinces WHERE Ord = @i

		SELECT      @Total         = COUNT(*), 
					@ARTRegimen    = COUNT(iif(ARTRegimen=''Unreported'', 1, NULL)), 
					@SpecimenDate  = COUNT(*) - count(vl.SpecimenDatetime),
				    @AgeInYears    = COUNT(*) - count(vl.AgeInYears), 
					@TreatmentLine = COUNT(iif((PrimeiraLinha=''Unreported'' OR PrimeiraLinha=''Não preenchido'') AND (SegundaLinha=''Unreported'' OR SegundaLinha=''Não preenchido''), 1, NULL)), 
					@ReasonForTest = COUNT(iif(ReasonForTest=''Reason Not Specified'', 1, NULL)),
					@Gender        = COUNT(iif(HL7SexCode IS NULL OR HL7SexCode = '''', 1, NULL))
		FROM VlData vl
		WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingProvinceName = @provinceName

		SELECT      @Pregnant      = COUNT(iif(Pregnant=''Unreported'' OR Pregnant=''Não preenchido'', 1, NULL)),
			        @BreastFeeding = COUNT(iif(Breastfeeding=''Unreported'' OR Breastfeeding=''Não preenchido'', 1, NULL))
		FROM VlData vl
		WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingProvinceName = @provinceName AND
			  vl.HL7SexCode = ''F''

		INSERT INTO @resultsWaiting
		SELECT @provinceName,@Total,@ARTRegimen,@SpecimenDate,@AgeInYears,@TreatmentLine,@ReasonForTest,@Gender,@Pregnant,@Breastfeeding

		INSERT INTO @resultsWaiting
		SELECT CONCAT(@provinceName,'' (%)''),100,
			ROUND((@ARTRegimen/@Total)*100,1),
			ROUND((@SpecimenDate/@Total)*100,1),
			ROUND((@AgeInYears/@Total)*100,1),
			ROUND((@TreatmentLine/@Total)*100,1),
			ROUND((@ReasonForTest/@Total)*100,1),
			ROUND((@Gender/@Total)*100,1),
			ROUND((@Pregnant/@Total)*100,1),
			ROUND((@Breastfeeding/@Total)*100,1)
		SET @i = @i + 1

	END

	--INSERT INTO @resultsWaiting
	--SELECT ''Total'', SUM(Total), SUM(ARTRegimen), SUM(SpecimenDatetime), SUM(Age), SUM(TreatmentLine), SUM(ReasonForTest), SUM(Gender), SUM(Pregnant), SUM(Breastfeeding)
	--FROM @resultsWaiting

	--INSERT INTO @resultsWaiting
	--SELECT ''Total %'', ''100'', 
	--		ROUND((SUM(ARTRegimen)/SUM(Total))*100,1), 
	--		ROUND(SUM(SpecimenDatetime)/SUM(Total))*100,1), 
	--		ROUND(SUM(Age)/SUM(Total))*100,1), 
	--		ROUND(SUM(TreatmentLine)/SUM(Total))*100,1),
	--		ROUND(SUM(ReasonForTest)/SUM(Total))*100,1), 
	--		ROUND(SUM(Gender)/SUM(Total))*100,1), 
	--		ROUND(SUM(Pregnant)/SUM(Total))*100,1), 
	--		ROUND(SUM(Breastfeeding)/SUM(Total))*100,1)
	--FROM @resultsWaiting

	RETURN 
END




' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getResultsMissingForAllDistricts]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getResultsMissingForAllDistricts]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getResultsMissingForAllDistricts] (@startDate Date, @endDate Date)

RETURNS @resultsWaiting TABLE(Ord int, Name varchar(100),Total int, ARTRegimen float, SpecimenDatetime float, Age float, TreatmentLine float, ReasonForTest float, Gender float, Pregnant float, Breastfeeding float)
AS 
BEGIN
	DECLARE @tableProvinces TABLE(Ord int, Nome varchar(100))
	DECLARE @tableDistricts TABLE(Ord int, Nome varchar(100))
	DECLARE @ord int
	DECLARE @provinceName varchar(100)
	DECLARE @districtName varchar(100)
	DECLARE @i int
	DECLARE @j int
	DECLARE @ARTRegimen float
	DECLARE @SpecimenDate float
	DECLARE @AgeInYears float
	DECLARE @TreatmentLine float
	DECLARE @ReasonForTest float
	DECLARE @Gender float
	DECLARE @Pregnant float
	DECLARE @Breastfeeding float
	DECLARE @Total float

	INSERT INTO @tableProvinces
	SELECT ROW_NUMBER() OVER(ORDER BY vl.RequestingProvinceName), vl.RequestingProvinceName FROM (SELECT DISTINCT(RequestingProvinceName) FROM VlData WHERE RequestingProvinceName IS NOT NULL) AS vl --FROM ViralLoadData.dbo.VlData vl
	SET @i = 1
	WHILE @i < (SELECT COUNT(*)+1 FROM @tableProvinces)
	BEGIN
		SELECT @ord = Ord, @provinceName = Nome FROM @tableProvinces WHERE Ord = @i

		SELECT      @Total         = COUNT(*), 
					@ARTRegimen    = COUNT(iif(ARTRegimen=''Unreported'', 1, NULL)), 
					@SpecimenDate  = COUNT(*) - count(vl.SpecimenDatetime),
				    @AgeInYears    = COUNT(*) - count(vl.AgeInYears), 
					@TreatmentLine = COUNT(iif((PrimeiraLinha=''Unreported'' OR PrimeiraLinha=''Não preenchido'') AND (SegundaLinha=''Unreported'' OR SegundaLinha=''Não preenchido''), 1, NULL)), 
					@ReasonForTest = COUNT(iif(ReasonForTest=''Reason Not Specified'', 1, NULL)),
					@Gender        = COUNT(iif(HL7SexCode IS NULL OR HL7SexCode = '''', 1, NULL))
		FROM VlData vl
		WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingProvinceName = @provinceName

		SELECT      @Pregnant      = COUNT(iif(Pregnant=''Unreported'' OR Pregnant=''Não preenchido'', 1, NULL)),
			        @BreastFeeding = COUNT(iif(Breastfeeding=''Unreported'' OR Breastfeeding=''Não preenchido'', 1, NULL))
		FROM VlData vl
		WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingProvinceName = @provinceName AND
			  vl.HL7SexCode = ''F''

		INSERT INTO @resultsWaiting
		SELECT NULL, @provinceName,@Total,@ARTRegimen,@SpecimenDate,@AgeInYears,@TreatmentLine,@ReasonForTest,@Gender,@Pregnant,@Breastfeeding

		INSERT INTO @resultsWaiting
		SELECT NULL,
			CONCAT(@provinceName,'' (%)''),100,
			ROUND((@ARTRegimen/@Total)*100,1),
			ROUND((@SpecimenDate/@Total)*100,1),
			ROUND((@AgeInYears/@Total)*100,1),
			ROUND((@TreatmentLine/@Total)*100,1),
			ROUND((@ReasonForTest/@Total)*100,1),
			ROUND((@Gender/@Total)*100,1),
			ROUND((@Pregnant/@Total)*100,1),
			ROUND((@Breastfeeding/@Total)*100,1)
		SET @i = @i + 1

		DELETE FROM @tableDistricts
		INSERT INTO @tableDistricts
		SELECT ROW_NUMBER() OVER(ORDER BY vl.RequestingDistrictName), vl.RequestingDistrictName FROM (SELECT DISTINCT(RequestingDistrictName) FROM VlData WHERE RequestingProvinceName = @provinceName AND RequestingProvinceName IS NOT NULL AND RequestingDistrictName IS NOT NULL) AS vl 
		SET @j = 1
		WHILE @j < (SELECT COUNT(*) + 1 FROM @tableDistricts)
		BEGIN
			SELECT @ord = Ord, @districtName=Nome FROM @tableDistricts WHERE Ord = @j

			SELECT      @Total         = COUNT(*), 
						@ARTRegimen    = COUNT(iif(ARTRegimen=''Unreported'', 1, NULL)), 
						@SpecimenDate  = COUNT(*) - count(vl.SpecimenDatetime),
						@AgeInYears    = COUNT(*) - count(vl.AgeInYears), 
						@TreatmentLine = COUNT(iif((PrimeiraLinha=''Unreported'' OR PrimeiraLinha=''Não preenchido'') AND (SegundaLinha=''Unreported'' OR SegundaLinha=''Não preenchido''), 1, NULL)), 
						@ReasonForTest = COUNT(iif(ReasonForTest=''Reason Not Specified'', 1, NULL)),
						@Gender        = COUNT(iif(HL7SexCode IS NULL OR HL7SexCode = '''', 1, NULL))
			FROM VlData vl
			WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingDistrictName = @districtName

			SELECT      @Pregnant      = COUNT(iif(Pregnant=''Unreported'' OR Pregnant=''Não preenchido'', 1, NULL)),
						@BreastFeeding = COUNT(iif(Breastfeeding=''Unreported'' OR Breastfeeding=''Não preenchido'', 1, NULL))
			FROM VlData vl
			WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingDistrictName = @districtName AND
				  vl.HL7SexCode = ''F''

			INSERT INTO @resultsWaiting
			SELECT @ord, @districtName,@Total,@ARTRegimen,@SpecimenDate,@AgeInYears,@TreatmentLine,@ReasonForTest,@Gender,@Pregnant,@Breastfeeding

			SET @j = @j + 1
		END
	END

	RETURN 
END




' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getResultsPedsByProvince]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getResultsPedsByProvince]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getResultsPedsByProvince] (@startDate Date, @endDate Date)

RETURNS @resultsWaiting TABLE(Province varchar(100),Total int, Peds_Suppressed int, Peds_Suppressed_percentage float, Peds_NotSuppressed int, Peds_NotSuppressed_percentage float)
AS 
BEGIN
	DECLARE @tableProvinces TABLE(Ord int, Nome varchar(100))
	DECLARE @ord int
	DECLARE @provinceName varchar(100)
	DECLARE @i int
	DECLARE @peds int
	DECLARE @pedsSuppressed int
	DECLARE @pedsNotSuppressed int
	DECLARE @pedsSuppressedPercentage float
	DECLARE @pedsNotSuppressedPercentage float
	DECLARE @Total float

	INSERT INTO @tableProvinces
	SELECT ROW_NUMBER() OVER(ORDER BY vl.RequestingProvinceName), vl.RequestingProvinceName FROM (SELECT DISTINCT(RequestingProvinceName) FROM VlData WHERE RequestingProvinceName IS NOT NULL) AS vl --FROM ViralLoadData.dbo.VlData vl
	SET @i = 1
	WHILE @i < (SELECT COUNT(*)+1 FROM @tableProvinces)
	BEGIN
		SELECT @ord = Ord, @provinceName = Nome FROM @tableProvinces WHERE Ord = @i

		SELECT      
					@pedsSuppressed	   = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
					@pedsNotSuppressed = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
					@Total         = COUNT(*)
		FROM VlData vl
		WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingProvinceName = @provinceName AND
			  ViralLoadResultCategory IS NOT NULL AND vl.AgeInYears >= 0 AND vl.AgeInYears <= 14
		
		SET @pedsSuppressedPercentage    = ROUND((@pedsSuppressed/@Total) * 100, 1)
		SET @pedsNotSuppressedPercentage = ROUND((@pedsNotSuppressed/@Total) * 100, 1)

		INSERT INTO @resultsWaiting
		SELECT @provinceName, @Total, @pedsSuppressed, @pedsSuppressedPercentage, @pedsNotSuppressed, @pedsNotSuppressedPercentage

		SET @i = @i + 1

	END

	RETURN 
END



' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getResultsPregnantAndBreastfeedingByProvince]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getResultsPregnantAndBreastfeedingByProvince]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getResultsPregnantAndBreastfeedingByProvince] (@startDate Date, @endDate Date)

RETURNS @resultsWaiting TABLE(Name varchar(100),Total int, Pregnant float, PregnantSupressed float, PregnantNotSupressed float, Breastfeeding float, BreastfeedingSupressed float, BreastfeedingNotSupressed float)
AS 
BEGIN
	DECLARE @tableProvinces TABLE(Ord int, Nome varchar(100))
	DECLARE @ord int
	DECLARE @provinceName varchar(100)
	DECLARE @i int
	DECLARE @Pregnant float
	DECLARE @Breastfeeding float
	DECLARE @PregnantSuppressed float
	DECLARE @BreastFeedingSuppressed float
	DECLARE @PregnantNonSuppressed float
	DECLARE @BreastFeedingNonSuppressed float
	DECLARE @Total float

	INSERT INTO @tableProvinces
	SELECT ROW_NUMBER() OVER(ORDER BY vl.RequestingProvinceName), vl.RequestingProvinceName FROM (SELECT DISTINCT(RequestingProvinceName) FROM VlData WHERE RequestingProvinceName IS NOT NULL) AS vl --FROM ViralLoadData.dbo.VlData vl
	SET @i = 1
	WHILE @i < (SELECT COUNT(*)+1 FROM @tableProvinces)
	BEGIN
		SELECT @ord = Ord, @provinceName = Nome FROM @tableProvinces WHERE Ord = @i

		SELECT      @Pregnant      = COUNT(iif(Pregnant=''Yes'', 1, NULL)),
			        @BreastFeeding = COUNT(iif(Breastfeeding=''Yes'', 1, NULL)),
					@PregnantSuppressed = COUNT(iif(Pregnant=''Yes'' AND ViralLoadResultCategory =''Suppressed'', 1, NULL)),
					@BreastFeedingSuppressed = COUNT(iif(Breastfeeding=''Yes'' AND ViralLoadResultCategory =''Suppressed'', 1, NULL)),
					@PregnantNonSuppressed = COUNT(iif(Pregnant=''Yes'' AND ViralLoadResultCategory =''Not Suppressed'', 1, NULL)),
					@BreastFeedingNonSuppressed = COUNT(iif(Breastfeeding=''Yes'' AND ViralLoadResultCategory =''Not Suppressed'', 1, NULL)),
					@Total         = COUNT(*)
		FROM VlData vl
		WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingProvinceName = @provinceName AND
			  vl.HL7SexCode = ''F'' AND ViralLoadResultCategory IS NOT NULL

		INSERT INTO @resultsWaiting
		SELECT @provinceName, @Total, @Pregnant, @PregnantSuppressed, @PregnantNonSuppressed, @Breastfeeding, @BreastFeedingSuppressed, @BreastFeedingNonSuppressed

		INSERT INTO @resultsWaiting
		SELECT CONCAT(@provinceName,'' (%)''),100,
			ROUND((@Pregnant/@Total)*100,1),
			ROUND((@PregnantSuppressed/@Pregnant)*100,1),
			ROUND((@PregnantNonSuppressed/@Pregnant)*100,1),
			ROUND((@Breastfeeding/@Total)*100,1),
			ROUND((@BreastFeedingSuppressed/@Breastfeeding)*100,1),
			ROUND((@BreastFeedingNonSuppressed/@Breastfeeding)*100,1)
		SET @i = @i + 1

	END

	RETURN 
END




' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getResultsPregnantAndBreastfeedingForAllDistricts]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getResultsPregnantAndBreastfeedingForAllDistricts]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getResultsPregnantAndBreastfeedingForAllDistricts] (@startDate Date, @endDate Date)

RETURNS @resultsWaiting TABLE(Name varchar(100),Total int, Pregnant float, PregnantSupressed float, PregnantNotSupressed float, Breastfeeding float, BreastfeedingSupressed float, BreastfeedingNotSupressed float)
AS 
BEGIN
	DECLARE @tableProvinces TABLE(Ord int, Nome varchar(100))
	DECLARE @tableDistricts TABLE(Ord int, Nome varchar(100))
	DECLARE @ord int
	DECLARE @provinceName varchar(100)
	DECLARE @districtName varchar(100)
	DECLARE @i int
	DECLARE @j int
	DECLARE @Pregnant float
	DECLARE @Breastfeeding float
	DECLARE @PregnantSuppressed float
	DECLARE @BreastFeedingSuppressed float
	DECLARE @PregnantNonSuppressed float
	DECLARE @BreastFeedingNonSuppressed float
	DECLARE @Total float

	INSERT INTO @tableProvinces
	SELECT ROW_NUMBER() OVER(ORDER BY vl.RequestingProvinceName), vl.RequestingProvinceName FROM (SELECT DISTINCT(RequestingProvinceName) FROM VlData WHERE RequestingProvinceName IS NOT NULL) AS vl --FROM ViralLoadData.dbo.VlData vl
	SET @i = 1
	WHILE @i < (SELECT COUNT(*)+1 FROM @tableProvinces)
	BEGIN
		SELECT @ord = Ord, @provinceName = Nome FROM @tableProvinces WHERE Ord = @i

		SELECT      @Pregnant       = COUNT(iif(Pregnant=''Yes'', 1, NULL)),
			        @BreastFeeding = COUNT(iif(Breastfeeding=''Yes'', 1, NULL)),
					@PregnantSuppressed = COUNT(iif(Pregnant=''Yes'' AND ViralLoadResultCategory =''Suppressed'', 1, NULL)),
					@BreastFeedingSuppressed = COUNT(iif(Breastfeeding=''Yes'' AND ViralLoadResultCategory =''Suppressed'', 1, NULL)),
					@PregnantNonSuppressed = COUNT(iif(Pregnant=''Yes'' AND ViralLoadResultCategory =''Not Suppressed'', 1, NULL)),
					@BreastFeedingNonSuppressed = COUNT(iif(Breastfeeding=''Yes'' AND ViralLoadResultCategory =''Not Suppressed'', 1, NULL)),
					@Total         = COUNT(*)
		FROM VlData vl
		WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingProvinceName = @provinceName AND
			  vl.HL7SexCode = ''F'' AND ViralLoadResultCategory IS NOT NULL

		INSERT INTO @resultsWaiting
		SELECT @provinceName, @Total, @Pregnant, @PregnantSuppressed, @PregnantNonSuppressed, @Breastfeeding, @BreastFeedingSuppressed, @BreastFeedingNonSuppressed

		INSERT INTO @resultsWaiting
		SELECT CONCAT(@provinceName,'' (%)''),100,
			ROUND((@Pregnant/@Total)*100,1),
			ROUND((@PregnantSuppressed/@Pregnant)*100,1),
			ROUND((@PregnantNonSuppressed/@Pregnant)*100,1),
			ROUND((@Breastfeeding/@Total)*100,1),
			ROUND((@BreastFeedingSuppressed/@Breastfeeding)*100,1),
			ROUND((@BreastFeedingNonSuppressed/@Breastfeeding)*100,1)
		SET @i = @i + 1

		DELETE FROM @tableDistricts
		INSERT INTO @tableDistricts
		SELECT ROW_NUMBER() OVER(ORDER BY vl.RequestingDistrictName), vl.RequestingDistrictName FROM (SELECT DISTINCT(RequestingDistrictName) FROM VlData WHERE RequestingProvinceName = @provinceName AND RequestingProvinceName IS NOT NULL AND RequestingDistrictName IS NOT NULL) AS vl 
		SET @j = 1
		WHILE @j < (SELECT COUNT(*) + 1 FROM @tableDistricts)
		BEGIN
			SELECT @ord = Ord, @districtName=Nome FROM @tableDistricts WHERE Ord = @j

			SELECT  @Pregnant       = COUNT(iif(Pregnant=''Yes'', 1, NULL)),
			        @BreastFeeding = COUNT(iif(Breastfeeding=''Yes'', 1, NULL)),
					@PregnantSuppressed = COUNT(iif(Pregnant=''Yes'' AND ViralLoadResultCategory =''Suppressed'', 1, NULL)),
					@BreastFeedingSuppressed = COUNT(iif(Breastfeeding=''Yes'' AND ViralLoadResultCategory =''Suppressed'', 1, NULL)),
					@PregnantNonSuppressed = COUNT(iif(Pregnant=''Yes'' AND ViralLoadResultCategory =''Not Suppressed'', 1, NULL)),
					@BreastFeedingNonSuppressed = COUNT(iif(Breastfeeding=''Yes'' AND ViralLoadResultCategory =''Not Suppressed'', 1, NULL)),
					@Total         = COUNT(*)
			FROM VlData vl
			WHERE vl.RegisteredDateTime >= @startDate AND vl.RegisteredDateTime <= @endDate AND vl.RequestingDistrictName = @districtName AND
				  vl.HL7SexCode = ''F'' AND ViralLoadResultCategory IS NOT NULL

			INSERT INTO @resultsWaiting
			SELECT @districtName, @Total, @Pregnant, @PregnantSuppressed, @PregnantNonSuppressed, @Breastfeeding, @BreastFeedingSuppressed, @BreastFeedingNonSuppressed

			SET @j = @j + 1
		END

	END

	RETURN 
END




' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTotalRejectedSamplesForAllDistrictsByProvince]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTotalRejectedSamplesForAllDistrictsByProvince]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTotalRejectedSamplesForAllDistrictsByProvince]
(
	-- Add the parameters for the function here
	@provinceID varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @rejectedSamplesTable TABLE(ProvinceCode varchar(10), ProvinceName varchar(100), DistrictName varchar(100), SamplesRejected int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @samplesRejected int
	DECLARE @numberSamples int
	DECLARE @provinceName varchar(100)
	DECLARE @districtName varchar(100)
	DECLARE @districtCode varchar(20)


	SELECT @provinceName = RequestingProvinceName
	FROM VlData WHERE HealthCareID LIKE CONCAT(@provinceID, ''%'')

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*)+1 FROM OpenLDRDict.dbo.HealthcareAreas AS dict WHERE dict.HealthcareAreaCode LIKE CONCAT(@provinceID,''%'') AND len(dict.HealthcareAreaCode)=8 AND dict.HealthcareAreaCode IS NOT NULL)
	BEGIN
		SELECT @districtcode = tbl_dict.HealthcareAreaCode, @districtName = tbl_dict.HealthcareAreaDesc
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER BY HealthcareAreaDesc) AS ron_num, HealthcareAreaCode, HealthcareAreaDesc FROM OpenLDRDict.dbo.HealthcareAreas WHERE HealthcareAreaCode LIKE CONCAT(@provinceID,''%'') AND HealthcareAreaCode IS NOT NULL AND LEN(HealthcareAreaCode) >= 8
		) AS tbl_dict
		WHERE tbl_dict.ron_num = @i

		SELECT @samplesRejected = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND HealthCareID LIKE @districtCode
			   AND ((HIVVL_LIMSRejectionCode IS NOT NULL AND HIVVL_LIMSRejectionCode <> '''') OR (HIVVL_LIMSRejectionDesc IS NOT NULL AND HIVVL_LIMSRejectionDesc <> ''''))

		SELECT @numberSamples  = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND HealthCareID LIKE @districtCode
	
		INSERT INTO @rejectedSamplesTable
		SELECT @provinceID, @provinceName, @districtName, @samplesRejected, @numberSamples

		SET @i = @i + 1;
	END

	RETURN
END	






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTotalRejectedSamplesForAllLabs]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTotalRejectedSamplesForAllLabs]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTotalRejectedSamplesForAllLabs]
(
	-- Add the parameters for the function here
	@start_date varchar(20), @end_date varchar(20)
)
RETURNS @rejectedSamplesTable TABLE(LabCode varchar(10), LabName varchar(100), TotalRejected int, Total int)
AS
BEGIN

	DECLARE @i int
	DECLARE @labcode varchar(20)
	DECLARE @labname varchar(100)
	DECLARE @samplesRejected int
	DECLARE @total int

	SET @i = 0

	WHILE @i < (SELECT COUNT(1)+1 FROM VlLabs)
	BEGIN
		SELECT @labcode = tbl_labs.LabID, @labname = tbl_labs.Lab
		FROM (SELECT ROW_NUMBER() OVER(ORDER BY tbl.LabID) AS row_numb, tbl.LabID, tbl.Lab FROM VlLabs AS tbl) AS tbl_labs
		WHERE tbl_labs.row_numb = @i

		SELECT 
			@samplesRejected = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND RequestID LIKE CONCAT(''%'',@labcode,''%'') 
			  AND ((HIVVL_LIMSRejectionCode IS NOT NULL AND HIVVL_LIMSRejectionCode <> '''') OR (HIVVL_LIMSRejectionDesc IS NOT NULL AND HIVVL_LIMSRejectionDesc <> '''')) 

		SELECT 
			@total = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND RequestID LIKE CONCAT(''%'',@labcode,''%'') 

		INSERT INTO @rejectedSamplesTable
		SELECT @labcode, @labname, @samplesRejected, @total WHERE @labcode IS NOT NULL AND @labname IS NOT NULL

		SET @i = @i + 1
	END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTotalRejectedSamplesForAllLabsOrderByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTotalRejectedSamplesForAllLabsOrderByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTotalRejectedSamplesForAllLabsOrderByMonth]
(
	-- Add the parameters for the function here
	@lab varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @rejectedSamplesTable TABLE(LabCode varchar(10), Months varchar(100), Years int, SamplesRejected int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @samplesRejected int
	DECLARE @numberSamples int

	INSERT INTO @table_months VALUES(1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
								  (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
								  (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
								  (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id
	--SELECT * FROM @tableDates 
	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT @samplesRejected = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(RegisteredDateTime) and @year = YEAR(RegisteredDateTime)) AND RequestID LIKE CONCAT(''%'',@lab,''%'')
			   AND ((HIVVL_LIMSRejectionCode IS NOT NULL AND HIVVL_LIMSRejectionCode <> '''') OR (HIVVL_LIMSRejectionDesc IS NOT NULL AND HIVVL_LIMSRejectionDesc <> ''''))

		SELECT @numberSamples  = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(RegisteredDateTime) and @year = YEAR(RegisteredDateTime)) AND RequestID LIKE CONCAT(''%'',@lab,''%'')

	
		INSERT INTO @rejectedSamplesTable
		SELECT @lab, @monthPT, @year, @samplesRejected, @numberSamples

		SET @i = @i + 1;
	END

	RETURN
END	







' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTotalRejectedSamplesForProvinceByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTotalRejectedSamplesForProvinceByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTotalRejectedSamplesForProvinceByMonth]
(
	-- Add the parameters for the function here
	@provinceID varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @rejectedSamplesTable TABLE(ProvinceCode varchar(10), ProvinceName varchar(100), Months varchar(100), Years int, SamplesRejected int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @samplesRejected int
	DECLARE @numberSamples int
	DECLARE @provinceName varchar(100)

	INSERT INTO @table_months VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
								     (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
								     (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
								     (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id
	--SELECT * FROM @tableDates 
	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT @samplesRejected = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND HealthCareID LIKE CONCAT(@provinceID,''%'')  -- RequestID LIKE CONCAT(''%'',@labID,''%'')
			   AND ((HIVVL_LIMSRejectionCode IS NOT NULL AND HIVVL_LIMSRejectionCode <> '''') OR (HIVVL_LIMSRejectionDesc IS NOT NULL AND HIVVL_LIMSRejectionDesc <> ''''))

		SELECT @numberSamples  = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND HealthCareID LIKE CONCAT(@provinceID,''%'') -- AND RequestID LIKE CONCAT(''%'',@labID,''%'')

		SELECT @provinceName = RequestingProvinceName
		FROM VlData WHERE HealthCareID LIKE CONCAT(@provinceID, ''%'')
	
		INSERT INTO @rejectedSamplesTable
		SELECT @provinceID, @provinceName, @monthPT, @year, @samplesRejected, @numberSamples

		SET @i = @i + 1;
	END

	RETURN
END	






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTotalTestedSamplesForAllLabsOrderByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTotalTestedSamplesForAllLabsOrderByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTotalTestedSamplesForAllLabsOrderByMonth]
(
	-- Add the parameters for the function here
	@labID varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @rejectedSamplesTable TABLE(LabName varchar(100), X_Months varchar(100), Years int, Y_PregnantTested int, PedsTested int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @pregnantTested int
	DECLARE @peds int
	DECLARE @numberSamples int
	DECLARE @labName varchar(50)

	INSERT INTO @table_months VALUES(1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
								  (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
								  (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
								  (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	SELECT @labName = Lab FROM ViralLoadData.dbo.VlLabs WHERE LabID = @labID

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT @pregnantTested = COUNT(iif(Pregnant LIKE ''Yes'',1, NULL)),
			   @peds = COUNT(iif(AgeInYears <= 12, 1, NULL))
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND RequestID LIKE CONCAT(''%'',@labID,''%'')
			   AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory <> '''' 

		SELECT @numberSamples  = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND RequestID LIKE CONCAT(''%'',@labID,''%'')
		AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory <> '''' 
	
		INSERT INTO @rejectedSamplesTable
		SELECT @labName, @monthPT, @year, @pregnantTested, @peds, @numberSamples

		SET @i = @i + 1;
	END

	RETURN
END	






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTotalTestedSamplesForAllProvincesOrderByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTotalTestedSamplesForAllProvincesOrderByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTotalTestedSamplesForAllProvincesOrderByMonth]
(
	-- Add the parameters for the function here
	@provinceID varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @rejectedSamplesTable TABLE(LabCode varchar(10), X_Months varchar(100), Years int, Y_PregnantTested int, PedsTested int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @pregnantTested int
	DECLARE @peds int
	DECLARE @numberSamples int

	INSERT INTO @table_months VALUES(1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
								  (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
								  (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
								  (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT @pregnantTested = COUNT(iif(Pregnant LIKE ''Yes'',1, NULL)),
			   @peds = COUNT(iif(AgeInYears <= 12, 1, NULL))
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND HealthCareID LIKE CONCAT(@provinceID,''%'')
			   AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory <> '''' 

		SELECT @numberSamples  = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND HealthCareID LIKE CONCAT(@provinceID,''%'')
		AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory <> '''' 
	
		INSERT INTO @rejectedSamplesTable
		SELECT @provinceID, @monthPT, @year, @pregnantTested, @peds, @numberSamples

		SET @i = @i + 1;
	END

	RETURN
END	






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTurnaroundTime]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTurnaroundTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTurnaroundTime]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(100), NAME VARCHAR(200), COLLECTION_TO_RECEIVE int, RECEIVE_TO_REGISTER int, REGISTER_TO_ANALYSIS int, ANALYSIS_TO_AUTHORISE int, TOTAL int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))

	SET @startDate = CONCAT(@startDate, '' 00:00'')
	SET @endDate   = CONCAT(@endDate, '' 23:59:59'')

	INSERT INTO @healthcareareas 
	VALUES(''MZ'',''Mozambique''),(''MZ01'',''Niassa''),(''MZ02'',''Cabo Delgado''),
		  (''MZ03'', ''Nampula''),(''MZ04'',''Zambezia''),(''MZ05'',''Tete''),(''MZ06'',''Manica''),
		  (''MZ07'',''Sofala''),(''MZ08'',''Inhambane''),(''MZ09'',''Gaza''),
		  (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories))
	  BEGIN
		SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
				@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
				@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
				@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
				@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
				@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE (FullFacilityCode LIKE @id OR RequestingFacilityCode LIKE @id) AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL -- AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 90
		SELECT TOP 1 @name = ClinicName FROM ViralLoadData.dbo.viewHealthCareSites WHERE ClinicCode LIKE @id OR OldFacilityCode LIKE @id
	  END
	ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
	  BEGIN
		SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
				@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
				@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
				@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
				@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
				@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL --AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 90
		SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
	  END
	ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
	  BEGIN
		SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
				@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
				@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
				@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
				@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
				@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL --AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 90
		SELECT @name = Name FROM @healthcareareas WHERE Code = @id
	  END
	ELSE IF (@id = ''MZ'')  -- NATIONAL
	  BEGIN
		SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
				@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
				@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
				@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
				@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
				@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL --AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 90
		SELECT @name = ''MOZAMBIQUE''
	  END
	ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
	  BEGIN
		SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
				@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
				@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
				@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
				@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
				@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL --AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 90
		SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
	  END

	 INSERT INTO @table
	 SELECT @id, @name, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTurnaroundTimeByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTurnaroundTimeByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTurnaroundTimeByMonth]
(
	-- Add the parameters for the function here
	@id varchar(50), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(50), NAME VARCHAR(200), YEAR int, MONTH VARCHAR(20), COLLECTION_TO_RECEIVE int, RECEIVE_TO_REGISTER int, REGISTER_TO_ANALYSIS int, ANALYSIS_TO_AUTHORISE int, TOTAL int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int
	DECLARE @healthcareareas TABLE(Code varchar(50), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories))
		  BEGIN
			SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
					@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
					@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
					@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
					@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
					@numberSamples			 = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL -- AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 300
			SELECT TOP 1 @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
					@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
					@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
					@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
					@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
					@numberSamples			 = COUNT(1)
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'',@id,''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL -- AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 300
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode LIKE @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
					@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
					@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
					@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
					@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
					@numberSamples			 = COUNT(1)
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL -- AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 300
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
					@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
					@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
					@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
					@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
					@numberSamples			 = COUNT(1)
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL -- AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 300
			SELECT @name = ''MOZAMBIQUE''
		  END
		ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
					@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
					@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
					@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
					@specimen_authorisedate  = AVG(DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime)),
					@numberSamples			 = COUNT(1)
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL -- AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 300
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples
	
		SET @i = @i + 1
	END

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTurnaroundTimeByMonthInterval]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTurnaroundTimeByMonthInterval]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTurnaroundTimeByMonthInterval]
(
	-- Add the parameters for the function here
	@id varchar(50), @startDate varchar(20), @endDate varchar(20), @interval int
)
RETURNS @table TABLE ( ID VARCHAR(50), NAME VARCHAR(200), YEAR int, MONTH VARCHAR(20), COLLECTION_TO_RECEIVE int, RECEIVE_TO_REGISTER int, REGISTER_TO_ANALYSIS int, ANALYSIS_TO_AUTHORISE int, TOTAL int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int
	DECLARE @healthcareareas TABLE(Code varchar(50), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF (SELECT LEN(@id)) <= 5 AND (SELECT COUNT(RequestingFacilityCode) FROM VlData WHERE RequestingFacilityCode LIKE CONCAT(''%'',@id,''%'')) > 0 AND (SELECT COUNT(1) FROM VlLabs WHERE LabID = @id) = 0 AND (SELECT COUNT(Code) FROM @healthcareareas WHERE Code = @id) = 0
		  BEGIN
			SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
					@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
					@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
					@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
					@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
					@numberSamples			 = COUNT(1)
			FROM VlData
			WHERE RequestingFacilityCode LIKE CONCAT(''%'',@id,''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= @interval
			SELECT @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE CONCAT(''%'',@id,''%'')
		  END
		ELSE IF (SELECT LEFT(@id, 1)) = ''P'' AND  (SELECT COUNT(1) FROM VlLabs WHERE LabID = @id) > 0
		  BEGIN
			SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
					@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
					@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
					@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
					@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
					@numberSamples			 = COUNT(1)
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= @interval
			SELECT @name = Lab FROM VlLabs WHERE LabID = @id
		  END
		ELSE 
		  BEGIN
			SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
					@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
					@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
					@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
					@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
					@numberSamples			 = COUNT(1)
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= @interval
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples
	
		SET @i = @i + 1
	END

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getTurnaroundTimeInterval]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getTurnaroundTimeInterval]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getTurnaroundTimeInterval]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20), @interval int
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), COLLECTION_TO_RECEIVE int, RECEIVE_TO_REGISTER int, REGISTER_TO_ANALYSIS int, ANALYSIS_TO_AUTHORISE int, TOTAL int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))

	SET @startDate = CONCAT(@startDate, '' 00:00'')
	SET @endDate   = CONCAT(@endDate, '' 23:59:59'')

	INSERT INTO @healthcareareas 
	VALUES(''MZ'',''Mozambique''),(''MZ01'',''Niassa''),(''MZ02'',''Cabo Delgado''),
		  (''MZ03'', ''Nampula''),(''MZ04'',''Zambezia''),(''MZ05'',''Tete''),(''MZ06'',''Manica''),
		  (''MZ07'',''Sofala''),(''MZ08'',''Inhambane''),(''MZ09'',''Gaza''),
		  (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	IF (SELECT LEN(@id)) <= 5 AND (SELECT COUNT(RequestingFacilityCode) FROM VlData WHERE RequestingFacilityCode = @id) > 0 AND (SELECT COUNT(1) FROM VlLabs WHERE LabID = @id) = 0
	  BEGIN
		SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
				@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
				@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
				@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
				@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
				@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE RequestingFacilityCode LIKE @id AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= @interval
		SELECT @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode = @id
	  END
	ELSE IF (SELECT LEFT(@id, 1)) = ''P'' AND  (SELECT COUNT(1) FROM VlLabs WHERE LabID = @id) > 0
	  BEGIN
		SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
				@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
				@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
				@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
				@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
				@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= @interval
		SELECT @name = Lab FROM VlLabs WHERE LabID = @id
	  END
	ELSE 
	  BEGIN
		SELECT  @specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
				@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
				@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
				@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
				@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
				@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= @interval
		SELECT @name = Name FROM @healthcareareas WHERE Code = @id
	  END

	 INSERT INTO @table
	 SELECT @id, @name, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples 

	RETURN

END







' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralLoadResultsByAgeAndGenderForAllDistricts]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralLoadResultsByAgeAndGenderForAllDistricts]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getViralLoadResultsByAgeAndGenderForAllDistricts] (@provinceID varchar(10), @startDate Date, @endDate Date, @age1 int, @age2 int, @gender varchar(2))

RETURNS @resultsTable TABLE(
							ORD int, PROVINCE varchar(100),DISTRICT varchar(100),
							ROUTINE_SUPPRESSION int, ROUTINE_TOTAL int, STF_SUPPRESSION int, STF_TOTAL int, RNS_SUPPRESSION int, RNS_TOTAL int, SUPPRESSION int, TOTAL int
						)
AS 
BEGIN

	DECLARE @provinceName varchar(100)
	DECLARE @districtID varchar(20)
	DECLARE @districtName varchar(100)
	DECLARE @healthCenterID varchar(20)
	DECLARE @healthCenter varchar(100)
	DECLARE @districtTable TABLE(ORD int, DISTRICT_ID varchar(20), PROVINCE_NAME varchar(100), DISTRICT_NAME varchar(100))
	DECLARE @healthCenterTable TABLE(ORD int, CLINIC_ID varchar(20), CLINIC_NAME varchar(100))
	DECLARE @i int
	DECLARE @j int
	DECLARE @x int 

	DECLARE @rot_sup int
	DECLARE @rot_total int
	DECLARE @stf_sup int
	DECLARE @stf_total int
	DECLARE @rns_sup int
	DECLARE @rns_total int
	DECLARE @sup int
	DECLARE @total int

	INSERT INTO @districtTable 
	SELECT ROW_NUMBER() OVER(ORDER BY district.HealthCareID), district.HealthCareID, district.RequestingProvinceName, district.RequestingDistrictName FROM (SELECT DISTINCT(HealthCareID), RequestingProvinceName, RequestingDistrictName FROM VlData WHERE HealthCareID LIKE CONCAT(@provinceID,''%'') AND RequestingDistrictName IS NOT NULL AND HealthCareID IS NOT NULL) AS district
	SET @i = 1
	SET @x = 1
	WHILE @i < (SELECT COUNT(1) FROM @districtTable)
	BEGIN
		SELECT @districtID   = (SELECT DISTRICT_ID   FROM @districtTable WHERE ORD = @i)
		SELECT @districtName = (SELECT DISTRICT_NAME FROM @districtTable WHERE ORD = @i)
		SELECT @provinceName = (SELECT PROVINCE_NAME FROM @districtTable WHERE ORD = @i)

		SELECT @rot_sup    = COUNT(iif(ReasonForTest = ''Routine'', iif(ViralLoadResultCategory = ''Suppressed'',1, NULL), NULL)),
			   @rot_total  = COUNT(iif(ReasonForTest = ''Routine'', 1, NULL)),
			   @stf_sup    = COUNT(iif(ReasonForTest = ''Suspected treatment failure'', iif(ViralLoadResultCategory = ''Suppressed'',1, NULL), NULL)),
			   @stf_total  = COUNT(iif(ReasonForTest = ''Suspected treatment failure'', 1, NULL)),
			   @rns_sup    = COUNT(iif(ReasonForTest = ''Reason Not Specified'', iif(ViralLoadResultCategory = ''Suppressed'',1, NULL), NULL)),
			   @rns_total  = COUNT(iif(ReasonForTest = ''Reason Not Specified'', 1, NULL)),
			   @sup        = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
			   @total      = @rot_total + @stf_total +@rns_total
		FROM   VlData
		WHERE  HealthCareID = @districtID AND RequestingDistrictName IS NOT NULL AND HealthCareID IS NOT NULL AND 
			   (AgeInYears >= @age1 AND AgeInYears <= @age2) AND HL7SexCode = @gender AND (AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate)

		INSERT INTO @resultsTable
		SELECT @x, @provinceName, @districtName, @rot_sup, @rot_total, @stf_sup, @stf_total, @rns_sup, @rns_total, @sup, @total

		SET @x = @x + 1 
		SET @i = @i + 1
	END

	RETURN 
END




' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralLoadResultsByAgeAndGenderForAllFacilities]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralLoadResultsByAgeAndGenderForAllFacilities]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[getViralLoadResultsByAgeAndGenderForAllFacilities] (@provinceID varchar(10), @startDate Date, @endDate Date, @age1 int, @age2 int, @gender varchar(2))

RETURNS @resultsTable TABLE(
							ORD int, PROVINCE varchar(100),DISTRICT varchar(100), HEALTH_CENTER varchar(100), HEALTH_CENTER_ID  varchar(10),
							ROUTINE_SUPPRESSION int, ROUTINE_TOTAL int, STF_SUPPRESSION int, STF_TOTAL int, RNS_SUPPRESSION int, RNS_TOTAL int, SUPPRESSION int, TOTAL int
						)
AS 
BEGIN

	DECLARE @provinceName varchar(100)
	DECLARE @districtID varchar(20)
	DECLARE @districtName varchar(100)
	DECLARE @healthCenterID varchar(20)
	DECLARE @healthCenter varchar(100)
	DECLARE @districtTable TABLE(ORD int, DISTRICT_ID varchar(20), PROVINCE_NAME varchar(100), DISTRICT_NAME varchar(100))
	DECLARE @healthCenterTable TABLE(ORD int, CLINIC_ID varchar(20), CLINIC_NAME varchar(100))
	DECLARE @i int
	DECLARE @j int
	DECLARE @x int 

	DECLARE @rot_sup int
	DECLARE @rot_total int
	DECLARE @stf_sup int
	DECLARE @stf_total int
	DECLARE @rns_sup int
	DECLARE @rns_total int
	DECLARE @sup int
	DECLARE @total int

	INSERT INTO @districtTable 
	SELECT ROW_NUMBER() OVER(ORDER BY district.HealthCareID), district.HealthCareID, district.RequestingProvinceName, district.RequestingDistrictName FROM (SELECT DISTINCT(HealthCareID), RequestingProvinceName, RequestingDistrictName FROM VlData WHERE HealthCareID LIKE CONCAT(@provinceID,''%'') AND RequestingDistrictName IS NOT NULL AND HealthCareID IS NOT NULL) AS district
	SET @i = 1
	SET @x = 1
	WHILE @i < (SELECT COUNT(1) FROM @districtTable)
	BEGIN
		SELECT @districtID   = (SELECT DISTRICT_ID   FROM @districtTable WHERE ORD = @i)
		SELECT @districtName = (SELECT DISTRICT_NAME FROM @districtTable WHERE ORD = @i)
		SELECT @provinceName = (SELECT PROVINCE_NAME FROM @districtTable WHERE ORD = @i)

		INSERT INTO @healthCenterTable
		SELECT ROW_NUMBER() OVER(ORDER BY clinic.RequestingFacilityCode), clinic.RequestingFacilityCode, clinic.RequestingFacilityName FROM (SELECT DISTINCT(RequestingFacilityName), RequestingFacilityCode FROM VlData WHERE HealthCareID LIKE @districtID) AS clinic
		SET @j = 1

		WHILE @j < (SELECT COUNT(1) FROM @healthCenterTable)
		BEGIN
			SELECT @healthCenter   = (SELECT CLINIC_NAME FROM @healthCenterTable WHERE ORD = @j)
			SELECT @healthCenterID = (SELECT CLINIC_ID FROM @healthCenterTable WHERE ORD = @j)
			
			SELECT @rot_sup   = COUNT(iif(ReasonForTest = ''Routine'', iif(ViralLoadResultCategory = ''Suppressed'',1, NULL), NULL)),
				   @rot_total = COUNT(iif(ReasonForTest = ''Routine'', 1, NULL)),
				   @stf_sup   = COUNT(iif(ReasonForTest = ''Suspected treatment failure'', iif(ViralLoadResultCategory = ''Suppressed'',1, NULL), NULL)),
				   @stf_total = COUNT(iif(ReasonForTest = ''Suspected treatment failure'', 1, NULL)),
				   @rns_sup   = COUNT(iif(ReasonForTest = ''Reason Not Specified'', iif(ViralLoadResultCategory = ''Suppressed'',1, NULL), NULL)),
				   @rns_total = COUNT(iif(ReasonForTest = ''Reason Not Specified'', 1, NULL)),
				   @sup       = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @total     = COUNT(1)
			FROM  VlData
			WHERE RequestingFacilityCode = @healthCenterID AND RequestingFacilityCode IS NOT NULL AND (AgeInYears >= @age1 AND AgeInYears <= @age2) AND HL7SexCode = @gender AND (AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate)

			INSERT INTO @resultsTable
			SELECT @x, @provinceName, @districtName, @healthCenter, @healthCenterID, @rot_sup, @rot_total, @stf_sup, @stf_total, @rns_sup, @rns_total, @sup, @total

			SET @x = @x + 1
			SET @j = @j + 1
		END
		DELETE FROM @healthCenterTable 
		SET @i = @i + 1
	END

	RETURN 
END




' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppression]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppression]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppression]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(50), NAME VARCHAR(200), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )

	SET @startDate = CONCAT(@startDate, '' 00:00'')
	SET @endDate   = CONCAT(@endDate, '' 23:59:59'')

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')


		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories)) -- Health Facilities
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL
			SELECT TOP 1 @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL 
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL 
			SELECT @name = ''MOZAMBIQUE''
		  END
		ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL 
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repestBreastNotSup, @suppressed, @notSuppressed, @total
	

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionAgeBreastFeeding]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionAgeBreastFeeding]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
 CREATE FUNCTION [dbo].[getViralSuppressionAgeBreastFeeding]
(
	-- Add the parameters for the function here
	@id varchar(20), @age1 int, @age2 int, @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))

	SET @startDate = CONCAT(@startDate, '' 00:00'')
	SET @endDate   = CONCAT(@endDate, '' 23:59:59'')

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')


		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories))
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE RequestingFacilityCode LIKE @id AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			AND AgeInYears >= @age1 AND AgeInYears <= @age2

			SELECT @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode = @id
		  END
		ELSE IF (SELECT LEFT(@id, 1)) = ''P'' AND  (SELECT COUNT(1) FROM VlLabs WHERE LabID = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			AND AgeInYears >= @age1 AND AgeInYears <= @age2
			
			SELECT @name = Lab FROM VlLabs WHERE LabID = @id
		  END
		ELSE 
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			AND AgeInYears >= @age1 AND AgeInYears <= @age2
			
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repestBreastNotSup, @suppressed, @notSuppressed, @total

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionAgePregnantByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionAgePregnantByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionAgePregnantByMonth]
(
	-- Add the parameters for the function here
	@id varchar(20), @age1 int, @age2 int, @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), YEAR int, MONTH VARCHAR(20), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories))
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE FullFacilityCode LIKE @id AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			AND AgeInYears >= @age1 AND AgeInYears <= @age2

			SELECT TOP 1 @name = ClinicName FROM ViralLoadData.dbo.viewHealthCareSites WHERE ClinicCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			AND AgeInYears >= @age1 AND AgeInYears <= @age2

			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id = ''MZ'')  
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			AND AgeInYears >= @age1 AND AgeInYears <= @age2
			
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repestBreastNotSup, @suppressed, @notSuppressed, @total
	
		SET @i = @i + 1
	END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionBreastFeeding]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionBreastFeeding]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
 CREATE FUNCTION [dbo].[getViralSuppressionBreastFeeding]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))

	SET @startDate = CONCAT(@startDate, '' 00:00'')
	SET @endDate   = CONCAT(@endDate, '' 23:59:59'')

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')


		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories)) -- Health Facilities
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			SELECT TOP 1 @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		 ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			SELECT @name = ''MOZAMBIQUE''
		  END
		 ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repestBreastNotSup, @suppressed, @notSuppressed, @total

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionBreastFeedingByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionBreastFeedingByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionBreastFeedingByMonth]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), YEAR int, MONTH VARCHAR(20), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories))
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			
			SELECT TOP 1 @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			SELECT @name = ''MOZAMBIQUE''
		  END
		ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND BreastFeeding = ''Yes''
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repestBreastNotSup, @suppressed, @notSuppressed, @total
	
		SET @i = @i + 1
	END

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionByAge]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionByAge]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionByAge]
(
	-- Add the parameters for the function here
	@id varchar(20), @age1 int, @age2 int, @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), AGE_RANGE varchar(10), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repeatBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))

	SET @startDate = CONCAT(@startDate, '' 00:00'')
	SET @endDate   = CONCAT(@endDate, '' 23:59:59'')

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')


		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories)) -- Health Facilities
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND AgeInYears >= @age1 AND AgeInYears <= @age2
			SELECT TOP 1 @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL  AND AgeInYears >= @age1 AND AgeInYears <= @age2
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites)) --- PROVINCE
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL  AND AgeInYears >= @age1 AND AgeInYears <= @age2
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		 ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL  AND AgeInYears >= @age1 AND AgeInYears <= @age2
			SELECT @name = ''MOZAMBIQUE''
		  END
		 ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id = ''MZ'')  
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL  AND AgeInYears >= @age1 AND AgeInYears <= @age2
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, CONCAT(@age1, ''-'', @age2), @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repeatBreastNotSup, @suppressed, @notSuppressed, @total
	

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionByGender]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionByGender]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionByGender]
(
	-- Add the parameters for the function here
	@id varchar(20), @gender varchar(5), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), GENDER varchar(10), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repeatBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))

	SET @startDate = CONCAT(@startDate, '' 00:00'')
	SET @endDate   = CONCAT(@endDate, '' 23:59:59'')

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')


		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories)) -- Health Facilities
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND HL7SexCode LIKE @gender
			SELECT TOP 1 @name = ClinicName FROM ViralLoadData.dbo.viewHealthCareSites WHERE ClinicCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND HL7SexCode LIKE @gender
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND HL7SexCode LIKE @gender
			
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND HL7SexCode LIKE @gender
			SELECT @name = ''MOZAMBIQUE''
		  END
		 ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repeatBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate and AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND HL7SexCode LIKE @gender
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @gender, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repeatBreastNotSup, @suppressed, @notSuppressed, @total
	

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionByMonth]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), YEAR int, MONTH VARCHAR(20), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories)) -- Health Facilities
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL
			SELECT TOP 1 @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL
			SELECT @name = ''MOZAMBIQUE''
		  END
		ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repestBreastNotSup, @suppressed, @notSuppressed, @total
	
		SET @i = @i + 1
	END

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionByMonthForCDC]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionByMonthForCDC]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionByMonthForCDC]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(50), NAME VARCHAR(200), YEARS int, MONTHS VARCHAR(45), REGISTERED int, SUPPRESSED int, RESULTS int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @registered int
	DECLARE @results int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF (@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND ((SELECT COUNT(1) FROM VlLabs WHERE LabID = @id) = 0) -- Health Facilities
		  BEGIN
			SELECT @registered          = COUNT(RegisteredDateTime), 
				   @results             = COUNT(iif(ViralLoadResultCategory IS NOT NULL, 1, NULL)),
				   @suppressed          = COUNT(iif(ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @total               = COUNT(1)
			FROM VlData
			WHERE FullFacilityCode LIKE @id AND (@monthID = MONTH(RegisteredDateTime) and @year = YEAR(RegisteredDateTime)) 
			
			SELECT TOP 1 @name = ClinicName FROM ViralLoadData.dbo.viewHealthCareSites WHERE ClinicCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM VlLabs WHERE LabID = @id) > 0
		  BEGIN
		    SELECT @registered          = COUNT(RegisteredDateTime), 
				   @results             = COUNT(iif(ViralLoadResultCategory IS NOT NULL, 1, NULL)),
				   @suppressed          = COUNT(iif(ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @total               = COUNT(1)
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND (@monthID = MONTH(RegisteredDateTime) and @year = YEAR(RegisteredDateTime)) 
			SELECT @name = Lab FROM VlLabs WHERE LabID = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id = ''MZ'') 
		  BEGIN
		    SELECT @registered          = COUNT(RegisteredDateTime), 
				   @results             = COUNT(iif(ViralLoadResultCategory IS NOT NULL, 1, NULL)),
				   @suppressed          = COUNT(iif(ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @total               = COUNT(1)
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(RegisteredDateTime) and @year = YEAR(RegisteredDateTime)) 
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, @registered, @results, @suppressed, @total
	
		SET @i = @i + 1
	END

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionByMonthForCDCWithRegisteredDatetime]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionByMonthForCDCWithRegisteredDatetime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionByMonthForCDCWithRegisteredDatetime]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(50), NAME VARCHAR(200), YEARS int, MONTHS VARCHAR(45), REGISTERED int, SUPPRESSED int, RESULTS int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @registered int
	DECLARE @results int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF (@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND ((SELECT COUNT(1) FROM VlLabs WHERE LabID = @id) = 0) -- Health Facilities
		  BEGIN
			SELECT @registered = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(RegisteredDateTime) = @monthID AND YEAR(RegisteredDateTime) = @year AND FullFacilityCode LIKE @id
			SELECT @results    = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(AnalysisDateTime) = @monthID AND YEAR(AnalysisDateTime) = @year AND ViralLoadResultCategory IS NOT NULL AND FullFacilityCode LIKE @id
			SELECT @suppressed = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(AnalysisDateTime) = @monthID AND YEAR(AnalysisDateTime) = @year AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory LIKE ''Suppressed'' AND FullFacilityCode LIKE @id
			SELECT @total      = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(RegisteredDateTime) = @monthID AND YEAR(RegisteredDateTime) = @year AND FullFacilityCode LIKE @id
			SELECT TOP 1 @name = ClinicName FROM ViralLoadData.dbo.viewHealthCareSites WHERE ClinicCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM VlLabs WHERE LabID = @id) > 0
		  BEGIN
		    SELECT @registered = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(RegisteredDateTime) = @monthID AND YEAR(RegisteredDateTime) = @year AND RequestID LIKE CONCAT(''%'', @id, ''%'')
			SELECT @results    = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(AnalysisDateTime) = @monthID AND YEAR(AnalysisDateTime) = @year AND ViralLoadResultCategory IS NOT NULL AND RequestID LIKE CONCAT(''%'', @id, ''%'')
			SELECT @suppressed = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(AnalysisDateTime) = @monthID AND YEAR(AnalysisDateTime) = @year AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory LIKE ''Suppressed'' AND RequestID LIKE CONCAT(''%'', @id, ''%'')
		    SELECT @total      = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(RegisteredDateTime) = @monthID AND YEAR(RegisteredDateTime) = @year AND RequestID LIKE CONCAT(''%'', @id, ''%'')
			SELECT @name = Lab FROM VlLabs WHERE LabID = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id = ''MZ'') 
		  BEGIN
			SELECT @registered = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(RegisteredDateTime) = @monthID AND YEAR(RegisteredDateTime) = @year AND HealthCareID LIKE CONCAT(@id, ''%'')
			SELECT @results    = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(AnalysisDateTime) = @monthID AND YEAR(AnalysisDateTime) = @year AND ViralLoadResultCategory IS NOT NULL AND HealthCareID LIKE CONCAT(@id, ''%'')
			SELECT @suppressed = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(AnalysisDateTime) = @monthID AND YEAR(AnalysisDateTime) = @year AND ViralLoadResultCategory IS NOT NULL AND ViralLoadResultCategory LIKE ''Suppressed'' AND HealthCareID LIKE CONCAT(@id, ''%'')
			SELECT @total      = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE MONTH(RegisteredDateTime) = @monthID AND YEAR(RegisteredDateTime) = @year AND HealthCareID LIKE CONCAT(@id, ''%'')
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, @registered, @results, @suppressed, @total
	
		SET @i = @i + 1
	END

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionDesagragation]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionDesagragation]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionDesagragation]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(50), NAME VARCHAR(200), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repeatBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @sitesTable TABLE (Ord int, ID varchar(20), Name varchar(200))
	DECLARE @i int
	DECLARE @siteCode varchar(20)
	DECLARE @siteName varchar(200)

	IF (SELECT LEN(@id)) = 2 AND @id = ''MZ''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.ProvinceCode) AS ORD, temp.ProvinceCode, temp.ProvinceName
		FROM (SELECT Distinct(ProvinceCode), ProvinceName FROM [ViralLoadData].[dbo].[viewHealthCareSites] WHERE Country LIKE @id) AS temp

	ELSE IF (SELECT LEN(@id)) = 4 AND (SELECT LEFT(@id,2)) = ''MZ''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.DistrictCode) AS ORD, temp.DistrictCode, temp.DistrictName
		FROM (SELECT Distinct(DistrictCode), DistrictName FROM [ViralLoadData].[dbo].[viewHealthCareSites] WHERE ProvinceCode LIKE @id) AS temp
	
	ELSE IF (SELECT LEN(@id)) = 8 AND (SELECT LEFT(@id,2)) = ''MZ''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.ClinicCode) AS ORD, temp.ClinicCode, temp.clinicName
		FROM (SELECT ROW_NUMBER() OVER(PARTITION BY ClinicCode ORDER BY ClinicCode) Od, ClinicCode, ClinicName FROM [ViralLoadData].[dbo].[viewHealthCareSites] WHERE DistrictCode LIKE @id) AS temp
		WHERE temp.Od = 1 AND temp.ClinicCode IS NOT NULL

	ELSE IF (SELECT LEFT(@id, 1)) = ''P'' AND (SELECT LEN(@id)) = 3 AND (SELECT COUNT(1) FROM VlLabs) > 0
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.FullFacilityCode) AS ORD, temp.FullFacilityCode, temp.RequestingFacilityName
		FROM (SELECT Distinct(FullFacilityCode), RequestingFacilityName FROM VlData WHERE RequestID LIKE CONCAT(''%'', @id, ''%'')) AS temp

	--ELSE IF (SELECT LEFT(@id, 2)) = ''MZ'' AND (SELECT LEN(@id)) > 8
	--	INSERT INTO @sitesTable
	--	SELECT ROW_NUMBER() OVER(ORDER BY temp.ClinicCode) AS ORD, temp.RequestingFacilityCode, temp.RequestingFacilityName
	--	FROM (SELECT Distinct(ClinicCode), ClinicName FROM ViralLoadData.dbo.viewHealthCareSites WHERE ClinicCode LIKE @id) AS temp

	SET @i = 1
	WHILE @i < (SELECT COUNT(1) + 1 FROM @sitesTable)
	BEGIN

		SELECT @siteCode = ID, @siteName = Name FROM @sitesTable WHERE Ord = @i
		SELECT @rotineSup          = ROTINE_SUPPRESSED,
			   @rotineNotSup       = ROTINE_NOT_SUPPRESSED,
			   @stfSup             = STF_SUPPRESSED,
			   @stfNotSup          = STF_NOT_SUPPRESSED,
			   @notSpecifiedSup    = NS_SUPPRESSED,
			   @notSpecifiedNotSup = NS_NOT_SUPPRESSED,
			   @repeatBreastSup    = REPEAT_AFTER_BREASTFEEDING_SUPPRESSED,
			   @repeatBreastNotSup = REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED,
			   @suppressed         = SUPPRESSED,
			   @notSuppressed      = NOT_SUPPRESSED,
			   @total              = N
		FROM ViralLoadData.dbo.getViralSuppression(@siteCode, @startDate, @endDate)

		INSERT INTO @table
		SELECT @siteCode, @siteName, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repeatBreastNotSup, @suppressed, @notSuppressed, @total

		SET @i = @i + 1
	END
	
	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionDesagragationByAge]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionDesagragationByAge]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionDesagragationByAge]
(
	-- Add the parameters for the function here
	@id varchar(50), @age1 int, @age2 int, @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(50), NAME VARCHAR(200), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repeatBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @sitesTable TABLE (Ord int, ID varchar(50), Name varchar(200))
	DECLARE @i int
	DECLARE @siteCode varchar(50)
	DECLARE @siteName varchar(200)

	IF (SELECT LEN(@id)) = 2 AND @id = ''MZ''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.ProvinceCode) AS ORD, temp.ProvinceCode, temp.ProvinceName
		FROM (SELECT Distinct(ProvinceCode), ProvinceName FROM [ViralLoadData].[dbo].[viewHealthCareSites] WHERE Country LIKE @id) AS temp
	ELSE IF (SELECT LEN(@id)) = 4 AND (SELECT LEFT(@id,2)) = ''MZ''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.DistrictCode) AS ORD, temp.DistrictCode, temp.DistrictName
		FROM (SELECT Distinct(DistrictCode), DistrictName FROM [ViralLoadData].[dbo].[viewHealthCareSites] WHERE ProvinceCode LIKE @id) AS temp
	ELSE IF (SELECT LEN(@id)) >= 8 AND (SELECT LEFT(@id,2)) = ''MZ''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.ClinicCode) AS ORD, temp.ClinicCode, temp.clinicName
		FROM (SELECT Distinct(ClinicCode), clinicName FROM [ViralLoadData].[dbo].[viewHealthCareSites] WHERE DistrictCode LIKE @id) AS temp
	
	ELSE IF (SELECT LEFT(@id, 1)) = ''P''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.RequestingFacilityCode) AS ORD, temp.RequestingFacilityCode, temp.RequestingFacilityName
		FROM (SELECT Distinct(RequestingFacilityCode), RequestingFacilityName FROM VlData WHERE RequestID LIKE CONCAT(''%'',@id,''%'')) AS temp
	ELSE 
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.RequestingFacilityCode) AS ORD, temp.RequestingFacilityCode, temp.RequestingFacilityName
		FROM (SELECT Distinct(RequestingFacilityCode), RequestingFacilityName FROM VlData WHERE RequestID LIKE CONCAT(''%'',''PJV'',''%'')) AS temp
		
	SET @i = 1
	WHILE @i < (SELECT COUNT(1) + 1 FROM @sitesTable)
	BEGIN
		SELECT @siteCode = ID, @siteName = Name FROM @sitesTable WHERE Ord = @i
		SELECT @rotineSup          = ROTINE_SUPPRESSED,
			   @rotineNotSup       = ROTINE_NOT_SUPPRESSED,
			   @stfSup             = STF_SUPPRESSED,
			   @stfNotSup          = STF_NOT_SUPPRESSED,
			   @notSpecifiedSup    = NS_SUPPRESSED,
			   @notSpecifiedNotSup = NS_NOT_SUPPRESSED,
			   @repeatBreastSup    = REPEAT_AFTER_BREASTFEEDING_SUPPRESSED,
			   @repeatBreastNotSup = REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED,
			   @suppressed         = SUPPRESSED,
			   @notSuppressed      = NOT_SUPPRESSED,
			   @total              = N
		FROM ViralLoadData.dbo.getViralSuppression(@siteCode, @startDate, @endDate)

		INSERT INTO @table
		SELECT @siteCode, @siteName, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repeatBreastNotSup, @suppressed, @notSuppressed, @total

		SET @i = @i + 1
	END
	
	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionDesagragationForPregnant]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionDesagragationForPregnant]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionDesagragationForPregnant]
(
	-- Add the parameters for the function here
	@id varchar(50), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(50), NAME VARCHAR(200), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repeatBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @sitesTable TABLE (Ord int, ID varchar(50), Name varchar(200))
	DECLARE @i int
	DECLARE @siteCode varchar(50)
	DECLARE @siteName varchar(200)

	IF (SELECT LEN(@id)) = 2 AND @id = ''MZ''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.ProvinceCode) AS ORD, temp.ProvinceCode, temp.ProvinceName
		FROM (SELECT Distinct(ProvinceCode), ProvinceName FROM [ViralLoadData].[dbo].[viewHealthCareSites] WHERE Country LIKE @id) AS temp
	ELSE IF (SELECT LEN(@id)) = 4 AND (SELECT LEFT(@id,2)) = ''MZ''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.DistrictCode) AS ORD, temp.DistrictCode, temp.DistrictName
		FROM (SELECT Distinct(DistrictCode), DistrictName FROM [ViralLoadData].[dbo].[viewHealthCareSites] WHERE ProvinceCode LIKE @id) AS temp
	ELSE IF (SELECT LEN(@id)) >= 8 AND (SELECT LEFT(@id,2)) = ''MZ''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.ClinicCode) AS ORD, temp.ClinicCode, temp.clinicName
		FROM (SELECT Distinct(ClinicCode), clinicName FROM [ViralLoadData].[dbo].[viewHealthCareSites] WHERE DistrictCode LIKE @id) AS temp
	
	ELSE IF (SELECT LEFT(@id, 1)) = ''P''
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.RequestingFacilityCode) AS ORD, temp.RequestingFacilityCode, temp.RequestingFacilityName
		FROM (SELECT Distinct(RequestingFacilityCode), RequestingFacilityName FROM VlData WHERE RequestID LIKE CONCAT(''%'',@id,''%'')) AS temp
	ELSE 
		INSERT INTO @sitesTable
		SELECT ROW_NUMBER() OVER(ORDER BY temp.RequestingFacilityCode) AS ORD, temp.RequestingFacilityCode, temp.RequestingFacilityName
		FROM (SELECT Distinct(RequestingFacilityCode), RequestingFacilityName FROM VlData WHERE RequestID LIKE CONCAT(''%'',''PJV'',''%'')) AS temp
		
	SET @i = 1
	WHILE @i < (SELECT COUNT(1) + 1 FROM @sitesTable)
	BEGIN
		SELECT @siteCode = ID, @siteName = Name FROM @sitesTable WHERE Ord = @i
		SELECT @rotineSup          = ROTINE_SUPPRESSED,
			   @rotineNotSup       = ROTINE_NOT_SUPPRESSED,
			   @stfSup             = STF_SUPPRESSED,
			   @stfNotSup          = STF_NOT_SUPPRESSED,
			   @notSpecifiedSup    = NS_SUPPRESSED,
			   @notSpecifiedNotSup = NS_NOT_SUPPRESSED,
			   @repeatBreastSup    = REPEAT_AFTER_BREASTFEEDING_SUPPRESSED,
			   @repeatBreastNotSup = REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED,
			   @suppressed         = SUPPRESSED,
			   @notSuppressed      = NOT_SUPPRESSED,
			   @total              = N
		FROM ViralLoadData.dbo.getViralSuppressionPregnant(@siteCode, @startDate, @endDate)

		INSERT INTO @table
		SELECT @siteCode, @siteName, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repeatBreastNotSup, @suppressed, @notSuppressed, @total

		SET @i = @i + 1
	END
	
	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionFromAgerByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionFromAgerByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionFromAgerByMonth]
(
	-- Add the parameters for the function here
	@id varchar(20), @age1 int, @age2 int, @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), YEAR int, MONTH VARCHAR(20), AGE_RANGE varchar(10), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories))
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND AgeInYears >= @age1 AND AgeInYears <= @age2
			
			SELECT TOP 1 @name = ClinicName FROM ViralLoadData.dbo.viewHealthCareSites WHERE ClinicCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL  AND AgeInYears >= @age1 AND AgeInYears <= @age2
			
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL  AND AgeInYears >= @age1 AND AgeInYears <= @age2
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL  AND AgeInYears >= @age1 AND AgeInYears <= @age2
			SELECT @name = ''MOZAMBIQUE''
		  END
		ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL  AND AgeInYears >= @age1 AND AgeInYears <= @age2
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, CONCAT(@age1, ''-'', @age2), @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repestBreastNotSup, @suppressed, @notSuppressed, @total
	
		SET @i = @i + 1
	END

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionPregnant]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionPregnant]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionPregnant]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(50), NAME VARCHAR(200), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	SET @startDate = CONCAT(@startDate, '' 00:00'')
	SET @endDate   = CONCAT(@endDate, '' 23:59:59'')

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories)) -- Health Facilities
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			SELECT TOP 1 @name = ClinicName FROM ViralLoadData.dbo.viewHealthCareSites WHERE ClinicCode LIKE @id OR OldFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		 ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			SELECT @name = ''MOZAMBIQUE''
		  END
		 ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repestBreastNotSup, @suppressed, @notSuppressed, @total
	

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getViralSuppressionPregnantByMonth]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getViralSuppressionPregnantByMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[getViralSuppressionPregnantByMonth]
(
	-- Add the parameters for the function here
	@id varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE ( ID VARCHAR(10), NAME VARCHAR(200), YEAR int, MONTH VARCHAR(20), ROTINE_SUPPRESSED int, ROTINE_NOT_SUPPRESSED int, STF_SUPPRESSED int, STF_NOT_SUPPRESSED int, NS_SUPPRESSED int, NS_NOT_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_SUPPRESSED int, REPEAT_AFTER_BREASTFEEDING_NOT_SUPPRESSED int,  SUPPRESSED int, NOT_SUPPRESSED int, N int )
AS
BEGIN
	DECLARE @name varchar(100)
	DECLARE @rotineSup int
	DECLARE @rotineNotSup int
	DECLARE @stfSup int 
	DECLARE @stfNotSup int
	DECLARE @notSpecifiedSup int
	DECLARE @notSpecifiedNotSup int
	DECLARE @repeatBreastSup int
	DECLARE @repestBreastNotSup int
	DECLARE @suppressed int
	DECLARE @notSuppressed int
	DECLARE @total int
	DECLARE @healthcareareas TABLE(Code varchar(20), Name varchar(100))
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @i int

	INSERT INTO @healthcareareas 
	VALUES (''MZ'',''Mozambique''), (''MZ01'',''Niassa''), (''MZ02'',''Cabo Delgado''),
		   (''MZ03'', ''Nampula''), (''MZ04'',''Zambezia''), (''MZ05'',''Tete''), (''MZ06'',''Manica''),
		   (''MZ07'',''Sofala''), (''MZ08'',''Inhambane''), (''MZ09'',''Gaza''),
		   (''MZ10'', ''Maputo Provincia''), (''MZ11'', ''Maputo Cidade'')

	INSERT INTO @table_months 
	VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
		   (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
		   (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
		   (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN

		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		IF ((@id IN (SELECT ClinicCode FROM ViralLoadData.dbo.viewHealthCareSites) OR @id IN (SELECT OldFacilityCode FROM ViralLoadData.dbo.viewHealthCareSites)) AND @id NOT IN (SELECT LabCode FROM OpenLDRDict.dbo.Laboratories))
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1)
			FROM VlData
			WHERE (RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id) AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			
			SELECT TOP 1 @name = RequestingFacilityName FROM VlData WHERE RequestingFacilityCode LIKE @id OR FullFacilityCode LIKE @id
		  END
		ELSE IF (SELECT COUNT(1) FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id) > 0
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE RequestID LIKE CONCAT(''%'', @id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			SELECT @name = LabName FROM OpenLDRDict.dbo.Laboratories WHERE LabCode = @id
		  END
		ELSE IF (@id IN (SELECT DISTINCT ProvinceCode FROM ViralLoadData.dbo.viewHealthCareSites))  --- PROVINCE 
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			SELECT @name = Name FROM @healthcareareas WHERE Code = @id
		  END
		 ELSE IF (@id = ''MZ'') -- NATIONAL
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			SELECT @name = ''MOZAMBIQUE''
		  END
		 ELSE IF (@id IN (SELECT DISTINCT DistrictCode FROM ViralLoadData.dbo.viewHealthCareSites)) -- DISTRICT
		  BEGIN
			SELECT @rotineSup          = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @rotineNotSup       = COUNT(iif(ReasonForTest = ''Routine'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @stfSup             = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @stfNotSup          = COUNT(iif(ReasonForTest = ''Suspected treatment failure'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @notSpecifiedSup    = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)), 
				   @notSpecifiedNotSup = COUNT(iif((ReasonForTest = ''Não preenchido'' OR ReasonForTest = ''Reason Not Specified'') AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @repeatBreastSup    = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @repestBreastNotSup = COUNT(iif(ReasonForTest = ''Repeat after breastfeeding'' AND ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @suppressed         = COUNT(iif(ViralLoadResultCategory = ''Suppressed'', 1, NULL)),
				   @notSuppressed      = COUNT(iif(ViralLoadResultCategory = ''Not Suppressed'', 1, NULL)),
				   @total              = COUNT(1) 
			FROM VlData
			WHERE HealthCareID LIKE CONCAT(@id, ''%'') AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND ViralLoadResultCategory IS NOT NULL AND Pregnant = ''Yes''
			SELECT @name = DistrictName FROM ViralLoadData.dbo.viewHealthCareSites WHERE DistrictCode = @id
		  END

		 INSERT INTO @table
		 SELECT @id, @name, @year, @monthPT, @rotineSup, @rotineNotSup, @stfSup, @stfNotSup, @notSpecifiedSup, @notSpecifiedNotSup, @repeatBreastSup, @repestBreastNotSup, @suppressed, @notSuppressed, @total
	
		SET @i = @i + 1
	END

	RETURN

END





' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[NumberOfSamplesByProvince]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NumberOfSamplesByProvince]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

CREATE FUNCTION [dbo].[NumberOfSamplesByProvince] (@startDate Date, @endDate Date)

RETURNS @resultsWaiting TABLE(Name varchar(100),TotalRegistered int, TotalTested int, TotalNotTested int)
AS 
BEGIN
	DECLARE @tableProvinces TABLE(Ord int, Nome varchar(100))
	DECLARE @ord int
	DECLARE @provinceName varchar(100)
	DECLARE @i int
	DECLARE @TotalRegistered int
	DECLARE @TotalTested int
	DECLARE @TotalNotTested int
	DECLARE @Total float

	INSERT INTO @tableProvinces
	SELECT ROW_NUMBER() OVER(ORDER BY vl.RequestingProvinceName), vl.RequestingProvinceName FROM (SELECT DISTINCT(RequestingProvinceName) FROM VlData WHERE RequestingProvinceName IS NOT NULL) AS vl --FROM ViralLoadData.dbo.VlData vl
	SET @i = 1
	WHILE @i < (SELECT COUNT(*)+1 FROM @tableProvinces)
	BEGIN
		SELECT @ord = Ord, @provinceName = Nome FROM @tableProvinces WHERE Ord = @i

		SELECT      @TotalRegistered   = COUNT(1), 
					@TotalTested       = COUNT(iif(ViralLoadResultCategory IS NOT NULL, 1, NULL)),
					@TotalNotTested    = COUNT(iif(ViralLoadResultCategory IS NULL, 1, NULL))		
		FROM VlData vl
		WHERE vl.SpecimenDatetime >= @startDate AND vl.SpecimenDatetime <= @endDate AND vl.RequestingProvinceName = @provinceName

		INSERT INTO @resultsWaiting
		SELECT @provinceName,@TotalRegistered,@TotalTested,@TotalNotTested
		
		SET @i = @i + 1

	END

	RETURN 
END




' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[Samples]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Samples]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Samples]
(
	-- Add the parameters for the function here
	@healthcareid varchar(20), @start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(HealthcareCode varchar(10), HealthcareDesc varchar(100), DistrictName varchar(100), Samples_received int, Samples_analysed int, Samples_rejected int)
AS
BEGIN

	DECLARE @i int
	DECLARE @healthcarecode varchar(20)
	DECLARE @healthcaredesc varchar(100)
	DECLARE @district varchar(100)
	DECLARE @samples_received int
	DECLARE @samples_rejected int
	DECLARE @samples_analysed int 


	SET @i = 0;
	WHILE @i < (SELECT COUNT(*) FROM OpenLDRDict.dbo.viewFacilities AS dict WHERE dict.HealthcareDistrictCode LIKE @healthcareid)
	BEGIN
		SELECT @healthcarecode = tbl_dict.FacilityCode, @healthcaredesc = tbl_dict.Description, @district = tbl_dict.DistrictName
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER BY FacilityCode) AS ron_num, FacilityCode, [Description], DistrictName FROM OpenLDRDict.dbo.viewFacilities WHERE HealthcareDistrictCode LIKE @healthcareid
		) AS tbl_dict
		WHERE tbl_dict.ron_num = @i

		SELECT @samples_received = COUNT(*)
		FROM [ViralLoadData].[dbo].[VlData]
		WHERE RequestingFacilityCode LIKE @healthcarecode AND  RegisteredDateTime >= @start_date AND RegisteredDateTime <= @end_date AND HealthCareID LIKE @healthcareid

		SELECT @samples_analysed = COUNT(*)
		FROM [ViralLoadData].[dbo].[VlData]
		WHERE RequestingFacilityCode LIKE @healthcarecode AND  RegisteredDateTime >= @start_date AND RegisteredDateTime <= @end_date AND (HIVVL_ViralLoadCAPCTM IS NOT NULL OR HIVVL_ViralLoadResult IS NOT NULL)

		SELECT @samples_rejected = COUNT(*)
		FROM [ViralLoadData].[dbo].[VlData]
		WHERE RequestingFacilityCode LIKE @healthcarecode AND  RegisteredDateTime >= @start_date AND RegisteredDateTime <= @end_date AND 
			  HIVVL_LIMSRejectionCode IS NOT NULL AND HIVVL_LIMSRejectionCode <> ''''
		--SELECT 
		--	@specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
		--	@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
		--	@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
		--	@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)), 
		--	@specimen_authorisedate = @specimen_receivedate+@receive_registereddate+@registered_analysisdate+@analysis_authorisedate
		--FROM VlDashboard.dbo.TAT_table
		--WHERE AnalysisDateTime BETWEEN @start_date AND @end_date AND RequestingFacilityCode LIKE @healthcarecode

		INSERT INTO @table
		SELECT @healthcarecode, @healthcaredesc, @district, @samples_received, @samples_analysed, @samples_rejected WHERE @healthcarecode IS NOT NULL AND @healthcaredesc IS NOT NULL
	
		SET @i = @i + 1;
	END
	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[SamplesRegisterdAndTestedForAllLabs]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SamplesRegisterdAndTestedForAllLabs]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[SamplesRegisterdAndTestedForAllLabs]
(
	-- Add the parameters for the function here
	@start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(LabCode varchar(10), LabName varchar(100), SamplesRegistered int, SamplesTested int)
AS
BEGIN

	DECLARE @i int
	DECLARE @labcode varchar(20)
	DECLARE @labname varchar(100)
	--DECLARE @table_labs TABLE(Ord int, LabID varchar(10), LabName varchar(50))
	DECLARE @samplesRegistered int
	DECLARE @samplesTested int

	--INSERT INTO @table_labs VALUES(1,''PJV'',''Jose Macamo''),(2,''PMB'',''INS''),(3,''PXM'', ''XAI-XAI''),(4,''PPG'', ''Ponta Gea''),(5,''PNC'', ''Nampula''),(6,''PQM'', ''Quelimane''),(7,''PMV'', ''HG Machava'')

	SET @i = 0;
	WHILE @i < (SELECT COUNT(*)+1 FROM VlLabs)
	BEGIN

		SELECT @labcode = tbl_labs.LabID, @labname = tbl_labs.Lab
		FROM (SELECT ROW_NUMBER() OVER(ORDER BY tbl.LabID) AS row_numb, tbl.LabID, tbl.Lab FROM VlLabs AS tbl) AS tbl_labs
		WHERE tbl_labs.row_numb = @i

		SELECT 
			@samplesRegistered = COUNT(1)
		FROM VlData
		WHERE RegisteredDateTime >= @start_date AND RegisteredDateTime <= @end_date AND RegisteredDateTime IS NOT NULL AND RequestID LIKE CONCAT(''%'',@labcode,''%'')

		SELECT 
			@samplesTested = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND ViralLoadResultCategory IS NOT NULL AND RequestID LIKE CONCAT(''%'',@labcode,''%'') AND AnalysisDateTime IS NOT NULL

		INSERT INTO @table
		SELECT @labcode, @labname, @samplesRegistered, @samplesTested WHERE @labcode IS NOT NULL AND @labname IS NOT NULL

		SET @i = @i + 1
	END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[SamplesRegisteredAndTestedByMonthsForNational]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SamplesRegisteredAndTestedByMonthsForNational]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[SamplesRegisteredAndTestedByMonthsForNational]
(
	-- Add the parameters for the function here
	@startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(Months varchar(100), Years int, Samples_registered int, Samples_tested int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @provinceName varchar(100)
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @numberSamples int

	DECLARE @totalRegistered int
	DECLARE @totalTested int


	INSERT INTO @table_months VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
									 (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
									 (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
									 (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM [dbo].[get_months_and_years_within_dateRange] (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT 
			@totalRegistered = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(RegisteredDateTime) and @year = YEAR(RegisteredDateTime)) AND RegisteredDateTime IS NOT NULL

		SELECT 
			@totalTested = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND (HIVVL_ViralLoadCAPCTM IS NOT NULL OR HIVVL_ViralLoadResult IS NOT NULL)
			  AND ViralLoadResultCategory IS NOT NULL AND AnalysisDateTime IS NOT NULL

		INSERT INTO @table
		SELECT @monthPT, @year, @totalRegistered, @totalTested

		SET @i = @i + 1;
	END

	RETURN

END







' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[SamplesRegisteredAndTestedByMonthsForOneLab]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SamplesRegisteredAndTestedByMonthsForOneLab]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[SamplesRegisteredAndTestedByMonthsForOneLab]
(
	-- Add the parameters for the function here
	@labID varchar(5), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(Months varchar(100), Years int, Samples_registered int, Samples_tested int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @provinceName varchar(100)
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @numberSamples int

	DECLARE @totalRegistered int
	DECLARE @totalTested int


	INSERT INTO @table_months VALUES (1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
									 (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
									 (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
									 (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM [dbo].[get_months_and_years_within_dateRange] (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT 
			@totalRegistered = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(RegisteredDateTime) and @year = YEAR(RegisteredDateTime)) AND RegisteredDateTime IS NOT NULL AND RequestID LIKE CONCAT(''%'',@labID,''%'') AND @labID IS NOT NULL

		SELECT 
			@totalTested = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND (HIVVL_ViralLoadCAPCTM IS NOT NULL OR HIVVL_ViralLoadResult IS NOT NULL)
			  AND ViralLoadResultCategory IS NOT NULL AND AnalysisDateTime IS NOT NULL AND RequestID LIKE CONCAT(''%'',@labID,''%'') AND @labID IS NOT NULL

		INSERT INTO @table
		SELECT @monthPT, @year, @totalRegistered, @totalTested

		SET @i = @i + 1;
	END

	RETURN

END







' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[SamplesRegisteredAndTestedForOneLab]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SamplesRegisteredAndTestedForOneLab]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[SamplesRegisteredAndTestedForOneLab]
(
	-- Add the parameters for the function here
	@lab varchar(20), @start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(LabCode varchar(10), LabName varchar(100), SamplesRegistered int, SamplesTested int)
AS
BEGIN

	DECLARE @i int
	DECLARE @labcode varchar(20)
	DECLARE @labname varchar(100)
	--DECLARE @table_labs TABLE(Ord int, LabID varchar(10), LabName varchar(50))
	DECLARE @samplesRegistered int
	DECLARE @samplesTested int

	--INSERT INTO @table_labs VALUES(1,''PJV'',''Jose Macamo''),(2,''PMB'',''INS''),(3,''PXM'', ''XAI-XAI''),(4,''PPG'', ''Ponta Gea''),(5,''PNC'', ''Nampula''),(6,''PQM'', ''Quelimane''),(7,''PMV'', ''HG Machava'')

	--SET @i = 0;
	--WHILE @i < (SELECT COUNT(*)+1 FROM @table_labs)
	--BEGIN

	--	SELECT @labcode = tbl_labs.LabID, @labname = tbl_labs.LabName
	--	FROM (SELECT ROW_NUMBER() OVER(ORDER BY tbl.Ord) AS row_numb, tbl.LabID, tbl.LabName FROM @table_labs AS tbl) AS tbl_labs
	--	WHERE tbl_labs.row_numb = @i
		SELECT @labcode = LabID, @labName = Lab
		FROM VlLabs WHERE LabID = @lab

		SELECT @samplesRegistered = COUNT(1)
		FROM VlData
		WHERE RegisteredDateTime >= @start_date AND RegisteredDateTime <= @end_date AND RegisteredDateTime IS NOT NULL AND RequestID LIKE CONCAT(''%'',@labcode,''%'')

		SELECT @samplesTested = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND ViralLoadResultCategory IS NOT NULL AND RequestID LIKE CONCAT(''%'',@labcode,''%'') AND AnalysisDateTime IS NOT NULL

		INSERT INTO @table
		SELECT @labcode, @labname, @samplesRegistered, @samplesTested WHERE @labcode IS NOT NULL AND @labname IS NOT NULL

	--	SET @i = @i + 1
	--END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TAT_NationalForDisaFacilities]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAT_NationalForDisaFacilities]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Vagner Pene>
-- ALTER date: <ALTER 22.02.2018, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TAT_NationalForDisaFacilities]
(
	-- Add the parameters for the function here
	@startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(HealthcareCode varchar(10), HealthcareDesc varchar(100), DistrictName varchar(100), Collection_Receive int, Received_Registered int, Registered_Analysis int, Analysis_Authorise int, Collection_Authorise int, N int, Ignored int, Total int)
AS
BEGIN

	DECLARE @i int
	DECLARE @healthcarecode varchar(20)
	DECLARE @healthcaredesc varchar(100)
	DECLARE @district varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int
	DECLARE @numberIgnoredSamples int
	DECLARE @percentage int
	DECLARE @total int

	SET @i = 0;
	WHILE @i < (SELECT COUNT(1) + 1 FROM ViralLoadData.dbo.DisaFacilities)
	BEGIN

		SELECT @healthcarecode = tbl_disa.FacilityCode, @healthcaredesc = tbl_disa.FacilityDescription
		FROM(
			SELECT ROW_NUMBER() OVER(ORDER BY FacilityCode) AS row_num, FacilityCode, FacilityDescription FROM ViralLoadData.dbo.DisaFacilities 
		) AS tbl_disa
		WHERE tbl_disa.row_num = @i

		SELECT @district = DistrictName  FROM OpenLDRDict.dbo.viewFacilities WHERE FacilityCode = @healthcarecode

		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)) = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate, 0) + isnull(@receive_registereddate, 0) + isnull(@registered_analysisdate,0) + isnull(@analysis_authorisedate, 0),
			@numberSamples			 = COUNT(1)
		FROM ViralLoadData.dbo.VlData
		WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode LIKE @healthcarecode
			  AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 90

		SELECT @numberIgnoredSamples = COUNT(1) FROM ViralLoadData.dbo.VlData
		WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode LIKE @healthcarecode
			  AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) > 90

		SELECT @total = COUNT(1) FROM ViralLoadData.dbo.VlData WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode LIKE @healthcarecode

		SELECT @percentage = iif(@numberSamples = 0, 0, (@numberIgnoredSamples/@total)*100)

		INSERT INTO @table
		SELECT @healthcarecode, @healthcaredesc, @district, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples, @numberIgnoredSamples, @total WHERE @healthcarecode IS NOT NULL -- AND @healthcaredesc IS NOT NULL
	
		SET @i = @i + 1;
	END
	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TAT_NationalForDisaLabSites]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAT_NationalForDisaLabSites]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- ============================================= 
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TAT_NationalForDisaLabSites]
(
	-- Add the parameters for the function here
	@startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(HealthcareCode varchar(100), Collection_Receive int, Received_Registered int, Registered_Analysis int, Analysis_Authorise int, Collection_Authorise int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @healthcarecode varchar(20)
	DECLARE @healthcaredesc varchar(100)
	DECLARE @district varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int
	DECLARE @label varchar(100)

	SELECT @numberSamples = COUNT(1)
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT FacilityCode FROM ViralLoadData.dbo.DisaFacilities 
	) 

	INSERT INTO @table
	SELECT 
		  ''Average TAT'',
		  AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
		  AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
		  AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
		  AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
		  AVG(DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime)),
		  @numberSamples
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT FacilityCode FROM ViralLoadData.dbo.DisaFacilities 
	) AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 60


	INSERT INTO @table
	SELECT 
		    ''Minimum TAT'',
			MIN(Collection_Receive),
			MIN(Received_Registered),
			MIN(Registered_Analysis),
			MIN(Analysis_Authorise),
			MIN(Collection_Authorise),
			@numberSamples
	FROM ViralLoadData.dbo.TAT_NationalForDisaFacilities(@startDate,@endDate)

	INSERT INTO @table
	SELECT ''Maximum TAT'',
		   MAX(Collection_Receive),
		   MAX(Received_Registered),
		   MAX(Registered_Analysis),
		   MAX(Analysis_Authorise),
		   MAX(Collection_Authorise),
		   @numberSamples
	FROM ViralLoadData.dbo.TAT_NationalForDisaFacilities(@startDate,@endDate)

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TAT_NationalForDisaLabSitesByLab]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAT_NationalForDisaLabSitesByLab]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- ============================================= 
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TAT_NationalForDisaLabSitesByLab]
(
	-- Add the parameters for the function here
	@lab varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(Variables varchar(100), Collection_Receive int, Received_Registered int, Registered_Analysis int, Analysis_Authorise int, Collection_Authorise int, Total int, IgnoredSamples int, TestedSamples int)
AS
BEGIN

	DECLARE @i int
	DECLARE @healthcarecode varchar(20)
	DECLARE @healthcaredesc varchar(100)
	DECLARE @district varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int
	DECLARE @ignoredSamples int
	DECLARE @acceptedSamples int
	DECLARE @label varchar(100)

	SELECT @numberSamples = COUNT(1)
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT distinct(FacilityCode) FROM ViralLoadData.dbo.DisaFacilities disa, VlData data 
		WHERE disa.FacilityCode = data.RequestingFacilityCode 
	) AND RequestID LIKE CONCAT(''%'',@lab,''%'')

	SELECT @ignoredSamples = COUNT(1)
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT distinct(FacilityCode) FROM ViralLoadData.dbo.DisaFacilities disa, VlData data 
		WHERE disa.FacilityCode = data.RequestingFacilityCode
	)  AND RequestID LIKE CONCAT(''%'',@lab,''%'') AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) > 60

	SELECT @acceptedSamples = COUNT(1)
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT distinct(FacilityCode) FROM ViralLoadData.dbo.DisaFacilities disa, VlData data 
		WHERE disa.FacilityCode = data.RequestingFacilityCode
	)  AND RequestID LIKE CONCAT(''%'',@lab,''%'') AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 60

	INSERT INTO @table
	SELECT 
		  ''Average TAT'',
		  AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
		  AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
		  AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
		  AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
		  AVG(DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime)),
		  @numberSamples,
		  @ignoredSamples,
		  @acceptedSamples
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT distinct(FacilityCode) FROM ViralLoadData.dbo.DisaFacilities disa, VlData data 
		WHERE disa.FacilityCode = data.RequestingFacilityCode 
	) AND RequestID LIKE CONCAT(''%'',@lab,''%'') AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 60


	INSERT INTO @table
	SELECT  
			''Minimum TAT'', 
			MIN(Collection_Receive),
			MIN(Received_Registered),
			MIN(Registered_Analysis),
			MIN(Analysis_Authorise),
			MIN(Collection_Authorise),
			@numberSamples,
			@ignoredSamples,
			@acceptedSamples
	FROM ViralLoadData.dbo.TAT_NationalForDisaFacilities(@startDate,@endDate), ViralLoadData.dbo.VlData data
	WHERE HealthcareCode = RequestingFacilityCode AND RequestID LIKE CONCAT(''%'',@lab,''%'')

	INSERT INTO @table
	SELECT 
		   ''Maximum TAT'',
		   MAX(Collection_Receive),
		   MAX(Received_Registered),
		   MAX(Registered_Analysis),
		   MAX(Analysis_Authorise),
		   MAX(Collection_Authorise),
		   @numberSamples,
		   @ignoredSamples,
		   @acceptedSamples
	FROM ViralLoadData.dbo.TAT_NationalForDisaFacilities(@startDate,@endDate), ViralLoadData.dbo.VlData data
	WHERE HealthcareCode = RequestingFacilityCode AND RequestID LIKE CONCAT(''%'',@lab,''%'')


	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TAT_NationalForDisaLabSitesByProvince]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAT_NationalForDisaLabSitesByProvince]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- ============================================= 
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TAT_NationalForDisaLabSitesByProvince]
(
	-- Add the parameters for the function here
	@provinceCode varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(Variables varchar(100), Collection_Receive int, Received_Registered int, Registered_Analysis int, Analysis_Authorise int, Collection_Authorise int, Total int, IgnoredSamples int, TestedSamples int)
AS
BEGIN

	DECLARE @i int
	DECLARE @healthcarecode varchar(20)
	DECLARE @healthcaredesc varchar(100)
	DECLARE @district varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int
	DECLARE @ignoredSamples int
	DECLARE @acceptedSamples int
	DECLARE @label varchar(100)

	SELECT @numberSamples = COUNT(1)
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT distinct(FacilityCode) FROM ViralLoadData.dbo.DisaFacilities disa, VlData data 
		WHERE disa.FacilityCode = data.RequestingFacilityCode AND HealthCareID LIKE CONCAT(@provinceCode,''%'')
	) 

	SELECT @ignoredSamples = COUNT(1)
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT distinct(FacilityCode) FROM ViralLoadData.dbo.DisaFacilities disa, VlData data 
		WHERE disa.FacilityCode = data.RequestingFacilityCode AND HealthCareID LIKE CONCAT(@provinceCode,''%'')
	) AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) > 60

	SELECT @acceptedSamples = COUNT(1)
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT distinct(FacilityCode) FROM ViralLoadData.dbo.DisaFacilities disa, VlData data 
		WHERE disa.FacilityCode = data.RequestingFacilityCode AND HealthCareID LIKE CONCAT(@provinceCode,''%'')
	) AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 60

	INSERT INTO @table
	SELECT 
		  ''Average TAT'',
		  AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
		  AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
		  AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
		  AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
		  AVG(DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime)),
		  @numberSamples,
		  @ignoredSamples,
		  @acceptedSamples
	FROM ViralLoadData.dbo.VlData
	WHERE AnalysisDateTime >= @startDate AND AnalysisDateTime <= @endDate AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode IN (
		SELECT distinct(FacilityCode) FROM ViralLoadData.dbo.DisaFacilities disa, VlData data 
		WHERE disa.FacilityCode = data.RequestingFacilityCode AND HealthCareID LIKE CONCAT(@provinceCode,''%'')
	) AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 60


	INSERT INTO @table
	SELECT  
			''Minimum TAT'', 
			MIN(Collection_Receive),
			MIN(Received_Registered),
			MIN(Registered_Analysis),
			MIN(Analysis_Authorise),
			MIN(Collection_Authorise),
			@numberSamples,
			@ignoredSamples,
			@acceptedSamples
	FROM ViralLoadData.dbo.TAT_NationalForDisaFacilities(@startDate,@endDate), ViralLoadData.dbo.VlData data
	WHERE HealthcareCode = RequestingFacilityCode AND HealthCareID LIKE CONCAT(@provinceCode,''%'')

	INSERT INTO @table
	SELECT 
		   ''Maximum TAT'',
		   MAX(Collection_Receive),
		   MAX(Received_Registered),
		   MAX(Registered_Analysis),
		   MAX(Analysis_Authorise),
		   MAX(Collection_Authorise),
		   @numberSamples,
		   @ignoredSamples,
		   @acceptedSamples
	FROM ViralLoadData.dbo.TAT_NationalForDisaFacilities(@startDate,@endDate), ViralLoadData.dbo.VlData data
	WHERE HealthcareCode = RequestingFacilityCode AND HealthCareID LIKE CONCAT(@provinceCode,''%'')



	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeAllSitesOrderByMonths]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeAllSitesOrderByMonths]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeAllSitesOrderByMonths]
(
	-- Add the parameters for the function here
	@startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(Months varchar(100), Years int, Colect_Received int, Received_Registered int, Registered_Analysis int, Analysis_Authorised int, Colect_Authorised int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @provinceName varchar(100)
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @numberSamples int

	INSERT INTO @table_months VALUES(1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
								  (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
								  (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
								  (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM [dbo].[get_months_and_years_within_dateRange] (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND (HIVVL_ViralLoadCAPCTM IS NOT NULL OR HIVVL_ViralLoadResult IS NOT NULL)
			  AND ViralLoadResultCategory IS NOT NULL

		INSERT INTO @table
		SELECT @monthPT, @year, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples 

		SET @i = @i + 1;
	END

	RETURN

END







' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeByDistrict]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeByDistrict]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeByDistrict]
(
	-- Add the parameters for the function here
	@districtcode varchar(20), @start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(HealthcareCode varchar(10), HealthcareDesc varchar(100), Province varchar(30), Colect_Receive int, Receive_Register int, Register_Analyse int, Analyse_Authorise int, Colect_Authorise int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @districtname varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @province varchar(30)
	DECLARE @numberSamples int

	SET @i = 0;
	WHILE @i < (SELECT COUNT(*)+1 FROM OpenLDRDict.dbo.HealthcareAreas AS dict WHERE dict.HealthcareAreaCode LIKE CONCAT(@districtcode,''%'') AND len(dict.HealthcareAreaCode)=8 AND dict.HealthcareAreaCode IS NOT NULL)
	BEGIN
		SELECT @districtname = tbl_dict.HealthcareAreaDesc
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER BY HealthcareAreaDesc) AS ron_num, HealthcareAreaCode, HealthcareAreaDesc FROM OpenLDRDict.dbo.HealthcareAreas WHERE HealthcareAreaCode LIKE CONCAT(@districtcode,''%'') AND len(HealthcareAreaCode)=8 AND HealthcareAreaCode IS NOT NULL
		) AS tbl_dict
		WHERE tbl_dict.ron_num = @i

		SELECT @province= HealthcareAreaDesc FROM OpenLDRDict.dbo.HealthcareAreas WHERE HealthcareAreaCode LIKE SUBSTRING(@districtcode,1,4)
		
		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@numberSamples			 = COUNT(1)
		FROM ViralLoadData.dbo.VlData 
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND RequestingDistrictName = @districtname AND ViralLoadResultCategory IS NOT NULL

		
		INSERT INTO @table
		SELECT @districtcode, @districtname, @province, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples WHERE @districtname IS NOT NULL
	
		SET @i = @i + 1;
	END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeByHealthCenter]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeByHealthCenter]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeByHealthCenter]
(
	-- Add the parameters for the function here
	@healthcenterid varchar(20), @start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(HealthcareCode varchar(10), HealthcareDesc varchar(100), DistrictName varchar(100), Colect_Receive int, Receive_Register int, Register_Analyse int, Analyse_Authorise int, Colect_Authorise int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @healthcaredesc varchar(100)
	DECLARE @district varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int

	SELECT @healthcaredesc = Description, @district = DistrictName FROM OpenLDRDict.dbo.viewFacilities WHERE FacilityCode LIKE @healthcenterid
	SELECT 
		@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
		@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
		@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
		@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
		@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
		@numberSamples			 = COUNT(1)
	FROM VlData
	WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode LIKE @healthcenterid

	INSERT INTO @table
	SELECT @healthcenterid, @healthcaredesc, @district, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples WHERE @healthcenterid IS NOT NULL AND @healthcaredesc IS NOT NULL
	
	RETURN

END







' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeByLab]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeByLab]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeByLab]
(
	-- Add the parameters for the function here
	@lab varchar(20), @start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(LabCode varchar(10), LabName varchar(100), Colect_Receive int, Receive_Register int, Register_Analyse int, Analyse_Authorise int, Colect_Authorise int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @labcode varchar(20)
	DECLARE @labname varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int

	--INSERT INTO @table_labs VALUES(1,''PJV'',''Jose Macamo''),(2,''PMB'',''INS''),(3,''PXM'', ''XAI-XAI''),(4,''PPG'', ''Ponta Gea''),(5,''PNC'', ''Nampula''),(6,''PQM'', ''Quelimane''),(7,''PMV'', ''HG Machava'')

	SET @i = 0;
	WHILE @i < (SELECT COUNT(*)+1 FROM VlLabs)
	BEGIN
		SELECT @labcode = tbl_labs.LabID, @labname = tbl_labs.Lab
		FROM (SELECT ROW_NUMBER() OVER(ORDER BY tbl.LabID) AS row_numb, tbl.LabID, tbl.Lab FROM VlLabs AS tbl) AS tbl_labs
		WHERE tbl_labs.row_numb = @i

		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND ViralLoadResultCategory IS NOT NULL AND RequestID LIKE CONCAT(''%'',@labcode,''%'') --AND HIVVL_ViralLoadCAPCTM IS NOT NULL

		INSERT INTO @table
		SELECT @labcode, @labname,  @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples WHERE @labcode IS NOT NULL AND @labname IS NOT NULL

		SET @i = @i + 1
	END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeByLabOrderByMonths]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeByLabOrderByMonths]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeByLabOrderByMonths]
(
	-- Add the parameters for the function here
	@lab varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(LabCode varchar(10), Months varchar(100), Years int, Colect_Received int, Received_Registered int, Registered_Analysis int, Analysis_Authorised int, Colect_Authorised int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @numberSamples int

	INSERT INTO @table_months VALUES(1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
								  (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
								  (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
								  (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id
	--SELECT * FROM @tableDates 
	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND RequestID LIKE CONCAT(''%'',@lab,''%'')
			   AND (HIVVL_ViralLoadCAPCTM IS NOT NULL OR HIVVL_ViralLoadResult IS NOT NULL)

	
		INSERT INTO @table
		SELECT @lab, @monthPT, @year, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples

		SET @i = @i + 1;
	END

	RETURN
END	







' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeByLabOrderByMonths_x60]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeByLabOrderByMonths_x60]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeByLabOrderByMonths_x60]
(
	-- Add the parameters for the function here
	@labID varchar(20), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(LabCode varchar(10), X_Months varchar(100), Years int, Y_Collection_Received int, Y_Received_Registered int, Y_Registered_Analysis int, Y_Analysis_Authorised int, Y_Collection_Authorised int, SamplesWithLessThan60days int, Less60Percentage float, SamplesWithMoreThan60days int, More60Percentage float, OutRange float, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @numberSamples int
	DECLARE @samplesWithLessthan60days int
	DECLARE @samplesWithMorethan60days int
	DECLARE @Less60daysPercentage float
	DECLARE @More60daysPercentage float
	DECLARE @total int
	DECLARE @out float

	INSERT INTO @table_months VALUES(1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
								  (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
								  (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
								  (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM dbo.get_months_and_years_within_dateRange (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id
	--SELECT * FROM @tableDates 
	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT 
			@specimen_receivedate    = AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime)), 
			@receive_registereddate  = AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)), 
			@registered_analysisdate = AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)),
			@analysis_authorisedate  = AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@samplesWithLessthan60days = COUNT(1)
		FROM (
			SELECT * FROM VlData 
			WHERE DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 60  AND ViralLoadResultCategory IS NOT NULL 
				  AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND RequestID LIKE CONCAT(''%'',@labID,''%'')
		) AS data

		SELECT @samplesWithMorethan60days = COUNT(iif(DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) >= 60 AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 90, 1, NULL)),
			   @numberSamples			  = COUNT(1)
		FROM VlData 
		WHERE ViralLoadResultCategory IS NOT NULL 
		AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND RequestID LIKE CONCAT(''%'',@labID,''%'')
	
		SELECT @total = iif(@numberSamples = 0, 1, @numberSamples)
		
		SELECT @Less60daysPercentage = ROUND((CAST(@samplesWithLessthan60days AS float)/CAST(@total AS float))*100, 1),
			   @More60daysPercentage = ROUND((CAST(@samplesWithMorethan60days AS float)/CAST(@total AS float))*100, 1)

		SELECT @out = 100 - (@Less60daysPercentage + @More60daysPercentage)
	
		INSERT INTO @table
		SELECT @labID, @monthPT, @year, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @samplesWithLessthan60days, @Less60daysPercentage, @samplesWithMorethan60days, @More60daysPercentage, @out, @numberSamples

		SET @i = @i + 1;
	END

	RETURN
END	






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeByProvince]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeByProvince]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeByProvince]
(
	-- Add the parameters for the function here
	@provinceid varchar(20), @start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(HealthcareCode varchar(10), HealthcareDesc varchar(100), Colect_Receive int, Receive_Register int, Register_Analyse int, Analyse_Authorise int, Colect_Authorise int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @healthcarecode varchar(20)
	DECLARE @healthcaredesc varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int

	SET @i = 0;

	WHILE @i < 2
	BEGIN
		SELECT @healthcarecode = tbl_dict.HealthcareAreaCode, @healthcaredesc = tbl_dict.HealthcareAreaDesc
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER BY HealthcareAreaCode) AS ron_num, HealthcareAreaCode, HealthcareAreaDesc FROM OpenLDRDict.dbo.HealthcareAreas WHERE HealthcareAreaCode LIKE CONCAT(@provinceid,''%'') AND len(HealthcareAreaCode) = 4
		) AS tbl_dict
		WHERE tbl_dict.ron_num = @i
		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND ViralLoadResultCategory IS NOT NULL AND HealthCareID LIKE CONCAT(@healthcarecode,''%'')

		INSERT INTO @table
		SELECT @healthcarecode AS HEALTHCARE_CODE, @healthcaredesc AS HEALTHCARE_DESC, @specimen_receivedate AS SAMPLE_COLECT_RECIVE_DATE, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples WHERE @healthcarecode IS NOT NULL AND @healthcaredesc IS NOT NULL
	
		SET @i = @i + 1;
	END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeByProvinceOrderByMonths]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeByProvinceOrderByMonths]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeByProvinceOrderByMonths]
(
	-- Add the parameters for the function here
	@provinceID varchar(100), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(ProvinceName varchar(100), Months varchar(100), Years int, Colect_Received int, Received_Registered int, Registered_Analysis int, Analysis_Authorised int, Colect_Authorised int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @provinceName varchar(100)
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @numberSamples int

	INSERT INTO @table_months VALUES(1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
								  (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
								  (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
								  (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM [dbo].[get_months_and_years_within_dateRange] (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND HealthCareID LIKE CONCAT(@provinceID,''%'') AND ViralLoadResultCategory IS NOT NULL

		INSERT INTO @table
		SELECT (SELECT DISTINCT(RequestingProvinceName) FROM VlData WHERE HealthCareID LIKE CONCAT(@provinceID,''%'')), @monthPT, @year, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples 

		SET @i = @i + 1;
	END

	RETURN

END







' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeByProvinceOrderByMonths_x60]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeByProvinceOrderByMonths_x60]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeByProvinceOrderByMonths_x60]
(
	-- Add the parameters for the function here
	@provinceID varchar(100), @startDate varchar(20), @endDate varchar(20)
)
RETURNS @table TABLE(ProvinceName varchar(100), X_Months varchar(100), Years int, Y_Collection_Received int, Y_Received_Registered int, Y_Registered_Analysis int, Y_Analysis_Authorised int, Y_Collection_Authorised int, SamplesWithLessThan60days int, Less60Percentage float, SamplesWithMoreThan60days int, More60Percentage float, OutRange float, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @order int
	DECLARE @monthID int
	DECLARE @year int
	DECLARE @provinceName varchar(100)
	DECLARE @monthPT varchar(100)
	DECLARE @monthEN varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @table_months TABLE(id int, monthEN varchar(10), monthPT varchar(50))
	DECLARE @tableDates TABLE(ord int, monthId int, monthPT varchar(20), monthEN varchar(20), years int )
	DECLARE @numberSamples int
	DECLARE @samplesWithLessthan60days int
	DECLARE @samplesWithMorethan60days int
	DECLARE @Less60daysPercentage float
	DECLARE @More60daysPercentage float
	DECLARE @total int
	DECLARE @out float

	INSERT INTO @table_months VALUES(1,''January'', ''Janeiro''),(2,''February'',''Fevereiro''),(3,''March'', ''Março''),
								    (4,''April'', ''Abril''),(5,''May'', ''Maio''),(6,''June'', ''Junho''),
								    (7,''July'', ''Julho''),(8,''August'', ''Agosto''),(9,''September'', ''Setembro''),
								    (10,''October'', ''Outubro''),(11,''November'', ''Novembro''),(12,''December'', ''Dezembro'')

	INSERT INTO @tableDates 
	SELECT ROW_NUMBER() OVER(ORDER BY YEAR(tbl_date.Data)), MONTH(tbl_date.Data), table_months.monthPT, table_months.monthEN, YEAR(tbl_date.Data) 
	FROM(
		SELECT Data FROM [dbo].[get_months_and_years_within_dateRange] (@startDate,@endDate)
	) AS tbl_date
	LEFT JOIN @table_months AS table_months ON MONTH(tbl_date.Data) = table_months.id

	SET @i = 1;
	WHILE @i < (SELECT COUNT(*) FROM @tableDates)
	BEGIN
		
		SELECT @order   = tbl_date.ord,
			   @monthID = tbl_date.monthId, 
			   @monthPT = tbl_date.monthPT, 
			   @monthEN = tbl_date.monthEN, 
			   @year    = tbl_date.years 
		FROM @tableDates AS tbl_date
		WHERE tbl_date.ord = @i

		SELECT 
			@specimen_receivedate    = AVG(DATEDIFF(day, data.SpecimenDatetime, data.ReceivedDateTime)), 
			@receive_registereddate  = AVG(DATEDIFF(day, data.ReceivedDateTime, data.RegisteredDateTime)), 
			@registered_analysisdate = AVG(DATEDIFF(day, data.RegisteredDateTime, data.AnalysisDateTime)),
			@analysis_authorisedate  = AVG(DATEDIFF(day, data.AnalysisDateTime, data.AuthorisedDateTime)),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@samplesWithLessthan60days = COUNT(1)
		FROM (
			SELECT * FROM VlData 
			WHERE DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 60  AND ViralLoadResultCategory IS NOT NULL 
				  AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND HealthCareID LIKE CONCAT(@provinceID,''%'')
		) AS data

		SELECT @samplesWithMorethan60days = COUNT(iif(DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) >= 60 AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) <= 90, 1, NULL)),
			   @numberSamples			  = COUNT(1)
		FROM VlData 
		WHERE ViralLoadResultCategory IS NOT NULL 
		AND (@monthID = MONTH(AnalysisDateTime) and @year = YEAR(AnalysisDateTime)) AND HealthCareID LIKE CONCAT(@provinceID,''%'')
	
		SELECT @total = iif(@numberSamples = 0, 1, @numberSamples)
		
		SELECT @Less60daysPercentage = ROUND((CAST(@samplesWithLessthan60days AS float)/CAST(@total AS float))*100, 1),
			   @More60daysPercentage = ROUND((CAST(@samplesWithMorethan60days AS float)/CAST(@total AS float))*100, 1)

		SELECT @out = 100 - (@Less60daysPercentage + @More60daysPercentage)

		INSERT INTO @table
		SELECT (SELECT DISTINCT(RequestingProvinceName) FROM VlData WHERE HealthCareID LIKE CONCAT(@provinceID,''%'')), @monthPT, @year, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @samplesWithLessthan60days, @Less60daysPercentage, @samplesWithMorethan60days, @More60daysPercentage, @out, @numberSamples

		SET @i = @i + 1;
	END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeForAllDistricts]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeForAllDistricts]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeForAllDistricts]
(
	-- Add the parameters for the function here
	@healthcareid varchar(20), @start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(HealthcareCode varchar(10), HealthcareDesc varchar(100), Province varchar(30), Colect_Receive int, Receive_Register int, Register_Analyse int, Analyse_Authorise int, Colect_Authorise int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @districtcode varchar(20)
	DECLARE @districtname varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @province varchar(30)
	DECLARE @numberSamples int

	SET @i = 0;
	WHILE @i < (SELECT COUNT(*)+1 FROM OpenLDRDict.dbo.HealthcareAreas AS dict WHERE dict.HealthcareAreaCode LIKE CONCAT(@healthcareid,''%'') AND len(dict.HealthcareAreaCode)=8 AND dict.HealthcareAreaCode IS NOT NULL)
	BEGIN
		SELECT @districtcode = tbl_dict.HealthcareAreaCode, @districtname = tbl_dict.HealthcareAreaDesc
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER BY HealthcareAreaDesc) AS ron_num, HealthcareAreaCode, HealthcareAreaDesc FROM OpenLDRDict.dbo.HealthcareAreas WHERE HealthcareAreaCode LIKE CONCAT(@healthcareid,''%'') AND len(HealthcareAreaCode)=8 AND HealthcareAreaCode IS NOT NULL
		) AS tbl_dict
		WHERE tbl_dict.ron_num = @i

		SELECT @province= HealthcareAreaDesc FROM OpenLDRDict.dbo.HealthcareAreas WHERE HealthcareAreaCode LIKE SUBSTRING(@districtcode,1,4)
		
		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND ViralLoadResultCategory IS NOT NULL AND HealthCareID = @districtcode
		
		INSERT INTO @table
		SELECT @districtcode, @districtname, @province, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples WHERE @districtcode IS NOT NULL AND @districtname IS NOT NULL
	
		SET @i = @i + 1;
	END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeForAllHealthCenters]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeForAllHealthCenters]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeForAllHealthCenters]
(
	-- Add the parameters for the function here
	@healthcareid varchar(20), @start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(HealthcareCode varchar(10), HealthcareDesc varchar(100), DistrictName varchar(100), Colect_Receive int, Receive_Register int, Register_Analyse int, Analyse_Authorise int, Colect_Authorise int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @healthcarecode varchar(20)
	DECLARE @healthcaredesc varchar(100)
	DECLARE @district varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int

	SET @i = 0;
	WHILE @i < (SELECT COUNT(*) FROM OpenLDRDict.dbo.viewFacilities AS dict WHERE dict.HealthcareDistrictCode LIKE @healthcareid)
	BEGIN
		SELECT @healthcarecode = tbl_dict.FacilityCode, @healthcaredesc = tbl_dict.Description, @district = tbl_dict.DistrictName
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER BY FacilityCode) AS ron_num, FacilityCode, [Description], DistrictName FROM OpenLDRDict.dbo.viewFacilities WHERE HealthcareDistrictCode LIKE @healthcareid
		) AS tbl_dict
		WHERE tbl_dict.ron_num = @i
		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@numberSamples			 = COUNT(1)
		FROM ViralLoadData.dbo.VlData
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND ViralLoadResultCategory IS NOT NULL AND RequestingFacilityCode LIKE @healthcarecode

		INSERT INTO @table
		SELECT @healthcarecode, @healthcaredesc, @district, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples WHERE @healthcarecode IS NOT NULL AND @healthcaredesc IS NOT NULL
	
		SET @i = @i + 1;
	END
	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeForAllProvinces]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeForAllProvinces]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeForAllProvinces]
(
	-- Add the parameters for the function here
	@start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(HealthcareCode varchar(10), HealthcareDesc varchar(100), Colect_Receive int, Receive_Register int, Register_Analyse int, Analyse_Authorise int, Colect_Authorise int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @healthcarecode varchar(20)
	DECLARE @healthcaredesc varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int

	SET @i = 0;
	--WHILE @i < (SELECT COUNT(*) FROM OpenLDRDict.dbo.HealthcareAreas AS dict WHERE dict.HealthcareAreaCode LIKE @healthcareid AND len(dict.HealthcareAreaCode) = 4)
	WHILE @i < 12
	BEGIN
		SELECT @healthcarecode = tbl_dict.HealthcareAreaCode, @healthcaredesc = tbl_dict.HealthcareAreaDesc
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER BY HealthcareAreaCode) AS ron_num, HealthcareAreaCode, HealthcareAreaDesc FROM OpenLDRDict.dbo.HealthcareAreas WHERE HealthcareAreaCode LIKE ''MZ%'' AND len(HealthcareAreaCode) = 4
		) AS tbl_dict
		WHERE tbl_dict.ron_num = @i
		SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate,0)+isnull(@receive_registereddate,0)+isnull(@registered_analysisdate,0)+isnull(@analysis_authorisedate,0),
			@numberSamples			 = COUNT(1)
		FROM VlData
		WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND ViralLoadResultCategory IS NOT NULL AND RequestingProvinceName = @healthcaredesc AND DATEDIFF(day, SpecimenDatetime, AuthorisedDateTime) < 90

	
		INSERT INTO @table
		SELECT @healthcarecode, @healthcaredesc, @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples WHERE @healthcarecode IS NOT NULL AND @healthcaredesc IS NOT NULL
	
		SET @i = @i + 1;
	END

	RETURN

END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[TurnaroundTimeNational]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TurnaroundTimeNational]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:		<Author,,Name>
-- ALTER date: <ALTER Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[TurnaroundTimeNational]
(
	-- Add the parameters for the function here
	@start_date varchar(20), @end_date varchar(20)
)
RETURNS @table TABLE(Location varchar(100), Collection_Received int, Received_Registered int, Registered_Analysis int, Analysis_Authorise int, Collection_Authorise int, N int)
AS
BEGIN

	DECLARE @i int
	DECLARE @labcode varchar(20)
	DECLARE @labname varchar(100)
	DECLARE @specimen_receivedate int
	DECLARE @receive_registereddate int
	DECLARE @analysis_authorisedate int 
	DECLARE @registered_analysisdate int
	DECLARE @specimen_authorisedate int
	DECLARE @numberSamples int


	SELECT 
			@specimen_receivedate    = iif(AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))   = 0, 1, AVG(DATEDIFF(day, SpecimenDatetime, ReceivedDateTime))), 
			@receive_registereddate  = iif(AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime)) = 0, 1, AVG(DATEDIFF(day, ReceivedDateTime, RegisteredDateTime))), 
			@registered_analysisdate = iif(AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime)) = 0, 1, AVG(DATEDIFF(day, RegisteredDateTime, AnalysisDateTime))),
			@analysis_authorisedate  = iif(AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime)) = 0, 1, AVG(DATEDIFF(day, AnalysisDateTime, AuthorisedDateTime))),
			@specimen_authorisedate  = isnull(@specimen_receivedate, 0) + isnull(@receive_registereddate, 0) + isnull(@registered_analysisdate, 0) + isnull(@analysis_authorisedate, 0),
			@numberSamples			 = COUNT(1)
	FROM VlData
	WHERE AnalysisDateTime >= @start_date AND AnalysisDateTime <= @end_date AND ViralLoadResultCategory IS NOT NULL 


	INSERT INTO @table
	SELECT ''National'', @specimen_receivedate, @receive_registereddate, @registered_analysisdate, @analysis_authorisedate, @specimen_authorisedate, @numberSamples -- WHERE @labcode IS NOT NULL AND @labname IS NOT NULL

	RETURN
END






' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[ufn_GetAgeGroupJSON]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ufn_GetAgeGroupJSON]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [dbo].[ufn_GetAgeGroupJSON] (@alias nvarchar(50))
RETURNS nvarchar(1000)
AS
BEGIN
RETURN REPLACE(N''{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365) IS NULL","then":"''''N '''''''' Especif.''''","alias":"'' + @alias + ''"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  < 2","then":"''''< 2 Anos''''","alias":"'' + @alias + ''"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  <= 5","then":"''''2-5 Anos''''","alias":"'' + @alias + ''"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  <= 14","then":"''''6-14 Anos''''","alias":"'' + @alias + ''"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  <= 49","then":"''''15-49 Anos''''","alias":"'' + @alias + ''"}
,{"when":"COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)  > 49","then":"''''>= 50 Anos''''","alias":"'' + @alias + ''"}
,{"else":"''''N '''''''' Especif.''''","alias":"'' + @alias + ''"}'', Char(13)+Char(10), '''')
END

' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[ufn_GetSexCodeJSON]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ufn_GetSexCodeJSON]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [dbo].[ufn_GetSexCodeJSON] (@alias nvarchar(50))
RETURNS nvarchar(1000)
AS
BEGIN
RETURN REPLACE(N''{"when":"Requests.HL7SexCode IN (''''M'''', ''''Masculino'''')","then":"''''Masculino''''","alias":"'' + @alias + ''"}
,{"when":"Requests.HL7SexCode IN (''''F'''', ''''Feminino'''')","then":"''''Feminino''''","alias":"'' + @alias + ''"}
,{"else":"''''Desconhecido''''","alias":"'' + @alias + ''"}'', Char(13)+Char(10), '''')
END

' 
END

GO
/****** Object:  Table [dbo].[DisaFacilities]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DisaFacilities]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DisaFacilities](
	[FacilityCode] [nvarchar](255) NULL,
	[FacilityDescription] [nvarchar](255) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Facilities]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Facilities]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Facilities](
	[MoH/DISA ProvinceName] [nvarchar](255) NULL,
	[MoH/DISA DistrictName] [nvarchar](255) NULL,
	[MoH/DISA HF Description] [nvarchar](255) NULL,
	[DISA FacilityCode] [nvarchar](255) NULL,
	[New DISA FacilityCode] [nvarchar](255) NULL,
	[HFStatus] [nvarchar](255) NULL,
	[F7] [nvarchar](255) NULL,
	[F8] [nvarchar](255) NULL,
	[F9] [nvarchar](255) NULL,
	[F10] [nvarchar](255) NULL,
	[F11] [nvarchar](255) NULL,
	[F12] [nvarchar](255) NULL,
	[F13] [nvarchar](255) NULL,
	[F14] [nvarchar](255) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[ViralLoadDatesOfUpdatesTable]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ViralLoadDatesOfUpdatesTable]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ViralLoadDatesOfUpdatesTable](
	[LastDateTimeStamp] [datetime] NULL,
	[DateTimeStamp] [timestamp] NULL,
	[UpdateSequenceID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[VlData]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VlData]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[VlData](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[RequestID] [varchar](26) NULL,
	[Versionstamp] [varchar](30) NULL,
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
	[DOBType] [varchar](25) NULL,
	[AgeInDays] [int] NULL,
	[HL7SexCode] [char](1) NULL,
	[SpecimenDatetime] [datetime] NULL,
	[ReceivedDateTime] [datetime] NULL,
	[RegisteredDateTime] [datetime] NULL,
	[AnalysisDateTime] [datetime] NULL,
	[AuthorisedDateTime] [datetime] NULL,
	[LIMSRejectionCode] [varchar](10) NULL,
	[LIMSRejectionDesc] [varchar](250) NULL,
	[LIMSDateTimeStamp] [datetime] NULL,
	[Newborn] [bit] NULL,
	[Pregnant] [varchar](80) NOT NULL,
	[BreastFeeding] [varchar](80) NOT NULL,
	[FirstTime] [varchar](80) NOT NULL,
	[CollectedDate] [varchar](80) NULL,
	[CollectedTime] [varchar](80) NULL,
	[DataDeInicioDoTARV] [varchar](80) NULL,
	[PrimeiraLinha] [varchar](80) NOT NULL,
	[SegundaLinha] [varchar](80) NOT NULL,
	[ARTRegimen] [varchar](80) NOT NULL,
	[TypeOfSampleCollection] [varchar](80) NOT NULL,
	[LastViralLoadDate] [varchar](80) NOT NULL,
	[LastViralLoadResult] [varchar](80) NOT NULL,
	[RequestingClinician] [varchar](80) NOT NULL,
	[LIMSVersionstamp] [varchar](30) NULL,
	[LOINCPanelCode] [varchar](10) NULL,
	[HL7PriorityCode] [char](1) NULL,
	[AdmitAttendDateTime] [datetime] NULL,
	[CollectionVolume] [float] NULL,
	[LIMSFacilityCode] [varchar](15) NULL,
	[LIMSFacilityName] [varchar](50) NULL,
	[LIMSProvinceName] [varchar](50) NULL,
	[LIMSDistrictName] [varchar](50) NULL,
	[RequestingFacilityCode] [varchar](15) NULL,
	[RequestingFacilityName] [varchar](50) NULL,
	[RequestingProvinceName] [varchar](50) NULL,
	[RequestingDistrictName] [varchar](50) NULL,
	[ReceivingFacilityCode] [varchar](10) NULL,
	[ReceivingFacilityName] [varchar](50) NULL,
	[ReceivingProvinceName] [varchar](50) NULL,
	[ReceivingDistrictName] [varchar](50) NULL,
	[TestingFacilityCode] [varchar](10) NULL,
	[TestingFacilityName] [varchar](50) NULL,
	[TestingProvinceName] [varchar](50) NULL,
	[TestingDistrictName] [varchar](50) NULL,
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
	[EncryptedPatientID] [varchar](20) NULL,
	[HL7EthnicGroupCode] [char](3) NULL,
	[Deceased] [bit] NULL,
	[HL7PatientClassCode] [char](1) NULL,
	[AttendingDoctor] [varchar](50) NULL,
	[ReferringRequestID] [varchar](25) NULL,
	[Therapy] [varchar](250) NULL,
	[LIMSAnalyzerCode] [varchar](10) NULL,
	[TargetTimeDays] [int] NULL,
	[TargetTimeMins] [int] NULL,
	[Repeated] [tinyint] NULL,
	[HIVVL_AuthorisedDateTime] [datetime] NULL,
	[HIVVL_LIMSRejectionCode] [varchar](10) NULL,
	[HIVVL_LIMSRejectionDesc] [varchar](250) NULL,
	[HIVVL_VRLogValue] [varchar](80) NULL,
	[ViralLoadResultCategory] [nvarchar](1024) NULL,
	[HIVVL_ViralLoadResult] [varchar](80) NULL,
	[HIVVL_ViralLoadCAPCTM] [varchar](80) NULL,
	[AgeGroup] [nvarchar](64) NULL,
	[AgeInYears] [int] NULL,
	[ReasonForTest] [nvarchar](64) NOT NULL,
	[RegisteredYearAndQuarter] [varchar](25) NOT NULL,
	[RegisteredYearAndMonth] [varchar](25) NOT NULL,
	[DateTimeStamp] [datetime] NULL,
	[HealthCareID] [varchar](20) NULL,
	[FullFacilityCode] [varchar](50) NULL,
 CONSTRAINT [PK_vldata] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VlDataTemp]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VlDataTemp]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[VlDataTemp](
	[RequestID] [varchar](26) NULL,
	[Versionstamp] [varchar](30) NULL,
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
	[DOBType] [varchar](25) NULL,
	[AgeInDays] [int] NULL,
	[HL7SexCode] [char](1) NULL,
	[SpecimenDatetime] [datetime] NULL,
	[ReceivedDateTime] [datetime] NULL,
	[RegisteredDateTime] [datetime] NULL,
	[AnalysisDateTime] [datetime] NULL,
	[AuthorisedDateTime] [datetime] NULL,
	[LIMSRejectionCode] [varchar](10) NULL,
	[LIMSRejectionDesc] [varchar](250) NULL,
	[LIMSDateTimeStamp] [datetime] NULL,
	[Newborn] [bit] NULL,
	[Pregnant] [varchar](80) NOT NULL,
	[BreastFeeding] [varchar](80) NOT NULL,
	[FirstTime] [varchar](80) NOT NULL,
	[CollectedDate] [varchar](80) NULL,
	[CollectedTime] [varchar](80) NULL,
	[DataDeInicioDoTARV] [varchar](80) NULL,
	[PrimeiraLinha] [varchar](80) NOT NULL,
	[SegundaLinha] [varchar](80) NOT NULL,
	[ARTRegimen] [varchar](80) NOT NULL,
	[TypeOfSampleCollection] [varchar](80) NOT NULL,
	[LastViralLoadDate] [varchar](80) NOT NULL,
	[LastViralLoadResult] [varchar](80) NOT NULL,
	[RequestingClinician] [varchar](80) NOT NULL,
	[LIMSVersionstamp] [varchar](30) NULL,
	[LOINCPanelCode] [varchar](10) NULL,
	[HL7PriorityCode] [char](1) NULL,
	[AdmitAttendDateTime] [datetime] NULL,
	[CollectionVolume] [float] NULL,
	[LIMSFacilityCode] [varchar](15) NULL,
	[LIMSFacilityName] [varchar](50) NULL,
	[LIMSProvinceName] [varchar](50) NULL,
	[LIMSDistrictName] [varchar](50) NULL,
	[RequestingFacilityCode] [varchar](15) NULL,
	[RequestingFacilityName] [varchar](50) NULL,
	[RequestingProvinceName] [varchar](50) NULL,
	[RequestingDistrictName] [varchar](50) NULL,
	[ReceivingFacilityCode] [varchar](10) NULL,
	[ReceivingFacilityName] [varchar](50) NULL,
	[ReceivingProvinceName] [varchar](50) NULL,
	[ReceivingDistrictName] [varchar](50) NULL,
	[TestingFacilityCode] [varchar](10) NULL,
	[TestingFacilityName] [varchar](50) NULL,
	[TestingProvinceName] [varchar](50) NULL,
	[TestingDistrictName] [varchar](50) NULL,
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
	[EncryptedPatientID] [varchar](20) NULL,
	[HL7EthnicGroupCode] [char](3) NULL,
	[Deceased] [bit] NULL,
	[HL7PatientClassCode] [char](1) NULL,
	[AttendingDoctor] [varchar](50) NULL,
	[ReferringRequestID] [varchar](25) NULL,
	[Therapy] [varchar](250) NULL,
	[LIMSAnalyzerCode] [varchar](10) NULL,
	[TargetTimeDays] [int] NULL,
	[TargetTimeMins] [int] NULL,
	[Repeated] [tinyint] NULL,
	[HIVVL_AuthorisedDateTime] [datetime] NULL,
	[HIVVL_LIMSRejectionCode] [varchar](10) NULL,
	[HIVVL_LIMSRejectionDesc] [varchar](250) NULL,
	[HIVVL_VRLogValue] [varchar](80) NULL,
	[ViralLoadResultCategory] [nvarchar](1024) NULL,
	[HIVVL_ViralLoadResult] [varchar](80) NULL,
	[HIVVL_ViralLoadCAPCTM] [varchar](80) NULL,
	[AgeGroup] [nvarchar](64) NULL,
	[AgeInYears] [int] NULL,
	[ReasonForTest] [nvarchar](64) NOT NULL,
	[RegisteredYearAndQuarter] [varchar](25) NOT NULL,
	[RegisteredYearAndMonth] [varchar](25) NOT NULL,
	[DateTimeStamp] [datetime] NULL,
	[HealthCareID] [varchar](20) NULL,
	[FullFacilityCode] [varchar](50) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VlLabs]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VlLabs]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[VlLabs](
	[LabID] [varchar](50) NULL,
	[LabName] [nvarchar](100) NULL,
	[Type] [varchar](50) NULL,
	[Province] [varchar](50) NULL,
	[ProvinceName] [varchar](50) NULL,
	[DateTimeStamp] [timestamp] NULL,
	[Lab] [varchar](50) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VlTemp]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VlTemp]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[VlTemp](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[RequestID] [varchar](26) NULL,
	[Versionstamp] [varchar](30) NULL,
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
	[DOBType] [varchar](25) NULL,
	[AgeInDays] [int] NULL,
	[HL7SexCode] [char](1) NULL,
	[SpecimenDatetime] [datetime] NULL,
	[ReceivedDateTime] [datetime] NULL,
	[RegisteredDateTime] [datetime] NULL,
	[AnalysisDateTime] [datetime] NULL,
	[AuthorisedDateTime] [datetime] NULL,
	[LIMSRejectionCode] [varchar](10) NULL,
	[LIMSRejectionDesc] [varchar](250) NULL,
	[LIMSDateTimeStamp] [datetime] NULL,
	[Newborn] [bit] NULL,
	[Pregnant] [varchar](80) NOT NULL,
	[BreastFeeding] [varchar](80) NOT NULL,
	[FirstTime] [varchar](80) NOT NULL,
	[CollectedDate] [varchar](80) NULL,
	[CollectedTime] [varchar](80) NULL,
	[DataDeInicioDoTARV] [varchar](80) NULL,
	[PrimeiraLinha] [varchar](80) NOT NULL,
	[SegundaLinha] [varchar](80) NOT NULL,
	[ARTRegimen] [varchar](80) NOT NULL,
	[TypeOfSampleCollection] [varchar](80) NOT NULL,
	[LastViralLoadDate] [varchar](80) NOT NULL,
	[LastViralLoadResult] [varchar](80) NOT NULL,
	[RequestingClinician] [varchar](80) NOT NULL,
	[LIMSVersionstamp] [varchar](30) NULL,
	[LOINCPanelCode] [varchar](10) NULL,
	[HL7PriorityCode] [char](1) NULL,
	[AdmitAttendDateTime] [datetime] NULL,
	[CollectionVolume] [float] NULL,
	[LIMSFacilityCode] [varchar](15) NULL,
	[LIMSFacilityName] [varchar](50) NULL,
	[LIMSProvinceName] [varchar](50) NULL,
	[LIMSDistrictName] [varchar](50) NULL,
	[RequestingFacilityCode] [varchar](15) NULL,
	[RequestingFacilityName] [varchar](50) NULL,
	[RequestingProvinceName] [varchar](50) NULL,
	[RequestingDistrictName] [varchar](50) NULL,
	[ReceivingFacilityCode] [varchar](10) NULL,
	[ReceivingFacilityName] [varchar](50) NULL,
	[ReceivingProvinceName] [varchar](50) NULL,
	[ReceivingDistrictName] [varchar](50) NULL,
	[TestingFacilityCode] [varchar](10) NULL,
	[TestingFacilityName] [varchar](50) NULL,
	[TestingProvinceName] [varchar](50) NULL,
	[TestingDistrictName] [varchar](50) NULL,
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
	[EncryptedPatientID] [varchar](20) NULL,
	[HL7EthnicGroupCode] [char](3) NULL,
	[Deceased] [bit] NULL,
	[HL7PatientClassCode] [char](1) NULL,
	[AttendingDoctor] [varchar](50) NULL,
	[ReferringRequestID] [varchar](25) NULL,
	[Therapy] [varchar](250) NULL,
	[LIMSAnalyzerCode] [varchar](10) NULL,
	[TargetTimeDays] [int] NULL,
	[TargetTimeMins] [int] NULL,
	[Repeated] [tinyint] NULL,
	[HIVVL_AuthorisedDateTime] [datetime] NULL,
	[HIVVL_LIMSRejectionCode] [varchar](10) NULL,
	[HIVVL_LIMSRejectionDesc] [varchar](250) NULL,
	[HIVVL_VRLogValue] [varchar](80) NULL,
	[ViralLoadResultCategory] [nvarchar](1024) NULL,
	[HIVVL_ViralLoadResult] [varchar](80) NULL,
	[HIVVL_ViralLoadCAPCTM] [varchar](80) NULL,
	[AgeGroup] [nvarchar](64) NULL,
	[AgeInYears] [int] NULL,
	[ReasonForTest] [nvarchar](64) NOT NULL,
	[RegisteredYearAndQuarter] [varchar](25) NOT NULL,
	[RegisteredYearAndMonth] [varchar](25) NOT NULL,
	[DateTimeStamp] [datetime] NULL,
	[HealthCareID] [varchar](20) NULL,
	[FullFacilityCode] [varchar](50) NULL,
 CONSTRAINT [PK_vltemp] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VlTempEPTS]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VlTempEPTS]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[VlTempEPTS](
	[RequestID] [varchar](26) NULL,
	[Versionstamp] [varchar](30) NULL,
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
	[DOBType] [varchar](25) NULL,
	[AgeInDays] [int] NULL,
	[HL7SexCode] [char](1) NULL,
	[SpecimenDatetime] [datetime] NULL,
	[ReceivedDateTime] [datetime] NULL,
	[RegisteredDateTime] [datetime] NULL,
	[AnalysisDateTime] [datetime] NULL,
	[AuthorisedDateTime] [datetime] NULL,
	[LIMSRejectionCode] [varchar](10) NULL,
	[LIMSRejectionDesc] [varchar](250) NULL,
	[LIMSDateTimeStamp] [datetime] NULL,
	[Newborn] [bit] NULL,
	[Pregnant] [varchar](80) NOT NULL,
	[BreastFeeding] [varchar](80) NOT NULL,
	[FirstTime] [varchar](80) NOT NULL,
	[CollectedDate] [varchar](80) NULL,
	[CollectedTime] [varchar](80) NULL,
	[DataDeInicioDoTARV] [varchar](80) NULL,
	[PrimeiraLinha] [varchar](80) NOT NULL,
	[SegundaLinha] [varchar](80) NOT NULL,
	[ARTRegimen] [varchar](80) NOT NULL,
	[TypeOfSampleCollection] [varchar](80) NOT NULL,
	[LastViralLoadDate] [varchar](80) NOT NULL,
	[LastViralLoadResult] [varchar](80) NOT NULL,
	[RequestingClinician] [varchar](80) NOT NULL,
	[LIMSVersionstamp] [varchar](30) NULL,
	[LOINCPanelCode] [varchar](10) NULL,
	[HL7PriorityCode] [char](1) NULL,
	[AdmitAttendDateTime] [datetime] NULL,
	[CollectionVolume] [float] NULL,
	[LIMSFacilityCode] [varchar](15) NULL,
	[LIMSFacilityName] [varchar](50) NULL,
	[LIMSProvinceName] [varchar](50) NULL,
	[LIMSDistrictName] [varchar](50) NULL,
	[RequestingFacilityCode] [varchar](15) NULL,
	[RequestingFacilityName] [varchar](50) NULL,
	[RequestingProvinceName] [varchar](50) NULL,
	[RequestingDistrictName] [varchar](50) NULL,
	[ReceivingFacilityCode] [varchar](10) NULL,
	[ReceivingFacilityName] [varchar](50) NULL,
	[ReceivingProvinceName] [varchar](50) NULL,
	[ReceivingDistrictName] [varchar](50) NULL,
	[TestingFacilityCode] [varchar](10) NULL,
	[TestingFacilityName] [varchar](50) NULL,
	[TestingProvinceName] [varchar](50) NULL,
	[TestingDistrictName] [varchar](50) NULL,
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
	[EncryptedPatientID] [varchar](20) NULL,
	[HL7EthnicGroupCode] [char](3) NULL,
	[Deceased] [bit] NULL,
	[HL7PatientClassCode] [char](1) NULL,
	[AttendingDoctor] [varchar](50) NULL,
	[ReferringRequestID] [varchar](25) NULL,
	[Therapy] [varchar](250) NULL,
	[LIMSAnalyzerCode] [varchar](10) NULL,
	[TargetTimeDays] [int] NULL,
	[TargetTimeMins] [int] NULL,
	[Repeated] [tinyint] NULL,
	[HIVVL_AuthorisedDateTime] [datetime] NULL,
	[HIVVL_LIMSRejectionCode] [varchar](10) NULL,
	[HIVVL_LIMSRejectionDesc] [varchar](250) NULL,
	[HIVVL_VRLogValue] [varchar](80) NULL,
	[ViralLoadResultCategory] [nvarchar](1024) NULL,
	[HIVVL_ViralLoadResult] [varchar](80) NULL,
	[HIVVL_ViralLoadCAPCTM] [varchar](80) NULL,
	[AgeGroup] [nvarchar](64) NULL,
	[AgeInYears] [int] NULL,
	[ReasonForTest] [nvarchar](64) NOT NULL,
	[RegisteredYearAndQuarter] [varchar](25) NOT NULL,
	[RegisteredYearAndMonth] [varchar](25) NOT NULL,
	[DateTimeStamp] [datetime] NULL,
	[HealthCareID] [varchar](20) NULL,
	[FullFacilityCode] [varchar](50) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[getPatientsVL_Vendor1_DateTimeStamp]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getPatientsVL_Vendor1_DateTimeStamp]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'-- ########################################################
CREATE FUNCTION [dbo].[getPatientsVL_Vendor1_DateTimeStamp] (@startDate Datetime2)
RETURNS TABLE
AS RETURN (
-- select * from dbo.[getVL_Vendor1_DateTimeStamp](''2016-09-01'',''2016-12-01'')
-- select * from dbo.[getVL_Vendor1_DateTimeStamp](''2016-01-01'',''2017-04-01'') 
-- The only difference with this function and the RegisteredDatetime function is the sub query selecting RequestIDs
-- So if you are changing one just copy it and change the three column instances 
-- 2-Oct-17 Brett Staib - Changed query to  get AnalysisDateTime and AuthorisedDateTime from HIVVL rather than from VIRAL panel
-- 7-Dec-17 Brett Staib - Changed the query do no longer have the sub query but instead do straight table joins 
--          It''s important to note that I use the table alias result for the view returning the actual test results however,
--          this query starts with requests and does a left join into LabResults so it may have Requests without results but it serves
--          as a list of all requests as well as containing any possible result data. I use this view as the primary list of requests
--          to return because there might not be a row in the Info query if it was missing the Viral query (which is common)
SELECT 	
 patients.[RequestID],patients.[Versionstamp],patients.[REFNO],patients.[REGISTEREDDATE],
 patients.[LOCATION],patients.[WARD],patients.[HOSPID],patients.[NATIONALITY],patients.[NATIONALID],
 patients.[UNIQUEID],patients.[SURNAME],patients.[FIRSTNAME],patients.[INITIALS],patients.[REFDRCODE],
 patients.[REFDR],patients.[MEDAID],patients.[MEDAIDNO],patients.[BILLACCNO],patients.[TELHOME],
 patients.[TELWORK],patients.[MOBILE],patients.[EMAIL],patients.[DOB],patients.[DOBType],
 result.AgeInDays, result.HL7SexCode,  result.SpecimenDatetime, result.ReceivedDateTime, result.RegisteredDateTime,
 result.AnalysisDateTime, result.AuthorisedDateTime, result.LIMSRejectionCode, result.LIMSRejectionDesc, result.LIMSDateTimeStamp, result.Newborn,
 IsNull(info.Pregnant,''Unreported'') AS Pregnant, IsNull(info.BreastFeeding,''Unreported'') AS BreastFeeding,
 IsNull(info.FirstTime,''Unreported'') AS FirstTime, info.CollectedDate, info.CollectedTime, info.DataDeInicioDoTARV, 
 IsNull(info.PrimeiraLinha, ''Unreported'') AS PrimeiraLinha, 
 IsNull(info.SegundaLinha,''Unreported'') AS SegundaLinha,
 IsNull(info.ARTRegimen, ''Unreported'') AS ARTRegimen, 
 IsNull(info.TypeOfSampleCollection,''Unreported'') AS TypeOfSampleCollection,
 IsNull(info.LastViralLoadDate, ''Unreported'') AS LastViralLoadDate, 
 IsNull(info.LastViralLoadResult,''Unreported'') AS LastViralLoadResult,
 IsNull(info.RequestingClinician, ''Unreported'') AS RequestingClinician, 
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
 OpenLDRData.[dbo].[ViralLoadResultRange] (HIVVL_ViralLoadResult, HIVVL_ViralLoadCAPCTM) AS ViralLoadResultCategory,
 result.HIVVL_ViralLoadResult, result.HIVVL_ViralLoadCAPCTM, 
 OpenLDRData.[dbo].[GetAgeGroup](result.AgeInYears) AS AgeGroup,
 result.AgeInYears,
 IsNull(info.ReasonForTest,''Reason Not Specified'') AS ReasonForTest,
 CONCAT(YEAR(result.RegisteredDateTime), ''-'', DatePart(QUARTER, result.RegisteredDateTime)) AS RegisteredYearAndQuarter,
 CONCAT(YEAR(result.RegisteredDateTime),''-'',Month(result.RegisteredDateTime)) AS RegisteredYearAndMonth,
 --- New Line
 IIF(info.DateTimeStamp IS NULL OR result.DateTimeStamp IS NULL, ISNULL(info.DateTimeStamp,result.DateTimeStamp), IIF(info.DateTimeStamp < result.DateTimeStamp, info.DateTimeStamp, result.DateTimeStamp)) AS DateTimeStamp,
 dbo.[getHealthCareCode] (result.RequestingFacilityCode) AS HealthcareDistrictCode
FROM
-- First get a listing of all RequestIDs that look like they had an actual viral load test requested
dbo.getRequestIDsWithUpdatedDateTimeStamp(@startDate) AS mainRequests
INNER JOIN OpenLDRData.dbo.Patients AS patients ON mainRequests.RequestID = patients.RequestID
LEFT JOIN OpenLDRData.dbo.viewVL_Result AS result ON mainRequests.RequestID = result.RequestID 
LEFT JOIN OpenLDRData.dbo.viewVL_Info AS info ON result.RequestID = info.RequestID -- AND result.OBRSetID = info.OBRSetID
)


' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getVL_by_DateTimeStamp]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getVL_by_DateTimeStamp]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [dbo].[getVL_by_DateTimeStamp] (@startDate datetime, @endDate datetime)
RETURNS TABLE
AS RETURN (
-- 2-Oct-17 Brett Staib - Changed query to  get AnalysisDateTime and AuthorisedDateTime from HIVVL rather than from VIRAL panel
SELECT 	mainRequests.RequestID, result.AgeInDays, result.HL7SexCode, result.SpecimenDatetime, result.ReceivedDateTime, result.RegisteredDateTime,
 result.AnalysisDateTime, result.AuthorisedDateTime, result.LIMSRejectionCode, result.LIMSRejectionDesc, result.LIMSDateTimeStamp, result.Newborn,
 IsNull(info.Pregnant,''Unreported'') AS Pregnant, IsNull(info.BreastFeeding,''Unreported'') AS BreastFeeding,
 IsNull(info.FirstTime,''Unreported'') AS FirstTime, info.CollectedDate, info.CollectedTime, info.DataDeInicioDoTARV, 
 IsNull(info.PrimeiraLinha, ''Unreported'') AS PrimeiraLinha, 
 IsNull(info.SegundaLinha,''Unreported'') AS SegundaLinha,
 IsNull(info.ARTRegimen, ''Unreported'') AS ARTRegimen, 
 IsNull(info.TypeOfSampleCollection,''Unreported'') AS TypeOfSampleCollection,
 IsNull(info.LastViralLoadDate, ''Unreported'') AS LastViralLoadDate, 
 IsNull(info.LastViralLoadResult,''Unreported'') AS LastViralLoadResult,
 IsNull(info.RequestingClinician, ''Unreported'') AS RequestingClinician, 
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
 OpenLDRData.dbo.[ViralLoadResultRange] (HIVVL_ViralLoadResult, HIVVL_ViralLoadCAPCTM) AS ViralLoadResultCategory,
 result.HIVVL_ViralLoadResult, result.HIVVL_ViralLoadCAPCTM, 
 OpenLDRData.dbo.[GetAgeGroup](result.AgeInYears) AS AgeGroup,
 result.AgeInYears,
 IsNull(info.ReasonForTest,''Reason Not Specified'') AS ReasonForTest,
 CONCAT(YEAR(result.RegisteredDateTime), ''-'', DatePart(QUARTER, result.RegisteredDateTime)) AS RegisteredYearAndQuarter,
 CONCAT(YEAR(result.RegisteredDateTime),''-'',Month(result.RegisteredDateTime)) AS RegisteredYearAndMonth,
 mainRequests.DateTimeStamp,
 dbo.[getHealthCareCode] (result.RequestingFacilityCode) AS HealthcareDistrictCode
FROM
-- First get a listing of all RequestIDs that look like they had an actual viral load test requested
(
    SELECT DISTINCT Requests.RequestId, labResults.DateTimeStamp
    FROM OpenLDRData.dbo.Requests AS Requests LEFT JOIN OpenLDRData.dbo.LabResults AS labResults ON Requests.RequestID = labResults.RequestID AND Requests.OBRSetID = LabResults.OBRSetID
    WHERE (
            (Requests.LIMSPanelCode = ''VIRAL'')
            OR (Requests.LIMSPanelCode = ''HIVVL'')
        )
	 AND (
		(Requests.DateTimeStamp >= @startDate AND Requests.DateTimeStamp < @endDate)
		OR
		(LabResults.DateTimeStamp Is Not Null AND LabResults.DateTimeStamp >= @startDate AND LabResults.DateTimeStamp < @endDate)
		)
) AS mainRequests
	LEFT JOIN OpenLDRData.dbo.viewVL_Info AS info ON mainRequests.RequestID = info.RequestID
	LEFT JOIN OpenLDRData.dbo.viewVL_Result AS result ON mainRequests.RequestID = result.RequestID
)




' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getVL_Vendor1_DateTimeStamp]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getVL_Vendor1_DateTimeStamp]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'-- ########################################################
CREATE FUNCTION [dbo].[getVL_Vendor1_DateTimeStamp] (@startDate Datetime2)
RETURNS TABLE
AS RETURN (
-- select * from dbo.[getVL_Vendor1_DateTimeStamp](''2016-09-01'',''2016-12-01'')
-- select * from dbo.[getVL_Vendor1_DateTimeStamp](''2016-01-01'',''2017-04-01'') 
-- The only difference with this function and the RegisteredDatetime function is the sub query selecting RequestIDs
-- So if you are changing one just copy it and change the three column instances 
-- 2-Oct-17 Brett Staib - Changed query to  get AnalysisDateTime and AuthorisedDateTime from HIVVL rather than from VIRAL panel
-- 7-Dec-17 Brett Staib - Changed the query do no longer have the sub query but instead do straight table joins 
--          It''s important to note that I use the table alias result for the view returning the actual test results however,
--          this query starts with requests and does a left join into LabResults so it may have Requests without results but it serves
--          as a list of all requests as well as containing any possible result data. I use this view as the primary list of requests
--          to return because there might not be a row in the Info query if it was missing the Viral query (which is common)
SELECT 	mainRequests.RequestID, result.AgeInDays, result.HL7SexCode,  result.SpecimenDatetime, result.ReceivedDateTime, result.RegisteredDateTime,
 result.AnalysisDateTime, result.AuthorisedDateTime, result.LIMSRejectionCode, result.LIMSRejectionDesc, result.LIMSDateTimeStamp, result.Newborn,
 IsNull(info.Pregnant,''Unreported'') AS Pregnant, IsNull(info.BreastFeeding,''Unreported'') AS BreastFeeding,
 IsNull(info.FirstTime,''Unreported'') AS FirstTime, info.CollectedDate, info.CollectedTime, info.DataDeInicioDoTARV, 
 IsNull(info.PrimeiraLinha, ''Unreported'') AS PrimeiraLinha, 
 IsNull(info.SegundaLinha,''Unreported'') AS SegundaLinha,
 IsNull(info.ARTRegimen, ''Unreported'') AS ARTRegimen, 
 IsNull(info.TypeOfSampleCollection,''Unreported'') AS TypeOfSampleCollection,
 IsNull(info.LastViralLoadDate, ''Unreported'') AS LastViralLoadDate, 
 IsNull(info.LastViralLoadResult,''Unreported'') AS LastViralLoadResult,
 IsNull(info.RequestingClinician, ''Unreported'') AS RequestingClinician, 
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
 OpenLDRData.[dbo].[ViralLoadResultRange] (HIVVL_ViralLoadResult, HIVVL_ViralLoadCAPCTM) AS ViralLoadResultCategory,
 result.HIVVL_ViralLoadResult, result.HIVVL_ViralLoadCAPCTM, 
 OpenLDRData.[dbo].[GetAgeGroup](result.AgeInYears) AS AgeGroup,
 result.AgeInYears,
 IsNull(info.ReasonForTest,''Reason Not Specified'') AS ReasonForTest,
 CONCAT(YEAR(result.RegisteredDateTime), ''-'', DatePart(QUARTER, result.RegisteredDateTime)) AS RegisteredYearAndQuarter,
 CONCAT(YEAR(result.RegisteredDateTime),''-'',Month(result.RegisteredDateTime)) AS RegisteredYearAndMonth,
 --- New Line
 IIF(info.DateTimeStamp IS NULL OR result.DateTimeStamp IS NULL, ISNULL(info.DateTimeStamp,result.DateTimeStamp), IIF(info.DateTimeStamp < result.DateTimeStamp, info.DateTimeStamp, result.DateTimeStamp)) AS DateTimeStamp,
 dbo.[getHealthCareCode] (result.RequestingFacilityCode) AS HealthcareDistrictCode
FROM
-- First get a listing of all RequestIDs that look like they had an actual viral load test requested
dbo.getRequestIDsWithUpdatedDateTimeStamp(@startDate) AS mainRequests
INNER JOIN OpenLDRData.dbo.viewVL_Result AS result ON mainRequests.RequestID = result.RequestID 
LEFT JOIN OpenLDRData.dbo.viewVL_Info AS info ON result.RequestID = info.RequestID -- AND result.OBRSetID = info.OBRSetID
)


' 
END

GO
/****** Object:  UserDefinedFunction [dbo].[getVL_Vendor1_WithPatients_DateTimeStamp]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[getVL_Vendor1_WithPatients_DateTimeStamp]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'-- ########################################################
CREATE FUNCTION [dbo].[getVL_Vendor1_WithPatients_DateTimeStamp] (@startDate Datetime2)
RETURNS TABLE
AS RETURN (
-- select * from dbo.[getVL_Vendor1_DateTimeStamp](''2016-09-01'',''2016-12-01'')
-- select * from dbo.[getVL_Vendor1_DateTimeStamp](''2016-01-01'',''2017-04-01'') 
-- The only difference with this function and the RegisteredDatetime function is the sub query selecting RequestIDs
-- So if you are changing one just copy it and change the three column instances 
-- 2-Oct-17 Brett Staib - Changed query to  get AnalysisDateTime and AuthorisedDateTime from HIVVL rather than from VIRAL panel
-- 7-Dec-17 Brett Staib - Changed the query do no longer have the sub query but instead do straight table joins 
--          It''s important to note that I use the table alias result for the view returning the actual test results however,
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
 IsNull(info.Pregnant,''Unreported'') AS Pregnant, IsNull(info.BreastFeeding,''Unreported'') AS BreastFeeding,
 IsNull(info.FirstTime,''Unreported'') AS FirstTime, info.CollectedDate, info.CollectedTime, info.DataDeInicioDoTARV, 
 IsNull(info.PrimeiraLinha, ''Unreported'') AS PrimeiraLinha, 
 IsNull(info.SegundaLinha,''Unreported'') AS SegundaLinha,
 IsNull(info.ARTRegimen, ''Unreported'') AS ARTRegimen, 
 IsNull(info.TypeOfSampleCollection,''Unreported'') AS TypeOfSampleCollection,
 IsNull(info.LastViralLoadDate, ''Unreported'') AS LastViralLoadDate, 
 IsNull(info.LastViralLoadResult,''Unreported'') AS LastViralLoadResult,
 IsNull(info.RequestingClinician, ''Unreported'') AS RequestingClinician, 
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
 LDRDataTemp.[dbo].[ViralLoadResultRange] (HIVVL_ViralLoadResult, HIVVL_ViralLoadCAPCTM) AS ViralLoadResultCategory,
 result.HIVVL_ViralLoadResult, result.HIVVL_ViralLoadCAPCTM, 
 LDRDataTemp.[dbo].[GetAgeGroup](result.AgeInYears) AS AgeGroup,
 result.AgeInYears,
 IsNull(info.ReasonForTest,''Reason Not Specified'') AS ReasonForTest,
 CONCAT(YEAR(result.RegisteredDateTime), ''-'', DatePart(QUARTER, result.RegisteredDateTime)) AS RegisteredYearAndQuarter,
 CONCAT(YEAR(result.RegisteredDateTime),''-'',Month(result.RegisteredDateTime)) AS RegisteredYearAndMonth,
 --- New Line
 IIF(info.DateTimeStamp IS NULL OR result.DateTimeStamp IS NULL, ISNULL(info.DateTimeStamp,result.DateTimeStamp), IIF(info.DateTimeStamp < result.DateTimeStamp, info.DateTimeStamp, result.DateTimeStamp)) AS DateTimeStamp,
 dbo.[getHealthCareCode] (result.RequestingFacilityCode) AS HealthcareDistrictCode,
 --result.RequestingFacilityCode AS FullHealthCareID
 fac.HealthCareID AS FullHealthCareID
FROM
-- First get a listing of all RequestIDs that look like they had an actual viral load test requested
dbo.getRequestIDsWithUpdatedDateTimeStamp(@startDate) AS mainRequests
INNER JOIN LDRDataTemp.dbo.Patients AS patients ON patients.RequestID = mainRequests.RequestID
LEFT JOIN LDRDataTemp.dbo.viewVL_Result AS result ON mainRequests.RequestID = result.RequestID 
LEFT JOIN LDRDataTemp.dbo.viewVL_Info AS info ON result.RequestID = info.RequestID -- AND result.OBRSetID = info.OBRSetID
LEFT JOIN OpenLDRDict.dbo.Facilities AS fac ON fac.FacilityCode = result.RequestingFacilityCode OR fac.FacilityCode = info.RequestingFacilityCode
)

' 
END

GO
/****** Object:  View [dbo].[viewHealthCareSites]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[viewHealthCareSites]'))
EXEC dbo.sp_executesql @statement = N'




-- select * from OpenLDRDict.[dbo].[viewFacilities] 
CREATE VIEW [dbo].[viewHealthCareSites]
AS 

SELECT 
	LEFT(province.HealthcareAreaCode, 2) AS Country,
	LEFT(province.HealthcareAreaCode, 4) AS ProvinceCode,
	province.HealthcareAreaDesc          AS ProvinceName, 
	districts.HealthcareAreaCode         AS DistrictCode, 
	districts.HealthcareAreaDesc		 AS DistrictName,
	clinics.FacilityCode                 AS OldFacilityCode, 
	clinics.HealthCareID				 AS ClinicCode,
	clinics.Description					 AS ClinicName,
	iif(disa.FacilityDescription IS NOT NULL, ''Yes'', ''No'') AS ''DisaLink''
FROM
	(SELECT * FROM OpenLDRDict.dbo.HealthcareAreas WHERE HealthcareAreaCode LIKE ''MZ%'' AND LEN(HealthcareAreaCode) = 4) AS province
	LEFT JOIN OpenLDRDict.dbo.HealthcareAreas AS districts ON districts.HealthcareAreaCode LIKE ''MZ%'' AND LEN(districts.HealthcareAreaCode) > 4 AND LEFT(districts.HealthcareAreaCode,4) = province.HealthcareAreaCode
	LEFT JOIN OpenLDRDict.dbo.viewFacilities AS clinics ON clinics.HealthcareDistrictCode = districts.HealthcareAreaCode 
	LEFT JOIN DisaFacilities AS disa ON disa.FacilityCode = clinics.FacilityCode



' 
GO
/****** Object:  View [dbo].[viewVLData]    Script Date: 8/14/2019 11:47:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[viewVLData]'))
EXEC dbo.sp_executesql @statement = N'


-- select * from OpenLDRDict.[dbo].[viewFacilities] 
CREATE VIEW [dbo].[viewVLData]
AS 

SELECT [RequestID]
      ,[AgeInDays]
      ,[HL7SexCode]
      ,[SpecimenDatetime]
      ,[ReceivedDateTime]
      ,[RegisteredDateTime]
      ,[AnalysisDateTime]
      ,[AuthorisedDateTime]
      ,[LIMSRejectionCode]
      ,[LIMSRejectionDesc]
      ,[LIMSDateTimeStamp]
      ,[Newborn]
      ,[Pregnant]
      ,[BreastFeeding]
      ,[FirstTime]
      ,[CollectedDate]
      ,[CollectedTime]
      ,[DataDeInicioDoTARV]
      ,[PrimeiraLinha]
      ,[SegundaLinha]
      ,[ARTRegimen]
      ,[TypeOfSampleCollection]
      ,[LastViralLoadDate]
      ,[LastViralLoadResult]
      ,[RequestingClinician]
      ,[LIMSVersionstamp]
      ,[LOINCPanelCode]
      ,[HL7PriorityCode]
      ,[AdmitAttendDateTime]
      ,[CollectionVolume]
      ,[LIMSFacilityCode]
      ,[LIMSFacilityName]
      ,[LIMSProvinceName]
      ,[LIMSDistrictName]
      ,[RequestingFacilityCode]
      ,[RequestingFacilityName]
      ,[RequestingProvinceName]
      ,[RequestingDistrictName]
      ,[ReceivingFacilityCode]
      ,[ReceivingFacilityName]
      ,[ReceivingProvinceName]
      ,[ReceivingDistrictName]
      ,[TestingFacilityCode]
      ,[TestingFacilityName]
      ,[TestingProvinceName]
      ,[TestingDistrictName]
      ,[LIMSPointOfCareDesc]
      ,[RequestTypeCode]
      ,[ICD10ClinicalInfoCodes]
      ,[ClinicalInfo]
      ,[HL7SpecimenSourceCode]
      ,[LIMSSpecimenSourceCode]
      ,[LIMSSpecimenSourceDesc]
      ,[HL7SpecimenSiteCode]
      ,[LIMSSpecimenSiteCode]
      ,[LIMSSpecimenSiteDesc]
      ,[WorkUnits]
      ,[CostUnits]
      ,[HL7SectionCode]
      ,[HL7ResultStatusCode]
      ,[RegisteredBy]
      ,[TestedBy]
      ,[AuthorisedBy]
      ,[OrderingNotes]
      ,[EncryptedPatientID]
      ,[HL7EthnicGroupCode]
      ,[Deceased]
      ,[HL7PatientClassCode]
      ,[AttendingDoctor]
      ,[ReferringRequestID]
      ,[Therapy]
      ,[LIMSAnalyzerCode]
      ,[TargetTimeDays]
      ,[TargetTimeMins]
      ,[Repeated]
      ,[HIVVL_AuthorisedDateTime]
      ,[HIVVL_LIMSRejectionCode]
      ,[HIVVL_LIMSRejectionDesc]
      ,[HIVVL_VRLogValue]
      ,[ViralLoadResultCategory]
      ,[HIVVL_ViralLoadResult]
      ,[HIVVL_ViralLoadCAPCTM]
      ,[AgeGroup]
      ,[AgeInYears]
      ,[ReasonForTest]
      ,[RegisteredYearAndQuarter]
      ,[RegisteredYearAndMonth]
      ,[DateTimeStamp]
      ,[HealthCareID]
      ,[FullFacilityCode]
  FROM [ViralLoadData].[dbo].[VlData]



' 
GO
