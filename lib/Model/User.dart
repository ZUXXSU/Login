class User {
	String? user;
	String? message;
	String? timestamp;

	User({this.user, this.message, this.timestamp});

	User.fromJson(Map<String, dynamic> json) {
		user = json['user'];
		message = json['message'];
		timestamp = json['timestamp'];
	}

	Map<String, dynamic> toJson() {
		final Map<String, dynamic> data = new Map<String, dynamic>();
		data['user'] = this.user;
		data['message'] = this.message;
		data['timestamp'] = this.timestamp;
		return data;
	}
}

