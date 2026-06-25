class Lead:
    def __init__(self, businessName, ownerName='', phone='', email='', 
                 socialMedia='', address='', website=''):
        self.businessName = businessName
        self.ownerName = ownerName
        self.phone = phone
        self.email = email
        self.socialMedia = socialMedia
        self.address = address
        self.website = website
    
    def to_dict(self):
        return {
            'businessName': self.businessName,
            'ownerName': self.ownerName,
            'phone': self.phone,
            'email': self.email,
            'socialMedia': self.socialMedia,
            'address': self.address,
            'website': self.website
        }