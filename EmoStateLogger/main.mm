

// Data will be saved to file : EmoStateLog.csv

#import <Foundation/Foundation.h>
#import "MIDIWrapper.h"

 #ifdef __cplusplus
 #include "edk.h"
 #include "edkErrorCode.h"
 #include "EmoStateDLL.h"
 #endif

int state = 0;

void logState(EmoEngineEventHandle, EmoStateHandle, int, NSFileHandle * , NSMutableData *);
const char* UpperFaceAction(EmoStateHandle);
const char* LowerFaceAction(EmoStateHandle);
const char* CognitivSuite(EmoStateHandle);

void saveStr(NSFileHandle *file, NSMutableData *data, const char* str);
void saveFloatVal(NSFileHandle *, NSMutableData *, const float);
void saveIntVal(NSFileHandle *, NSMutableData *, const int);
void upperFaceBunches(NSFileHandle *file, NSMutableData *data, float fEyebrow, float fFurrow);
void lowerFaceBunches(NSFileHandle *file, NSMutableData *data, float fSmile, float fClench,float fSmirkLeft, float fSmirkRight, float fLaught);

//Instanciation du midi wrapper se connectant à CodeMIDI d'OSX
MIDIWrapper *midi;

const char *newLine = "\n";
const char *content = "Time, UserId, Wireless signal status, Blink, Wink Left, Wink Right, Look Left, Look Right, Eyebrow, Furrow, Smile,Clench, Smirk Left, Smirk Right, Laugh, Short Term Excitement, Long Term Excitement, Engagement/Boredom, Cognitiv Action, Cognitiv Power, ";

const char *comma = ",";

int main (int argc, const char * argv[])
{
    
    @autoreleasepool 
    {
        EmoEngineEventHandle eEvent = EE_EmoEngineEventCreate();
        EmoStateHandle eState = EE_EmoStateCreate();
        unsigned int userID = 0;
        const unsigned short composerPort = 1726;
        bool connected = FALSE;
        
        midi = [[MIDIWrapper alloc] initWithClientName:@"Client" inPort:@"Input Port" outPort:@"Output Port"];
        NSLog(@"%@", [midi getDeviceList]);
        NSLog(@"Example to show how to log the EmoState from EmoEngine/EmoComposer");
        NSLog(@"Press \'1\' to start and connect to the EmoEngine !");
        NSLog(@"Press \'2\' to start and connect to the EmoComposer !");
        NSLog(@" choose : ");
        int option;
        scanf("%i",&option);
        switch(option)
        {
            case 1:
                if(EE_EngineConnect() == EDK_OK) {
                    connected = TRUE;
                    NSLog(@"Connected to the EmoEngine");
                }
                else
                { 
                    connected = FALSE;
                    NSLog(@"Cannot connect to the EmoEngine !");
                }
                break;
            case 2:
                if(EE_EngineRemoteConnect("127.0.0.1",composerPort)==EDK_OK) {
                    connected = TRUE;
                    NSLog(@"Connected to Composer");    
                }
                else
                {
                    connected = FALSE;
                    NSLog(@"Cannot connect to the Composer !");
                }
                break;
            default:
                connected = FALSE;
                break;
        }
        
        
        NSString* fileName = @"EmoStateLog.csv";
        NSString* createFile = @"";
        [createFile writeToFile:fileName atomically:YES encoding:NSUnicodeStringEncoding error:nil];
        NSFileHandle *file;
        NSMutableData *data;
        file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
        
        saveStr(file,data, content);
        saveStr(file,data,newLine);
        
        if(connected)
        {
            while(TRUE)
            {
                
                state = EE_EngineGetNextEvent(eEvent);
                if(state == EDK_OK)
                {
                    EE_Event_t eventType = EE_EmoEngineEventGetType(eEvent);
                    EE_EmoEngineEventGetUserId(eEvent, &userID);
                    if(eventType == EE_EmoStateUpdated)
                    {
                        EE_EmoEngineEventGetEmoState(eEvent, eState);
                        
                        // time from start
                        const float timestart = ES_GetTimeFromStart(eState);
                        NSLog(@"%s",CognitivSuite(eState));
                        
                        saveFloatVal(file, data, timestart);
                        saveStr(file,data,comma);
                        saveIntVal(file,data,userID);
                        saveStr(file,data,comma);
                        
                        logState(eEvent, eState, userID,file,data);
                        EE_CognitivAction_t actionType;
                        actionType = ES_CognitivGetCurrentAction(eState);
                        float actionPower;
                        actionPower = ES_CognitivGetCurrentActionPower(eState);
                        
                        NSLog(@"%u", actionType);
                        NSLog(@"%f", actionPower);
                    }
                    if(eventType == EE_UserAdded)
                        
                    {
                        NSLog(@"User Added");
                    }
                }
                
            }
        }
        
        [file closeFile];
        EE_EmoStateFree(eState);
        EE_EmoEngineEventFree(eEvent); 
        
    }
    return 0;
}

void logState(EmoEngineEventHandle eEvent, EmoStateHandle eState, int userId, NSFileHandle *file, NSMutableData *data)
{	
	// signal strength
    const char *commonStr ;
	EE_SignalStrength_t signalStr = ES_GetWirelessSignalStatus(eState);
	if(signalStr == 0)
    {
		//printf("Signal Status : No Signal\n");
        commonStr = "No Signal";         
    }
	else if( signalStr == 1)
    {
		//printf("Signal Status : Bad Signal\n");
        commonStr = "Bad Signal";
    }
	else if( signalStr == 2)
    {
		//printf("Signal Status : Good Signal");
        commonStr = "Good Signal";    
    }
    
    
    saveStr(file,data,commonStr);
    
    
	// exp blink
	if( ES_ExpressivIsBlink(eState)==0)
	{
		//printf("Blink : No\n");
        commonStr = "No";
	}
	else
	{
		//printf("Blink : Yes\n");
        commonStr = "Yes";
	}
    
    saveStr(file,data,comma);
    saveStr(file, data, commonStr );
    
	// exp left wink
	if(ES_ExpressivIsLeftWink(eState) == 0)
	{
		//printf("Left Wink : No\n");
        commonStr = "No";
	}
	else 
	{
		//printf("Left Wink : Yes\n");
        commonStr = "Yes";
	}
    
    saveStr(file,data,comma);
    saveStr(file, data, commonStr);
    
    // exp right wink
    if(ES_ExpressivIsRightWink(eState) == 0)
    {
        commonStr = "No";
    }
    else
    {
        commonStr = "Yes";
    }
    
    saveStr(file,data,comma);
    saveStr(file, data, commonStr);
    
	// exp looking left
	if(ES_ExpressivIsLookingLeft(eState)==0)
	{
		//printf("Looking left : No\n");
        commonStr = "No";
	}
	else
	{
		//printf("Looking left : Yes\n");
        commonStr = "Yes";
	}        
    
    saveStr(file,data,comma);
    saveStr(file,data,commonStr);
    
	// exp looking right
	if(ES_ExpressivIsLookingRight(eState))
	{
		//printf("Looking right : No\n");
        commonStr = "No";
	}
	else
	{
		//printf("Looking right : Yes\n");
        commonStr = "Yes";
	}
	
    saveStr(file,data,comma);
    saveStr(file,data,commonStr);
    
    //exp looking 
    
	// upperfaceaction
	const char* upperFaceAction = UpperFaceAction( eState ) ;
    const float upperFacePower = ES_ExpressivGetUpperFaceActionPower(eState);
    
    if(upperFaceAction == "Eyebrow")
    {               
        upperFaceBunches(file,data,upperFacePower,0.0);
    }
    else if(upperFaceAction == "Furrow")
    {
        upperFaceBunches(file,data,0.0,upperFacePower);    
    }
    else
    {
        upperFaceBunches(file,data,0.0,0.0);
    }
    
	// lowerFaceAction
	const char* lowerFaceAction = LowerFaceAction( eState );	    
	float lowerFacePower = ES_ExpressivGetLowerFaceActionPower( eState );
	if(lowerFaceAction == "Smile")
    {
        lowerFaceBunches(file,data,lowerFacePower,0.0,0.0,0.0,0.0);
    }
    else if(lowerFaceAction == "Clench")
    {
        lowerFaceBunches(file,data,0.0,lowerFacePower,0.0,0.0,0.0);
    }
    else if(lowerFaceAction == "Smirk Left")
    {
        lowerFaceBunches(file,data,0.0,0.0,lowerFacePower,0.0,0.0);
    }
    else if(lowerFaceAction == "Smirk Right")
    {
        lowerFaceBunches(file,data,0.0,0.0,0.0,lowerFacePower,0.0);
    }
    else if( lowerFaceAction == "Laugh")
    {
        lowerFaceBunches(file,data,0.0,0.0,0.0,0.0,lowerFacePower);
    }
    else
    {
        lowerFaceBunches(file,data,0.0,0.0,0.0,0.0,0.0);
    }
    
	// Affectiv results
	float shortTermScore = ES_AffectivGetExcitementShortTermScore(eState);
    saveStr(file,data,comma);
    saveFloatVal(file,data,shortTermScore);
    
	float longTermScore = ES_AffectivGetExcitementLongTermScore(eState);
    saveStr(file,data,comma);
    saveFloatVal(file,data,longTermScore);
    
	float engagementScore = ES_AffectivGetEngagementBoredomScore(eState);
	saveStr(file,data,comma);
    saveFloatVal(file,data,engagementScore);

    
	// Cognitiv Suite results
	const char* cognitivAction = CognitivSuite(eState);
    saveStr(file, data, comma);
    saveStr(file, data, cognitivAction);
    
	float cognitivPower = ES_CognitivGetCurrentActionPower(eState);
    saveStr(file, data, comma);
    saveFloatVal(file, data, cognitivPower);
	    
    saveStr(file,data,newLine);
}

const char* UpperFaceAction(EmoStateHandle eState)
{
	EE_ExpressivAlgo_t upperFaceAction = ES_ExpressivGetUpperFaceAction( eState ) ;
	if( upperFaceAction == EXP_EYEBROW)
		return "Eyebrow";
	else  if(upperFaceAction == EXP_FURROW )
		return "Furrow";	
    
	return "-";
}

const char* LowerFaceAction(EmoStateHandle eState)
{
	EE_ExpressivAlgo_t lowerFaceAction = ES_ExpressivGetLowerFaceAction( eState );
	if( lowerFaceAction == EXP_SMILE)
		return "Smile";
	else if( lowerFaceAction == EXP_CLENCH)
		return "Clench";
	else if( lowerFaceAction == EXP_SMIRK_LEFT)
		return "Smirk left";
	else if( lowerFaceAction == EXP_SMIRK_RIGHT)
		return "Smirk right";
	else if( lowerFaceAction == EXP_LAUGH )
		return "Laugh";
    
	return "-";
}

const char* CognitivSuite(EmoStateHandle eState)
{
	EE_CognitivAction_t cognitivAction = ES_CognitivGetCurrentAction(eState);
	if( cognitivAction == COG_NEUTRAL)
		return "Neutral";
	else if(cognitivAction == COG_PUSH)
		return "Push";
	else if( cognitivAction == COG_PULL)
		return "Pull";
	else if(cognitivAction == COG_LIFT)
		return "Lift";
	else if( cognitivAction == COG_DROP)
		return "Drop";
	else if( cognitivAction == COG_LEFT)
		return "Left";
	else if(cognitivAction == COG_RIGHT)
		return "Right";
	else if( cognitivAction == COG_ROTATE_LEFT)
		return "Rotate Left";
	else if( cognitivAction == COG_ROTATE_RIGHT)
		return "Rotate Right";
	else if(cognitivAction == COG_ROTATE_CLOCKWISE)
		return "Rotate_ClockWise";
	else if(cognitivAction==COG_ROTATE_COUNTER_CLOCKWISE)
		return "Rotate_Counter_ClockWise";
	else if( cognitivAction == COG_ROTATE_FORWARDS)
		return "Rotate_Forwards";
	else if(cognitivAction == COG_ROTATE_REVERSE)
		return "Rotate_Reverse";
	else if( cognitivAction == COG_DISAPPEAR)
		return "Disappear";
    
	
	return "-";
}   

void saveStr(NSFileHandle *file, NSMutableData *data, const char* str)
{
    [file seekToEndOfFile];
    data = [NSMutableData dataWithBytes:str length:strlen(str)];
    [file writeData:data];
}

void saveFloatVal(NSFileHandle *file, NSMutableData *data, const float val)
{
    NSString* str = [NSString stringWithFormat:@"%f",val];
    const char* myValStr = (const char*)[str UTF8String];
    saveStr(file,data,myValStr);          
}

void saveIntVal(NSFileHandle *file, NSMutableData *data, const int val)
{
    NSString* str = [NSString stringWithFormat : @"%d",val];
    const char *myIntStr = (const char*) [str UTF8String];
    saveStr(file, data, myIntStr);
}

void upperFaceBunches(NSFileHandle *file, NSMutableData *data, float fEyebrow, float fFurrow)
{
    saveStr(file,data,comma);
    saveFloatVal(file,data,fEyebrow);
    saveStr(file,data,comma);
    saveFloatVal(file,data,fFurrow);
}

void lowerFaceBunches(NSFileHandle *file, NSMutableData *data, float fSmile, float fClench,float fSmirkLeft, float fSmirkRight, float fLaught)
{
    saveStr(file,data,comma);
    saveFloatVal(file,data,fSmile);
    
    saveStr(file,data,comma);
    saveFloatVal(file,data,fClench);
    
    saveStr(file,data,comma);
    saveFloatVal(file,data,fSmirkLeft);
    
    saveStr(file,data,comma);
    saveFloatVal(file,data,fSmirkRight);

    saveStr(file,data,comma);
    saveFloatVal(file,data,fLaught);

}
