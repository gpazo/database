CREATE OR REPLACE FUNCTION checkBOOSitePrivs(INTEGER) RETURNS BOOLEAN AS '
DECLARE
  pBooheadid ALIAS FOR $1;
  _check    BOOLEAN;
  _result   INTEGER;

BEGIN

  SELECT COALESCE(usrpref_value::BOOLEAN, false) INTO _check
    FROM usrpref
   WHERE ( (usrpref_username=current_user)
     AND   (usrpref_name=''selectedSites'') );
  IF (NOT _check) THEN
    RETURN true;
  END IF;

  SELECT COALESCE(COUNT(*), 0) INTO _result
    FROM ( SELECT booitem_id
             FROM boohead, booitem, wrkcnt
            WHERE ( (boohead_id=pBooheadid)
              AND   (booitem_item_id=boohead_item_id)
              AND   (booitem_rev_id=boohead_rev_id)
              AND   (booitem_wrkcnt_id=wrkcnt_id)
              AND   (wrkcnt_warehous_id NOT IN (SELECT usrsite_warehous_id
                                                    FROM usrsite
                                                   WHERE (usrsite_username=current_user))) )
         ) AS data;
  IF (_result > 0) THEN
    RETURN false;
  END IF;

  RETURN true;
END;
' LANGUAGE 'plpgsql';