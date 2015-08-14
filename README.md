![dx11-pointcloud!](https://raw.githubusercontent.com/letmp/dx11-pointcloud/master/nodes/assets/logo.png)

DX11.Pointcloud
=================

This pack is a collection of pointcloud tools and techniques for [vvvv](http://vvvv.org/) on top of the nodes provided by [dx11-vvvv](https://github.com/mrvux/dx11-vvvv).
It emerged from a previous pack called KinectToolkitDX11 and offers much more tools for dealing with pointclouds independent of devices like Kinect(2) or other depth cameras. Its purpose is to create a central repository for modules and plugins related to pointclouds.

If you have questions or want to share an idea just head over to the vvvv contribution page of [DX11.Pointcloud](http://vvvv.org/contribution/dx11.pointcloud).

Background
==========

When dealing with pointclouds and depthcameras (like Kinect) as input device for creating pointclouds in vvvv there are some tasks that pop up again and again:
* Setup the virtual environment and calibrate the input of the kinect from the virtual to the real environment (or a projection in it).
* Extract parts of the pointcloud data and provide a realtime rendering.
* Detect events or occurences based on the pointcloud data.
* Find components that are connected to each other.
* Apply forces to the particlesystem.

This pack attempts to provide a modular foundation that can be extended and reused very easily. It included some nodes for all of the listed needs and is designed to be extended in a clear manner.
Nonetheless, the purpose of this project is to bundle the power of the vvvv community and build a comprehensive toolkit we all benefit from.

One requirement while starting this package was to be independent from big thirdparty frameworks like openframeworks or opencv. The reason for that was to keep the maintenance expenses as low as possible.

Another requirement was a high performance, so all expensive calculations are done on the GPU.

Features
==========

* clean and modular design
* visualize pointclouds in many ways
* kinect calibration for mapping realworld data to the virtual scene
* jitter filter for the depth image of the kinect device
* blobdetection and tracking
* hittests, centroids, bounds
* dynamic emission of particles
* apply forces to particles (attractors, collision-detection, deceleration, gravity, self repulsion, turbulences, vectorfields and more)

Getting Started
===============

You need:
* [vvvv](http://vvvv.org/)
* [dx11-vvvv](http://vvvv.org/contribution/directx11-nodes-alpha)

If you want to create pointclouds with real world data:
* Kinect/Kinect2

There are help patches for all included nodes that give small examples how to use them. Just highlight a node of your choice and press F1. You can also find more complex examples under /dx11.pointcloud/girlpower/

Best Practise
============

* When you start to develop additional nodes (or nodes on top of existing nodes) try to stay as modular as possible for further usage.
* Stick to the existing folder structure. (dx11 for shaders, geom11 for geometryshaders, modules for nodes,  plugins for plugins, texture11 for texture effects)
* Try to build simple helppatches that show the purpose of the developed node. You can also use the girlpower folder for more complex setups.
* Besides the existing categories (Analysis, Data, Filters, Forces, Setup, Tools, Visualization) there are alot more (Segmentation, Classification, Clustering, FeatureDetection, and so on). Don't be shy to create new folders for that.


Further development ideas
=========================

Here are some ideas that could be worth to put some effort in:
* Network nodes to distribute pointcloud data 
* Reader/Writer for reading/writing data on hdd
* Consistent indexing of points over time.

These are more sophisticated (especially on the GPU) but also very interesting:
* Meshing the pointcloud. You can find a nice summary on this topic [here](http://meshlabstuff.blogspot.de/2009/09/meshing-point-clouds.html).
* Clustering points to entities and classifying them (for example as living,lifeless,..).
* [3D Reconstruction of Indoor Environments](http://www.cs.unc.edu/~doums/pdfs/slides-3D-Room-Reconstruction-with-One-Kinect.pdf)


Problems? Questions?
====================

Feel free to ask questions in the [original thread](http://vvvv.org/contribution/dx11.pointcloud) of this pack. You can also post as guest there.
You can also contact me via skype (le-tmp) or email (robert@intolight.de).


License
=======

© intolight, 2015
![CC 4.0BY NC SAt](http://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png)

Author: intolight (robert@intolight.de)

This software is distributed under the [CC Attribution-NonCommercial-ShareAlike 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.

If this license seems to restrictive for your use case, please contact *license (at) intolight.de* and tell us about your project or your goal, so we can find a solution or an alternative license for you.
