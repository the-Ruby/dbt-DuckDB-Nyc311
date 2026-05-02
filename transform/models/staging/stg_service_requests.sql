with source as (

    select * from {{ source('raw', 'service_requests') }}

),

renamed as (

    select
        -- identifiers
        unique_key,

        -- dates
        created_date,
        closed_date,
        due_date,
        resolution_action_updated_date  as last_modified_date,

        -- request details
        complaint_type,
        descriptor,
        descriptor_2,
        location_type,
        status,
        resolution_description,
        open_data_channel_type,

        -- agency
        agency,
        agency_name,

        -- location
        borough,
        city,
        incident_zip                    as zip_code,
        incident_address,
        street_name,
        cross_street_1,
        cross_street_2,
        intersection_street_1,
        intersection_street_2,
        address_type,
        landmark,
        community_board,
        TRY_CAST(REGEXP_REPLACE(council_district, '[^0-9]', '', 'g') AS INTEGER)  AS council_district,
        TRY_CAST(REGEXP_REPLACE(police_precinct, '[^0-9]', '', 'g') AS INTEGER)   AS police_precinct,
        bbl,
        x_coordinate_state_plane::double as x_coordinate,
        y_coordinate_state_plane::double as y_coordinate,
        latitude::double                as latitude,
        longitude::double               as longitude,

        -- domain-specific (mostly null, kept for completeness)
        park_facility_name,
        park_borough,
        vehicle_type,
        facility_type,
        bridge_highway_name,
        bridge_highway_direction,
        road_ramp,
        bridge_highway_segment,
        taxi_company_borough,
        taxi_pick_up_location

        -- dropped: _dlt_id, _dlt_load_id (dlt internals)
        -- dropped: location__type (redundant nested object artifact)

    from source

)

select * from renamed
