import 'ticket_type_model.dart';

const int kSeatColumns = 10;

class Seat {
  final String id;
  final String row;
  final int number;
  final String ticketTypeId;

  const Seat({
    required this.id,
    required this.row,
    required this.number,
    required this.ticketTypeId,
  });
}

class SeatGroup {
  final TicketType type;
  final List<List<Seat>> rows;

  const SeatGroup({required this.type, required this.rows});

  int get totalSeats => rows.fold(0, (sum, row) => sum + row.length);
}

String seatRowLabel(int index) {
  if (index < 26) return String.fromCharCode(65 + index);
  final first = String.fromCharCode(65 + (index ~/ 26) - 1);
  final second = String.fromCharCode(65 + (index % 26));
  return '$first$second';
}

List<SeatGroup> buildSeatLayout(List<TicketType> types) {
  final sorted = [...types]..sort((a, b) => a.price.compareTo(b.price));
  final groups = <SeatGroup>[];
  var rowIndex = 0;

  for (final type in sorted) {
    final rows = <List<Seat>>[];
    var remaining = type.totalQty;

    while (remaining > 0) {
      final count = remaining < kSeatColumns ? remaining : kSeatColumns;
      final label = seatRowLabel(rowIndex);
      rows.add(
        List.generate(
          count,
          (i) => Seat(
            id: '$label${i + 1}',
            row: label,
            number: i + 1,
            ticketTypeId: type.id,
          ),
        ),
      );
      remaining -= count;
      rowIndex++;
    }

    groups.add(SeatGroup(type: type, rows: rows));
  }

  return groups;
}
