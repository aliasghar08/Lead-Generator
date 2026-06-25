from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import os
import logging
from scraper.serpapi import SerpAPIScraper
from scraper.website import WebsiteScraper
from scraper.social import SocialScraper
from models.lead import Lead
from utils.validators import validate_phone, validate_email

load_dotenv()

app = Flask(__name__)
CORS(app)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize scrapers
serpapi_scraper = SerpAPIScraper()
website_scraper = WebsiteScraper()
social_scraper = SocialScraper()

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'message': 'Lead Generator API is running'
    })

@app.route('/scrape', methods=['POST'])
def scrape_business():
    try:
        data = request.get_json()
        
        if not data or 'business_name' not in data:
            return jsonify({'error': 'Missing business_name field'}), 400
        
        business_name = data['business_name']
        website = data.get('website')
        limit = data.get('limit', 10)
        
        logger.info(f"🔍 Searching for: {business_name}")
        
        # Search using SerpAPI
        results = serpapi_scraper.search(business_name, limit)
        
        leads = []
        
        if results:
            logger.info(f"✅ Found {len(results)} real results from SerpAPI")
            for result in results:
                lead_data = {
                    'businessName': result.get('name', business_name),
                    'ownerName': result.get('owner', ''),
                    'phone': result.get('phone', ''),
                    'email': '',
                    'socialMedia': result.get('social', ''),
                    'address': result.get('address', ''),
                    'website': result.get('website', website or ''),
                    'rating': result.get('rating', ''),
                    'reviews': result.get('reviews', '')
                }
                
                # If no phone, try to find from website or generate
                if not lead_data['phone'] and lead_data['website']:
                    try:
                        website_data = website_scraper.scrape(lead_data['website'])
                        if website_data and website_data.get('phone'):
                            lead_data['phone'] = website_data['phone']
                    except:
                        pass
                
                # If still no phone, leave empty (don't generate fake)
                if not lead_data['phone']:
                    lead_data['phone'] = ''
                
                # If no website, leave empty
                if not lead_data['website']:
                    lead_data['website'] = ''
                
                # Scrape website for emails
                if lead_data['website']:
                    try:
                        website_data = website_scraper.scrape(lead_data['website'])
                        if website_data:
                            if website_data.get('email'):
                                lead_data['email'] = website_data.get('email')
                            if website_data.get('owner_name'):
                                lead_data['ownerName'] = website_data['owner_name']
                    except Exception as e:
                        logger.error(f"Website scraping error: {e}")
                
                # Find social media handles
                try:
                    social_data = social_scraper.search(lead_data['businessName'])
                    if social_data and not lead_data['socialMedia']:
                        lead_data['socialMedia'] = social_data.get('instagram', '')
                except Exception as e:
                    logger.error(f"Social media search error: {e}")
                
                # Validate
                if lead_data['phone']:
                    lead_data['phone'] = validate_phone(lead_data['phone'])
                
                if lead_data['email']:
                    lead_data['email'] = validate_email(lead_data['email'])
                
                lead = Lead(
                    businessName=lead_data['businessName'],
                    ownerName=lead_data['ownerName'],
                    phone=lead_data['phone'],
                    email=lead_data['email'],
                    socialMedia=lead_data['socialMedia'],
                    address=lead_data['address'],
                    website=lead_data['website'],
                    rating=lead_data['rating'],
                    reviews=lead_data['reviews']
                )
                leads.append(lead.to_dict())
            
            return jsonify({
                'success': True,
                'leads': leads,
                'total': len(leads)
            })
        
        # ===== NO RESULTS FROM SERPAPI =====
        logger.info("No results from SerpAPI, returning empty response")
        
        # Return empty leads array instead of generating fake data
        return jsonify({
            'success': True,
            'leads': [],
            'total': 0,
            'message': 'No businesses found. Try a different search term.'
        })
        
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({
            'error': str(e),
            'success': False
        }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)