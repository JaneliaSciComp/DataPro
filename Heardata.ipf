#pragma rtGlobals=1		// Use modern global access method.

Macro Heardata()
setdatafolder root:DP_browser
duplicate/O/c $newwave1 waveSound
SetScale/p x,10,.2e-4,waveSound
String Timer
timer="Tues, Oct 09, 2002"
Print TIME()
PlaySound waveSound
Print TIME()
If (cmpstr ( Date(),timer)>=0)
print "hello"
else 
endif
end
