-- Load required extensions
LOAD a5;
LOAD spatial;

SET geometry_always_xy = true;

WITH flattened_json AS (
    -- Read and unnest the nested JSON structure
    SELECT
        r.nome AS zone,
        unnest(r.bairros) AS neighborhood
    FROM (
        SELECT unnest(regioes) AS r
        FROM read_json_auto('D:\Personal\projects\duckdb_extensions\extensions\a5\data\sao_paulo_bairros_utf8.json')
    )
),
mock_coordinates AS (
    -- Mock latitude and longitude data for testing
    SELECT 'Tatuape' AS neighborhood, -46.5772 AS lon, -23.5405 AS lat UNION ALL
    SELECT 'Moema'   AS neighborhood, -46.6575 AS lon, -23.6001 AS lat UNION ALL
    SELECT 'Pinheiros' AS neighborhood, -46.6967 AS lon, -23.5615 AS lat
)
-- Join data and generate A5 GeoJSON polygons
SELECT
    j.zone,
    j.neighborhood,
    c.lon,
    c.lat,
    a5_lonlat_to_cell(c.lon, c.lat, 12) AS a5_cell_id,
    ST_AsGeoJSON(a5_cell_to_geometry(a5_lonlat_to_cell(c.lon, c.lat, 12))) AS geojson_polygon
FROM flattened_json j
JOIN mock_coordinates c
  ON j.neighborhood = c.neighborhood;

-- generate the file
COPY (
    WITH flattened_json AS (
        SELECT
            r.nome AS zone,
            unnest(r.bairros) AS neighborhood
        FROM (
            SELECT unnest(regioes) AS r
            FROM read_json_auto('D:\Personal\projects\duckdb_extensions\extensions\a5\data\sao_paulo_bairros_utf8.json')
        )
    ),
    mock_coordinates AS (
        SELECT 'Tatuape' AS neighborhood, -46.5772 AS lon, -23.5405 AS lat UNION ALL
        SELECT 'Moema'   AS neighborhood, -46.6575 AS lon, -23.6001 AS lat UNION ALL
        SELECT 'Pinheiros' AS neighborhood, -46.6967 AS lon, -23.5615 AS lat
    )
    SELECT
        j.zone,
        j.neighborhood,
        c.lon,
        c.lat,
        a5_lonlat_to_cell(c.lon, c.lat, 12) AS a5_cell_id,
        -- ¡OJO AQUÍ! Quitamos ST_AsGeoJSON para enviar la geometría nativa a GDAL
        a5_cell_to_geometry(a5_lonlat_to_cell(c.lon, c.lat, 12)) AS geom
    FROM flattened_json j
    JOIN mock_coordinates c
      ON j.neighborhood = c.neighborhood
) TO 'D:\Personal\projects\duckdb_extensions\extensions\a5\data\mapa_kepler.geojson'
WITH (FORMAT GDAL, DRIVER 'GeoJSON');
