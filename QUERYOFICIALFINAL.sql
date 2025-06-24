CREATE DATABASE DesaparecidosBASE1;
GO
USE DesaparecidosBASE1;


CREATE TABLE Grupo_Etario (
    id_grupo_etario VARCHAR(6) PRIMARY KEY,
    grupo_etario VARCHAR(50)
);


CREATE TABLE Ocupacion (
    id_ocupacion VARCHAR(6) PRIMARY KEY,
    ocupacion VARCHAR(100)
);


CREATE TABLE Nivel_Educativo (
    id_nivel_educativo VARCHAR(6) PRIMARY KEY,
    nivel_educativo VARCHAR(100)
);


CREATE TABLE Situacion_Laboral (
    id_situacion_laboral VARCHAR(6) PRIMARY KEY,
    situacion_laboral VARCHAR(100)
);


CREATE TABLE Red_Social (
    id_red_social VARCHAR(6) PRIMARY KEY,
    red_social_predominante VARCHAR(50)
);


CREATE TABLE Rango (
    id_rango VARCHAR(6) PRIMARY KEY,
    rango VARCHAR(10)
);


CREATE TABLE Dependencia (
    id_dependencia VARCHAR(8) PRIMARY KEY,
    nombre_dependencia VARCHAR(100)
);


CREATE TABLE Persona (
    id_persona VARCHAR(50) PRIMARY KEY,
    apellidos VARCHAR(100),
    nombres VARCHAR(100),
    fecha_nacimiento DATE,
    edad INT,
    genero VARCHAR(20),
    id_grupo_etario VARCHAR(6),
    pais_nacimiento VARCHAR(50),
    id_nivel_educativo VARCHAR(6),
    id_ocupacion VARCHAR(6),
    id_situacion_laboral VARCHAR(6),
    uso_redes_sociales VARCHAR(6),
    id_red_social VARCHAR(6),
    url_img VARCHAR(1000),
    FOREIGN KEY (id_grupo_etario) REFERENCES Grupo_Etario(id_grupo_etario),
    FOREIGN KEY (id_nivel_educativo) REFERENCES Nivel_Educativo(id_nivel_educativo),
    FOREIGN KEY (id_ocupacion) REFERENCES Ocupacion(id_ocupacion),
    FOREIGN KEY (id_situacion_laboral) REFERENCES Situacion_Laboral(id_situacion_laboral),
    FOREIGN KEY (id_red_social) REFERENCES Red_Social(id_red_social)
);



CREATE TABLE Denuncia (
    id_denuncia VARCHAR(50) PRIMARY KEY,
    nro_denuncia BIGINT,
    fecha_denuncia DATETIME,
    tipo_denuncia VARCHAR(50),
    denunciante_parentesco VARCHAR(50),
    id_dependencia VARCHAR(8),
    nombre_instructor VARCHAR(100),
    apellido_instructor VARCHAR(100),
    id_rango VARCHAR(6),
    FOREIGN KEY (id_dependencia) REFERENCES Dependencia(id_dependencia),
    FOREIGN KEY (id_rango) REFERENCES Rango(id_rango)
);


CREATE TABLE Desaparicion (
    id_desaparicion VARCHAR(50) PRIMARY KEY,
    id_persona VARCHAR(50),
    id_denuncia VARCHAR(50),
    fecha_hecho DATETIME,
    distrito_hecho VARCHAR(100),
    provincia_hecho VARCHAR(100),
    departamento_hecho VARCHAR(100),
    region_hecho VARCHAR(100),
    calle_hecho TEXT,
    referencia_hecho TEXT,
    circunstancias TEXT,
    situacion_resolucion VARCHAR(100),
    dias_desaparecido INT,
    FOREIGN KEY (id_persona) REFERENCES Persona(id_persona),
    FOREIGN KEY (id_denuncia) REFERENCES Denuncia(id_denuncia)
);


ALTER TABLE Persona
ALTER COLUMN genero VARCHAR(20);


------Consulta 1-----

SELECT COUNT(*) AS total_desapariciones
FROM Desaparicion;


-----Consulta 2 ------

SELECT MONTH(fecha_hecho) AS mes, COUNT(*) AS cantidad
FROM Desaparicion
WHERE YEAR(fecha_hecho) = 2022
GROUP BY MONTH(fecha_hecho)
ORDER BY mes;

----Consulta 3-------

SELECT departamento_hecho, COUNT(*) AS cantidad
FROM Desaparicion
GROUP BY departamento_hecho
ORDER BY cantidad DESC;


----Consulta 4------

SELECT genero, COUNT(*) AS cantidad
FROM Persona p
JOIN Desaparicion d ON p.id_persona = d.id_persona
GROUP BY genero;


----Consulta 5----

SELECT 
    g.grupo_etario,
    COUNT(*) AS total_casos,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Desaparicion), 2) AS porcentaje_sobre_total
FROM Desaparicion d
JOIN Persona p ON d.id_persona = p.id_persona
JOIN Grupo_Etario g ON p.id_grupo_etario = g.id_grupo_etario
GROUP BY g.grupo_etario
ORDER BY porcentaje_sobre_total DESC;

----Consulta 6----

SELECT 
    ne.nivel_educativo,
    COUNT(*) AS total_casos,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Desaparicion), 2) AS porcentaje
FROM Persona p
JOIN Desaparicion d ON p.id_persona = d.id_persona
JOIN Nivel_Educativo ne ON p.id_nivel_educativo = ne.id_nivel_educativo
GROUP BY ne.nivel_educativo
ORDER BY porcentaje DESC;


---- Consulta 7 ----

SELECT 
    dep.nombre_dependencia,
    d.situacion_resolucion,
    COUNT(*) AS total_casos
FROM Desaparicion d
JOIN Denuncia dn ON d.id_denuncia = dn.id_denuncia
JOIN Dependencia dep ON dn.id_dependencia = dep.id_dependencia
GROUP BY dep.nombre_dependencia, d.situacion_resolucion
ORDER BY dep.nombre_dependencia, d.situacion_resolucion;

----Consulta 8----

SELECT 
    rs.red_social_predominante,
    COUNT(*) AS total_usuarios
FROM Persona p
JOIN Red_Social rs ON p.id_red_social = rs.id_red_social
JOIN Desaparicion d ON p.id_persona = d.id_persona
GROUP BY rs.red_social_predominante
ORDER BY total_usuarios DESC;


----- Consulta 9 ----

SELECT 
    tipo_denuncia,
    COUNT(*) AS total
FROM Denuncia
GROUP BY tipo_denuncia;

---- Consulta 10 ----

SELECT 
    d.id_desaparicion,
    d.fecha_hecho,
    dn.fecha_denuncia,
    DATEDIFF(DAY, d.fecha_hecho, dn.fecha_denuncia) AS dias_para_denunciar
FROM Desaparicion d
JOIN Denuncia dn ON d.id_denuncia = dn.id_denuncia
WHERE d.fecha_hecho IS NOT NULL AND dn.fecha_denuncia IS NOT NULL
ORDER BY dias_para_denunciar DESC;


------Funcion 1-----
CREATE FUNCTION fn_TiempoPromedioReportePorDepartamento (@departamento VARCHAR(100))
RETURNS FLOAT
AS
BEGIN
    DECLARE @promedio FLOAT

    SELECT @promedio = AVG(DATEDIFF(DAY, d.fecha_hecho, dn.fecha_denuncia) * 1.0)
    FROM Desaparicion d
    JOIN Denuncia dn ON d.id_denuncia = dn.id_denuncia
    WHERE d.departamento_hecho = @departamento
          AND d.fecha_hecho IS NOT NULL
          AND dn.fecha_denuncia IS NOT NULL

    RETURN @promedio
END;

SELECT dbo.fn_TiempoPromedioReportePorDepartamento('AREQUIPA') AS PromedioDias;



--Funcion #2--

CREATE FUNCTION fn_PorcentajeDenunciasPorTipo()
RETURNS TABLE
AS
RETURN (
    SELECT 
        tipo_denuncia,
        COUNT(*) AS total,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Denuncia), 2) AS porcentaje
    FROM Denuncia
    GROUP BY tipo_denuncia
);

SELECT * FROM fn_PorcentajeDenunciasPorTipo();


--Funcion 3--
CREATE FUNCTION fn_CasosResueltosPorRegion()
RETURNS TABLE
AS
RETURN (
    SELECT 
        region_hecho,
        COUNT(*) AS total_resueltos
    FROM Desaparicion
    WHERE situacion_resolucion LIKE '%resuelto%'
    GROUP BY region_hecho
);

SELECT * FROM fn_CasosResueltosPorRegion();

--funcion 4--

CREATE FUNCTION fn_CasosPorGrupoEtario()
RETURNS @Resultado TABLE (
    grupo_etario VARCHAR(50),
    total INT
)
AS
BEGIN
    DECLARE @Grupos TABLE (
        id INT IDENTITY(1,1),
        id_grupo_etario VARCHAR(6),
        grupo_etario VARCHAR(50)
    );

    -- Insertamos todos los grupos etarios
    INSERT INTO @Grupos (id_grupo_etario, grupo_etario)
    SELECT id_grupo_etario, grupo_etario FROM Grupo_Etario;

    DECLARE @i INT = 1;
    DECLARE @max INT = (SELECT COUNT(*) FROM @Grupos);
    DECLARE @grupo_nombre VARCHAR(50);
    DECLARE @grupo_id VARCHAR(6);
    DECLARE @conteo INT;

    WHILE @i <= @max
    BEGIN
        SELECT @grupo_id = id_grupo_etario, @grupo_nombre = grupo_etario
        FROM @Grupos WHERE id = @i;

        SELECT @conteo = COUNT(*)
        FROM Persona p
        JOIN Desaparicion d ON p.id_persona = d.id_persona
        WHERE p.id_grupo_etario = @grupo_id;

        INSERT INTO @Resultado (grupo_etario, total)
        VALUES (@grupo_nombre, @conteo);

        SET @i = @i + 1;
    END

    RETURN;
END;

SELECT * FROM fn_CasosPorGrupoEtario();


----- Procedimiento 1 ----

CREATE PROCEDURE sp_DenunciasActivas
AS
BEGIN
    SELECT 
        d.id_denuncia,
        p.nombres,
        p.apellidos,
        des.fecha_hecho,
        des.situacion_resolucion
    FROM Denuncia d
    JOIN Desaparicion des ON d.id_denuncia = des.id_denuncia
    JOIN Persona p ON p.id_persona = des.id_persona
    WHERE des.situacion_resolucion NOT LIKE '%resuelto%'
END;

EXEC sp_DenunciasActivas;


-----Procedimiento 2----
CREATE PROCEDURE sp_ActualizarEstadoDenuncia
    @id_desaparicion VARCHAR(50),
    @nuevo_estado VARCHAR(100)
AS
BEGIN
    UPDATE Desaparicion
    SET situacion_resolucion = @nuevo_estado
    WHERE id_desaparicion = @id_desaparicion;
END;

EXEC sp_ActualizarEstadoDenuncia 'DES0541', 'resuelto';

----Procedimineto 3----
CREATE PROCEDURE sp_ActualizarCircunstancias
    @id_desaparicion VARCHAR(50),
    @nuevas_circunstancias TEXT
AS
BEGIN
    UPDATE Desaparicion
    SET circunstancias = @nuevas_circunstancias
    WHERE id_desaparicion = @id_desaparicion;
END;

EXEC sp_ActualizarCircunstancias 
    @id_desaparicion = 'DESA0143',
    @nuevas_circunstancias = 'Fue vista por última vez saliendo del colegio en horas de la tarde.';

---Trigger 1----

CREATE TRIGGER trg_actualizar_dias_desaparecido
ON Desaparicion
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE d
    SET d.dias_desaparecido = DATEDIFF(DAY, i.fecha_hecho, GETDATE())
    FROM Desaparicion d
    INNER JOIN inserted i ON d.id_desaparicion = i.id_desaparicion;
END;

---Trigerr 2 ----

CREATE TRIGGER trg_BloquearFechaFutura
ON Desaparicion
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE fecha_hecho > GETDATE()
    )
    BEGIN
        RAISERROR('No se puede registrar una desaparición con fecha futura.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO Desaparicion (
            id_desaparicion, id_persona, id_denuncia, fecha_hecho,
            distrito_hecho, provincia_hecho, departamento_hecho, region_hecho,
            calle_hecho, referencia_hecho, circunstancias, situacion_resolucion, dias_desaparecido
        )
        SELECT 
            id_desaparicion, id_persona, id_denuncia, fecha_hecho,
            distrito_hecho, provincia_hecho, departamento_hecho, region_hecho,
            calle_hecho, referencia_hecho, circunstancias, situacion_resolucion, dias_desaparecido
        FROM inserted;
    END
END;












