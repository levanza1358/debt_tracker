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
        cardTheme: CardTheme(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: _debts.length,
                  itemBuilder: (context, index) {
                    final debt = _debts[index];
                    return FutureBuilder<double>(
                      future: _getTotalPayments(debt.id),
                      builder: (context, snapshot) {
                        final totalPaid = snapshot.data ?? 0.0;
                        final remaining = debt.jumlahHutang - totalPaid;
                        final isFullyPaid = remaining <= 0;

                        return Card(
                          child: InkWell(
                            onTap: () => _viewPayments(debt),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          debt.namaHutang,
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                      ),
                                      if (isFullyPaid)
                                        const Icon(Icons.check_circle, color: Colors.green)
                                      else
                                        const Icon(Icons.pending, color: Colors.orange),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tanggal: ${DateFormat('dd/MM/yyyy').format(debt.tanggalHutang)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (debt.deskripsi != null && debt.deskripsi!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Deskripsi: ${debt.deskripsi}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Hutang',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              'Rp ${debt.jumlahHutang.toStringAsFixed(0)}',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sudah Dibayar',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              'Rp ${totalPaid.toStringAsFixed(0)}',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sisa',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              'Rp ${remaining.toStringAsFixed(0)}',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: remaining > 0 ? Colors.red : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
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
      title: const Text('Tambah Hutang Baru'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Hutang',
                hintText: 'Contoh: Hutang ke Ahmad',
              ),
              validator: (value) => value!.isEmpty ? 'Nama hutang harus diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jumlahController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Hutang (Rp)',
                hintText: 'Contoh: 500000',
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Jumlah hutang harus diisi' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tanggal: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Ubah'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deskripsiController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Catatan tambahan...',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
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
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Hutang',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Rp ${widget.debt.jumlahHutang.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Dibayar',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Rp ${totalPaid.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Sisa',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Rp ${remaining.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: remaining > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                    ? const Center(child: Text('Belum ada pembayaran'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Rp ${payment.jumlahBayar.toStringAsFixed(0)}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(payment.tanggalBayar),
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (payment.fotoUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        payment.fotoUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    const Icon(Icons.image_not_supported),
                                ],
                              ),
                            ),
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
              decoration: const InputDecoration(
                labelText: 'Jumlah Bayar (Rp)',
                hintText: 'Contoh: 100000',
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Jumlah bayar harus diisi' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tanggal: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Ubah'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_imageFile!.path),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pilih Bukti Bayar'),
                  ),
                ),
              ],
            ),
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Bukti pembayaran akan diupload',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
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
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: _savePayment,
                child: const Text('Simpan'),
              ),
      ],
    );
  }
}