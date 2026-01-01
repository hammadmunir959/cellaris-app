import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/features/repairs/controller/repair_controller.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:intl/intl.dart';

class RepairsScreen extends ConsumerStatefulWidget {
  const RepairsScreen({super.key});

  @override
  ConsumerState<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends ConsumerState<RepairsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.watch(repairProvider.notifier);
    final tickets = notifier.searchTickets(_searchQuery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repair Intelligence',
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                const Text('Enterprise-grade device lifecycle management.', style: TextStyle(color: Colors.grey)),
              ],
            ),
            PrimaryButton(
              label: 'New Repair Ticket',
              onPressed: () => _showAddRepairDialog(context, ref),
              icon: LucideIcons.plus,
              width: 180,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Metrics Summary Strip
        Row(
          children: [
            _MetricCard(
              label: 'Total Revenue',
              value: 'Rs. ${NumberFormat('#,###').format(notifier.calculateTotalRevenue())}',
              icon: LucideIcons.banknote,
              color: Colors.green,
            ),
            const SizedBox(width: 16),
            _MetricCard(
              label: 'Active Repairs',
              value: '${notifier.getActiveRepairsCount()}',
              icon: LucideIcons.activity,
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            _MetricCard(
              label: 'Due Today',
              value: '${notifier.getDueTodayCount()}',
              icon: LucideIcons.clock,
              color: Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Unified Search Bar
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by Device Model, Customer Name or Ticket ID...',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  })
                : null,
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Kanban Board
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RepairColumn(
                title: 'Received', 
                status: RepairStatus.received,
                tickets: tickets.where((t) => t.status == RepairStatus.received).toList(),
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _RepairColumn(
                title: 'In Repair', 
                status: RepairStatus.inRepair,
                tickets: tickets.where((t) => t.status == RepairStatus.inRepair).toList(),
                color: Colors.orange,
              ),
              const SizedBox(width: 16),
              _RepairColumn(
                title: 'Ready', 
                status: RepairStatus.ready,
                tickets: tickets.where((t) => t.status == RepairStatus.ready).toList(),
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _RepairColumn(
                title: 'Delivered', 
                status: RepairStatus.delivered,
                tickets: tickets.where((t) => t.status == RepairStatus.delivered).toList(),
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddRepairDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final deviceController = TextEditingController();
    final issueController = TextEditingController();
    final costController = TextEditingController();
    DateTime? selectedDate;
    
    final customers = ref.read(customerProvider);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(LucideIcons.wrench, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text('Professional Entry'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CLIENT PROFILE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Autocomplete<Customer>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') return customers;
                      return customers.where((Customer option) {
                        return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                               option.contact.contains(textEditingValue.text);
                      });
                    },
                    displayStringForOption: (Customer option) => option.name,
                    onSelected: (Customer selection) {
                      nameController.text = selection.name;
                      phoneController.text = selection.contact;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (val) => nameController.text = val,
                        decoration: const InputDecoration(
                          labelText: 'Customer Search / New Name',
                          hintText: 'Search database...',
                          prefixIcon: Icon(LucideIcons.user, size: 18),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController, 
                    decoration: const InputDecoration(
                      labelText: 'Primary Contact', 
                      prefixIcon: Icon(LucideIcons.phone, size: 18),
                      border: OutlineInputBorder()
                    )
                  ),
                  const SizedBox(height: 24),
                  const Text('ASSET SPECIFICATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deviceController, 
                    decoration: const InputDecoration(
                      labelText: 'Device Identification (e.g. iPhone 15 Pro)', 
                      prefixIcon: Icon(LucideIcons.smartphone, size: 18),
                      border: OutlineInputBorder()
                    )
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: issueController, 
                    decoration: const InputDecoration(
                      labelText: 'Technical Issue Diagnostic', 
                      prefixIcon: Icon(LucideIcons.alertTriangle, size: 18),
                      border: OutlineInputBorder()
                    )
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: costController, 
                    decoration: const InputDecoration(
                      labelText: 'Estimated Service Fee', 
                      prefixIcon: Icon(LucideIcons.banknote, size: 18),
                      border: OutlineInputBorder()
                    ), 
                    keyboardType: TextInputType.number
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        if (context.mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 12, minute: 0),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          }
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Service SLA Deadline', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(
                                selectedDate == null 
                                  ? 'Not Scheduled' 
                                  : DateFormat('MMM dd, yyyy @ hh:mm a').format(selectedDate!),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Discard', style: TextStyle(color: Colors.grey))
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.save, size: 16),
              label: const Text('Commit Only'),
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                try {
                  await ref.read(repairProvider.notifier).createTicket(
                    name: nameController.text,
                    contact: phoneController.text,
                    device: deviceController.text,
                    issue: issueController.text,
                    cost: double.tryParse(costController.text) ?? 0,
                    expectedReturnDate: selectedDate,
                    printAfter: false,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Error: $e')));
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: const BorderSide(color: Colors.blueGrey),
              ),
            ),
            const SizedBox(width: 8),
            PrimaryButton(
              label: 'Commit & Token',
              icon: LucideIcons.printer,
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                try {
                  await ref.read(repairProvider.notifier).createTicket(
                    name: nameController.text,
                    contact: phoneController.text,
                    device: deviceController.text,
                    issue: issueController.text,
                    cost: double.tryParse(costController.text) ?? 0,
                    expectedReturnDate: selectedDate,
                    printAfter: true,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Service Error: $e')));
                }
              },
              width: 170,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 0.5)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RepairColumn extends StatelessWidget {
  final String title;
  final RepairStatus status;
  final List<RepairTicket> tickets;
  final Color color;

  const _RepairColumn({required this.title, required this.status, required this.tickets, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${tickets.length}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RepairCard(ticket: tickets[index], color: color),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepairCard extends ConsumerWidget {
  final RepairTicket ticket;
  final Color color;
  const _RepairCard({required this.ticket, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final bool isUpcoming = ticket.expectedReturnDate != null && 
                            ticket.expectedReturnDate!.isAfter(now) &&
                            ticket.expectedReturnDate!.difference(now).inHours <= 1 &&
                            ticket.status != RepairStatus.delivered;

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: () => _showRepairDetailsDialog(context, ticket),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ticket.id, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  if (isUpcoming)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('PRIORITY', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  else
                    Text(
                      DateFormat('hh:mm a').format(ticket.createdAt),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(ticket.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(LucideIcons.smartphone, size: 10, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(ticket.deviceModel, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const Divider(height: 16, color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rs. ${ticket.estimatedCost.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      _ActionIcon(icon: LucideIcons.printer, onTap: () => ref.read(repairProvider.notifier).printTicket(ticket)),
                      const SizedBox(width: 6),
                      _ActionIcon(icon: LucideIcons.chevronRight, color: color, onTap: () => _showUpdateStatusDialog(context, ref, ticket)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRepairDetailsDialog(BuildContext context, RepairTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.info, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text('Protocol Details: ${ticket.id}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailItem('Client', ticket.customerName, LucideIcons.user),
                _detailItem('Point of Contact', ticket.customerContact, LucideIcons.phone),
                const Divider(height: 32, color: Colors.white10),
                _detailItem('Equipment Model', ticket.deviceModel, LucideIcons.smartphone),
                _detailItem('Technical Complaint', ticket.issueDescription, LucideIcons.alertTriangle),
                _detailItem('Professional Fee Est.', 'Rs. ${ticket.estimatedCost.toInt()}', LucideIcons.banknote),
                const Divider(height: 32, color: Colors.white10),
                _detailItem('Current Phase', ticket.status.name.toUpperCase(), LucideIcons.activity),
                _detailItem('SLA Commitment', ticket.expectedReturnDate == null ? 'Not Scheduled' : DateFormat('MMM dd, hh:mm a').format(ticket.expectedReturnDate!), LucideIcons.calendar),
                const Divider(height: 32, color: Colors.white10),
                const Text('OPERATIONAL LOGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ticket.notes.isEmpty 
                      ? [const Text('No logs available', style: TextStyle(color: Colors.grey, fontSize: 12))]
                      : ticket.notes.map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppTheme.primaryColor)),
                              Expanded(child: Text(note, style: const TextStyle(fontSize: 11))),
                            ],
                          ),
                        )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          PrimaryButton(
            label: 'Close Protocol',
            onPressed: () => Navigator.pop(context),
            width: 140,
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, WidgetRef ref, RepairTicket ticket) {
    final noteController = TextEditingController();
    RepairStatus selectedStatus = ticket.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text('Update Repair Phase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RepairStatus>(
                value: selectedStatus,
                dropdownColor: AppTheme.darkSurface,
                items: RepairStatus.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedStatus = val);
                },
                decoration: const InputDecoration(labelText: 'New Operational Stage', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Technician Note',
                  hintText: 'Describe progress...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            PrimaryButton(
              label: 'Update Stage',
              onPressed: () {
                ref.read(repairProvider.notifier).updateStatus(
                  ticket.id, 
                  selectedStatus,
                  note: noteController.text,
                );
                Navigator.pop(context);
              },
              width: 140,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionIcon({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: (color ?? Colors.grey).withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 12, color: color ?? Colors.grey),
        ),
      ),
    );
  }
}
