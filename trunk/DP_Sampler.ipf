#pragma rtGlobals=1		// Use modern global access method.

Function SamplerConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O/S root:DP_Sampler
	
	// Auto-detect the ITC version present
	// itc is 16 if ITC-16 is being used, 18 if ITC-18, and 0 if neither is present
	// If neither is present, DataPro runs in "demo" mode.
	Variable /G itc=detectITCVersion()
	Variable /G usPerDigitizerClockTick=((itc<18)?1:1.25)

	// Restore the original data folder
	SetDataFolder savedDF
End

Function /WAVE SamplerSampleData(adseq,daseq,seqLength,FIFOoutFree)
	// The heart of the data acquisition.
	String adseq
	String daseq
	Variable seqLength
	Wave FIFOoutFree
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sampler

	NVAR itc
	NVAR usPerDigitizerClockTick
	WAVE FIFOout, FIFOin	// wave references to bound waves that don't exist yet.

	// Duplicate FIFOoutFree into a bound wave
	Duplicate /O FIFOoutFree, FIFOout

	// Make the FIFOin wave (cannot be free)
	Variable nSamplesFIFO=numpnts(FIFOout)
	Variable dtFIFO=deltax(FIFOout)
	Make /O /N=(nSamplesFIFO) FIFOin
	SetScale /P x, 0, dtFIFO, "ms", FIFOin

	// Calculate the number of digitizer clock ticks per FIFO sampling interval
	// If this is not an integer, that is a problem
	Variable usPerFIFODt=1000*dtFIFO	// us
	Variable nDigitizerClockTicksPerDtWant=usPerFIFODt/usPerDigitizerClockTick
	Variable nDigitizerClockTicksPerDt=round(nDigitizerClockTicksPerDtWant)	
	if (abs(nDigitizerClockTicksPerDtWant-nDigitizerClockTicksPerDt)>0.001)
		// Can't sample at that rate, given the digitizer settings.
		// The FIFO dt has to be an integer multiple of the digitizer dt, and that integer has to be >=4.
		// Abort, but suggest a sampling rate to the user that will work.
		Variable dtRecommended
		if (nDigitizerClockTicksPerDt>=4)
			dtRecommended=nDigitizerClockTicksPerDt*usPerDigitizerClockTick*seqLength/1000;		// ms
		else
			dtRecommended=4*usPerDigitizerClockTick*seqLength/1000;		// ms
		endif
		Abort sprintf3fff("The FIFO sampling interval, %0.2f us, is not an integer multiple of the digitizer clock interval, %0.2f us.  Setting the sampling interval to %0.5f ms will fix this.",usPerFIFODt,usPerDigitizerClockTick,dtRecommended)
	endif
	if (nDigitizerClockTicksPerDt<4)
		Abort sprintf2ff("Cannot sample that fast.  The given sampling parameters result in a FIFO sampling interval of %0.2f us, and the shortest possible FIFO sampling interval is %0.2f.  Increase the sampling interval, or use fewer channels.",usPerFIFODt,4*usPerDigitizerClockTick)
	endif
	
	String commandLine
	if (itc==0)
		WAVE stepPulse
		FIFOin=sin(0.05*x)+gnoise(0.1)+stepPulse+5
	elseif (itc==16)
		Execute "ITC16StimClear 0"
		//Execute "ITC16Seq daseq, adseq"
		sprintf commandLine "ITC16Seq \"%s\", \"%s\"", daseq, adseq
		Execute commandLine
		sprintf commandLine, "ITC16StimAndSample FIFOout, FIFOin, %d, 14", nDigitizerClockTicksPerDt
		Execute commandLine
		Execute "ITC16StopAcq"
	elseif (itc==18)
		// might need to change acqflags to 14 to make this work
		//Execute "ITC18StimClear 0"  // ALT, 2012/05/23
		//Execute "ITC18Seq daseq, adseq"
		sprintf commandLine "ITC18Seq \"%s\", \"%s\"", daseq, adseq
		Execute commandLine
		Execute "ITC18Stim FIFOout"
		sprintf commandLine, "ITC18StartAcq %d,2,0", nDigitizerClockTicksPerDt
		Execute commandLine
		Execute "ITC18Samp FIFOin"
		Execute "ITC18StopAcq"
	else
		// do nothing
	endif
	
	// Copy the FIFOin wave to a free wave, then delete the non-free wave
	Duplicate /FREE FIFOin, FIFOinFree
	KillWaves FIFOin, FIFOout
	
	SetDataFolder savedDF
	return FIFOinFree
End

