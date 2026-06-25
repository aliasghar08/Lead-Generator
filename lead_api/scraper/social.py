import logging

logger = logging.getLogger(__name__)

class SocialScraper:
    def search(self, business_name):
        try:
            clean_name = business_name.lower().replace(' ', '').replace('-', '')
            return {
                'instagram': f'@{clean_name}',
                'facebook': f'facebook.com/{clean_name}',
                'linkedin': '',
                'twitter': ''
            }
        except Exception as e:
            logger.error(f"Social search error: {e}")
            return {}