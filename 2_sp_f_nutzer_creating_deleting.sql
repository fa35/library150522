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

