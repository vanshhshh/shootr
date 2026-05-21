enum AppCountry { india, uae, usa }

extension AppCountryX on AppCountry {
  String get label => switch (this) {
        AppCountry.india => 'India',
        AppCountry.uae => 'UAE',
        AppCountry.usa => 'USA',
      };

  String get symbol => switch (this) {
        AppCountry.india => '₹',
        AppCountry.uae => 'AED ',
        AppCountry.usa => '\$',
      };

  String get taxLabel => switch (this) {
        AppCountry.india => 'GST',
        AppCountry.uae => 'VAT',
        AppCountry.usa => 'Tax',
      };
}

enum DeviceType { iphone, samsung, pixel, oneplus, nothing, other }

extension DeviceTypeX on DeviceType {
  String get label => switch (this) {
        DeviceType.iphone => 'iPhone',
        DeviceType.samsung => 'Samsung',
        DeviceType.pixel => 'Pixel',
        DeviceType.oneplus => 'OnePlus',
        DeviceType.nothing => 'Nothing',
        DeviceType.other => 'Other',
      };
}

enum DeviceTier { premium, professional, standard, waitlist }

extension DeviceTierX on DeviceTier {
  String get label => switch (this) {
        DeviceTier.premium => 'Premium',
        DeviceTier.professional => 'Professional',
        DeviceTier.standard => 'Standard',
        DeviceTier.waitlist => 'Waitlist',
      };

  String get badge => switch (this) {
        DeviceTier.premium => 'Premium',
        DeviceTier.professional => 'Professional',
        DeviceTier.standard => 'Standard',
        DeviceTier.waitlist => 'Waitlist',
      };

  double get defaultRate => switch (this) {
        DeviceTier.premium => 2499,
        DeviceTier.professional => 1999,
        DeviceTier.standard => 1799,
        DeviceTier.waitlist => 0,
      };

  double get minRate => switch (this) {
        DeviceTier.premium => 1999,
        DeviceTier.professional => 1499,
        DeviceTier.standard => 1299,
        DeviceTier.waitlist => 0,
      };

  double get maxRate => switch (this) {
        DeviceTier.premium => 5000,
        DeviceTier.professional => 3500,
        DeviceTier.standard => 2500,
        DeviceTier.waitlist => 0,
      };
}

enum UserGender { male, female, preferNotToSay }

extension UserGenderX on UserGender {
  String get label => switch (this) {
        UserGender.male => 'Male',
        UserGender.female => 'Female',
        UserGender.preferNotToSay => 'Prefer not to say',
      };
}

enum PreferredGender { any, female, male }

extension PreferredGenderX on PreferredGender {
  String get label => switch (this) {
        PreferredGender.any => 'Any',
        PreferredGender.female => 'Female',
        PreferredGender.male => 'Male',
      };
}

enum ShootrSortOption {
  nearest,
  topRated,
  priceLowToHigh,
  priceHighToLow,
  mostBooked,
}

extension ShootrSortOptionX on ShootrSortOption {
  String get label => switch (this) {
        ShootrSortOption.nearest => 'Nearest',
        ShootrSortOption.topRated => 'Top Rated',
        ShootrSortOption.priceLowToHigh => 'Price: Low to High',
        ShootrSortOption.priceHighToLow => 'Price: High to Low',
        ShootrSortOption.mostBooked => 'Most Booked',
      };
}

enum VerificationStatus { pending, verified, rejected, suspended }

extension VerificationStatusX on VerificationStatus {
  String get label => switch (this) {
        VerificationStatus.pending => 'Pending',
        VerificationStatus.verified => 'Verified',
        VerificationStatus.rejected => 'Rejected',
        VerificationStatus.suspended => 'Suspended',
      };
}

enum ShootrLevel { rookie, pro, elite, master }

extension ShootrLevelX on ShootrLevel {
  String get label => switch (this) {
        ShootrLevel.rookie => 'Rookie',
        ShootrLevel.pro => 'Pro',
        ShootrLevel.elite => 'Elite',
        ShootrLevel.master => 'Master',
      };
}

class MarketplaceCategory {
  const MarketplaceCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.iconKey,
  });

  final String id;
  final String label;
  final String emoji;
  final String iconKey;
}

const List<MarketplaceCategory> kMarketplaceCategories = <MarketplaceCategory>[
  MarketplaceCategory(id: 'restaurant', label: 'Restaurant & Cafe', emoji: '🍽️', iconKey: 'forkKnife'),
  MarketplaceCategory(id: 'wedding', label: 'Wedding', emoji: '💍', iconKey: 'rings'),
  MarketplaceCategory(id: 'birthday', label: 'Birthday Party', emoji: '🎂', iconKey: 'cake'),
  MarketplaceCategory(id: 'brand_launch', label: 'Brand Launch', emoji: '🚀', iconKey: 'rocket'),
  MarketplaceCategory(id: 'corporate', label: 'Corporate Event', emoji: '🏢', iconKey: 'buildings'),
  MarketplaceCategory(id: 'college_fest', label: 'College Fest', emoji: '🎓', iconKey: 'graduationCap'),
  MarketplaceCategory(id: 'product', label: 'Product Shoot', emoji: '📦', iconKey: 'package'),
  MarketplaceCategory(id: 'fashion', label: 'Fashion & Beauty', emoji: '💄', iconKey: 'sparkle'),
  MarketplaceCategory(id: 'fitness', label: 'Gym & Fitness', emoji: '🏋️', iconKey: 'barbell'),
  MarketplaceCategory(id: 'music', label: 'Music & Performance', emoji: '🎵', iconKey: 'musicNotes'),
  MarketplaceCategory(id: 'real_estate', label: 'Real Estate', emoji: '🏠', iconKey: 'houseLine'),
  MarketplaceCategory(id: 'pet_family', label: 'Pet & Family', emoji: '🐾', iconKey: 'pawPrint'),
  MarketplaceCategory(id: 'gaming', label: 'Gaming & Tech', emoji: '🎮', iconKey: 'gameController'),
  MarketplaceCategory(id: 'food_blog', label: 'Food Blog', emoji: '🌿', iconKey: 'bowlFood'),
  MarketplaceCategory(id: 'maternity', label: 'Baby & Maternity', emoji: '👶', iconKey: 'baby'),
  MarketplaceCategory(id: 'personal', label: 'Just for Fun / Personal', emoji: '📸', iconKey: 'camera'),
  MarketplaceCategory(id: 'other', label: 'Other', emoji: '➕', iconKey: 'plusCircle'),
];

class IndiaRegion {
  const IndiaRegion(this.name, this.cities, {this.isUnionTerritory = false});

  final String name;
  final List<String> cities;
  final bool isUnionTerritory;
}

const List<IndiaRegion> kIndiaRegions = <IndiaRegion>[
  IndiaRegion('Andhra Pradesh', <String>['Visakhapatnam', 'Vijayawada', 'Tirupati']),
  IndiaRegion('Arunachal Pradesh', <String>['Itanagar', 'Tawang']),
  IndiaRegion('Assam', <String>['Guwahati', 'Silchar']),
  IndiaRegion('Bihar', <String>['Patna', 'Gaya', 'Muzaffarpur']),
  IndiaRegion('Chhattisgarh', <String>['Raipur', 'Bilaspur']),
  IndiaRegion('Goa', <String>['Panaji', 'Margao']),
  IndiaRegion('Gujarat', <String>['Ahmedabad', 'Surat', 'Vadodara']),
  IndiaRegion('Haryana', <String>['Gurugram', 'Faridabad', 'Panipat']),
  IndiaRegion('Himachal Pradesh', <String>['Shimla', 'Dharamshala']),
  IndiaRegion('Jharkhand', <String>['Ranchi', 'Jamshedpur']),
  IndiaRegion('Karnataka', <String>['Bengaluru', 'Mysuru', 'Mangaluru']),
  IndiaRegion('Kerala', <String>['Kochi', 'Thiruvananthapuram', 'Kozhikode']),
  IndiaRegion('Madhya Pradesh', <String>['Indore', 'Bhopal', 'Gwalior']),
  IndiaRegion('Maharashtra', <String>['Mumbai', 'Pune', 'Nagpur', 'Nashik']),
  IndiaRegion('Manipur', <String>['Imphal']),
  IndiaRegion('Meghalaya', <String>['Shillong', 'Tura']),
  IndiaRegion('Mizoram', <String>['Aizawl']),
  IndiaRegion('Nagaland', <String>['Kohima', 'Dimapur']),
  IndiaRegion('Odisha', <String>['Bhubaneswar', 'Cuttack', 'Puri']),
  IndiaRegion('Punjab', <String>['Ludhiana', 'Amritsar', 'Mohali']),
  IndiaRegion('Rajasthan', <String>['Jaipur', 'Udaipur', 'Jodhpur']),
  IndiaRegion('Sikkim', <String>['Gangtok']),
  IndiaRegion('Tamil Nadu', <String>['Chennai', 'Coimbatore', 'Madurai']),
  IndiaRegion('Telangana', <String>['Hyderabad', 'Warangal']),
  IndiaRegion('Tripura', <String>['Agartala']),
  IndiaRegion('Uttar Pradesh', <String>['Lucknow', 'Noida', 'Kanpur', 'Varanasi']),
  IndiaRegion('Uttarakhand', <String>['Dehradun', 'Haridwar', 'Rishikesh']),
  IndiaRegion('West Bengal', <String>['Kolkata', 'Siliguri', 'Durgapur']),
  IndiaRegion('Andaman and Nicobar Islands', <String>['Port Blair'], isUnionTerritory: true),
  IndiaRegion('Chandigarh', <String>['Chandigarh'], isUnionTerritory: true),
  IndiaRegion('Dadra and Nagar Haveli and Daman and Diu', <String>['Daman', 'Diu', 'Silvassa'], isUnionTerritory: true),
  IndiaRegion('Delhi', <String>['New Delhi', 'Dwarka', 'Rohini'], isUnionTerritory: true),
  IndiaRegion('Jammu and Kashmir', <String>['Srinagar', 'Jammu'], isUnionTerritory: true),
  IndiaRegion('Ladakh', <String>['Leh', 'Kargil'], isUnionTerritory: true),
  IndiaRegion('Lakshadweep', <String>['Kavaratti'], isUnionTerritory: true),
  IndiaRegion('Puducherry', <String>['Puducherry', 'Karaikal'], isUnionTerritory: true),
];

class ApprovedDevice {
  const ApprovedDevice(this.model, this.type, this.tier, this.cameraSpec);

  final String model;
  final DeviceType type;
  final DeviceTier tier;
  final String cameraSpec;
}

const List<ApprovedDevice> kApprovedDevices = <ApprovedDevice>[
  ApprovedDevice('iPhone 13 Pro', DeviceType.iphone, DeviceTier.premium, 'Triple camera'),
  ApprovedDevice('iPhone 13 Pro Max', DeviceType.iphone, DeviceTier.premium, 'Triple camera'),
  ApprovedDevice('iPhone 14', DeviceType.iphone, DeviceTier.premium, 'Dual camera'),
  ApprovedDevice('iPhone 14 Plus', DeviceType.iphone, DeviceTier.premium, 'Dual camera'),
  ApprovedDevice('iPhone 14 Pro', DeviceType.iphone, DeviceTier.premium, '48MP main camera'),
  ApprovedDevice('iPhone 14 Pro Max', DeviceType.iphone, DeviceTier.premium, '48MP main camera'),
  ApprovedDevice('iPhone 15', DeviceType.iphone, DeviceTier.premium, '48MP main camera'),
  ApprovedDevice('iPhone 15 Plus', DeviceType.iphone, DeviceTier.premium, '48MP main camera'),
  ApprovedDevice('iPhone 15 Pro', DeviceType.iphone, DeviceTier.premium, 'ProRes camera'),
  ApprovedDevice('iPhone 15 Pro Max', DeviceType.iphone, DeviceTier.premium, 'ProRes camera'),
  ApprovedDevice('iPhone 16', DeviceType.iphone, DeviceTier.premium, 'Flagship camera'),
  ApprovedDevice('iPhone 16 Plus', DeviceType.iphone, DeviceTier.premium, 'Flagship camera'),
  ApprovedDevice('iPhone 16 Pro', DeviceType.iphone, DeviceTier.premium, 'Pro camera system'),
  ApprovedDevice('iPhone 16 Pro Max', DeviceType.iphone, DeviceTier.premium, 'Pro camera system'),
  ApprovedDevice('iPhone 17', DeviceType.iphone, DeviceTier.premium, 'Flagship camera'),
  ApprovedDevice('iPhone 17 Plus', DeviceType.iphone, DeviceTier.premium, 'Flagship camera'),
  ApprovedDevice('iPhone 17 Pro', DeviceType.iphone, DeviceTier.premium, 'Pro camera system'),
  ApprovedDevice('iPhone 17 Pro Max', DeviceType.iphone, DeviceTier.premium, 'Pro camera system'),
  ApprovedDevice('Samsung Galaxy S22', DeviceType.samsung, DeviceTier.professional, '50MP triple camera'),
  ApprovedDevice('Samsung Galaxy S22+', DeviceType.samsung, DeviceTier.professional, '50MP triple camera'),
  ApprovedDevice('Samsung Galaxy S22 Ultra', DeviceType.samsung, DeviceTier.professional, '108MP quad camera'),
  ApprovedDevice('Samsung Galaxy S23', DeviceType.samsung, DeviceTier.professional, '50MP triple camera'),
  ApprovedDevice('Samsung Galaxy S23+', DeviceType.samsung, DeviceTier.professional, '50MP triple camera'),
  ApprovedDevice('Samsung Galaxy S23 Ultra', DeviceType.samsung, DeviceTier.professional, '200MP quad camera'),
  ApprovedDevice('Samsung Galaxy S24', DeviceType.samsung, DeviceTier.professional, '50MP triple camera'),
  ApprovedDevice('Samsung Galaxy S24+', DeviceType.samsung, DeviceTier.professional, '50MP triple camera'),
  ApprovedDevice('Samsung Galaxy S24 Ultra', DeviceType.samsung, DeviceTier.professional, '200MP quad camera'),
  ApprovedDevice('Samsung Galaxy S25', DeviceType.samsung, DeviceTier.professional, '50MP triple camera'),
  ApprovedDevice('Samsung Galaxy S25+', DeviceType.samsung, DeviceTier.professional, '50MP triple camera'),
  ApprovedDevice('Samsung Galaxy S25 Ultra', DeviceType.samsung, DeviceTier.professional, '200MP quad camera'),
  ApprovedDevice('Google Pixel 7', DeviceType.pixel, DeviceTier.standard, '50MP dual camera'),
  ApprovedDevice('Google Pixel 7 Pro', DeviceType.pixel, DeviceTier.standard, '50MP triple camera'),
  ApprovedDevice('Google Pixel 7a', DeviceType.pixel, DeviceTier.standard, '64MP dual camera'),
  ApprovedDevice('Google Pixel 8', DeviceType.pixel, DeviceTier.standard, '50MP dual camera'),
  ApprovedDevice('Google Pixel 8 Pro', DeviceType.pixel, DeviceTier.standard, '50MP triple camera'),
  ApprovedDevice('Google Pixel 8a', DeviceType.pixel, DeviceTier.standard, '64MP dual camera'),
  ApprovedDevice('Google Pixel 9', DeviceType.pixel, DeviceTier.standard, '50MP dual camera'),
  ApprovedDevice('Google Pixel 9 Pro', DeviceType.pixel, DeviceTier.standard, '50MP triple camera'),
  ApprovedDevice('Google Pixel 9a', DeviceType.pixel, DeviceTier.standard, '64MP dual camera'),
  ApprovedDevice('OnePlus 11', DeviceType.oneplus, DeviceTier.standard, '50MP Hasselblad camera'),
  ApprovedDevice('OnePlus 11R', DeviceType.oneplus, DeviceTier.standard, '50MP Sony camera'),
  ApprovedDevice('OnePlus 12', DeviceType.oneplus, DeviceTier.standard, '50MP Hasselblad camera'),
  ApprovedDevice('OnePlus 12R', DeviceType.oneplus, DeviceTier.standard, '50MP Sony camera'),
  ApprovedDevice('OnePlus 13', DeviceType.oneplus, DeviceTier.standard, '50MP flagship camera'),
  ApprovedDevice('OnePlus 13R', DeviceType.oneplus, DeviceTier.standard, '50MP flagship camera'),
  ApprovedDevice('Nothing Phone 2', DeviceType.nothing, DeviceTier.standard, '50MP dual camera'),
  ApprovedDevice('Nothing Phone 2a', DeviceType.nothing, DeviceTier.standard, '50MP dual camera'),
  ApprovedDevice('Nothing Phone 3', DeviceType.nothing, DeviceTier.standard, 'Flagship dual camera'),
];

ApprovedDevice? findApprovedDevice(String model) {
  final query = model.trim().toLowerCase();
  for (final device in kApprovedDevices) {
    if (device.model.toLowerCase() == query) {
      return device;
    }
  }
  return null;
}

ShootrLevel levelFromShoots(int shoots) {
  if (shoots >= 201) {
    return ShootrLevel.master;
  }
  if (shoots >= 51) {
    return ShootrLevel.elite;
  }
  if (shoots >= 11) {
    return ShootrLevel.pro;
  }
  return ShootrLevel.rookie;
}
