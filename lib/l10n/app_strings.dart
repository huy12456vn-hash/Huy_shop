import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
/// Notifier ngôn ngữ toàn app - đặt ở đây để mọi widget nghe được
class LocaleController {
  LocaleController._();
  static const String languageKey = 'account_language';
  static final ValueNotifier<Locale> locale =
      ValueNotifier<Locale>(const Locale('en'));

  static void setLanguage(String languageLabel) {
    locale.value =
        languageLabel == 'Tiếng Việt' ? const Locale('vi') : const Locale('en');
  }

  static String labelFor(Locale l) => l.languageCode == 'vi' ? 'Tiếng Việt' : 'English';
  static Future<void> loadSavedLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(languageKey) ?? 'English';
    setLanguage(savedLanguage);
  }
}

/// Bảng dịch chuỗi dùng trong AccountPage (mở rộng thêm cho các màn khác nếu cần)
class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    return AppStrings(LocaleController.locale.value);
  }
  bool get _isVi => locale.languageCode == 'vi';
String formatPrice(dynamic value) {
  final input = value?.toString() ?? '0';
  final normalized = input.replaceAll(RegExp(r'[^0-9,.-]'), '');
  final num parsed = normalized.isEmpty
      ? 0
      : num.tryParse(normalized.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  if (_isVi) {
    final int whole = parsed.round();
    final String digits = whole.toString();
    final buffer = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      final positionFromRight = digits.length - index;
      buffer.write(digits[index]);

      if (positionFromRight > 1 && positionFromRight % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()}đ';
  } else {
    final double usdAmount = parsed / 26300;
    final int cents = (usdAmount * 100).round();
    final int whole = cents ~/ 100;
    final String fraction = (cents % 100).abs().toString().padLeft(2, '0');
    final String digits = whole.toString();
    final buffer = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      final positionFromRight = digits.length - index;
      buffer.write(digits[index]);

      if (positionFromRight > 1 && positionFromRight % 3 == 1) {
        buffer.write(',');
      }
    }

    return '\$${buffer.toString()}.$fraction';
  }
}
  String get myAccount => _isVi ? 'TÀI KHOẢN CỦA TÔI' : 'MY ACCOUNT';
  String get settings => _isVi ? 'CÀI ĐẶT' : 'SETTINGS';

  String get myOrders => _isVi ? 'Đơn hàng của tôi' : 'My Orders';
  String get myOrdersSubtitle =>
      _isVi ? 'Xem lịch sử và trạng thái đơn hàng' : 'View order history and order status';

  String get deliveryAddress => _isVi ? 'Địa chỉ giao hàng' : 'Delivery Address';
  String get addDeliveryAddress => _isVi ? 'Thêm địa chỉ giao hàng' : 'Add your delivery address';

  String get personalInfo => _isVi ? 'Thông tin cá nhân' : 'Personal Information';
  String get personalInfoSubtitle =>
      _isVi ? 'Cập nhật họ tên và số điện thoại' : 'Update your name and phone number';

  String get accountSettings => _isVi ? 'Cài đặt tài khoản' : 'Account Settings';
  String get accountSettingsSubtitle =>
      _isVi ? 'Bảo mật và tùy chọn tài khoản' : 'Security and account preferences';

  String get language => _isVi ? 'Ngôn ngữ' : 'Language';

  String get helpSupport => _isVi ? 'Trợ giúp & Hỗ trợ' : 'Help & Support';
  String get helpSupportSubtitle =>
      _isVi ? 'Hỗ trợ và các câu hỏi thường gặp' : 'Support and frequently asked questions';

  String get logout => _isVi ? 'Đăng xuất' : 'Log out';
  String get logoutTitle => _isVi ? 'Đăng xuất' : 'Log out';
  String get logoutConfirm => _isVi
      ? 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'
      : 'Are you sure you want to log out of your account?';
  String get cancel => _isVi ? 'Hủy' : 'Cancel';

  String get signedIn => _isVi ? 'Đã đăng nhập' : 'Signed in';

  String get changePassword => _isVi ? 'Đổi mật khẩu' : 'Change password';
  String get changePasswordSubtitle => _isVi
      ? 'Nhận liên kết đặt lại mật khẩu qua email'
      : 'Receive a password reset link by email';
  String get accountEmail => _isVi ? 'Email tài khoản' : 'Account email';
  String get noEmail => _isVi ? 'Không có email' : 'No email';

  String get languageChangedTo => _isVi ? 'Đã đổi ngôn ngữ sang' : 'Language changed to';

  String get personalInfoUpdated =>
      _isVi ? 'Cập nhật thông tin cá nhân thành công.' : 'Personal information updated successfully.';
  String get deliveryAddressSaved =>
      _isVi ? 'Lưu địa chỉ giao hàng thành công.' : 'Delivery address saved successfully.';

  // ---- Login screen ----
  String get welcomeBack => _isVi ? 'Chào mừng trở lại' : 'Welcome Back';
  String get signInSubtitle => _isVi
      ? 'Đăng nhập để tiếp tục trải nghiệm mua sắm cao cấp'
      : 'Sign in to continue your luxury shopping experience';
  String get emailHint => _isVi ? 'Email' : 'Email';
  String get passwordHint => _isVi ? 'Mật khẩu' : 'Password';
  String get rememberMe => _isVi ? 'Ghi nhớ đăng nhập' : 'Remember me';
  String get forgotPassword => _isVi ? 'Quên mật khẩu?' : 'Forgot Password?';
  String get loginButton => _isVi ? 'ĐĂNG NHẬP' : 'LOGIN';
  String get orDivider => _isVi ? 'HOẶC' : 'OR';
  String get continueWithGoogle => _isVi ? 'Tiếp tục với Google' : 'Continue with Google';
  String get continueWithApple => _isVi ? 'Tiếp tục với Apple' : 'Continue with Apple';
  String get noAccountYet => _isVi ? 'Chưa có tài khoản?' : "Don't have an account?";
  String get registerLink => _isVi ? 'Đăng ký' : 'Register';

  String get enterEmailPassword =>
      _isVi ? 'Vui lòng nhập email và mật khẩu' : 'Please enter both your email and password';
  String get userNotFound => _isVi ? 'Không tìm thấy tài khoản với email này' : 'No account was found for this email';
  String get wrongPassword => _isVi ? 'Sai mật khẩu' : 'Incorrect password';
  String get invalidEmail => _isVi ? 'Địa chỉ email không hợp lệ' : 'Invalid email address';
  String get invalidCredential =>
      _isVi ? 'Email hoặc mật khẩu không đúng' : 'The email or password is incorrect';
  String get loginFailed => _isVi ? 'Đăng nhập thất bại' : 'Login failed';
  String get errorOccurred => _isVi ? 'Đã xảy ra lỗi' : 'An error occurred';
  // ---- Forgot password screen ----
String get forgotPasswordTitle => _isVi ? 'Quên mật khẩu' : 'Forgot Password';
String get resetYourPassword => _isVi ? 'Đặt lại mật khẩu' : 'Reset your password';
String get resetPasswordSubtitle => _isVi
    ? 'Nhập địa chỉ email của bạn và chúng tôi sẽ gửi liên kết đặt lại mật khẩu.'
    : "Enter your email address and we'll send you a password reset link.";
String get pleaseEnterEmail => _isVi ? 'Vui lòng nhập email của bạn' : 'Please enter your email';
String get resetLinkSent =>
    _isVi ? 'Email đặt lại mật khẩu đã được gửi.' : 'Password reset email has been sent.';
String get sendResetLink => _isVi ? 'GỬI LIÊN KẾT ĐẶT LẠI' : 'SEND RESET LINK';
// ---- Register screen ----
String get createLuxuryAccount => _isVi ? 'Tạo tài khoản cao cấp của bạn' : 'Create Your Luxury Account';
String get fullNameHint => _isVi ? 'Họ và tên' : 'Full Name';
String get phoneNumberHint => _isVi ? 'Số điện thoại' : 'Phone Number';
String get confirmPasswordHint => _isVi ? 'Xác nhận mật khẩu' : 'Confirm Password';
String get agreeTermsText => _isVi ? 'Tôi đồng ý với Điều khoản & Điều kiện' : 'I agree to the Terms & Conditions';
String get createAccountButton => _isVi ? 'TẠO TÀI KHOẢN' : 'CREATE ACCOUNT';
String get alreadyHaveAccount => _isVi ? 'Đã có tài khoản? Đăng nhập' : 'Already have an account? Log in';

String get fillRequiredInfo => _isVi ? 'Vui lòng điền đầy đủ thông tin bắt buộc' : 'Please fill in all required information';
String get passwordsDoNotMatch => _isVi ? 'Mật khẩu không khớp' : 'Passwords do not match';
String get mustAgreeTerms => _isVi ? 'Bạn phải đồng ý với Điều khoản & Điều kiện' : 'You must agree to the Terms & Conditions';
String get emailAlreadyInUse => _isVi ? 'Email này đã được sử dụng' : 'This email is already in use';
String get weakPassword => _isVi ? 'Mật khẩu quá yếu' : 'Password is too weak';
String get registrationFailed => _isVi ? 'Đăng ký thất bại' : 'Registration failed';
// ---- Welcome screen ----
String get luxuryTagline => _isVi ? 'Bộ Sưu Tập Thời Trang Cao Cấp' : 'Luxury Fashion Collection';
String get exploreButton => _isVi ? 'KHÁM PHÁ' : 'EXPLORE';
// ---- Category page ----
String get signInToWishlist => _isVi ? 'Vui lòng đăng nhập để dùng danh sách yêu thích.' : 'Please sign in to use the wishlist.';
String get removedFromWishlist => _isVi ? 'Đã xóa khỏi danh sách yêu thích.' : 'Removed from wishlist.';
String get addedToWishlist => _isVi ? 'Đã thêm vào danh sách yêu thích.' : 'Added to wishlist.';
String unableToUpdateWishlist(String error) =>
    _isVi ? 'Không thể cập nhật danh sách yêu thích: $error' : 'Unable to update wishlist: $error';
String addedToCartMessage(String name) =>
    _isVi ? '$name đã được thêm vào giỏ hàng.' : '$name was added to your cart.';
String get unableToLoadCategories => _isVi ? 'Không thể tải danh mục' : 'Unable to load categories';
String get allCategoriesLabel => _isVi ? 'Tất cả' : 'All';
String unableToLoadProducts(String error) =>
    _isVi ? 'Không thể tải sản phẩm.\n$error' : 'Unable to load products.\n$error';
String get noProductsInCategory =>
    _isVi ? 'Không tìm thấy sản phẩm nào trong danh mục này.' : 'No products were found in this category.';
  // ---- Cart page ----
String get shoppingCartTitle => _isVi ? 'GIỎ HÀNG' : 'SHOPPING CART';
String get clearEntireCart => _isVi ? 'Xóa toàn bộ giỏ hàng' : 'Clear entire cart';
String get clearCartTitle => _isVi ? 'Xóa toàn bộ giỏ hàng?' : 'Clear the entire shopping cart?';
String get clearCartContent =>
    _isVi ? 'Tất cả sản phẩm trong giỏ hàng sẽ bị xóa.' : 'All products in the cart will be removed..';
String get clear => _isVi ? 'Xóa' : 'Clear';
String get allProductsRemoved =>
    _isVi ? 'Tất cả sản phẩm đã được xóa khỏi giỏ hàng.' : 'All products have been removed from the cart.';
String get removeProductTitle => _isVi ? 'Xóa sản phẩm?' : 'Remove product?';
String removeProductContent(String name) =>
    _isVi ? 'Bạn có chắc chắn muốn xóa "$name" khỏi giỏ hàng?' : 'Are you sure you want to remove "$name" from the cart?';
String get remove => _isVi ? 'Xóa' : 'Remove';
String get productRemoved => _isVi ? 'Đã xóa sản phẩm khỏi giỏ hàng.' : 'Product removed from cart.';
String get noOtherSizes => _isVi ? 'Sản phẩm này không có kích cỡ khác.' : 'This product has no other sizes.';
String get selectSize => _isVi ? 'Chọn kích cỡ' : 'Select size';
String get cartIsEmpty => _isVi ? 'Giỏ hàng đang trống.' : 'The shopping cart is empty.';
String get emptyCartTitle => _isVi ? 'Giỏ hàng trống' : 'Shopping Cart is Empty';
String get emptyCartSubtitle =>
    _isVi ? 'Thêm sản phẩm yêu thích của bạn vào giỏ hàng.' : 'Add your favorite products to the cart.';
String get continueShopping => _isVi ? 'Tiếp tục mua sắm' : 'Continue Shopping';
String get removeItemTooltip => _isVi ? 'Xóa sản phẩm' : 'Remove item';
String sizeLabel(String size) => _isVi ? 'Cỡ: $size' : 'Size: $size';
String totalItemsLabel(int count) => _isVi ? 'Tổng $count sản phẩm' : 'Total $count items';
String get totalLabel => _isVi ? 'Thành tiền:' : 'Total:';
String get checkoutButton => _isVi ? 'Thanh toán' : 'Checkout';
String get chatSupportTitle => _isVi ? 'Hỗ trợ chat Gucci' : 'Gucci Chat Support';
// ---- Checkout page ----
String get checkoutTitle => _isVi ? 'THANH TOÁN' : 'CHECKOUT';
String get deliveryInfoSection => _isVi ? 'THÔNG TIN GIAO HÀNG' : 'DELIVERY INFORMATION';
String get orderItemsSection => _isVi ? 'SẢN PHẨM ĐẶT MUA' : 'ORDER ITEMS';
String get paymentMethodSection => _isVi ? 'PHƯƠNG THỨC THANH TOÁN' : 'PAYMENT METHOD';
String get voucherSection => _isVi ? 'MÃ GIẢM GIÁ' : 'VOUCHER';
String get orderSummarySection => _isVi ? 'TÓM TẮT ĐƠN HÀNG' : 'ORDER SUMMARY';

String get fullNameLabel => _isVi ? 'Họ và tên' : 'Full name';
String get phoneNumberLabel => _isVi ? 'Số điện thoại' : 'Phone number';
String get deliveryAddressLabel => _isVi ? 'Địa chỉ giao hàng' : 'Delivery address';
String pleaseEnterField(String label) => _isVi ? 'Vui lòng nhập $label.' : 'Please enter $label.';

String get cashOnDelivery => _isVi ? 'Thanh toán khi nhận hàng' : 'Cash on Delivery';
String get bankTransfer => _isVi ? 'Chuyển khoản ngân hàng' : 'Bank Transfer';
String get eWallet => _isVi ? 'Ví điện tử' : 'E-Wallet';

String get voucherHint => _isVi ? 'GUCCI10 hoặc FREESHIP' : 'GUCCI10 or FREESHIP';
String get applyButton => _isVi ? 'Áp dụng' : 'Apply';
String get voucherApplied => _isVi ? 'Áp dụng mã giảm giá thành công.' : 'Voucher applied successfully.';
String get voucherInvalid => _isVi ? 'Mã giảm giá không hợp lệ.' : 'Invalid voucher code.';

String get subtotalLabel => _isVi ? 'Tạm tính' : 'Subtotal';
String get shippingFeeLabel => _isVi ? 'Phí vận chuyển' : 'Shipping fee';
String get discountLabel => _isVi ? 'Giảm giá' : 'Discount';
String get totalSummaryLabel => _isVi ? 'Tổng cộng' : 'Total';
String quantityLabel(int qty) => _isVi ? 'Số lượng: $qty' : 'Quantity: $qty';

String get cartEmptyForCheckout => _isVi ? 'Giỏ hàng của bạn đang trống.' : 'Your cart is empty.';
String get signInBeforeOrder => _isVi ? 'Vui lòng đăng nhập trước khi đặt hàng.' : 'Please sign in before placing an order.';
String unableToPlaceOrder(String error) =>
    _isVi ? 'Không thể đặt hàng: $error' : 'Unable to place order: $error';

String get orderPlacedTitle => _isVi ? 'Đặt hàng thành công' : 'Order Placed';
String orderPlacedContent(String orderCode) => _isVi
    ? 'Đơn hàng của bạn đã được đặt thành công.\n\nMã đơn #$orderCode'
    : 'Your order has been placed successfully.\n\nOrder #$orderCode';
String get viewMyOrders => _isVi ? 'Xem đơn hàng của tôi' : 'View My Orders';
String placeOrderButton(String price) => _isVi ? 'Đặt hàng • $price' : 'Place Order • $price';
// ---- Home page ----
String get featuredCategories => _isVi ? 'DANH MỤC NỔI BẬT' : 'FEATURED CATEGORIES';
String get newArrivals => _isVi ? 'HÀNG MỚI VỀ' : 'NEW ARRIVALS';
String get allProducts => _isVi ? 'TẤT CẢ SẢN PHẨM' : 'ALL PRODUCTS';
String get viewAll => _isVi ? 'Xem tất cả' : 'View all';
String get categoryPageTitle => _isVi ? 'DANH MỤC' : 'CATEGORY';
String get noCategoriesYet => _isVi ? 'Chưa có danh mục' : 'No categories yet';
String get noProducts => _isVi ? 'Chưa có sản phẩm' : 'No products';
String get noProductsYet => _isVi ? 'Chưa có sản phẩm nào.' : 'No products yet.';
String get unableToLoadProductsShort => _isVi ? 'Không thể tải sản phẩm' : 'Unable to load products';

String get signInToWishlistShort => _isVi ? 'Vui lòng đăng nhập để dùng Wishlist.' : 'Please sign in to use Wishlist.';
String get itemRemovedFromWishlist => _isVi ? 'Đã xóa khỏi Wishlist.' : 'Item removed from Wishlist.';
String get itemAddedToWishlist => _isVi ? 'Đã thêm vào Wishlist.' : 'Item added to Wishlist.';
String unableToUpdateWishlistShort(String error) =>
    _isVi ? 'Không thể cập nhật Wishlist: $error' : 'Unable to update Wishlist: $error';
String get removeFromWishlistTooltip => _isVi ? 'Xóa khỏi Wishlist' : 'Remove from Wishlist';
String get addToWishlistTooltip => _isVi ? 'Thêm vào Wishlist' : 'Add to Wishlist';
String addedToCartHome(String name) =>
    _isVi ? '$name đã được thêm vào giỏ hàng.' : '$name has been added to the cart.';
    // ---- Order history page ----
String get myOrdersTitle => _isVi ? 'ĐƠN HÀNG CỦA TÔI' : 'MY ORDERS';
String get signInRequired => _isVi ? 'Yêu cầu đăng nhập' : 'Sign in required';
String get signInToViewOrders => _isVi ? 'Vui lòng đăng nhập để xem đơn hàng của bạn.' : 'Please sign in to view your orders.';
String get unableToLoadOrders => _isVi ? 'Không thể tải đơn hàng' : 'Unable to load orders';
String get noOrdersYet => _isVi ? 'Chưa có đơn hàng' : 'No orders yet';
String get completedPurchasesAppearHere => _isVi ? 'Các đơn hàng đã hoàn thành sẽ hiển thị ở đây.' : 'Your completed purchases will appear here.';
String get statusConfirmed => _isVi ? 'Đã xác nhận' : 'Confirmed';
String get statusShipping => _isVi ? 'Đang giao' : 'Shipping';
String get statusCompleted => _isVi ? 'Hoàn thành' : 'Completed';
String get statusCancelled => _isVi ? 'Đã hủy' : 'Cancelled';
String get statusPending => _isVi ? 'Chờ xử lý' : 'Pending';
String orderNumberLabel(String id) => _isVi ? 'Đơn hàng #$id' : 'Order #$id';
String moreProductsLabel(int count) =>
    _isVi ? '+ $count sản phẩm khác' : '+ $count more product${count > 1 ? 's' : ''}';
String orderItemsCount(int count) => _isVi ? '$count sản phẩm' : '$count item${count == 1 ? '' : 's'}';
String get orderTotalPrefix => _isVi ? 'Tổng: ' : 'Total: ';
String get defaultProductName => _isVi ? 'Sản phẩm' : 'Product';
String get orderDetailsTitle => _isVi ? 'Chi tiết đơn hàng' : 'Order Details';
String get orderIdLabel => _isVi ? 'Mã đơn hàng' : 'Order ID';
String get orderDateLabel => _isVi ? 'Ngày đặt hàng' : 'Order date';
String get statusFieldLabel => _isVi ? 'Trạng thái' : 'Status';
String get productsLabel => _isVi ? 'Sản phẩm' : 'Products';
String get orderTotalLabel => _isVi ? 'Tổng đơn hàng' : 'Order total';
String quantityShortLabel(int qty) => _isVi ? 'Số lượng: $qty' : 'Quantity: $qty';
// ---- Product detail page ----
String get reviewsCount => _isVi ? '128 đánh giá' : '128 reviews';
String get freeDelivery => _isVi ? 'Miễn phí vận chuyển' : 'Free delivery';
String get authenticProduct => _isVi ? 'Hàng chính hãng' : 'Authentic product';
String get sizeSectionTitle => _isVi ? 'Kích cỡ' : 'Size';
String get colorSectionTitle => _isVi ? 'Màu sắc' : 'Color';
String get productDescriptionTitle => _isVi ? 'Mô tả sản phẩm' : 'Product Description';
String get noDescriptionAvailable =>
    _isVi ? 'Sản phẩm này chưa có mô tả.' : 'No description is available for this product.';
String get addToCartButton => _isVi ? 'Thêm vào giỏ' : 'Add to Cart';
String get buyNowButton => _isVi ? 'Mua ngay' : 'Buy Now';
String get shareComingSoon =>
    _isVi ? 'Tính năng chia sẻ sẽ có trong bản cập nhật tiếp theo.' : 'Share feature is ready for the next step.';
String addedToCartWithOptions(String name, String size, String color) => _isVi
    ? '$name ($size, $color) đã được thêm vào giỏ hàng.'
    : '$name ($size, $color) was added to your cart.';
String get colorBrown => _isVi ? 'Nâu' : 'Brown';
String get colorBlack => _isVi ? 'Đen' : 'Black';
String get colorWhite => _isVi ? 'Trắng' : 'White';
String get colorBlue => _isVi ? 'Xanh dương' : 'Blue';
// ---- Search page ----
String get searchProductsHint => _isVi ? 'Tìm kiếm sản phẩm...' : 'Search products...';
String get enterKeywordToSearch =>
    _isVi ? 'Nhập từ khóa để tìm kiếm sản phẩm' : 'Enter a keyword to search products';
String get noProductsFound => _isVi ? 'Không tìm thấy sản phẩm nào' : 'No products found';
// ---- Wishlist page ----
String get notSignedInTitle => _isVi ? 'Bạn chưa đăng nhập' : 'You are not signed in';
String get signInToViewFavorites =>
    _isVi ? 'Vui lòng đăng nhập để xem sản phẩm yêu thích của bạn.' : 'Please sign in to view your favorite products.';
String unableToLoadWishlist(String error) =>
    _isVi ? 'Không thể tải Wishlist.\n$error' : 'Unable to load wishlist.\n$error';
String get itemRemovedFromWishlistShort => _isVi ? 'Đã xóa sản phẩm khỏi Wishlist' : 'Item removed from wishlist';
String unableToRemoveItem(String error) =>
    _isVi ? 'Không thể xóa sản phẩm: $error' : 'Unable to remove item: $error';
String get wishlistEmptyTitle => _isVi ? 'Wishlist của bạn đang trống' : 'Your wishlist is empty';
String get wishlistEmptySubtitle =>
    _isVi ? 'Chạm vào biểu tượng trái tim để lưu sản phẩm yêu thích.' : 'Tap the heart icon to save your favorite products.';
String get untitledProduct => _isVi ? 'Chưa có tên' : 'Untitled';
// ---- Main page (bottom nav) ----
String get navTitleCategory => _isVi ? 'DANH MỤC' : 'Category';
String get navTitleWishlist => _isVi ? 'YÊU THÍCH' : 'Wishlist';
String get navTitleAccount => _isVi ? 'TÀI KHOẢN' : 'Account';
String get supportChatTooltip => _isVi ? 'Hỗ trợ trò chuyện' : 'Support Chat';
// ---- Bottom navigation labels ----
String get navHome => _isVi ? 'Trang chủ' : 'Home';
String get navCategory => _isVi ? 'Danh mục' : 'Category';
String get navWishlist => _isVi ? 'Yêu thích' : 'Wishlist';
String get navAccount => _isVi ? 'Tài khoản' : 'Account';
// ---- Admin service ----
String get authenticationFailed => _isVi ? 'Xác thực thất bại.' : 'Authentication failed.';
String get notAnAdministrator => _isVi ? 'Bạn không phải là quản trị viên.' : 'You are not an administrator.';
String get noAccountFoundEmail =>
    _isVi ? 'Không tìm thấy tài khoản với email này.' : 'No account found with this email.';
String get incorrectPassword => _isVi ? 'Sai mật khẩu.' : 'Incorrect password.';
String get invalidEmailAddress => _isVi ? 'Địa chỉ email không hợp lệ.' : 'Invalid email address.';
String get incorrectEmailOrPassword =>
    _isVi ? 'Email hoặc mật khẩu không đúng.' : 'Incorrect email or password.';
String get adminSignInFailed => _isVi ? 'Đăng nhập quản trị thất bại.' : 'Admin sign in failed.';
String errorOccurredWith(String error) =>
    _isVi ? 'Đã xảy ra lỗi: $error' : 'An error occurred: $error';
}