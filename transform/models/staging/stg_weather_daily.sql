with source as (

    select * from {{ source('raw', 'weather_daily') }}

),

renamed as (

    select
        date,
        temperature_2m_max          as temp_max_c,
        temperature_2m_min          as temp_min_c,
        precipitation_sum           as precipitation_mm,
        wind_speed_10m_max          as wind_speed_max_kmh,
        weathercode                 as weather_code

        -- dropped: _dlt_id, _dlt_load_id (dlt internals)

    from source

)

select * from renamed
