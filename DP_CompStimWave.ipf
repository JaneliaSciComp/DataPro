// A compund stimulus wave is a wave that has a wave note which specifies a compound stimulus.
// If you want to change the duration or the dt for the stimulus, the wave note contains enough information
// to do this.  Each CompStimWave should obey the invariant that the wave data points match the CompStim encoded
// as a string in the wave note.
// These are treated as mutable objects.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE CompStimWave(dt,durationWanted,compStim)
	Variable dt
	Variable durationWanted
	Wave /T compStim

	Make /FREE /N=0 w	
	CompStimWaveSet(w,dt,durationWanted,compStim)
	return w
End

Function /WAVE CompStimWaveSingleton(dt,durationWanted,stimType,paramsAsStrings)
	Variable dt
	Variable durationWanted
	String stimType
	Wave /T paramsAsStrings
	
	Wave /T compStim=CompStimSingleton(stimType,paramsAsStrings)
	return CompStimWave(dt,durationWanted,compStim)
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
	SetSamplesToCompStimBang(w,compStim)
End

Function CompStimWaveSetCompStim(w,compStim)
	// Set dt and duration, recalculating the wave samples
	Wave w
	Wave /T compStim
		
	String compStimString=StringFromCompStim(compStim)
	ReplaceStringByKeyInWaveNote(w,"COMPSTIM",compStimString)
	SetSamplesToCompStimBang(w,compStim)
End

Function CompStimWaveSetParamAsString(w,segmentIndex,parameterName,valueAsString)
	Wave w
	Variable segmentIndex
	String parameterName
	String valueAsString
	
	Wave /T compStimOriginal=CompStimWaveGetCompStim(w)
	Wave /T compStim=CompStimSetParamAsString(compStimOriginal,segmentIndex,parameterName,valueAsString)
	CompStimWaveSetCompStim(w,compStim)	
End

Function /S CompStimWaveGetParamAsString(w,segmentIndex,parameterName)
	Wave w
	Variable segmentIndex
	String parameterName
	
	Wave /T compStim=CompStimWaveGetCompStim(w)
	String result=CompStimGetParamAsString(compStim,segmentIndex,parameterName)
	return result
End

Function CompStimWaveSetSegmentType(w,segmentIndex,simpStimType)
	Wave w
	Variable segmentIndex
	String simpStimType
	
	Wave /T compStimOriginal=CompStimWaveGetCompStim(w)
	Wave /T compStim=CompStimSetSegmentType(compStimOriginal,segmentIndex,simpStimType)
	CompStimWaveSetCompStim(w,compStim)	
End

Function CompStimWaveAddSegment(w,segmentType)
	Wave w
	String segmentType
	
	Wave /T compStimOriginal=CompStimWaveGetCompStim(w)
	Wave /T compStim=CompStimAddSegment(compStimOriginal,segmentType)
	CompStimWaveSetCompStim(w,compStim)
End

Function CompStimWaveDelSegment(w)
	Wave w
	
	Wave /T compStimOriginal=CompStimWaveGetCompStim(w)
	Wave /T compStim=CompStimDelSegment(compStimOriginal)
	CompStimWaveSetCompStim(w,compStim)
End

Function CompStimWaveSetEachToDefault(w)
	Wave w
	
	Wave /T theCompStim=CompStimWaveGetCompStim(w)
	Variable nStimuli=CompStimGetNStimuli(theCompStim)
	Variable i
	for (i=0; i<nStimuli; i+=1)
		String thisStimType=SimpStimGetStimType(theCompStim[i])
		theCompStim[i]=SimpStimDefault(thisStimType)
	endfor
	CompStimWaveSetCompStim(w,theCompStim)
End

Function CompStimWaveSetSegParamsAsStrs(w,segmentIndex,paramsAsStrings)
	// Sets the parameters in the special case where there is only one SimpStim
	Wave w
	Variable segmentIndex
	Wave /T paramsAsStrings
	
	Wave /T compStimOriginal=CompStimWaveGetCompStim(w)
	Wave /T compStimNew=CompStimSetSegParamsAsStrs(compStimOriginal,segmentIndex,paramsAsStrings)
	CompStimWaveSetCompStim(w,compStimNew)
End


//
// Static methods
//

//Function /WAVE CompStimWaveGetStimTypes()
//	Make /T /FREE result={"Pulse", "Train", "MulTrain", "Ramp", "Sine", "Chirp", "FroNoise", "PSC" }
//	return result
//End

//
// Private methods
//


