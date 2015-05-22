-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis


USE[Library]
GO
CREATE PROCEDURE sp_TestAusweisVerlaengern @ausweisNr int, @recht bit, @vname nvarchar(max), @nname varchar(max), @gdatum date, @konto SMALLINT, @pw varchar(16)
AS
PRINT 'Lege Test-Nutzer an'
EXEC sp_CreateNutzer @ausweisNr, @recht, @vname, @nname, @gdatum, @konto, @pw
PRINT CONCAT('Test-Nutzer mit Vname: ', @vname, ' Nname: ', @nname, ' Geburtsdatum: ', @gdatum, ' Recht: ', @recht , ' Kontostand: ', @konto, ' Passwort: ', @pw, ' angelegt')

PRINT 'Suche nach AusweisNr'
DECLARE @personenId int = (select top(1) p_personen_id from Nutzer where name = @nname and vorname = @vname and geburtsdatum = @gdatum and mitarbeiter = @recht)
DECLARE @datum date = (select top(1) gueltigBis from Ausweise where passwort = @pw and pf_personen_id = @personenId)
PRINT CONCAT('PersonenId = ', @personenId, ' Datum =' , @datum)

PRINT 'Versuche Ausweis zu verlaengern'
DECLARE @ok bit = 0;
EXEC @ok = sp_VerlaengereAusweis @ausweisNr, @personenId

IF(@ok = 1)
BEGIN
	DECLARE @neuesdatum date = (select top(1) gueltigBis from Ausweise where passwort = @pw and pf_personen_id = @personenId)
	PRINT CONCAT('Altes Datum: ', @datum, ' Neues Datum: ', @neuesdatum)

	IF(@datum < @neuesdatum)
		BEGIN 
			PRINT 'Prozedur sp_VerlaengereAusweis funktioniert'
		END
	ELSE
		BEGIN
			PRINT 'Etwas stimmt mit der Prozedur sp_VerlaengereAusweis nicht'
		END
END

PRINT 'Loesche Test-Nutzer'
EXEC sp_DeleteNutzer @ausweisNr, @personenId
PRINT 'Prozedur sp_LoescheNutzer wurde ausgefuehrt'

PRINT 'Pruefe Loeschung'
DECLARE @catched int = (select count(*) from Nutzer where p_personen_id = @personenId and name = @nname and vorname = @vname)
IF(@catched = 0)
	BEGIN
		PRINT 'Test-Nutzer wurde geloescht'
	END
ELSE
	BEGIN
		PRINT 'Prozedur sp_LoescheNutzer funktioniert nicht richtig - versuche manuelle Loeschung'
		delete from Nutzer where p_personen_id = @personenId and name = @nname and vorname = @vname and geburtsdatum = @gdatum
		PRINT 'Ueberpruefe noch einmal'
		SET @catched = (select count(*) from Nutzer where  p_personen_id = @personenId and name = @nname and vorname = @vname and geburtsdatum = @gdatum)
		IF(@catched = 0)
			BEGIN
				PRINT 'Loeschen hat funktioniert'
			END
		ELSE
			BEGIN
				PRINT CONCAT('Der Eintrag mit der PersonenId: ', @personenId, ' konnte nich aus der Nutzer - Tabelle geloescht werden')
			END
	END
GO

EXEC sp_TestAusweisVerlaengern 2, 0, '#vorname#test#', '#test_nachname#', '13.06.1965', 0, 'l!+#3d8wlö'