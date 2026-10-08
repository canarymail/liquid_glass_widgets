import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/contact_models.dart';
import '../theme/contacts_theme.dart';
import 'contact_detail_view.dart';
import 'contact_edit_sheet.dart';

/// The root Contacts list screen matching Apple Contacts (iOS 26/27).
///
/// Demonstrates:
/// - Pinned [GlassAppBar.pinned] with ambient [GlassEditButton]
/// - [GlassEditScope] + [GlassReorderableList.grouped] with drag reordering
/// - Row-level delete confirmation badges with 90° rotation & slide-in pill
/// - [GlassSwipeActions] with leading & trailing platters and full-swipe dismiss
/// - [GlassContextMenu] on long press with authentic specular preview & actions
/// - [GlassNavigationLink] for typed declarative navigation to [ContactDetailView]
/// - [showGlassFullScreenCover] to present [ContactEditSheet]
class ContactsListView extends StatefulWidget {
  const ContactsListView({super.key});

  @override
  State<ContactsListView> createState() => _ContactsListViewState();
}

class _ContactsListViewState extends State<ContactsListView> {
  final GlassEditController _editController = GlassEditController();
  late List<ContactItem> _contacts;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _contacts = List.from(kInitialContacts);
  }

  void _addContact(ContactItem newContact) {
    setState(() {
      _contacts.insert(0, newContact);
    });
  }

  void _updateContact(ContactItem updated) {
    setState(() {
      final index = _contacts.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _contacts[index] = updated;
      }
    });
  }

  void _deleteContact(String id) {
    setState(() {
      _contacts.removeWhere((c) => c.id == id);
    });
  }

  void _openAddSheet() {
    showGlassFullScreenCover(
      context: context,
      builder: (ctx) => ContactEditSheet(
        onSave: _addContact,
      ),
    );
  }

  List<ContactItem> get _filteredContacts {
    if (_searchQuery.trim().isEmpty) return _contacts;
    final q = _searchQuery.toLowerCase();
    return _contacts
        .where((c) =>
            c.displayName.toLowerCase().contains(q) ||
            c.company.toLowerCase().contains(q) ||
            c.phone.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContacts;

    return ListenableBuilder(
      listenable: _editController,
      builder: (context, _) {
        return GlassPage(
          background: Container(
            color: ContactsTheme.bg.resolveFrom(context),
          ),
          child: GlassEditScope(
            controller: _editController,
            child: GlassScaffold(
              appBar: GlassAppBar.pinned(
                title: const Text('Contacts'),
                leading: [
                  GlassBarItem.custom(
                    child: GlassEditButton.explicit(
                      isEditing: _editController.isEditing,
                      onPressed: _editController.toggle,
                    ),
                  ),
                ],
                actions: [
                  GlassBarItem.icon(
                    icon: const Icon(CupertinoIcons.add),
                    onTap: _openAddSheet,
                  ),
                ],
              ),
              body: GlassSwipeActionScope(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + 54,
                    16,
                    48,
                  ),
                  children: [
                    // Search Field
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CupertinoSearchTextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        placeholder: 'Search',
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),

                    // My Card Section
                    if (_searchQuery.isEmpty) ...[
                      GlassGroupedSection(
                        children: [
                          GlassListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF8E8E93),
                                    Color(0xFF636366)
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'ME',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            title: const Text(
                              'Apple Developer',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('My Card'),
                            trailing: const Icon(CupertinoIcons.chevron_right,
                                size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Contacts Reorderable List
                    GlassReorderableList.grouped(
                      header: Text(
                        'ALL CONTACTS (${filtered.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      itemCount: filtered.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _contacts.removeAt(oldIndex);
                          _contacts.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final contact = filtered[index];
                        return _buildContactTile(contact, index);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactTile(ContactItem contact, int index) {
    // When editing is inactive, wrap in ContextMenu and SwipeActions.
    return ListenableBuilder(
      key: ValueKey(contact.id),
      listenable: _editController,
      builder: (context, child) {
        final isEditing = _editController.isEditing;

        final tile = GlassListTile(
          key: ValueKey(contact.id),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: contact.avatarColor,
            ),
            child: Center(
              child: Text(
                contact.initials,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          title: Text(
            contact.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: contact.company.isNotEmpty ? Text(contact.company) : null,
          trailing: isEditing
              ? null
              : const Icon(CupertinoIcons.chevron_right, size: 16),
          canDelete: isEditing,
          onDelete: () => _deleteContact(contact.id),
          canReorder: isEditing,
          reorderIndex: index,
          onTap: isEditing
              ? null
              : () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (ctx) => ContactDetailView(
                        contact: contact,
                        onContactUpdated: _updateContact,
                        onContactDeleted: _deleteContact,
                      ),
                    ),
                  );
                },
        );

        if (isEditing) {
          return tile;
        }

        // Standard interactive mode: swipe actions + context menu
        return GlassContextMenu(
          key: ValueKey(contact.id),
          actions: [
            GlassContextMenuAction(
              icon: const Icon(CupertinoIcons.bubble_left_fill),
              onPressed: () {},
              child: const Text('Send Message'),
            ),
            GlassContextMenuAction(
              icon: const Icon(CupertinoIcons.phone_fill),
              onPressed: () {},
              child: const Text('Call'),
            ),
            GlassContextMenuAction(
              icon: const Icon(CupertinoIcons.videocam_fill),
              onPressed: () {},
              child: const Text('FaceTime Video'),
            ),
            GlassContextMenuAction(
              icon: const Icon(CupertinoIcons.share),
              onPressed: () {},
              child: const Text('Share Contact'),
            ),
            GlassContextMenuAction(
              icon: const Icon(CupertinoIcons.trash_fill),
              isDestructive: true,
              onPressed: () => _deleteContact(contact.id),
              child: const Text('Delete Contact'),
            ),
          ],
          child: GlassSwipeActions(
            style: GlassSwipeActionStyle.tintedGlass,
            leadingActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.phone_fill),
                label: const Text('Call'),
                backgroundColor: ContactsTheme.green,
                onTap: () {},
              ),
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.bubble_left_fill),
                label: const Text('Message'),
                backgroundColor: ContactsTheme.blue,
                onTap: () {},
              ),
            ],
            trailingActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.trash_fill),
                label: const Text('Delete'),
                backgroundColor: ContactsTheme.red,
                isDestructive: true,
                onTap: () => _deleteContact(contact.id),
              ),
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.share),
                label: const Text('Share'),
                backgroundColor: ContactsTheme.orange,
                onTap: () {},
              ),
            ],
            onDismissed: () => _deleteContact(contact.id),
            child: tile,
          ),
        );
      },
    );
  }
}
