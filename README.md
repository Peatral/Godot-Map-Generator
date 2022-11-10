# Map Generator

This map generator roughly follows [this](http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/) article.
It uses a custom GDExtension addon that provides a faster C++ implementation of Poisson-Disc-Sampling and a Delaunator. 
Originally used GDScript implementations, [this](https://github.com/hiulit/Delaunator-GDScript/blob/master/Delaunator.gd) for the 
Delaunator and a custom one for the PDS algorithm. The move to C++ improved the speed of the generator roughly by 50%-60%.