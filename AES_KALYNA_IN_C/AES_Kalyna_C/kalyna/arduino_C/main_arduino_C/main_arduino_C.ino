#include <avr/pgmspace.h>
extern "C"{
  #include "aes.h"
}


void setup()
{
        Serial.begin(9600);
	keyExpansion();
	cipher();
	Serial.print("Cipher text : \n"); 

        uint8_t* state;
        state = arduino_get_array();
        
        size_t i;
	for(i=0 ; i<2*sizeof(uint64_t) ; ++i)
	{
		Serial.print(state[i],HEX);
	}
	Serial.print("\nFinished");
}

void loop(){
}

