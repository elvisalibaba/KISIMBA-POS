String? normalizeCongolesePhone(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = '243${digits.substring(1)}';
  if (!digits.startsWith('243') && digits.length == 9) digits = '243$digits';
  if (!RegExp(r'^243[0-9]{9}$').hasMatch(digits)) return null;
  return '+$digits';
}
