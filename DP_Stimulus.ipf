// A stimulus is a wave that has a wave note which specifies a stimulus type and a set of parameters.
// If you want to change the duration or the dt for the stimulus, the wave note contains enough information
// to do this.  Each stimulus should obey the invariant that the wave data points match the stimulus type and the
// parameters in the wave note, for some value of duration and time step.

// Eventually, all the builders should be refactored such that they rely on an underlying Stimulus 'subclass', 
// And the Sweeper should be modified to deal exclusively with Stimulus 'objects'.  But I don't have time to
// do this right now (ALT, Feb 4 2014).

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE StimulusConstructor(dt,durationWanted,stimulusType,params)
	Variable dt
	Variable durationWanted
	String stimulusType
	Wave params

	Make /FREE /N=0 w	
	StimulusInitialize(w,dt,durationWanted,stimulusType,params)
	return w
End

Function /WAVE StimulusConstructorToDefault(dt,durationWanted,stimulusType)
	Variable dt
	Variable durationWanted
	String stimulusType

	Make /FREE /N=0 w	
	StimulusInitializeToDefault(w,dt,durationWanted,stimulusType)
	return w
End

Function StimulusInitialize(w,dt,durationWanted,stimulusType,params)
	Wave w
	Variable dt
	Variable durationWanted
	String stimulusType
	Wave params
	
	StimulusSetWaveNote(w,stimulusType,params)
	StimulusResample(w,dt,durationWanted)
End

Function StimulusInitializeToDefault(w,dt,durationWanted,stimulusType)
	Wave w
	Variable dt
	Variable durationWanted
	String stimulusType
	
	Wave params=StimulusGetDefParamsFromType(stimulusType)
	StimulusInitialize(w,dt,durationWanted,stimulusType,params)
End

Function StimulusSetParamsToDefault(w)
	Wave w

	String stimulusType=StringByKeyInWaveNote(w,"WAVETYPE")
	Wave params=StimulusGetDefParamsFromType(stimulusType)
	StimulusSetWaveNote(w,StimulusGetType(w),params)
	StimulusRefill(w)
End

Function StimulusSetParams(w,params)
	// Set the named param in the named stimulusType model
	Wave w
	Wave params

	StimulusSetWaveNote(w,StimulusGetType(w),params)
	StimulusRefill(w)
End

Function StimulusSetParam(w,paramName,newValue)
	// Set the named param in the named stimulusType model
	Wave w
	String paramName
	Variable newValue

	ReplaceStringByKeyInWaveNote(w,paramName,num2str(newValue))
	StimulusRefill(w)
End

Function StimulusChangeSampling(w,dt,durationWanted)
	// Used to notify the Builder model of a change to dt or durationWanted in the Sweeper.
	Wave w
	Variable dt
	Variable durationWanted
		
	// Update the	wave
	StimulusResample(w,dt,durationWanted)
End

Function StimulusReset(w,dt,durationWanted,params)
	Wave w
	Variable dt
	Variable durationWanted
	Wave params

	StimulusSetWaveNote(w,StimulusGetType(w),params)
	StimulusResample(w,dt,durationWanted)		
End

Function /S StimulusGetType(w)
	Wave w	
	return StringByKeyInWaveNote(w, "WAVETYPE")
End

Function StimulusGetDt(w)
	Wave w
	return deltax(w)
End

Function StimulusGetN(w)
	Wave w
	return numpnts(w)
End

Function StimulusGetDuration(w)
	Wave w
	Variable n=StimulusGetN(w)
	Variable dt=StimulusGetDt(w)
	return (n-1)*dt
End

Function /WAVE StimulusGetParamNames(w)
	Wave w
	
	String stimulusType=StringByKeyInWaveNote(w,"WAVETYPE")
	Wave /T paramNames=StimulusGetParamNamesFromType(stimulusType)
	return paramNames
End

Function StimulusGetNumOfParams(w)
	Wave w
	
	Wave /T paramNames=StimulusGetParamNames(w)
	return numpnts(paramNames)
End

Function /WAVE StimulusGetParams(w)
	Wave w
	
	Wave /T paramNames=StimulusGetParamNames(w)
	Variable nParams=numpnts(paramNames)

	Make /FREE /N=(nParams) params
	Variable i
	for (i=0; i<nParams; i+=1)
		params[i]=NumberByKeyInWaveNote(w,paramNames[i])
	endfor
	
	return params
End





//
// Private methods
//

Function StimulusSetWaveNote(w,stimulusType,params)
	// Set the fields in the wave note that are relevant to the stimulus.  Leave any other
	// fields alone.
	Wave w
	String stimulusType
	Wave params

	//Note /K w
	ReplaceStringByKeyInWaveNote(w,"WAVETYPE",stimulusType)
	//ReplaceStringByKeyInWaveNote(w,"TIME",time())
	
	// Set the params in the wave note
	Wave /T paramNames=StimulusGetParamNamesFromType(stimulusType)
	
	Variable nParams=numpnts(paramNames)
	Variable i
	for (i=0; i<nParams; i+=1)
		ReplaceStringByKeyInWaveNote(w,paramNames[i],num2str(params[i]))
	endfor
End

Function StimulusResample(w,dt,durationWanted)
	// Re-compute the wave in w, using the given dt, durationWanted, and the
	// param values stored in the wave note of w itself.
	Wave w
	Variable dt, durationWanted
		
	Variable nScans=numberOfScans(dt,durationWanted)
	Redimension /N=(nScans) w
	Setscale /P x, 0, dt, "ms", w
	
	Wave params=StimulusGetParams(w)
	StimulusFillFromParams(w,params)
End

Function StimulusFillFromParamsSig(w,params)
	// Placeholder function
	Wave w
	Wave params
	Abort "Internal Error: Attempt to call a StimulusFillFromParamsSig function that doesn't exist."
End

Function StimulusRefill(w)
	// Re-compute the wave in w, using the current wave dt and number of scans
	Wave w
		
	Wave params=StimulusGetParams(w)
	StimulusFillFromParams(w,params)
End

Function StimulusFillFromParams(w,params)
	Wave w
	Wave params
		
	String stimulusType=StringByKeyInWaveNote(w,"WAVETYPE")
	String fillFunctionName=stimulusType+"FillFromParams"
	Funcref StimulusFillFromParamsSig fillFunction=$fillFunctionName
	fillFunction(w,params)
End

Function /S StimulusGetSignalType(w)
	Wave w
	String stimulusType=StimulusGetType(w)
	String signalType=StimulusGetSignalTypeFromType(stimulusType)
	return signalType
End






//
// Class methods
//

Function StimulusGetNumOfParamsFromType(stimulusType)
	String stimulusType
	Wave /T paramNames=StimulusGetParamNamesFromType(stimulusType)
	return numpnts(paramNames)
End

Function /WAVE StimulusGetParamNamesFromType(stimulusType)
	String stimulusType

	String paramNamesFunctionName=stimulusType+"GetParamNames"
	Funcref StimulusGetParamNamesSig paramNamesFunction=$paramNamesFunctionName
	Wave paramNames=paramNamesFunction()
	
	return paramNames
End

Function /WAVE StimulusGetParamNamesSig()
	// Placeholder function
	Abort "Internal Error: Attempt to call a StimulusGetParamNamesSig function that doesn't exist."
End

Function /WAVE StimulusGetDefParamsFromType(stimulusType)
	String stimulusType

	String defaultParamsFunctionName=stimulusType+"GetDfltParams"
	Funcref StimulusGetDfltParamsSig defaultParamsFunction=$defaultParamsFunctionName
	Wave defaultParams=defaultParamsFunction()
	
	return defaultParams
End

Function /WAVE StimulusGetDfltParamsSig()
	// Placeholder function
	Abort "Internal Error: Attempt to call a StimulusGetDfltParamsSig function that doesn't exist."
End

Function /S StimulusGetSignalTypeFromType(stimulusType)
	String stimulusType

	String signalTypeFunctionName=stimulusType+"GetSignalType"
	Funcref StimulusGetSignalTypeSig signalTypeFunction=$signalTypeFunctionName
	String signalType=signalTypeFunction()
	
	return signalType
End

Function /S StimulusGetSignalTypeSig()
	// Placeholder function
	Abort "Internal Error: Attempt to call a StimulusGetSignalTypeSig function that doesn't exist."
End

