import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Spacing System (8pt grid)
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  static const double spacing72 = 72.0;
  static const double spacing80 = 80.0;
  static const double spacing96 = 96.0;

  // Padding
  static const EdgeInsets paddingNone = EdgeInsets.zero;
  static const EdgeInsets paddingXS = EdgeInsets.all(spacing4);
  static const EdgeInsets paddingS = EdgeInsets.all(spacing8);
  static const EdgeInsets paddingM = EdgeInsets.all(spacing16);
  static const EdgeInsets paddingL = EdgeInsets.all(spacing24);
  static const EdgeInsets paddingXL = EdgeInsets.all(spacing32);
  static const EdgeInsets paddingXXL = EdgeInsets.all(spacing48);

  // Horizontal Padding
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(
    horizontal: spacing8,
  );
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(
    horizontal: spacing16,
  );
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(
    horizontal: spacing24,
  );
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(
    horizontal: spacing32,
  );

  // Vertical Padding
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(
    vertical: spacing8,
  );
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(
    vertical: spacing16,
  );
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(
    vertical: spacing24,
  );
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(
    vertical: spacing32,
  );

  // Margin
  static const EdgeInsets marginNone = EdgeInsets.zero;
  static const EdgeInsets marginXS = EdgeInsets.all(spacing4);
  static const EdgeInsets marginS = EdgeInsets.all(spacing8);
  static const EdgeInsets marginM = EdgeInsets.all(spacing16);
  static const EdgeInsets marginL = EdgeInsets.all(spacing24);
  static const EdgeInsets marginXL = EdgeInsets.all(spacing32);
  static const EdgeInsets marginXXL = EdgeInsets.all(spacing48);

  // Horizontal Margin
  static const EdgeInsets marginHorizontalS = EdgeInsets.symmetric(
    horizontal: spacing8,
  );
  static const EdgeInsets marginHorizontalM = EdgeInsets.symmetric(
    horizontal: spacing16,
  );
  static const EdgeInsets marginHorizontalL = EdgeInsets.symmetric(
    horizontal: spacing24,
  );
  static const EdgeInsets marginHorizontalXL = EdgeInsets.symmetric(
    horizontal: spacing32,
  );

  // Vertical Margin
  static const EdgeInsets marginVerticalS = EdgeInsets.symmetric(
    vertical: spacing8,
  );
  static const EdgeInsets marginVerticalM = EdgeInsets.symmetric(
    vertical: spacing16,
  );
  static const EdgeInsets marginVerticalL = EdgeInsets.symmetric(
    vertical: spacing24,
  );
  static const EdgeInsets marginVerticalXL = EdgeInsets.symmetric(
    vertical: spacing32,
  );

  // Border Radius
  static const double radiusNone = 0.0;
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;
  static const double radiusCircle = 50.0;

  // Border Radius Values
  static const Radius radiusValueNone = Radius.circular(radiusNone);
  static const Radius radiusValueXS = Radius.circular(radiusXS);
  static const Radius radiusValueS = Radius.circular(radiusS);
  static const Radius radiusValueM = Radius.circular(radiusM);
  static const Radius radiusValueL = Radius.circular(radiusL);
  static const Radius radiusValueXL = Radius.circular(radiusXL);
  static const Radius radiusValueXXL = Radius.circular(radiusXXL);
  static const Radius radiusValueCircle = Radius.circular(radiusCircle);

  // BorderRadius
  static const BorderRadius borderRadiusNone = BorderRadius.all(
    radiusValueNone,
  );
  static const BorderRadius borderRadiusXS = BorderRadius.all(radiusValueXS);
  static const BorderRadius borderRadiusS = BorderRadius.all(radiusValueS);
  static const BorderRadius borderRadiusM = BorderRadius.all(radiusValueM);
  static const BorderRadius borderRadiusL = BorderRadius.all(radiusValueL);
  static const BorderRadius borderRadiusXL = BorderRadius.all(radiusValueXL);
  static const BorderRadius borderRadiusXXL = BorderRadius.all(radiusValueXXL);
  static const BorderRadius borderRadiusCircle = BorderRadius.all(
    radiusValueCircle,
  );

  // Icon Sizes
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
  static const double iconSizeXXL = 64.0;

  // Button Sizes
  static const double buttonHeightS = 32.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;
  static const double buttonHeightXL = 64.0;

  static const double buttonWidthS = 80.0;
  static const double buttonWidthM = 120.0;
  static const double buttonWidthL = 160.0;
  static const double buttonWidthXL = 200.0;

  // Image Sizes
  static const double imageThumbSize = 64.0;
  static const double imageSmallSize = 80.0;
  static const double imageMediumSize = 120.0;
  static const double imageLargeSize = 200.0;
  static const double imageXLargeSize = 300.0;

  // Card Sizes
  static const double cardMinHeight = 120.0;
  static const double cardMediumHeight = 160.0;
  static const double cardLargeHeight = 200.0;
  static const double cardXLargeHeight = 300.0;

  // Avatar Sizes
  static const double avatarSizeXS = 24.0;
  static const double avatarSizeS = 32.0;
  static const double avatarSizeM = 40.0;
  static const double avatarSizeL = 48.0;
  static const double avatarSizeXL = 64.0;
  static const double avatarSizeXXL = 80.0;

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationXS = 1.0;
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 12.0;
  static const double elevationXXL = 16.0;

  // Border Width
  static const double borderWidthNone = 0.0;
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 2.0;
  static const double borderWidthThick = 3.0;
  static const double borderWidthExtraThick = 4.0;

  // AppBar
  static const double appBarHeight = 56.0;
  static const double appBarElevation = elevationS;

  // Bottom Navigation
  static const double bottomNavHeight = 64.0;
  static const double bottomNavElevation = elevationM;

  // Drawer
  static const double drawerWidth = 280.0;

  // Menu özel boyutlar
  static const double menuItemHeight = 80.0;
  static const double menuItemImageSize = 64.0;
  static const double categoryItemHeight = 60.0;
  static const double categoryIconSize = 40.0;

  // Product Card
  static const double productCardHeight = 120.0;
  static const double productCardWidth = double.infinity;
  static const double productImageSize = 80.0;
  static const double productImageBorderRadius = radiusM;

  // Category Card
  static const double categoryCardHeight = 100.0;
  static const double categoryCardWidth = double.infinity;
  static const double categoryImageSize = 60.0;
  static const double categoryImageBorderRadius = radiusL;

  // Business Card
  static const double businessCardHeight = 200.0;
  static const double businessLogoSize = 80.0;
  static const double businessLogoBorderRadius = radiusL;

  // QR Code
  static const double qrCodeSize = 200.0;
  static const double qrCodeBorderRadius = radiusM;

  // Form Elements
  static const double inputHeight = 48.0;
  static const double inputBorderRadius = radiusS;
  static const double inputBorderWidth = borderWidthThin;

  // Chip
  static const double chipHeight = 32.0;
  static const double chipBorderRadius = radiusS;

  // Badge
  static const double badgeSize = 20.0;
  static const double badgeBorderRadius = radiusCircle;

  // Divider
  static const double dividerThickness = 1.0;
  static const double dividerIndent = spacing16;

  // Loading Indicator
  static const double loadingIndicatorSize = 24.0;
  static const double loadingIndicatorSizeL = 32.0;
  static const double loadingIndicatorSizeXL = 48.0;

  // Snackbar
  static const double snackbarElevation = elevationM;
  static const double snackbarBorderRadius = radiusS;

  // Dialog
  static const double dialogBorderRadius = radiusL;
  static const double dialogElevation = elevationXL;
  static const double dialogMaxWidth = 400.0;

  // Sheet
  static const double sheetBorderRadius = radiusL;
  static const double sheetElevation = elevationXL;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Grid
  static const double gridSpacing = spacing8;
  static const double gridMainAxisSpacing = spacing16;
  static const double gridCrossAxisSpacing = spacing12;

  // List
  static const double listItemHeight = 72.0;
  static const double listItemMinHeight = 48.0;

  // Responsive helper methods
  static double getResponsiveWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getResponsiveHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isMobile(BuildContext context) {
    return getResponsiveWidth(context) < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = getResponsiveWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return getResponsiveWidth(context) >= tabletBreakpoint;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return paddingM;
    } else if (isTablet(context)) {
      return paddingL;
    } else {
      return paddingXL;
    }
  }

  static double getResponsiveCardWidth(BuildContext context) {
    final width = getResponsiveWidth(context);
    if (isMobile(context)) {
      return width - spacing32;
    } else if (isTablet(context)) {
      return width * 0.8;
    } else {
      return width * 0.6;
    }
  }

  static int getResponsiveGridCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }
}

// SizedBox helpers
class AppSizedBox {
  AppSizedBox._();

  // Width
  static const SizedBox w4 = SizedBox(width: AppDimensions.spacing4);
  static const SizedBox w8 = SizedBox(width: AppDimensions.spacing8);
  static const SizedBox w12 = SizedBox(width: AppDimensions.spacing12);
  static const SizedBox w16 = SizedBox(width: AppDimensions.spacing16);
  static const SizedBox w20 = SizedBox(width: AppDimensions.spacing20);
  static const SizedBox w24 = SizedBox(width: AppDimensions.spacing24);
  static const SizedBox w32 = SizedBox(width: AppDimensions.spacing32);
  static const SizedBox w40 = SizedBox(width: AppDimensions.spacing40);
  static const SizedBox w48 = SizedBox(width: AppDimensions.spacing48);

  // Height
  static const SizedBox h4 = SizedBox(height: AppDimensions.spacing4);
  static const SizedBox h8 = SizedBox(height: AppDimensions.spacing8);
  static const SizedBox h12 = SizedBox(height: AppDimensions.spacing12);
  static const SizedBox h16 = SizedBox(height: AppDimensions.spacing16);
  static const SizedBox h20 = SizedBox(height: AppDimensions.spacing20);
  static const SizedBox h24 = SizedBox(height: AppDimensions.spacing24);
  static const SizedBox h32 = SizedBox(height: AppDimensions.spacing32);
  static const SizedBox h40 = SizedBox(height: AppDimensions.spacing40);
  static const SizedBox h48 = SizedBox(height: AppDimensions.spacing48);

  // Square
  static const SizedBox square4 = SizedBox(
    width: AppDimensions.spacing4,
    height: AppDimensions.spacing4,
  );
  static const SizedBox square8 = SizedBox(
    width: AppDimensions.spacing8,
    height: AppDimensions.spacing8,
  );
  static const SizedBox square16 = SizedBox(
    width: AppDimensions.spacing16,
    height: AppDimensions.spacing16,
  );
  static const SizedBox square24 = SizedBox(
    width: AppDimensions.spacing24,
    height: AppDimensions.spacing24,
  );
  static const SizedBox square32 = SizedBox(
    width: AppDimensions.spacing32,
    height: AppDimensions.spacing32,
  );
}

// Divider helpers
class AppDivider {
  AppDivider._();

  static const Divider horizontal = Divider(
    thickness: AppDimensions.dividerThickness,
    indent: AppDimensions.dividerIndent,
    endIndent: AppDimensions.dividerIndent,
  );

  static const VerticalDivider vertical = VerticalDivider(
    thickness: AppDimensions.dividerThickness,
    indent: AppDimensions.dividerIndent,
    endIndent: AppDimensions.dividerIndent,
  );
}
