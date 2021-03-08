# Assembly-Multi-Threading-drones-single-target-game
A group of N drones which see the same target from different points of view and from different distance. Each drone tries to detect where is the target on the game board, in order to destroy it.
Drones may destroy the target only if the target is in drone’s field-of-view, and if the target is no more than some maximal distance from the drone. When the current target is destroyed, some new target appears on the game board in some randomly chosen place. The first drone that destroys T targets is the winner of the game. Each drone is associated with Assembly User-Level Threads (Coroutines).


https://www.cs.bgu.ac.il/~caspl192/Assignments/Assignment_3
