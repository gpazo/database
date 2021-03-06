CREATE OR REPLACE FUNCTION _imageassTrigger () RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.imageass_source = 'INCDT') THEN
    UPDATE incdt SET incdt_updated = now() WHERE incdt_id = NEW.imageass_source_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropifexists('TRIGGER' ,'imageassTrigger');
CREATE TRIGGER imageassTrigger AFTER INSERT OR UPDATE ON imageass FOR EACH ROW EXECUTE PROCEDURE _imageassTrigger();
