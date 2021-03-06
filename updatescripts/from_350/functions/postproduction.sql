CREATE OR REPLACE FUNCTION postProduction(INTEGER, NUMERIC, BOOLEAN, INTEGER, TIMESTAMP WITH TIME ZONE) RETURNS INTEGER AS $$
DECLARE
  pWoid          ALIAS FOR $1;
  pQty           ALIAS FOR $2;
  pBackflush     ALIAS FOR $3;
  pItemlocSeries ALIAS FOR $4;
  pGlDistTS      ALIAS FOR $5;
  _invhistid     INTEGER;
  _itemlocSeries INTEGER;
  _parentQty     NUMERIC;
  _r             RECORD;
  _sense         TEXT;
  _wipPost       NUMERIC;
  _woNumber      TEXT;

BEGIN

  IF (pQty = 0) THEN
    RETURN 0;
  ELSIF (pQty > 0) THEN
    _sense = 'from';
  ELSE
    _sense = 'to';
  END IF;

  IF ( ( SELECT wo_status
         FROM wo
         WHERE (wo_id=pWoid) ) NOT IN  ('R','E','I') ) THEN
    RETURN -1;
  END IF;

  SELECT formatWoNumber(pWoid) INTO _woNumber;

  SELECT roundQty(item_fractional, pQty) INTO _parentQty
  FROM wo, itemsite, item
  WHERE ((wo_itemsite_id=itemsite_id)
   AND (itemsite_item_id=item_id)
   AND (wo_id=pWoid));

--  Create the material receipt transaction
  IF (pItemlocSeries = 0) THEN
    SELECT NEXTVAL('itemloc_series_seq') INTO _itemlocSeries;
  ELSE
    _itemlocSeries = pItemlocSeries;
  END IF;

  IF (pBackflush) THEN
    FOR _r IN SELECT womatl_id, womatl_qtyiss + 
		     (CASE 
		       WHEN (womatl_qtywipscrap >  ((womatl_qtyfxd + (_parentQty + wo_qtyrcv) * womatl_qtyper) * womatl_scrap)) THEN
                         (womatl_qtyfxd + (_parentQty + wo_qtyrcv) * womatl_qtyper) * womatl_scrap
		       ELSE 
		         womatl_qtywipscrap 
		      END) AS consumed,
		     (womatl_qtyfxd + ((_parentQty + wo_qtyrcv) * womatl_qtyper)) * (1 + womatl_scrap) AS expected
	      FROM womatl, wo, itemsite, item
	      WHERE ((womatl_issuemethod IN ('L', 'M'))
		AND  (womatl_wo_id=pWoid)
		AND  (womatl_wo_id=wo_id)
		AND  (womatl_itemsite_id=itemsite_id)
		AND  (itemsite_item_id=item_id)) LOOP
      -- Don't issue more than should have already been consumed at this point
      IF (noNeg(_r.expected - _r.consumed) > 0) THEN
        SELECT issueWoMaterial(_r.womatl_id, noNeg(_r.expected - _r.consumed), _itemlocSeries) INTO _itemlocSeries;
      END IF;

      UPDATE womatl
      SET womatl_issuemethod='L'
      WHERE ( (womatl_issuemethod='M')
       AND (womatl_id=_r.womatl_id) );

    END LOOP;
  END IF;

  SELECT CASE
           WHEN (wo_cosmethod = 'D') THEN
             wo_wipvalue
           ELSE
             round((wo_wipvalue - (wo_postedvalue / wo_qtyord * (wo_qtyord -
               CASE
                 WHEN (wo_qtyord < wo_qtyrcv + pQty) THEN
                       wo_qtyord
                 ELSE
                       wo_qtyrcv + pQty
                 END ))),2)
         END INTO _wipPost
  FROM wo
  WHERE (wo_id=pWoid);

  SELECT postInvTrans( itemsite_id, 'RM', _parentQty,
                       'W/O', 'WO', _woNumber, '', ('Receive Inventory ' || item_number || ' ' || _sense || ' Manufacturing'),
                       costcat_asset_accnt_id, costcat_wip_accnt_id, _itemlocSeries, pGlDistTS,
                       -- the following is only actually used when the item is average or job costed
                       _wipPost ) INTO _invhistid
  FROM wo, itemsite, item, costcat
  WHERE ( (wo_itemsite_id=itemsite_id)
   AND (itemsite_item_id=item_id)
   AND (itemsite_costcat_id=costcat_id)
   AND (wo_id=pWoid) );

--  Increase this W/O's received qty decrease its WIP value
  UPDATE wo
  SET wo_qtyrcv = (wo_qtyrcv + _parentQty),
      wo_wipvalue = (wo_wipvalue - (CASE WHEN (itemsite_costmethod IN ('A','J')) THEN _wipPost ELSE (stdcost(itemsite_item_id) * _parentQty)  END))
  FROM itemsite, item
  WHERE ((wo_itemsite_id=itemsite_id)
   AND (itemsite_item_id=item_id)
   AND (wo_id=pWoid));

--  ROB Increase this W/O's WIP value for custom costing
  UPDATE wo
  SET wo_wipvalue = (wo_wipvalue + (itemcost_stdcost * _parentQty)) 
FROM costelem, itemcost, costcat, itemsite, item
WHERE 
  ((wo_id=pWoid) AND
  (wo_itemsite_id=itemsite_id) AND
  (itemsite_item_id=item_id) AND
  (costelem_id = itemcost_costelem_id) AND
  (itemcost_item_id = itemsite_item_id) AND
  (itemsite_costcat_id = costcat_id) AND
  (costelem_exp_accnt_id) IS NOT NULL  AND 
  (costelem_sys = false));

--  ROB Distribute to G/L - create Cost Variance, debit WIP
  PERFORM insertGLTransaction( 'W/O', 'WO', _woNumber,
                               ('Post Other Cost ' || item_number || ' ' || _sense || ' Manufacturing'),
                               costelem_exp_accnt_id, costcat_wip_accnt_id, _invhistid,
			       (itemcost_stdcost * _parentQty),
                               CURRENT_DATE )
FROM wo, costelem, itemcost, costcat, itemsite, item
WHERE 
  ((wo_id=pWoid) AND
  (wo_itemsite_id=itemsite_id) AND
  (itemsite_item_id=item_id) AND
  (costelem_id = itemcost_costelem_id) AND
  (itemcost_item_id = itemsite_item_id) AND
  (itemsite_costcat_id = costcat_id) AND
  (costelem_exp_accnt_id) IS NOT NULL  AND 
  (costelem_sys = false));
--End


--  Make sure the W/O is at issue status
  UPDATE wo
  SET wo_status='I'
  WHERE (wo_id=pWoid);

  RETURN _itemlocSeries;

END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION postProduction(INTEGER, NUMERIC, BOOLEAN, BOOLEAN) RETURNS INTEGER AS $$
BEGIN
  RAISE NOTICE 'postProduction(INTEGER, NUMERIC, BOOLEAN, BOOLEAN) is deprecated. please use postProduction(INTEGER, NUMERIC, BOOLEAN, INTEGER, TIMESTAMP WITH TIME ZONE) instead';
  RETURN postProduction($1, $2, $3, 0, now());
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION postProduction(INTEGER, NUMERIC, BOOLEAN, BOOLEAN, INTEGER) RETURNS INTEGER AS $$
BEGIN
  RAISE NOTICE 'postProduction(INTEGER, NUMERIC, BOOLEAN, BOOLEAN, INTEGER) is deprecated. please use postProduction(INTEGER, NUMERIC, BOOLEAN, INTEGER, TIMESTAMP WITH TIME ZONE) instead';
  RETURN postProduction($1, $2, $3, $5, now());
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION postProduction(INTEGER, NUMERIC, BOOLEAN, BOOLEAN, INTEGER, TEXT, TEXT) RETURNS INTEGER AS $$
BEGIN
  RAISE NOTICE 'postProduction(INTEGER, NUMERIC, BOOLEAN, BOOLEAN, INTEGER, TEXT, TEXT) is deprecated. please use postProduction(INTEGER, NUMERIC, BOOLEAN, INTEGER, TIMESTAMP WITH TIME ZONE) instead';
  RETURN postProduction($1, $2, $3, $5, now());
END;
$$ LANGUAGE 'plpgsql';
