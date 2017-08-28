CREATE OR REPLACE FUNCTION st_fineltra(
	p_geom IN MDSYS.SDO_GEOMETRY,
	p_table_name IN varchar2,
	p_src_column IN varchar2,
	p_tgt_column IN varchar2
) RETURN MDSYS.SDO_GEOMETRY
IS
	s1x NUMBER;  s1y NUMBER;
	s2x NUMBER;  s2y NUMBER;
	s3x NUMBER;  s3y NUMBER;

	t1x NUMBER;  t1y NUMBER;
	t2x NUMBER;  t2y NUMBER;
	t3x NUMBER;  t3y NUMBER;

	v1x NUMBER;  v1y NUMBER;
	v2x NUMBER;  v2y NUMBER;
	v3x NUMBER;  v3y NUMBER;

	x NUMBER;   y NUMBER;

	p1 NUMBER;
	p2 NUMBER;
	p3 NUMBER;
	pt NUMBER;

	v_geom SDO_GEOMETRY;
	v_i INTEGER;
	v_ord INTEGER;
	v_dim INTEGER;
	v_sql varchar2(2000);

	v_src SDO_GEOMETRY;
	v_tgt SDO_GEOMETRY;
BEGIN
	IF p_geom IS NULL THEN
		RETURN NULL;
	END IF;

	v_geom := p_geom;
	v_dim := p_geom.get_dims();

	v_sql :=
		'SELECT '||p_src_column||','||p_tgt_column||' FROM '||p_table_name||
		' WHERE '||
			'sdo_relate('||p_src_column||
			',sdo_geometry(2001, :1, SDO_POINT_TYPE(:2, :3, NULL), NULL, NULL),''mask=CONTAINS'')=''TRUE''';

	IF v_geom.sdo_point IS NOT NULL THEN
		x := p_geom.sdo_point.x;
		y := p_geom.sdo_point.y;

		EXECUTE IMMEDIATE v_sql INTO v_src, v_tgt USING p_geom.sdo_srid, x, y;
		IF NOT SQL%FOUND THEN
			dbms_output.put_line('coordinate not found: X:'||x||' Y:'||y);
			RETURN NULL;
		END IF;

		s1x := v_src.sdo_ordinates(1);  s1y := v_src.sdo_ordinates(2);
		s2x := v_src.sdo_ordinates(3);  s2y := v_src.sdo_ordinates(4);
		s3x := v_src.sdo_ordinates(5);  s3y := v_src.sdo_ordinates(6);

		t1x := v_tgt.sdo_ordinates(1);  t1y := v_tgt.sdo_ordinates(2);
		t2x := v_tgt.sdo_ordinates(3);  t2y := v_tgt.sdo_ordinates(4);
		t3x := v_tgt.sdo_ordinates(5);  t3y := v_tgt.sdo_ordinates(6);

		v1x := t1x - s1x;  v1y := t1y - s1y;
		v2x := t2x - s2x;  v2y := t2y - s2y;
		v3x := t3x - s3x;  v3y := t3y - s3y;

		p1 := abs( 0.5 * ( x * (s2y - s3y) + s2x * ( s3y - y ) + s3x * ( y - s2y ) ) );
		p2 := abs( 0.5 * ( x * (s1y - s3y) + s1x * ( s3y - y ) + s3x * ( y - s1y ) ) );
		p3 := abs( 0.5 * ( x * (s1y - s2y) + s1x * ( s2y - y ) + s2x * ( y - s1y ) ) );
		pt := p1 + p2 + p3;

		v_geom.sdo_srid := v_tgt.sdo_srid;
		v_geom.sdo_point.x := x + (v1x*p1 + v2x*p2 + v3x*p3) / pt;
		v_geom.sdo_point.y := y + (v1y*p1 + v2y*p2 + v3y*p3) / pt;
	ELSE
		FOR v_i IN 1..(v_geom.sdo_ordinates.COUNT/v_dim) LOOP
			v_ord := (v_i-1)*v_dim + 1;

			x := p_geom.sdo_ordinates(v_ord);
			y := p_geom.sdo_ordinates(v_ord+1);

			EXECUTE IMMEDIATE v_sql INTO v_src, v_tgt USING p_geom.sdo_srid, x, y;
			IF NOT SQL%FOUND THEN
				dbms_output.put_line('coordinate not found: X:'||x||' Y:'||y);
				RETURN NULL;
			END IF;

			s1x := v_src.sdo_ordinates(1);  s1y := v_src.sdo_ordinates(2);
			s2x := v_src.sdo_ordinates(3);  s2y := v_src.sdo_ordinates(4);
			s3x := v_src.sdo_ordinates(5);  s3y := v_src.sdo_ordinates(6);

			t1x := v_tgt.sdo_ordinates(1);  t1y := v_tgt.sdo_ordinates(2);
			t2x := v_tgt.sdo_ordinates(3);  t2y := v_tgt.sdo_ordinates(4);
			t3x := v_tgt.sdo_ordinates(5);  t3y := v_tgt.sdo_ordinates(6);

			v1x := t1x - s1x;  v1y := t1y - s1y;
			v2x := t2x - s2x;  v2y := t2y - s2y;
			v3x := t3x - s3x;  v3y := t3y - s3y;

			p1 := abs( 0.5 * ( x * (s2y - s3y) + s2x * ( s3y - y ) + s3x * ( y - s2y ) ) );
			p2 := abs( 0.5 * ( x * (s1y - s3y) + s1x * ( s3y - y ) + s3x * ( y - s1y ) ) );
			p3 := abs( 0.5 * ( x * (s1y - s2y) + s1x * ( s2y - y ) + s2x * ( y - s1y ) ) );
			pt := p1 + p2 + p3;

			v_geom.sdo_srid := v_tgt.sdo_srid;
			v_geom.sdo_ordinates(v_ord)   := x + (v1x*p1 + v2x*p2 + v3x*p3) / pt;
			v_geom.sdo_ordinates(v_ord+1) := y + (v1y*p1 + v2y*p2 + v3y*p3) / pt;
		END LOOP;
	END IF;

	RETURN v_geom;
END st_fineltra;
/
