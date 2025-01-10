class Boiler {
  final int id;
  final String name;
  final String district;
  final String address;
  final String status;

  Boiler({
    required this.id,
    required this.name,
    required this.district,
    required this.address,
    required this.status,
  });

  factory Boiler.fromJson(Map<String, dynamic> json) {
    return Boiler(
      id: json['id'],
      name: json['name'],
      district: json['district'],
      address: json['address'],
      status: json['status'],
    );
  }
}
