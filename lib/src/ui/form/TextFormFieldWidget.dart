import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:tch_appliable_core/tch_appliable_core.dart';
import 'package:tch_common_widgets/src/core/CommonDimens.dart';
import 'package:tch_common_widgets/src/core/CommonTheme.dart';
import 'package:tch_appliable_core/utils/Color.dart';
import 'package:tch_common_widgets/src/ui/form/Form.dart';

class TextFormFieldWidget extends AbstractStatefulWidget {
  final TextFormFieldStyle? style;
  final TextEditingController controller;
  final bool autofocus;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? label;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int lines;
  final List<FormFieldValidation<String>>? validations;
  final bool enabled;
  final bool autocorrect;

  /// TextFormFieldWidget initialization
  TextFormFieldWidget({
    this.style,
    Key? key,
    required this.controller,
    this.autofocus = false,
    this.focusNode,
    this.nextFocus,
    this.onChanged,
    this.onFieldSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.lines = 1,
    this.validations,
    this.enabled = true,
    this.autocorrect = true,
  })  : assert((focusNode == null && nextFocus == null) || focusNode != null),
        super(key: key);

  /// Create state for widget
  @override
  State<StatefulWidget> createState() => _TextFormFieldWidgetState();
}

class _TextFormFieldWidgetState extends AbstractStatefulWidgetState<TextFormFieldWidget> with TickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isError = false;
  String? _errorText;
  GlobalKey? _uiKitKey;
  MethodChannel? _methodChannel;
  String? _ignoreSetTextOnIOSNativeTextField;

  /// State initialization
  @override
  void initState() {
    super.initState();

    _focusNode = widget.focusNode ?? FocusNode();
  }

  /// Manually dispose of resources
  @override
  void dispose() {
    _methodChannel = null;

    widget.controller.removeListener(_controllerTextChangedForIOSNativeTextField);

    _focusNode.removeListener(_focusChangedForIOSNativeTextField);

    super.dispose();
  }

  /// Run initializations of screen on first build only
  @override
  firstBuildOnly(BuildContext context) {
    super.firstBuildOnly(context);

    final commonTheme = CommonTheme.of(context);

    bool iOSUseNativeTextField = true;
    if (widget.style != null) {
      iOSUseNativeTextField = widget.style!.iOSUseNativeTextField;
    } else if (commonTheme != null) {
      iOSUseNativeTextField = commonTheme.formStyle.textFormFieldStyle.iOSUseNativeTextField;
    }

    if (iOSUseNativeTextField && !kIsWeb && Platform.isIOS) {
      _uiKitKey = GlobalKey();

      widget.controller.addListener(_controllerTextChangedForIOSNativeTextField);

      _focusNode.addListener(_focusChangedForIOSNativeTextField);
    }
  }

  /// Create view layout from widgets
  @override
  Widget buildContent(BuildContext context) {
    final commonTheme = CommonTheme.of(context);

    final TextFormFieldVariant theVariant = (widget.style?.variant ?? commonTheme?.formStyle.textFormFieldStyle.variant) ?? TextFormFieldVariant.Material;

    bool iOSUseNativeTextField = true;
    if (widget.style != null) {
      iOSUseNativeTextField = widget.style!.iOSUseNativeTextField;
    } else if (commonTheme != null) {
      iOSUseNativeTextField = commonTheme.formStyle.textFormFieldStyle.iOSUseNativeTextField;
    }

    final bool animatedSizeChanges = commonTheme?.formStyle.animatedSizeChanges ?? true;
    final bool fullWidthMobileOnly = commonTheme?.formStyle.fullWidthMobileOnly ?? true;

    final theNextFocus = widget.nextFocus;
    final theOnFieldSubmitted = widget.onFieldSubmitted;

    InputDecoration theDecoration = (widget.style?.inputDecoration ?? commonTheme?.formStyle.textFormFieldStyle.inputDecoration) ?? InputDecoration();

    if ((widget.style?.inputDecoration ?? commonTheme?.formStyle.textFormFieldStyle.inputDecoration) != null) {
      theDecoration = theDecoration.copyWith(
        enabledBorder: theDecoration.enabledBorder?.copyWith(
          borderSide: theDecoration.enabledBorder!.borderSide.copyWith(
            color: widget.style?.borderColor ?? commonTheme?.formStyle.textFormFieldStyle.borderColor,
          ),
        ),
        disabledBorder: theDecoration.disabledBorder?.copyWith(
          borderSide: theDecoration.disabledBorder!.borderSide.copyWith(
            color: widget.style?.disabledBorderColor ?? commonTheme?.formStyle.textFormFieldStyle.disabledBorderColor,
          ),
        ),
        focusedBorder: theDecoration.focusedBorder?.copyWith(
          borderSide: theDecoration.focusedBorder!.borderSide.copyWith(
            color: widget.style?.borderColor ?? commonTheme?.formStyle.textFormFieldStyle.borderColor,
          ),
        ),
        errorBorder: theDecoration.errorBorder?.copyWith(
          borderSide: theDecoration.errorBorder!.borderSide.copyWith(
            color: widget.style?.errorColor ?? commonTheme?.formStyle.textFormFieldStyle.errorColor,
          ),
        ),
        focusedErrorBorder: theDecoration.focusedErrorBorder?.copyWith(
          borderSide: theDecoration.focusedErrorBorder!.borderSide.copyWith(
            color: widget.style?.errorColor ?? commonTheme?.formStyle.textFormFieldStyle.errorColor,
          ),
        ),
        errorStyle: theDecoration.errorStyle?.copyWith(
          color: widget.style?.errorColor ?? commonTheme?.formStyle.textFormFieldStyle.errorColor,
        ),
      );

      if (commonTheme != null) {
        theDecoration = theDecoration.copyWith(
          labelStyle: theDecoration.labelStyle != null ? commonTheme.preProcessTextStyle(theDecoration.labelStyle!) : null,
          errorStyle: theDecoration.errorStyle != null ? commonTheme.preProcessTextStyle(theDecoration.errorStyle!) : null,
        );
      }
    }

    if (!widget.enabled) {
      theDecoration = theDecoration.copyWith(
        fillColor: widget.style?.fillColorDisabled ?? commonTheme?.formStyle.textFormFieldStyle.fillColorDisabled,
      );
    }

    if (_isError) {
      theDecoration = theDecoration.copyWith(
        labelStyle: theDecoration.errorStyle?.copyWith(
          color: theDecoration.errorStyle?.color,
        ),
      );
    }

    final theLines = widget.lines > 0 ? widget.lines : 1;
    final theKeyboardType = widget.keyboardType ??
        widget.style?.keyboardType ??
        commonTheme?.formStyle.textFormFieldStyle.keyboardType ??
        (theLines > 1 ? TextInputType.multiline : null);
    final theTextInputAction = widget.textInputAction ?? (theLines > 1 ? TextInputAction.newline : null);

    final List<FormFieldValidation<String>>? theValidations =
        widget.validations ?? widget.style?.validations ?? commonTheme?.formStyle.textFormFieldStyle.validations;

    late Widget field;

    if (iOSUseNativeTextField && !kIsWeb && Platform.isIOS) {
      TextStyle? inputStyle = widget.style?.inputStyle ?? commonTheme?.formStyle.textFormFieldStyle.inputStyle;
      if (inputStyle != null && commonTheme != null) {
        inputStyle = commonTheme.preProcessTextStyle(inputStyle);
      }

      final creationParams = _IOSUseNativeTextFieldParams(
        text: widget.controller.text,
        inputStyle: inputStyle,
        maxLines: theLines,
        keyboardType: theKeyboardType,
        textInputAction: theTextInputAction,
        textCapitalization: (widget.style?.textCapitalization ?? commonTheme?.formStyle.textFormFieldStyle.textCapitalization) ?? TextCapitalization.none,
        textAlign: (widget.style?.textAlign ?? commonTheme?.formStyle.textFormFieldStyle.textAlign) ?? TextAlign.start,
        autocorrect: widget.autocorrect,
      );

      field = IgnorePointer(
        ignoring: !widget.enabled,
        child: FormField(
          builder: (FormFieldState<String> field) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputDecorator(
                  decoration: theDecoration.copyWith(
                    labelText: theVariant != TextFormFieldVariant.Cupertino ? widget.label : null,
                    prefixIcon:
                        widget.prefixIcon ?? widget.style?.inputDecoration.prefixIcon ?? commonTheme?.formStyle.textFormFieldStyle.inputDecoration.prefixIcon,
                    suffixIcon:
                        widget.suffixIcon ?? widget.style?.inputDecoration.suffixIcon ?? commonTheme?.formStyle.textFormFieldStyle.inputDecoration.suffixIcon,
                  ),
                  baseStyle: widget.style?.inputStyle ?? commonTheme?.preProcessTextStyle(commonTheme.formStyle.textFormFieldStyle.inputStyle),
                  isFocused: _focusNode.hasFocus,
                  isEmpty: widget.controller.value.text.isEmpty,
                  expands: false,
                  child: Container(
                    height: theLines * 24, //48, //TODO height by lines, isDense = false does not seem to work right now, check later
                    child: UiKitView(
                      key: _uiKitKey,
                      viewType: 'tch_common_widgets/TextFormFieldWidget',
                      layoutDirection: TextDirection.ltr,
                      creationParams: creationParams.toJson(),
                      creationParamsCodec: const StandardMessageCodec(),
                      onPlatformViewCreated: (int viewId) {
                        _methodChannel = MethodChannel('tch_common_widgets/TextFormFieldWidget$viewId');
                        _methodChannel!.setMethodCallHandler(_onMethodCall);
                      },
                    ),
                  ),
                ),
                if (_isError)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                    child: Text(
                      _errorText!,
                      style: theDecoration.errorStyle,
                    ),
                  ),
              ],
            );
          },
          validator: (String? value) {
            value = widget.controller.value.text;

            if (theValidations != null) {
              final validated = validateValidations(theValidations, value);

              setStateNotDisposed(() {
                _isError = validated != null;
                _errorText = validated;
              });

              return validated;
            }

            return null;
          },
        ),
      );
    } else {
      TextStyle? textStyle = widget.style?.inputStyle ?? commonTheme?.formStyle.textFormFieldStyle.inputStyle;
      if (textStyle != null && commonTheme != null) {
        textStyle = commonTheme.preProcessTextStyle(textStyle);
      }

      field = TextFormField(
        autofocus: widget.autofocus,
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        onFieldSubmitted: (String value) {
          if (theNextFocus != null) {
            final focusScope = FocusScope.of(context);

            focusScope.unfocus();

            focusScope.requestFocus(theNextFocus);
          }

          if (theOnFieldSubmitted != null) {
            theOnFieldSubmitted(value);
          }
        },
        keyboardType: theKeyboardType,
        textInputAction: theTextInputAction,
        style: textStyle,
        decoration: theDecoration.copyWith(
          labelText: theVariant != TextFormFieldVariant.Cupertino ? widget.label : null,
          prefixIcon: widget.prefixIcon ?? widget.style?.inputDecoration.prefixIcon ?? commonTheme?.formStyle.textFormFieldStyle.inputDecoration.prefixIcon,
          suffixIcon: widget.suffixIcon ?? widget.style?.inputDecoration.suffixIcon ?? commonTheme?.formStyle.textFormFieldStyle.inputDecoration.suffixIcon,
        ),
        textCapitalization: (widget.style?.textCapitalization ?? commonTheme?.formStyle.textFormFieldStyle.textCapitalization) ?? TextCapitalization.none,
        textAlign: (widget.style?.textAlign ?? commonTheme?.formStyle.textFormFieldStyle.textAlign) ?? TextAlign.start,
        minLines: theLines,
        maxLines: theLines,
        validator: (String? value) {
          if (theValidations != null) {
            final validated = validateValidations(theValidations, value);

            setStateNotDisposed(() {
              _isError = validated != null;
            });

            return validated;
          }

          return null;
        },
        autocorrect: widget.autocorrect,
        enabled: widget.enabled,
      );
    }

    Widget content = field;

    final theLabel = widget.label;
    if (theVariant == TextFormFieldVariant.Cupertino && theLabel != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: (widget.style?.cupertinoLabelPadding ?? commonTheme?.formStyle.textFormFieldStyle.cupertinoLabelPadding) ??
                const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: Text(
              theLabel,
              style: theDecoration.labelStyle,
            ),
          ),
          content,
        ],
      );
    }

    if (fullWidthMobileOnly) {
      content = Container(
        width: kPhoneStopBreakpoint,
        child: content,
      );
    }

    if (animatedSizeChanges) {
      content = AnimatedSize(
        vsync: this,
        duration: kThemeAnimationDuration,
        alignment: Alignment.topCenter,
        child: content,
      );
    }

    return content;
  }

  /// Response to message from platform
  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case "focused":
        _focusIOSNativeTextField();
        break;
      case "setText":
        _setTextFromIOSNativeTextField(call.arguments as String);
        break;
      case "didEndEditing":
        _didEndEditingIOSNativeTextField(call.arguments as String);
        break;
    }
  }

  /// On TextEditingController change text update Widget text
  void _controllerTextChangedForIOSNativeTextField() {
    if (widget.controller.text != _ignoreSetTextOnIOSNativeTextField) {
      _methodChannel!.invokeMethod("setText", widget.controller.text);

      setStateNotDisposed(() {});
    }

    _ignoreSetTextOnIOSNativeTextField = null;
  }

  /// On FocusNode focus changed update Widget state
  void _focusChangedForIOSNativeTextField() {
    if (_focusNode.hasFocus) {
      _methodChannel!.invokeMethod('focus');
    } else {
      _methodChannel!.invokeMethod('unFocus');

      _methodChannel!.invokeMethod<String>('getText').then((String? text) {
        setStateNotDisposed(() {
          widget.controller.text = text ?? "";
        });
      });
    }

    setStateNotDisposed(() {});
  }

  /// Make sure Widget is visible on screen and set focus
  void _focusIOSNativeTextField() {
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      if (mounted) {
        context.findRenderObject()!.showOnScreen(
              duration: kThemeAnimationDuration,
              curve: Curves.linear,
            );
      }
    });

    if (!_focusNode.hasFocus) {
      final focusScope = FocusScope.of(context);

      focusScope.unfocus();

      focusScope.requestFocus(_focusNode);
    }
  }

  /// Make sure Widget text is synchronized
  void _setTextFromIOSNativeTextField(String text) {
    _ignoreSetTextOnIOSNativeTextField = text;

    widget.controller.text = text;
  }

  /// Widget ended text editing, update controller and emulate onFieldSubmitted
  void _didEndEditingIOSNativeTextField(String text) {
    widget.controller.text = text;

    final theNextFocus = widget.nextFocus;
    final theOnFieldSubmitted = widget.onFieldSubmitted;

    if (theNextFocus != null) {
      final focusScope = FocusScope.of(context);

      focusScope.unfocus();

      focusScope.requestFocus(theNextFocus);
    }

    if (theOnFieldSubmitted != null) {
      theOnFieldSubmitted(text);
    }

    setStateNotDisposed(() {});
  }
}

enum TextFormFieldVariant {
  None,
  Material,
  Cupertino,
}

class TextFormFieldStyle {
  final TextFormFieldVariant variant;
  final bool iOSUseNativeTextField;
  final TextStyle inputStyle;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final InputDecoration inputDecoration;
  final Color borderColor;
  final Color fillColorDisabled;
  final Color disabledBorderColor;
  final Color errorColor;
  final EdgeInsets cupertinoLabelPadding;
  final List<FormFieldValidation<String>>? validations;

  /// TextFormFieldStyle initialization
  const TextFormFieldStyle({
    this.variant = TextFormFieldVariant.Material,
    this.iOSUseNativeTextField = false,
    this.inputStyle = const TextStyle(color: Colors.black, fontSize: 16, height: 1.5),
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.inputDecoration = const InputDecoration(
      isDense: true,
      labelStyle: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: kCommonHorizontalMarginHalf,
        vertical: 12,
      ),
      filled: true,
      fillColor: Colors.transparent,
      enabledBorder: const OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
        ),
        borderRadius: const BorderRadius.all(const Radius.circular(8)),
      ),
      disabledBorder: const OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
        ),
        borderRadius: const BorderRadius.all(const Radius.circular(8)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
        ),
        borderRadius: const BorderRadius.all(const Radius.circular(8)),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
        ),
        borderRadius: const BorderRadius.all(const Radius.circular(8)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
        ),
        borderRadius: const BorderRadius.all(const Radius.circular(8)),
      ),
      errorStyle: const TextStyle(fontSize: 16),
    ),
    this.borderColor = Colors.black,
    this.fillColorDisabled = Colors.grey,
    this.disabledBorderColor = Colors.grey,
    this.errorColor = Colors.red,
    this.cupertinoLabelPadding = const EdgeInsets.only(left: 8, right: 8, bottom: 8),
    this.validations = const <FormFieldValidation<String>>[],
  });

  /// Create copy if this style with changes
  TextFormFieldStyle copyWith({
    TextFormFieldVariant? variant,
    bool? iOSUseNativeTextField,
    TextStyle? inputStyle,
    TextCapitalization? textCapitalization,
    TextAlign? textAlign,
    TextInputType? keyboardType,
    InputDecoration? inputDecoration,
    Color? borderColor,
    Color? fillColorDisabled,
    Color? disabledBorderColor,
    Color? errorColor,
    EdgeInsets? cupertinoLabelPadding,
    List<FormFieldValidation<String>>? validations,
  }) {
    return TextFormFieldStyle(
      variant: variant ?? this.variant,
      iOSUseNativeTextField: iOSUseNativeTextField ?? this.iOSUseNativeTextField,
      inputStyle: inputStyle ?? this.inputStyle,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      textAlign: textAlign ?? this.textAlign,
      keyboardType: keyboardType ?? this.keyboardType,
      inputDecoration: inputDecoration ?? this.inputDecoration,
      borderColor: borderColor ?? this.borderColor,
      fillColorDisabled: fillColorDisabled ?? this.fillColorDisabled,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      errorColor: errorColor ?? this.errorColor,
      cupertinoLabelPadding: cupertinoLabelPadding ?? this.cupertinoLabelPadding,
      validations: validations ?? this.validations,
    );
  }
}

class _IOSUseNativeTextFieldParams extends DataModel {
  String text;
  TextStyle? inputStyle;
  int maxLines;
  TextInputType? keyboardType;
  TextInputAction? textInputAction;
  TextCapitalization textCapitalization;
  TextAlign textAlign;
  bool autocorrect;

  /// IOSUseNativeTextFieldParams initialization
  _IOSUseNativeTextFieldParams({
    required this.text,
    this.inputStyle,
    required this.maxLines,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.autocorrect = true,
  }) : super.fromJson(<String, dynamic>{});

  /// Convert into JSON map
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic>? _inputStyle;
    if (inputStyle != null) {
      _inputStyle = <String, dynamic>{
        'color': inputStyle!.color?.toHex(),
        'fontSize': inputStyle!.fontSize,
        'fontWeightBold': inputStyle!.fontWeight == FontWeight.bold,
        'fontFamily': inputStyle!.fontFamily,
      };
    }

    return <String, dynamic>{
      'text': text,
      'inputStyle': _inputStyle,
      'maxLines': maxLines,
      'keyboardType': keyboardType?.toJson()['name'],
      'textInputAction': textInputAction?.toString(),
      'textCapitalization': textCapitalization.toString(),
      'textAlign': textAlign.toString(),
      'autocorrect': autocorrect,
    };
  }
}
