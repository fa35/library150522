-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- teste ob das anlegen und loeschen eines buches funktioniert

USE [Library]
GO
CREATE PROCEDURE sp_TestBookCreateDelete @ausweisNr int, @isbn bigint, @titel nvarchar(max), @fachgebiet int
AS
-- anzahl der buecher vor irgendwelchen aenderungen
DECLARE @anzBuecherVor int = (select count(*) from Buecher)
	PRINT 'Versuche neues Buch anzulegen'
-- ausfuehren der anlege prozedur
EXEC sp_CreateBook @ausweisNr, @isbn, @titel, @fachgebiet 
	PRINT 'Prozedur sp_LegeBuchAn ausgefuehrt'
-- anzahl der buecher nachdem ein buch angelegt wurde
DECLARE @anzBuecherNach int = (select count(*) from Buecher)
	PRINT CONCAT('Anzahl vor: ', @anzBuecherVor, ' Anzahl nach: ', @anzBuecherNach)

-- wenn anzahl der buecher davor kleiner als die anzahl der buecher danach ist
IF(@anzBuecherVor < @anzBuecherNach)
BEGIN
PRINT 'Prozedur sp_LegeBuchAn funktioniert'
--- suche in der tabelle nach diesem einen datensatz
	DECLARE @catched int = (select count(*) from Buecher where p_ISBN = @isbn and titel = @titel and f_fachgebiet_id = @fachgebiet)
PRINT CONCAT('Es gibt genau: ', @catched, ' Eintrag/Eintraege, welche die eingegebenen Daten haben.')

-- loesche buch
PRINT 'Versuche Buch zu loeschen'
	EXEC sp_DeleteBook @ausweisNr, @isbn
PRINT 'Prozedur sp_LoescheBuch ausgefuehrt'
-- nachdem ein buch geloescht wurde, müsste die anzahl der buecher wieder so sein wie am anfang
	SET @anzBuecherNach = (select count(*) from Buecher)
PRINT CONCAT('Anzahl vor: ', @anzBuecherVor, ' Anzahl nach: ', @anzBuecherNach)
-- suche in der tabelle dem geloeschten datensatz
	SET @catched = (select count(*) from Buecher where p_ISBN = @isbn and titel = @titel and f_fachgebiet_id = @fachgebiet)
PRINT CONCAT('Es gibt genau: ', @catched, ' Eintrag/Eintraege, welche die eingegebenen Daten haben.')

	IF(@anzBuecherVor = @anzBuecherNach)
		BEGIN
			PRINT 'Prozedur sp_LoescheBuch funktioniert'
		END
	ELSE
		BEGIN
			PRINT 'Prozedur sp_LoescheBuch scheint nicht richtig zu funktionieren'
		END
END
ELSE
	BEGIN
		PRINT 'Prozedur sp_LegeBuchAn scheint nicht richtig zu funktionieren'
	END
GO


exec sp_TestBookCreateDelete 2, 9999999999, 'test buch anlegen', 1


