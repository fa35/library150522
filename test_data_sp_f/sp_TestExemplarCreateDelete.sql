-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

USE[Library]
GO
CREATE PROCEDURE sp_TestExemplarCreateDelete @ausweisNr int , @isbn bigint
AS
DECLARE @anzVor int = (select count(*) from Exemplare where f_ISBN = @isbn)

	--- tabelle mit akuellen signaturen
	DECLARE @zwischenTab1 table ( sig varchar(10) not null )
	insert into @zwischenTab1
	select p_signatur from Exemplare where f_ISBN = @isbn
	---

PRINT 'Versuche neues Exemplar anzulegen'
EXEC sp_CreateExemplar @ausweisNr, @isbn
PRINT 'Prozedur sp_LegeExemplarAn wurde ausgefuehrt'

DECLARE @anzNach int = (select count(*) from Exemplare where f_ISBN = @isbn)

PRINT CONCAT('Anzahl Exemplare zuvor: ', @anzVor, ' Anzahl Exemplare nachher: ' , @anzNach)
	
	--- tabelle mit akuellen signaturen
	DECLARE @zwischenTab2 table ( sig varchar(10) not null )
	insert into @zwischenTab2
	select p_signatur from Exemplare where f_ISBN = @isbn
	---

DECLARE @ersteSig varchar(10) = (select top(1) sig from @zwischenTab2 where sig not in (select sig from @zwischenTab1))

IF(@anzVor < @anzNach)
BEGIN
		--- tabelle mit akuellen signaturen
		DECLARE @signaturenVor table ( sig varchar(10) not null )
		insert into @signaturenVor
		select p_signatur  from Exemplare where f_ISBN = @isbn
		---

	Print 'Versuche weiters Exemplar anzulegen'
	EXEC sp_CreateExemplar @ausweisNr, @isbn
	Print 'Prozedur sp_LegeExemplarAn wurde ausgefuehrt'

	SET @anzVor = @anzNach
	SET @anzNach =  (select count(*) from Exemplare where f_ISBN = @isbn)

		--- tabelle mit akuellen signaturen
		DECLARE @signaturenNach table ( sig varchar(10) not null )
		insert into @signaturenNach
		select p_signatur from Exemplare where f_ISBN = @isbn
		---

	DECLARE @zweiteSig varchar(10) = (select top(1) sig from @signaturenNach where sig not in (select sig from @signaturenVor))

	PRINT CONCAT('Anzahl Exemplare zuvor: ', @anzVor, ' Anzahl Exemplare nachher: ' , @anzNach)

	IF(@anzVor < @anzNach)
	BEGIN
		PRINT 'Prozedur sp_LegeExemplarAn funktioniert'

		-- loesche beide exemplare wieder
		Print 'Versuche ein Exemplar zu loeschen'
		EXECUTE sp_DeleteExemplar @ausweisNr, @ersteSig
		Print 'Prozedur sp_LoescheExemplar wurde ausgefuehrt'
				
		Print 'Versuche ein Exemplar zu loeschen'
		EXECUTE sp_DeleteExemplar @ausweisNr, @zweiteSig
		Print 'Prozedur sp_LoescheExemplar wurde ausgefuehrt'

		PRINT 'Pruefe Anzahl der Exemplare der ISBN'
		SET @anzVor = (select count(*) from @signaturenVor)
		SET @anzNach =  (select count(*) from Exemplare where f_ISBN = @isbn)
		PRINT CONCAT('Akutelle Anzahl: ', @anzVor, ' Anzahl nach dem Loeschen ist: ', @anzNach)

		IF(@anzVor = @anzNach)
		BEGIN
			PRINT 'Prozedur sp_loescheExemplar funktioniert'
			-- tabellen müssen wieder gelert werden
			delete from @signaturenNach where sig in (select sig from @signaturenNach)
			delete from @signaturenVor where sig in (select sig from @signaturenVor)
		END
		ELSE
		BEGIN
			PRINT 'Prozedur sp_loescheExemplar scheint nicht richtig zu funktionieren'
		END			
	END
	ELSE
	BEGIN
		PRINT 'Die Prozedur sp_LegeExemplarAn funktioniert nicht richtig'
	END
END
ELSE
BEGIN
	PRINT 'Die Prozedur sp_LegeExemplarAn funktioniert nicht richtig'
END

GO



EXEC sp_TestExemplarCreateDelete 2, 1488544786