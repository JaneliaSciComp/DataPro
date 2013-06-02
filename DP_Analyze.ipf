//	DataPro Analysis
//	Adapted from BAD_ASS
//	(Browse, Analyze Data, and Average Selected Sweeps, Nelson Spruston, 8/95)
//	DataPro Analyze began 8/24/99

#pragma rtGlobals=1		// Use modern global access method.

//________________________DataPro Analyze ______________________//

Function AnalyzeButtonProc(ctrlName) : ButtonControl
	String ctrlName
	Execute "Analysis()"
End

//Function GraphColors(thename, sweep, rval, gval, bval)
//	String thename
//	Variable sweep, rval, gval, bval
//	String thewave=thename+num2istr(sweep)
//	ModifyGraph rgb($thewave)=(rval,gval,bval)
//	ModifyGraph /Z grid(left)=1
//	ModifyGraph /Z tickUnit(bottom)=1
//	ModifyGraph /Z tickUnit(left)=1
//End

//Function SummonMeasurePanel(bStruct) : ButtonControl
//	STRUCT WMButtonAction &bStruct
//	
//	if (bStruct.eventCode!=2)
//		return 0							// we only handle mouse up in control
//	endif
//	String browserName=bStruct.win;
//	Variable browserNumber=BrowserNumberFromName(browserName);
//	PauseUpdate; Silent 1		// building window...
//	String measurePanelName=sprintf1d("MeasurePanel%d",browserNumber)
//	if (PanelExists(measurePanelName))
//		DoWindow /F $measurePanelName
//	else
//		String createPanel
//		sprintf createPanel "MeasurePanel(%d)" browserNumber
//		Execute createPanel
//	endif
//	UpdateMeasurements(browserNumber)
//End

//Function SummonToolsPanel(bStruct) : ButtonControl
//	STRUCT WMButtonAction &bStruct
//	
//	if (bStruct.eventCode!=2)
//		return 0							// we only handle mouse up in control
//	endif
//	String browserName=bStruct.win;
//	Variable browserNumber=BrowserNumberFromName(browserName);
//	PauseUpdate; Silent 1		// building window...
//	String toolsPanelName=sprintf1d("ToolsPanel%d",browserNumber)
//	if (PanelExists(toolsPanelName))
//		DoWindow /F $toolsPanelName
//	else
//		String createPanel
//		sprintf createPanel "ToolsPanel(%d)" browserNumber
//		Execute createPanel
//	endif
//	//UpdateTools(browserNumber)
//End

//Function AverageOld(ctrlName) : ButtonControl
//	String ctrlName
//	PauseUpdate; Silent 1		// building window...
//	String createpanel
//	createpanel="AveragePanel()"
//	if (wintype("AveragePanel")!=7)
//		Execute createpanel
//	else
//		DoWindow /F AveragePanel
//	endif
//	DoWindow /F DataBrowser
//End

//Function UpdateMeasurementsAndFit(browserNumber)
//	Variable browserNumber  // the index of the DP browser instance
//
//	UpdateMeasurements(browserNumber)
//	UpdateFit(browserNumber)
//End

//Function UpdateRise(svStruct) : SetVariableControl
//	// Called when the user changes the sweep number in the DPBrowser, 
//	// which first changes iCurrentSweep.
//	STRUCT WMSetVariableAction &svStruct	
//	if ( svStruct.eventCode==-1 ) 
//		return 0
//	endif	
//	String browserName=svStruct.win
//	Variable browserNumber=BrowserNumberFromName(browserName)
//	UpdateMeasurements(browserNumber)	
//End


Function DataBrowser_Help()
	String AbortMessage
	AbortMessage="To get help, open the 'DataBrowser_Help' file (as a help file) or "
	AbortMessage+= "double click on the icon in the finder.  After doing so, 'DataBrowser_Help' "
	AbortMessage+= "will appear under 'Help Windows' in the Igor 'Windows' pulldown"
	Abort AbortMessage
End

//-------------------------USEFUL ANALYSIS UTILITIES-------------------------//

Function SetDataUnits(match,units)
	String match, units
	String list, command
	list=Wavelist(match,",","")
	sprintf command "SetScale d 0,0,\"%s\" %s", units, list
	print command
	Execute command
End

Function GetRidofGraphAxes()
	ModifyGraph noLabel=2,axThick=0
End

//Function DisplaySeries(name,first,n,left,top,right,bottom)
//	String name, wave
//	Variable first=0, n=1, left=0, top=0, right=700, bottom=500
//	iterate(n)
//		sprintf wave "%s%d", name, first+i
//		if (i==0)
//			Display /W=(left,top,right,bottom) $wave
//			PauseUpdate
//		else
//			Append $wave
//		endif
//	loop
//	Modify rgb=(0,0,0)
//	Modify axThick=0
//	Modify noLabel=2
//	Modify lsize=0.7
//End

Function KillWindows()
	Silent 1
	String name, list
	String win
	Variable index=0
	list = Winlist("*",";","WIN:7")
	do
		// get the next window
		win = GetStrFromList(list, index, ";")
		if (strlen(win) == 0)
			break
		else
			DoWindow /K $win
		endif
		index += 1
	while (1) // loop until break above
End

Function KillWavesWithName(name)
	String name
	String list, match
	Silent 1
	String wave
	Variable index=0
	sprintf match "%s*", name
	list = Wavelist(match,";","")
	do
		// get the next wave
		wave = GetStrFromList(list, index, ";")
		if (strlen(wave) == 0)
			break
		else
			KillWaves $wave
		endif
		index += 1
	while (1) // loop until break above
End

Function Inflection(wave,level,left,right)
//	Finds inflection point of a wave
	String wave
	Variable level, left, right
	String diff
	sprintf diff, "diff_%s", wave[0]
	Duplicate /O $wave $diff
	Smooth/S=4/E=3 7, $diff
	Differentiate $diff
	FindLevel /Q/R=(left,right) $diff, level
	return V_LevelX
End

Function niceround(x)
	Variable x
	do
		if (x<5)
			x=round(x)
			break
		endif
		if (x<10)
			x=round(x/5)*5
			break
		endif
		if (x<50)
			x=round(x/10)*10
			break
		endif
		if (x<100)
			x=round(x/25)*25
			break
		endif
		if (x<250)
			x=round(x/50)*50
			break
		else
			x=round(x/100)*100
		endif
	while(0)
	return x
End

//-----------------------Calibrator from Wavemetrics------------------------//

Function InitCalibratorGlobals()
	String/G u_xaxis="bottom",u_yaxis="left"
	Variable/G/D u_dx=1,u_dy=1
	Variable/G u_orient=3,u_label=3	// lower-left, print with units
End

Proc Calibrator()
	if (exists("u_xaxis")<2)
		InitCalibratorGlobals()
	endif
	WMCalibrator()
End

Proc WMCalibrator(xaxis,yaxis,dx,dy,orient,label)
	String xaxis=u_xaxis, yaxis=u_yaxis
	Variable/D dx=u_dx,dy=u_dy
	Variable orient=u_orient,label=u_label
	Prompt xaxis,"X axis (horizontal axis)",popup,HVAxisList("",1)	//  only horizontal axes
	Prompt yaxis,"Y axis (vertical axis)",popup,HVAxisList("",0)	//  only vertical axes
	Prompt dx,"calibrator X length, or 0 for none"
	Prompt dy,"calibrator Y length, or 0 for none"
	Prompt orient,"Orientation",popup,"upper-left;upper-right;lower-right;lower left;"
	Prompt label,"print values",popup,"don’t print;print;print with units;print with units and ,K,m,µ etc"
	
	PauseUpdate;Silent 1
	u_xaxis=xaxis;u_yaxis=yaxis
	u_dx=dx;u_dy=dy
	u_orient=orient;u_label=label
	
	FCalibrator(xaxis,yaxis,dx,dy,orient,label)
End

// Replace "Function" with "Macro" to reduce compile time
Function FCalibrator(xaxis,yaxis,dx,dy,orient,label)
	String xaxis,yaxis
	Variable/D dx,dy
	Variable orient,label	// see popup list of Calibrator macro for label values (1 is don't print, etc)
	
	// Put calibrator in upper right corner of graph
	Variable/D xorig,yorig	// corner of calibrator
	Variable/D px,py		// polygon origin
	Variable/D hx,hy,vx,vy	// text origins
	Variable/D sf=0.15		// inset from upper-right corner
	GetAxis/Q $xaxis;xorig=V_max-(V_max-V_min)*sf
	GetAxis/Q $yaxis;yorig=V_max-(V_max-V_min)*sf

	GraphNormal			// Forces deselection
	SetDrawEnv gstart		// gstart can't be on next line!
	SetDrawEnv xcoord= $xaxis,ycoord= $yaxis, fillpat=0,linethick=2, linefgc=(0,0,0)
	if(orient == 1) // upper-left
		xorig -= dx
		hx= xorig + dx/2
		vy= yorig - dy/2
		px= xorig;py=yorig-dy
		DrawPoly px,py, 1, 1, {0,0,0,dy,dx,dy}
	endif
	if(orient == 2) // upper-right
		hx= xorig - dx/2
		vy= yorig - dy/2
		px= xorig-dx;py=yorig
		DrawPoly px,py, 1, 1, {0,0,dx,0,dx,-dy}
	endif
	if(orient == 3) // lower-right
		yorig -= dy
		hx= xorig - dx/2
		vy= yorig + dy/2
		px= xorig;py=yorig+dy
		DrawPoly px,py, 1, 1, {0,0,0,-dy,-dx,-dy}
	endif
	if(orient == 4) // lower left
		xorig -= dx
		yorig -= dy
		hx= xorig + dx/2
		vy= yorig + dy/2
		px= xorig+dx;py=yorig
		DrawPoly px,py, 1, 1, {0,0,-dx,0,-dx,dy}
	endif
	String labelVal,fmt,units
	// horizontal calibrator value
	if( (dx != 0)%& (label>1) )		// label == 1 is don't print
		units= AxisUnits(xaxis)
		fmt="%g"
		if( (label== 3) %& (strlen(units)>0) )	// 3 is print with units
			fmt += " "+units
		endif
		if(label == 4)				// 4 is print with units and prefixes
			fmt="%.1W1P"+units	// change %.1 to number of digits after decimal point you want (%.2 is two digits, etc)
		endif
		sprintf labelVal, fmt, dx
		hy = yorig-(0.1*dy)
		Variable yj=0	// bottom
		if( orient >= 3 )
			yj= 2		// top
		endif
		SetDrawEnv xcoord= $xaxis,ycoord= $yaxis,textxjust=1,textyjust=yj
		DrawText hx,hy, labelVal
	endif
	// vertical calibrator value
	if( (dy != 0)%& (label>1) )
		units= AxisUnits(yaxis)
		fmt="%g"
		if( (label== 3) %& (strlen(units)>0) )
			fmt += " "+units
		endif
		if(label == 4)
			fmt="%.1W1P"+units
		endif
		sprintf labelVal, fmt, dy
		vx= xorig+(0.1*dx)
		Variable xj=0,rot=0					// left	| use rot= -90 for top-to-bottom
		if( (orient == 1) %| (orient == 4) )	// "upper-left; upper-right;lower-right;lower left;"
			xj= 0								// right use rot=90 for bottom-to-top
		endif
		SetDrawEnv xcoord= $xaxis,ycoord= $yaxis,textxjust= xj,textyjust=1,textrot=rot
		DrawText vx,vy, " "+labelVal+" "	// extra spaces to keep label away from line
	endif
	SetDrawEnv gstop
End

Function CountItemsInList(theList)
        String theList
        Variable i=0
        do
                if (strlen(GetStrFromList(theList, i, ";")) == 0)
                        break
                endif
                i += 1
        while(1)
        return i
end

Function CountWaves(BaseStr)
       String BaseStr
 	return CountItemsInList(GetSweepList(BaseStr))
end

Function /S GetSweepList(BaseStr)
	String BaseStr
	String SweepList
	String firstList, item, back
       Variable xx, i
	firstList = WaveList(BaseStr+"*", ";","")
//	removes all items from the list that do not have the form BaseStr+number
      SweepList = ""
      i =0
      	do
       	item = GetStrFromList(firstList, i, ";")
		if (strlen(item) == 0)
                        break
              else
			xx = str2num(item[strlen(BaseStr),99])
			back = BaseStr+num2str(xx)
			if (abs(cmpstr(item,back))<1)
				SweepList += item+";"
			endif
		endif
		i += 1
	while(1)
	return SweepList
End


