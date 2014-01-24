#pragma rtGlobals=1		// Use modern global access method.

Function SamplerConstructor()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_Sampler"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O/S root:DP_Sampler
	
	// Auto-detect the ITC version present
	// itc is 16 if ITC-16 is being used, 18 if ITC-18, and 0 if neither is present
	// If neither is present, DataPro runs in "demo" mode.
	Variable /G itc=detectITCVersion()
	Variable /G usPerDigitizerClockTick=((itc<18)?1:1.25)
	Variable /G ttlBackground=0		// How the TTLs will be set when not actively sampling
		// This is interpreted as a 16-bit unsigned integer

	// Restore the original data folder
	SetDataFolder savedDF
End



Function SamplerGetNearestPossibleDt(dtWanted,sequenceLength)
	// Get the closest dt to the given one that can be performed by the hardware,
	// given the other sampling parameters
	Variable dtWanted		// the desired sampling interval, in ms
	Variable sequenceLength	// The common length of the AD and DA sequences, after reconciliation

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sampler

	NVAR usPerDigitizerClockTick
	
	// Calculate the number of digitizer clock ticks per FIFO sampling interval
	// This has to be an integer, and has to be >=4
	Variable dtFIFOWanted=dtWanted/sequenceLength
	Variable usPerFIFODtWanted=1000*dtFIFOWanted	// us
	Variable nDigitizerClockTicksPerDtWanted=usPerFIFODtWanted/usPerDigitizerClockTick
	// The FIFO dt has to be an integer multiple of the digitizer dt, and that integer has to be >=4.
	// Find the closest possible nDigitizerClockTicksPerDt
	Variable nDigitizerClockTicksPerDtDoable=max(4,round(nDigitizerClockTicksPerDtWanted))
	Variable dtDoable=nDigitizerClockTicksPerDtDoable*usPerDigitizerClockTick*sequenceLength/1000;		// ms
	SetDataFolder savedDF
	return dtDoable
End



Function /WAVE SamplerSampleData(adSequence,daSequence,FIFOoutFree)
	// The heart of the data acquisition.
	String adSequence
	String daSequence
	Wave FIFOoutFree
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sampler

	NVAR itc
	NVAR usPerDigitizerClockTick
	//WAVE FIFOout, FIFOin	// wave references to bound waves that don't exist yet.

	// Duplicate FIFOoutFree into a bound wave
	Duplicate /O FIFOoutFree, FIFOout

	// Make the FIFOin wave (cannot be free)
	Variable nSamplesFIFO=numpnts(FIFOout)
	Variable dtFIFO=deltax(FIFOout)
	Make /O /N=(nSamplesFIFO) FIFOin
	SetScale /P x, 0, dtFIFO, "ms", FIFOin

	// Calculate the number of digitizer clock ticks per FIFO sampling interval
	// This must be an integer, and must be >=4, or problems will ensue
	Variable usPerFIFODt=1000*dtFIFO	// us
	Variable nDigitizerClockTicksPerDt=round(usPerFIFODt/usPerDigitizerClockTick)
	if (nDigitizerClockTicksPerDt<4)
		Abort "Requested sampling rate is faster than the hardware can achieve.."
	endif
	
	String commandLine
	if (itc==0)
		FIFOin=sin(0.05*x)+gnoise(0.1)
	elseif (itc==16)
		Execute "ITC16StimClear 0"
		//Execute "ITC16Seq daSequence, adSequence"
		sprintf commandLine "ITC16Seq \"%s\", \"%s\"", daSequence, adSequence
		Execute commandLine
		sprintf commandLine, "ITC16StimAndSample FIFOout, FIFOin, %d, 14", nDigitizerClockTicksPerDt
		Execute commandLine
		Execute "ITC16StopAcq"
	elseif (itc==18)
		// might need to change acqflags to 14 to make this work
		//Execute "ITC18StimClear 0"  // ALT, 2012/05/23
		//Execute "ITC18Seq daSequence, adSequence"
		sprintf commandLine "ITC18Seq \"%s\", \"%s\"", daSequence, adSequence
		Execute commandLine
		Execute "ITC18Stim FIFOout"
		sprintf commandLine, "ITC18StartAcq %d,2,0", nDigitizerClockTicksPerDt
		Execute commandLine
		Execute "ITC18Samp FIFOin"
		Execute "ITC18StopAcq"
	else
		// do nothing
	endif
	
	// Set the TTL signals back to the background settings
	SamplerSyncTTLOutputToBG()
	
	// Copy the FIFOin wave to a free wave, then delete the non-free wave
	Duplicate /FREE FIFOin, FIFOinFree
	KillWaves FIFOin, FIFOout
	
	SetDataFolder savedDF
	return FIFOinFree
End



Function SamplerSetBackgroundTTLOutput(ttlOutputIndex,newValue)
	// Sets a TTL output to a set level (which should be either 0 or 1)
	Variable ttlOutputIndex
	Variable newValue

	// Save, set DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sampler

	// Declare the instance variables we need
	NVAR itc
	NVAR ttlBackground

	// Modify ttlBackground
	ttlBackground = (ttlBackground & ~(2^ttlOutputIndex)) + newValue*(2^ttlOutputIndex)
		// Part before the + clears the bit, then we add back what we want
	
	// Set the output, using the method appropriate for the current amp
	SamplerSyncTTLOutputToBG()

	// Restore the original DF	
	SetDataFolder savedDF
End



Function SamplerGetTTLBackground()
	// Save, set DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sampler

	// Declare the instance variables we need
	NVAR ttlBackground

	// Get the value
	Variable value=ttlBackground

	// Restore the original DF	
	SetDataFolder savedDF
	
	// Return the value
	return ttlBackground
End


Function SamplerEpiLightTTLOutputChanged()
	SamplerSetBackgroundTTLOutput(EpiLightGetTTLOutputIndex(),EpiLightGetIsOn())
End

//
// Private methods
//
Function SamplerSyncTTLOutputToBG()
	// This tells the digitizer to set it's TTL outputs to match the ttlBackground instance var
	Variable ttlOutputIndex
	Variable newValue

	// Save, set DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sampler

	// Declare the instance variables we need
	NVAR itc
	NVAR ttlBackground

	// Set the output, using the method appropriate for the current amp
	if (itc==0)
		// Do nothing
	elseif (itc== 16)
		Execute sprintf1v("ITC16WriteDigital1 %d",ttlBackground)	// Hopefully this operator exists
	elseif (itc==18)
		Execute sprintf1v("ITC18WriteDigital1 %d",ttlBackground)
	else
		Abort "Internal error when trying to set a TTL output.  Contact the DataPro developer(s)."
	endif

	// Restore the original DF	
	SetDataFolder savedDF
End

