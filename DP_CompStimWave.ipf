// A compund stimulus wave is a wave that has a wave note which specifies a compound stimulus.
// If you want to change the duration or the dt for the stimulus, the wave note contains enough information
// to do this.  Each CompStimWave should obey the invariant that the wave data points match the CompStim encoded
// as a string in the wave note.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE CompStimWave(dt,durationWanted,compStim)
	Variable dt
	Variable durationWanted
	Wave /T compStim

	Make /FREE /N=0 w	
	CompStimWaveSet(w,dt,durationWanted,compStim)
	return w
End

//Function /WAVE CompStimWaveDefault(dt,durationWanted,simpStimType)
//	Variable dt
//	Variable durationWanted
//	String simpStimType
//
//	Make /FREE /N=0 w	
//	CompStimWaveSetCompStimToDefault(w,dt,durationWanted,simpStimType)
//	return w
//End
//
//Function CompStimWaveSetToSimpStim(w,dt,durationWanted,simpStimType)
//	// Set the compound stim wave to a stimple stimulus of type simpStimType,
//	// with default parameters
//	Wave w
//	Variable dt
//	Variable durationWanted
//	String simpStimType
//	
//	Wave params=CompStimWaveGetDefParamsFromType(simpStimType)
//	CompStimWaveSetCompStim(w,dt,durationWanted,simpStimType,params)
//End

Function CompStimWaveSet(w,dt,durationWanted,compStim)
	// Set all properties of the compound stimulus wave w
	Wave w
	Variable dt
	Variable durationWanted	
	Wave /T compStim

	String compStimString=StringFromCompStim(compStim)
	ReplaceStringByKeyInWaveNote(w,"COMPSTIM",compStimString)
	CompStimWaveSetDtAndDur(w,dt,durationWanted)		
End

Function CompStimWaveGetDt(w)
	Wave w
	return deltax(w)
End

Function CompStimWaveGetN(w)
	Wave w
	return numpnts(w)
End

Function CompStimWaveGetDuration(w)
	Wave w
	Variable n=CompStimWaveGetN(w)
	Variable dt=CompStimWaveGetDt(w)
	return (n-1)*dt
End

Function /WAVE CompStimWaveGetCompStim(w)
	Wave w
	
	String compStimString=StringByKeyInWaveNote(w,"COMPSTIM")
	return CompStimFromString(compStimString)
End

Function CompStimWaveGetNStimuli(w)
	Wave w

	Wave /T compStim=CompStimWaveGetCompStim(w)
	return CompStimGetNStimuli(compStim)
End

Function CompStimWaveSetDtAndDur(w,dt,durationWanted)
	// Set dt and duration, recalculating the wave samples
	Wave w
	Variable dt, durationWanted
		
	Variable nScans=numberOfScans(dt,durationWanted)
	Redimension /N=(nScans) w
	Setscale /P x, 0, dt, "ms", w
	
	Wave /T compStim=CompStimWaveGetCompStim(w)
	SetWaveToCompStimBang(w,dt,durationWanted,compStim)
End

//
// Static methods
//

Function /WAVE CompStimGetStimTypes(signalType)
	String signalType
	
	if ( AreStringsEqual(signalType,"DAC") )
		Make /T /FREE result={"Pulse", "Train", "MulTrain", "Ramp", "Sine", "Chirp", "WNoise", "PSC" }
	elseif ( AreStringsEqual(signalType,"TTL") )
		Make /T /FREE result={"TTLPulse", "TTLTrain", "TTLMTrain"}
	else
		Make /T /FREE /N=(0) result
	endif
	
	return result
End

//
// Private methods
//

//Function CompStimWaveSetCompStim_(w,compStim)
//	// Set the fields in the wave note that are relevant to the stimulus.  Leave any other
//	// fields alone.
//	Wave w
//	Wave /T compStim
//
//	String compStrimString=StringFromCompStim(compStim)
//	ReplaceStringByKeyInWaveNote(w,"COMPSTIM",compStimString)
//End

//Function CompStimWaveSyncSamplesFromRest_(w)
//	// Re-compute the wave in w, using the current wave dt and number of scans
//	Wave w
//		
//	Wave /T compStim=CompStimWaveGetCompStim(w)
//	SetSamplesToCompStimBang(w,compStim)
//End


//Function /S CompStimWaveGetSignalType_(w)
//	Wave w
//	String simpStimType=CompStimWaveGetType(w)
//	String signalType=CompStimWaveGetSignalTypeFromType(simpStimType)
//	return signalType
//End

