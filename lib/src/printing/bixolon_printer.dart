import 'dart:io';

import 'package:flutter/services.dart';

class BluetoothPrinter {
  const BluetoothPrinter({required this.name, required this.address});
  final String name;
  final String address;
}

class ReceiptLine {
  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });
  final String name;
  final int quantity;
  final int unitPrice;
}

class ReceiptPayment {
  const ReceiptPayment({
    required this.invoiceNumber,
    required this.method,
    required this.total,
    required this.received,
    required this.change,
    this.customerPhone,
  });
  final String invoiceNumber;
  final String method;
  final int total;
  final int received;
  final int change;
  final String? customerPhone;
}

class BixolonPrinter {
  static const _channel = MethodChannel('com.kisimba.pos/bixolon');

  Future<List<BluetoothPrinter>> pairedPrinters() async {
    if (!Platform.isAndroid) return [];
    final permission = await _channel.invokeMethod<bool>('requestPermission');
    if (permission != true) {
      throw PlatformException(
        code: 'permission_denied',
        message: 'Autorisez Bluetooth dans les paramètres.',
      );
    }
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>(
          'pairedPrinters',
        ) ??
        [];
    return raw
        .map(
          (item) => BluetoothPrinter(
            name: item['name']! as String,
            address: item['address']! as String,
          ),
        )
        .toList();
  }

  Future<void> print({
    required BluetoothPrinter printer,
    required String shopName,
    required String shopAddress,
    required String sellerName,
    required List<ReceiptLine> lines,
    required ReceiptPayment payment,
  }) async {
    final receipt = _receipt(shopName, shopAddress, sellerName, lines, payment);
    await _channel.invokeMethod<void>('printReceipt', {
      'address': printer.address,
      'receipt': receipt,
    });
  }

  String _receipt(
    String shop,
    String address,
    String seller,
    List<ReceiptLine> lines,
    ReceiptPayment payment,
  ) {
    final now = DateTime.now();
    final buffer = StringBuffer()
      ..writeln('================================')
      ..writeln(_center(shop.toUpperCase()))
      ..writeln(_center(address))
      ..writeln(_center('FACTURE / RECU DE VENTE'))
      ..writeln('================================')
      ..writeln(
        '${_two(now.day)}/${_two(now.month)}/${now.year}  ${_two(now.hour)}:${_two(now.minute)}',
      )
      ..writeln('Facture: ${payment.invoiceNumber}')
      ..writeln('Vendeur: $seller')
      ..writeln('Client: ${payment.customerPhone ?? 'Comptoir'}')
      ..writeln('--------------------------------');
    for (final line in lines) {
      buffer
        ..writeln(line.name)
        ..writeln(
          '${line.quantity} x ${line.unitPrice} CDF     ${line.quantity * line.unitPrice} CDF',
        );
    }
    buffer
      ..writeln('--------------------------------')
      ..writeln('TOTAL: ${payment.total} CDF')
      ..writeln('Paiement: ${payment.method}')
      ..writeln('Recu: ${payment.received} CDF')
      ..writeln('Monnaie: ${payment.change} CDF')
      ..writeln('================================')
      ..writeln(_center('Merci pour votre achat !'));
    return buffer.toString();
  }

  String _center(String value) => value.length >= 32
      ? value.substring(0, 32)
      : '${' ' * ((32 - value.length) ~/ 2)}$value';
  String _two(int value) => value.toString().padLeft(2, '0');
}
