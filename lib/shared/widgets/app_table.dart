import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppDataTable extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    this.showCheckboxColumn = false,
    super.key,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool showCheckboxColumn;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        horizontalMargin: AppSpacing.sm,
        columnSpacing: AppSpacing.lg,
        showCheckboxColumn: showCheckboxColumn,
        columns: columns,
        rows: rows,
      ),
    );
  }
}
