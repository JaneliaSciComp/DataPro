// This is a data type that implements a compound stimulus.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE CompStim()
	Make /T /FREE /N=(0) result
	return result
End

Function /WAVE CompStimFromSimpStim(simpStim)
	String simpStim
	
	Make /T /FREE /N=(0) result
	CompStimAppendStimString(result,simpStim)
	return result
End

Function /S StringFromCompStim(compStim)
	Wave /T compStim

	String result=""
	Variable nStimuli=numpnts(compStim)
	if (nStimuli>0)
		result=compStim[0]
	endif
	Variable i
	for (i=1; i<nStimuli; i+=1)
		result=result+";"+compStim[i]
	endfor

	return result
End

Function /WAVE CompStimFromString(compStimString)
	String compStimString
	
	Variable nStimuli=ItemsInList(compStimString,";")
	Make /T /FREE /N=(nStimuli) result
	result=StringFromList(p,compStimString,";")
	return result
End

Function /WAVE CompStimAppendStimString(compStim,stimString)
	Wave /T compStim
	String stimString
	
	Variable nStimuliOriginal=CompStimGetNStimuli(compStim)
	Variable nStimuli=nStimuliOriginal+1
	Duplicate /T /FREE compStim, result
	Redimension /N=(nStimuli) result
	result[nStimuliOriginal]=stimString
	return result
End

Function CompStimGetNStimuli(compStim)
	Wave /T compStim
	return numpnts(compStim)
End

Function SetSamplesToCompStimBang(w,compStim)
	Wave w
	Wave /T compStim
	
	w=0
	
	Variable nStimuli=CompStimGetNStimuli(compStim)
	Variable i
	for (i=1; i<nStimuli; i+=1)
		String simpStim=CompStimGetSimpStim(compStim,i)
		String stimType=SimpStimGetStimType(simpStim)
		Wave params=SimpStimGetParams(simpStim)
		String overlayFunctionName=stimType+"OverlayFromParams"
		
		Funcref StimulusOverlayFromParamsSig overlayFunction=$overlayFunctionName
		overlayFunction(w,params)
	endfor
End

Function /WAVE StimulusOverlayFromParamsSig(w,params)
	Wave w
	Wave params
	// Placeholder function
	Abort "Internal Error: Attempt to call a StimulusOverlayFromParamsSig function that doesn't exist."
End

Function /S CompStimGetSimpStim(compStim,i)
	Wave /T compStim
	Variable i
		
	return compStim[i]
End

Function SetWaveToCompStimBang(w,dt,durationWanted,compStim)
	Wave w
	Variable dt
	Variable durationWanted
	Wave /T compStim
	
	Variable nScans=numberOfScans(dt,durationWanted)
	Redimension /N=(nScans) w
	Setscale /P x, 0, dt, "ms", w
	SetSamplesToCompStimBang(w,compStim)
End
