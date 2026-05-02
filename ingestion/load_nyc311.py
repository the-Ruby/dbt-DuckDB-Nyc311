# ingestion/load_nyc311.py

import dlt
import requests
from datetime import datetime, timedelta

# ── Constants ────────────────────────────────────────────────
NYC311_URL  = "https://data.cityofnewyork.us/resource/erm2-nwe9.json"
WEATHER_URL = "https://archive-api.open-meteo.com/v1/archive"
PAGE_SIZE   = 50_000
NYC_LAT     = 40.7128
NYC_LON     = -74.0060
START_DATE  = (datetime.now() - timedelta(days=90)).strftime("%Y-%m-%dT%H:%M:%S")


# ── Resource 1: NYC 311 Service Requests ─────────────────────
@dlt.resource(
    name="service_requests",
    primary_key="unique_key",
    write_disposition="merge",
)
def service_requests():
    """
    Paginate through NYC 311 service requests.
    Loads last 1 year of data. dlt deduplicates via primary_key.
    We handle the date filter ourselves — no dlt incremental needed.
    """
    offset = 0
    total  = 0

    print(f"Fetching service requests from {START_DATE}")

    while True:
        soql = (
            f"SELECT * "
            f"WHERE created_date >= '{START_DATE}' "
            f"ORDER BY created_date ASC "
            f"LIMIT {PAGE_SIZE} "
            f"OFFSET {offset}"
        )

        response = requests.get(
            NYC311_URL,
            params={"$query": soql},
            timeout=60,
        )

        print(f"  Page offset={offset} → status {response.status_code}")

        if not response.ok:
            print(f"  API error: {response.text[:500]}")
            response.raise_for_status()

        page = response.json()

        if not page:
            break

        total += len(page)
        print(f"  Got {len(page)} rows (total: {total})")
        yield page

        if len(page) < PAGE_SIZE:
            break

        offset += PAGE_SIZE


# ── Resource 2: Open-Meteo Historical Weather ─────────────────
@dlt.resource(
    name="weather_daily",
    primary_key="date",
    write_disposition="merge",
)
def weather_daily():
    end_date   = datetime.now().strftime("%Y-%m-%d")
    start_date = (datetime.now() - timedelta(days=90)).strftime("%Y-%m-%d")

    print(f"Fetching weather {start_date} → {end_date}")

    params = {
        "latitude":   NYC_LAT,
        "longitude":  NYC_LON,
        "start_date": start_date,
        "end_date":   end_date,
        "daily": [
            "temperature_2m_max",
            "temperature_2m_min",
            "precipitation_sum",
            "wind_speed_10m_max",
            "weathercode",
        ],
        "timezone": "America/New_York",
    }

    response = requests.get(WEATHER_URL, params=params, timeout=60)
    print(f"  Status: {response.status_code}")

    if not response.ok:
        print(f"  Error: {response.text[:500]}")
        response.raise_for_status()

    data  = response.json()
    daily = data["daily"]

    rows = [
        {key: daily[key][i] for key in daily}
        for i in range(len(daily["time"]))
    ]

    for row in rows:
        row["date"] = row.pop("time")

    print(f"  Got {len(rows)} weather rows")
    yield rows


# ── Pipeline ──────────────────────────────────────────────────
pipeline = dlt.pipeline(
    pipeline_name="nyc311_pipeline",
    destination=dlt.destinations.duckdb(
        "/Users/ruby/Projects/_DBT_/Nyc311/nyc311.duckdb"
    ),
    dataset_name="raw",
)


# ── Entry point ───────────────────────────────────────────────
if __name__ == "__main__":
    print("Starting NYC 311 ingestion...")

    load_info = pipeline.run(
        [service_requests(), weather_daily()]
    )

    print(load_info)
    print("\nDone.")