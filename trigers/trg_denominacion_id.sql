CREATE OR REPLACE FUNCTION cajero_db.trg_denominacion_id() 
RETURNS trigger AS $$
    BEGIN
       
        IF NEW.id_denominacion IS NULL THEN
            SELECT TO_CHAR(current_timestamp, 'DDDMISSYY')||LPAD(NEW.denominacion::VARCHAR, 6, '0') INTO NEW.id_denominacion; 
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_denominacion_id BEFORE INSERT OR UPDATE ON cajero_db.cj_denominacion
    FOR EACH ROW EXECUTE PROCEDURE cajero_db.trg_denominacion_id();