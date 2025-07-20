import 'package:flutter/material.dart';
import '../services/url_service.dart';

mixin UrlMixin<T extends StatefulWidget> on State<T> {
  final UrlService _urlService = UrlService();

  @override
  void initState() {
    super.initState();
    // Set up URL listener for back/forward button support
    _setupUrlListener();
    // Update URL when page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onPageInitialized();
    });
  }

  /// Override this method in your page to handle URL updates on page initialization
  void _onPageInitialized() {
    // Default implementation - can be overridden
  }

  /// Set up URL listener for browser back/forward buttons
  void _setupUrlListener() {
    _urlService.setupUrlListener((String newPath) {
      onUrlChanged(newPath);
    });
  }

  /// Override this method to handle URL changes from back/forward buttons
  void onUrlChanged(String newPath) {
    // Default implementation - can be overridden by the page
  }

  /// Update the browser URL with a simple route
  void updatePageUrl(String route, {String? customTitle, Map<String, String>? params}) {
    _urlService.updateUrl(route, customTitle: customTitle, params: params);
  }

  /// Replace the current URL without adding to history
  void replacePageUrl(String route, {String? customTitle, Map<String, String>? params}) {
    _urlService.replaceUrl(route, customTitle: customTitle, params: params);
  }

  /// Navigate to a route while updating the URL
  void navigateWithUrl(String route, {
    Object? arguments,
    String? customTitle,
    Map<String, String>? params,
    bool replace = false,
  }) {
    _urlService.navigateWithUrl(
      context,
      route,
      arguments: arguments,
      customTitle: customTitle,
      params: params,
      replace: replace,
    );
  }

  /// Get the current URL path
  String getCurrentPath() => _urlService.getCurrentPath();

  /// Get the current URL parameters
  Map<String, String> getCurrentParams() => _urlService.getCurrentParams();
} 