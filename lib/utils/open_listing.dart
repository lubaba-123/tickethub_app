import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/listing_model.dart';
import '../screens/customer/seat_selection_screen.dart';
import '../screens/customer/ticket_selection_screen.dart';

void openListing(BuildContext context, Listing listing) {
  final types = ticketTypesForListing(listing.id);
  if (types.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tickets are not available for this listing yet.')),
    );
    return;
  }

  final Widget page = listing.requiresSeatSelection
      ? SeatSelectionScreen(listing: listing, ticketTypes: types)
      : TicketSelectionScreen(listing: listing, ticketTypes: types);

  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
