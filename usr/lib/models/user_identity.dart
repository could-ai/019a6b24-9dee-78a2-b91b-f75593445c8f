class UserIdentity {
  final String id;
  final String username;
  final String publicKeyPem;
  final String privateKeyPem;
  
  UserIdentity({
    required this.id,
    required this.username,
    required this.publicKeyPem,
    required this.privateKeyPem,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'publicKeyPem': publicKeyPem,
    'privateKeyPem': privateKeyPem,
  };
  
  factory UserIdentity.fromJson(Map<String, dynamic> json) => UserIdentity(
    id: json['id'],
    username: json['username'],
    publicKeyPem: json['publicKeyPem'],
    privateKeyPem: json['privateKeyPem'],
  );
}
