import requests
import logging
import os

logger = logging.getLogger(__name__)

class GoogleMapsScraper:
    def __init__(self):
        # Get API key from environment variable
        self.api_key = os.getenv('GOOGLE_PLACES_API_KEY', '')
        self.base_url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
    
    def search(self, business_name):
        """Search business using Google Places API"""
        try:
            if not self.api_key:
                logger.warning("⚠️ No Google Places API key found. Using fallback data.")
                return self._get_fallback_data(business_name)
            
            # Search for the business
            params = {
                'query': business_name,
                'key': self.api_key
            }
            
            response = requests.get(self.base_url, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            if data.get('status') != 'OK' or not data.get('results'):
                logger.info(f"No results found for: {business_name}")
                return self._get_fallback_data(business_name)
            
            # Get first result
            place = data['results'][0]
            
            # Get place details for phone number
            place_id = place.get('place_id')
            details = self._get_place_details(place_id)
            
            return {
                'name': place.get('name', business_name),
                'phone': details.get('phone', ''),
                'address': place.get('formatted_address', ''),
                'website': details.get('website', ''),
                'owner': ''
            }
            
        except Exception as e:
            logger.error(f"Error scraping Google Maps: {e}")
            return self._get_fallback_data(business_name)
    
    def _get_place_details(self, place_id):
        """Get additional details for a place"""
        try:
            details_url = 'https://maps.googleapis.com/maps/api/place/details/json'
            params = {
                'place_id': place_id,
                'fields': 'phone,website,formatted_phone_number',
                'key': self.api_key
            }
            
            response = requests.get(details_url, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            if data.get('status') != 'OK':
                return {}
            
            result = data.get('result', {})
            return {
                'phone': result.get('formatted_phone_number', ''),
                'website': result.get('website', '')
            }
            
        except Exception as e:
            logger.error(f"Error getting place details: {e}")
            return {}
    
    def _get_fallback_data(self, business_name):
        """Return fallback data when API fails"""
        return {
            'name': business_name,
            'phone': '',
            'address': '',
            'website': '',
            'owner': ''
        }