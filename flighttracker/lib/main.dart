import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const FlightTrackerApp());
}

class FlightTrackerApp extends StatelessWidget {
  const FlightTrackerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uçuş Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const FlightScreen(),
    );
  }
}

class Flight {
  final String icao;
  final String callsign;
  final String country;
  final double? lat;
  final double? lon;
  final double? altitude;
  final double? speed;
  final double? heading;

  Flight({required this.icao, required this.callsign, required this.country,
    this.lat, this.lon, this.altitude, this.speed, this.heading});

  factory Flight.fromList(List<dynamic> f) {
    return Flight(
      icao: f[0] ?? '',
      callsign: (f[1] ?? 'N/A').toString().trim(),
      country: f[2] ?? 'N/A',
      lon: f[5]?.toDouble(),
      lat: f[6]?.toDouble(),
      altitude: f[7]?.toDouble(),
      speed: f[9] != null ? f[9].toDouble() * 3.6 : null,
      heading: f[10]?.toDouble(),
    );
  }
}

class FlightScreen extends StatefulWidget {
  const FlightScreen({super.key});
  @override
  State<FlightScreen> createState() => _FlightScreenState();
}

class _FlightScreenState extends State<FlightScreen> {
  List<Flight> flights = [];
  bool loading = true;
  String status = 'Yükleniyor...';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchFlights();
    timer = Timer.periodic(const Duration(seconds: 15), (_) => fetchFlights());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchFlights() async {
    try {
      setState(() => status = '🔄 Güncelleniyor...');
      final res = await http.get(Uri.parse(
        'https://opensky-network.org/api/states/all?lamin=35&lomin=25&lamax=43&lomax=45'
      ));
      final data = jsonDecode(res.body);
      final states = data['states'] as List<dynamic>? ?? [];
      setState(() {
        flights = states
          .map((f) => Flight.fromList(f))
          .where((f) => f.lat != null && f.lon != null)
          .toList();
        loading = false;
        status = '✅ ${flights.length} uçuş canlı';
      });
    } catch (e) {
      setState(() => status = '❌ Bağlantı hatası');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.flight, color: Colors.blue),
          SizedBox(width: 8),
          Text('Uçuş Takip', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: Colors.grey[900],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(status, style: const TextStyle(color: Colors.green, fontSize: 12)),
          ),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: fetchFlights,
            child: ListView.builder(
              itemCount: flights.length,
              itemBuilder: (ctx, i) {
                final f = flights[i];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Text('✈️', style: TextStyle(fontSize: 28)),
                    title: Text(f.callsign, style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    subtitle: Text('🌍 ${f.country}', style: TextStyle(color: Colors.grey[400])),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(f.altitude != null ? '${f.altitude!.round()} m' : 'N/A',
                          style: const TextStyle(color: Colors.blue, fontSize: 12)),
                        Text(f.speed != null ? '${f.speed!.round()} km/h' : 'N/A',
                          style: const TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Colors.grey[850],
                        title: Text('✈️ ${f.callsign}', style: const TextStyle(color: Colors.white)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🌍 Ülke: ${f.country}', style: const TextStyle(color: Colors.white)),
                            Text('📡 ICAO: ${f.icao}', style: const TextStyle(color: Colors.white)),
                            Text('🔼 İrtifa: ${f.altitude?.round() ?? "N/A"} m', style: const TextStyle(color: Colors.white)),
                            Text('💨 Hız: ${f.speed?.round() ?? "N/A"} km/h', style: const TextStyle(color: Colors.white)),
                            Text('🧭 Yön: ${f.heading?.round() ?? "N/A"}°', style: const TextStyle(color: Colors.white)),
                            Text('📍 Konum: ${f.lat?.toStringAsFixed(2)}, ${f.lon?.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context),
                          child: const Text('Kapat'))],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }
}
