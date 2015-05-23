-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- beispiel view

USE [Library]
GO
CREATE VIEW v_BuchAnzahlExemplare
AS
SELECT b.p_ISBN as ISBN, (SELECT COUNT(exe.p_signatur) AS Expr1) AS AnzahlExemplare, a.name as AutorName
FROM dbo.Exemplare as exe INNER JOIN dbo.Buecher as b ON 
exe.f_ISBN = b.p_ISBN INNER JOIN dbo.Buecher_Autoren as ba ON 
b.p_ISBN = ba.pf_isbn INNER JOIN dbo.Autoren as a ON ba.pf_autor_id = a.p_autor_id
GROUP BY b.p_ISBN, a.name
GO


-- spaßige tablle für einen trigger

USE[Library]
GO
CREATE TABLE TriggeredSignatures (id int not null identity(1,1) primary key, isbn BIGINT, signatur varchar(10), inserted datetime)


-- spaßiger trigger

USE[Library]
GO
CREATE TRIGGER trgAfterInsertExemplar ON Exemplare 
FOR INSERT
AS
	declare @sig varchar(10);
	declare @isbn bigint;

	select @sig = i.p_signatur from inserted i;	
	select @isbn = i.f_ISBN from inserted i;
	
	IF (SUBSTRING(@sig, 1, 4) like 'UNKN%')
	BEGIN
		insert into TriggeredSignatures(isbn, signatur, inserted)
		values(@isbn, @sig, GETDATE())
	END

	PRINT 'UNKNOWN AUTOR!!!'
GO
