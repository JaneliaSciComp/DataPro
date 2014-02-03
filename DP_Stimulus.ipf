// A stimulus is a wave that has a wave note which specifies a builder type and a set of parameters.
// If you want to change the duration or the dt for the stimulus, the wave note contains enough information
// to do this.  Each stimulus should obey the invariant that the wave data points match the builder and the
// parameters in the wave note, for some value of duration and time step.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function StimulusInitialize(theWave,dt,totalDuration,stimulusType,parameters)
	Wave theWave
	Variable dt
	Variable totalDuration
	String stimulusType
	Wave parameters	
		
End

Function StimulusInitialize(theWave)
	Wave theWave
	Abort "Internal Error: Attempt to call a function that doesn't exist."
End

Function StimulusSetParameter(w,stimulusType,parameterName,value)
	// Set the named parameter in the named stimulusType model
	String stimulusType
	String parameterName
	Variable value

	String savedDF=GetDataFolder(1)
	String dataFolderName=sprintf1s("root:DP_%sBuilder",stimulusType)
	SetDataFolder $dataFolderName

	WAVE parameters
	WAVE /T parameterNames

	// Set the parameter in the parameters wave
	Variable nParameters=numpnts(parameters)
	Variable i
	for (i=0; i<nParameters; i+=1)
		if (AreStringsEqual(parameterName,parameterNames[i]))
			parameters[i]=value
		endif
	endfor

	// Update the wave
	StimulusUpdateWave(stimulusType)

	SetDataFolder savedDF
End

Function StimulusChangeSampling(w,stimulusType,dt,totalDuration)
	// Used to notify the Builder model of a change to dt or totalDuration in the Sweeper.
	String stimulusType
	Variable dt
	Variable totalDuration
		
	// Update the	wave
	StimulusUpdateWave(stimulusType,dt,totalDuration)
End






//
// Private methods
//

Function StimulusUpdateWave(theWave,stimulusType)
	// Updates the theWave wave to match the model parameters.
	// This is a private _model_ method -- The view updates itself when theWave changes.
	String stimulusType
	
	String savedDF=GetDataFolder(1)
	String dataFolderName=sprintf1s("root:DP_%sBuilder",stimulusType)
	SetDataFolder $dataFolderName
	
	WAVE /T parameterNames
	WAVE parameters
	WAVE theWave
	NVAR dt, totalDuration
		
	StimulusResampleFromParams(stimulusType,theWave,dt,totalDuration,parameters,parameterNames)
	
	Note /K theWave
	ReplaceStringByKeyInWaveNote(theWave,"WAVETYPE",stimulusType)
	ReplaceStringByKeyInWaveNote(theWave,"TIME",time())
	
	// Set the parameters in the wave note
	Variable nParameters=numpnts(parameters)
	Variable i
	for (i=0; i<nParameters; i+=1)
		ReplaceStringByKeyInWaveNote(theWave,parameterNames[i],num2str(parameters[i]))
	endfor
	SetDataFolder savedDF
End

Function StimulusResample(w,stimulusType,dt,totalDuration)
	// Re-compute the wave in w, using the given dt, totalDuration, and the
	// parameter values stored in the wave note of w itself.
	String stimulusType
	Wave w
	Variable dt, totalDuration
	
	String savedDF=GetDataFolder(1)
	String dataFolderName=sprintf1s("root:DP_%sBuilder",stimulusType)
	SetDataFolder $dataFolderName
	
	WAVE /T parameterNames
	
	Variable nParameters=numpnts(parameterNames)
	Make /FREE /N=(nParameters) parametersFromW
	Variable i
	for (i=0; i<nParameters; i+=1)
		parametersFromW[i]=NumberByKeyInWaveNote(w,parameterNames[i])
	endfor
	
	StimulusResampleFromParams(stimulusType,w,dt,totalDuration,parametersFromW,parameterNames)

	SetDataFolder savedDF	
End

Function StimulusResampleFromParams(w,stimulusType,dt,totalDuration,parameters)
	// Re-compute the wave in w using the given dt, totalDuration, and parameters
	// This is a class method.
	String stimulusType
	Wave w
	Variable dt,totalDuration
	Wave parameters
	
	Variable nScans=numberOfScans(dt,totalDuration)
	Redimension /N=(nScans) w
	Setscale /P x, 0, dt, "ms", w
	
	String fillFunctionName=stimulusType+"FillFromParams"
	Funcref StimulusFillFromParams fillFunction=$fillFunctionName
	fillFunction(w,dt,nScans,parameters,parameterNames)
End

Function StimulusFillFromParams(w,parameters)
	// Placeholder function
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames	
	Abort "Internal Error: Attempt to call a function that doesn't exist."
End


