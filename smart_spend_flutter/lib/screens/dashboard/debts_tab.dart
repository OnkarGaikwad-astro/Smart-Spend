import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../models/debt_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/debt_details_sheet.dart';
import '../../widgets/debt_dialogs.dart';

class DebtsTab extends StatefulWidget {
  const DebtsTab({super.key});

  @override
  State<DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends State<DebtsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _direction = 'ALL'; // 'ALL', 'LENT', 'BORROWED'
  String _filter = 'PENDING'; // 'PENDING', 'SETTLED', 'ALL'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddPersonDialog({String initialType = 'LENT'}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPersonDebtDialog(initialType: initialType),
    );
  }

  void _openDetailsSheet(String debtId) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DebtDetailsSheet(debtId: debtId),
    );
  }

  void _openAddMoreDialog(DebtModel debt) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMoreMoneyDialog(debt: debt),
    );
  }

  void _openRepaymentDialog(DebtModel debt) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordRepaymentDialog(debt: debt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final provider = context.watch<AppProvider>();
    final allDebts = provider.debts;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = allDebts.where((d) {
      // Direction filter
      if (_direction == 'LENT' && !d.isLent) return false;
      if (_direction == 'BORROWED' && !d.isBorrowed) return false;

      // Status filter
      if (_filter == 'PENDING' && d.isSettled) return false;
      if (_filter == 'SETTLED' && !d.isSettled) return false;

      // Search query
      if (query.isNotEmpty) {
        final matchesName = d.personName.toLowerCase().contains(query);
        final matchesNote = d.entries.any((e) => e.note.toLowerCase().contains(query));
        return matchesName || matchesNote;
      }
      return true;
    }).toList();

    final lentCount = allDebts.where((d) => d.isLent && !d.isSettled).length;
    final borrowedCount = allDebts.where((d) => d.isBorrowed && !d.isSettled).length;
    final settledCount = allDebts.where((d) => d.isSettled).length;

    return CustomScrollView(
      slivers: [
        // Top Hero Summary Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: colors.borderSubtle == Colors.transparent
                    ? null
                    : Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.primarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.handshake_rounded,
                                color: colors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Lent & Borrowed (Khata)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textMain,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${lentCount + borrowedCount} active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Three key figures: You'll Get, You'll Give, Net Balance
                  Row(
                    children: [
                      // You'll Get
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "YOU'LL GET",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppUtils.formatCurrency(provider.totalLentPending),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: provider.totalLentPending > 0
                                    ? colors.primary
                                    : colors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: colors.borderSubtle == Colors.transparent
                            ? colors.textMuted.withValues(alpha: 0.12)
                            : colors.borderSubtle,
                      ),
                      const SizedBox(width: 12),

                      // You'll Give
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "YOU'LL GIVE",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppUtils.formatCurrency(provider.totalBorrowedPending),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: provider.totalBorrowedPending > 0
                                    ? const Color(0xFFEF5350)
                                    : colors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: colors.borderSubtle == Colors.transparent
                            ? colors.textMuted.withValues(alpha: 0.12)
                            : colors.borderSubtle,
                      ),
                      const SizedBox(width: 12),

                      // Net
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "NET",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${provider.netDebtsBalance >= 0 ? '+' : ''}${AppUtils.formatCurrency(provider.netDebtsBalance)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: provider.netDebtsBalance >= 0
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFFEF5350),
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
        ),

        // Direction Selector & Search
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Direction Segmented Switch
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: colors.borderSubtle == Colors.transparent
                        ? null
                        : Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      _buildDirectionSegment('ALL', 'All (${allDebts.length})', colors),
                      _buildDirectionSegment('LENT', "You'll Get ($lentCount)", colors),
                      _buildDirectionSegment('BORROWED', "You'll Give ($borrowedCount)", colors),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: colors.textMain, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by person name or note...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: colors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    fillColor: colors.surface,
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                Row(
                  children: [
                    _buildStatusChip('PENDING', 'Pending (${lentCount + borrowedCount})', colors),
                    const SizedBox(width: 8),
                    _buildStatusChip('SETTLED', 'Settled ($settledCount)', colors),
                    const SizedBox(width: 8),
                    _buildStatusChip('ALL', 'All', colors),
                  ],
                ),
              ],
            ),
          ),
        ),

        // List of Records
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.handshake_outlined,
                        size: 40,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _filter == 'SETTLED'
                          ? 'No settled records yet'
                          : (_direction == 'BORROWED'
                              ? 'No borrowed money recorded'
                              : 'No lent money recorded'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _direction == 'BORROWED'
                          ? 'Record money you borrowed from friends or colleagues, and note repayments.'
                          : 'Record money friends borrow from you, and add more when they borrow again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(_direction == 'BORROWED' ? 'Record Borrowed' : 'Record Lent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _direction == 'BORROWED'
                            ? const Color(0xFFEF5350)
                            : colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _openAddPersonDialog(
                        initialType: _direction == 'BORROWED' ? 'BORROWED' : 'LENT',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final debt = filtered[index];
                  return _buildDebtCard(debt, colors);
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDirectionSegment(String key, String label, dynamic colors) {
    final isSelected = _direction == key;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _direction = key);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.surface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? colors.primary : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String key, String label, dynamic colors) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : colors.textMain,
      ),
      selectedColor: colors.primary,
      backgroundColor: colors.surface,
      side: colors.borderSubtle == Colors.transparent
          ? BorderSide.none
          : BorderSide(color: colors.borderSubtle),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _filter = key);
      },
    );
  }

  Widget _buildDebtCard(DebtModel debt, dynamic colors) {
    final isSettled = debt.isSettled;
    final isLent = debt.isLent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openDetailsSheet(debt.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: colors.borderSubtle == Colors.transparent
                  ? null
                  : Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Initials
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isLent
                          ? colors.primarySoft
                          : const Color(0xFFEF5350).withValues(alpha: 0.12),
                      child: Text(
                        debt.personName.isNotEmpty
                            ? debt.personName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isLent ? colors.primary : const Color(0xFFEF5350),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name and Direction Tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                debt.personName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textMain,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLent
                                      ? colors.primarySoft
                                      : const Color(0xFFEF5350).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isLent ? "You'll Get" : "You'll Give",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isLent ? colors.primary : const Color(0xFFEF5350),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${debt.lastNote}  •  ${AppUtils.formatDate(debt.lastActivityDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Amount Owed / Settled badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isSettled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF66BB6A)),
                                SizedBox(width: 4),
                                Text(
                                  'Settled',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF66BB6A),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            AppUtils.formatCurrency(debt.totalOwed),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLent ? colors.primary : const Color(0xFFEF5350),
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${debt.entries.length} entries',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Action Bar: "+ Add More" & "Repaid"
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openAddMoreDialog(debt),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.surface2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 15,
                                color: isLent ? colors.primary : const Color(0xFFEF5350),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Add More',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isLent ? colors.primary : const Color(0xFFEF5350),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: isSettled ? null : () => _openRepaymentDialog(debt),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.surface2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 15,
                                color: isSettled ? colors.textMuted : const Color(0xFF66BB6A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isLent ? 'Repaid' : 'Pay Back',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSettled ? colors.textMuted : const Color(0xFF66BB6A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
