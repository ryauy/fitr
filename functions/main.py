# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
import os
import requests
from datetime import datetime
import json

# Initialize Firebase app
initialize_app()

@https_fn.on_call()
def get_weather_data(req: https_fn.CallableRequest) -> dict:
    """Fetch weather data from OpenWeatherMap API"""
    try:
        # Get API key from Firebase config
        api_key = os.environ.get("812daaa291559e5d4ab30fc761ee7f75")
        
        # Validate input parameters
        city = req.data.get("city")
        lat = req.data.get("lat")
        lon = req.data.get("lon")
        
        if not api_key:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="OpenWeather API key not configured"
            )
        
        if not (city or (lat and lon)):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Must provide either city name or coordinates"
            )
        
        # Build API URL
        base_url = "https://api.openweathermap.org/data/2.5/weather"
        params = {
            "appid": api_key,
            "units": "imperial"  # Get Fahrenheit temperatures
        }
        
        if city:
            params["q"] = city
        else:
            params["lat"] = lat
            params["lon"] = lon
        
        # Make API request
        response = requests.get(base_url, params=params)
        response.raise_for_status()
        data = response.json()
        
        # Transform to match Swift WeatherData structure
        return {
            "coord": {
                "lon": data.get("coord", {}).get("lon"),
                "lat": data.get("coord", {}).get("lat")
            },
            "weather": [{
                "id": data["weather"][0]["id"],
                "main": data["weather"][0]["main"],
                "description": data["weather"][0]["description"],
                "icon": data["weather"][0]["icon"]
            }],
            "main": {
                "temp": data["main"]["temp"],
                "feels_like": data["main"]["feels_like"],
                "temp_min": data["main"]["temp_min"],
                "temp_max": data["main"]["temp_max"],
                "pressure": data["main"]["pressure"],
                "humidity": data["main"]["humidity"]
            },
            "wind": {
                "speed": data["wind"]["speed"],
                "deg": data["wind"].get("deg", 0)
            },
            "name": data["name"],
            "timestamp": datetime.now().isoformat()  # Add current timestamp
        }
        
    except requests.exceptions.RequestException as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAVAILABLE,
            message="Failed to fetch weather data",
            details=str(e)
        )
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="An unexpected error occurred",
            details=str(e)
        )

@https_fn.on_call()
def get_outfit_recommendation(req: https_fn.CallableRequest) -> dict:
    """Generate outfit recommendation based on weather"""
    try:
        # Parse request data
        user_id = req.data.get("user_id")
        weather_data = req.data.get("weather")
        clothing_items = req.data.get("clothing_items")
        
        if not all([user_id, weather_data, clothing_items]):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Missing required parameters"
            )
        
        # Simple recommendation logic
        temp_f = weather_data["main"]["temp"]
        condition = weather_data["weather"][0]["main"].lower()
        
        # Determine clothing types based on weather
        recommended_types = []
        
        if temp_f < 50:  # Cold
            recommended_types.extend(["coat", "jacket", "sweater", "pants"])
        elif temp_f < 65:  # Cool
            recommended_types.extend(["sweater", "long_sleeve", "pants"])
        else:  # Warm/Hot
            recommended_types.extend(["t_shirt", "shorts", "dress"])
        
        if "rain" in condition:
            recommended_types.append("rain_jacket")
        if "snow" in condition:
            recommended_types.append("winter_boots")
        
        # Filter available items
        recommended_items = [
            item for item in clothing_items
            if item["type"] in recommended_types
        ][:4]  # Limit to 4 items
        
        # Create outfit description
        conditions = {
            "hot": "hot",
            "warm": "warm",
            "cool": "cool",
            "cold": "cold",
            "rain": "rainy",
            "snow": "snowy"
        }
        
        description = (
            f"For {conditions.get(condition, 'current')} weather ({int(temp_f)}°F), "
            f"I recommend wearing {len(recommended_items)} items from your wardrobe."
        )
        
        return {
            "outfit_id": str(hash(f"{user_id}{datetime.now().isoformat()}")),
            "user_id": user_id,
            "items": recommended_items,
            "weather": weather_data,
            "created_at": datetime.now().isoformat(),
            "description": description
        }
        
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="Failed to generate outfit recommendation",
            details=str(e)
        )
