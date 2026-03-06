class Appointment {
  final String   id;
  final String   clientName;
  final String   procedure;
  final DateTime date;       // Sempre armazenado como meia-noite UTC
  final String   time;
  final String   location;
  final double   price;
  final String   paymentMethod;
  final bool     paid;
  final DateTime? paidAt;
  final bool     confirmed;
  final DateTime? confirmedAt;
  final String   notes;
  final DateTime createdAt;

  const Appointment({
    required this.id,
    required this.clientName,
    required this.procedure,
    required this.date,
    required this.time,
    required this.location,
    required this.price,
    required this.paymentMethod,
    required this.paid,
    this.paidAt,
    required this.confirmed,
    this.confirmedAt,
    required this.notes,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Normaliza a data: extrai apenas ano/mês/dia, ignora horário
    final rawDate = DateTime.parse(json['date']);
    final date    = DateTime.utc(rawDate.year, rawDate.month, rawDate.day);

    return Appointment(
      id:            json['_id']?.toString() ?? json['id']?.toString() ?? '',
      clientName:    json['clientName'] ?? '',
      procedure:     json['procedure'] ?? '',
      date:          date,
      time:          json['time'] ?? '',
      location:      json['location'] ?? '',
      price:         (json['price'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      paid:          json['paid'] ?? false,
      paidAt:        json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      confirmed:     json['confirmed'] ?? false,
      confirmedAt:   json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      notes:         json['notes'] ?? '',
      createdAt:     json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    // Envia data como YYYY-MM-DD para evitar problemas de timezone
    'date':          '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
    'clientName':    clientName,
    'procedure':     procedure,
    'time':          time,
    'location':      location,
    'price':         price,
    'paymentMethod': paymentMethod,
    'paid':          paid,
    'confirmed':     confirmed,
    'notes':         notes,
  };

  Appointment copyWith({
    String?   id,          String?   clientName, String?   procedure,
    DateTime? date,        String?   time,        String?   location,
    double?   price,       String?   paymentMethod,
    bool?     paid,        DateTime? paidAt,
    bool?     confirmed,   DateTime? confirmedAt,
    String?   notes,       DateTime? createdAt,
  }) => Appointment(
    id:            id            ?? this.id,
    clientName:    clientName    ?? this.clientName,
    procedure:     procedure     ?? this.procedure,
    date:          date          ?? this.date,
    time:          time          ?? this.time,
    location:      location      ?? this.location,
    price:         price         ?? this.price,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paid:          paid          ?? this.paid,
    paidAt:        paidAt        ?? this.paidAt,
    confirmed:     confirmed     ?? this.confirmed,
    confirmedAt:   confirmedAt   ?? this.confirmedAt,
    notes:         notes         ?? this.notes,
    createdAt:     createdAt     ?? this.createdAt,
  );
}