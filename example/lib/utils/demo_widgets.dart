import 'dart:async';

import 'package:flutter/material.dart';

const double kSpace8 = 8.0;
const double kSpace16 = 16.0;

const SizedBox SPACE_8 = SizedBox(height: 8);
const SizedBox SPACE_16 = SizedBox(height: 16);

final GlobalKey<NavigatorState> gNavigatorKey = GlobalKey<NavigatorState>();

void toast(String msg) {
  final context = gNavigatorKey.currentContext;
  if (context == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
  );
}

mixin DisposeBag {
  final List<StreamSubscription> _subscriptions = [];

  void addDisposable(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  void disposeBag() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
  }
}

extension StreamSubscriptionExtension on StreamSubscription {
  void addTo(DisposeBag bag) {
    bag.addDisposable(this);
  }
}

class DecoratedColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final Widget? divider;
  final MainAxisSize mainAxisSize;

  const DecoratedColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.padding,
    this.scrollable = false,
    this.divider,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> effectiveChildren = children;
    if (divider != null) {
      effectiveChildren = [];
      for (int i = 0; i < children.length; i++) {
        if (i > 0) effectiveChildren.add(divider!);
        effectiveChildren.add(children[i]);
      }
    }

    Widget column = Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: effectiveChildren,
    );

    if (padding != null) {
      column = Padding(padding: padding!, child: column);
    }

    if (scrollable) {
      column = SingleChildScrollView(child: column);
    }

    return column;
  }
}

class DecoratedRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double itemSpacing;
  final EdgeInsetsGeometry? padding;

  const DecoratedRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.itemSpacing = 0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> effectiveChildren = children;
    if (itemSpacing > 0 && children.length > 1) {
      effectiveChildren = [];
      for (int i = 0; i < children.length; i++) {
        if (i > 0) effectiveChildren.add(SizedBox(width: itemSpacing));
        effectiveChildren.add(children[i]);
      }
    }

    Widget row = Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: effectiveChildren,
    );

    if (padding != null) {
      row = Padding(padding: padding!, child: row);
    }

    return row;
  }
}

class DecoratedStack extends StatelessWidget {
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final StackFit fit;
  final Clip clipBehavior;

  const DecoratedStack({
    super.key,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
      children: children,
    );
  }
}

class FunctionGroup extends StatelessWidget {
  final String headLabel;
  final List<Widget> children;

  const FunctionGroup({
    super.key,
    required this.headLabel,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            headLabel,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: Colors.grey),
          ),
        ),
        ...children,
      ],
    );
  }
}

class FunctionItem extends StatelessWidget {
  final String label;
  final String? sublabel;
  final Widget? target;

  const FunctionItem({
    super.key,
    required this.label,
    this.sublabel,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: sublabel != null
          ? Text(sublabel!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (target != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => target!));
        }
      },
    );
  }
}

class BooleanSetting extends StatefulWidget {
  final String head;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const BooleanSetting({
    super.key,
    required this.head,
    this.selected = false,
    required this.onSelected,
  });

  @override
  State<BooleanSetting> createState() => _BooleanSettingState();
}

class _BooleanSettingState extends State<BooleanSetting> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.head),
      value: _value,
      onChanged: (value) {
        setState(() => _value = value);
        widget.onSelected(value);
      },
    );
  }
}

class DiscreteSetting extends StatelessWidget {
  final String head;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const DiscreteSetting({
    super.key,
    required this.head,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(head),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(option);
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class ContinuousSetting extends StatelessWidget {
  final String head;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const ContinuousSetting({
    super.key,
    required this.head,
    this.min = 0,
    this.max = 1,
    this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    double currentValue = min;

    return StatefulBuilder(
      builder: (context, setState) {
        return ListTile(
          title: Text(head),
          subtitle: Slider(
            value: currentValue,
            min: min,
            max: max,
            divisions: divisions,
            label: currentValue.toStringAsFixed(1),
            onChanged: (value) {
              setState(() => currentValue = value);
              onChanged(value);
            },
          ),
        );
      },
    );
  }
}
