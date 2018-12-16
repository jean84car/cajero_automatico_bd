-- FUNCTION: cajero_db.fn_registrar_denominacion(character varying)

-- DROP FUNCTION cajero_db.fn_registrar_denominacion(character varying);

/**************************************************************************
    NOMBRE:         cajero_db.fn_registrar_denominacion
    TIPO:           funcion
    PROPOSITO:      permite registrar las denominaciones con la cantidad.
					recibe un parametro en string en formato json con los
					respectivos valores.
    ***************************************************************************/ 

CREATE OR REPLACE FUNCTION cajero_db.fn_registrar_denominacion(
	p_solicitud character varying,
	OUT p_respuesta character varying)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

	c_cod_respuesta			CONSTANT VARCHAR(6) := '0';
	
	v_respuesta				JSON;
	v_solicitud				JSON;
	v_denominacion_json		JSON;
	v_denominacion			cajero_db.cj_denominacion.denominacion%TYPE;
	v_cantidad				cajero_db.cj_denominacion.cantidad%TYPE;
	v_id_denominacion		cajero_db.cj_denominacion.id_denominacion%TYPE;
	
BEGIN

	v_solicitud	:= p_solicitud::JSON;
	v_denominacion	:= v_solicitud->'denominacion';	
	v_cantidad := v_solicitud->'cantidad';
		
	SELECT id_denominacion INTO v_id_denominacion FROM cajero_db.cj_denominacion WHERE denominacion = v_denominacion;
	IF v_id_denominacion IS NOT NULL THEN
		UPDATE cajero_db.cj_denominacion SET cantidad = v_cantidad + cantidad WHERE id_denominacion = v_id_denominacion;
	ELSE
		INSERT INTO cajero_db.cj_denominacion (denominacion, cantidad) 
			VALUES (v_denominacion, v_cantidad) RETURNING id_denominacion INTO v_id_denominacion;
	END IF;
	
	v_denominacion_json := json_build_object(
		'idDenominacion',v_id_denominacion,
		'denominacion',v_denominacion,
		'cantidad',v_cantidad
	);
	
	v_respuesta := json_build_object(
		'exito',true,
		'codRespuesta', c_cod_respuesta,
		'denominacion', v_denominacion_json
	);

	p_respuesta := v_respuesta;
	
END;
$BODY$;

ALTER FUNCTION cajero_db.fn_registrar_denominacion(character varying)
    OWNER TO postgres;
