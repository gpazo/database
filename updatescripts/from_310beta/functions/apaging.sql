SELECT dropIfExists('FUNCTION', 'apaging(date)', 'public');

CREATE OR REPLACE FUNCTION apaging(date, boolean) RETURNS SETOF apaging AS $$
DECLARE
  pAsOfDate ALIAS FOR $1;
  pUseDocDate ALIAS FOR $2;
  _row apaging%ROWTYPE;
  _x RECORD;
  _returnVal INTEGER;
BEGIN

  FOR _x IN
        SELECT

        --report uses currtobase to convert all amounts to base based on apopen_docdate
        --apapplied function converts all amounts to base based on apapply_postdate

        --today and greater base:
        CASE WHEN((apopen_duedate >= DATE(pAsOfDate)))
        THEN ((currtobase(apopen_curr_id,apopen_amount,apopen_docdate)-apapplied(apopen_id,pAsOfDate)) *
        CASE WHEN (apopen_doctype IN ('C', 'R')) THEN -1 ELSE 1 END) ELSE 0 END AS cur_val,

        --0 to 30 base
        CASE WHEN((apopen_duedate >= DATE(pAsOfDate)-30) AND (apopen_duedate < DATE(pAsOfDate)))
        THEN ((currtobase(apopen_curr_id,apopen_amount,apopen_docdate)-apapplied(apopen_id,pAsOfDate)) *
        CASE WHEN (apopen_doctype IN ('C', 'R')) THEN -1 ELSE 1 END) ELSE 0 END AS thirty_val,

        --30-60 base
        CASE WHEN((apopen_duedate >= DATE(pAsOfDate)-60) AND (apopen_duedate < DATE(pAsOfDate) - 30 ))
        THEN ((currtobase(apopen_curr_id,apopen_amount,apopen_docdate)-apapplied(apopen_id,pAsOfDate)) *
        CASE WHEN (apopen_doctype IN ('C', 'R')) THEN -1 ELSE 1 END) ELSE 0 END AS sixty_val,

        --60-90 base
        CASE WHEN((apopen_duedate >= DATE(pAsOfDate)-90) AND (apopen_duedate < DATE(pAsOfDate) - 60))
        THEN ((currtobase(apopen_curr_id,apopen_amount,apopen_docdate)-apapplied(apopen_id,pAsOfDate)) *
        CASE WHEN (apopen_doctype IN ('C', 'R')) THEN -1 ELSE 1 END) ELSE 0 END AS ninety_val,

        --greater than 90 base:
        CASE WHEN((apopen_duedate > DATE(pAsOfDate)-10000) AND (apopen_duedate < DATE(pAsOfDate) - 90))
        THEN ((currtobase(apopen_curr_id,apopen_amount,apopen_docdate)-apapplied(apopen_id,pAsOfDate)) *
        CASE WHEN (apopen_doctype IN ('C', 'R')) THEN -1 ELSE 1 END) ELSE 0 END AS plus_val,

        --total amount base:
        CASE WHEN((apopen_duedate > DATE(pAsOfDate)-10000))
        THEN ((currtobase(apopen_curr_id,apopen_amount,apopen_docdate)-apapplied(apopen_id,pAsOfDate)) *
        CASE WHEN (apopen_doctype IN ('C', 'R')) THEN -1 ELSE 1 END) ELSE 0 END AS total_val,

        --AP Open Amount base

        CASE WHEN apopen_doctype IN ('C', 'R')
        THEN currtobase(apopen_curr_id,(apopen_amount * -1),apopen_docdate) ELSE currtobase(apopen_curr_id,apopen_amount,apopen_docdate) END AS apopen_amount,

        --Discount AMT base
        CASE WHEN((DATE(pAsOfDate) <= apopen_docdate  + terms_discdays))
        THEN (currtobase(apopen_curr_id,(apopen_amount * terms_discprcnt),apopen_docdate) *
        CASE WHEN (apopen_doctype='C') THEN 0 ELSE 1 END) ELSE 0 END AS disc_val,

        CASE WHEN((apopen_doctype<>'C') AND (DATE(pAsOfDate) <= apopen_docdate  + terms_discdays)) THEN apopen_docdate  + terms_discdays
        ELSE NULL END AS disc_date,

        apopen_docdate,
        apopen_duedate,
        apopen_ponumber,
        apopen_reference,
        apopen_invcnumber,
        apopen_docnumber,
        apopen_doctype,
        vend_id,
        vend_name,
        vend_number,
        vend_vendtype_id,
        vendtype_code,
        terms_descrip,
        terms_discdays,
        terms_discprcnt

        FROM apopen, vendinfo, vendtype, terms
        WHERE ( (apopen_vend_id IS NOT NULL)
        AND (apopen_vend_id = vend_id)
        AND (vend_terms_id = terms_id)
        AND (vend_vendtype_id=vendtype_id)
        AND (CASE WHEN(pUseDocDate) THEN apopen_docdate ELSE apopen_distdate END <= pAsOfDate)
        AND (COALESCE(apopen_closedate,pAsOfdate+1)>pAsOfdate)
        AND ((currtobase(apopen_curr_id,apopen_amount,apopen_docdate) - apapplied(apopen_id,pAsofdate)) > 0)  )
        ORDER BY vend_number, apopen_duedate
  LOOP
        _row.apaging_docdate := _x.apopen_docdate;
        _row.apaging_duedate := _x.apopen_duedate;
        _row.apaging_ponumber := _x.apopen_ponumber;
        _row.apaging_reference := _x.apopen_reference;
        _row.apaging_invcnumber := _x.apopen_invcnumber;
        _row.apaging_docnumber := _x.apopen_docnumber;
        _row.apaging_doctype := _x.apopen_doctype;
        _row.apaging_vend_id := _x.vend_id;
        _row.apaging_vend_number := _x.vend_number;
        _row.apaging_vend_name := _x.vend_name;
        _row.apaging_vend_vendtype_id := _x.vend_vendtype_id;
        _row.apaging_vendtype_code := _x.vendtype_code;
        _row.apaging_terms_descrip := _x.terms_descrip;
        _row.apaging_apopen_amount := _x.apopen_amount;
        _row.apaging_cur_val := _x.cur_val;
        _row.apaging_thirty_val := _x.thirty_val;
        _row.apaging_sixty_val := _x.sixty_val;
        _row.apaging_ninety_val := _x.ninety_val;
        _row.apaging_plus_val := _x.plus_val;
        _row.apaging_total_val := _x.total_val;
        _row.apaging_discdate := _x.disc_date;
        _row.apaging_disc_val := _x.disc_val;
        _row.apaging_discdays := _x.terms_discdays;
        _row.apaging_discprcnt := _x.terms_discprcnt;
        RETURN NEXT _row;
  END LOOP;
  RETURN;
END;
$$ LANGUAGE 'plpgsql';
