-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- Teste Anlegen und Löschen eines Nutzers

USE [Library]
GO
CREATE PROCEDURE sp_TestNutzerCreateDelete @ausweisNr int, @vname nvarchar(max), @nname nvarchar(max), @gdatum date, @pw varchar(16),
						@mitarbeiterrecht bit, @kontostand SMALLINT
AS
DECLARE @anzahlNutzerNach int, @anzahlNutzerVor int = (select count(*) from nutzer);	
	PRINT 'Versuche neuen Nutzer anzulegen'
EXEC sp_CreateNutzer @ausweisNr, @mitarbeiterrecht, @vname, @nname, @gdatum, @kontostand, @pw
	PRINT 'Neuer Nutzer angelegt'
SET @anzahlNutzerNach = (select count(*) from nutzer)
	PRINT CONCAT('Vorher: ' , @anzahlNutzerVor , ' Nachher: ' , @anzahlNutzerNach)
	
IF(@anzahlNutzerVor < @anzahlNutzerNach)
	BEGIN
			PRINT 'Prozedur zum Anlegen eines neuen Nutzers funktioniert'
			PRINT 'Versuche neuangelegten Nutzer zu löschen'
			PRINT 'Suche neuangelegten Nutzer und selektiere die Personen Id'
			DECLARE @pId int = (select Top(1) p_personen_id from Nutzer where vorname = @vname and name = @nname and geburtsdatum = @gdatum)
			PRINT CONCAT('Die neue Personen Id lautet: ', @pId)
		EXEC sp_DeleteNutzer  2, @pId
			SET @anzahlNutzerNach = (select count(*) from nutzer)
			PRINT CONCAT('Vorher: ' , @anzahlNutzerVor , ' Nachher: ' , @anzahlNutzerNach)
		IF(@anzahlNutzerVor = @anzahlNutzerNach)
			BEGIN
				DECLARE @anzahlIDs int = (select count(*) from nutzer where p_personen_id = @pId)
				IF(@anzahlIDs = 0)
					BEGIN
						PRINT 'Die durch den neuen Nutzer entstandene Id wurde nicht mehr in der Tabelle gefunden'
						PRINT 'Prozedur zum Löschen eines Nutzers funktioniert'
					END
			END
		ELSE
			BEGIN
				PRINT 'Prozedur zum Löschen eines Nutzers wirft Fehler'
			END 
	END
ELSE
	BEGIN
		PRINT 'Die Prozedur zum Anlegen eines neuen Nutzers wirft Fehler'
	END
GO

EXEC sp_TestNutzerCreateDelete 2, '#_test_vorname_#', '#_test_nachname_#', '01.01.1960', '#x_test_x#', 0, 0