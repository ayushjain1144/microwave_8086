#Implementation of microwave using 8086 processor

##Problem Statement
System to be Designed : Microwave Oven (P5)

##Description: A Simple Microwave Oven without grill.

- User can cook at 3 different Power levels: 90%, 60%, 30%
- Press of a Power Button decrements the power level by 30 %
- 1 Press - 90%; 2 Presses – 60% ; 3 Presses – 30%; 4 Presses – 90 %;
- 4 Presses – Brings the power level back to 100 %
- The Default power level is 90%
- Power Level is varied by controlling the amount of time for which the microwave is turned on.
- Time of cooking is broken up into 10 sec slots, if power is 60% then for 6 seconds the microwave is on and rest of the 4 seconds the microwave is off.
- Time is set as multiples of 10 Mins, 1 Min, 10 Secs. For e.g. if the cooking time is 12 Minutes and 40 secs- the 10 Minutes button has to be pressed once, 1 Minute Button has to be pressed Twice and 10 seconds button has to be pressed four times.
- Once Time has been set Power cannot be modified.
- When user is setting power level or Time, the value being pressed should be displayed, and when user presses the Start button, the cooking process begins and the time left for cooking to complete is displayed.
- Once the cooking begins the door gets locked and should open only when cooking process is terminated.
- User can terminate cooking anytime by pressing the STOP button. When Stop button is pressed once cooking is aborted, timer is stopped, not cleared; cooking can be resumed by pressing Start.
- When stop is pressed twice, cooking is aborted and timer is also cleared.
- When cooking time elapses, a buzzer is sounded; pressing the Stop Button stops the buzzer.
- A Quick Start mode is available where timer or power need not be set, just Start button needs to be pressed, the default power value is taken and time is set as 30 secs, for every press of the start button time is incremented by 30 seconds.


