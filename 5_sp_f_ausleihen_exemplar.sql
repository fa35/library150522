-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- check ausweis gesperrt

USE[Library]
GO
CREATE FUNCTION CheckAusweisGesperrt (@personenId int)
RETURNS BIT
AS
BEGIN
	RETURN (select gesperrt from Ausweise where pf_personen_id = @personenId);
END
GO

-- check ueberfaellige exemplare

USE[Library]
GO
CREATE FUNCTION CheckUeberfaelligeExemplare(@personenId int)
RETURNS BIT
AS
BEGIN
	DECLARE @cnt int = ( select count(*) from Ausgeliehene_Exemplare 
			where pf_personen_id = @personenId and rueckgabe_datum <= GETDATE()
			)
	IF(@cnt = 0)
	BEGIN
		RETURN 0
	END
	RETURN 1
END

-- check kontolimit: if limit > 10000 (100 Geldeinheiten) => limit ueberschritten

USE[Library]
GO
CREATE FUNCTION CheckKontolimit (@personenId int)
RETURNS BIT
AS
BEGIN
	DECLARE @result bit = 0
	DECLARE @kontostand SMALLINT = (select kontostand from nutzer where p_personen_id = @personenId)
	IF(@kontostand < 10000)
		BEGIN
			SET @result = 1;
		END
	RETURN @result;
END
GO


-- leihe exemplar aus
-- waere viel schoener alle bindungen auszulagern

USE[Library]
GO
CREATE PROCEDURE sp_LeiheExemplarAus (@isbn bigint, @ausweisNr int, @name nvarchar(max))
AS
DECLARE @signatur varchar(10) = (select Top(1) p_signatur from Exemplare where f_ISBN = @isbn and p_signatur not in (select pf_signatur from Ausgeliehene_Exemplare )) -- = signatur des exemplares
DECLARE @personenId INT = (select pf_personen_id from Ausweise where ausweisnr = @ausweisNr)
-- ausweis gültig
DECLARE @b bit = Library.dbo.CheckAusweisGesperrt(@personenId)

IF(@b = 1)
BEGIN
	PRINT 'Der Ausweis ist gesperrt'
END
ELSE
BEGIN
	-- keine überfälligen buecher
	select * from Ausgeliehene_Exemplare
	SET @b = Library.dbo.CheckUeberfaelligeExemplare(@personenId)

	IF(@b = 1)
		BEGIN
			PRINT 'Es sind noch Bücher fällig'
		END
	ELSE
	BEGIN
		-- check konto
		SET @b = Library.dbo.CheckKontolimit(@personenId) -- kontolimit > 0 => kontolimit ueberschritten

		IF(@b = 0)
			BEGIN
				PRINT 'Der Kontostand ist ueber 100 Geldeinheiten'
			END
		ELSE
		BEGIN
			-- anzahl der ausge. exempolare max. 10 , davo max. 1 pro buch
			DECLARE @count int = (select count(*) from Ausgeliehene_Exemplare where pf_personen_id = @personenId) 

			IF(@count >= 10)
			BEGIN
				PRINT 'Es sind schon 10 oder mehr Exemplare ausgeliehen'
			END
			ELSE
			BEGIN
			-- max 1. exemplar pro buch
			DECLARE @ex int = (select count(*) from Exemplare where f_ISBN = @isbn and p_signatur in 
					(
						select pf_signatur from Ausgeliehene_Exemplare where pf_personen_id = @personenId )
					)

			IF(@ex > 0)
				BEGIN
					PRINT 'Es wurde bereits ein Exemplare dieses Buches ausgeliehen'
				END
			ELSE
				BEGIN
				-- vorbestetll ? 
					DECLARE @vorBestellt int = (select count(*) from Vorbestellte_Buecher where pf_isbn = @isbn)
					IF(@vorBestellt > 0)
						BEGIN
							PRINT 'Buch bereits vorbestellt'
						END
					ELSE
						BEGIN
							DECLARE @leihWochen tinyint, @rueckgabeDatum date;
							SET @leihWochen = (select leihfrist_wochen from Bibliotheken where name = @name) -- = leihwochen
							SET @rueckgabeDatum = DATEADD(WEEK,1,GETDATE())

							INSERT INTO [dbo].[Ausgeliehene_Exemplare]
								   ([pf_signatur], [pf_personen_id], [rueckgabe_datum], [anzahl_verlaengerungen])
								VALUES
								(@signatur, @personenId, @rueckgabeDatum,0 )
						END
				END
			END
		END
	END
END
GO