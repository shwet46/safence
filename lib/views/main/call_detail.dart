import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';

class CallDetailScreen extends StatefulWidget {
  final String number;
  final String? owner;
  final Map<String, dynamic>? numlookup;
  final Map<String, dynamic>? numverify;
  final double? spamScore;
  final bool isSpam;

  const CallDetailScreen({
    super.key,
    required this.number,
    this.owner,
    this.numlookup,
    this.numverify,
    this.spamScore,
    this.isSpam = false,
  });

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  List<CallLogEntry> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogsForNumber();
  }

  String _normalizeNumber(String number) {
    final digits = number.replaceAll(RegExp(r"[^0-9]"), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  Future<void> _fetchLogsForNumber() async {
    try {
      final Iterable<CallLogEntry> all = await CallLog.get();
      final key = _normalizeNumber(widget.number);
      final filtered = all.where((e) {
        final n = e.number ?? '';
        final kn = _normalizeNumber(n);
        return kn.isNotEmpty && kn == key;
      }).toList();
      filtered.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
      if (mounted) setState(() {
        _logs = filtered;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _logs = []; _loading = false; });
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white54))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  String _formatDateTimeFromTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '${m}m ${s}s';
  }

  IconData _getCallIcon(CallType? callType) {
    switch (callType) {
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      case CallType.rejected:
        return Icons.call_end;
      default:
        return Icons.call_received;
    }
  }

  Color _getCallColor(CallType? callType) {
    switch (callType) {
      case CallType.outgoing:
        return Colors.green;
      case CallType.missed:
      case CallType.rejected:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call details'),
        backgroundColor: const Color(0xFF0F0F0F),
      ),
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.number, style: TextStyle(color: widget.isSpam ? Colors.red : Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (widget.owner != null) Text(widget.owner!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Row(children: [
                if (widget.isSpam)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFE25C5C), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Spam', style: TextStyle(color: Colors.white)),
                  ),
                if (widget.spamScore != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                    child: Text('Score ${widget.spamScore!.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              ]),
              const SizedBox(height: 16),

              Card(
                color: const Color(0xFF121212),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lookup details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _buildInfoRow('Owner', widget.owner),
                      _buildInfoRow('Carrier', widget.numlookup?['carrier']?.toString() ?? widget.numverify?['carrier']?.toString()),
                      _buildInfoRow('Location', widget.numlookup?['location']?.toString() ?? widget.numverify?['location']?.toString() ?? widget.numverify?['country_name']?.toString()),
                      _buildInfoRow('Line type', widget.numlookup?['line_type']?.toString() ?? widget.numverify?['line_type']?.toString()),
                      _buildInfoRow('Country', widget.numlookup?['country_name']?.toString() ?? widget.numverify?['country_name']?.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                color: const Color(0xFF121212),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Call history for this number', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (_loading) const Center(child: CircularProgressIndicator(color: Colors.white)),
                      if (!_loading && _logs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No call history found for this number', style: TextStyle(color: Colors.white70)),
                        ),
                      if (!_loading && _logs.isNotEmpty)
                        ..._logs.map((call) {
                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(_getCallIcon(call.callType), color: _getCallColor(call.callType)),
                                title: Text(call.name ?? call.number ?? '', style: const TextStyle(color: Colors.white)),
                                subtitle: Text(_formatDateTimeFromTimestamp(call.timestamp), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                trailing: Text(_formatDuration(call.duration ?? 0), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ),
                              const Divider(color: Color(0xFF222222)),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}