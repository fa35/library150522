-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis


-- check existing signature

USE [Library]
GO
CREATE FUNCTION CheckSignature (@signatur varchar(10))
RETURNS BIT
AS
BEGIN
	DECLARE @count INT = (SELECT COUNT(*) FROM Exemplare WHERE p_signatur = @signatur)
	DECLARE @exists BIT = 0;
	
	IF(@count > 0)
	BEGIN
		SET @exists = 1
	END

	RETURN @exists
END
GO

-- get number as varchar with zeros

USE[Library]
GO
CREATE FUNCTION GetNumber (@anzahl int)
RETURNS varchar(4)
AS
BEGIN
	DECLARE @nummer varchar(4) = '0001';
	IF (@anzahl > 0)
		BEGIN
			IF @anzahl <= 9
				BEGIN
					SET @nummer = ('000' + @anzahl);
				END
			ELSE IF @anzahl >= 10 and @anzahl < 100
				BEGIN
					SET @nummer = ('00' + @anzahl); 
				END
			ELSE IF @anzahl >= 100 and @anzahl < 1000
				BEGIN
					SET @nummer = ('0' + @anzahl);
				END
			ELSE
				BEGIN 
					SET @nummer = @anzahl
				END
	   END
RETURN @nummer
END
GO

-- create new signature

USE[Library]
GO
CREATE FUNCTION CreateSignature (@fachgebietId int, @isbn bigint)
RETURNS varchar(10)
AS
BEGIN
DECLARE @kuerzel varchar(3) = (select SUBSTRING(kuerzel, 1, 3) from Fachgebiete where p_fachgebiet_id = @fachgebietId)
DECLARE @name varchar(1) = (select SUBSTRING(name, 1,1) from Autoren where p_autor_id = (select pf_autor_id from Buecher_Autoren where pf_isbn = @isbn))
DECLARE @anzahl int = (select count(*) from Exemplare where f_ISBN = @isbn);

DECLARE @sig varchar(10), @nummer varchar(4), @exists bit = 1;

WHILE @exists = 1
	BEGIN
		SET @nummer = Library.dbo.GetNumber (@anzahl)

		IF (@kuerzel IS NULL) OR (@name IS NULL)
		BEGIN
			SET @kuerzel = 'UNK' -- UNK = unknown
			SET @name = 'N'
		END

		SET @sig = (@kuerzel + @name + @nummer) 
		SET @exists = dbo.CheckSignature (@sig) -- 1 = signature exists / 0 = signature not exists
		SET @anzahl = (@anzahl + 1)
	END

	RETURN @sig
END
GO

-- get mitarbeiter recht

USE[Library]
GO
CREATE FUNCTION GetMitarbeiterRecht (@ausweisNr int)
RETURNS bit
AS
BEGIN
	DECLARE @personenId int = (select pf_personen_id from Ausweise where ausweisnr = @ausweisNr), @bit bit = 0;
	IF (@personenId >= 1)
		BEGIN
			SET @bit = (SELECT mitarbeiter FROM Nutzer WHERE p_personen_id = @personenId)
		END
	RETURN @bit
END
GO

-- create new exemplar

USE[Library]
GO
CREATE PROCEDURE sp_CreateExemplar @ausweisNr int, @isbn bigint
AS

DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr)
	IF (@mitarbeiter = 0)
		BEGIN 
			PRINT 'Sie sind nicht berechtigt'
		END
	ELSE
		BEGIN
			DECLARE @fachgebiet int = (select f_fachgebiet_id from Buecher where p_ISBN = @isbn)
			DECLARE @signature varchar(10) = dbo.CreateSignature(@fachgebiet, @isbn);

			IF(@signature IS NULL OR LEN(@signature) < 10)
			BEGIN
				DECLARE @anzExem int = ((select  count(*) from Exemplare) +1)
				SET @signature = 'UNKN' + @anzExem
			END
			INSERT INTO [Exemplare] ([p_signatur], [f_ISBN]) VALUES (@signature, @isbn)
		END
GO

-- check if exempar is ausgeliehen

USE[Library]
GO
CREATE FUNCTION CheckExemparAusgeliehen (@signatur varchar(10))
RETURNS BIT
AS
BEGIN
	DECLARE @anzahl int = (SELECT COUNT(*) FROM Ausgeliehene_Exemplare WHERE pf_signatur = @signatur)
	DECLARE @ausgeliehen bit = 0 -- 0 = nicht ausgeliehen
	IF(@anzahl > 0)
		BEGIN
			SET @ausgeliehen = 1
		END
	RETURN @ausgeliehen
END
GO

-- delete exemplar

USE[Library]
GO
CREATE PROCEDURE sp_DeleteExemplar @ausweisNr int, @signatur varchar(10)
AS
DECLARE @mitarbeiter bit = dbo.GetMitarbeiterRecht(@ausweisNr)
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		DECLARE @existing bit = Library.dbo.CheckExemparAusgeliehen(@signatur)

		IF(@existing > 0)
			BEGIN
				PRINT 'Das Exemplar ist ausgeliehen - kann somit nicht gelöscht werden'
			END
		ELSE
			BEGIN
				DELETE FROM Exemplare WHERE p_signatur = @signatur
			END
	END
GO
