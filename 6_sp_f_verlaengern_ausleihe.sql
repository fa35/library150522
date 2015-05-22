-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

USE[Library]
GO
CREATE PROCEDURE sp_VerlaengereAusleihe @personenId int , @isbn bigint
AS
--- hole richtige signatur
DECLARE @sig varchar(10) = CONVERT(varchar(10), ( select pf_signatur from Ausgeliehene_Exemplare 
													where pf_personen_id = @personenId and pf_signatur in 
													(
														select p_signatur from Exemplare where f_ISBN = @isbn)
													)
												)

--- hole akutelle anzahl der verlaegerungen
DECLARE @anzVer tinyint = (select anzahl_verlaengerungen from Ausgeliehene_Exemplare 
							where pf_signatur = @sig and pf_personen_id = @personenId)
IF(@anzVer = 2)
	BEGIN
		PRINT 'Es wurde bereits 2 mal verlaengert!'
	END
ELSE
	BEGIN
		SET @anzVer = (@anzVer +1)
		UPDATE Ausgeliehene_Exemplare SET anzahl_verlaengerungen = @anzVer
				where pf_signatur = @sig and pf_personen_id = @personenId
		PRINT 'Ausleihe wurde verlaengert'
	END
GO
