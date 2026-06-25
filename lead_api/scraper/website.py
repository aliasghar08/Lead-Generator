import re
import requests
from bs4 import BeautifulSoup
from urllib.parse import urlparse, urljoin
import logging

logger = logging.getLogger(__name__)

class WebsiteScraper:
    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
    
    def scrape(self, url):
        """Scrape website for emails and owner info"""
        try:
            if not url:
                return None
            
            if not url.startswith('http'):
                url = 'https://' + url
            
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Extract emails
            emails = self._extract_emails(soup)
            
            # Extract owner name
            owner_name = self._extract_owner_name(soup)
            
            return {
                'email': emails[0] if emails else '',
                'owner_name': owner_name
            }
            
        except Exception as e:
            logger.error(f"Error scraping website {url}: {e}")
            return None
    
    def _extract_emails(self, soup):
        """Extract email addresses from website"""
        emails = set()
        
        # Check mailto: links
        for link in soup.find_all('a', href=True):
            href = link['href']
            if href.startswith('mailto:'):
                email = href.replace('mailto:', '').strip()
                if '@' in email:
                    emails.add(email)
        
        # Check text for email patterns
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        text = soup.get_text()
        found_emails = re.findall(email_pattern, text)
        emails.update(found_emails)
        
        # Filter out common spam emails
        filtered_emails = [
            e for e in emails 
            if not e.startswith('noreply') 
            and not e.startswith('no-reply')
            and not 'admin' in e.lower()
            and not 'support' in e.lower()
        ]
        
        return filtered_emails
    
    def _extract_owner_name(self, soup):
        """Extract owner/founder name from website"""
        # Common patterns for owner/founder
        patterns = [
            (r'(?:Owner|Founder|Director|CEO|Managing Director)\s*[:：]\s*([A-Za-z\s]+)', re.IGNORECASE),
            (r'(?:Dr\.|Dr\s)([A-Za-z\s]+)', re.IGNORECASE),
            (r'About\s+([A-Za-z\s]+)\s+(?:is|are)', re.IGNORECASE),
            (r'Founder\s+([A-Za-z\s]+)', re.IGNORECASE),
        ]
        
        text = soup.get_text()
        
        for pattern, flags in patterns:
            match = re.search(pattern, text, flags)
            if match:
                name = match.group(1).strip()
                if len(name) > 2 and len(name) < 50:
                    return name
        
        return ''