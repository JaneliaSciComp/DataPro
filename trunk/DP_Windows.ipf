//	DataPro//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18//	Nelson Spruston//	Northwestern University//	project began 10/27/1998//	last updated 1/12/2000//______________________________DataPro Acquire WINDOWS __________________________//Function RaiseOrCreatePanel(panelName)	String panelName		if (PanelExists(panelName))		DoWindow /F $panelName	else		Execute "Create"+panelName+"Panel()"	endifEndFunction CreateDataProPanel() : Panel	PauseUpdate; Silent 1		// building window...	NewPanel /W=(2,45,177,547) /N=DataPro /K=1	ModifyPanel /W=DataPro fixedSize=1	SetDrawLayer UserBack	DrawPICT 1,0,1,1,DataProMenu	SetDrawEnv fillfgc= (56797,56797,56797)	DrawRect 1.102,-0.46,-0.108,-0.08	DrawLine -0.112,-0.157,1.078,-0.157	SetDrawEnv gstart	SetDrawEnv linefgc= (65535,65535,0),fillfgc= (65535,65535,0),fname= "Helvetica",fsize= 36,fstyle= 1,textrgb= (0,43690,65535)	DrawText 16,49,"DataPro"	SetDrawEnv gstop	SetDrawEnv fsize= 10,fstyle= 1,textrgb= (65535,65535,0)	DrawText 24,426,"data acquisition and"	SetDrawEnv fsize= 10,fstyle= 1,textrgb= (65535,65535,0)	DrawText 24,446,"analysis macros for"	SetDrawEnv fsize= 10,fstyle= 1,textrgb= (65535,65535,0)	DrawText 24,466,"use with Igor Pro &"	SetDrawEnv fsize= 10,fstyle= 1,textrgb= (65535,65535,0)	DrawText 24,486,"Instrutech ITC16/18"	DrawLine -0.11,-0.29,1.08,-0.29	Button data_button,pos={24,205},size={120,20},proc=DataButtonProc,title="Acquire"	Button adc_dac_button,pos={24,235},size={120,20},proc=ADC_DACButtonProc,title="ADC/DAC control"	Button tp_button,pos={24,265},size={120,20},proc=TPWinButtonProc,title="Test pulse"	Button pulse_button,pos={24,295},size={120,20},proc=DACBuilderButtonProc,title="DAC Pulse Builder"	//Button imaging_button,pos={24,325},size={120,20},proc=ImagingButtonProc,title="Imaging"	//Button analyze_button,pos={24,355},size={120,20},proc=AnalyzeButtonProc,title="Analyze"EndFunction CreateDataAcqPanel() : Panel	Silent 1		// building window...	String savDF=GetDataFolder(1)	SetDataFolder root:DP_ADCDACcontrol	NewPanel /W=(757,44,1051,430) /K=1 /N=DataAcqPanel as "Data Acquisition Panel"	ModifyPanel /W=DataAcqPanel fixedSize=1	CheckBox autoAnalyzeCheckBox,pos={180,1},size={58,14},title="Auto Analyze On"	CheckBox autoAnalyzeCheckBox,variable=autoAnalyzeChecked	GroupBox DataAcqGroup,pos={6,3},size={279,88},title="Data Acquisition"	SetVariable iSweep_val,pos={130,23},size={100,15},title="next sweep"	SetVariable iSweep_val,format="%d"	SetVariable iSweep_val,limits={0,10000,1},value= iSweep	SetVariable setvar1,pos={135,183},size={115,15},title="samp. int."	SetVariable setvar1,limits={0.001,100,0.01},value=sintsp	SetVariable set_sweep_interval,pos={138,50},size={140,15},title="one every n seconds"	SetVariable set_sweep_interval,limits={1,10000,1},value= root:DP_ADCDACcontrol:sweep_interval	//SetVariable set_comments,pos={12,69},size={270,15},title="comments"	//SetVariable set_comments,value= root:DP_ADCDACcontrol:wave_comments	GroupBox SubtractionGroup,pos={6,94},size={279,40},title="P/N subtraction"	CheckBox pn_check,pos={49,111},size={54,14},title="pN sub.",value= 0	SetVariable pnsetvar0,pos={151,110},size={70,15},title="pN"	SetVariable pnsetvar0,value= root:DP_ADCDACcontrol:pn	GroupBox StepPulseGroup,pos={6,139},size={280,71},title="StepPulse_DAC"	SetVariable spamp,pos={22,161},size={95,15},proc=DPampProc,title="step amp."	SetVariable spamp,limits={-1000,10000,10},value= root:DP_ADCDACcontrol:spamp	SetVariable spdur,pos={131,161},size={120,15},proc=DPdurProc,title="step. dur."	SetVariable spdur,limits={1e-05,100000,100},value= root:DP_ADCDACcontrol:spdur	GroupBox SynPulseGroup,pos={6,213},size={280,49},title="SynPulse_DAC"	SetVariable syntime,pos={38,234},size={85,15},title="time"	SetVariable syntime,limits={0,1000,10},value= root:DP_ADCDACcontrol:syntime	SetVariable syndur,pos={146,234},size={80,15},title="dur."	SetVariable syndur,limits={0.001,10,0.1},value= root:DP_ADCDACcontrol:syndur	GroupBox TestPulseGroup,pos={5,266},size={280,111},title="Test Pulse"	SetVariable setvar0,pos={9,313},size={100,15},title="samp. int."	SetVariable setvar0,limits={0.01,100,0.01},value= root:DP_ADCDACcontrol:sinttp	CheckBox tp_bsub,pos={183,283},size={58,14},title="Base Sub"	CheckBox tp_bsub,value=1	CheckBox tpgate_check,pos={183,357},size={58,14},proc=TPgateCheckProc,title="Use Gate"	CheckBox tpgate_check,value=0	SetVariable tpamp,pos={142,300},size={130,15},proc=TPampProc,title="amplitude"	SetVariable tpamp,limits={-1000,1000,1},value= root:DP_ADCDACcontrol:tpamp	SetVariable tpdur,pos={152,319},size={120,15},title="duration (ms)"	SetVariable tpdur,limits={1,1000,1},value= root:DP_ADCDACcontrol:tpdur	SetVariable tpgate,pos={142,339},size={130,15},proc=TPampProc,title="gate amp."	SetVariable tpgate,limits={-1000,1000,1},value= root:DP_ADCDACcontrol:tpgateamp	SetVariable test_adc,pos={10,353},size={90,15},title="show ADC"	SetVariable test_adc,limits={0,7,1},value= root:DP_ADCDACcontrol:testadc	SetVariable test_dac,pos={19,333},size={80,15},title="use DAC"	SetVariable test_dac,limits={0,7,1},value= root:DP_ADCDACcontrol:testdac	Button getdatabutton0,pos={19,22},size={80,20},proc=DataAcqButtonProc,title="Get Data"	Button start_tp_button0,pos={13,283},size={80,20},proc=TPStartButtonProc,title="Start"	SetVariable set_numacquire,pos={13,51},size={120,15},title="repeat n times"	SetVariable set_numacquire,value= root:DP_ADCDACcontrol:nSweepsPerTrial	SetDataFolder savDFEndFunction TestPulseDisplay() : Graph	Silent 1		// building window...	String savDF=GetDataFolder(1)	SetDataFolder root:DP_ADCDACcontrol	Display /W=(757,453,1051,692) /K=1 TestPulse_ADC as "Test Pulse Display"	ModifyGraph margin(top)=43	ModifyGraph grid(left)=1	ModifyGraph tickUnit(bottom)=1	NVAR testadc	WAVE adcType	SVAR unitsCurrent, unitsVoltage	String yLabel	if (adcType[testadc]==1)		yLabel=sprintf1s("Current (%s)",unitsCurrent)	else		yLabel=sprintf1s("Voltage (%s)",unitsVoltage)	endif	Label left sprintf1s("\\F'Helvetica'\\Z12\\f01%s",yLabel)	Label bottom "\\F'Helvetica'\\Z12\\f01Time (ms)"	SetAxis left -6.75,7.5	ValDisplay RSeal_val,pos={130,12},size={120,17},fSize=12,format="%10.3f"	ValDisplay RSeal_val,limits={0,0,0},barmisc={0,1000},value=#"root:DP_ADCDACcontrol:RSeal"	SetDrawLayer UserFront	SetDrawEnv xcoord= rel,ycoord= rel,fillfgc= (56797,56797,56797)	DrawRect -0.01,-0.06,1,0.115	SetDrawEnv xcoord= rel,ycoord= rel,fillfgc= (52428,52428,52428),fsize= 18	SetDrawEnv save	SetDrawEnv fsize= 12	DrawText 0.05,0.09,"Resistance"	SetDrawEnv fsize= 12	DrawText 0.79,0.09,"GOhm"	SetDataFolder savDFEndFunction CreateADCDACControlPanel() : Panel	PauseUpdate; Silent 1		// building window...	String savDF=GetDataFolder(1)	SetDataFolder root:DP_ADCDACcontrol	NewPanel /W=(176,570,872,862) /N=ADCDACControl /K=1 as "ADC/DAC Contol Panel"	ModifyPanel /W=ADCDACControl fixedSize=1		//	// ADC channel area	// 		// ADC checkboxes	WAVE adcon	CheckBox ADC0Checkbox,pos={10,12},size={44,14},proc=HandleADCCheckbox,title="ADC0"	CheckBox ADC0Checkbox,value= adcon[0]	CheckBox ADC1Checkbox,pos={10,43},size={44,14},proc=HandleADCCheckbox,title="ADC1"	CheckBox ADC1Checkbox,value= adcon[1]	CheckBox ADC2Checkbox,pos={10,74},size={44,14},proc=HandleADCCheckbox,title="ADC2"	CheckBox ADC2Checkbox,value= adcon[2]	CheckBox ADC3Checkbox,pos={10,105},size={44,14},proc=HandleADCCheckbox,title="ADC3"	CheckBox ADC3Checkbox,value= adcon[3]	CheckBox ADC4Checkbox,pos={10,136},size={44,14},proc=HandleADCCheckbox,title="ADC4"	CheckBox ADC4Checkbox,value= adcon[4]	CheckBox ADC5Checkbox,pos={10,167},size={44,14},proc=HandleADCCheckbox,title="ADC5"	CheckBox ADC5Checkbox,value= adcon[5]	CheckBox ADC6Checkbox,pos={10,198},size={44,14},proc=HandleADCCheckbox,title="ADC6"	CheckBox ADC6Checkbox,value= adcon[6]	CheckBox ADC7Checkbox,pos={10,229},size={44,14},proc=HandleADCCheckbox,title="ADC7"	CheckBox ADC7Checkbox,value= adcon[7]	// ADC channel base names	WAVE /T adcBaseName	SetVariable adc0BaseNameSetVariable,pos={62,12-1},size={70+5,15},proc=HandleADCBaseNameSetVariable,title="name"	SetVariable adc0BaseNameSetVariable,value= _STR:adcBaseName[0]	SetVariable adc1BaseNameSetVariable,pos={62,43-1},size={70+5,15},proc=HandleADCBaseNameSetVariable,title="name"	SetVariable adc1BaseNameSetVariable,value= _STR:adcBaseName[1]	SetVariable adc2BaseNameSetVariable,pos={62,74-1},size={70+5,15},proc=HandleADCBaseNameSetVariable,title="name"	SetVariable adc2BaseNameSetVariable,value= _STR:adcBaseName[2]	SetVariable adc3BaseNameSetVariable,pos={62,105-1},size={70+5,15},proc=HandleADCBaseNameSetVariable,title="name"	SetVariable adc3BaseNameSetVariable,value= _STR:adcBaseName[3]	SetVariable adc4BaseNameSetVariable,pos={62,136-1},size={70+5,15},proc=HandleADCBaseNameSetVariable,title="name"	SetVariable adc4BaseNameSetVariable,value= _STR:adcBaseName[4]	SetVariable adc5BaseNameSetVariable,pos={62,167-1},size={70+5,15},proc=HandleADCBaseNameSetVariable,title="name"	SetVariable adc5BaseNameSetVariable,value= _STR:adcBaseName[5]	SetVariable adc6BaseNameSetVariable,pos={62,198-1},size={70+5,15},proc=HandleADCBaseNameSetVariable,title="name"	SetVariable adc6BaseNameSetVariable,value= _STR:adcBaseName[6]	SetVariable adc7BaseNameSetVariable,pos={62,229-1},size={70+5,15},proc=HandleADCBaseNameSetVariable,title="name"	SetVariable adc7BaseNameSetVariable,value= _STR:adcBaseName[7]	// Channel type list boxes	WAVE adcType	PopupMenu ADCChannelModePopupMenu0,pos={62+80+5,12-3}	PopupMenu ADCChannelModePopupMenu0,mode=adcType[0],value= #"\"Current;Voltage\""	PopupMenu ADCChannelModePopupMenu0, proc=HandleADCChannelModePopupMenu	PopupMenu ADCChannelModePopupMenu1,pos={62+80+5,43-3}	PopupMenu ADCChannelModePopupMenu1,mode=adcType[1],value= #"\"Current;Voltage\""	PopupMenu ADCChannelModePopupMenu1, proc=HandleADCChannelModePopupMenu	PopupMenu ADCChannelModePopupMenu2,pos={62+80+5,74-3}	PopupMenu ADCChannelModePopupMenu2,mode=adcType[2],value= #"\"Current;Voltage\""	PopupMenu ADCChannelModePopupMenu2, proc=HandleADCChannelModePopupMenu	PopupMenu ADCChannelModePopupMenu3,pos={62+80+5,105-3}	PopupMenu ADCChannelModePopupMenu3,mode=adcType[3],value= #"\"Current;Voltage\""	PopupMenu ADCChannelModePopupMenu3, proc=HandleADCChannelModePopupMenu	PopupMenu ADCChannelModePopupMenu4,pos={62+80+5,136-3}	PopupMenu ADCChannelModePopupMenu4,mode=adcType[4],value= #"\"Current;Voltage\""	PopupMenu ADCChannelModePopupMenu4, proc=HandleADCChannelModePopupMenu	PopupMenu ADCChannelModePopupMenu5,pos={62+80+5,167-3}	PopupMenu ADCChannelModePopupMenu5,mode=adcType[5],value= #"\"Current;Voltage\""	PopupMenu ADCChannelModePopupMenu5, proc=HandleADCChannelModePopupMenu	PopupMenu ADCChannelModePopupMenu6,pos={62+80+5,198-3}	PopupMenu ADCChannelModePopupMenu6,mode=adcType[6],value= #"\"Current;Voltage\""	PopupMenu ADCChannelModePopupMenu6, proc=HandleADCChannelModePopupMenu	PopupMenu ADCChannelModePopupMenu7,pos={62+80+5,229-3}	PopupMenu ADCChannelModePopupMenu7,mode=adcType[7],value= #"\"Current;Voltage\""	PopupMenu ADCChannelModePopupMenu7, proc=HandleADCChannelModePopupMenu	// ADC gain setvars	WAVE adcgain	SetVariable adcGain0SetVariable,pos={110+20+10+80,12},size={70,15},proc=HandleADCGainSetVariable,title="gain"	SetVariable adcGain0SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:adcgain[0]	SetVariable adcGain1SetVariable,pos={110+20+10+80,43},size={70,15},proc=HandleADCGainSetVariable,title="gain"	SetVariable adcGain1SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:adcgain[1]	SetVariable adcGain2SetVariable,pos={110+20+10+80,74},size={70,15},proc=HandleADCGainSetVariable,title="gain"	SetVariable adcGain2SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:adcgain[2]	SetVariable adcGain3SetVariable,pos={110+20+10+80,105},size={70,15},proc=HandleADCGainSetVariable,title="gain"	SetVariable adcGain3SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:adcgain[3]	SetVariable adcGain4SetVariable,pos={110+20+10+80,136},size={70,15},proc=HandleADCGainSetVariable,title="gain"	SetVariable adcGain4SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:adcgain[4]	SetVariable adcGain5SetVariable,pos={110+20+10+80,167},size={70,15},proc=HandleADCGainSetVariable,title="gain"	SetVariable adcGain5SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:adcgain[5]	SetVariable adcGain6SetVariable,pos={110+20+10+80,198},size={70,15},proc=HandleADCGainSetVariable,title="gain"	SetVariable adcGain6SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:adcgain[6]	SetVariable adcGain7SetVariable,pos={110+20+10+80,229},size={70,15},proc=HandleADCGainSetVariable,title="gain"	SetVariable adcGain7SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:adcgain[7]	// Reminder about gain units	SetDrawEnv fstyle= 1	DrawText 20,275,"Gain units:"		SetDrawEnv fsize= 10	SVAR unitsCurrent, unitsVoltage	DrawText 90,270,sprintf1s("Current inputs: V/%s",unitsCurrent)	SetDrawEnv fsize= 10	DrawText 90,285,sprintf1s("Voltage inputs: V/%s",unitsVoltage)	// Vertical rule	SetDrawEnv linethick= 2	DrawLine 279+20,0,279+20,301	//	// DAC channel area	// 	// Checkboxes for turning each DAC on/off	WAVE dacon	CheckBox DAC0Checkbox,pos={290+20,10},size={44,14},proc=HandleDACCheckbox,title="DAC0"	CheckBox DAC0Checkbox,value= dacon[0]	CheckBox DAC1Checkbox,pos={290+20,71},size={44,14},proc=HandleDACCheckbox,title="DAC1"	CheckBox DAC1Checkbox,value= dacon[1]	CheckBox DAC2Checkbox,pos={290+20,135},size={44,14},proc=HandleDACCheckbox,title="DAC2"	CheckBox DAC2Checkbox,value= dacon[2]	CheckBox DAC3Checkbox,pos={290+20,200},size={44,14},proc=HandleDACCheckbox,title="DAC3"	CheckBox DAC3Checkbox,value= dacon[3]	// Channel type list boxes	WAVE dacType	PopupMenu DACChannelModePopupMenu0,pos={361+3,10-2}	PopupMenu DACChannelModePopupMenu0,mode=dacType[0],value= #"\"Current;Voltage\""	PopupMenu DACChannelModePopupMenu0, proc=HandleDACChannelModePopupMenu	PopupMenu DACChannelModePopupMenu1,pos={361+3,71-2}	PopupMenu DACChannelModePopupMenu1,mode=dacType[1],value= #"\"Current;Voltage\""	PopupMenu DACChannelModePopupMenu1, proc=HandleDACChannelModePopupMenu	PopupMenu DACChannelModePopupMenu2,pos={361+3,135-2}	PopupMenu DACChannelModePopupMenu2,mode=dacType[2],value= #"\"Current;Voltage\""	PopupMenu DACChannelModePopupMenu2, proc=HandleDACChannelModePopupMenu	PopupMenu DACChannelModePopupMenu3,pos={361+3,200-2}	PopupMenu DACChannelModePopupMenu3,mode=dacType[3],value= #"\"Current;Voltage\""	PopupMenu DACChannelModePopupMenu3, proc=HandleDACChannelModePopupMenu	// DAC gain setvars	WAVE dacgain	SetVariable dacGain0SetVariable,pos={361+20+40+15,10},size={70,15},proc=HandleDACGainSetVariable,title="gain"	SetVariable dacGain0SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:dacgain[0]	SetVariable dacGain1SetVariable,pos={361+20+40+15,71},size={70,15},proc=HandleDACGainSetVariable,title="gain"	SetVariable dacGain1SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:dacgain[1]	SetVariable dacGain2SetVariable,pos={361+20+40+15,135},size={70,15},proc=HandleDACGainSetVariable,title="gain"	SetVariable dacGain2SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:dacgain[2]	SetVariable dacGain3SetVariable,pos={361+20+40+15,200},size={70,15},proc=HandleDACGainSetVariable,title="gain"	SetVariable dacGain3SetVariable,format="%g",limits={0.0001,10000,0},value= _NUM:dacgain[3]	// Popup menus for choosing the wave that gets outputted via a given DAC	WAVE /T dacWavePopupSelection	PopupMenu DAC0WavePopupMenu,pos={290+20,34},size={113,20}	PopupMenu DAC0WavePopupMenu,mode=3,popvalue=dacWavePopupSelection[0],value=#"\"_none_;\"+GetPopupItems(\"DAC\")"	PopupMenu DAC0WavePopupMenu,proc=HandleDACWavePopupMenu	PopupMenu DAC1WavePopupMenu,pos={290+20,95},size={113,20}	PopupMenu DAC1WavePopupMenu,mode=1,popvalue=dacWavePopupSelection[1],value=#"\"_none_;\"+GetPopupItems(\"DAC\")"	PopupMenu DAC1WavePopupMenu,proc=HandleDACWavePopupMenu	PopupMenu DAC2WavePopupMenu,pos={290+20,161},size={113,20}	PopupMenu DAC2WavePopupMenu,mode=1,popvalue=dacWavePopupSelection[2],value=#"\"_none_;\"+GetPopupItems(\"DAC\")"	PopupMenu DAC2WavePopupMenu,proc=HandleDACWavePopupMenu	PopupMenu DAC3WavePopupMenu,pos={290+20,226},size={113,20}	PopupMenu DAC3WavePopupMenu,mode=1,popvalue=dacWavePopupSelection[3],value=#"\"_none_;\"+GetPopupItems(\"DAC\")"	PopupMenu DAC3WavePopupMenu,proc=HandleDACWavePopupMenu	// Multiplier applied to a wave before being outputted via a given DAC	WAVE dacMultiplier	SetVariable dacMultiplier0SetVariable,pos={415+20,34},size={70,15},title="x ",proc=HandleDACMultiplierSetVariable	SetVariable dacMultiplier0SetVariable,limits={-10000,10000,100},value= _NUM:dacMultiplier[0]	SetVariable dacMultiplier1SetVariable,pos={415+20,98},size={70,15},title="x ",proc=HandleDACMultiplierSetVariable	SetVariable dacMultiplier1SetVariable,limits={-10000,10000,100},value= _NUM:dacMultiplier[1]	SetVariable dacMultiplier2SetVariable,pos={415+20,165},size={70,15},title="x ",proc=HandleDACMultiplierSetVariable	SetVariable dacMultiplier2SetVariable,limits={-10000,10000,100},value= _NUM:dacMultiplier[2]	SetVariable dacMultiplier3SetVariable,pos={415+20,227},size={70,15},title="x ",proc=HandleDACMultiplierSetVariable	SetVariable dacMultiplier3SetVariable,limits={-10000,10000,100},value= _NUM:dacMultiplier[3]	// Reminder about gain units	SetDrawEnv fstyle= 1	DrawText 282+30,275,"Gain units:"	SetDrawEnv fsize= 10	DrawText 370+10,270,sprintf1s("Voltage commands: %s/V",unitsVoltage)	SetDrawEnv fsize= 10	DrawText 370+10,285,sprintf1s("Current commands: %s/V",unitsCurrent)	// Vertical rule	SetDrawEnv linethick= 2	DrawLine 494+20,-3,494+20,300	// 	// TTL area	//	// Checkboxes to turn on/off	WAVE ttlon	CheckBox TTL0Checkbox,pos={509+20+15,10+2},size={43,14},proc=HandleTTLCheckbox,title="TTL0"	CheckBox TTL0Checkbox,value= ttlon[0]	CheckBox TTL1Checkbox,pos={509+20+15,37+2},size={43,14},proc=HandleTTLCheckbox,title="TTL1"	CheckBox TTL1Checkbox,value= ttlon[1]	CheckBox TTL2Checkbox,pos={509+20+15,64+2},size={43,14},proc=HandleTTLCheckbox,title="TTL2"	CheckBox TTL2Checkbox,value= ttlon[2]	CheckBox TTL3Checkbox,pos={509+20+15,91+2},size={43,14},proc=HandleTTLCheckbox,title="TTL3"	CheckBox TTL3Checkbox,value= ttlon[3]		// Popup menus to set the wave for each	WAVE /T ttlWavePopupSelection	PopupMenu TTL0WavePopupMenu,pos={584+15,10},size={67,20}	PopupMenu TTL0WavePopupMenu,mode=1,popvalue=ttlWavePopupSelection[0],value=#"\"_none_;\"+GetPopupItems(\"TTL\")"	PopupMenu TTL0WavePopupMenu,proc=HandleTTLWavePopupMenu	PopupMenu TTL1WavePopupMenu,pos={584+15,37},size={67,20}	PopupMenu TTL1WavePopupMenu,mode=1,popvalue=ttlWavePopupSelection[1],value=#"\"_none_;\"+GetPopupItems(\"TTL\")"	PopupMenu TTL1WavePopupMenu,proc=HandleTTLWavePopupMenu	PopupMenu TTL2WavePopupMenu,pos={584+15,64},size={67,20}	PopupMenu TTL2WavePopupMenu,mode=1,popvalue=ttlWavePopupSelection[2],value=#"\"_none_;\"+GetPopupItems(\"TTL\")"	PopupMenu TTL2WavePopupMenu,proc=HandleTTLWavePopupMenu	PopupMenu TTL3WavePopupMenu,pos={584+15,91},size={67,20}	PopupMenu TTL3WavePopupMenu,mode=1,popvalue=ttlWavePopupSelection[2],value=#"\"_none_;\"+GetPopupItems(\"TTL\")"	PopupMenu TTL3WavePopupMenu,proc=HandleTTLWavePopupMenu		// Horizontal rule	SetDrawLayer UserBack	SetDrawEnv linethick= 2	DrawLine 496+20,126,717,126		// Old stuff, may come back at some point	//CheckBox Vclamp_check,pos={504,231},size={84,14},proc=ClampModeProc,title="voltage clamp"	//CheckBox Vclamp_check,value= 1	//CheckBox Cclamp_check,pos={596,232},size={88,14},proc=ClampModeProc,title="current clamp"	//CheckBox Cclamp_check,value= 0	//Button switchclampbutton0,pos={544,256},size={100,20},proc=ToggleClampButtonProc,title="VC <--> CC"	//Button readgain_button,pos={532,174},size={120,20},proc=ReadControlButtonProc,title="Read set from file"	//Button savegain_button,pos={532,202},size={120,20},proc=SaveControlButtonProc,title="Save set to file"	//SetVariable setvar0,pos={540,139},size={100,25},title="ITC",fSize=18,format="%d"	//SetVariable setvar0,limits={16,18,2},value= itc		// Restore the original data folder	SetDataFolder savDFEndFunction Analysis() : Panel	PauseUpdate; Silent 1		// building window...	NewPanel /W=(757,44,1070,518) /K=1 as "Analysis"	Button analyze,pos={1,1},size={70,18},proc=Analyze,title="Measure"	Button fit,pos={21,34},size={70,18},proc=Fit,title="Fit"	Button avgswps,pos={39,72},size={70,18},proc=AverageSweeps,title="Average"EndFunction DACPulses() : Panel	PauseUpdate; Silent 1		// building window...	NewPanel /W=(19,424,175,658) /K=1	Button fivestep_button,pos={15,11},size={120,20},proc=FiveSegButtonProc,title="Five seg. wave"	Button train_button,pos={15,45},size={120,20},proc=TrainButtonProc,title="Train"	Button readwave_button,pos={15,174},size={120,20},proc=ReadwaveButtonProc,title="Read from file"	Button ramp_button,pos={15,77},size={120,20},proc=RampButtonProc,title="Ramp"	Button psc_button,pos={15,112},size={120,20},proc=PSCButtonProc,title="PSC wave"	Button sinewave_button,pos={15,144},size={120,20},proc=SineButtonProc,title="Sine wave"	Button viewwave_button,pos={15,204},size={120,20},proc=ViewDACButtonProc,title="View DAC"EndFunction FiveSegBuilder() : Graph	PauseUpdate; Silent 1		// building window...	String fldrSav= GetDataFolder(1)	SetDataFolder root:DP_ADCDACcontrol:	Display /W=(80,150,780,450) /K=1 Step5DAC	SetDataFolder fldrSav	ModifyGraph margin(top)=36	ModifyGraph grid(left)=1	ControlBar 90	SetVariable stepdur_0,pos={12,13},size={100,15},proc=StepVarProc,title="dur. 0"	SetVariable stepdur_0,limits={0,10000,10},value= root:DP_ADCDACcontrol:stepdur0	SetVariable stepdur_1,pos={132,11},size={100,15},proc=StepVarProc,title="dur. 1"	SetVariable stepdur_1,limits={0,10000,10},value= root:DP_ADCDACcontrol:stepdur1	SetVariable stepdur_2,pos={252,11},size={100,15},proc=StepVarProc,title="dur. 2"	SetVariable stepdur_2,limits={0,10000,10},value= root:DP_ADCDACcontrol:stepdur2	SetVariable stepdur_3,pos={368,11},size={100,15},proc=StepVarProc,title="dur. 3"	SetVariable stepdur_3,limits={0,10000,10},value= root:DP_ADCDACcontrol:stepdur3	SetVariable stepdur_4,pos={477,11},size={100,15},proc=StepVarProc,title="dur. 4"	SetVariable stepdur_4,limits={0,10000,10},value= root:DP_ADCDACcontrol:stepdur4	SetVariable stepamp_0,pos={12,39},size={100,15},proc=StepVarProc,title="amp. 0"	SetVariable stepamp_0,limits={-10000,10000,10},value= root:DP_ADCDACcontrol:stepamp0	SetVariable stepamp_1,pos={131,41},size={100,15},proc=StepVarProc,title="amp. 1"	SetVariable stepamp_1,limits={-10000,10000,10},value= root:DP_ADCDACcontrol:stepamp1	SetVariable stepamp_2,pos={252,38},size={100,15},proc=StepVarProc,title="amp. 2"	SetVariable stepamp_2,limits={-10000,10000,10},value= root:DP_ADCDACcontrol:stepamp2	SetVariable stepamp_3,pos={368,37},size={100,15},proc=StepVarProc,title="amp. 3"	SetVariable stepamp_3,limits={-10000,10000,10},value= root:DP_ADCDACcontrol:stepamp3	SetVariable stepamp_4,pos={478,37},size={100,15},proc=StepVarProc,title="amp. 4"	SetVariable stepamp_4,limits={-10000,10000,10},value= root:DP_ADCDACcontrol:stepamp4	Button save_dac,pos={607,11},size={80,20},proc=SaveDACButtonProc,title="Save As..."	SetVariable sint_pb,pos={594,37},size={120,15},proc=StepVarProc,title="sint. (ms)"	SetVariable sint_pb,limits={0.01,10,0.01},value= root:DP_ADCDACcontrol:sintpb	CheckBox ff_0,pos={28,61},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_0,value= 0	CheckBox ff_1,pos={147,62},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_1,value= 0  // ALT: Changed from 1 to fix error on 2012/05/18	CheckBox ff_2,pos={270,62},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_2,value= 0	CheckBox ff_3,pos={383,60},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_3,value= 0	CheckBox ff_4,pos={497,60},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_4,value= 0	PopupMenu editwave_popup0,pos={587,63},size={98,20},proc=EditFiveSegWave,title="Edit: "	PopupMenu editwave_popup0,mode=1,popvalue="_none_",value= #"\"_none_;\"+GetPopupItems(\"DAC\")+GetPopupItems(\"TTL\")"	SetDrawLayer UserFront	SetDrawEnv fstyle= 1	DrawText -0.0500647382210309,-0.0603730897293596,"When done, save the wave with an extension _DAC or _TTL (TTL high should have an amplitude of 1)"	DrawLine -0.085,-0.0346,1.04,-0.0345EndFunction TrainBuilder() : Graph	PauseUpdate; Silent 1		// building window...	String fldrSav= GetDataFolder(1)	SetDataFolder root:DP_ADCDACcontrol:	Display /W=(80,150,780,450) /K=1 TrainDAC	SetDataFolder fldrSav	ModifyGraph margin(top)=36	ModifyGraph grid(left)=1	ControlBar 90	SetVariable train_num,pos={16,12},size={104,15},proc=TrainVarProc,title="number"	SetVariable train_num,limits={1,10000,1},value= root:DP_ADCDACcontrol:trainnum	SetVariable train_freq,pos={415,13},size={120,15},proc=TrainVarProc,title="frequency"	SetVariable train_freq,limits={0.001,10000,10},value= root:DP_ADCDACcontrol:trainfreq	SetVariable train_dur,pos={10,39},size={109,15},proc=TrainVarProc,title="duration"	SetVariable train_dur,limits={0.001,1000,1},value= root:DP_ADCDACcontrol:traindur	Button train_save,pos={570,8},size={90,20},proc=SaveDACButtonProc,title="Save As..."	SetVariable train_pre,pos={306,13},size={75,15},proc=TrainVarProc,title="pre"	SetVariable train_pre,limits={0,1000,1},value= root:DP_ADCDACcontrol:traindur0	SetVariable train_post,pos={299,38},size={85,15},proc=TrainVarProc,title="post"	SetVariable train_post,limits={0,1000,10},value= root:DP_ADCDACcontrol:traindur2	SetVariable train_amp,pos={142,38},size={120,15},proc=TrainVarProc,title="amplitude"	SetVariable train_amp,limits={-10000,10000,10},value= root:DP_ADCDACcontrol:trainamp	SetVariable train_sint,pos={417,38},size={120,15},proc=TrainVarProc,title="samp. int."	SetVariable train_sint,limits={0.01,1000,0.01},value= root:DP_ADCDACcontrol:sintpb	SetVariable train_base,pos={151,12},size={110,15},proc=TrainVarProc,title="baseline"	SetVariable train_base,limits={-10000,10000,1},value= root:DP_ADCDACcontrol:trainbase	PopupMenu edittrain_popup0,pos={571,38},size={98,20},proc=EditTrainWave,title="Edit: "	PopupMenu edittrain_popup0,mode=1,popvalue="_none_",value= #"\"_none_;\"+GetPopupItems(\"DAC\")+GetPopupItems(\"TTL\")"	SetDrawLayer UserFront	SetDrawEnv fstyle= 1	DrawText -0.06,-0.06,"When done, save the wave with an extension _DAC or _TTL (TTL high should have an amplitude of 1)"	DrawLine -0.085,-0.035,1.04,-0.035EndFunction RampBuilder() : Graph	PauseUpdate; Silent 1		// building window...	String fldrSav= GetDataFolder(1)	SetDataFolder root:DP_ADCDACcontrol:	Display /W=(80,150,780,450) /K=1 RampDAC	ModifyGraph margin(top)=36	ModifyGraph grid(left)=1	ControlBar 90	SetVariable ramp_amp1,pos={26,22},size={110,15},proc=RampVarProc,title="amplitude1"	SetVariable ramp_amp1,limits={-10000,10000,10},value= root:DP_ADCDACcontrol:rampamp1	SetVariable ramp_dur1,pos={27,49},size={110,15},proc=RampVarProc,title="duration1"	SetVariable ramp_dur1,limits={0,1000,1},value= root:DP_ADCDACcontrol:rampdur1	SetVariable ramp_dur2,pos={163,51},size={110,15},proc=RampVarProc,title="duration2"	SetVariable ramp_dur2,limits={1,100000,10},value= root:DP_ADCDACcontrol:rampdur2	SetVariable ramp_amp3,pos={285,20},size={110,15},proc=RampVarProc,title="amplitude3"	SetVariable ramp_amp3,limits={-10000,10000,10},value= root:DP_ADCDACcontrol:rampamp3	SetVariable ramp_dur3,pos={282,50},size={110,15},proc=RampVarProc,title="duration3"	SetVariable ramp_dur3,limits={1,100000,10},value= root:DP_ADCDACcontrol:rampdur3	SetVariable ramp_amp4,pos={422,20},size={110,15},proc=RampVarProc,title="amplitude4"	SetVariable ramp_amp4,limits={0,0,0},value= root:DP_ADCDACcontrol:rampamp4	SetVariable ramp_dur4,pos={422,50},size={110,15},proc=RampVarProc,title="duration4"	SetVariable ramp_dur4,limits={10,1000,10},value= root:DP_ADCDACcontrol:rampdur4	SetVariable ramp_sint,pos={551,35},size={110,15},proc=RampVarProc,title="samp. int."	SetVariable ramp_sint,limits={0.01,1000,0.01},value= root:DP_ADCDACcontrol:sintpb	Button train_save,pos={570,8},size={90,20},proc=SaveDACButtonProc,title="Save As..."	PopupMenu editramp_popup0,pos={565,59},size={95,20},proc=EditRampWave,title="Edit: "	PopupMenu editramp_popup0,mode=1,popvalue="_New_",value=#"\"_New_;\"+GetPopupItems(\"DAC\")+GetPopupItems(\"TTL\")"	SetDrawLayer UserFront	SetDrawEnv fstyle= 1	DrawText -0.046,-0.06,"When done, save the wave with an extension _DAC"	DrawLine -0.085,-0.035,1.04,-0.035	SetDataFolder fldrSavEndFunction PSCBuilder() : Graph	String savDF=GetDataFolder(1)	SetDataFolder root:DP_ADCDACcontrol	PauseUpdate; Silent 1		// building window...	Display /W=(80,150,780,450) /K=1 PSCDAC	ModifyGraph margin(top)=36	ModifyGraph grid(left)=1	ControlBar 90	SetVariable psc_pre,pos={42,12},size={110,17},proc=PSCVarProc,title="pre (ms)"	SetVariable psc_pre,limits={0,1000,1},value= pscdur0	SetVariable psc_post,pos={301,13},size={120,17},proc=PSCVarProc,title="post (ms)"	SetVariable psc_post,limits={10,1000,10},value= pscdur2	SetVariable psc_amp,pos={28,43},size={120,17},proc=PSCVarProc,title="amplitude"	SetVariable psc_amp,limits={-10000,10000,10},value= pscamp	SetVariable psc_taur,pos={163,43},size={120,17},proc=PSCVarProc,title="tau_rise"	SetVariable psc_taur,format="%g",limits={0,10000,0.1},value= psctaur	SetVariable psc_taud1,pos={289,42},size={130,17},proc=PSCVarProc,title="tau_decay1"	SetVariable psc_taud1,format="%g",limits={0,10000,1},value= psctaud1	SetVariable psc_taud2,pos={429,41},size={130,17},proc=PSCVarProc,title="tau_decay2"	SetVariable psc_taud2,format="%g",limits={0,10000,10},value= psctaud2	SetVariable psc_sint,pos={587,51},size={120,17},proc=pscVarProc,title="samp. int."	SetVariable psc_sint,limits={0.01,1000,0.01},value= sintpb	Button train_save,pos={585,5},size={90,20},proc=SaveDACButtonProc,title="Save As..."	SetVariable psc_dur,pos={173,13},size={110,17},proc=PSCVarProc,title="psc (ms)"	SetVariable psc_dur,limits={0,1000,10},value= pscdur1	SetVariable psc_wt_td2,pos={440,12},size={120,17},proc=PSCVarProc,title="weight td2"	SetVariable psc_wt_td2,format="%2.1f",limits={0,1,0.1},value= wttd2	PopupMenu editpsc_popup0,pos={584,28},size={100,19},proc=EditPSCWave,title="Edit: "	PopupMenu editpsc_popup0,mode=1,value=#"\"_New_;\"+GetPopupItems(\"DAC\")+GetPopupItems(\"TTL\")"	SetDrawLayer UserFront	SetDrawEnv fstyle= 1	DrawText -0.05,-0.06,"When done, save the wave with an extension _DAC"	DrawLine -0.085,-0.035,1.04,-0.035	SetDataFolder savDFEndFunction SineBuilder() : Graph	String savDF=GetDataFolder(1)	SetDataFolder root:DP_ADCDACcontrol	PauseUpdate; Silent 1		// building window...	Display /W=(80,150,780,450) /K=1 SineDAC	ModifyGraph margin(top)=36	ModifyGraph grid(left)=1	ControlBar 90	SetVariable sine_pre,pos={42,12},size={110,17},proc=sineVarProc,title="pre (ms)"	SetVariable sine_pre,limits={0,1000,1},value= sinedur0	SetVariable sine_post,pos={331,13},size={120,17},proc=sineVarProc,title="post (ms)"	SetVariable sine_post,limits={10,1000,10},value= sinedur2	SetVariable sine_amp,pos={128,43},size={120,17},proc=sineVarProc,title="amplitude"	SetVariable sine_amp,limits={-10000,10000,10},value= sineamp	SetVariable sine_freq,pos={286,41},size={130,17},proc=sineVarProc,title="freq. (Hz)"	SetVariable sine_freq,format="%g",limits={0,10000,10},value= sinefreq	SetVariable sine_sint,pos={466,12},size={120,17},proc=sineVarProc,title="samp. int."	SetVariable sine_sint,limits={0.01,1000,0.01},value= sintpb	Button train_save,pos={601,10},size={90,20},proc=SaveDACButtonProc,title="Save As..."	SetVariable sine_dur,pos={174,13},size={120,17},proc=SineVarProc,title="sine (ms)"	SetVariable sine_dur,format="%g",limits={0,10000,10},value= sinedur1	PopupMenu editsine_popup0,pos={578,42},size={100,19},proc=EditSineWave,title="Edit: "	PopupMenu editsine_popup0,mode=1,value=#"\"_New_;\"+GetPopupItems(\"DAC\")+GetPopupItems(\"TTL\")"	SetDrawLayer UserFront	SetDrawEnv fstyle= 1	DrawText -0.038,-0.06,"When done, save the wave with an extension _DAC"	DrawLine -0.085,-0.035,1.04,-0.035	SetDataFolder savDFEndFunction DACViewer() : Graph	PauseUpdate; Silent 1		// building window...	String fldrSav= GetDataFolder(1)	SetDataFolder root:DP_ADCDACcontrol:	//Display /W=(78,138,698,408) ThetaTETNUS_DAC	String dacWaveNames=GetPopupItems("DAC")	String firstDacWaveName=StringFromList(0,DacWaveNames,";")	String popupItems, initialPopupItem	if ( strlen(firstDacWaveName)==0 )		popupItems="(none)"		initialPopupItem="(none)"	else		popupItems="(none);" + dacWaveNames		initialPopupItem=firstDacWaveName	endif	Display /W=(100,150,700,400) /K=1 $initialPopupItem	ModifyGraph grid(left)=1	PopupMenu dacpopup,pos={650,20},size={115,20},proc=handleViewDACPopupSelection	String popupItemsStupidized="\""+popupItems+"\""	PopupMenu dacpopup,mode=3,popvalue=initialPopupItem,value=#popupItemsStupidized	//SetVariable disp0,pos={650,40},size={100,15},title="samp. int."	//SetVariable disp0,limits={0,0,0},value= root:DP_ADCDACcontrol:sintdisp	SetDataFolder fldrSavEndWindow ImagingPanel() : Panel	PauseUpdate; Silent 1		// building window...	NewPanel /W=(757,268,1068,741) /K=1	Button flu_on,pos={10,40},size={130,20},proc=FluONButtonProc,title="Fluorescence ON"	Button flu_off,pos={10,10},size={130,20},proc=FluOFFButtonProc,title="Fluorescence OFF"	CheckBox imaging_check0,pos={14,244},size={114,14},proc=ImagingCheckProc,title="trigger filter wheel"	CheckBox imaging_check0,value= 1	Button button0,pos={215,283},size={80,20},proc=DFFButtonProc,title="Append DF/F"	Button button1,pos={9,190},size={130,20},proc=EphysImageButtonProc,title="Electrophys. + Image"	SetVariable setimagename0,pos={141,223},size={80,15},title="name"	SetVariable setimagename0,value= imageseq_name	CheckBox bkgndcheck0,pos={14,265},size={71,14},title="Bkgnd Sub.",value= 1	SetVariable numimages_setvar0,pos={11,223},size={120,15},title="No. images"	SetVariable numimages_setvar0,limits={1,10000,1},value= ccd_frames	SetVariable ccdtemp_setvar0,pos={13,311},size={150,15},proc=SetCCDTempVarProc,title="CCD Temp. Set"	SetVariable ccdtemp_setvar0,limits={-50,20,5},value= ccd_tempset	CheckBox showimageavg_check0,pos={14,286},size={84,14},title="Show Average"	CheckBox showimageavg_check0,value= 0	Button resetavg_button2,pos={212,253},size={80,20},proc=ResetAvgButtonProc,title="Reset Avg"	Button focus,pos={10,70},size={130,20},proc=FocusButtonProc,title="Focus"	Button full_frame,pos={10,130},size={130,20},proc=FullButtonProc,title="Full Frame Image"	SetVariable fluo_on_set,pos={178,40},size={120,15},title="ON   position"	SetVariable fluo_on_set,limits={0,9,1},value= fluo_on_wheel	SetVariable fluo_off_set,pos={177,10},size={120,15},title="OFF position"	SetVariable fluo_off_set,limits={0,9,1},value= fluo_off_wheel	SetVariable focusnum_set,pos={229,98},size={70,15},title="no."	SetVariable focusnum_set,limits={0,1000,1},value= focus_num	SetVariable fulltime_set,pos={152,130},size={150,15},title="Exp. time (ms)"	SetVariable fulltime_set,limits={0,10000,100},value= ccd_fullexp	SetVariable imagetime_setvar0,pos={149,193},size={150,15},title="Exp.time (ms)"	SetVariable imagetime_setvar0,limits={0,10000,10},value= ccd_seqexp	SetVariable setfullname0,pos={137,158},size={80,15},title="name"	SetVariable setfullname0,value= full_name	SetVariable setfocusname0,pos={139,99},size={80,15},title="name"	SetVariable setfocusname0,value= focus_name	ValDisplay tempdisp0,pos={174,311},size={120,14},title="CCD Temp."	ValDisplay tempdisp0,format="%3.1f",limits={0,0,0},barmisc={0,1000}	ValDisplay tempdisp0,value= #"ccd_temp"	SetVariable focustime_set,pos={151,70},size={150,15},title="Exp. time (ms)"	SetVariable focustime_set,limits={0,10000,100},value= ccd_focusexp	SetVariable fullnum_set,pos={230,159},size={70,15},title="no."	SetVariable fullnum_set,limits={0,1000,1},value= full_num	SetVariable imageseqnum_set,pos={227,223},size={70,15},title="no."	SetVariable imageseqnum_set,limits={0,10000,1},value= iSweep	SetVariable roinum_set0,pos={117,341},size={90,15},proc=GetROIProc,title="ROI no."	SetVariable roinum_set0,format="%d",limits={1,2,1},value= roinum	SetVariable settop0,pos={182,371},size={77,15},proc=SetROIProc,title="top"	SetVariable settop0,format="%d",limits={0,512,1},value= roi_top	SetVariable setright0,pos={54,395},size={85,15},proc=SetROIProc,title="right"	SetVariable setright0,format="%d",limits={0,512,1},value= roi_right	SetVariable settleft0,pos={64,370},size={75,15},proc=SetROIProc,title="left"	SetVariable settleft0,format="%d",limits={0,512,1},value= roi_left	SetVariable setbottom0,pos={159,395},size={100,15},proc=SetROIProc,title="bottom"	SetVariable setbottom0,format="%d",limits={0,512,1},value= roi_bottom	SetVariable setxbin0,pos={55,419},size={85,15},proc=SetROIProc,title="x bin"	SetVariable setxbin0,format="%d",limits={0,512,1},value= xbin	SetVariable setybin0,pos={174,419},size={85,15},proc=SetROIProc,title="y bin"	SetVariable setybin0,format="%d",limits={0,512,1},value= ybin	ValDisplay xpixels0,pos={54,444},size={85,14},title="x pixels",format="%4.2f"	ValDisplay xpixels0,limits={0,0,0},barmisc={0,1000},value= #"xpixels"	ValDisplay ypixels0,pos={173,446},size={85,14},title="y pixels",format="%4.2f"	ValDisplay ypixels0,limits={0,0,0},barmisc={0,1000},value= #"ypixels"	Button getstac_button,pos={125,253},size={80,20},proc=StackButtonProc,title="GetStack"	CheckBox show_roi_check0,pos={109,286},size={94,14},title="Show ROI Image"	CheckBox show_roi_check0,value= 0EndMacro//------------- DataPro Analyze WINDOWS (keep at bottom, because they are long) ------------////Window ShowAccessoryWaves() : Table//	PauseUpdate; Silent 1		// building window...//	Edit /W=(5,42,966,557) /K=1 baselineA,avgflag1,reject1,bsub1//	AppendToTable baselineB,avgflag2,reject2, bsub2//EndMacro