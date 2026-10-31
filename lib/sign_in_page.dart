import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool isLogin = true;

  // Login controllers
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  // Email/password login (used for admin access, or any account
  // created directly in Firebase Console with email+password).
  bool useEmailLogin = false;
  final TextEditingController emailLoginController = TextEditingController();
  final TextEditingController passwordLoginController = TextEditingController();
  bool isEmailLoginLoading = false;
  bool _obscurePassword = true;

  // Sign Up controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController signUpMobileController = TextEditingController();
  final TextEditingController signUpOtpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL:
        'https://food-ordering-app-5c822-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // ==================== GOOGLE SIGN-IN ====================
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool isGoogleLoading = false;

  String? _verificationId;
  bool isOtpSent = false;
  bool isLoading = false;

  String? _signUpVerificationId;
  bool isSignUpOtpSent = false;
  bool isSignUpLoading = false;

  @override
  void dispose() {
    mobileController.dispose();
    otpController.dispose();
    emailLoginController.dispose();
    passwordLoginController.dispose();
    nameController.dispose();
    emailController.dispose();
    signUpMobileController.dispose();
    signUpOtpController.dispose();
    super.dispose();
  }

  // ==================== EMAIL/PASSWORD LOGIN ====================
  // Used for accounts created directly in Firebase Console (e.g. the
  // admin@gmail.com account) — no OTP involved, straight email+password.

  Future<void> signInWithEmailPassword() async {
    final email = emailLoginController.text.trim();
    final password = passwordLoginController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter a valid email');
      return;
    }
    if (password.isEmpty) {
      _showError('Enter your password');
      return;
    }

    setState(() => isEmailLoginLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('🟢 EMAIL LOGIN: success, uid=${_auth.currentUser?.uid}');
      if (!mounted) return;
      setState(() => isEmailLoginLoading = false);
      _showMessage('Login successful!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('🔴 EMAIL LOGIN: failed => ${e.code} | ${e.message}');
      setState(() => isEmailLoginLoading = false);
      _showError(e.message ?? 'Login failed. Check your email and password.');
    }
  }

  // ==================== LOGIN LOGIC ====================

  Future<void> sendOTP() async {
    final phone = mobileController.text.trim();
    debugPrint('🔵 LOGIN: sendOTP called with phone=$phone');

    if (phone.length != 10) {
      _showError('Enter a valid 10-digit mobile number');
      return;
    }

    setState(() => isLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('🔵 LOGIN: verificationCompleted (auto)');
        await _auth.signInWithCredential(credential);
        await _checkUserExistsAndLogin();
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('🔴 LOGIN: verificationFailed => ${e.code} | ${e.message}');
        setState(() => isLoading = false);
        _showError(e.message ?? 'Verification failed. Try again.');
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('🔵 LOGIN: codeSent, verificationId=$verificationId');
        setState(() {
          _verificationId = verificationId;
          isOtpSent = true;
          isLoading = false;
        });
        _showMessage('OTP sent to +91$phone');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('🔵 LOGIN: codeAutoRetrievalTimeout');
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifyOTP() async {
    final smsCode = otpController.text.trim();
    debugPrint('🔵 LOGIN: verifyOTP called with code=$smsCode');

    if (smsCode.length != 6 || _verificationId == null) {
      _showError('Enter the 6-digit OTP');
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      debugPrint('🟢 LOGIN: signInWithCredential success, uid=${_auth.currentUser?.uid}');
      await _checkUserExistsAndLogin();
    } on FirebaseAuthException catch (e) {
      debugPrint('🔴 LOGIN: verifyOTP failed => ${e.code} | ${e.message}');
      setState(() => isLoading = false);
      _showError(e.message ?? 'Invalid OTP. Try again.');
    }
  }

  Future<void> _checkUserExistsAndLogin() async {
    final user = _auth.currentUser;
    debugPrint('🔵 CHECK: current uid = ${user?.uid}');

    if (user == null) {
      setState(() => isLoading = false);
      _showError('Something went wrong. Try again.');
      return;
    }

    try {
      final ref = _database.ref('users/${user.uid}');
      debugPrint('🔵 CHECK: querying path = users/${user.uid}');

      final snapshot = await ref.get();
      debugPrint('🔵 CHECK: snapshot.exists = ${snapshot.exists}');
      debugPrint('🔵 CHECK: snapshot.value = ${snapshot.value}');

      if (snapshot.exists) {
        setState(() => isLoading = false);
        _showMessage('Login successful!');
        Navigator.pop(context);
      } else {
        debugPrint('🟠 CHECK: No record found -> signing out, blocking login');
        await _auth.signOut();
        setState(() {
          isLoading = false;
          isOtpSent = false;
          otpController.clear();
        });
        _showError('No account found. Please sign up first.');
      }
    } catch (e) {
      debugPrint('🔴 CHECK: Database read error => $e');
      setState(() => isLoading = false);
      _showError('Error checking account: $e');
    }
  }

  // ==================== SIGN UP LOGIC ====================

  Future<void> sendSignUpOTP() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = signUpMobileController.text.trim();

    debugPrint('🔵 SIGNUP: sendSignUpOTP -> name=$name, email=$email, phone=$phone');

    if (name.isEmpty) {
      _showError('Enter your full name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter a valid email');
      return;
    }
    if (phone.length != 10) {
      _showError('Enter a valid 10-digit mobile number');
      return;
    }

    setState(() => isSignUpLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('🔵 SIGNUP: verificationCompleted (auto)');
        await _auth.signInWithCredential(credential);
        await _saveNewUserAndFinish(name, email, phone);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('🔴 SIGNUP: verificationFailed => ${e.code} | ${e.message}');
        setState(() => isSignUpLoading = false);
        _showError(e.message ?? 'Verification failed. Try again.');
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('🔵 SIGNUP: codeSent, verificationId=$verificationId');
        setState(() {
          _signUpVerificationId = verificationId;
          isSignUpOtpSent = true;
          isSignUpLoading = false;
        });
        _showMessage('OTP sent to +91$phone');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('🔵 SIGNUP: codeAutoRetrievalTimeout');
        _signUpVerificationId = verificationId;
      },
    );
  }

  Future<void> verifySignUpOTP() async {
    final smsCode = signUpOtpController.text.trim();
    debugPrint('🔵 SIGNUP: verifySignUpOTP called with code=$smsCode');

    if (smsCode.length != 6 || _signUpVerificationId == null) {
      _showError('Enter the 6-digit OTP');
      return;
    }

    setState(() => isSignUpLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _signUpVerificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      debugPrint('🟢 SIGNUP: signInWithCredential success, uid=${_auth.currentUser?.uid}');

      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final phone = signUpMobileController.text.trim();

      await _saveNewUserAndFinish(name, email, phone);
    } on FirebaseAuthException catch (e) {
      debugPrint('🔴 SIGNUP: verifySignUpOTP failed => ${e.code} | ${e.message}');
      setState(() => isSignUpLoading = false);
      _showError(e.message ?? 'Invalid OTP. Try again.');
    }
  }

  Future<void> _saveNewUserAndFinish(
      String name, String email, String phone) async {
    final user = _auth.currentUser;
    debugPrint('🔵 SAVE: current uid = ${user?.uid}');

    if (user == null) {
      setState(() => isSignUpLoading = false);
      _showError('Something went wrong. Try again.');
      return;
    }

    try {
      final ref = _database.ref('users/${user.uid}');
      debugPrint('🔵 SAVE: writing to path = users/${user.uid}');

      await ref.set({
        'name': name,
        'email': email,
        'phone': '+91$phone',
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('🟢 SAVE: write successful');

      setState(() => isSignUpLoading = false);
      _showMessage('Account created successfully! You can now log in.');
      Navigator.pop(context);
    } catch (e) {
      debugPrint('🔴 SAVE: write failed => $e');
      setState(() => isSignUpLoading = false);
      _showError('Failed to save account: $e');
    }
  }

  // ==================== GOOGLE SIGN-IN LOGIC ====================

  Future<void> signInWithGoogle() async {
    debugPrint('🔵 GOOGLE: signInWithGoogle called');
    setState(() => isGoogleLoading = true);

    try {
      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in flow
        debugPrint('🟠 GOOGLE: sign-in cancelled by user');
        setState(() => isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      debugPrint('🟢 GOOGLE: signInWithCredential success, uid=${user?.uid}');

      if (user == null) {
        setState(() => isGoogleLoading = false);
        _showError('Google sign-in failed. Try again.');
        return;
      }

      await _handleGoogleUser(user);
    } on FirebaseAuthException catch (e) {
      debugPrint('🔴 GOOGLE: FirebaseAuthException => ${e.code} | ${e.message}');
      setState(() => isGoogleLoading = false);
      _showError(e.message ?? 'Google sign-in failed. Try again.');
    } catch (e) {
      debugPrint('🔴 GOOGLE: error => $e');
      setState(() => isGoogleLoading = false);
      _showError('Google sign-in error: $e');
    }
  }

  // Checks if a user record already exists for this Google account.
  // If not, creates one automatically using the Google profile info
  // (name/email are already verified by Google, so no OTP is needed).
  Future<void> _handleGoogleUser(User user) async {
    try {
      final ref = _database.ref('users/${user.uid}');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        debugPrint('🟢 GOOGLE: existing user found -> logging in');
        setState(() => isGoogleLoading = false);
        _showMessage('Login successful!');
        Navigator.pop(context);
      } else {
        debugPrint('🟠 GOOGLE: no existing record -> creating new user');
        await ref.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'createdAt': DateTime.now().toIso8601String(),
        });
        setState(() => isGoogleLoading = false);
        _showMessage('Account created with Google!');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('🔴 GOOGLE: database error => $e');
      setState(() => isGoogleLoading = false);
      _showError('Error checking account: $e');
    }
  }

  // ==================== LOGOUT LOGIC ====================

  bool isLoggingOut = false;

  Future<void> _logout() async {
    setState(() => isLoggingOut = true);
    try {
      // Sign out of Google too, if that's how they signed in — otherwise
      // the next "Continue with Google" tap silently reuses the same
      // account instead of showing the account picker.
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      debugPrint('🟢 LOGOUT: signed out');
      if (!mounted) return;
      _showMessage('Logged out successfully');
      Navigator.pop(context);
    } catch (e) {
      debugPrint('🔴 LOGOUT: failed => $e');
      setState(() => isLoggingOut = false);
      _showError('Failed to log out: $e');
    }
  }

  // ==================== ACCOUNT VIEW (signed in) ====================

  Widget _buildAccountDialog(User user) {
    final displayName = user.displayName?.trim();
    final initials = (displayName != null && displayName.isNotEmpty)
        ? displayName[0].toUpperCase()
        : (user.email?.isNotEmpty == true
            ? user.email![0].toUpperCase()
            : '?');

    return Dialog(
      backgroundColor: const Color(0xFFF7EDE3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepOrange.shade100,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                (displayName != null && displayName.isNotEmpty)
                    ? displayName
                    : 'Welcome back!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (user.email != null && user.email!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  user.email!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
              if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  user.phoneNumber!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isLoggingOut ? null : _logout,
                icon: isLoggingOut
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout, size: 18, color: Colors.white),
                label: Text(
                  isLoggingOut ? 'Logging out...' : 'Log Out',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: _buttonStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user != null) {
      return _buildAccountDialog(user);
    }

    return Dialog(
      backgroundColor: const Color(0xFFF7EDE3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Login or sign up to continue ordering',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildTab('Login', isLogin, () {
                    setState(() {
                      isLogin = true;
                      isOtpSent = false;
                    });
                  }),
                  const SizedBox(width: 24),
                  _buildTab('Sign Up', !isLogin, () {
                    setState(() {
                      isLogin = false;
                      isSignUpOtpSent = false;
                    });
                  }),
                ],
              ),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 20),
              if (isLogin) _buildLoginForm() else _buildSignUpForm(),
              const SizedBox(height: 20),
              _buildOrDivider(),
              const SizedBox(height: 16),
              _buildGoogleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.deepOrange : Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: label == 'Login' ? 44 : 60,
            color: selected ? Colors.deepOrange : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    if (useEmailLogin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailLoginController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordLoginController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration('Password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black45,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: isEmailLoginLoading ? null : signInWithEmailPassword,
            style: _buttonStyle(),
            child: isEmailLoginLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => useEmailLogin = false),
            child: const Text(
              'Login with mobile number instead',
              style: TextStyle(color: Colors.deepOrange),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: mobileController,
          keyboardType: TextInputType.phone,
          enabled: !isOtpSent,
          decoration: _inputDecoration('Mobile Number'),
        ),
        if (isOtpSent) ...[
          const SizedBox(height: 14),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _inputDecoration('Enter 6-digit OTP'),
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: isLoading ? null : (isOtpSent ? verifyOTP : sendOTP),
          style: _buttonStyle(),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  isOtpSent ? 'Verify OTP' : 'Send OTP',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
        if (isOtpSent) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    setState(() {
                      isOtpSent = false;
                      otpController.clear();
                    });
                  },
            child: const Text(
              'Change mobile number',
              style: TextStyle(color: Colors.deepOrange),
            ),
          ),
        ],
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => setState(() => useEmailLogin = true),
          child: const Text(
            'Login with email instead',
            style: TextStyle(color: Colors.deepOrange),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          enabled: !isSignUpOtpSent,
          decoration: _inputDecoration('Full Name'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !isSignUpOtpSent,
          decoration: _inputDecoration('Email'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: signUpMobileController,
          keyboardType: TextInputType.phone,
          enabled: !isSignUpOtpSent,
          decoration: _inputDecoration('Mobile Number'),
        ),
        if (isSignUpOtpSent) ...[
          const SizedBox(height: 14),
          TextField(
            controller: signUpOtpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _inputDecoration('Enter 6-digit OTP'),
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: isSignUpLoading
              ? null
              : (isSignUpOtpSent ? verifySignUpOTP : sendSignUpOTP),
          style: _buttonStyle(),
          child: isSignUpLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  isSignUpOtpSent ? 'Verify & Create Account' : 'Send OTP',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
        if (isSignUpOtpSent) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: isSignUpLoading
                ? null
                : () {
                    setState(() {
                      isSignUpOtpSent = false;
                      signUpOtpController.clear();
                    });
                  },
            child: const Text(
              'Edit details',
              style: TextStyle(color: Colors.deepOrange),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(thickness: 1, color: Colors.black26)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(thickness: 1, color: Colors.black26)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: isGoogleLoading ? null : signInWithGoogle,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        backgroundColor: Colors.white,
      ),
      child: isGoogleLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.deepOrange,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                // Requires an asset at assets/google_logo.png,
                // or swap for Icon(Icons.g_mobiledata, size: 24) if you
                // don't want to add an asset.
                Icon(Icons.login, size: 20, color: Colors.black87),
                SizedBox(width: 10),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7EDE3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.deepOrange),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.deepOrange,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation:0
      );
  }
  
}