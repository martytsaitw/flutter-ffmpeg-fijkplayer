/*
 * Copyright (c) 2020 Taner Sener
 *
 * This file is part of FlutterFFmpeg.
 *
 * FlutterFFmpeg is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FlutterFFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with FlutterFFmpeg.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:io';

import 'package:flutter_ffmpeg_fijkplayer/log.dart';
import 'package:flutter_ffmpeg_fijkplayer/statistics.dart';
import 'package:flutter_ffmpeg_fijkplayer_example/abstract.dart';
import 'package:flutter_ffmpeg_fijkplayer_example/flutter_ffmpeg_api_wrapper.dart';
import 'package:flutter_ffmpeg_fijkplayer_example/player.dart';
import 'package:flutter_ffmpeg_fijkplayer_example/popup.dart';
import 'package:flutter_ffmpeg_fijkplayer_example/tooltip.dart';
import 'package:flutter_ffmpeg_fijkplayer_example/video_util.dart';
import 'package:video_player/video_player.dart';

import 'util.dart';

enum _State { IDLE, CREATING, BURNING }

class SubtitleTab implements PlayerTab {
  VideoPlayerController _videoPlayerController;
  RefreshablePlayerDialogFactory _refreshablePlayerDialogFactory;
  Statistics _statistics;
  _State _state;
  int _executionId;

  void init(RefreshablePlayerDialogFactory refreshablePlayerDialogFactory) {
    _refreshablePlayerDialogFactory = refreshablePlayerDialogFactory;
    _statistics = null;
    _state = _State.IDLE;
    _executionId = 0;
  }

  void setActive() {
    print("Subtitle Tab Activated");
    enableLogCallback(logCallback);
    enableStatisticsCallback(statisticsCallback);
    showPopup(SUBTITLE_TEST_TOOLTIP_TEXT);
  }

  void logCallback(Log log) {
    ffprint(log.message);
    _refreshablePlayerDialogFactory.refresh();
  }

  void statisticsCallback(Statistics statistics) {
    this._statistics = statistics;
    updateProgressDialog();
  }

  void burnSubtitles() {
    VideoUtil.assetPath(VideoUtil.ASSET_1).then((image1Path) {
      VideoUtil.assetPath(VideoUtil.ASSET_2).then((image2Path) {
        VideoUtil.assetPath(VideoUtil.ASSET_3).then((image3Path) {
          VideoUtil.assetPath(VideoUtil.SUBTITLE_ASSET).then((subtitlePath) {
            getVideoFile().then((videoFile) {
              getVideoWithSubtitlesFile().then((videoWithSubtitlesFile) {
                // IF VIDEO IS PLAYING STOP PLAYBACK
                pause();

                try {
                  videoFile.delete().catchError((_) {});
                } on Exception catch (_) {}

                try {
                  videoWithSubtitlesFile.delete().catchError((_) {});
                } on Exception catch (_) {}

                ffprint("Testing SUBTITLE burning");

                showCreateProgressDialog();

                final ffmpegCommand = VideoUtil.generateEncodeVideoScript(
                    image1Path,
                    image2Path,
                    image3Path,
                    videoFile.path,
                    "mpeg4",
                    "");

                ffprint(
                    "FFmpeg process started with arguments\n\'$ffmpegCommand\'.");

                _state = _State.CREATING;

                executeAsyncFFmpeg(ffmpegCommand,
                    (int executionId, int returnCode) {
                  ffprint("FFmpeg process exited with rc $returnCode.");

                  hideProgressDialog();

                  if (returnCode == 0) {
                    ffprint(
                        "Create completed successfully; burning subtitles.");

                    String burnSubtitlesCommand =
                        "-y -i ${videoFile.path} -vf subtitles=$subtitlePath:force_style='FontName=MyFontName' -c:v mpeg4 ${videoWithSubtitlesFile.path}";

                    showBurnProgressDialog();

                    ffprint(
                        "FFmpeg process started with arguments\n\'$burnSubtitlesCommand\'.");

                    _state = _State.BURNING;

                    executeAsyncFFmpeg(burnSubtitlesCommand,
                        (int executionId, int returnCode) {
                      ffprint("FFmpeg process exited with rc $returnCode.");
                      hideProgressDialog();

                      if (returnCode == 0) {
                        ffprint(
                            "Burn subtitles completed successfully; playing video.");
                        playVideo();
                      } else if (returnCode == 255) {
                        showPopup("Burn subtitles operation cancelled.");
                        ffprint("Burn subtitles operation cancelled");
                      } else {
                        showPopup(
                            "Burn subtitles failed. Please check log for the details.");
                        ffprint("Burn subtitles failed with rc=$returnCode.");
                      }
                    }).then((value) {
                      _executionId = executionId;
                    });
                  }
                }).then((int executionId) {
                  _executionId = executionId;
                  ffprint(
                      "Async FFmpeg process started with executionId $executionId.");
                });
              });
            });
          });
        });
      });
    });
  }

  Future<void> playVideo() async {
    if (_videoPlayerController != null) {
      await _videoPlayerController.initialize();
      await _videoPlayerController.play();
    }
    _refreshablePlayerDialogFactory.refresh();
  }

  Future<void> pause() async {
    if (_videoPlayerController != null) {
      await _videoPlayerController.pause();
    }
    _refreshablePlayerDialogFactory.refresh();
  }

  Future<File> getSubtitleFile() async {
    final String subtitle = "subtitle.srt";
    Directory documentsDirectory = await VideoUtil.tempDirectory;
    return new File("${documentsDirectory.path}/$subtitle");
  }

  Future<File> getVideoFile() async {
    final String video = "video.mp4";
    Directory documentsDirectory = await VideoUtil.documentsDirectory;
    return new File("${documentsDirectory.path}/$video");
  }

  Future<File> getVideoWithSubtitlesFile() async {
    final String video = "video-with-subtitles.mp4";
    Directory documentsDirectory = await VideoUtil.documentsDirectory;
    return new File("${documentsDirectory.path}/$video");
  }

  void showCreateProgressDialog() {
    // CLEAN STATISTICS
    _statistics = null;
    resetStatistics();
    _refreshablePlayerDialogFactory.dialogShowCancellable(
        "Creating video", () => cancelExecution(_executionId));
  }

  void showBurnProgressDialog() {
    // CLEAN STATISTICS
    _statistics = null;
    resetStatistics();
    _refreshablePlayerDialogFactory.dialogShowCancellable(
        "Burning subtitles", () => cancelExecution(_executionId));
  }

  void updateProgressDialog() {
    if (_statistics == null) {
      return;
    }

    int timeInMilliseconds = this._statistics.time;
    if (timeInMilliseconds > 0) {
      int totalVideoDuration = 9000;

      int completePercentage = (timeInMilliseconds * 100) ~/ totalVideoDuration;

      if (_state == _State.CREATING) {
        _refreshablePlayerDialogFactory
            .dialogUpdate("Creating video % $completePercentage");
      } else if (_state == _State.BURNING) {
        _refreshablePlayerDialogFactory
            .dialogUpdate("Burning subtitles % $completePercentage");
      }
      _refreshablePlayerDialogFactory.refresh();
    }
  }

  void hideProgressDialog() {
    _refreshablePlayerDialogFactory.dialogHide();
  }

  @override
  void setController(VideoPlayerController controller) {
    _videoPlayerController = controller;
  }
}
