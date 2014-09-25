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

Function /S SimpStimReplaceParam(stimString,paramName,newValueAsString)
	String stimString
	String paramName
	String newValueAsString

	String result
	Variable newValue=str2num(newValueAsString)
	if ( IsNan(newValue) )
		result=stimString
		return result
	endif

	String stimType=SimpStimGetStimType(stimString)
	String paramList=SimpStimGetParamList(stimString)
	
	String newParamList=ReplaceStringByKey(paramName, paramList, newValueAsString, "=", ",", 1)		
	result=SimpStimFromTypeAndParamList(stimType,newParamList)
	
	return result
End

Function /S SimpStimFromTypeAndParamList(stimType,paramList)
	String stimType
	String paramList
	String result=stimType+":"+paramList	
	return result
End

Function /S SimpStimGetStimType(stimString)
	String stimString
	
	Variable colonIndex=strsearch(stimString,":",0)  // 0 means start from start of string
	String stimType=stimString[0,colonIndex-1]
	return stimType
End

Function /S SimpStimGetParamList(stimString)
	String stimString
	
	Variable colonIndex=strsearch(stimString,":",0)  // 0 means start from start of string
	Variable n=strlen(stimString)
	String paramList=stimString[colonIndex+1,n-1]
	return paramList
End

Function /WAVE SimpStimGetParamNames(stimString)
	String stimString
	
	String stimType=SimpStimGetStimType(stimString)
	Wave /T paramNames=SimpStimGetParamNamesFromType(stimType)
	return paramNames
End

Function SimpStimGetNumOfParams(stimString)
	String stimString
	
	String stimType=SimpStimGetStimType(stimString)
	Wave /T paramNames=SimpStimGetParamNamesFromType(stimType)
	return numpnts(paramNames)
End

Function /WAVE SimpStimGetParamsAsStrings(stimString)
	String stimString
	
	Wave /T paramNames=SimpStimGetParamNames(stimString)
	Variable nParams=numpnts(paramNames)
	String paramList=SimpStimGetParamList(stimString)

	Make /T /FREE /N=(nParams) paramsAsStrings
	Variable i
	for (i=0; i<nParams; i+=1)
		paramsAsStrings[i]=StringByKey(paramNames[i],paramList,"=",",")
	endfor
	
	return paramsAsStrings
End

Function /WAVE SimpStimGetParams(stimString)
	String stimString
	
	Wave /T paramsAsStrings=SimpStimGetParamsAsStrings(stimString)
	Wave params=NumericWaveFromTextWave(paramsAsStrings)	
	return params
End

Function /S SimpStimGetSignalType(stimString)
	String stimString
	String stimType=SimpStimGetStimType(stimString)
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

	String defaultParamsFunctionName=stimType+"GetDefaultParamsAsStrings"
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

