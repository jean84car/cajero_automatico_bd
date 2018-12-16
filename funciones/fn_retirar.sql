-- FUNCTION: cajero_db.fn_retirar(character varying)

-- DROP FUNCTION cajero_db.fn_retirar(character varying);

/**************************************************************************
    NOMBRE:         cajero_db.fn_retirar
    TIPO:           funcion
    PROPOSITO:      permite a los clientes retirar el dinero. Recibe un parametro
					json con el campo del valor a retirar.
    ***************************************************************************/ 

CREATE OR REPLACE FUNCTION cajero_db.fn_retirar(
	p_solicitud character varying,
	OUT p_respuesta character varying)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE
	
	v_respuesta				JSON;
	v_solicitud				JSON;
	v_denominacion			cajero_db.cj_denominacion.denominacion%TYPE;
	v_valor					NUMERIC(10,0);
	v_valor_aux				NUMERIC(10,0);
	v_n_billetes			NUMERIC(10,0);
	i_den					RECORD;
	v_respuesta_billetes	VARCHAR(200) := '';
	
BEGIN

	v_solicitud	:= p_solicitud::JSON;
	v_valor	:= v_solicitud->'valorRetirar';	
	v_valor_aux := v_valor;
	
	SELECT MIN(denominacion) INTO v_denominacion FROM cajero_db.cj_denominacion WHERE cantidad>0;
	
	IF v_valor < v_denominacion THEN
		v_respuesta := json_build_object(
			'exito',false,
			'mensaje', 'El cajero no dispone de la cantidad especificada. Minimo valor '||v_denominacion
		);
		p_respuesta := v_respuesta;
		RETURN;
	END IF;
	
	FOR i_den IN (
		SELECT id_denominacion, denominacion, cantidad 
			FROM cajero_db.cj_denominacion
			ORDER BY denominacion DESC
	) LOOP
	
		EXIT WHEN v_valor_aux = 0;
		
		IF i_den.denominacion <= v_valor_aux THEN
			v_n_billetes := TRUNC(v_valor_aux / i_den.denominacion);
			IF v_n_billetes <= i_den.cantidad THEN
				v_valor_aux := v_valor_aux - (i_den.denominacion * v_n_billetes);
				UPDATE cajero_db.cj_denominacion SET cantidad = i_den.cantidad - v_n_billetes 
					WHERE id_denominacion = i_den.id_denominacion;
				v_respuesta_billetes := v_respuesta_billetes||' '||v_n_billetes||'('||i_den.denominacion||')';
			ELSE
				v_valor_aux := v_valor_aux - (i_den.denominacion * i_den.cantidad);
				UPDATE cajero_db.cj_denominacion SET cantidad = 0
					WHERE id_denominacion = i_den.id_denominacion;
				v_respuesta_billetes := v_respuesta_billetes||' '||i_den.cantidad||'('||i_den.denominacion||')';
			END IF;
	
		END IF;
		
	END LOOP;
	
	IF v_valor_aux > 0 THEN
		--ROLLBACK;
		RAISE EXCEPTION 'Valor a retirar no disponible';
	END IF;
	
	v_respuesta_billetes := 'Valor solicitado: '||v_valor||'. Billetes entregados: '||v_respuesta_billetes;
	v_respuesta := json_build_object(
		'exito',true,
		'mensaje',v_respuesta_billetes 
	);

	p_respuesta := v_respuesta;
	
	EXCEPTION WHEN OTHERS THEN
		v_respuesta := json_build_object(
			'exito',false,
			'mensaje', 'El cajero no dispone de la cantidad especificada.'
		);
		p_respuesta := v_respuesta;
	
END;
$BODY$;

ALTER FUNCTION cajero_db.fn_retirar(character varying)
    OWNER TO postgres;
