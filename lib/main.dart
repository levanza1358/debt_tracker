import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class Debt {
  final String id;
  final String namaHutang;
  final double jumlahHutang;
  final DateTime tanggalHutang;
  final String? deskripsi;

  Debt({
    required this.id,
    required this.namaHutang,
    required this.jumlahHutang,
    required this.tanggalHutang,
    this.deskripsi,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'],
      namaHutang: json['nama_hutang'],
      jumlahHutang: json['jumlah_hutang'].toDouble(),
      tanggalHutang: DateTime.parse(json['tanggal_hutang']),
      deskripsi: json['deskripsi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_hutang': namaHutang,
      'jumlah_hutang': jumlahHutang,
      'tanggal_hutang': tanggalHutang.toIso8601String().split('T').first,
      'deskripsi': deskripsi,
    };
  }
}

class Payment {
  final String id;
  final String debtId;
  final double jumlahBayar;
  final DateTime tanggalBayar;
  final String? fotoUrl;

  Payment({
    required this.id,
    required this.debtId,
    required this.jumlahBayar,
    required this.tanggalBayar,
    this.fotoUrl,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      debtId: json['debt_id'],
      jumlahBayar: json['jumlah_bayar'].toDouble(),
      tanggalBayar: DateTime.parse(json['tanggal_bayar']),
      fotoUrl: json['foto_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debt_id': debtId,
      'jumlah_bayar': jumlahBayar,
      'tanggal_bayar': tanggalBayar.toIso8601String().split('T').first,
      'foto_url': fotoUrl,
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://inntsqnvfrqdhrobrygt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlubnRzcW52ZnJxZGhyb2JyeWd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgxNjg5MTksImV4cCI6MjA4Mzc0NDkxOX0.jndqk91ugv8HimpzBKmqjdjXrRCziICz2jwjwPgc7Vk',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatatan Hutang',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DebtListScreen(),
    );
  }
}

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  List<Debt> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDebts();
  }

  Future<void> _fetchDebts() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.from('debts').select();
      _debts = (response as List).map((json) => Debt.fromJson(json)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<double> _getTotalPayments(String debtId) async {
    try {
      final response = await Supabase.instance.client
          .from('payments')
          .select('jumlah_bayar')
          .eq('debt_id', debtId);
      final payments = (response as List<dynamic>).map<double>((json) {
        final data = json as Map<String, dynamic>;
        return (data['jumlah_bayar'] as num).toDouble();
      }).toList();
      return payments.fold<double>(0.0, (double sum, double amount) => sum + amount);
    } catch (e) {
      return 0.0;
    }
  }

  void _addDebt() {
    showDialog(
      context: context,
      builder: (context) => const AddDebtDialog(),
    ).then((_) => _fetchDebts());
  }

  void _viewPayments(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(debt: debt),
      ),
    ).then((_) => _fetchDebts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Hutang'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debts.isEmpty
              ? const Center(child: Text('Belum ada hutang'))
              : ListView.builder(
                  itemCount: _debts.length,
                  itemBuilder: (context, index) {
                    final debt = _debts[index];
                    return FutureBuilder<double>(
                      future: _getTotalPayments(debt.id),
                      builder: (context, snapshot) {
                        final totalPaid = snapshot.data ?? 0.0;
                        final remaining = debt.jumlahHutang - totalPaid;
                        return ListTile(
                          title: Text(debt.namaHutang),
                          subtitle: Text(
                            'Total: Rp ${debt.jumlahHutang.toStringAsFixed(0)}\n'
                            'Dibayar: Rp ${totalPaid.toStringAsFixed(0)}\n'
                            'Sisa: Rp ${remaining.toStringAsFixed(0)}',
                          ),
                          onTap: () => _viewPayments(debt),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDebt,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddDebtDialog extends StatefulWidget {
  const AddDebtDialog({super.key});

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _jumlahController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _deskripsiController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Supabase.instance.client.from('debts').insert({
          'nama_hutang': _namaController.text,
          'jumlah_hutang': double.parse(_jumlahController.text),
          'tanggal_hutang': _selectedDate.toIso8601String().split('T').first,
          'deskripsi': _deskripsiController.text.isEmpty ? null : _deskripsiController.text,
        });
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Hutang'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Hutang'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _jumlahController,
              decoration: const InputDecoration(labelText: 'Jumlah Hutang'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            Row(
              children: [
                Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Pilih Tanggal'),
                ),
              ],
            ),
            TextFormField(
              controller: _deskripsiController,
              decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _saveDebt,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final Debt debt;

  const PaymentScreen({super.key, required this.debt});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('payments')
          .select()
          .eq('debt_id', widget.debt.id);
      _payments = (response as List).map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addPayment() {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(debtId: widget.debt.id),
    ).then((_) => _fetchPayments());
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = _payments.fold(0.0, (sum, payment) => sum + payment.jumlahBayar);
    final remaining = widget.debt.jumlahHutang - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran - ${widget.debt.namaHutang}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Total Hutang: Rp ${widget.debt.jumlahHutang.toStringAsFixed(0)}'),
                Text('Total Dibayar: Rp ${totalPaid.toStringAsFixed(0)}'),
                Text('Sisa: Rp ${remaining.toStringAsFixed(0)}'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                    ? const Center(child: Text('Belum ada pembayaran'))
                    : ListView.builder(
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return ListTile(
                            title: Text('Rp ${payment.jumlahBayar.toStringAsFixed(0)}'),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(payment.tanggalBayar)),
                            trailing: payment.fotoUrl != null
                                ? Image.network(payment.fotoUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPayment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddPaymentDialog extends StatefulWidget {
  final String debtId;

  const AddPaymentDialog({super.key, required this.debtId});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  XFile? _imageFile;
  bool _isUploading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(imageFile.path);
      await Supabase.instance.client.storage
          .from('debt_photos')
          .upload(fileName, file);
      final publicUrl = Supabase.instance.client.storage
          .from('debt_photos')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      String? fotoUrl;
      if (_imageFile != null) {
        fotoUrl = await _uploadImage(_imageFile!);
      }
      try {
        await Supabase.instance.client.from('payments').insert({
          'debt_id': widget.debtId,
          'jumlah_bayar': double.parse(_jumlahController.text),
          'tanggal_bayar': _selectedDate.toIso8601String().split('T').first,
          'foto_url': fotoUrl,
        });
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Pembayaran'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _jumlahController,
              decoration: const InputDecoration(labelText: 'Jumlah Bayar'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            Row(
              children: [
                Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Pilih Tanggal'),
                ),
              ],
            ),
            Row(
              children: [
                _imageFile != null
                    ? Image.file(File(_imageFile!.path), width: 50, height: 50, fit: BoxFit.cover)
                    : const Text('Tidak ada gambar'),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text('Pilih Gambar'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        _isUploading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: _savePayment,
                child: const Text('Simpan'),
              ),
      ],
    );
  }
}