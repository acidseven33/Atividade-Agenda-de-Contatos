import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_4/DataBase/Model/contact_model.dart';
import 'package:flutter_application_4/DataBase/helper/contact_helper.dart';
import 'package:flutter_application_4/services/cep_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ContactPage extends StatefulWidget {
  final Contact? contact;
  const ContactPage({super.key, this.contact});
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cep = TextEditingController();
  final _street = TextEditingController();
  final _neighborhood = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _helper = ContactHelper();
  final _picker = ImagePicker();
  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {'#': RegExp(r'\d')});
  final _cepMask = MaskTextInputFormatter(mask: '#####-###', filter: {'#': RegExp(r'\d')});
  String? _imagePath;
  bool _consultandoCep = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    if (c != null) {
      _name.text = c.name; _email.text = c.email; _phone.text = c.phone;
      _cep.text = c.cep; _street.text = c.street; _neighborhood.text = c.neighborhood;
      _city.text = c.city; _state.text = c.state; _number.text = c.number;
      _complement.text = c.complement; _imagePath = c.img;
      _phoneMask.formatEditUpdate(const TextEditingValue(text: ''), TextEditingValue(text: c.phone));
    }
  }

  @override
  void dispose() {
    for (final c in [_name,_email,_phone,_cep,_street,_neighborhood,_city,_state,_number,_complement]) { c.dispose(); }
    super.dispose();
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _consultarCep() async {
    FocusScope.of(context).unfocus();
    setState(() => _consultandoCep = true);
    try {
      final data = await CepService.consultar(_cep.text);
      if (!mounted) return;
      setState(() {
        _street.text = (data['logradouro'] ?? '').toString();
        _neighborhood.text = (data['bairro'] ?? '').toString();
        _city.text = (data['localidade'] ?? '').toString();
        _state.text = (data['uf'] ?? '').toString();
        if (_complement.text.trim().isEmpty) _complement.text = (data['complemento'] ?? '').toString();
        _cep.text = (data['cep'] ?? _cep.text).toString();
      });
      _message('Endereço preenchido pelo ViaCEP. Informe o número e confira os dados.');
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('FormatException: ', '').replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _consultandoCep = false);
    }
  }

  Future<void> _escolherFoto() async {
    final source = await showModalBottomSheet<ImageSource>(context: context, builder: (context) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Tirar foto com a câmera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Selecionar da galeria'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
      if (_imagePath != null) ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Remover foto'), onTap: () => Navigator.pop(context, null)),
    ])));
    if (source == null) {
      // O fechamento do menu sem escolher não altera a foto; remover é oferecido separadamente abaixo.
      return;
    }
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
      if (image != null && mounted) setState(() => _imagePath = image.path);
    } on PlatformException catch (e) {
      if (mounted) _message('Não foi possível acessar a imagem: ${e.message ?? e.code}');
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final old = widget.contact;
    final contact = Contact(
      id: old?.id, name: _name.text.trim(), email: _email.text.trim(), phone: _phone.text.trim(), img: _imagePath,
      cep: _cep.text.trim(), street: _street.text.trim(), neighborhood: _neighborhood.text.trim(),
      city: _city.text.trim(), state: _state.text.trim().toUpperCase(), number: _number.text.trim(), complement: _complement.text.trim(),
    );
    try {
      if (old == null) { await _helper.saveContact(contact); } else { await _helper.updateContact(contact); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _message('Erro ao salvar contato: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String? _validarEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Informe o e-mail.';
    final regex = RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$");
    if (!regex.hasMatch(email)) return 'E-mail inválido. Ex.: nome@dominio.com';
    return null;
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboardType, String? Function(String?)? validator, List<TextInputFormatter>? formatters, int maxLines = 1, String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(controller: controller, keyboardType: keyboardType, validator: validator, inputFormatters: formatters,
      maxLines: maxLines, decoration: InputDecoration(labelText: label, hintText: hint)),
  );

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _imagePath != null && _imagePath!.isNotEmpty && File(_imagePath!).existsSync();
    return Scaffold(
      appBar: AppBar(title: Text(widget.contact == null ? 'Novo contato' : 'Editar contato')),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: InkWell(onTap: _escolherFoto, borderRadius: BorderRadius.circular(70), child: Column(children: [
          CircleAvatar(radius: 58, backgroundColor: Colors.blue.shade50,
            backgroundImage: hasPhoto ? FileImage(File(_imagePath!)) : null,
            child: hasPhoto ? null : const Icon(Icons.add_a_photo_outlined, size: 38)),
          const SizedBox(height: 6), const Text('Adicionar foto (câmera ou galeria)')]))),
        const SizedBox(height: 22),
        _field('Nome *', _name, validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome.' : null),
        _field('E-mail *', _email, keyboardType: TextInputType.emailAddress, validator: _validarEmail, hint: 'nome@dominio.com'),
        _field('Telefone', _phone, keyboardType: TextInputType.phone, formatters: [_phoneMask]),
        const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Endereço por CEP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _field('CEP', _cep, keyboardType: TextInputType.number, formatters: [_cepMask], hint: '00000-000')),
          const SizedBox(width: 8),
          Padding(padding: const EdgeInsets.only(top: 3), child: FilledButton(onPressed: _consultandoCep ? null : _consultarCep,
            child: _consultandoCep ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buscar'))),
        ]),
        _field('Logradouro', _street),
        _field('Bairro', _neighborhood),
        Row(children: [Expanded(child: _field('Cidade', _city)), const SizedBox(width: 10), SizedBox(width: 90, child: _field('UF', _state))]),
        Row(children: [Expanded(child: _field('Número', _number)), const SizedBox(width: 10), Expanded(child: _field('Complemento', _complement))]),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _salvando ? null : _salvar, icon: const Icon(Icons.save), label: Text(_salvando ? 'Salvando...' : 'Salvar contato')),
      ])),
    );
  }
}
