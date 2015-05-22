-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- bestelle buch vor

USE[Library]
GO
CREATE PROCEDURE sp_TestBookVorbestellen @ausweisNr int, @isbn bigint, @titel nvarchar(max), @fachgebiet int, @recht bit, @vname nvarchar(max), @nname varchar(max), @gdatum date, @konto SMALLINT, @pw varchar(16)
AS
PRINT 'Lege Test-Buch an'
EXEC sp_CreateBook @ausweisNr, @isbn, @titel, @fachgebiet
PRINT CONCAT('Test-Buch mit ISBN: ', @isbn, ' Titel: ', @titel, ' FachgebietId: ', @fachgebiet, ' angelegt')

PRINT 'Lege Test-Nutzer an'
EXEC sp_CreateNutzer @ausweisNr, @recht, @vname, @nname, @gdatum, @konto, @pw
PRINT CONCAT('Test-Nutzer mit Vname: ', @vname, ' Nname: ', @nname, ' Geburtsdatum: ', @gdatum, ' Recht: ', @recht , ' Kontostand: ', @konto, ' Passwort: ', @pw, ' angelegt')


PRINT 'Suche nach AusweisNr'
DECLARE @personenId int = (select p_personen_id from Nutzer where name = @nname and vorname = @vname and geburtsdatum = @gdatum and mitarbeiter = @recht)
DECLARE @perAus int = (select ausweisnr from Ausweise where passwort = @pw and pf_personen_id = @personenId)
PRINT CONCAT('PersonenId = ', @personenId, ' AusweisNr =' , @perAus)

PRINT 'Versuche Buch vorzubestellen'
EXEC sp_BestelleBuchVor @isbn, @perAus 
PRINT 'Prozedur sp_BestelleBuchVor wurde ausgefuehrt'

PRINT 'Suche nach Eintrag in Vorbestellte_Buecher'
DECLARE @catchedIsbn bigint = (select pf_isbn from Vorbestellte_Buecher where pf_personen_id = @personenId)
DECLARE @catchedPer int = (select pf_personen_id from Vorbestellte_Buecher where pf_isbn = @isbn)

PRINT CONCAT('Mit der ISDN: ', @isbn, ' konnte die Personenid: ', @catchedPer, ' gefunden werden')
PRINT CONCAT('Mit der PersonenId: ', @perAus, ' konnte die ISBN: ' , @catchedIsbn, ' gefunden werden')

IF(@catchedIsbn = @isbn and @catchedPer = @personenId)
	BEGIN
		PRINT 'Die Vorbestellung war erfolgreich - die Prozedur sp_BestelleBuchVor funktioniert'
	END
ELSE
	BEGIN
		PRINT 'Die Prozedur sp_BestelleBuchVor scheint nicht richtig zu funktionieren'
	END
PRINT 'Loesche Test-Daten wieder'

PRINT 'Beginne mit dem neuen Eintrag zum vorbestellte Buch'
DELETE FROM Vorbestellte_Buecher WHERE pf_isbn = @isbn and pf_personen_id = @personenId
PRINT 'Eintrag geloescht'

EXEC sp_DeleteBook @ausweisNr , @isbn 
PRINT 'sp_LoescheBuch wurde ausgefuehrt'

DECLARE @findIsbn int = (select count(*) from Buecher where p_isbn = @isbn)

IF(@findIsbn = 0)
	BEGIN
		PRINT 'Test-Buch wurde erfolgreich geloescht'
	END
ELSE
	BEGIN
		PRINT 'Test-Buch konnte nicht geloescht werden'
	END

EXEC sp_DeleteNutzer @ausweisNr, @personenId
PRINT 'sp_LoescheNutzer wurde ausgefuehrt'

DECLARE @findNutzer int = (select count(*) from Nutzer where p_personen_id = @personenId and vorname = @vname and name = @nname and geburtsdatum = @gdatum)

IF(@findNutzer = 0)
	BEGIN
		PRINT 'Test-Nutzer wurde erfolgreich geloescht'
	END
ELSE
	BEGIN
		PRINT 'Test-Nutzer konnte nicht geloescht werden'
	END
GO


EXEC sp_TestBookVorbestellen 2, 9999479999, '##_bestelle_buch_vor_test_##', 1, 0, 'vorname_testnutzer', 'nachname_testnutzer', '01.02.1984', 5, 'ts_pw_234'

