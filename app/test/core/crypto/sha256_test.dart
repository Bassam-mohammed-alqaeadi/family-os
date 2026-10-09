import 'dart:convert';
import 'dart:typed_data';

import 'package:family_os/core/crypto/sha256.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sha256 against published vectors', () {
    test('empty message (FIPS 180-4)', () {
      expect(
        sha256Hex(const <int>[]),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('abc (FIPS 180-4)', () {
      expect(
        sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('56-byte message that needs a second block (FIPS 180-4)', () {
      expect(
        sha256Hex(
          utf8.encode('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
        ),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('1000 bytes of "a" spans several blocks', () {
      expect(
        sha256Hex(List<int>.filled(1000, 0x61)),
        '41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3',
      );
    });

    test('1024-byte counting pattern', () {
      final bytes = Uint8List.fromList(<int>[for (var i = 0; i < 1024; i++) i & 0xff]);
      expect(
        sha256Hex(bytes),
        '785b0751fc2c53dc14a4ce3d800e69ef9ce1009eb327ccf458afe09c242c26c9',
      );
    });
  });

  test('the digest is 32 bytes and the hex form is lowercase', () {
    final digest = sha256Digest(utf8.encode('family'));
    expect(digest, hasLength(32));
    expect(sha256Hex(utf8.encode('family')), digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
    expect(sha256Hex(utf8.encode('family')), matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('a single changed byte changes the digest', () {
    expect(sha256Hex(utf8.encode('voice-a')), isNot(sha256Hex(utf8.encode('voice-b'))));
  });
}
