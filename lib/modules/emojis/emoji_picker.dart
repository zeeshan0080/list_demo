import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;

class EmojiPickerView extends StatefulWidget {
  const EmojiPickerView({super.key});

  @override
  State<EmojiPickerView> createState() => _EmojiPickerViewState();
}

class _EmojiPickerViewState extends State<EmojiPickerView> {
  final _emojiController = TextEditingController();

  List<String> _selected = [];

  @override
  void initState() {
    _selected.add("😀");
    _selected.add("😃");
    _selected.add("😄");
    _selected.add("😁");
    _selected.add("😆");
    _selected.add("😅");
    super.initState();
  }

  Future<dynamic> showFull() async {
    return await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      // barrierColor: Colors.transparent,
      barrierLabel: "Emojis",
      pageBuilder: (_, __, ___){
        return Dialog(
          backgroundColor: Colors.redAccent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 15
          ),
          child: EmojiPicker(
            onEmojiSelected: (Category? category, Emoji emoji) {
              Navigator.of(context).pop(emoji.emoji);
            },
            // textEditingController: _emojiController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
            config: Config(
              height: 290,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: Colors.white,
                columns: 7,
                verticalSpacing: 5,
                horizontalSpacing: 6,
                emojiSizeMax: 35
                /*emojiSizeMax: 28 *
                    (foundation.defaultTargetPlatform == TargetPlatform.iOS
                        ?  1.20
                        :  1.0),*/
              ),
              viewOrderConfig: const ViewOrderConfig(
                top: EmojiPickerItem.categoryBar,
                middle: EmojiPickerItem.emojiView,
              ),
              skinToneConfig: const SkinToneConfig(enabled: false),
              categoryViewConfig: const CategoryViewConfig(
                initCategory: Category.SMILEYS,
                recentTabBehavior: RecentTabBehavior.NONE,
              ),
              bottomActionBarConfig: const BottomActionBarConfig(
                  showBackspaceButton: false,
                  showSearchViewButton: false
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Emoji Picker"
        ),
      ),
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final result = await showFull();
              if(result != null){
                print("Result: ${result.toString()}");
              }
            },
            child: Text("Show"),
          )
        ],
      ),
    );
  }
}
