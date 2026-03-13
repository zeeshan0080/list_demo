import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoListView extends StatefulWidget {
  const VideoListView({super.key});

  @override
  State<VideoListView> createState() => _VideoListViewState();
}

class _VideoListViewState extends State<VideoListView> {
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
              VideoPlayerCard(url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
              const SizedBox(height: 20),
              VideoPlayerCard(url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
              const SizedBox(height: 20),
              VideoPlayerCard(url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4'),
              const SizedBox(height: 20),
              VideoPlayerCard(url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4'),
              const SizedBox(height: 20),
              VideoPlayerCard(url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4'),
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

  const VideoPlayerCard({super.key, required this.url});

  @override
  State<VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<VideoPlayerCard> {
  late VideoPlayerController _controller;
  bool _showControls = false;
  bool _hasStartedPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.url))
          ..initialize().then((_) {
            setState(() {});
          })
          ..addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      // When paused, hide bottom controls immediately, show center play
      _showControls = false;
    } else {
      _controller.play();
      _hasStartedPlaying = true;
      // When starting play, hide center play and show bottom controls briefly
      _showControls = true;
      _autoHideControls();
    }
    setState(() {});
  }

  void _onTap() {
    // Only toggle bottom controls if video has started and is currently playing
    if (_hasStartedPlaying && _controller.value.isPlaying) {
      setState(() {
        _showControls = !_showControls;
      });
      if (_showControls) {
        _autoHideControls();
      }
    }
    // If video hasn't started or is paused, tapping does nothing (center play button handles it)
  }

  void _autoHideControls() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _seekToStart() {
    _controller.seekTo(Duration.zero);
    setState(() {});
  }

  void _toggleMute() {
    final newVolume = _controller.value.volume == 0 ? 1.0 : 0.0;
    _controller.setVolume(newVolume);
    setState(() {});
  }

  bool get _isVideoCompleted {
    return _controller.value.position >= _controller.value.duration;
  }

  bool get _isMuted => _controller.value.volume == 0;

  bool get _showCenterPlay {
    // Show center play when:
    // - Video hasn't started yet
    // - Video is paused (and not showing bottom controls)
    // - Video is completed
    if (!_hasStartedPlaying) return true;
    if (_isVideoCompleted) return true;
    if (!_controller.value.isPlaying && !_showControls) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                  // Video layer
                  Positioned.fill(
                    child:
                        shouldConstrain
                            ? VideoPlayer(_controller)
                            : AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            ),
                  ),

                  // Center Play Button
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

                  // Bottom Controls (only when playing and toggled)
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
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress bar
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

                              // Controls row
                              Row(
                                children: [
                                  // Play/Pause button
                                  IconButton(
                                    onPressed: _togglePlayPause,
                                    icon: Icon(
                                      Icons.pause,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),

                                  // Current time / Duration
                                  Text(
                                    '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),

                                  const SizedBox(width: 20),
                                  // Mute/Unmute button
                                  IconButton(
                                    onPressed: _toggleMute,
                                    icon: Icon(
                                      _isMuted
                                          ? Icons.volume_off
                                          : Icons.volume_up,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),

                                  Spacer(),

                                  // Fullscreen button
                                  IconButton(
                                    onPressed: () {
                                      // TODO: Implement fullscreen
                                    },
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
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
