class Lead {
  final String? id;
  final String businessName;
  final String ownerName;
  final String phone;
  final String email;
  final String socialMedia;
  final String address;
  final String website;
  final String? rating;
  final String? reviews;

  Lead({
    this.id,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.socialMedia,
    required this.address,
    required this.website,
    this.rating,
    this.reviews,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      businessName: json['businessName'] ?? '',
      ownerName: json['ownerName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      socialMedia: json['socialMedia'] ?? '',
      address: json['address'] ?? '',
      website: json['website'] ?? '',
      rating: json['rating']?.toString(),
      reviews: json['reviews']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'socialMedia': socialMedia,
      'address': address,
      'website': website,
      'rating': rating,
      'reviews': reviews,
    };
  }
}