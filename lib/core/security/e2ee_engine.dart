/// Security-reviewed E2EE integration boundary for 143.
///
/// The application deliberately does not provide a homemade cryptographic
/// implementation. A production implementation must wrap a reviewed protocol
/// library (for example a Signal-protocol compatible implementation) and keep
/// private key material in platform-secure storage.
abstract interface class E2eeEngine {
  bool get available;
  String get implementationName;
  Future<E2eeProvisioningState> provisioningState();
  Future<void> provisionDevice();
  Future<List<int>> encryptText({required String peerUserId, required List<int> plaintext});
  Future<List<int>> decryptText({required String peerUserId, required List<int> ciphertext});
}

class E2eeProvisioningState {
  const E2eeProvisioningState({required this.ready, required this.detail});
  final bool ready;
  final String detail;
}

/// Safe default used until a reviewed crypto provider is integrated.
///
/// Every operation that could otherwise imply encryption fails closed rather
/// than returning plaintext or pretending encryption succeeded.
class SecurityReviewRequiredE2eeEngine implements E2eeEngine {
  const SecurityReviewRequiredE2eeEngine();

  @override
  bool get available => false;

  @override
  String get implementationName => 'SECURITY REVIEW REQUIRED';

  @override
  Future<E2eeProvisioningState> provisioningState() async => const E2eeProvisioningState(
        ready: false,
        detail: 'A reviewed E2EE protocol/library and secure private-key lifecycle have not been integrated.',
      );

  Never _blocked() => throw StateError(
        'E2EE operation blocked: integrate a reviewed protocol/library before encrypting private 143 content.',
      );

  @override
  Future<void> provisionDevice() async => _blocked();

  @override
  Future<List<int>> encryptText({required String peerUserId, required List<int> plaintext}) async => _blocked();

  @override
  Future<List<int>> decryptText({required String peerUserId, required List<int> ciphertext}) async => _blocked();
}
