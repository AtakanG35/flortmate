class UserProfile {
  final String name;
  final String city;
  final int age;

  UserProfile({
    required this.name,
    required this.city,
    required this.age,
  });

  // Null güvenli veri alma için factory constructor
  factory UserProfile.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      // Boş veri gelirse varsayılan boş nesne döndür
      return UserProfile(name: '', city: '', age: 0);
    }

    return UserProfile(
      name: data['name'] is String ? data['name'] : '',
      city: data['city'] is String ? data['city'] : '',
      age: data['age'] is int
          ? data['age']
          : int.tryParse(data['age']?.toString() ?? '') ?? 0,
    );
  }

  // Modeli Firestore'a yazmak için harita haline getirir
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'age': age,
    };
  }

  // Kopyalama metodu: var olan nesneden belli alanları değiştirmek için kullanılır
  UserProfile copyWith({String? name, String? city, int? age}) {
    return UserProfile(
      name: name ?? this.name,
      city: city ?? this.city,
      age: age ?? this.age,
    );
  }

  // Eşitlik kontrolü ve hashcode, bu sınıfı collection'larda ve testlerde daha rahat kullanmak için
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserProfile &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              city == other.city &&
              age == other.age;

  @override
  int get hashCode => name.hashCode ^ city.hashCode ^ age.hashCode;

  // Debug için güzel görünümlü string
  @override
  String toString() => 'UserProfile(name: $name, city: $city, age: $age)';
}
