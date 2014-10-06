// This is a data type that implements a compound stimulus.
// These are treated as _immutable_ objects.  If you change it, it returns a new and indepent one.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE CompStimEmpty()
	Make /T /FREE /N=(0) result
	return result
End

Function /WAVE CompStimFromSimpStim(simpStim)
	String simpStim	
	Make /T /FREE /N=(1) result={simpStim}
	return result
End

Function /WAVE CompStimSingleton(stimType,paramsAsStrings)
	String stimType
	Wave /T paramsAsStrings
	
	String thisSimpStim=SimpStim(stimType,paramsAsStrings)
	return CompStimFromSimpStim(thisSimpStim)
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
	Variable tEndOfLast=0	// the time at which the previous segment ended
	for (i=0; i<nStimuli; i+=1)
		String simpStim=CompStimGetSimpStim(compStim,i)
		String stimType=SimpStimGetStimType(simpStim)
		Wave /T paramsAsStrings=SimpStimGetParamsAsStrings(simpStim)
		Variable delayThis=str2num(paramsAsStrings[0])
		
		// Modify the delay so that the "delay" spec'ed by user is the delay from the end of the last segment
		Duplicate /FREE /T paramsAsStrings, paramsAsStringsShifted
		Variable compoundDelay=tEndOfLast+delayThis
		paramsAsStringsShifted[0]=sprintf1v("%0.17g",compoundDelay)		// Preserve as much precision as possible
		
		// Call the overlay function
		String overlayFunctionName=stimType+"OverlayFromParams"		
		Funcref StimulusOverlayFromParamsSig overlayFunction=$overlayFunctionName
		overlayFunction(w,paramsAsStringsShifted)
		
		// Get ready for next segment
		Variable durationThis=str2num(paramsAsStrings[1])
		tEndOfLast += (delayThis+durationThis)
	endfor
End

Function StimulusOverlayFromParamsSig(w,paramsAsStrings)
	Wave w
	Wave /T paramsAsStrings
	// Placeholder function
	Abort "Internal Error: Attempt to call a StimulusOverlayFromParamsSig function that doesn't exist."
End

Function /S CompStimGetSimpStim(compStim,i)
	Wave /T compStim
	Variable i
		
	return compStim[i]
End

Function /WAVE CompStimSetParamAsString(compStimOriginal,segmentIndex,parameterName,valueAsString)
	Wave /T compStimOriginal
	Variable segmentIndex
	String parameterName
	String valueAsString

	String simpStimOriginal=compStimOriginal[segmentIndex]
	String simpStim=SimpStimReplaceParam(simpStimOriginal,parameterName,valueAsString)
	Duplicate /T /FREE compStimOriginal, result
	result[segmentIndex]=simpStim
	
	return result
End

Function /S CompStimGetParamAsString(compStim,segmentIndex,parameterName)
	Wave /T compStim
	Variable segmentIndex
	String parameterName

	String simpStim=compStim[segmentIndex]
	String result=SimpStimGetParamAsString(simpStim,parameterName)
	
	return result
End

Function /WAVE CompStimSetSegmentType(compStimOriginal,segmentIndex,simpStimType)
	Wave /T compStimOriginal
	Variable segmentIndex
	String simpStimType

	String simpStim=SimpStimDefault(simpStimType)
	Duplicate /T /FREE compStimOriginal, result
	result[segmentIndex]=simpStim
	
	return result
End

Function /WAVE CompStimAddSegment(compStimOriginal,segmentType)
	Wave /T compStimOriginal
	String segmentType

	String simpStim=SimpStimDefault(segmentType)
	Duplicate /T /FREE compStimOriginal, result
	Variable nStimuliOriginal=CompStimGetNStimuli(compStimOriginal)
	Redimension /N=(nStimuliOriginal+1) result
	result[nStimuliOriginal]=simpStim
	
	return result
End

Function /WAVE CompStimDelSegment(compStimOriginal)
	Wave /T compStimOriginal

	Duplicate /T /FREE compStimOriginal, result
	Variable nStimuliOriginal=CompStimGetNStimuli(compStimOriginal)
	if (nStimuliOriginal>0)
		Redimension /N=(nStimuliOriginal-1) result
	endif
	
	return result
End

Function /WAVE CompStimSetSegParamsAsStrs(compStimOriginal,segmentIndex,paramsAsStrings)
	Wave /T compStimOriginal
	Variable segmentIndex
	Wave /T paramsAsStrings

	String simpStimOriginal=compStimOriginal[segmentIndex]
	String stimType=SimpStimGetStimType(simpStimOriginal)
	String thisSimpStim=SimpStim(stimType,paramsAsStrings)
	Duplicate /T /FREE compStimOriginal, result
	result[segmentIndex]=thisSimpStim
	
	return result	
End

//Function SetWaveToCompStimBang(w,dt,durationWanted,compStim)
//	Wave w
//	Variable dt
//	Variable durationWanted
//	Wave /T compStim
//	
//	Variable nScans=numberOfScans(dt,durationWanted)
//	Redimension /N=(nScans) w
//	Setscale /P x, 0, dt, "ms", w
//	SetSamplesToCompStimBang(w,compStim)
//End
