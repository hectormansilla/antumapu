DECLARE
   exectime    timestamp without time zone := NOW();
BEGIN
    -- Borrar la tabla temporal
    DROP TABLE IF EXISTS temp;

    -- Borrar la tabla de procesos en ejecución
	DELETE FROM running;

    -- Crear la BD temporal
    CREATE TABLE temp(
        malla text,
        proceso text,
        estado text,
        ws text,
        opnum text,
        fejecucion text,
        hejecucion text,
        ftermino text,
        htermino text,
        duracion text,
        -- Inicio de campos adicionales para evitar errores en la importación
        x11 text,
        x12 text,
        x13 text,
        x14 text,
        x15 text,
        x16 text,
        x17 text,
        x18 text,
        x19 text,
        x20 text);

    -- Importar el archivo enviado desde el mainframe
    COPY temp FROM 'C:\temp\ingreso.csv' (FORMAT CSV, DELIMITER(';'), ENCODING('UTF8'));

    -- Inserta los valores en la tabla en_ejecucion
    INSERT INTO running(malla, proceso, estado, ws, opnum, inicio)
	SELECT malla, proceso, estado, ws, opnum::integer, TO_TIMESTAMP(fejecucion || ' ' || hejecucion,'YYYY-MM-DD HH24:MI:SS')
		FROM temp
        WHERE estado = 'S' AND proceso != 'DUMMY   ' AND proceso != 'IEFBR14 ' AND ws != 'MANU' AND malla NOT LIKE '%RUNJ%';

	-- Inserta los valores en la vista temporal consulta_promedio
	CREATE OR REPLACE VIEW consulta_promedio AS
	SELECT running.malla, running.proceso, running.ws, running.opnum, running.inicio, limiter.promedio
		FROM running INNER JOIN limiter on running.proceso = limiter.proceso;

	-- Inserta los procesos con tiempo excedido en la tabla TimeOut
	INSERT INTO timeout(malla, proceso, ws, opnum, inicio, ejecucion, ahora, justificar, promedio)
    SELECT malla, proceso, ws, opnum, inicio, age(exectime, te.inicio), exectime, TRUE, te.promedio
    	FROM consulta_promedio AS te
		WHERE age(exectime, te.inicio) > te.promedio AND
         NOT EXISTS (
                SELECT * FROM timeout WHERE
                timeout.proceso = te.proceso AND
                timeout.opnum = te.opnum AND
                timeout.inicio = te.inicio);
		raise notice 'Ahora: %', exectime;


	-- Actualiza los procesos con tiempo excedido previamente ingresados a la tabla TimeOut
    UPDATE timeout
    SET ejecucion = age(exectime, te2.inicio),
 		ahora = exectime,
 		justificar = TRUE
	FROM consulta_promedio AS te2
		WHERE age(exectime, te2.inicio) > te2.promedio AND
        timeout.proceso = te2.proceso AND
        timeout.opnum = te2.opnum AND
        timeout.inicio = te2.inicio;


    -- Inserta los procesos que no tengan los promedios informados
	INSERT INTO pending(malla, proceso, ws, opnum, inicio, ahora)
    SELECT running.malla, running.proceso, running.ws, running.opnum, running.inicio, exectime
		FROM running LEFT JOIN limiter on running.proceso = limiter.proceso
        WHERE limiter.promedio IS NULL AND
         NOT EXISTS (
                SELECT * FROM pending WHERE
                pending.proceso = running.proceso);

    -- Destruye la vista temporal consulta_promedio
    DROP VIEW IF EXISTS consulta_promedio;

END; -- Fin del procedimiento
