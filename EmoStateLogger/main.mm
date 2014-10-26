#import <Foundation/Foundation.h>
#import "MIDIWrapper.h"

 #ifdef __cplusplus
 #include "edk.h"
 #include "edkErrorCode.h"
 #include "EmoStateDLL.h"
 #endif

int state = 0;

//CoreMIDI Wrapper for OS X's MIDI framework
MIDIWrapper *midi;
//Virtual device created as an IAC Driver
MIDIDeviceRef virtualDevice;

int main (int argc, const char * argv[])
{
    @autoreleasepool 
    {
        /*
         * Code from the EmoStateLogger demo
         */
        EmoEngineEventHandle eEvent = EE_EmoEngineEventCreate();
        EmoStateHandle eState = EE_EmoStateCreate();
        unsigned int userID = 0;
        const unsigned short composerPort = 1726;
        
        //Pour se connecter au Consumer control panel avec le SDK Lite il faut passer par ce port.
        //EmoEngine ne fonctionne qu'avec le SDK complet.
        const unsigned short remoteConnectEmoEnginePort = 3008;
        bool connected = FALSE;
        
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
                if(EE_EngineRemoteConnect("127.0.0.1", remoteConnectEmoEnginePort) == EDK_OK) {
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
        
        if(connected)
        {
            //Enable MIDI connectionbetween the IAC Driver and the CoreMIDI Wrapper
            midi = [[MIDIWrapper alloc] initWithClientName:@"Client" inPort:@"Input Port" outPort:@"Output Port"];
            virtualDevice = (MIDIDeviceRef)[midi getDevice:@"Gestionnaire IAC"];
            [midi connectDevice: virtualDevice];
            
            NSArray *meditationMIDIData;
            NSArray *excitementMIDIData;
            
            float excitementScore;
            
            EE_Event_t eventType;
            NSLog(@"Connected");
            while(TRUE)
            {
                state = EE_EngineGetNextEvent(eEvent);
                
                if(state == EDK_OK)
                {
                    eventType = EE_EmoEngineEventGetType(eEvent);
                    EE_EmoEngineEventGetUserId(eEvent, &userID);
                    
                    if(eventType == EE_EmoStateUpdated)
                    {
                        EE_EmoEngineEventGetEmoState(eEvent, eState);
                        
                        //Data from 0 to 1
                        excitementScore = ES_AffectivGetExcitementShortTermScore(eState);
                        
                        //Meditation sends pitchBend data on channel 0 and Excitement sends pitchBend data on channel 1
                        meditationMIDIData = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:0xE0 ], [NSNumber numberWithUnsignedInt:0x0C], [NSNumber numberWithUnsignedInt: (127 - excitementScore * 127)],nil];
                        excitementMIDIData = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:0xE1 ], [NSNumber numberWithUnsignedInt:0x0C], [NSNumber numberWithUnsignedInt: (excitementScore * 127)],nil];
                        
                        [midi sendData:meditationMIDIData withDevice:virtualDevice];
                        [midi sendData:excitementMIDIData withDevice:virtualDevice];
                        
                   }
                    if(eventType == EE_UserAdded)
                        
                    {
                        NSLog(@"User Added");
                    }
                }
                
            }
        }
    
        EE_EmoStateFree(eState);
        EE_EmoEngineEventFree(eEvent); 
        
    }
    return 0;
}