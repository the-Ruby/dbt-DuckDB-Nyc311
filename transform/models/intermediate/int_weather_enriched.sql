with weather as (

    select * from {{ ref('stg_weather_daily') }}

),

enriched as (

    select
        date,
        temp_max_c,
        temp_min_c,
        precipitation_mm,
        wind_speed_max_kmh,
        weather_code,

        -- human-readable weather description from WMO weather code
        CASE
            WHEN weather_code = 0                       THEN 'Clear'
            WHEN weather_code IN (1, 2, 3)              THEN 'Cloudy'
            WHEN weather_code IN (45, 48)               THEN 'Fog'
            WHEN weather_code BETWEEN 51 AND 67         THEN 'Rain'
            WHEN weather_code BETWEEN 71 AND 77         THEN 'Snow'
            WHEN weather_code BETWEEN 80 AND 82         THEN 'Showers'
            WHEN weather_code BETWEEN 95 AND 99         THEN 'Thunderstorm'
            ELSE 'Other'
        END                                             as weather_description,

        -- temperature category based on max temp
        CASE
            WHEN temp_max_c < 0                         THEN 'Freezing'
            WHEN temp_max_c < 10                        THEN 'Cold'
            WHEN temp_max_c < 20                        THEN 'Mild'
            WHEN temp_max_c < 30                        THEN 'Warm'
            ELSE 'Hot'
        END                                             as temp_category,

        -- average temperature
        ROUND((temp_max_c + temp_min_c) / 2, 1)        as temp_avg_c,

        -- precipitation flag
        CASE
            WHEN precipitation_mm > 0 THEN true
            ELSE false
        END                                             as had_precipitation

    from weather

)

select * from enriched
