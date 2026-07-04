class UserModel {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String avatar;
  final String gender;
  UserModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.avatar,
    required this.gender,
  });
  Map<String,dynamic> toJson(){
    return{
      "fullName": fullName,
      "email": email,
      "phone": phone,
      "password": password,
      "avatar": avatar,
      "gender": gender,
    };
  }
  factory UserModel.fromJson(Map<String,dynamic> json){
    return UserModel(fullName: json["fullName"], email: json["email"], phone: json["phone"], password: json["password"], avatar:json["avatar"], gender: json["gender"]);
  }
  @override
  String toString(){
    return '''
  UserModel(
  fullName: $fullName,
  email: $email,
  phone: $phone,
  password: $password,
  avatar: $avatar,
  gender: $gender,
  )
''';
  }
}