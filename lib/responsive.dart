import 'package:flutter/material.dart';

const double kDesktopBreakpoint = 600.0;
const double kMaxContentWidth = 800.0;
const BoxConstraints kSheetConstraints =
    BoxConstraints(maxWidth: kMaxContentWidth);

bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;
