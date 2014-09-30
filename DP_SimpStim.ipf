// This is a data type that implements a simple (not compound) stimulus

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /S SimpStim(stimType,paramsAsStrings)
	String stimType
	Wave /T paramsAsStrings
	String result=stimType+":"
	
	Wave /T paramNames=SimpStimGetParamNamesFromType(stimType)
	
	Variable nParams=numpnts(paramNames)
	String thisKVPair=""
	if (nParams>0)
	       thisKVPair=paramNames[0]+"="+paramsAsStrings[0]
	       result=result+thisKVPair
	endif
	Variable i
	for (i=1; i<nParams; i+=1)
	       thisKVPair=paramNames[i]+"="+paramsAsStrings[i]
		result=result+","+thisKVPair
	endfor

	return result
End

Function /S SimpStimDefault(stimType)
	String stimType
	Wave /T paramsAsStrings=SimpStimGetDefParamsAsStrings(stimType)
	return SimpStim(stimType,paramsAsStrings)
End

Function /S SimpStimReplaceParam(simpStim,paramName,newValueAsString)
	String simpStim
	String paramName
	String newValueAsString

	// Make sure new value represents a number
	String result
	Variable newValue=str2num(newValueAsString)
	if ( IsNan(newValue) )
		result=simpStim
		return result
	endif
	
	// Replace the parameter with the new value
	String stimType=SimpStimGetStimType(simpStim)
	String paramList=SimpStimGetParamList(simpStim)	
	String newParamList=ReplaceStringByKey(paramName, paramList, newValueAsString, "=", ",", 1)		
	String newSimpStim=SimpStimFromTypeAndParamList(stimType,newParamList)
	
	// Return the new simpStim only if it's valid, otherwise use original
	Variable isValid=SimpStimAreParamsValid(newSimpStim)
	result=stringFif(isValid,newSimpStim,simpStim)
	
	return result
End

Function /S SimpStimFromTypeAndParamList(stimType,paramList)
	String stimType
	String paramList
	String result=stimType+":"+paramList	
	return result
End

Function /S SimpStimGetStimType(simpStim)
	String simpStim
	
	Variable colonIndex=strsearch(simpStim,":",0)  // 0 means start from start of string
	String stimType=simpStim[0,colonIndex-1]
	return stimType
End

Function /S SimpStimGetParamList(simpStim)
	String simpStim
	
	Variable colonIndex=strsearch(simpStim,":",0)  // 0 means start from start of string
	Variable n=strlen(simpStim)
	String paramList=simpStim[colonIndex+1,n-1]
	return paramList
End

Function /WAVE SimpStimGetParamNames(simpStim)
	String simpStim
	
	String stimType=SimpStimGetStimType(simpStim)
	Wave /T paramNames=SimpStimGetParamNamesFromType(stimType)
	return paramNames
End

Function SimpStimGetNumOfParams(simpStim)
	String simpStim
	
	String stimType=SimpStimGetStimType(simpStim)
	Wave /T paramNames=SimpStimGetParamNamesFromType(stimType)
	return numpnts(paramNames)
End

Function /WAVE SimpStimGetParamsAsStrings(simpStim)
	String simpStim
	
	Wave /T paramNames=SimpStimGetParamNames(simpStim)
	Variable nParams=numpnts(paramNames)
	String paramList=SimpStimGetParamList(simpStim)

	Make /T /FREE /N=(nParams) paramsAsStrings
	Variable i
	for (i=0; i<nParams; i+=1)
		paramsAsStrings[i]=StringByKey(paramNames[i],paramList,"=",",")
	endfor
	
	return paramsAsStrings
End

Function /WAVE SimpStimGetParams(simpStim)
	String simpStim
	
	Wave /T paramsAsStrings=SimpStimGetParamsAsStrings(simpStim)
	Wave params=NumericWaveFromTextWave(paramsAsStrings)	
	return params
End

Function /S SimpStimGetSignalType(simpStim)
	String simpStim
	String stimType=SimpStimGetStimType(simpStim)
	String signalType=SimpStimGetSignalTypeFromType(stimType)
	return signalType
End

Function SimpStimGetNumOfParamsFromType(stimType)
	String stimType
	Wave /T paramNames=SimpStimGetParamNamesFromType(stimType)
	return numpnts(paramNames)
End

Function /WAVE SimpStimGetParamNamesFromType(stimType)
	String stimType

	String paramNamesFunctionName=stimType+"GetParamNames"
	Funcref SimpStimGetParamNamesSig paramNamesFunction=$paramNamesFunctionName
	Wave paramNames=paramNamesFunction()
	
	return paramNames
End

Function /WAVE SimpStimGetParamNamesSig()
	// Placeholder function
	Abort "Internal Error: Attempt to call a SimpStimGetParamNamesSig function that doesn't exist."
End

Function /WAVE SimpStimGetDefParams(stimType)
	String stimType

	Wave defParamsAsStrings=SimpStimGetDefParamsAsStrings(stimType)
	Wave result=numericWaveFromTextWave(defParamsAsStrings)
	return result
End

Function /WAVE SimpStimGetDefParamsAsStrings(stimType)
	String stimType

	String defaultParamsFunctionName=stimType+"GetDfltParamsAsStr"
	Funcref SimpStimGetDefParamsAsStrsSig defaultParamsFunction=$defaultParamsFunctionName
	Wave defaultParams=defaultParamsFunction()
	
	return defaultParams
End

Function /WAVE SimpStimGetDefParamsAsStrsSig()
	// Placeholder function
	Abort "Internal Error: Attempt to call a SimpStimGetDefParamsAsStrsSig function that doesn't exist."
End

Function /S SimpStimGetSignalTypeFromType(stimType)
	String stimType

	String signalTypeFunctionName=stimType+"GetSignalType"
	Funcref SimpStimGetSignalTypeSig signalTypeFunction=$signalTypeFunctionName
	String signalType=signalTypeFunction()
	
	return signalType
End

Function /S SimpStimGetSignalTypeSig()
	// Placeholder function
	Abort "Internal Error: Attempt to call a SimpStimGetSignalTypeSig function that doesn't exist."
End

Function /WAVE SimpStimGetStimTypes()
	Make /T /FREE result={"Pulse", "Train", "MulTrain", "Ramp", "Sine", "Chirp", "WNoise", "PSC", "BuiltinPulse" }
	return result
End

Function /WAVE SimpStimGetDisplayStimTypes()
	Make /T /FREE result={"Pulse", "Train", "Multiple Trains", "Ramp", "Sine", "Chirp", "White Noise", "PSC", "Built-in Pulse" }
	return result
End

Function SimpStimAreParamsValidForType(stimType,params)
	String stimType
	Wave params

	String areParamsValidFunctionName=stimType+"AreParamsValid"
	Funcref SimpStimAreParamsValidSig areParamsValidFunction=$areParamsValidFunctionName
	Variable areValid=areParamsValidFunction(params)
	return areValid
End

Function SimpStimAreParamsValidSig(params)
	Wave params
	// Placeholder function
	Abort "Internal Error: Attempt to call a <stimType>AreParamsValid() function that doesn't exist."
End


Function SimpStimAreParamsValid(simpStim)
	String simpStim
	
	String stimType=SimpStimGetStimType(simpStim)
	Wave params=SimpStimGetParams(simpStim)
	Variable areValid=SimpStimAreParamsValidForType(stimType,params)
	
	return areValid
End


Function /S SimpStimGetParamAsString(simpStim,paramName)
	String simpStim
	String paramName
	
	String paramList=	SimpStimGetParamList(simpStim)
	String result=StringByKey(paramName,paramList,"=",",")
	return result
End
