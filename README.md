KinectToolkitDX11
=================

This pack is a collection of kinect tools and techniques on top of the nodes provided by [dx11-vvvv](https://github.com/mrvux/dx11-vvvv).
Its purpose is to create a central repository for modules related to the usage of the kinect with [vvvv](http://vvvv.org/).

Background
==========

When using the kinect as input device for the development of applications in vvvv there are some tasks that pop up again and again:
* Setup the virtual environment and calibrate the input of the kinect from the virtual to the real environment (or a projection in it).
* Extract parts of the pointcloud data from the kinect and provide a (colored) preview.
* Detect events or occurences based on the pointcloud data.

This toolkit attempts to provide a modular foundation that can be extended and reused very easily. The initial version already included some nodes for all of the listed needs and is designed to be extended in a clear manner.
Nonetheless, the purpose of this project is to bundle the power of the vvvv community and build a comprehensive toolkit we all benefit from.

One requirement while starting this package was to be independent from big thirdparty frameworks like openframeworks or opencv. The reason for that was to keep the maintenance expenses as low as possible.

Another requirement was a high performance, so all expensive calculations are done on the GPU.

Features
==========
* clean and modular design
* visualize pointclouds with arbitrary geometries
* detect collisions
* detect blobs and track them
* automatic or semiautomatic kinect-to-realworld calibration 

Getting Started
===============

You need:
* the kinect device (everything should also work with kinect2 - but this is not tested yet)
* [vvvv](http://vvvv.org/) (vvvv_45beta_33 - 32bit/64bit)
* [dx11-vvvv](http://vvvv.org/contribution/directx11-nodes-alpha)

There are help patches for all included nodes that give small examples how to use them. For the beginning it is recommendable to look at the Pointcloud and Detection helppatches.
The calibration is a bit more advanced, but well documented as well. Also check out the included girlpower folder for more complex examples.

Some words about the Visualization nodes
=====================================

At this moment there a 3 different nodes to visualize the kinect data. All of them are capable to filter out points by simply putting in filter transforms.

1. The Pointcloud (DX11.Texture) node creates a simple colored pointcloud layer that can be rendered directly. Additionally it outputs a 2d texture that contains all (filtered)
points where the world coordinates are encoded in its RGB values.

2. The Pointcloud (DX11.Buffer) also creates a pointcloud layer with the advantage that you can use arbitrary geometries for each point. Additionally it outputs the number of vertices, a buffer containing
the pointcloud data and an indexbuffer that can be used in further shaders.

3. The Mesh (DX11.Buffer) creates a colored mesh layer and outputs a buffer of triangles for further usage.

At this point the Detection nodes use the Pointcloud (DX11.Texture) node but it would be easy to adapt them with the DX11.Buffers as input. 

Best Practise
============
* When you start to develop additional nodes (or nodes on top of existing nodes) try to stay as modular as possible for further usage.
* If your new node uses foreign contributions (modules,plugins,..) put them in the ThirdParty folder. 
* Try to build simple helppatches that show the purpose of the developed node. You can also use the girlpower folder for more complex setups.
* Besides the existing categories (Detection, Pointcloud, Setup) there are alot more (IO, Tracking, Segmentation, Classification, Clustering, FeatureDetection, and so on). Don't be shy to create new folders for that.

Further development ideas
=========================

Here are some ideas that could be worth to put some effort in:
* Meshing the pointcloud. You can find a nice summary on this topic [here](http://meshlabstuff.blogspot.de/2009/09/meshing-point-clouds.html). Another idea is to put the cloud into a 3dTexture and use a marching cubes algorithm.
* Consistent indexing of points over time.
* Recording and replaying pointcloud-data.

These are more sophisticated (especially on the GPU) but also very interesting:
* Clustering points to entities and classifying them (for example as living,lifeless,..).
* [3D Reconstruction of Indoor Environments](http://www.cs.unc.edu/~doums/pdfs/slides-3D-Room-Reconstruction-with-One-Kinect.pdf)

License
=======

© intolight, 2014
![CC 4.0BY NC SAt](http://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png)

Author: intolight (robert@intolight.de)

This software is distributed under the [CC Attribution-NonCommercial-ShareAlike 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.

If this license seems to restrictive for your use case, please contact *license (at) intolight.de* and tell us about your project or your goal, so we can find a solution or an alternative license for you.
