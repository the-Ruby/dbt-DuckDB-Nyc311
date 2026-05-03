with service_requests as (

    select * from {{ ref('stg_service_requests') }}

),

enriched as (

    select
        -- all original staging columns
        unique_key,
        created_date,
        closed_date,
        due_date,
        last_modified_date,
        complaint_type,
        descriptor,
        descriptor_2,
        location_type,
        status,
        resolution_description,
        open_data_channel_type,
        agency,
        agency_name,
        community_board,
        council_district,
        police_precinct,
        bbl,
        zip_code,
        incident_address,
        street_name,
        cross_street_1,
        cross_street_2,
        intersection_street_1,
        intersection_street_2,
        address_type,
        landmark,
        x_coordinate,
        y_coordinate,
        latitude,
        longitude,
        park_facility_name,
        park_borough,
        vehicle_type,
        facility_type,
        bridge_highway_name,
        bridge_highway_direction,
        road_ramp,
        bridge_highway_segment,
        taxi_company_borough,
        taxi_pick_up_location,

        -- normalize borough casing
        CASE UPPER(TRIM(borough))
            WHEN 'MANHATTAN'     THEN 'Manhattan'
            WHEN 'BROOKLYN'      THEN 'Brooklyn'
            WHEN 'QUEENS'        THEN 'Queens'
            WHEN 'BRONX'         THEN 'Bronx'
            WHEN 'STATEN ISLAND' THEN 'Staten Island'
            ELSE borough
        END                                             AS borough,

        -- response time in hours (null for open requests)
        CASE
            WHEN closed_date IS NOT NULL
            THEN DATEDIFF('hour', created_date, closed_date)
        END                                             as response_time_hours,

        -- open/closed flag
        CASE
            WHEN UPPER(status) = 'OPEN' THEN true
            ELSE false
        END                                             as is_open,

        -- late closure flag (closed before created — data quality issue)
        CASE
            WHEN closed_date < created_date THEN true
            ELSE false
        END                                             as is_late_closure

    from service_requests

)

select * from enriched
