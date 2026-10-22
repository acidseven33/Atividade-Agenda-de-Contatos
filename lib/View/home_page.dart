
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_4/DataBase/helper/contact_helper.dart';
import 'package:flutter_application_4/DataBase/Model/contact_model.dart';
import 'package:flutter_application_4/View/contact_page.dart';

enum OrderOptions { orderAZ, orderZA }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ContactHelper _helper = ContactHelper();

  List<Contact> _contacts = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  // Carrega os contatos salvos no SQLite.
  Future<void> _reload() async {
    try {
      final List<Contact> list = await _helper.getAllContacts();

      if (!mounted) return;

      setState(() {
        _contacts = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar contatos: $e'),
        ),
      );
    }
  }

  // Filtra os contatos por nome ou e-mail.
  List<Contact> get _filtered {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) {
      return List<Contact>.from(_contacts);
    }

    return _contacts.where((contact) {
      return contact.name.toLowerCase().contains(query) ||
          contact.email.toLowerCase().contains(query);
    }).toList();
  }

  // Abre a tela de cadastro ou edição.
  Future<void> _openContact({Contact? contact}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactPage(contact: contact),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await _reload();
    }
  }

  // Ordena os contatos alfabeticamente.
  void _sortContacts(OrderOptions order) {
    setState(() {
      _contacts.sort((a, b) {
        final nameA = a.name.toLowerCase();
        final nameB = b.name.toLowerCase();

        if (order == OrderOptions.orderAZ) {
          return nameA.compareTo(nameB);
        }

        return nameB.compareTo(nameA);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Contatos'),
        centerTitle: true,
        actions: [
          PopupMenuButton<OrderOptions>(
            tooltip: 'Ordenar contatos',
            icon: const Icon(Icons.sort_by_alpha),
            itemBuilder: (context) => const [
              PopupMenuItem<OrderOptions>(
                value: OrderOptions.orderAZ,
                child: Text('Ordenar de A-Z'),
              ),
              PopupMenuItem<OrderOptions>(
                value: OrderOptions.orderZA,
                child: Text('Ordenar de Z-A'),
              ),
            ],
            onSelected: _sortContacts,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _openContact(),
        tooltip: 'Adicionar contato',
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // Campo de busca.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Buscar contato',
                hintText: 'Nome ou e-mail',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _search = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
          ),

          // Lista de contatos.
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _contacts.isEmpty
                                ? 'Nenhum contato cadastrado.\n'
                                    'Toque em + para adicionar.'
                                : 'Nenhum contato encontrado.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          return _contactCard(_filtered[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Monta o card de cada contato.
  Widget _contactCard(Contact contact) {
    final imagePath = contact.img;

    final bool photoExists = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    final addressParts = [
      contact.street,
      contact.number,
      contact.neighborhood,
      contact.city,
      contact.state,
    ];

    final address = addressParts
        .where((value) => value.trim().isNotEmpty)
        .join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        leading: CircleAvatar(
          radius: 28,
          backgroundImage: photoExists
              ? FileImage(File(imagePath))
              : null,
          child: photoExists
              ? null
              : const Icon(Icons.person, size: 30),
        ),

        title: Text(
          contact.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact.email.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  contact.email,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              if (contact.phone.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text('Telefone: ${contact.phone}'),
              ],

              if (address.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        isThreeLine: true,

        trailing: const Icon(Icons.more_vert),

        onTap: () => _showOptions(contact),
      ),
    );
  }

  // Exibe as opções disponíveis para o contato.
  void _showOptions(Contact contact) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.call,
                  color: Colors.green,
                ),
                title: const Text('Ligar'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _callContact(contact);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.edit,
                  color: Colors.blue,
                ),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openContact(contact: contact);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text('Excluir'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _confirmDelete(contact);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Realiza a ligação telefônica.
  Future<void> _callContact(Contact contact) async {
    final phone = contact.phone.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (phone.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este contato não tem telefone cadastrado.',
          ),
        ),
      );
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final launched = await launchUrl(uri);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível iniciar a ligação.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao tentar realizar a ligação.',
          ),
        ),
      );
    }
  }

  // Solicita confirmação antes de excluir.
  Future<void> _confirmDelete(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir contato?'),
          content: Text(
            'Deseja realmente excluir ${contact.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    if (contact.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar o contato.',
          ),
        ),
      );
      return;
    }

    try {
      await _helper.deleteContact(contact.id!);
      await _reload();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contato excluído com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir contato: $e'),
        ),
      );
    }
  }
}
