-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis


USE[Library]
GO
CREATE PROCEDURE sp_TestAusweisSperrenEntsperren @ausweisNr int
AS
PRINT 'Lege neuen Test-Nutzer an'
DECLARE @vname nvarchar(max) = 'testnutzer', @nname nvarchar(max) = 'testnachname', @pw varchar(16) = 'xtestPwx';
EXEC sp_CreateNutzer @ausweisNr,0, @vname, @nname, '01.01.1990', 0, @pw
PRINT 'Test-Nutzer angelegt - suche die Personen-Id des Test-Nutzers'

DECLARE @personenId int = (select Top(1) p_personen_id from Nutzer where name = @nname and vorname = @vname)

PRINT CONCAT ('PersonenId ist ' , @personenId)
PRINT 'Versuche Ausweis zu sprerren'
EXEC sp_SperreAusweis @ausweisNr, @personenId
PRINT 'Prozedur sp_SperreAusweis wurde ausgefuehrt'

DECLARE @status bit = (select gesperrt from Ausweise where pf_personen_id = @personenId)

IF(@status = 1)
BEGIN
	PRINT 'Der Ausweis ist geperrt - versuche den Ausweis zu entsperren'
	EXEC sp_EntsperreAusweis @ausweisNr, @personenId
	PRINT 'Prozedur sp_EntsperreAusweis wurde ausgefuehrt'

	SET @status = (select gesperrt from Ausweise where pf_personen_id = @personenId)

	IF(@status = 0)
	BEGIN
		PRINT 'Der Ausweis ist entsperrt - beide Prozeduren funktionieren'
		PRINT 'Loesche Test-Nutzer'
		EXEC sp_DeleteNutzer @ausweisNr, @personenID
	END
	ELSE
	BEGIN
		PRINT 'Ausweis konnte nicht entsperrt werden'
	END
END
ELSE
BEGIN
	PRINT 'Ausweis konnte nicht gesperrt werden'
END

PRINT 'Suche nach PersonenId in Ausweisen und Nutzer'

DECLARE @anzNutzer int = (select count(*) from Nutzer where p_personen_id = @personenId and vorname = @vname and name = @nname)
DECLARE @anzAusweise int = (select count(*) from Ausweise where pf_personen_id = @personenId and passwort = @pw)

PRINT CONCAT('Anzahl Nutzer: ', @anzNutzer, ' Anzahl Ausweise: ', @anzAusweise)

IF(@anzNutzer = 0 and @anzAusweise = 0)
BEGIN
	PRINT 'Alle Prozeduren haben funktioniert'
END
ELSE
BEGIN
	PRINT 'Etwas stimmt nicht mit den Prozeduren'
END
GO



EXEC sp_TestAusweisSperrenEntsperren 2