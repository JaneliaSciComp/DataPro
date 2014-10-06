DataPro
=======

Package of Igor Pro scripts for doing data acquisition using
Instrutech ITC 18 or ITC 16.  Also includes an optional imaging module
for using the Andor iXon Ultra camera via the Bruxton Corporation SIDX
7.2 API.  DataPro only works with the Windows version of Igor Pro 6,
and development and testing has all been done on the 32-bit version of
Igor Pro.





How to Install
--------------

1. Make sure you have the Igor Pro XOPs that you need installed.  For
   the ITC 16, you need the Igor Pro 6 legacy ITC 16 XOP:

       http://www.heka.com/instrutech/IgorXOPs/Win/ITC16_X86_XOP.zip

   For the ITC 18, you need the Igor Pro 6 legacy ITC 18 XOP:

       http://www.heka.com/instrutech/IgorXOPs/Win/ITC18_X86.zip

   If you want to do imaging (which currently only works with the
   Andor iXon Ultra camera), you need the Bruxton Corporation SIDX
   7.2 XOP, which costs money:

       http://www.bruxton.com/SIDX/index.html  

2. Unzip the DataPro-release_8.21.zip file, which creates a folder called 
   DataPro-release_8.21.

3. Copy the folder DataPro-release_8.21 to the "Igor Pro 6 User Files"
   folder.  (You must copy the whole folder, not just the files within
   the folder.)

4. In experiments where you want to use this version of DataPro, add
   the line

     #include ":DataPro-release_8.21:DataPro"

   to the experiment's procedure file.  You can access this from the
   Igor Pro menu by going to
   Windows > Procedure Windows > Procedure Window.  (Note: You will
   have to do this for each experiment and/or template that you want
   to use this version of DataPro with.  Usually it's best to create a
   template where you've added the above line to the template's
   procedure file.)

If DataPro is installed correctly, you should have a menu item called
"DataPro" in the Igor Pro main menu.

To get started using DataPro, select "All Controls" from the "DataPro"
menu.





Intended Workflow
-----------------

Once DataPro is installed, we recommend that you create an Igor Pro
packed experiment template for each type of recording session you plan
to do.  Start Igor Pro, and add the line:

  #include ":DataPro-release_8.21:DataPro"

to the procedure file.  You can access this from the Igor Pro menu by
going to Windows > Procedure Windows > Procedure Window.  Set up all
the windows the way you like them, and set up any stimuli you'll need
for that type of recording session.  Then go to File > Save Experiment
As..., then set the "Save as type:" field to "Packed Experiment
Template (*.pxt)").

Then, at the start of each recording session, open the template, and
immediately save the experiment as an _unpacked_ experiment (File >
Save Experiment As..., then set the "Save as type:" field to "Unpacked
Experiment File (*.uxp)").  Then use DataPro to collect the data, and
finally use DataPro to collect the data, and save the Igor Pro
experiment when done (File > Save).  (If you feel you understand the
tradeoffs involved between packed and unpacked experiments in Igor
Pro, you can save your experiments as packed experiments, but we
recommed saving them as unpacked experiments.)

If you want to go back and browse your data, simply open the .uxp file
in Igor Pro, and use the "Sweep:" control in a Signal Browser window
to browse the traces.

If you know what you're doing, you don't have to use DataPro as
outlined here, but generally speaking your life will be easier if you
do.





Multiple Versions
-----------------

DataPro is designed so that if at some point you upgrade to a new
version, and you've been using it as outlined above, your experiments
using the older version will still open in Igor Pro without issue. But
note that you need to keep the older version of Igor Pro in your "Igor
Pro 6 User Files" folder.  Each saved experiment file that uses
DataPro contains a pointer (of sorts) to the version of DataPro that
was used to create it.  Your older experiments will still use the
older version of DataPro.

After installing a new version of DataPro, you _will_ have to manually
recreate your templates (described above), modifying the Procedure
Window in each to point to the newer version.  We realize this is kind
of a pain.

At present, there is no easy way to use a newer version of DataPro to
browse an experiment created with an older version.  This can
sometimes be made to more-or-less work with some hacking, but best not
to try this unless you know what you're doing.  And we probably can't
help you if you try this and it leads to tears.  And whatever you do,
don't modify one of your old experiment files without making a copy of
the original first.





Copyright Notice
----------------

All files included in DataPro are Copyright (c) 1998-2014, Nelson
Spruston and Adam L. Taylor.
All rights reserved.





License
-------

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies, 
either expressed or implied, of the Howard Hughes Medical Institute.





Release History
---------------

7.00   (August 23, 2012)

Initial release of DataPro at Janelia Farm.





7.00 -> 7.01    (August 24, 2012)

Aquiring a sweep now updates all DataPro browser windows.

Reduced minimum y limits in Test Pulse Display from [-1,+1] to [-0.2,+0.2].

Updated installation instructions.





7.01 -> 7.02     (August 31, 2012)

Mainly code refactoring.  Some minor user-facing changes.





7.02 -> 7.03     (March 7, 2013)

Improved in many, many ways.  This release marks the completion of 
"Phase I" of the DataPro project at Janelia.





7.03 -> 7.04     (March 11, 2013)

Added a Switcher to work with Axon Instruments computer-controlled amplifier.
DataPro now gets initialized after a compile instead of on Igor Pro start up, 
which is more generally appropriate.

DataPro used to not allow you to turn of all input channels, or all output 
channels, in the Sweeper.  It now allows you to do this, but disables the 
Get Data until you turn on at least one input and one output channel.




7.04 -> 7.05    (May 14, 2013)

Made it easier for a single user to use different versions of DataPro
without going insane.




7.05 -> 7.06    (June 3, 2013)

Added Chirp Builder, Multiple Train Builder, Multiple TTL Train
Builder.  Split Train Builder in Train Builder and TTL Train Builder.
Renamed Step Builder to Stair Builder.  In general, each builder is
now designed for either analog output or TTL output, but not both.

Reimplemented how many of the builder outputs are constructed, for
greater robustness.




7.06 -> 7.07    (June 4, 2013)

Small change to builders that have discontinuities in their outputs,
to make them more predictable in the common case.




7.07 -> 7.08    (September 11, 2013)

Added history to the Sweeper.  Similar to the stimHistory in 
DataPro 6, but contains more information.




7.08 -> 7.09    (September 13, 2013)

Added more precise date/time information to acquired ADC waves.




7.09 -> 7.10    (October 11, 2013)

Made ramp builder slightly more flexible.




7.10 -> 7.11    (November 5, 2013)

Added white noise builder.




7.11 -> 8.00    (February 11, 2014)

Added imaging module, for imaging with Andor iXon Ultra camera.




8.00 -> 8.10    (February 24, 2014)

Enhanced imaging module to read frames from camera as they come in,
not all at end.  This allows users to acquire videos longer than 500
frames. 




8.10 -> 8.11    (February 27, 2014)

Added ability to export videos as TIFF files.  "Get Data" button is
now disabled if doing triggered video acquisition and the sweep
duration is not long enough to accommodate the video.




8.11 -> 8.12    (March 11, 2014)

Fixed bug where DataPro wouldn't compile until SIDX XOP was present.
Also fixed some bugs with faux camera operation.




8.12 -> 8.13    (May 12, 2014)

White noise stimulus builder now supports bandpass filtering.




8.13 -> 8.14    (June 27, 2014)

Added a Train-with-Prepulse builder.




8.14 -> 8.15    (June 27, 2014)

Manually merged in barrage silencing code, but commented out in master
branch.




8.15 -> 8.2    (October 1, 2014)

Added compound stimulus builder.




8.2 -> 8.21    (October 4, 2014)

Fixed bugs.  Added ability to use a saved wave as a simple stimulus,
with proper interpolation as needed.
