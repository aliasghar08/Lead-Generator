import requests
import logging
import os
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

class SerpAPIScraper:
    def __init__(self):
        self.api_key = os.getenv('SERPAPI_KEY', '')
        self.base_url = 'https://serpapi.com/search.json'
        self.cache = {}
    
    def search(self, business_name):
        """Search Google Maps using SerpAPI - REAL DATA"""
        try:
            # Check cache first
            if business_name in self.cache:
                logger.info(f"📦 Returning cached data for: {business_name}")
                return self.cache[business_name]
            
            if not self.api_key:
                logger.warning("⚠️ No SerpAPI key found!")
                return None
            
            logger.info(f"🔍 Searching SerpAPI for: {business_name}")
            
            params = {
                'api_key': self.api_key,
                'engine': 'google_maps',
                'q': business_name,
                'type': 'search',
                'hl': 'en',
                'gl': 'in'  # Focus on India
            }
            
            response = requests.get(self.base_url, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            # Check if we got results
            if not data.get('local_results'):
                logger.info(f"No results found for: {business_name}")
                return None
            
            # Get first result
            place = data['local_results'][0]
            
            result = {
                'name': place.get('title', business_name),
                'phone': place.get('phone', ''),
                'address': place.get('address', ''),
                'website': place.get('website', ''),
                'rating': place.get('rating', ''),
                'reviews': place.get('reviews', ''),
                'owner': '',
                'social': ''
            }
            
            # If no phone, try to get from place details
            if not result['phone'] and place.get('place_id'):
                details = self._get_place_details(place['place_id'])
                if details:
                    result['phone'] = details.get('phone', '')
                    result['website'] = details.get('website', result['website'])
            
            # Cache the result
            self.cache[business_name] = result
            logger.info(f"✅ Found real data: {result['name']}")
            logger.info(f"📞 Phone: {result['phone']}")
            logger.info(f"📍 Address: {result['address']}")
            
            return result
            
        except Exception as e:
            logger.error(f"Error with SerpAPI: {e}")
            return None
    
    def _get_place_details(self, place_id):
        """Get additional details for a place"""
        try:
            params = {
                'api_key': self.api_key,
                'engine': 'google_maps_place_details',
                'place_id': place_id,
                'hl': 'en'
            }
            
            response = requests.get(self.base_url, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            result = data.get('place_details', {})
            
            return {
                'phone': result.get('phone', ''),
                'website': result.get('website', '')
            }
            
        except Exception as e:
            logger.error(f"Error getting place details: {e}")
            return {}