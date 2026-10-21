import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user_repository.dart';
import '../../domain/entities/stage_entity.dart';
import '../../presentation/providers/ad_provider.dart';
import '../../presentation/providers/booster_provider.dart';
import '../../presentation/providers/stage_provider.dart';
import '../../presentation/widgets/stage_node.dart';
import '../../presentation/widgets/map_path_painter.dart';
import '../../presentation/widgets/map_background.dart';
import '../../presentation/widgets/rabbit_icon.dart';
import '../../presentation/widgets/refill_countdown.dart';
import '../../presentation/widgets/ad_banner_widget.dart';
import '../../presentation/screens/stage_popup.dart';

/// Candy Crush Saga-style stage selection map.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    context.read<StageProvider>().loadStages();
    context.read<BoosterProvider>().loadInventory();
    context.read<AdProvider>().loadBannerAd();
    context.read<AdProvider>().loadInterstitialAd();
    context.read<AdProvider>().loadRewardedAd();
  }

  List<Offset> _getNodePositions(int stageCount) {
    const perRow = 4;
    final positions = <Offset>[];
    for (int i = 0; i < stageCount; i++) {
      final row = i ~/ perRow;
      final inRow = i % perRow;
      // Snake layout: even rows run left -> right, odd rows right -> left.
      // Every node gets a unique slot (the old zigzag math mapped every
      // odd-row node to the same x, stacking stages 5-8 and 9-10).
      final col = row.isOdd ? perRow - 1 - inRow : inRow;
      final x = 60.0 + col * 90.0;
      final y = 140.0 + row * 110.0;
      positions.add(Offset(x, y));
    }
    return positions;
  }

  void _showStagePopup(BuildContext context, StageEntity stage) {
    final stars = context.read<StageProvider>().getStarsForStage(stage.id);
    showDialog(
      context: context,
      builder: (_) => StagePopup(
        stage: stage,
        stars: stars,
        onPlay: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/game', arguments: {
            'id': stage.id,
            'regionGrid': stage.regionGrid,
            'starterRabbitRow': stage.starterRabbitRow,
            'starterRabbitCol': stage.starterRabbitCol,
            'solution': stage.solution,
            'isSpecial': stage.isSpecialStage,
          });
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StageProvider>(
      builder: (context, stageProvider, child) {
        if (stageProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final stages = stageProvider.stages;
        final unlocked = stageProvider.unlockedStageIndex;
        final positions = _getNodePositions(stages.length);
        final userRepo = context.read<UserRepository>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bunny Doku'),
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const RabbitIcon(size: 22),
                onPressed: () => Navigator.pushNamed(context, '/shop'),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Always-on animated meadow: a rabbit hopping through
              // greenery. It loops forever and cannot be paused.
              const Positioned.fill(child: MapBackground()),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // The 5-life pool lives on the map only.
                        ExtraLivesPill(userRepo: userRepo),
                        const Spacer(),
                        // Total stars actually earned across every cleared
                        // stage (not a live counter of the current run).
                        _StarsPill(stars: stageProvider.getTotalStars()),
                        const SizedBox(width: 12),
                        const Icon(Icons.monetization_on, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${userRepo.getCurrentUser()?.totalCoins ?? 0}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 200,
                      ),
                      child: Stack(
                        children: [
                          if (positions.length >= 2)
                            CustomPaint(
                              size: Size(
                                MediaQuery.of(context).size.width,
                                positions.last.dy + 120,
                              ),
                              painter: MapPathPainter(points: positions),
                            ),
                          ...List.generate(stages.length, (index) {
                            final stage = stages[index];
                            final pos = positions[index];
                            final isUnlocked = stage.id <= unlocked;
                            final isCompleted = index < unlocked - 1;

                            return Positioned(
                              left: pos.dx - 28,
                              top: pos.dy - 28,
                              child: StageNode(
                                stageId: stage.id,
                                isUnlocked: isUnlocked,
                                isCompleted: isCompleted,
                                isSpecial: stage.isSpecialStage,
                                stars: stageProvider.getStarsForStage(stage.id),
                                onTap: isUnlocked
                                    ? () => _showStagePopup(context, stage)
                                    : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  ),
                  if (!(userRepo.getCurrentUser()?.isAdsRemoved ?? false))
                    const AdBannerWidget(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact pill in the map header showing the total stars the player has
/// actually earned across every cleared stage.
class _StarsPill extends StatelessWidget {
  final int stars;

  const _StarsPill({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 22),
        const SizedBox(width: 4),
        Text(
          '$stars',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
