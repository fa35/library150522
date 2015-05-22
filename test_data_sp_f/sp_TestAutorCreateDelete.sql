-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- anlegen und loechen von autoren testen

USE[Library]
GO
CREATE PROCEDURE sp_TestAutorCreateDelete @ausweisNr int, @vname varchar(max), @nname varchar(max)
AS
DECLARE @anzVor int = (select count(*) from Autoren)

PRINT 'Versuche einen Autor anzulegen'
EXEC sp_CreateAutor @ausweisNr, @vname, @nname
PRINT 'Prozedur sp_LegeAutorAn wurde ausgefuehrt'

DECLARE @anzNach int = (select count(*) from Autoren)
PRINT CONCAT('Anzahl vor: ', @anzVor, ' Anzahl nach: ', @anzNach)

IF(@anzVor < @anzNach)
BEGIN
	PRINT 'Prozedur sp_LegeAutorAn scheint zu funktionieren'
	DECLARE @catched int = (select count(*) from Autoren where vorname = @vname and name = @nname)
	PRINT CONCAT('Es gibt genau: ', @catched , ' Eintrag von dem neu angelegten Auto')

	-- wenn es nur einen autor mit den beschreibungen gibt - dann hole die id und loesche den autoren wieder
	IF(@catched = 1)
	BEGIN
		PRINT 'Suche die Id des Autoren'
		DECLARE @autorId int = (select Top(1) p_autor_id from Autoren where vorname = @vname and name = @nname)
		PRINT CONCAT('Id = ' , @autorId)
		-- loeschen
		PRINT 'Versuche den Autor zu loeschen'
		EXEC sp_DeleteAutor @ausweisNr, @autorId 
		PRINT 'Prozedur sp_LoescheAutor wurde ausgefuehrt'

		SET @anzNach = (select count(*) from Autoren)	
		PRINT CONCAT('Anzahl vor: ', @anzVor, ' Anzahl nach: ', @anzNach)
		SET @catched = (select count(*) from Autoren where p_autor_id = @autorId)
		PRINT CONCAT('Es gibt genau: ', @catched , ' Eintrag von dem neu angelegten Auto')

		IF(@catched = 0)
		BEGIN
			PRINT 'Prozedure sp_LoescheAutor funktioniert'
		END
		ELSE
			BEGIN
				PRINT 'Prozedure sp_LoescheAutor funktioniert nicht richtig'
			END
	END
	ELSE
	BEGIN
		PRINT 'Etwas stimmt nicht'
	END
END
ELSE
BEGIN
	PRINT 'Prozedur sp_LegeAutorAn scheint nicht richtig zu funktionieren'
END


EXEC sp_TestAutorCreateDelete 2, 'test autor', 'test autor nachname'