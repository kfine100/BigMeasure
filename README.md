# BigMeasure
MATLAB 80 channel oscilloscope GUI using National Instruments digitizers

BigMeasure

Purpose
BigMeasure records up to 80 channels of digitizer data. It is a GUI written in MATLAB. It functions much like an oscilloscope with various kinds of triggers. It is meant to be operated with different external digitizers from National Instruments, although it can work with others supported by the MATLAB Data Acquisition Toolbox. Several digitizers can be setup to operate simultaneously controlled from one computer running BigMeasure. For more info on how to wire the digitizers see BigMeasure Trigger Configurations.pptx.

It can save data in .mat format and reload the data for easy viewing. The user can save names for each channel (such as “Mic 8” or “Top Detector”) which get saved in the output. This make further analysis and plotting easy when the .mat file is imported.

Another convenient feature is configuration saving and recalling. You can save all settings such as channel names, voltage scales, and trigger settings. With 80 channels this is a big time savings.


How to run it

First of all you need a working copy of MATLAB along with the Data Acquisition Toolbox. If you have that, then you start MATLAB and simply navigate to a directory with all of the files and launch the script BigMeasure.m. This will display the BigMeasure GUI and you are off and running.
If there is no digitizer attached, BigMeasure automatically enters into a mode where it creates its own random data. Since this looks realistic, I added FAKE DATA in red letters so there is no confusion. The fake data mode is a good way to begin and use the interface.


Connecting a digitizer

The big step is always connecting the digitizer. The MATLAB data engine has to enter into a dialog with it and connect correctly. Sometimes this can take a little fiddling around. One problem may be that your digitizer may require different setup parameters than those in the program. If this is the case, some reprogramming will be involved. Take a look at the routine GetDevices and modify that routine.

My goal is to have others use BigMeasure and update GetDevices.m to work with a maximum set of digitizers. Please contact me if you have problem connecting to your digitizer and I will try to help.


Memory problems

This program has been heavily used and debugged. One sticky problem occurs when really large data sets are taken. This program was written for use with the MATLAB 32-bit data acquisition engine, which means the useable address space is limited to around 2 GB. In practice, you can repeat ably take 500 MB data captures without problems. For larger data captures the program crashes after a few runs. This problem would be solved if the data acquisition engine was 64 bit, but MATLAB has the problem that the vendors (like NI) have been slow in upgrading their software to 64 bit. It might be that now MATLAB has gotten to 64 bit, and if so, let me know.
