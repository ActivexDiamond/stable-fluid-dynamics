# Stable Fluid Dynamics Library
A Lua/Love2D physics simulation of stable fluids implenting Jos Stam's paper on the subject.
Can be run as a stand-alone sandbox to explore the concept or used as a Lua library to implement this behavior into your own game or project.

## Demo
![Demo Gif](https://user-images.githubusercontent.com/21343576/171421351-f40dc529-ceb9-4027-90f5-ccbad66b9371.gif)

## Controls
- LMB -> Add static density source.
- RMB -> Add density source with a random velocity.
- LMB + Shift -> Remove density.
- RMB + Shift -> Remove velocity.

Note: Currently, once a source is added there is no way to remove or modify it. (WIP)

## References
A pure-Lua implementation of Jos Stam's 2003 paper "Real-Time Fluid Dynamics for Games"
The paper (online): https://www.dgp.toronto.edu/public_user/stam/reality/Research/pdf/GDC03.pdf

Special thanks to Gonkee's video for introducing me to this concept and paper.
"But how do fluid simulations work?" https://www.youtube.com/watch?v=qsYE1wMEMPA

Gonkee's channel: https://www.youtube.com/channel/UCG2IoSJBUhrGL8fb5stMCWw

