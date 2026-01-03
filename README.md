# **B**ill's **R**robot **O**perator

A direct fork of [The official Lerobot](https://github.com/huggingface/lerobot), but with some modifications that are specific to my use case: 

## 1 Separation of "edge" processes and "cloud" processes.
* edge processes are operating the robot, managing servos and USB ports, generating telemetry
* cloud processes are better for systems like Azure _(not yet implemented)_
  * Training models
  * Visualizing datasets (not live)
  * Real time analytics in tools Graphana or Fabric

## 2 Running on a smaller footprint at the edge
I'm building for a smaller machine like a NUC or a RaspberyPii.
