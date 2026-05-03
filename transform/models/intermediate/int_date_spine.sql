with date_spine as (

    {{
        dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2024-04-01' as date)",
            end_date="cast('2026-04-30' as date)"
        )
    }}

),

dates as (

    select
        date_day                                        as date,
        EXTRACT(year from date_day)::integer            as year,
        EXTRACT(quarter from date_day)::integer         as quarter,
        EXTRACT(month from date_day)::integer           as month,
        STRFTIME(date_day, '%B')                        as month_name,
        EXTRACT(week from date_day)::integer            as week_of_year,
        EXTRACT(dow from date_day)::integer             as day_of_week_num,
        STRFTIME(date_day, '%A')                        as day_name,

        -- weekend flag (0=Sunday, 6=Saturday in DuckDB)
        CASE
            WHEN EXTRACT(dow from date_day) IN (0, 6) THEN true
            ELSE false
        END                                             as is_weekend,

        -- season (meteorological)
        CASE
            WHEN EXTRACT(month from date_day) IN (12, 1, 2)  THEN 'Winter'
            WHEN EXTRACT(month from date_day) IN (3, 4, 5)   THEN 'Spring'
            WHEN EXTRACT(month from date_day) IN (6, 7, 8)   THEN 'Summer'
            WHEN EXTRACT(month from date_day) IN (9, 10, 11) THEN 'Fall'
        END                                             as season,

        -- quarter label
        'Q' || EXTRACT(quarter from date_day)::integer  as quarter_label

    from date_spine

)

select * from dates
