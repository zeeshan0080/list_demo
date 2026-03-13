import 'package:flutter/material.dart';
import 'package:list_demo/modules/video_list/video_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoListView extends StatefulWidget {
  const VideoListView({super.key});

  @override
  State<VideoListView> createState() => _VideoListViewState();
}

class _VideoListViewState extends State<VideoListView> {

  final List<String> _videoUrls = [
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: Text("Video List")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              ..._videoUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: VideoPlayerCard(
                    url: url,
                    index: index, // Pass unique index for visibility key
                  ),
                );
              }),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPlayerCard extends StatefulWidget {
  final String url;
  final int index;

  const VideoPlayerCard({
    super.key,
    required this.url,
    required this.index,
  });

  @override
  State<VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<VideoPlayerCard> {
  late VideoPlayerController _controller;
  bool _showControls = false;
  bool _hasStartedPlaying = false;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
      })
      ..addListener(_onVideoUpdate);

    VideoPlayerManager().addListener(_onManagerUpdate);
  }

  void _onManagerUpdate() {
    final manager = VideoPlayerManager();
    if (manager.currentlyPlayingUrl != widget.url && _controller.value.isPlaying) {
      _controller.pause();
      setState(() {
        _showControls = false;
        _hasStartedPlaying = true;
      });
    }
  }

  void _onVideoUpdate() {
    if (mounted) {
      if (_controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration &&
          _controller.value.duration > Duration.zero) {
        VideoPlayerManager().stopAll();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    VideoPlayerManager().removeListener(_onManagerUpdate);
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final visibleFraction = info.visibleFraction;
    final wasVisible = _isVisible;
    _isVisible = visibleFraction > 0.5; // Consider visible if more than 50% visible

    // If visibility changed from visible to not visible and video is playing, pause it
    if (wasVisible && !_isVisible && _controller.value.isPlaying) {
      _controller.pause();
      setState(() {
        _showControls = false;
        _hasStartedPlaying = true;
      });
      // Notify manager that this video stopped
      if (VideoPlayerManager().currentlyPlayingUrl == widget.url) {
        VideoPlayerManager().stopAll();
      }
    }
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      _showControls = false;
    } else {
      // Only play if widget is visible
      if (!_isVisible) return;

      VideoPlayerManager().playVideo(widget.url);
      _controller.play();
      _hasStartedPlaying = true;
      _showControls = true;
      _autoHideControls();
    }
    setState(() {});
  }

  void _toggleMute() {
    final newVolume = _controller.value.volume == 0 ? 1.0 : 0.0;
    _controller.setVolume(newVolume);
    setState(() {});
  }

  void _onTap() {
    if (_hasStartedPlaying && _controller.value.isPlaying) {
      setState(() {
        _showControls = !_showControls;
      });
      if (_showControls) {
        _autoHideControls();
      }
    }
  }

  void _autoHideControls() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _seekToStart() {
    _controller.seekTo(Duration.zero);
    setState(() {});
  }

  bool get _isVideoCompleted {
    return _controller.value.position >= _controller.value.duration;
  }

  bool get _showCenterPlay {
    if (!_hasStartedPlaying) return true;
    if (_isVideoCompleted) return true;
    if (!_controller.value.isPlaying && !_showControls) return true;
    return false;
  }

  bool get _isMuted => _controller.value.volume == 0;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video-${widget.index}-${widget.url}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          if (!_controller.value.isInitialized) {
            return Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final calculatedHeight = maxWidth / _controller.value.aspectRatio;
          final maxAllowedHeight = 500.0;
          final shouldConstrain = calculatedHeight > maxAllowedHeight;

          return Container(
            height: shouldConstrain ? maxAllowedHeight : calculatedHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: GestureDetector(
                onTap: _onTap,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: shouldConstrain
                          ? VideoPlayer(_controller)
                          : AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),

                    if (_showCenterPlay)
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              if (_isVideoCompleted) {
                                _seekToStart();
                              }
                              _togglePlayPause();
                            },
                            icon: Icon(
                              _isVideoCompleted ? Icons.replay : Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),

                    if (_showControls && _controller.value.isPlaying)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black54,
                                Colors.black87,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                colors: VideoProgressColors(
                                  playedColor: Colors.white,
                                  bufferedColor: Colors.white54,
                                  backgroundColor: Colors.white24,
                                ),
                                padding: EdgeInsets.only(bottom: 5),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _togglePlayPause,
                                    icon: Icon(
                                      Icons.pause,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  Text(
                                    '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _toggleMute,
                                    icon: Icon(
                                      _isMuted ? Icons.volume_off : Icons.volume_up,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                  Spacer(),
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.fullscreen,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
