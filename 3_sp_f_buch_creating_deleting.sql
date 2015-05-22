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