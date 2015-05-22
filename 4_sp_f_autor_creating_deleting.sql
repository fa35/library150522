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