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


-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- create new user and cause it's a new user, create new ausweis

USE[Library]
GO
CREATE PROCEDURE sp_CreateNutzer @ausweisNr int, @nutzer bit, @vorname nvarchar(max),
           @name nvarchar(max), @geburtsdatum date, @kontostand SMALLINT, @passwort varchar(16)
AS
DECLARE @mitarbeiter bit = dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		DECLARE @personenId int = ((select max(p_personen_id) from nutzer) + 1);
		INSERT INTO [dbo].[Nutzer] ([p_personen_id], [mitarbeiter], [vorname], [name], [geburtsdatum], [kontostand])
		 VALUES
			   (@personenId, @nutzer, @vorname, @name, @geburtsdatum, @kontostand)

		-- create new ausweis for this user
		DECLARE @ausweis int = ((select max(ausweisnr) from ausweise) + 1);
		INSERT INTO [dbo].[Ausweise]
				   ([pf_personen_id], [ausweisnr], [passwort], [gueltigBis], [gesperrt])
			 VALUES
				   (@personenId, @ausweis, @passwort, DATEADD(year, 2, getdate()), 0)
	END
GO

--- delete user, ausweis, preordered books, if there are no books ausgeliehen

USE[Library]
GO
CREATE PROCEDURE sp_DeleteNutzer @ausweisNr int, @personenId int
AS
DECLARE @mitarbeiter bit = dbo.GetMitarbeiterBit(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		-- prüfe ob es noch ausgeliehene exemplare gibt:
		DECLARE @ausgelieheneExemplare int = (SELECT COUNT(*) FROM Ausgeliehene_Exemplare WHERE pf_personen_id = @personenId)
		IF(@ausgelieheneExemplare <= 0)
			BEGIN
				DELETE FROM Ausweise WHERE pf_personen_id = @personenId
				DELETE FROM Vorbestellte_Buecher WHERE pf_personen_id = @personenId
				DELETE FROM Nutzer WHERE p_personen_id = @personenId
			END
		ELSE
			BEGIN
				PRINT 'Es sind noch Exemplare ausgeliehen'
			END
	END
GO


-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis


-- Funktion GetMitarbeiterBit notwendig

USE [Library]
GO
CREATE PROCEDURE sp_CreateBook @ausweisNr int, @isbn bigint, @titel nvarchar(max), @fachgebietId int
AS

DECLARE @mitarbeiter bit;
SET @mitarbeiter = dbo.GetMitarbeiterRecht(@ausweisNr)

IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
INSERT INTO [dbo].[Buecher] ([p_ISBN], [titel], [f_fachgebiet_id])
     VALUES
           (@isbn, @titel, @fachgebietId)
	END
GO

-- ge anzahl ausgeliehener exemplare

USE[Library]
GO
CREATE FUNCTION GetAnzahlAusgeliehenerExemplare (@isbn bigint)
RETURNS int
AS
BEGIN
	return( select count (*) from Ausgeliehene_Exemplare where pf_signatur in ( 
			select p_signatur from exemplare where f_ISBN = @isbn)
		   )
END
GO

-- weitere Funktion zu Löschen benötigt: getAnzahlAusgeliehenerExemplare

USE [Library]
GO
CREATE PROCEDURE sp_DeleteBook @ausweisNr int, @isbn bigint
AS
IF (dbo.GetMitarbeiterRecht(@ausweisNr) = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		DECLARE @anzahlAusgeliehenerExemplare int = Library.dbo.GetAnzahlAusgeliehenerExemplare(@isbn)
		IF (@anzahlAusgeliehenerExemplare <> 0)
			BEGIN
				PRINT 'Es sind noch Exemplare ausgeliehen'
			END
		ELSE
		BEGIN
			DELETE FROM [Buecher] WHERE p_ISBN = @isbn
		END
	END
GO


-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- create new autor

USE [Library]
GO
CREATE PROCEDURE sp_CreateAutor @ausweisNr int, @vorname nvarchar(max), @nachname nvarchar(max)
AS
IF (dbo.GetMitarbeiterBit(@ausweisNr) = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
BEGIN
INSERT INTO [dbo].[Autoren] ([p_autor_id] ,[vorname] ,[name])
     VALUES
           (((select count(*) from Autoren) +1), @vorname, @nachname)
END
GO

-- delete existing autor

USE [Library]
GO
CREATE PROCEDURE sp_DeleteAutor @ausweisNr int, @autorId int
AS
IF (dbo.GetMitarbeiterRecht(@ausweisNr) = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
BEGIN
-- prüfe ob es noch buecher mit diesem autoren gibt
DECLARE @anzBuecher int = (select count(*) from Buecher where p_ISBN in (
							SELECT pf_isbn FROM Buecher_Autoren WHERE pf_autor_id = @autorId)
							)
IF(@anzBuecher > 0)
BEGIN
	--prüfe ob die buecher noch andere autoren haben
	DECLARE @anzBuchMitAnderenAutoren int = 
	(
		select count(*) from Buecher_Autoren where pf_ISBN in 
		(
			select p_ISBN from Buecher where p_ISBN in (
			SELECT pf_isbn FROM Buecher_Autoren WHERE pf_autor_id = @autorId)
		)
		and pf_isbn not in (SELECT pf_isbn FROM Buecher_Autoren WHERE pf_autor_id = @autorId)
	)

	IF(@anzBuchMitAnderenAutoren <= 0)
	BEGIN
		-- buch kann geloescht werden, da autor nicht mehr existiert
		DECLARE @newAnz int = (select count(*) from Buecher where p_ISBN in (SELECT pf_isbn FROM Buecher_Autoren WHERE pf_autor_id = @autorId))
		WHILE ( @newAnz > 0 )
		BEGIN
			DECLARE @theIsbn bigint = (SELECT Top(1) pf_isbn FROM Buecher_Autoren WHERE pf_autor_id = @autorId)
			EXEC sp_DeleteBook @ausweisNr, @theIsbn
				-- buch - autor referenz loeschen
			DELETE FROM Buecher_Autoren Where pf_isbn = @theIsbn
			SET @newAnz = (select count(*) from Buecher where p_ISBN in (SELECT pf_isbn FROM Buecher_Autoren WHERE pf_autor_id = @autorId))
		END
	END
	ELSE
	BEGIN
		-- buch - autor referenz loeschen
		DELETE FROM Buecher_Autoren Where pf_autor_id = @autorID
	END
END
-- autor loeschen
DELETE FROM Autoren WHERE p_autor_id = @autorId
END
GO

-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- check ausweis gesperrt

USE[Library]
GO
CREATE FUNCTION CheckAusweisGesperrt (@personenId int)
RETURNS BIT
AS
BEGIN
	RETURN (select gesperrt from Ausweise where pf_personen_id = @personenId);
END
GO

-- check ueberfaellige exemplare

USE[Library]
GO
CREATE FUNCTION CheckUeberfaelligeExemplare(@personenId int)
RETURNS BIT
AS
BEGIN
	DECLARE @cnt int = ( select count(*) from Ausgeliehene_Exemplare 
			where pf_personen_id = @personenId and rueckgabe_datum <= GETDATE()
			)
	IF(@cnt = 0)
	BEGIN
		RETURN 0
	END
	RETURN 1
END

-- check kontolimit: if limit > 10000 (100 Geldeinheiten) => limit ueberschritten

USE[Library]
GO
CREATE FUNCTION CheckKontolimit (@personenId int)
RETURNS BIT
AS
BEGIN
	DECLARE @result bit = 0
	DECLARE @kontostand SMALLINT = (select kontostand from nutzer where p_personen_id = @personenId)
	IF(@kontostand < 10000)
		BEGIN
			SET @result = 1;
		END
	RETURN @result;
END
GO


-- leihe exemplar aus
-- waere viel schoener alle bindungen auszulagern

USE[Library]
GO
CREATE PROCEDURE sp_LeiheExemplarAus (@isbn bigint, @ausweisNr int, @name nvarchar(max))
AS
DECLARE @signatur varchar(10) = (select Top(1) p_signatur from Exemplare where f_ISBN = @isbn and p_signatur not in (select pf_signatur from Ausgeliehene_Exemplare )) -- = signatur des exemplares
DECLARE @personenId INT = (select pf_personen_id from Ausweise where ausweisnr = @ausweisNr)
-- ausweis gültig
DECLARE @b bit = Library.dbo.CheckAusweisGesperrt(@personenId)

IF(@b = 1)
BEGIN
	PRINT 'Der Ausweis ist gesperrt'
END
ELSE
BEGIN
	-- keine überfälligen buecher
	select * from Ausgeliehene_Exemplare
	SET @b = Library.dbo.CheckUeberfaelligeExemplare(@personenId)

	IF(@b = 1)
		BEGIN
			PRINT 'Es sind noch Bücher fällig'
		END
	ELSE
	BEGIN
		-- check konto
		SET @b = Library.dbo.CheckKontolimit(@personenId) -- kontolimit > 0 => kontolimit ueberschritten

		IF(@b = 0)
			BEGIN
				PRINT 'Der Kontostand ist ueber 100 Geldeinheiten'
			END
		ELSE
		BEGIN
			-- anzahl der ausge. exempolare max. 10 , davo max. 1 pro buch
			DECLARE @count int = (select count(*) from Ausgeliehene_Exemplare where pf_personen_id = @personenId) 

			IF(@count >= 10)
			BEGIN
				PRINT 'Es sind schon 10 oder mehr Exemplare ausgeliehen'
			END
			ELSE
			BEGIN
			-- max 1. exemplar pro buch
			DECLARE @ex int = (select count(*) from Exemplare where f_ISBN = @isbn and p_signatur in 
					(
						select pf_signatur from Ausgeliehene_Exemplare where pf_personen_id = @personenId )
					)

			IF(@ex > 0)
				BEGIN
					PRINT 'Es wurde bereits ein Exemplare dieses Buches ausgeliehen'
				END
			ELSE
				BEGIN
				-- vorbestetll ? 
					DECLARE @vorBestellt int = (select count(*) from Vorbestellte_Buecher where pf_isbn = @isbn)
					IF(@vorBestellt > 0)
						BEGIN
							PRINT 'Buch bereits vorbestellt'
						END
					ELSE
						BEGIN
							DECLARE @leihWochen tinyint, @rueckgabeDatum date;
							SET @leihWochen = (select leihfrist_wochen from Bibliotheken where name = @name) -- = leihwochen
							SET @rueckgabeDatum = DATEADD(WEEK,1,GETDATE())

							INSERT INTO [dbo].[Ausgeliehene_Exemplare]
								   ([pf_signatur], [pf_personen_id], [rueckgabe_datum], [anzahl_verlaengerungen])
								VALUES
								(@signatur, @personenId, @rueckgabeDatum,0 )
						END
				END
			END
		END
	END
END
GO


-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

USE[Library]
GO
CREATE PROCEDURE sp_VerlaengereAusleihe @personenId int , @isbn bigint
AS
--- hole richtige signatur
DECLARE @sig varchar(10) = CONVERT(varchar(10), ( select pf_signatur from Ausgeliehene_Exemplare 
													where pf_personen_id = @personenId and pf_signatur in 
													(
														select p_signatur from Exemplare where f_ISBN = @isbn)
													)
												)

--- hole akutelle anzahl der verlaegerungen
DECLARE @anzVer tinyint = (select anzahl_verlaengerungen from Ausgeliehene_Exemplare 
							where pf_signatur = @sig and pf_personen_id = @personenId)
IF(@anzVer = 2)
	BEGIN
		PRINT 'Es wurde bereits 2 mal verlaengert!'
	END
ELSE
	BEGIN
		SET @anzVer = (@anzVer +1)
		UPDATE Ausgeliehene_Exemplare SET anzahl_verlaengerungen = @anzVer
				where pf_signatur = @sig and pf_personen_id = @personenId
		PRINT 'Ausleihe wurde verlaengert'
	END
GO


-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- aendere die jahres gebuehr

USE[Library]
GO
CREATE PROCEDURE sp_AendereJahresGebuehr @ausweisNr int, @gebuehr SMALLINT, @bibname nvarchar(max)
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Bibliotheken] SET [gebuehren_jahr] = @gebuehr WHERE name = @bibname
	END
GO

-- andere die ausleih gebuehr

USE[Library]
GO
CREATE PROCEDURE sp_AendereLeihGebuehr @ausweisNr int, @gebuehr SMALLINT, @bibname nvarchar(max)
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Bibliotheken] SET [gebuehren_leihfrist] = @gebuehr WHERE name = @bibname
	END
GO


-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- sperre ausweis

USE[Library]
GO
CREATE PROCEDURE sp_SperreAusweis @ausweisNr int, @personenId int
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Ausweise] SET [gesperrt] = 1 WHERE pf_personen_id = @personenId
	END
GO

-- entsperre ausweis

USE[Library]
GO
CREATE PROCEDURE sp_EntsperreAusweis @ausweisNr int, @personenId int
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Ausweise] SET [gesperrt] = 0 WHERE pf_personen_id = @personenId
	END
GO


-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- check positive zahl

USE[Library]
GO
CREATE FUNCTION CheckPositiveZahl (@wert SMALLINT)
RETURNS BIT
AS
BEGIN
DECLARE @result bit = 1;
IF(@wert < 0)
	BEGIN 
		-- Wert ist negativ
		SET @result = 0;
	END
	RETURN @result;
END
GO

-- begleiche gebuehr

USE[Library]
GO
CREATE PROCEDURE sp_BegleicheGebuehr (@ausweisNr int, @betrag smallint)
AS
DECLARE @b bit = Library.dbo.CheckPositiveZahl(@betrag)

IF(@b = 0)
BEGIN
	PRINT 'Negative Beitraege werden nicht angenommen'
END
ELSE
	BEGIN
		DECLARE @personenId int, @currKontostand smallint;
		SET @personenId = (select pf_personen_id from Ausweise where ausweisnr = @ausweisNr)
		SET @currKontostand = (select top(1) kontostand from Nutzer where p_personen_id = @personenId)

		IF(@personenId >= 0)
			BEGIN
				UPDATE [dbo].[Nutzer]
					SET kontostand = (@currKontostand-@betrag)
					WHERE p_personen_id = @personenId
			END
		ELSE
			BEGIN
				PRINT 'Person konnte nicht gefunden werden.'
			END
	END
GO

-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- konto ausgeglichen ?

USE[Library]
GO
CREATE FUNCTION CheckKontoAusgeglichen (@personenId int)
RETURNS BIT
AS
BEGIN
	DECLARE @result bit = 0
	DECLARE @kontostand SMALLINT = (select kontostand from nutzer where p_personen_id = @personenId)
	IF(@kontostand = 0)
		BEGIN
			SET @result = 1; -- konto ist ausgeglichen
		END
	RETURN @result;
END
GO

-- verlaegere ausweis


USE[Library]
GO
CREATE PROCEDURE sp_VerlaengereAusweis @ausweisNr int, @personenId int
AS
DECLARE @ok bit = 0, @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
		RETURN @ok
	END
ELSE
	BEGIN
		DECLARE @bit bit = Library.dbo.CheckKontoAusgeglichen(@personenId)

		IF(@bit = 0)
			BEGIN
				PRINT 'Das Nutzer-Konto ist nicht ausgeglichen'
				RETURN @ok
			END
		ELSE
			BEGIN
				UPDATE [dbo].[Ausweise] SET [gueltigBis] = DATEADD(YEAR, 10, GETDATE()) WHERE pf_personen_id = @personenId
				SET @ok = 1;
				RETURN @ok
			END
	END
GO


-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- bestelle buch vor

USE[Library]
GO
CREATE PROCEDURE sp_BestelleBuchVor (@isbn bigint, @ausweisNr int)
AS
DECLARE @gesperrt bit = Library.dbo.GetAusweisGesperrt (@ausweisNr)

IF(@gesperrt = 1)
BEGIN
	PRINT 'Ausweis ist geperrt'
END
ELSE
	BEGIN
		DECLARE @personenId int = (select pf_personen_id from Ausweise where ausweisnr = @ausweisNr)

		INSERT INTO [dbo].[Vorbestellte_Buecher] ([pf_isbn], [pf_personen_id])
			 VALUES (@isbn, @personenId)
	END
GO

-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- aendere leihfrist / die ausleihwochen

USE[Library]
GO
CREATE PROCEDURE sp_AendereLeihfrist @ausweisNr int, @leihwochen tinyint, @bibname nvarchar(max)
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Bibliotheken] SET [leihfrist_wochen] = @leihwochen WHERE name = @bibname
	END
GO

-- gebe exemplar zurueck

USE[Library]
GO
CREATE PROCEDURE sp_GebeExemplarZurueck (@signature varchar(10))
AS
DELETE FROM Ausgeliehene_Exemplare
WHERE pf_signatur = @signature
GO

-- check kuerzel

USE[Library]
GO
CREATE PROCEDURE sp_KuerzelPruefung @preKuerzel char(4)
AS

IF (SELECT COUNT(*) FROM Exemplare WHERE SUBSTRING(p_signatur, 0,4) = @preKuerzel) > 0
	BEGIN
		RETURN 1;
	END
ELSE
	BEGIN
		RETURN 0;
	END
