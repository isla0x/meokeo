import 'package:flutter/cupertino.dart';

import '../icons.dart';
import '../models.dart';
import '../repo/firebase_repo.dart' show errorDetail;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// 사진을 크게 봐요. 내 사진이면 지울 수 있어요.
Future<void> openPhoto(BuildContext context, Room room, Post post, String name, bool mine) {
  return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
    opaque: false,
    barrierColor: const Color(0xF2000000),
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => PhotoViewer(room: room, post: post, name: name, mine: mine),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  ));
}

class PhotoViewer extends StatelessWidget {
  const PhotoViewer({super.key, required this.room, required this.post, required this.name, required this.mine});
  final Room room;
  final Post post;
  final String name;
  final bool mine;

  Future<void> _delete(BuildContext context) async {
    final app = AppScope.read(context);
    final ok = await showConfirm(context,
        title: '이 사진을 지울까요?', message: '${post.meal.label} 사진이 방에서 사라져요.', okLabel: '지우기', destructive: true);
    if (!ok || !context.mounted) return;
    try {
      await app.repo.deletePost(room.id, post);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) await showAlert(context, '지우지 못했어요.\n(${errorDetail(e)})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: EdgeInsets.only(top: topPad(context) + 52, bottom: 150 + bottom),
              child: Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image(image: post.image, fit: BoxFit.contain, gaplessPlayback: true),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: topPad(context),
          child: GlassIconButton(icon: Ic.close, label: '닫기', size: 20, onTap: () => Navigator.of(context).pop()),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16 + bottom,
          child: Glass(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(children: [
              MealBadge(post.meal, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    post.text.isEmpty ? name : post.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ts(15, w: FontWeight.w700, lh: 20, color: C.ink),
                  ),
                  Text(
                    '${post.text.isEmpty ? '' : '$name · '}${post.meal.label} · ${post.timeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(12, lh: 16, color: C.sub),
                  ),
                ]),
              ),
              if (mine)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _delete(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('지우기', style: ts(14, w: FontWeight.w600, lh: 20, color: C.red)),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
