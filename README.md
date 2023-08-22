# Anari Metal

## About The Project

This is an [Anari](https://github.com/KhronosGroup/ANARI-SDK) device implementation on top of Apple's [Metal](https://developer.apple.com/metal/) library. It uses a classical forward renderer with no postprocessing effects.

### Limitations

The project is currently in an early stage of development, and so there are some limitations to it.

1. Only triangle geometry is supported
2. The frames's color and depth format is always RGBA8_sRGB and Depth32Float respectively
3. Only directional light is supported
4. Volumes aren't rendered
5. Command buffers and encoders are created separatelly for every blit command, which is very inefficient
6. Loading RGB images does not work, since Metal does only support formats with 2^ bit count
7. anariViewer renders only the upper right quarter of the example, most likely because of Retina screens
8. All the images are rendered upside down, will be fixed soon
9. The 'Matte' material is currently the same as PBM material

## Getting Started

### Installation

1. Build the project
    ```
    cd /path/to/anari_metal
    mkdir build
    cd build
    cmake --build . -t install
    ```

## License

Distributed under the Apache License. See `LICENSE.txt` for more information.

## Contact

Samuel Žúbor - samuliak77@gmail.com

Project Link: [https://github.com/SamoZ256/anari_metal](https://github.com/SamoZ256/anari_metal)