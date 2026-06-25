import re
import phonenumbers

def validate_phone(phone):
    """Validate and format phone number"""
    try:
        # Remove spaces, brackets, dashes
        phone = re.sub(r'[\s\-\(\)]', '', phone)
        
        # Check if it's an Indian number
        if phone.startswith('+91'):
            try:
                parsed = phonenumbers.parse(phone, 'IN')
                if phonenumbers.is_valid_number(parsed):
                    return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)
            except:
                pass
        
        # Check if it's a valid number
        try:
            parsed = phonenumbers.parse(phone, None)
            if phonenumbers.is_valid_number(parsed):
                return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)
        except:
            pass
        
        return phone
        
    except Exception as e:
        print(f"Phone validation error: {e}")
        return phone

def validate_email(email):
    """Validate email address"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if re.match(pattern, email):
        return email
    return ''