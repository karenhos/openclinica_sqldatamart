CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_metadata_event_crf_ig()
  RETURNS VOID AS
$b$
/*
Study metadata; event, crf and item group levels.

Useful for understanding the overall study structure.
*/
DECLARE
  column_list TEXT;
  column_filter TEXT DEFAULT $r$^(study|event|crf|item_group).*$r$;
BEGIN
SELECT
  trim(BOTH $s$, $s$ FROM string_agg(s.attname, $s$, $s$)) AS column_list
  INTO column_list
FROM (
  SELECT
    pga.attname
  FROM pg_catalog.pg_attribute AS pga
  WHERE
    pga.attrelid = cast('dm.metadata' AS regclass)
    AND pga.attnum > 0
    AND NOT pga.attisdropped
    AND pga.attname ~ column_filter
  ORDER BY attnum
) as s;
EXECUTE format($q$
    CREATE MATERIALIZED VIEW dm.metadata_event_crf_ig AS
    SELECT DISTINCT ON (
      study_id,
      event_id,
      crf_version_id,
      item_group_id
    )
      %1$s
    FROM dm.metadata;
  $q$, column_list);
END;
$b$ LANGUAGE plpgsql VOLATILE;