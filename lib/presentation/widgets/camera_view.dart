import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  final CameraController? controller;
  final CustomPaint? customPaint;
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onZoomChanged;

  const CameraView({
    super.key,
    required this.controller,
    this.customPaint,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          _buildZoomControl(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final controller = widget.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(
      controller,
      child: widget.customPaint,
    );
  }

  Widget _buildZoomControl() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 250,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Slider(
                  value: widget.currentZoom,
                  min: widget.minZoom,
                  max: widget.maxZoom,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                  onChanged: widget.onZoomChanged,
                ),
              ),
              Container(
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      '${widget.currentZoom.toStringAsFixed(1)}x',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
