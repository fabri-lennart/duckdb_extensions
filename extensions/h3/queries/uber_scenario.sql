INSTALL h3 FROM community;
LOAD h3;

COPY (
    WITH raw_mobility AS (
        SELECT
            request_id,
            timestamp,
            lat,
            lon,
            status,
            passenger_rating,
            h3_latlng_to_cell(lat, lon, 8) AS h3_cell_int
        FROM read_csv_auto('data/sao_paulo_urban_mobility_1500.csv')
    )
    SELECT
        h3_cell_int,
        printf('%x', h3_cell_int) AS h3_cell_hex,
        COUNT(*) AS total_requests,
        COUNT(*) FILTER (WHERE status = 'COMPLETED') AS completed_trips,
        COUNT(*) FILTER (WHERE status = 'NO_DRIVERS_AVAILABLE') AS no_drivers_count,
        COUNT(*) FILTER (WHERE status = 'CANCELLED') AS cancelled_count,
        ROUND(
            (COUNT(*) FILTER (WHERE status IN ('NO_DRIVERS_AVAILABLE', 'CANCELLED')) * 100.0) / COUNT(*),
            2
        ) AS friction_rate_pct,
        ROUND(AVG(passenger_rating), 2) AS avg_passenger_rating
    FROM raw_mobility
    GROUP BY h3_cell_int
    ORDER BY total_requests DESC
) TO 'outputs/sao_paulo_h3_res8_summary.csv' (HEADER, DELIMITER ',');
